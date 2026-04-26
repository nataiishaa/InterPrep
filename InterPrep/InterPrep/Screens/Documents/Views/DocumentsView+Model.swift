//
//  DocumentsView+Model.swift
//  InterPrep
//
//  Documents view model
//

import Foundation

extension DocumentsView {
    struct Model {
        let folders: [Folder]
        let rootDocuments: [Document]
        let recentDocuments: [Document]
        let selectedFolder: Folder?
        let folderContentsFolders: [Folder]
        let folderContentsDocuments: [Document]
        let isLoading: Bool
        let error: String?
        let isOfflineMode: Bool
        let showingCreateFolderSheet: Bool
        let folderToRename: Folder?
        let folderToDelete: Folder?
        let showingUploadSheet: Bool
        let showingCreateNoteSheet: Bool
        let showingEditNoteSheet: Bool
        let editingNote: Document?
        let documentURLToOpen: URL?
        let onFolderTap: (Folder) -> Void
        let onBackFromFolder: () -> Void
        let onDocumentTap: (Document) -> Void
        let onCreateFolderTap: () -> Void
        let onUploadFileTap: () -> Void
        let onCreateNoteTap: () -> Void
        let onDismissSheet: () -> Void
        let onFolderCreate: (String) -> Void
        let onRenameFolderTap: (Folder) -> Void
        let onCommitFolderRename: (String) -> Void
        let onCancelFolderRename: () -> Void
        let onDeleteFolderTap: (Folder) -> Void
        let onConfirmDeleteFolder: (Folder) -> Void
        let onDismissDeleteFolderConfirmation: () -> Void
        let onFileUpload: (URL) -> Void
        let onNoteCreate: (String, String) -> Void
        let onNoteUpdate: (Document, String, String) -> Void
        let onEditNoteTap: (Document) -> Void
        let onDocumentDelete: (Document) -> Void
        let onClearDocumentToOpen: () -> Void
        let onClearError: () -> Void
        let onRetry: () -> Void
    }
}
