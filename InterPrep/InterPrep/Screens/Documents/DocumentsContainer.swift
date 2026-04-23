//
//  DocumentsContainer.swift
//  InterPrep
//
//  Documents container
//

import ArchitectureCore
import SwiftUI

public struct DocumentsContainer: View {
    @StateObject private var store: DocumentsStore
    
    public init(store: @autoclosure @escaping () -> DocumentsStore) {
        _store = StateObject(wrappedValue: store())
    }
    
    public var body: some View {
        DocumentsView(model: makeModel())
            .task {
                store.send(.onAppear)
            }
    }
    
    // swiftlint:disable:next function_body_length
    private func makeModel() -> DocumentsView.Model {
        .init(
            folders: store.state.folders,
            recentDocuments: store.state.recentDocuments,
            selectedFolder: store.state.selectedFolder,
            folderContentsFolders: store.state.folderContentsFolders,
            folderContentsDocuments: store.state.folderContentsDocuments,
            isLoading: store.state.isLoading,
            error: store.state.error,
            isOfflineMode: store.state.isOfflineMode,
            showingCreateFolderSheet: store.state.showingCreateFolderSheet,
            folderToRename: store.state.folderToRename,
            folderToDelete: store.state.folderToDelete,
            showingUploadSheet: store.state.showingUploadSheet,
            showingCreateNoteSheet: store.state.showingCreateNoteSheet,
            showingEditNoteSheet: store.state.showingEditNoteSheet,
            editingNote: store.state.editingNote,
            documentURLToOpen: store.state.documentURLToOpen,
            onFolderTap: { folder in
                store.send(.folderTapped(folder))
            },
            onBackFromFolder: {
                store.send(.backFromFolder)
            },
            onDocumentTap: { document in
                if document.isNote || document.type == .other {
                    store.send(.editNoteTapped(document))
                } else {
                    store.send(.documentTapped(document))
                }
            },
            onCreateFolderTap: {
                store.send(.createFolderTapped)
            },
            onUploadFileTap: {
                store.send(.uploadFileTapped)
            },
            onCreateNoteTap: {
                store.send(.createNoteTapped)
            },
            onDismissSheet: {
                store.send(.dismissSheet)
            },
            onFolderCreate: { name in
                store.send(.folderCreated(name))
            },
            onRenameFolderTap: { folder in
                store.send(.renameFolderTapped(folder))
            },
            onCommitFolderRename: { name in
                store.send(.commitFolderRename(name))
            },
            onCancelFolderRename: {
                store.send(.cancelFolderRename)
            },
            onDeleteFolderTap: { folder in
                store.send(.deleteFolderTapped(folder))
            },
            onConfirmDeleteFolder: { folder in
                store.send(.confirmDeleteFolder(folder))
            },
            onDismissDeleteFolderConfirmation: {
                store.send(.dismissDeleteFolderConfirmation)
            },
            onFileUpload: { url in
                store.send(.fileUploaded(url, folderId: store.state.selectedFolder?.id))
            },
            onNoteCreate: { title, content in
                store.send(.noteCreated(title, content))
            },
            onNoteUpdate: { document, newName, content in
                store.send(.noteUpdated(document, newName, content))
            },
            onEditNoteTap: { document in
                store.send(.editNoteTapped(document))
            },
            onDocumentDelete: { document in
                store.send(.documentDeleted(document))
            },
            onClearDocumentToOpen: {
                store.send(.clearDocumentToOpen)
            },
            onClearError: {
                store.send(.clearError)
            }
        )
    }
}

#Preview {
    DocumentsContainer(store: Store(
        state: DocumentsState(),
        effectHandler: DocumentsEffectHandler(
            documentService: DocumentServiceImpl()
        )
    ))
}
