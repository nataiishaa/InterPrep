import AnalyticsService
import ArchitectureCore
import CacheService
import Foundation
import NetworkMonitorService
import NetworkService

private struct FolderContentsCache: Codable {
    let folders: [Folder]
    let documents: [Document]
}

private struct DocumentFileMeta: Codable {
    let filename: String
    let materialId: String
}

public actor DocumentsEffectHandler: EffectHandler {
    public typealias StateType = DocumentsState

    private let documentService: DocumentServicing
    private let cacheManager = CacheManager.shared

    public init(documentService: DocumentServicing) {
        self.documentService = documentService
    }

    @MainActor
    private static func connectionMessage() -> String {
        NetworkMonitor.shared.isConnected
            ? "Не удалось подключиться к серверу. Возможно, включён VPN — попробуйте отключить его"
            : "Нет интернета. Проверьте подключение и попробуйте снова"
    }

    private static func message(for error: Error) async -> String {
        if let ne = error as? NetworkError {
            if ne.isConnectionError {
                return await connectionMessage()
            }
            if let api = ne.asAPIError {
                return api.userMessage
            }
        }
        return "Произошла ошибка. Попробуйте позже"
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    public func handle(effect: StateType.Effect) async -> StateType.Feedback? {
        switch effect {
        case .loadFolders:
            let isConnected = await MainActor.run { NetworkMonitor.shared.isConnected }
            if !isConnected {
                let cachedFolders = try? await cacheManager.load(forKey: CacheKey.documentsFolders, as: [Folder].self)
                let cachedRootDocs = try? await cacheManager.load(forKey: CacheKey.documentsRoot, as: [Document].self)
                let cachedRecentDocs = try? await cacheManager.load(forKey: CacheKey.documentsRecent, as: [Document].self)

                if cachedFolders != nil || cachedRootDocs != nil || cachedRecentDocs != nil {
                    return .foldersAndDocumentsLoadedFromCache(folders: cachedFolders ?? [], rootDocuments: cachedRootDocs ?? [], recentDocuments: cachedRecentDocs ?? [])
                }
                return .loadingFailed("Нет интернета. Проверьте подключение и попробуйте снова")
            }

            do {
                let (folders, rootDocs) = try await documentService.fetchRootContents()
                let recentDocs = (try? await documentService.fetchRecentDocuments()) ?? []

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
                return .loadingFailed(await Self.message(for: error))
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
                return .loadingFailed(await Self.message(for: error))
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
                return .loadingFailed(await Self.message(for: error))
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
                return .loadingFailed(await Self.message(for: error))
            }

        case .uploadFile(let url, let folderId):
            let isConnected = await MainActor.run { NetworkMonitor.shared.isConnected }
            if !isConnected {
                return .loadingFailed("Нет интернета. Подключитесь к сети для загрузки файла")
            }

            do {
                try await documentService.uploadFile(url: url, folderId: folderId)
                await trackEvent(.documentUploaded(type: url.pathExtension))
                let (folders, rootDocs) = try await documentService.fetchRootContents()
                let recentDocs = (try? await documentService.fetchRecentDocuments()) ?? []
                return .foldersAndDocumentsLoaded(folders: folders, rootDocuments: rootDocs, recentDocuments: recentDocs)
            } catch {
                if let ne = error as? NetworkError, ne.isConnectionError || ne.isTimeoutError {
                    return .loadingFailed("Не удалось загрузить файл. Проверьте подключение к интернету")
                }
                return .loadingFailed(await Self.message(for: error))
            }

        case .createNote(let title, let content, let parentFolder):
            do {
                let parentId = parentFolder.flatMap { $0.nodeId }.map { UInt32($0) }
                try await documentService.createNote(title: title, content: content, parentId: parentId)
                let (folders, rootDocs) = try await documentService.fetchRootContents()
                let recentDocs = (try? await documentService.fetchRecentDocuments()) ?? []
                return .foldersAndDocumentsLoaded(folders: folders, rootDocuments: rootDocs, recentDocuments: recentDocs)
            } catch {
                return .loadingFailed(await Self.message(for: error))
            }

        case .updateNote(let document, let newName, let content):
            do {
                try await documentService.updateNote(document: document, newName: newName, content: content)
                let (folders, rootDocs) = try await documentService.fetchRootContents()
                let recentDocs = try await documentService.fetchRecentDocuments()
                return .noteUpdatedAndRefreshed(folders: folders, rootDocuments: rootDocs, recentDocuments: recentDocs)
            } catch {
                return .loadingFailed(await Self.message(for: error))
            }

        case .loadNoteContent(let document):
            do {
                let content = try await documentService.loadNoteContent(id: document.id)
                return .noteContentLoaded(document, content)
            } catch {
                return .documentOpenFailed(await Self.message(for: error))
            }

        case .deleteDocument(let id):
            do {
                try await documentService.deleteDocument(id: id)
                await trackEvent(.documentDeleted(type: "unknown"))
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
                return .loadingFailed(await Self.message(for: error))
            }

        case .renameFolder(let folder, let newName):
            do {
                try await documentService.renameFolder(folder: folder, newName: newName)
                let (folders, rootDocs) = try await documentService.fetchRootContents()
                let recentDocs = try await documentService.fetchRecentDocuments()
                return .folderRenamedAndRefreshed(folderId: folder.id, newName: newName, folders: folders, rootDocuments: rootDocs, recentDocuments: recentDocs)
            } catch {
                return .loadingFailed(await Self.message(for: error))
            }

        case .deleteFolder(let folder):
            do {
                try await documentService.deleteFolder(folder: folder)
                let (folders, rootDocs) = try await documentService.fetchRootContents()
                let recentDocs = try await documentService.fetchRecentDocuments()
                return .folderDeletedAndRefreshed(deletedFolderId: folder.id, folders: folders, rootDocuments: rootDocs, recentDocuments: recentDocs)
            } catch {
                return .loadingFailed(await Self.message(for: error))
            }

        case let .openDocument(document):
            let isConnected = await MainActor.run { NetworkMonitor.shared.isConnected }
            let metaKey = CacheKey.documentMeta(documentId: document.id.uuidString)
            let contentKey = CacheKey.documentContent(documentId: document.id.uuidString)

            if !isConnected {
                if let meta = try? await cacheManager.load(forKey: metaKey, as: DocumentFileMeta.self),
                   let cachedData = try? await cacheManager.loadBinary(forKey: contentKey),
                   !cachedData.isEmpty {
                    let tempDir = FileManager.default.temporaryDirectory
                    var safeName = (meta.filename as NSString).lastPathComponent
                    if safeName.isEmpty { safeName = "document" }
                    if (safeName as NSString).pathExtension.isEmpty {
                        let ext = document.type.fileExtension.isEmpty ? "txt" : document.type.fileExtension
                        safeName = "\(safeName).\(ext)"
                    }
                    let tempURL = tempDir.appendingPathComponent("preview_\(UUID().uuidString)_\(safeName)")
                    do {
                        try cachedData.write(to: tempURL)
                        return .documentDownloaded(tempURL)
                    } catch {
                        return .documentOpenFailed("Не удалось открыть кэшированный файл")
                    }
                }
                return .documentOpenFailed("Нет интернета. Этот файл не был сохранён для офлайн-доступа")
            }

            do {
                let (data, filename) = try await documentService.downloadDocument(id: document.id)
                await trackEvent(.documentViewed(type: document.type.fileExtension))
                let tempDir = FileManager.default.temporaryDirectory
                var safeName = filename.isEmpty ? "document" : (filename as NSString).lastPathComponent
                if (safeName as NSString).pathExtension.isEmpty {
                    let ext = document.type.fileExtension.isEmpty ? "txt" : document.type.fileExtension
                    safeName = "\(safeName).\(ext)"
                }
                let tempURL = tempDir.appendingPathComponent("preview_\(UUID().uuidString)_\(safeName)")
                try data.write(to: tempURL)
                try? await cacheManager.saveBinary(data, forKey: contentKey)
                try? await cacheManager.save(DocumentFileMeta(filename: safeName, materialId: ""), forKey: metaKey)
                return .documentDownloaded(tempURL)
            } catch {
                if let meta = try? await cacheManager.load(forKey: metaKey, as: DocumentFileMeta.self),
                   let cachedData = try? await cacheManager.loadBinary(forKey: contentKey),
                   !cachedData.isEmpty {
                    let tempDir = FileManager.default.temporaryDirectory
                    var safeName = (meta.filename as NSString).lastPathComponent
                    if safeName.isEmpty { safeName = "document" }
                    let tempURL = tempDir.appendingPathComponent("preview_\(UUID().uuidString)_\(safeName)")
                    if (try? cachedData.write(to: tempURL)) != nil {
                        return .documentDownloaded(tempURL)
                    }
                }
                return .documentOpenFailed(await Self.message(for: error))
            }
        }
    }

    @MainActor
    private func trackEvent(_ event: AnalyticsEvent) {
        AnalyticsManager.shared.track(event)
    }
}
