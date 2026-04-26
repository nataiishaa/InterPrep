//
//  DocumentsEffectHandler.swift
//  InterPrep
//
//  Documents effect handler
//

import ArchitectureCore
import CacheService
import Foundation
import NetworkMonitorService
import NetworkService

// swiftlint:disable file_length

private struct FolderContentsCache: Codable {
    let folders: [Folder]
    let documents: [Document]
}

public actor DocumentsEffectHandler: EffectHandler {
    public typealias StateType = DocumentsState
    
    private let documentService: DocumentServicing
    private let cacheManager = CacheManager.shared
    
    public init(documentService: DocumentServicing) {
        self.documentService = documentService
    }
    
    private static func message(for error: Error) -> String {
        print("[Documents] error: \(error)")
        if let ne = error as? NetworkError {
            print("[Documents] NetworkError case: \(ne)")
            if ne.isConnectionError {
                return "Нет подключения к интернету"
            }
            if let api = ne.asAPIError {
                return api.userMessage
            }
        }
        return error.localizedDescription
    }
    
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    public func handle(effect: StateType.Effect) async -> StateType.Feedback? {
        switch effect {
        case .loadFolders:
            do {
                let (folders, rootDocs) = try await documentService.fetchRootContents()
                let recentDocs = try await documentService.fetchRecentDocuments()
                
                try? await cacheManager.save(folders, forKey: CacheKey.documentsFolders)
                try? await cacheManager.save(rootDocs, forKey: CacheKey.documentsRoot)
                try? await cacheManager.save(recentDocs, forKey: CacheKey.documentsRecent)
                
                return .foldersAndDocumentsLoaded(folders: folders, rootDocuments: rootDocs, recentDocuments: recentDocs)
            } catch {
                let cachedFolders = try? await cacheManager.load(forKey: CacheKey.documentsFolders, as: [Folder].self)
                let cachedRootDocs = try? await cacheManager.load(forKey: CacheKey.documentsRoot, as: [Document].self)
                let cachedRecentDocs = try? await cacheManager.load(forKey: CacheKey.documentsRecent, as: [Document].self)
                if cachedFolders != nil || cachedRootDocs != nil || cachedRecentDocs != nil {
                    return .foldersAndDocumentsLoadedFromCache(folders: cachedFolders ?? [], rootDocuments: cachedRootDocs ?? [], recentDocuments: cachedRecentDocs ?? [])
                }
                return .loadingFailed(Self.message(for: error))
            }
            
        case .loadRecentDocuments:
            do {
                let documents = try await documentService.fetchRecentDocuments()
                try? await cacheManager.save(documents, forKey: CacheKey.documentsRecent)
                return .recentDocumentsLoaded(documents)
            } catch {
                if let cachedDocuments = try? await cacheManager.load(forKey: CacheKey.documentsRecent, as: [Document].self) {
                    return .recentDocumentsLoaded(cachedDocuments)
                }
                return .loadingFailed(Self.message(for: error))
            }
            
        case .createFolder(let name, let parentFolder):
            do {
                let parentId = parentFolder.flatMap { $0.nodeId }.map { UInt32($0) }
                try await documentService.createFolder(name: name, parentId: parentId)
                let (folders, rootDocs) = try await documentService.fetchRootContents()
                let recentDocs = try await documentService.fetchRecentDocuments()
                
                try? await cacheManager.save(folders, forKey: CacheKey.documentsFolders)
                try? await cacheManager.save(rootDocs, forKey: CacheKey.documentsRoot)
                try? await cacheManager.save(recentDocs, forKey: CacheKey.documentsRecent)
                
                return .foldersAndDocumentsLoaded(folders: folders, rootDocuments: rootDocs, recentDocuments: recentDocs)
            } catch {
                if (error as? NetworkError)?.isConnectionError == true {
                    let parentId = parentFolder.flatMap { $0.nodeId }.map { UInt32($0) }
                    await MainActor.run {
                        OfflineSyncManager.shared.addOperation(.createFolder(name: name, parentId: parentId))
                    }
                    
                    if let cachedFolders = try? await cacheManager.load(forKey: CacheKey.documentsFolders, as: [Folder].self) {
                        let cachedRootDocs = (try? await cacheManager.load(forKey: CacheKey.documentsRoot, as: [Document].self)) ?? []
                        let cachedRecentDocs = (try? await cacheManager.load(forKey: CacheKey.documentsRecent, as: [Document].self)) ?? []
                        return .foldersAndDocumentsLoaded(folders: cachedFolders, rootDocuments: cachedRootDocs, recentDocuments: cachedRecentDocs)
                    }
                }
                return .loadingFailed(Self.message(for: error))
            }

        case .loadFolderContents(let folder):
            do {
                guard let nodeId = folder.nodeId else {
                    return .loadingFailed("Папка не найдена")
                }
                let (folders, documents) = try await documentService.fetchFolderContents(parentNodeId: nodeId)
                
                let cacheKey = CacheKey.documentFolderContents(folderId: folder.id.uuidString)
                let cacheData = FolderContentsCache(folders: folders, documents: documents)
                try? await cacheManager.save(cacheData, forKey: cacheKey)
                
                return .folderContentsLoaded(folders, documents)
            } catch {
                let cacheKey = CacheKey.documentFolderContents(folderId: folder.id.uuidString)
                if let cached = try? await cacheManager.load(forKey: cacheKey, as: FolderContentsCache.self) {
                    return .folderContentsLoadedFromCache(cached.folders, cached.documents)
                }
                return .loadingFailed(Self.message(for: error))
            }
            
        case .uploadFile(let url, let folderId):
            do {
                try await documentService.uploadFile(url: url, folderId: folderId)
                let (folders, rootDocs) = try await documentService.fetchRootContents()
                let recentDocs = try await documentService.fetchRecentDocuments()
                return .foldersAndDocumentsLoaded(folders: folders, rootDocuments: rootDocs, recentDocuments: recentDocs)
            } catch {
                return .loadingFailed(Self.message(for: error))
            }
            
        case .createNote(let title, let content, let parentFolder):
            do {
                let parentId = parentFolder.flatMap { $0.nodeId }.map { UInt32($0) }
                print("[Documents] createNote title=\(title) parentId=\(String(describing: parentId))")
                try await documentService.createNote(title: title, content: content, parentId: parentId)
                print("[Documents] createNote success, refreshing...")
                let (folders, rootDocs) = try await documentService.fetchRootContents()
                let recentDocs = try await documentService.fetchRecentDocuments()
                return .foldersAndDocumentsLoaded(folders: folders, rootDocuments: rootDocs, recentDocuments: recentDocs)
            } catch {
                print("[Documents] createNote failed: \(error)")
                return .loadingFailed(Self.message(for: error))
            }
            
        case .updateNote(let document, let newName, let content):
            do {
                try await documentService.updateNote(document: document, newName: newName, content: content)
                let (folders, rootDocs) = try await documentService.fetchRootContents()
                let recentDocs = try await documentService.fetchRecentDocuments()
                return .noteUpdatedAndRefreshed(folders: folders, rootDocuments: rootDocs, recentDocuments: recentDocs)
            } catch {
                return .loadingFailed(Self.message(for: error))
            }
            
        case .loadNoteContent(let document):
            do {
                let content = try await documentService.loadNoteContent(id: document.id)
                return .noteContentLoaded(document, content)
            } catch {
                return .documentOpenFailed(Self.message(for: error))
            }
            
        case .deleteDocument(let id):
            do {
                try await documentService.deleteDocument(id: id)
                let (folders, rootDocs) = try await documentService.fetchRootContents()
                let recentDocs = try await documentService.fetchRecentDocuments()
                
                try? await cacheManager.save(folders, forKey: CacheKey.documentsFolders)
                try? await cacheManager.save(rootDocs, forKey: CacheKey.documentsRoot)
                try? await cacheManager.save(recentDocs, forKey: CacheKey.documentsRecent)
                
                return .foldersAndDocumentsLoaded(folders: folders, rootDocuments: rootDocs, recentDocuments: recentDocs)
            } catch {
                if (error as? NetworkError)?.isConnectionError == true {
                    await MainActor.run {
                        OfflineSyncManager.shared.addOperation(.deleteDocument(id: id))
                    }
                    
                    let cachedFolders = (try? await cacheManager.load(forKey: CacheKey.documentsFolders, as: [Folder].self)) ?? []
                    var cachedRootDocs = (try? await cacheManager.load(forKey: CacheKey.documentsRoot, as: [Document].self)) ?? []
                    var cachedRecentDocs = (try? await cacheManager.load(forKey: CacheKey.documentsRecent, as: [Document].self)) ?? []
                    cachedRootDocs.removeAll { $0.id == id }
                    cachedRecentDocs.removeAll { $0.id == id }
                    try? await cacheManager.save(cachedRootDocs, forKey: CacheKey.documentsRoot)
                    try? await cacheManager.save(cachedRecentDocs, forKey: CacheKey.documentsRecent)
                    return .foldersAndDocumentsLoaded(folders: cachedFolders, rootDocuments: cachedRootDocs, recentDocuments: cachedRecentDocs)
                }
                return .loadingFailed(Self.message(for: error))
            }

        case .renameFolder(let folder, let newName):
            do {
                try await documentService.renameFolder(folder: folder, newName: newName)
                let (folders, rootDocs) = try await documentService.fetchRootContents()
                let recentDocs = try await documentService.fetchRecentDocuments()
                return .folderRenamedAndRefreshed(folderId: folder.id, newName: newName, folders: folders, rootDocuments: rootDocs, recentDocuments: recentDocs)
            } catch {
                return .loadingFailed(Self.message(for: error))
            }

        case .deleteFolder(let folder):
            do {
                try await documentService.deleteFolder(folder: folder)
                let (folders, rootDocs) = try await documentService.fetchRootContents()
                let recentDocs = try await documentService.fetchRecentDocuments()
                return .folderDeletedAndRefreshed(deletedFolderId: folder.id, folders: folders, rootDocuments: rootDocs, recentDocuments: recentDocs)
            } catch {
                return .loadingFailed(Self.message(for: error))
            }
            
        case let .openDocument(document):
            do {
                let (data, filename) = try await documentService.downloadDocument(id: document.id)
                let tempDir = FileManager.default.temporaryDirectory
                var safeName = filename.isEmpty ? "document" : (filename as NSString).lastPathComponent
                if (safeName as NSString).pathExtension.isEmpty {
                    let ext = document.type.fileExtension.isEmpty ? "txt" : document.type.fileExtension
                    safeName = "\(safeName).\(ext)"
                }
                let tempURL = tempDir.appendingPathComponent("preview_\(UUID().uuidString)_\(safeName)")
                try data.write(to: tempURL)
                return .documentDownloaded(tempURL)
            } catch {
                return .documentOpenFailed(Self.message(for: error))
            }
        }
    }
}

