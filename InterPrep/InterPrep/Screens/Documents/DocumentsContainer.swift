//
//  DocumentsContainer.swift
//  InterPrep
//
//  Documents container
//

import SwiftUI
import ArchitectureCore

public struct DocumentsContainer: View {
    public typealias DocumentsStore = Store<DocumentsState, DocumentsEffectHandler>
    
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
            documentURLToOpen: store.state.documentURLToOpen,
            onFolderTap: { folder in
                store.send(.folderTapped(folder))
            },
            onDocumentTap: { document in
                store.send(.documentTapped(document))
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
