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
                let documents = try await documentService.fetchRecentDocuments()
                return .foldersAndDocumentsLoaded(folders, documents)
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
                let documents = try await documentService.fetchRecentDocuments()
                return .foldersAndDocumentsLoaded(folders, documents)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .uploadFile(let url, let folderId):
            do {
                try await documentService.uploadFile(url: url, folderId: folderId)
                let folders = try await documentService.fetchFolders()
                let documents = try await documentService.fetchRecentDocuments()
                return .foldersAndDocumentsLoaded(folders, documents)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .createNote(let title, let content):
            do {
                try await documentService.createNote(title: title, content: content)
                let folders = try await documentService.fetchFolders()
                let documents = try await documentService.fetchRecentDocuments()
                return .foldersAndDocumentsLoaded(folders, documents)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .updateNote(let document, let content):
            do {
                try await documentService.updateNote(id: document.id, content: content)
                let folders = try await documentService.fetchFolders()
                let documents = try await documentService.fetchRecentDocuments()
                return .foldersAndDocumentsLoaded(folders, documents)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .loadNoteContent(let document):
            do {
                let content = try await documentService.loadNoteContent(id: document.id)
                return .noteContentLoaded(document, content)
            } catch {
                return .documentOpenFailed(error.localizedDescription)
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
    func uploadFile(url: URL, folderId: UUID?) async throws
    func createNote(title: String, content: String) async throws
    func updateNote(id: UUID, content: String) async throws
    func loadNoteContent(id: UUID) async throws -> String
    func deleteDocument(id: UUID) async throws
    /// Скачивает файл по id документа. Возвращает (данные, имя файла).
    func downloadDocument(id: UUID) async throws -> (Data, String)
}

// MARK: - Real Service

public final actor DocumentServiceImpl: DocumentServiceProtocol {
    private let networkService: NetworkServiceV2
    private var nodeIdByDocumentId: [UUID: UInt32] = [:]
    private var documentIdToMaterialId: [UUID: String] = [:]
    private var folderIdToNodeId: [UUID: UInt32] = [:]
    
    /// Стабильный UUID из node.id: один и тот же node всегда даёт один и тот же UUID.
    private static func uuidFromNodeId(_ nodeId: UInt32, folder: Bool) -> UUID {
        var bytes = [UInt8](repeating: 0, count: 16)
        bytes[0] = folder ? 0 : 1
        bytes[1] = UInt8((nodeId >> 24) & 0xFF)
        bytes[2] = UInt8((nodeId >> 16) & 0xFF)
        bytes[3] = UInt8((nodeId >> 8) & 0xFF)
        bytes[4] = UInt8(nodeId & 0xFF)
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7], bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }
    
    public init(networkService: NetworkServiceV2 = .shared) {
        self.networkService = networkService
    }
    
    public func fetchFolders() async throws -> [Folder] {
        let result = await networkService.listFolder(parentId: nil)
        
        switch result {
        case .success(let response):
            folderIdToNodeId.removeAll()
            
            let allNodes = response.nodes
            let folderNodes = allNodes.filter { $0.type == "folder" }
            
            return folderNodes.map { node in
                let folderId = Self.uuidFromNodeId(node.id, folder: true)
                folderIdToNodeId[folderId] = node.id
                
                let filesInFolder = allNodes.filter { 
                    $0.type == "file" && $0.hasParentID && $0.parentID == node.id 
                }
                
                return Folder(
                    id: folderId,
                    nodeId: node.id,
                    name: node.name,
                    documentsCount: filesInFolder.count,
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
            
            let allNodes = response.nodes
            let folderNodes = allNodes.filter { $0.type == "folder" }
            for node in folderNodes {
                let folderId = Self.uuidFromNodeId(node.id, folder: true)
                folderIdToNodeId[folderId] = node.id
            }
            
            return allNodes
                .filter { $0.type == "file" }
                .map { node in
                    let documentId = Self.uuidFromNodeId(node.id, folder: false)
                    nodeIdByDocumentId[documentId] = node.id
                    if node.hasMaterialID {
                        documentIdToMaterialId[documentId] = node.materialID
                    }
                    
                    let size = node.hasFile ? node.file.size : 0
                    let createdAt = Date(timeIntervalSince1970: TimeInterval(node.createdAt))
                    let updatedAt = Date(timeIntervalSince1970: TimeInterval(node.updatedAt))
                    
                    let docType = self.detectDocumentType(from: node.name)
                    
                    var folderId: UUID?
                    if node.hasParentID {
                        folderId = Self.uuidFromNodeId(node.parentID, folder: true)
                    }
                    
                    return Document(
                        id: documentId,
                        name: node.name,
                        type: docType,
                        size: size,
                        createdAt: createdAt,
                        modifiedAt: updatedAt,
                        folderId: folderId,
                        url: nil
                    )
                }
                .sorted { $0.modifiedAt > $1.modifiedAt }
        case .failure(let error):
            throw error
        }
    }
    
    private func detectDocumentType(from filename: String) -> DocumentType {
        let lowercased = filename.lowercased()
        if lowercased.hasSuffix(".pdf") {
            return .pdf
        } else if lowercased.hasSuffix(".doc") {
            return .doc
        } else if lowercased.hasSuffix(".docx") {
            return .docx
        } else if lowercased.hasSuffix(".txt") {
            return .txt
        } else if lowercased.hasSuffix(".png") || lowercased.hasSuffix(".jpg") || lowercased.hasSuffix(".jpeg") {
            return .image
        } else {
            return .other
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
    
    public func uploadFile(url: URL, folderId: UUID?) async throws {
        let resources = try url.resourceValues(forKeys: [.nameKey])
        let fileName = resources.name ?? url.lastPathComponent
        let data = try Data(contentsOf: url)
        
        var parentNodeId: UInt32?
        if let folderId = folderId {
            parentNodeId = folderIdToNodeId[folderId]
        }
        
        let result = await networkService.uploadFile(
            fileContent: data,
            filename: fileName,
            parentId: parentNodeId,
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
    
    public func loadNoteContent(id: UUID) async throws -> String {
        let (data, _) = try await downloadDocument(id: id)
        guard let content = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "DocumentService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Не удалось прочитать содержимое заметки"])
        }
        return content
    }
    
    public func updateNote(id: UUID, content: String) async throws {
        guard let nodeId = nodeIdByDocumentId[id] else {
            throw NSError(domain: "DocumentService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Заметка не найдена"])
        }
        let result = await networkService.listFolder(parentId: nil)
        guard case .success(let response) = result else {
            throw NSError(domain: "DocumentService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Не удалось получить информацию о файле"])
        }
        guard let node = response.nodes.first(where: { $0.id == nodeId }) else {
            throw NSError(domain: "DocumentService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Файл не найден"])
        }
        let parentId: UInt32? = node.hasParentID ? node.parentID : nil
        let fileName = node.name
        
        try await deleteDocument(id: id)
        
        let data = Data(content.utf8)
        let uploadResult = await networkService.uploadFile(
            fileContent: data,
            filename: fileName,
            parentId: parentId,
            name: fileName
        )
        
        switch uploadResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}