public final actor DocumentServiceImpl: DocumentServicing {
    private let networkService: NetworkServiceV2
    private var nodeIdByDocumentId: [UUID: UInt32] = [:]
    private var documentIdToMaterialId: [UUID: String] = [:]
    private var folderIdToNodeId: [UUID: UInt32] = [:]
    private var documentSizeCache: [String: Int64] = [:]
    
    private static func uuidFromNodeId(_ nodeId: UInt32, folder: Bool) -> UUID {
        var bytes = [UInt8](repeating: 0, count: 16)
        bytes[0] = folder ? 0 : 1
        bytes[1] = UInt8((nodeId >> 24) & 0xFF)
        bytes[2] = UInt8((nodeId >> 16) & 0xFF)
        bytes[3] = UInt8((nodeId >> 8) & 0xFF)
        bytes[4] = UInt8(nodeId & 0xFF)
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7], bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }
    
    private static func safeDate(timestamp: Int64) -> Date {
        let timeInterval = TimeInterval(timestamp)
        guard timeInterval.isFinite else { return Date() }
        let date = Date(timeIntervalSince1970: timeInterval)
        return date
    }
    
    public init(networkService: NetworkServiceV2 = .shared) {
        self.networkService = networkService
    }
    
    public func fetchRootContents() async throws -> (folders: [Folder], documents: [Document]) {
        let result = await networkService.listFolder(parentId: nil)
        switch result {
        case .success(let response):
            folderIdToNodeId.removeAll()
            let allNodes = response.nodes
            let folderNodes = allNodes.filter { $0.type == "folder" }
            let fileNodes = allNodes.filter { $0.type == "file" }
            
            var folders: [Folder] = []
            await withTaskGroup(of: (node: Materials_Node, count: Int).self) { group in
                for node in folderNodes {
                    group.addTask {
                        let countResult = await self.networkService.listFolder(parentId: node.id)
                        let count: Int
                        if case .success(let response) = countResult {
                            count = response.nodes.filter { $0.type == "file" }.count
                        } else {
                            count = 0
                        }
                        return (node, count)
                    }
                }
                for await (node, count) in group {
                    let folderId = Self.uuidFromNodeId(node.id, folder: true)
                    folderIdToNodeId[folderId] = node.id
                    folders.append(Folder(
                        id: folderId,
                        nodeId: node.id,
                        name: node.name,
                        documentsCount: count,
                        createdAt: Self.safeDate(timestamp: Int64(node.createdAt)),
                        color: .blue
                    ))
                }
            }
            
            for node in fileNodes {
                let documentId = Self.uuidFromNodeId(node.id, folder: false)
                nodeIdByDocumentId[documentId] = node.id
                if node.hasMaterialID {
                    documentIdToMaterialId[documentId] = node.materialID
                }
            }
            
            let documents: [Document] = fileNodes.map { node in
                let documentId = Self.uuidFromNodeId(node.id, folder: false)
                var size = node.hasFile ? node.file.size : 0
                if size == 0, node.hasMaterialID, let cachedSize = documentSizeCache[node.materialID] {
                    size = cachedSize
                }
                return Document(
                    id: documentId,
                    name: node.name,
                    type: detectDocumentType(from: node.name),
                    size: size,
                    createdAt: Self.safeDate(timestamp: Int64(node.createdAt)),
                    modifiedAt: Self.safeDate(timestamp: Int64(node.updatedAt)),
                    folderId: nil,
                    url: nil
                )
            }.sorted { $0.modifiedAt > $1.modifiedAt }
            
            return (folders.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }, documents)
        case .failure(let error):
            throw error
        }
    }
    
    public func fetchRecentDocuments() async throws -> [Document] {
        let result = await networkService.recentFiles()
        
        switch result {
        case .success(let response):
            let fileNodes = response.nodes
            
            for node in fileNodes {
                let documentId = Self.uuidFromNodeId(node.id, folder: false)
                nodeIdByDocumentId[documentId] = node.id
                if node.hasMaterialID {
                    documentIdToMaterialId[documentId] = node.materialID
                }
            }
            
            return fileNodes
                .map { node in
                    let documentId = Self.uuidFromNodeId(node.id, folder: false)
                    
                    var size = node.hasFile ? node.file.size : 0
                    if size == 0, node.hasMaterialID, let cachedSize = documentSizeCache[node.materialID] {
                        size = Int64(Int(cachedSize))
                    }
                    let createdAt = Self.safeDate(timestamp: Int64(node.createdAt))
                    let updatedAt = Self.safeDate(timestamp: Int64(node.updatedAt))
                    
                    let docType = self.detectDocumentType(from: node.name)
                    
                    return Document(
                        id: documentId,
                        name: node.name,
                        type: docType,
                        size: size,
                        createdAt: createdAt,
                        modifiedAt: updatedAt,
                        folderId: nil,
                        url: nil
                    )
                }
                .sorted { $0.modifiedAt > $1.modifiedAt }
        case .failure(let error):
            // RecentFiles not implemented on backend yet — return empty list instead of failing
            if case .apiError(let apiError) = error,
               apiError.serverMessage.contains("unknown method") || apiError.serverMessage.contains("unimplemented") {
                print("[Documents] RecentFiles not implemented, returning empty list")
                return []
            }
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
    
    public func fetchFolderContents(parentNodeId: UInt32) async throws -> (folders: [Folder], documents: [Document]) {
        let result = await networkService.listFolder(parentId: parentNodeId)
        switch result {
        case .success(let response):
            let allNodes = response.nodes
            let folderNodes = allNodes.filter { $0.type == "folder" }
            let folders: [Folder] = folderNodes.map { node in
                let folderId = Self.uuidFromNodeId(node.id, folder: true)
                folderIdToNodeId[folderId] = node.id
                let filesInFolder = allNodes.filter { $0.type == "file" && $0.hasParentID && $0.parentID == node.id }
                return Folder(
                    id: folderId,
                    nodeId: node.id,
                    name: node.name,
                    documentsCount: filesInFolder.count,
                    createdAt: Self.safeDate(timestamp: Int64(node.createdAt)),
                    color: .blue
                )
            }
            let documents: [Document] = allNodes
                .filter { $0.type == "file" }
                .map { node in
                    let documentId = Self.uuidFromNodeId(node.id, folder: false)
                    nodeIdByDocumentId[documentId] = node.id
                    if node.hasMaterialID {
                        documentIdToMaterialId[documentId] = node.materialID
                    }
                    var size = node.hasFile ? node.file.size : 0
                    if size == 0, node.hasMaterialID, let cachedSize = documentSizeCache[node.materialID] {
                        size = cachedSize
                    }
                    let parentFolderId = node.hasParentID ? Self.uuidFromNodeId(node.parentID, folder: true) : nil
                    return Document(
                        id: documentId,
                        name: node.name,
                        type: detectDocumentType(from: node.name),
                        size: size,
                        createdAt: Self.safeDate(timestamp: Int64(node.createdAt)),
                        modifiedAt: Self.safeDate(timestamp: Int64(node.updatedAt)),
                        folderId: parentFolderId,
                        url: nil
                    )
                }
                .sorted { $0.modifiedAt > $1.modifiedAt }
            return (folders, documents)
        case .failure(let error):
            throw error
        }
    }

    public func createFolder(name: String, parentId: UInt32?) async throws {
        let result = await networkService.createFolder(name: name, parentId: parentId)
        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    public func renameFolder(folder: Folder, newName: String) async throws {
        guard let nodeId = folder.nodeId else {
            throw NSError(domain: "DocumentService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Папка не найдена"])
        }
        let result = await networkService.renameNode(nodeId: nodeId, newName: newName)
        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    public func deleteFolder(folder: Folder) async throws {
        guard let nodeId = folder.nodeId else {
            throw NSError(domain: "DocumentService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Папка не найдена"])
        }
        let result = await networkService.deleteNode(nodeId: nodeId)
        switch result {
        case .success:
            folderIdToNodeId.removeValue(forKey: folder.id)
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
        case .success(let response):
            if !response.materialID.isEmpty {
                let actualSize = response.size > 0 ? response.size : Int64(data.count)
                documentSizeCache[response.materialID] = actualSize
            }
            return
        case .failure(let error):
            throw error
        }
    }
    
    public func createNote(title: String, content: String, parentId: UInt32?) async throws {
        let data = Data(content.utf8)
        let filename = title.hasSuffix(".txt") ? title : "\(title).txt"
        let result = await networkService.uploadFile(
            fileContent: data,
            filename: filename,
            parentId: parentId,
            name: title
        )
        switch result {
        case .success(let response):
            if !response.materialID.isEmpty {
                let actualSize = response.size > 0 ? response.size : Int64(data.count)
                documentSizeCache[response.materialID] = actualSize
            }
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
        guard documentIdToMaterialId[id] != nil else {
            throw NSError(domain: "DocumentService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Не удалось открыть заметку: документ не найден"])
        }
        let (data, _) = try await downloadDocument(id: id)
        guard let content = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "DocumentService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Не удалось прочитать содержимое заметки"])
        }
        return content
    }
    
    public func updateNote(document: Document, newName: String, content: String) async throws {
        guard nodeIdByDocumentId[document.id] != nil else {
            throw NSError(domain: "DocumentService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Заметка не найдена"])
        }
        let parentId: UInt32? = document.folderId.flatMap { folderIdToNodeId[$0] }
        let fileName = newName.isEmpty ? document.name : newName

        try await deleteDocument(id: document.id)

        let data = Data(content.utf8)
        let uploadResult = await networkService.uploadFile(
            fileContent: data,
            filename: fileName,
            parentId: parentId,
            name: fileName
        )

        switch uploadResult {
        case .success(let response):
            if !response.materialID.isEmpty {
                let actualSize = response.size > 0 ? response.size : Int64(data.count)
                documentSizeCache[response.materialID] = actualSize
            }
            return
        case .failure(let error):
            throw error
        }
    }
}
