//
//  DocumentsEffectHandler.swift
//  InterPrep
//
//  Documents effect handler
//

import Foundation
import ArchitectureCore
import NetworkService

// MARK: - Effect Handler

public actor DocumentsEffectHandler: EffectHandler {
    public typealias S = DocumentsState
    
    private let documentService: DocumentServiceProtocol
    
    public init(documentService: DocumentServiceProtocol) {
        self.documentService = documentService
    }
    
    public func handle(effect: S.Effect) async -> S.Feedback? {
        switch effect {
        case .loadFolders:
            do {
                let folders = try await documentService.fetchFolders()
                // Also load recent documents after folders
                let documents = try await documentService.fetchRecentDocuments()
                // Note: We can only return one feedback at a time
                // In a real app, you might want to chain these differently
                return .foldersLoaded(folders)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .loadRecentDocuments:
            do {
                let documents = try await documentService.fetchRecentDocuments()
                return .recentDocumentsLoaded(documents)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .createFolder(let name):
            do {
                try await documentService.createFolder(name: name)
                let folders = try await documentService.fetchFolders()
                return .foldersLoaded(folders)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .uploadFile(let url):
            do {
                try await documentService.uploadFile(url: url)
                let documents = try await documentService.fetchRecentDocuments()
                return .recentDocumentsLoaded(documents)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .createNote(let title, let content):
            do {
                try await documentService.createNote(title: title, content: content)
                let documents = try await documentService.fetchRecentDocuments()
                return .recentDocumentsLoaded(documents)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .deleteDocument(let id):
            do {
                try await documentService.deleteDocument(id: id)
                return nil
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case let .openDocument(document):
            do {
                let (data, filename) = try await documentService.downloadDocument(id: document.id)
                let tempDir = FileManager.default.temporaryDirectory
                let safeName = filename.isEmpty ? "document" : (filename as NSString).lastPathComponent
                let tempURL = tempDir.appendingPathComponent("preview_\(UUID().uuidString)_\(safeName)")
                try data.write(to: tempURL)
                return .documentDownloaded(tempURL)
            } catch {
                return .documentOpenFailed(error.localizedDescription)
            }
        }
    }
}

// MARK: - Service Protocol

public protocol DocumentServiceProtocol: Actor {
    func fetchFolders() async throws -> [Folder]
    func fetchRecentDocuments() async throws -> [Document]
    func createFolder(name: String) async throws
    func uploadFile(url: URL) async throws
    func createNote(title: String, content: String) async throws
    func deleteDocument(id: UUID) async throws
    /// Скачивает файл по id документа. Возвращает (данные, имя файла).
    func downloadDocument(id: UUID) async throws -> (Data, String)
}

// MARK: - Real Service

public final actor DocumentServiceImpl: DocumentServiceProtocol {
    private let networkService: NetworkServiceV2
    private var nodeIdByDocumentId: [UUID: UInt32] = [:]
    private var documentIdToMaterialId: [UUID: String] = [:]
    
    public init(networkService: NetworkServiceV2 = .shared) {
        self.networkService = networkService
    }
    
    public func fetchFolders() async throws -> [Folder] {
        let result = await networkService.listFolder(parentId: nil)
        
        switch result {
        case .success(let response):
            return response.nodes
                .filter { $0.type == "folder" }
                .map { node in
                    Folder(
                        name: node.name,
                        documentsCount: 0,
                        createdAt: Date(timeIntervalSince1970: TimeInterval(node.createdAt)),
                        color: .blue
                    )
                }
        case .failure(let error):
            throw error
        }
    }
    
    public func fetchRecentDocuments() async throws -> [Document] {
        let result = await networkService.listFolder(parentId: nil)
        
        switch result {
        case .success(let response):
            nodeIdByDocumentId.removeAll()
            documentIdToMaterialId.removeAll()
            
            return response.nodes
                .filter { $0.type == "file" }
                .map { node in
                    let documentId = UUID()
                    nodeIdByDocumentId[documentId] = node.id
                    if node.hasMaterialID {
                        documentIdToMaterialId[documentId] = node.materialID
                    }
                    
                    let size = node.hasFile ? node.file.size : 0
                    let createdAt = Date(timeIntervalSince1970: TimeInterval(node.createdAt))
                    let updatedAt = Date(timeIntervalSince1970: TimeInterval(node.updatedAt))
                    
                    return Document(
                        id: documentId,
                        name: node.name,
                        type: .pdf,
                        size: size,
                        createdAt: createdAt,
                        modifiedAt: updatedAt,
                        folderId: nil,
                        url: nil
                    )
                }
        case .failure(let error):
            throw error
        }
    }
    
    public func createFolder(name: String) async throws {
        let result = await networkService.createFolder(name: name, parentId: nil)
        
        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    public func uploadFile(url: URL) async throws {
        let resources = try url.resourceValues(forKeys: [.nameKey])
        let fileName = resources.name ?? url.lastPathComponent
        let data = try Data(contentsOf: url)
        
        let result = await networkService.uploadFile(
            fileContent: data,
            filename: fileName,
            parentId: nil,
            name: fileName
        )
        
        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    public func createNote(title: String, content: String) async throws {
        let data = Data(content.utf8)
        let filename = "\(title).txt"
        
        let result = await networkService.uploadFile(
            fileContent: data,
            filename: filename,
            parentId: nil,
            name: title
        )
        
        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    public func deleteDocument(id: UUID) async throws {
        guard let nodeId = nodeIdByDocumentId[id] else {
            return
        }
        
        let result = await networkService.deleteNode(nodeId: nodeId)
        
        switch result {
        case .success:
            nodeIdByDocumentId.removeValue(forKey: id)
            documentIdToMaterialId.removeValue(forKey: id)
        case .failure(let error):
            throw error
        }
    }
    
    public func downloadDocument(id: UUID) async throws -> (Data, String) {
        guard let materialId = documentIdToMaterialId[id], !materialId.isEmpty else {
            throw NSError(domain: "DocumentService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Документ не найден"])
        }
        let result = await networkService.downloadFile(materialId: materialId)
        switch result {
        case .success(let response):
            let data = response.content.isEmpty && response.hasContentBase64
                ? (Data(base64Encoded: response.contentBase64) ?? Data())
                : response.content
            return (data, response.filename.isEmpty ? "document" : response.filename)
        case .failure(let error):
            throw error
        }
    }
}
