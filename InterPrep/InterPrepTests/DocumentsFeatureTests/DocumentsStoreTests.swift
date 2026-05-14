import ArchitectureCore
import CacheService
@testable import DocumentsFeature
import XCTest

private actor SpyDocumentService: DocumentServicing {
    var fetchRootContentsResult: Result<(folders: [Folder], documents: [Document]), Error> = .success(([], []))
    var fetchRecentDocumentsResult: Result<[Document], Error> = .success([])
    var fetchFolderContentsResult: Result<(folders: [Folder], documents: [Document]), Error> = .success(([], []))
    var createFolderResult: Result<Void, Error> = .success(())
    var deleteDocumentResult: Result<Void, Error> = .success(())
    var renameFolderResult: Result<Void, Error> = .success(())
    var deleteFolderResult: Result<Void, Error> = .success(())
    var downloadDocumentResult: Result<(Data, String), Error> = .success((Data(), "test.pdf"))
    var createNoteResult: Result<Void, Error> = .success(())
    var loadNoteContentResult: Result<String, Error> = .success("Note content")

    var fetchRootCallCount = 0
    var createFolderCallCount = 0
    var deleteDocumentCallCount = 0
    var renameFolderCallCount = 0
    var deleteFolderCallCount = 0

    func fetchRootContents() async throws -> (folders: [Folder], documents: [Document]) {
        fetchRootCallCount += 1
        switch fetchRootContentsResult {
        case .success(let contents): return contents
        case .failure(let error): throw error
        }
    }

    func fetchRecentDocuments() async throws -> [Document] {
        switch fetchRecentDocumentsResult {
        case .success(let documents): return documents
        case .failure(let error): throw error
        }
    }

    func fetchFolderContents(parentNodeId: UInt32) async throws -> (folders: [Folder], documents: [Document]) {
        switch fetchFolderContentsResult {
        case .success(let contents): return contents
        case .failure(let error): throw error
        }
    }

    func createFolder(name: String, parentId: UInt32?) async throws {
        createFolderCallCount += 1
        if case .failure(let error) = createFolderResult { throw error }
    }

    func uploadFile(url: URL, folderId: UUID?) async throws {}

    func createNote(title: String, content: String, parentId: UInt32?) async throws {
        if case .failure(let error) = createNoteResult { throw error }
    }

    func updateNote(document: Document, newName: String, content: String) async throws {}

    func loadNoteContent(id: UUID) async throws -> String {
        switch loadNoteContentResult {
        case .success(let content): return content
        case .failure(let error): throw error
        }
    }

    func deleteDocument(id: UUID) async throws {
        deleteDocumentCallCount += 1
        if case .failure(let error) = deleteDocumentResult { throw error }
    }

    func renameFolder(folder: Folder, newName: String) async throws {
        renameFolderCallCount += 1
        if case .failure(let error) = renameFolderResult { throw error }
    }

    func deleteFolder(folder: Folder) async throws {
        deleteFolderCallCount += 1
        if case .failure(let error) = deleteFolderResult { throw error }
    }

    func downloadDocument(id: UUID) async throws -> (Data, String) {
        switch downloadDocumentResult {
        case .success(let payload): return payload
        case .failure(let error): throw error
        }
    }

    func setFetchRootContentsResult(_ result: Result<(folders: [Folder], documents: [Document]), Error>) {
        fetchRootContentsResult = result
    }

    func setFetchRecentDocumentsResult(_ result: Result<[Document], Error>) {
        fetchRecentDocumentsResult = result
    }
}

private enum TestError: LocalizedError {
    case network
    var errorDescription: String? { "Network error" }
}

@MainActor
final class DocumentsStoreTests: XCTestCase {
    private var documentService: SpyDocumentService!
    private var store: DocumentsStore!

    override func setUp() async throws {
        try await super.setUp()
        try? await CacheManager.shared.clearAll()
        documentService = SpyDocumentService()
        store = DocumentsStore(
            state: DocumentsState(),
            effectHandler: DocumentsEffectHandler(documentService: documentService)
        )
    }

    override func tearDown() {
        store = nil
        documentService = nil
        super.tearDown()
    }

    private func waitForEffects() async {
        try? await Task.sleep(nanoseconds: 150_000_000)
        await Task.yield()
    }

