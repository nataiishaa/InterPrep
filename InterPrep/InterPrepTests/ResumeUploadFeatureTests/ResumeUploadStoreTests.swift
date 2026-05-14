import ArchitectureCore
@testable import ResumeUploadFeature
import XCTest

private actor SpyFileUploadService: FileUploading {
    var validateFileResult: Result<ResumeUploadState.SelectedFile, Error> = .success(
        ResumeUploadState.SelectedFile(
            name: "resume.pdf",
            size: 2048,
            url: URL(fileURLWithPath: "/tmp/resume.pdf"),
            type: .pdf
        )
    )
    var uploadFileResult: Result<ResumeSessionInfo, Error> = .success(
        ResumeSessionInfo(sessionId: "session-123", questions: [], status: "completed")
    )

    var validateFileCallCount = 0
    var uploadFileCallCount = 0

    func validateFile(_ url: URL) async throws -> ResumeUploadState.SelectedFile {
        validateFileCallCount += 1
        switch validateFileResult {
        case .success(let file): return file
        case .failure(let error): throw error
        }
    }

    func uploadFile(_ file: ResumeUploadState.SelectedFile) async throws -> ResumeSessionInfo {
        uploadFileCallCount += 1
        switch uploadFileResult {
        case .success(let session): return session
        case .failure(let error): throw error
        }
    }

    func setValidateFileResult(_ result: Result<ResumeUploadState.SelectedFile, Error>) {
        validateFileResult = result
    }

    func setUploadFileResult(_ result: Result<ResumeSessionInfo, Error>) {
        uploadFileResult = result
    }
}

private enum TestError: LocalizedError {
    case validation
    case upload

    var errorDescription: String? {
        switch self {
        case .validation: return "Invalid file"
        case .upload: return "Upload failed"
        }
    }
}

@MainActor
final class ResumeUploadStoreTests: XCTestCase {
    private var fileService: SpyFileUploadService!
    private var store: ResumeUploadStore!

    override func setUp() {
        super.setUp()
        fileService = SpyFileUploadService()
        store = ResumeUploadStore(
            state: ResumeUploadState(),
            effectHandler: ResumeUploadEffectHandler(fileService: fileService)
        )
    }

    override func tearDown() {
        store = nil
        fileService = nil
        super.tearDown()
    }

    private func waitForEffects() async {
        try? await Task.sleep(nanoseconds: 100_000_000)
        await Task.yield()
    }

    func test_fileSelected_success_setsSelectedFileAndStatus() async {
        let url = URL(fileURLWithPath: "/tmp/resume.pdf")

        store.send(.fileSelected(url))

        await waitForEffects()

        XCTAssertEqual(store.state.selectedFile?.name, "resume.pdf")
        XCTAssertEqual(store.state.selectedFile?.size, 2048)
        XCTAssertEqual(store.state.uploadStatus, .selected)
        XCTAssertNil(store.state.errorMessage)
        let callCount = await fileService.validateFileCallCount
        XCTAssertEqual(callCount, 1)
    }

    func test_fileSelected_validationFails_setsErrorAndFailedStatus() async {
        await fileService.setValidateFileResult(.failure(TestError.validation))
        let url = URL(fileURLWithPath: "/tmp/bad.xyz")

        store.send(.fileSelected(url))

        await waitForEffects()

        XCTAssertNil(store.state.selectedFile)
        XCTAssertEqual(store.state.uploadStatus, .failed)
        XCTAssertEqual(store.state.errorMessage, "Invalid file")
    }

    func test_uploadTapped_withoutFile_doesNothing() async {
        store.send(.uploadTapped)

        await waitForEffects()

        XCTAssertEqual(store.state.uploadStatus, .idle)
        XCTAssertNil(store.state.selectedFile)
        let callCount = await fileService.uploadFileCallCount
        XCTAssertEqual(callCount, 0)
    }

    func test_uploadTapped_withFile_success_setsSuccessAndProgress() async {
        let url = URL(fileURLWithPath: "/tmp/resume.pdf")
        store.send(.fileSelected(url))
        await waitForEffects()

        XCTAssertEqual(store.state.uploadStatus, .selected)

        store.send(.uploadTapped)

        XCTAssertEqual(store.state.uploadStatus, .uploading)
        XCTAssertEqual(store.state.uploadProgress, 0.0)

        await waitForEffects()

        XCTAssertEqual(store.state.uploadStatus, .success)
        XCTAssertEqual(store.state.uploadProgress, 1.0)
        XCTAssertNil(store.state.errorMessage)
        let callCount = await fileService.uploadFileCallCount
        XCTAssertEqual(callCount, 1)
    }

    func test_uploadTapped_withFile_failure_setsFailedAndError() async {
        let url = URL(fileURLWithPath: "/tmp/resume.pdf")
        store.send(.fileSelected(url))
        await waitForEffects()

        await fileService.setUploadFileResult(.failure(TestError.upload))

        store.send(.uploadTapped)

        await waitForEffects()

        XCTAssertEqual(store.state.uploadStatus, .failed)
        XCTAssertEqual(store.state.errorMessage, "Upload failed")
        XCTAssertEqual(store.state.uploadProgress, 0.0)
    }

    func test_removeFileTapped_resetsState() async {
        let url = URL(fileURLWithPath: "/tmp/resume.pdf")
        store.send(.fileSelected(url))
        await waitForEffects()

        XCTAssertNotNil(store.state.selectedFile)

        store.send(.removeFileTapped)

        XCTAssertNil(store.state.selectedFile)
        XCTAssertEqual(store.state.uploadStatus, .idle)
        XCTAssertEqual(store.state.uploadProgress, 0.0)
        XCTAssertNil(store.state.errorMessage)
    }

    func test_cancelTapped_whenUploading_triggersCancelUpload() async {
        let url = URL(fileURLWithPath: "/tmp/resume.pdf")
        store.send(.fileSelected(url))
        await waitForEffects()

        store.send(.uploadTapped)

        XCTAssertEqual(store.state.uploadStatus, .uploading)

        store.send(.cancelTapped)

        await waitForEffects()
    }

    func test_cancelTapped_whenIdle_triggersNavigateBack() async {
        XCTAssertEqual(store.state.uploadStatus, .idle)

        store.send(.cancelTapped)

        await waitForEffects()

        XCTAssertEqual(store.state.uploadStatus, .idle)
    }

    func test_skipTapped_triggersNavigateToMain() async {
        store.send(.skipTapped)

        await waitForEffects()

        XCTAssertEqual(store.state.uploadStatus, .idle)
    }
}
