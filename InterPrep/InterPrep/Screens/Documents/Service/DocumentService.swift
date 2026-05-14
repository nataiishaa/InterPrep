import DocumentsFeature
import Foundation
import NetworkService

public final actor DocumentService: DocumentServicing {
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
            if case .apiError(let apiError) = error,
               apiError.serverMessage.contains("unknown method") || apiError.serverMessage.contains("unimplemented") {
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

    private static let maxFileSizeBytes = 25 * 1024 * 1024 

    public func uploadFile(url: URL, folderId: UUID?) async throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "DocumentService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Нет доступа к файлу"])
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let resources = try url.resourceValues(forKeys: [.nameKey, .fileSizeKey])
        let fileName = resources.name ?? url.lastPathComponent
        let fileSize = resources.fileSize ?? 0

        if fileSize > Self.maxFileSizeBytes {
            let sizeMB = Double(fileSize) / 1024.0 / 1024.0
            throw NSError(domain: "DocumentService", code: 413, userInfo: [NSLocalizedDescriptionKey: "Файл слишком большой (\(String(format: "%.1f", sizeMB)) МБ). Максимальный размер — 25 МБ"])
        }

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