    func test_onAppear_success_loadsFoldersAndDocuments() async {
        let folders = [Folder(name: "Work", documentsCount: 2)]
        let docs = [Document(name: "file.pdf", type: .pdf)]
        await documentService.setFetchRootContentsResult(.success((folders, docs)))
        await documentService.setFetchRecentDocumentsResult(.success([]))

        store.send(.onAppear)

        XCTAssertTrue(store.state.isLoading)

        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertEqual(store.state.folders.count, 1)
        XCTAssertEqual(store.state.rootDocuments.count, 1)
        XCTAssertNil(store.state.error)
    }

    func test_onAppear_failure_showsError() async {
        await documentService.setFetchRootContentsResult(.failure(TestError.network))

        store.send(.onAppear)

        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertNotNil(store.state.error)
    }

    func test_folderTapped_setsSelectedFolder() {
        let folder = Folder(nodeId: 1, name: "Docs", documentsCount: 3)

        store.send(.folderTapped(folder))

        XCTAssertEqual(store.state.selectedFolder?.name, "Docs")
        XCTAssertTrue(store.state.isLoading)
    }

    func test_backFromFolder_clearsSelection() {
        let folder = Folder(nodeId: 1, name: "Docs", documentsCount: 0)
        store.send(.folderTapped(folder))

        store.send(.backFromFolder)

        XCTAssertNil(store.state.selectedFolder)
        XCTAssertTrue(store.state.folderContentsFolders.isEmpty)
        XCTAssertTrue(store.state.folderContentsDocuments.isEmpty)
    }

    func test_createFolderTapped_showsSheet() {
        store.send(.createFolderTapped)

        XCTAssertTrue(store.state.showingCreateFolderSheet)
        XCTAssertNil(store.state.error)
    }

    func test_uploadFileTapped_showsSheet() {
        store.send(.uploadFileTapped)

        XCTAssertTrue(store.state.showingUploadSheet)
    }

    func test_createNoteTapped_showsSheet() {
        store.send(.createNoteTapped)

        XCTAssertTrue(store.state.showingCreateNoteSheet)
    }

    func test_dismissSheet_hidesAllSheets() {
        store.send(.createFolderTapped)
        store.send(.uploadFileTapped)

        store.send(.dismissSheet)

        XCTAssertFalse(store.state.showingCreateFolderSheet)
        XCTAssertFalse(store.state.showingUploadSheet)
        XCTAssertFalse(store.state.showingCreateNoteSheet)
        XCTAssertFalse(store.state.showingEditNoteSheet)
        XCTAssertNil(store.state.editingNote)
    }

    func test_renameFolderTapped_setsFolderToRename() {
        let folder = Folder(name: "Old", documentsCount: 1)

        store.send(.renameFolderTapped(folder))

        XCTAssertEqual(store.state.folderToRename?.name, "Old")
    }

    func test_commitFolderRename_clearsFolderToRename() {
        let folder = Folder(name: "Old", documentsCount: 0)
        store.send(.renameFolderTapped(folder))

        store.send(.commitFolderRename("  New  "))

        XCTAssertNil(store.state.folderToRename)
    }

    func test_clearError_clearsError() async {
        await documentService.setFetchRootContentsResult(.failure(TestError.network))
        store.send(.onAppear)
        await waitForEffects()
        XCTAssertNotNil(store.state.error)

        store.send(.clearError)

        XCTAssertNil(store.state.error)
    }

    func test_retryTapped_clearsErrorAndReloads() async {
        await documentService.setFetchRootContentsResult(.failure(TestError.network))
        store.send(.onAppear)
        await waitForEffects()
        XCTAssertNotNil(store.state.error)

        let folders = [Folder(name: "Recovered")]
        await documentService.setFetchRootContentsResult(.success((folders, [])))
        await documentService.setFetchRecentDocumentsResult(.success([]))

        store.send(.retryTapped)
        XCTAssertNil(store.state.error)
        XCTAssertTrue(store.state.isLoading)

        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertEqual(store.state.folders.first?.name, "Recovered")
    }

    func test_deleteFolderTapped_setsFolderToDelete() {
        let folder = Folder(name: "ToDelete")

        store.send(.deleteFolderTapped(folder))

        XCTAssertEqual(store.state.folderToDelete?.name, "ToDelete")
    }

    func test_dismissDeleteFolderConfirmation_clearsFolderToDelete() {
        let folder = Folder(name: "ToDelete")
        store.send(.deleteFolderTapped(folder))

        store.send(.dismissDeleteFolderConfirmation)

        XCTAssertNil(store.state.folderToDelete)
    }
}
