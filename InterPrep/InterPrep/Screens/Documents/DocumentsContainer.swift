//
//  DocumentsContainer.swift
//  InterPrep
//
//  Documents container
//

import SwiftUI
import ArchitectureCore

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
    
    // MARK: - Make Model
    
    private func makeModel() -> DocumentsView.Model {
        .init(
            folders: store.state.folders,
            recentDocuments: store.state.recentDocuments,
            isLoading: store.state.isLoading,
            showingCreateFolderSheet: store.state.showingCreateFolderSheet,
            showingUploadSheet: store.state.showingUploadSheet,
            showingCreateNoteSheet: store.state.showingCreateNoteSheet,
            showingEditNoteSheet: store.state.showingEditNoteSheet,
            editingNote: store.state.editingNote,
            documentURLToOpen: store.state.documentURLToOpen,
            onFolderTap: { folder in
                store.send(.folderTapped(folder))
            },
            onDocumentTap: { document in
                if document.isNote {
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
            onFileUpload: { url in
                store.send(.fileUploaded(url, folderId: nil))
            },
            onNoteCreate: { title, content in
                store.send(.noteCreated(title, content))
            },
            onNoteUpdate: { document, content in
                store.send(.noteUpdated(document, content))
            },
            onEditNoteTap: { document in
                store.send(.editNoteTapped(document))
            },
            onDocumentDelete: { document in
                store.send(.documentDeleted(document))
            },
            onClearDocumentToOpen: {
                store.send(.clearDocumentToOpen)
            }
        )
    }
}

// MARK: - Preview

#Preview {
    DocumentsContainer(store: Store(
        state: DocumentsState(),
        effectHandler: DocumentsEffectHandler(
            documentService: DocumentServiceImpl()
        )
    ))
}
