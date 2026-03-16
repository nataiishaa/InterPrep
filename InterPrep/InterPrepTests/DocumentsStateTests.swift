//
//  DocumentsStateTests.swift
//  InterPrepTests
//
//  Unit tests for DocumentsState reducer (Store state logic)
//

import XCTest
import ArchitectureCore
@testable import DocumentsFeature

@MainActor
final class DocumentsStateTests: XCTestCase {

    func testOnAppear_returnsLoadFolders() {
        var state = DocumentsState()

        let effect = DocumentsState.reduce(state: &state, with: .input(.onAppear))

        XCTAssertTrue(state.isLoading)
        guard case .loadFolders = effect else {
            XCTFail("Expected loadFolders")
            return
        }
    }

    func testFolderTapped_setsSelectedAndReturnsLoadContents() {
        var state = DocumentsState()
        let folder = Folder(name: "Work", documentsCount: 2)

        let effect = DocumentsState.reduce(state: &state, with: .input(.folderTapped(folder)))

        XCTAssertEqual(state.selectedFolder?.name, "Work")
        XCTAssertTrue(state.isLoading)
        guard case .loadFolderContents(let f) = effect else {
            XCTFail("Expected loadFolderContents")
            return
        }
        XCTAssertEqual(f.name, "Work")
    }

    func testBackFromFolder_clearsSelection() {
        var state = DocumentsState()
        state.selectedFolder = Folder(name: "X", documentsCount: 0)
        state.folderContentsFolders = [Folder(name: "Y", documentsCount: 0)]
        state.folderContentsDocuments = []

        _ = DocumentsState.reduce(state: &state, with: .input(.backFromFolder))

        XCTAssertNil(state.selectedFolder)
        XCTAssertTrue(state.folderContentsFolders.isEmpty)
        XCTAssertTrue(state.folderContentsDocuments.isEmpty)
    }

    func testCreateFolderTapped_showsSheet() {
        var state = DocumentsState()
        state.error = "Err"

        _ = DocumentsState.reduce(state: &state, with: .input(.createFolderTapped))

        XCTAssertTrue(state.showingCreateFolderSheet)
        XCTAssertNil(state.error)
    }

    func testDismissSheet_hidesAllSheets() {
        var state = DocumentsState()
        state.showingCreateFolderSheet = true
        state.folderToRename = Folder(name: "R", documentsCount: 0)
        state.showingUploadSheet = true
        state.showingEditNoteSheet = true
        state.editingNote = nil

        _ = DocumentsState.reduce(state: &state, with: .input(.dismissSheet))

        XCTAssertFalse(state.showingCreateFolderSheet)
        XCTAssertNil(state.folderToRename)
        XCTAssertFalse(state.showingUploadSheet)
        XCTAssertFalse(state.showingEditNoteSheet)
        XCTAssertNil(state.editingNote)
    }

    func testRenameFolderTapped_setsFolderToRename() {
        var state = DocumentsState()
        let folder = Folder(name: "Old", documentsCount: 1)

        _ = DocumentsState.reduce(state: &state, with: .input(.renameFolderTapped(folder)))

        XCTAssertEqual(state.folderToRename?.name, "Old")
    }

    func testCommitFolderRename_whenFolderToRenameSet_returnsRenameFolder() {
        var state = DocumentsState()
        let folder = Folder(name: "Old", documentsCount: 0)
        state.folderToRename = folder

        let effect = DocumentsState.reduce(state: &state, with: .input(.commitFolderRename("  New  ")))

        XCTAssertNil(state.folderToRename)
        guard case .renameFolder(let f, let name) = effect else {
            XCTFail("Expected renameFolder")
            return
        }
        XCTAssertEqual(f.name, "Old")
        XCTAssertEqual(name, "New")
    }

    func testClearError_clearsError() {
        var state = DocumentsState()
        state.error = "Something"

        _ = DocumentsState.reduce(state: &state, with: .input(.clearError))

        XCTAssertNil(state.error)
    }

    func testFeedback_foldersLoaded_updatesState() {
        var state = DocumentsState()
        state.isLoading = true
        state.error = "Err"
        let folders = [Folder(name: "F1", documentsCount: 0)]

        _ = DocumentsState.reduce(state: &state, with: .feedback(.foldersLoaded(folders)))

        XCTAssertEqual(state.folders.count, 1)
        XCTAssertEqual(state.folders[0].name, "F1")
        XCTAssertFalse(state.isLoading)
        XCTAssertNil(state.error)
    }

    func testFeedback_loadingFailed_setsError() {
        var state = DocumentsState()
        state.isLoading = true

        _ = DocumentsState.reduce(state: &state, with: .feedback(.loadingFailed("Network error")))

        XCTAssertFalse(state.isLoading)
        XCTAssertEqual(state.error, "Network error")
    }
}
