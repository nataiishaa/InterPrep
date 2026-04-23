//
//  ResumeUploadStateTests.swift
//  ResumeUploadFeatureTests
//
//  Unit tests for ResumeUploadState reducer (Store state logic)
//

import ArchitectureCore
@testable import ResumeUploadFeature
import XCTest

@MainActor
final class ResumeUploadStateTests: XCTestCase {

    func testFileSelected_returnsValidateFile() {
        var state = ResumeUploadState()
        state.errorMessage = "Old error"
        let url = URL(fileURLWithPath: "/tmp/doc.pdf")

        let effect = ResumeUploadState.reduce(state: &state, with: .input(.fileSelected(url)))

        XCTAssertNil(state.errorMessage)
        guard case .validateFile(let fileURL) = effect else {
            XCTFail("Expected validateFile")
            return
        }
        XCTAssertEqual(fileURL, url)
    }

    func testUploadTapped_whenNoFile_returnsNil() {
        var state = ResumeUploadState()
        state.selectedFile = nil

        let effect = ResumeUploadState.reduce(state: &state, with: .input(.uploadTapped))

        XCTAssertNil(effect)
    }

    func testUploadTapped_whenFileSelected_returnsUploadFile() {
        var state = ResumeUploadState()
        let file = ResumeUploadState.SelectedFile(
            name: "cv.pdf",
            size: 1024,
            url: URL(fileURLWithPath: "/tmp/cv.pdf"),
            type: .pdf
        )
        state.selectedFile = file
        state.uploadStatus = .selected

        let effect = ResumeUploadState.reduce(state: &state, with: .input(.uploadTapped))

        XCTAssertEqual(state.uploadStatus, .uploading)
        XCTAssertEqual(state.uploadProgress, 0.0)
        guard case .uploadFile(let uploadedFile) = effect else {
            XCTFail("Expected uploadFile")
            return
        }
        XCTAssertEqual(uploadedFile.name, "cv.pdf")
    }

    func testRemoveFileTapped_resetsState() {
        var state = ResumeUploadState()
        state.selectedFile = ResumeUploadState.SelectedFile(
            name: "x",
            size: 0,
            url: URL(fileURLWithPath: "/x"),
            type: .pdf
        )
        state.uploadStatus = .selected
        state.uploadProgress = 0.5
        state.errorMessage = "Err"

        _ = ResumeUploadState.reduce(state: &state, with: .input(.removeFileTapped))

        XCTAssertNil(state.selectedFile)
        XCTAssertEqual(state.uploadStatus, .idle)
        XCTAssertEqual(state.uploadProgress, 0.0)
        XCTAssertNil(state.errorMessage)
    }

    func testCancelTapped_whenUploading_returnsCancelUpload() {
        var state = ResumeUploadState()
        state.uploadStatus = .uploading

        let effect = ResumeUploadState.reduce(state: &state, with: .input(.cancelTapped))

        guard case .cancelUpload = effect else {
            XCTFail("Expected cancelUpload")
            return
        }
    }

    func testCancelTapped_whenIdle_returnsNavigateBack() {
        var state = ResumeUploadState()
        state.uploadStatus = .idle

        let effect = ResumeUploadState.reduce(state: &state, with: .input(.cancelTapped))

        guard case .navigateBack = effect else {
            XCTFail("Expected navigateBack")
            return
        }
    }

    func testSkipTapped_returnsNavigateToMain() {
        var state = ResumeUploadState()

        let effect = ResumeUploadState.reduce(state: &state, with: .input(.skipTapped))

        guard case .navigateToMain = effect else {
            XCTFail("Expected navigateToMain")
            return
        }
    }

    func testFeedback_fileValidated_setsSelectedAndStatus() {
        var state = ResumeUploadState()
        let file = ResumeUploadState.SelectedFile(
            name: "r.pdf",
            size: 100,
            url: URL(fileURLWithPath: "/r.pdf"),
            type: .pdf
        )

        _ = ResumeUploadState.reduce(state: &state, with: .feedback(.fileValidated(file)))

        XCTAssertEqual(state.selectedFile?.name, "r.pdf")
        XCTAssertEqual(state.uploadStatus, .selected)
    }

    func testFeedback_uploadCompleted_setsSuccess() {
        var state = ResumeUploadState()
        state.uploadStatus = .uploading
        state.uploadProgress = 0.5

        _ = ResumeUploadState.reduce(state: &state, with: .feedback(.uploadCompleted))

        XCTAssertEqual(state.uploadStatus, .success)
        XCTAssertEqual(state.uploadProgress, 1.0)
    }

    func testFeedback_uploadFailed_setsFailedAndError() {
        var state = ResumeUploadState()
        state.uploadStatus = .uploading

        _ = ResumeUploadState.reduce(state: &state, with: .feedback(.uploadFailed("Network error")))

        XCTAssertEqual(state.uploadStatus, .failed)
        XCTAssertEqual(state.errorMessage, "Network error")
        XCTAssertEqual(state.uploadProgress, 0.0)
    }
}
