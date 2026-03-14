//
//  DocumentsView.swift
//  InterPrep
//
//  Documents main view
//

import SwiftUI
import QuickLook
import DesignSystem

struct DocumentsView: View {
    let model: Model
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Мои папки
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Мои папки")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.textOnBackground)
                        
                        if model.isLoading && model.folders.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ],
                                spacing: 16
                            ) {
                                ForEach(model.folders) { folder in
                                    FolderCardView(folder: folder)
                                        .onTapGesture {
                                            model.onFolderTap(folder)
                                        }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Недавнее
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Недавнее")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.textOnBackground)
                        
                        if model.recentDocuments.isEmpty {
                            Text("Нет недавних документов")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            VStack(spacing: 12) {
                                ForEach(model.recentDocuments) { document in
                                    DocumentRowView(document: document)
                                        .onTapGesture {
                                            model.onDocumentTap(document)
                                        }
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                model.onDocumentDelete(document)
                                            } label: {
                                                Label("Удалить", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Документы")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            model.onUploadFileTap()
                        } label: {
                            Label("Загрузить файл", systemImage: "arrow.up.doc")
                        }
                        
                        Button {
                            model.onCreateNoteTap()
                        } label: {
                            Label("Создать заметку", systemImage: "note.text.badge.plus")
                        }
                        
                        Button {
                            model.onCreateFolderTap()
                        } label: {
                            Label("Создать папку", systemImage: "folder.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.brandPrimary)
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: .constant(model.showingCreateFolderSheet)) {
                CreateFolderSheet(
                    onDismiss: model.onDismissSheet,
                    onCreate: model.onFolderCreate
                )
            }
            .sheet(isPresented: .constant(model.showingUploadSheet)) {
                UploadFileSheet(
                    onDismiss: model.onDismissSheet,
                    onFileSelected: model.onFileUpload
                )
            }
            .sheet(isPresented: Binding(
                get: { model.documentURLToOpen != nil },
                set: { if !$0 { model.onClearDocumentToOpen() } }
            )) {
                if let url = model.documentURLToOpen {
                    DocumentPreviewSheet(url: url, onDismiss: model.onClearDocumentToOpen)
                }
            }
        }
    }
}

// MARK: - Document Preview (QuickLook)

struct DocumentPreviewSheet: View {
    let url: URL
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            QuickLookPreview(url: url)
                .navigationTitle(url.lastPathComponent)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Готово") {
                            onDismiss()
                        }
                    }
                }
        }
    }
}

struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(url: URL) { self.url = url }
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as QLPreviewItem
        }
    }
}

// MARK: - Model

extension DocumentsView {
    struct Model {
        let folders: [Folder]
        let recentDocuments: [Document]
        let isLoading: Bool
        let showingCreateFolderSheet: Bool
        let showingUploadSheet: Bool
        let documentURLToOpen: URL?
        let onFolderTap: (Folder) -> Void
        let onDocumentTap: (Document) -> Void
        let onCreateFolderTap: () -> Void
        let onUploadFileTap: () -> Void
        let onCreateNoteTap: () -> Void
        let onDismissSheet: () -> Void
        let onFolderCreate: (String) -> Void
        let onFileUpload: (URL) -> Void
        let onDocumentDelete: (Document) -> Void
        let onClearDocumentToOpen: () -> Void
    }
}

// MARK: - Preview

#Preview {
    DocumentsView(
        model: .init(
            folders: [
                Folder(name: "Базы данных", documentsCount: 12, color: .blue),
                Folder(name: "Резюме", documentsCount: 5, color: .green),
                Folder(name: "Проекты", documentsCount: 8, color: .orange)
            ],
            recentDocuments: [
                Document(
                    name: "Резюме iOS Developer.pdf",
                    type: .pdf,
                    size: 245_760
                ),
                Document(
                    name: "Заметки.txt",
                    type: .note,
                    size: 12_288
                )
            ],
            isLoading: false,
            showingCreateFolderSheet: false,
            showingUploadSheet: false,
            documentURLToOpen: nil,
            onFolderTap: { _ in },
            onDocumentTap: { _ in },
            onCreateFolderTap: {},
            onUploadFileTap: {},
            onCreateNoteTap: {},
            onDismissSheet: {},
            onFolderCreate: { _ in },
            onFileUpload: { _ in },
            onDocumentDelete: { _ in },
            onClearDocumentToOpen: {}
        )
    )
}
