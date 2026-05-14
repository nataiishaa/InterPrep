import DesignSystem
import NetworkMonitorService
import QuickLook
import SwiftUI

struct DocumentsView: View {
    let model: Model
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @State private var showOfflineToast = false
    @Environment(\.colorScheme) var colorScheme

    private var hasAnyData: Bool {
        !model.folders.isEmpty || !model.rootDocuments.isEmpty || !model.recentDocuments.isEmpty
    }

    private var isOffline: Bool {
        !networkMonitor.isConnected || model.isOfflineMode
    }

    private func guardOffline(action: @escaping () -> Void) {
        if isOffline {
            showOfflineToast = true
            Task {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                showOfflineToast = false
            }
        } else {
            action()
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Layout.rootStackSpacing) {
                if model.isOfflineMode {
                    OfflineBanner(showCachedHint: true)
                }
                Group {
                    if let errorMessage = model.error, !hasAnyData {
                        NoConnectionView(
                            onRetry: model.onRetry,
                            message: errorMessage,
                            subtitle: "Попробуйте позже"
                        )
                    } else if let folder = model.selectedFolder {
                        folderContentView(folder: folder)
                    } else {
                        rootContentView
                    }
                }
            }
            .background(Color.backgroundPrimary)
            .navigationTitle(model.selectedFolder?.name ?? "Документы")
            .navigationBarTitleDisplayMode(model.selectedFolder != nil ? .inline : .large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if model.selectedFolder != nil {
                        Button { model.onBackFromFolder() } label: {
                            Image(systemName: "chevron.left")
                            Text("Назад")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { guardOffline { model.onUploadFileTap() } } label: {
                            Label("Загрузить файл", systemImage: "arrow.up.doc")
                        }
                        .disabled(isOffline)
                        Button { guardOffline { model.onCreateNoteTap() } } label: {
                            Label("Создать заметку", systemImage: "note.text.badge.plus")
                        }
                        .disabled(isOffline)
                        Button { model.onCreateFolderTap() } label: {
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
        }
        .overlay(alignment: .bottom) {
            if showOfflineToast {
                Text("Нет интернета — действие недоступно")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, Layout.toastHorizontalPadding)
                    .padding(.vertical, Layout.toastVerticalPadding)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(Layout.toastCornerRadius)
                    .padding(.bottom, Layout.toastBottomPadding)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: Layout.overlayAnimationDuration), value: showOfflineToast)
        .sheet(isPresented: Binding(get: { model.showingCreateFolderSheet }, set: { if !$0 { model.onDismissSheet() } })) {
            CreateFolderSheet(onDismiss: model.onDismissSheet, onCreate: model.onFolderCreate)
        }
        .sheet(isPresented: Binding(get: { model.folderToRename != nil }, set: { if !$0 { model.onCancelFolderRename() } })) {
            renameFolderSheet
        }
        .sheet(isPresented: Binding(get: { model.showingUploadSheet }, set: { if !$0 { model.onDismissSheet() } })) {
            UploadFileSheet(onDismiss: model.onDismissSheet, onFileSelected: model.onFileUpload)
        }
        .sheet(isPresented: Binding(get: { model.showingCreateNoteSheet }, set: { if !$0 { model.onDismissSheet() } })) {
            CreateNoteSheet(onDismiss: model.onDismissSheet, onCreate: model.onNoteCreate)
        }
        .sheet(isPresented: Binding(get: { model.showingEditNoteSheet }, set: { if !$0 { model.onDismissSheet() } })) {
            if let note = model.editingNote {
                EditNoteSheet(
                    document: note,
                    onDismiss: model.onDismissSheet,
                    onSave: model.onNoteUpdate,
                    onDelete: {
                        model.onDismissSheet()
                        model.onDocumentDelete(note)
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: Binding(get: { model.documentURLToOpen != nil }, set: { if !$0 { model.onClearDocumentToOpen() } })) {
            if let url = model.documentURLToOpen {
                DocumentPreviewSheet(url: url, onDismiss: model.onClearDocumentToOpen)
            }
        }
        .alert("Удалить папку?", isPresented: Binding(get: { model.folderToDelete != nil }, set: { if !$0 { model.onDismissDeleteFolderConfirmation() } })) {
            Button("Отмена", role: .cancel) { model.onDismissDeleteFolderConfirmation() }
            Button("Удалить", role: .destructive) {
                if let folder = model.folderToDelete { model.onConfirmDeleteFolder(folder) }
            }
        } message: {
            if let folder = model.folderToDelete {
                Text("Папка «\(folder.name)» и всё её содержимое будут удалены. Это действие нельзя отменить.")
            }
        }
        .alert("Ошибка", isPresented: Binding(get: { model.error != nil && hasAnyData }, set: { if !$0 { model.onClearError() } })) {
            Button("OK", role: .cancel) { model.onClearError() }
        } message: {
            if let error = model.error { Text(error) }
        }
    }

    @ViewBuilder
    private var renameFolderSheet: some View {
        if let folder = model.folderToRename {
            DocumentsRenameFolderSheet(folder: folder, onSave: model.onCommitFolderRename, onDismiss: model.onCancelFolderRename)
        }
    }

    private var rootContentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                if model.isLoading && model.folders.isEmpty && model.rootDocuments.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else if model.folders.isEmpty && model.rootDocuments.isEmpty && model.recentDocuments.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text("Хранилище пусто")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Text("Создайте папку или загрузите файл")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    if !model.folders.isEmpty {
                        folderGridSection(title: "Папки", folders: model.folders)
                    }

                    if !model.rootDocuments.isEmpty {
                        documentListSection(title: model.folders.isEmpty ? nil : "Файлы", documents: model.rootDocuments)
                    }

                    if !model.recentDocuments.isEmpty {
                        documentListSection(title: "Недавнее", documents: model.recentDocuments, showDate: true)
                    }
                }
            }
        }
    }

    private func folderContentView(folder: Folder) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                if model.isLoading && model.folderContentsFolders.isEmpty && model.folderContentsDocuments.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else if model.folderContentsFolders.isEmpty && model.folderContentsDocuments.isEmpty {
                    Text("Папка пуста")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                } else {
                    if !model.folderContentsFolders.isEmpty {
                        folderGridSection(title: nil, folders: model.folderContentsFolders)
                    }

                    if !model.folderContentsDocuments.isEmpty {
                        documentListSection(title: model.folderContentsFolders.isEmpty ? nil : "Файлы", documents: model.folderContentsDocuments)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func folderGridSection(title: String?, folders: [Folder]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .padding(.horizontal)
                    .padding(.top, 16)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                ForEach(folders) { folder in
                    FolderCardView(folder: folder)
                        .onTapGesture(count: 2) { if !isOffline { model.onRenameFolderTap(folder) } }
                        .onTapGesture(count: 1) { model.onFolderTap(folder) }
                        .contextMenu {
                            Button { model.onRenameFolderTap(folder) } label: {
                                Label("Переименовать", systemImage: "pencil")
                            }
                            .disabled(isOffline)
                            Button(role: .destructive) { model.onDeleteFolderTap(folder) } label: {
                                Label("Удалить папку", systemImage: "trash")
                            }
                            .disabled(isOffline)
                        }
                }
            }
            .padding(.horizontal, 8)
        }
    }

    @ViewBuilder
    private func documentListSection(title: String?, documents: [Document], showDate: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 8)
            }

            ForEach(Array(documents.enumerated()), id: \.element.id) { index, document in
                documentRow(document, showDate: showDate)
                if index < documents.count - 1 {
                    Divider()
                        .padding(.leading, 56)
                }
            }
        }
    }

    private func documentRow(_ document: Document, showDate: Bool = false) -> some View {
        return DocumentRowView(document: document, showDate: showDate)
            .onTapGesture {
                model.onDocumentTap(document)
            }
            .contextMenu {
                if document.isNote {
                    Button { model.onEditNoteTap(document) } label: {
                        Label("Редактировать", systemImage: "pencil")
                    }
                    .disabled(isOffline)
                }
                Button(role: .destructive) { model.onDocumentDelete(document) } label: {
                    Label("Удалить", systemImage: "trash")
                }
                .disabled(isOffline)
            }
    }
}

extension DocumentsView {
    enum Layout {
        static let rootStackSpacing = CGFloat.zero
        static let toastHorizontalPadding: CGFloat = 20
        static let toastVerticalPadding: CGFloat = 12
        static let toastCornerRadius: CGFloat = 12
        static let toastBottomPadding: CGFloat = 80
        static let overlayAnimationDuration: Double = 0.3
    }
}

#Preview {
    DocumentsView(
        model: .init(
            folders: [
                Folder(name: "Базы данных", documentsCount: 12, color: .blue),
                Folder(name: "Резюме", documentsCount: 5, color: .green),
                Folder(name: "Проекты", documentsCount: 8, color: .orange)
            ],
            rootDocuments: [
                Document(name: "Сопроводительное письмо.txt", type: .txt, size: 8_192)
            ],
            recentDocuments: [
                Document(name: "Резюме iOS Developer.pdf", type: .pdf, size: 245_760),
                Document(name: "Заметки.txt", type: .note, size: 12_288)
            ],
            selectedFolder: nil,
            folderContentsFolders: [],
            folderContentsDocuments: [],
            isLoading: false,
            error: nil,
            isOfflineMode: false,
            showingCreateFolderSheet: false,
            folderToRename: nil,
            folderToDelete: nil,
            showingUploadSheet: false,
            showingCreateNoteSheet: false,
            showingEditNoteSheet: false,
            editingNote: nil,
            documentURLToOpen: nil,
            onFolderTap: { _ in },
            onBackFromFolder: {},
            onDocumentTap: { _ in },
            onCreateFolderTap: {},
            onUploadFileTap: {},
            onCreateNoteTap: {},
            onDismissSheet: {},
            onFolderCreate: { _ in },
            onRenameFolderTap: { _ in },
            onCommitFolderRename: { _ in },
            onCancelFolderRename: {},
            onDeleteFolderTap: { _ in },
            onConfirmDeleteFolder: { _ in },
            onDismissDeleteFolderConfirmation: {},
            onFileUpload: { _ in },
            onNoteCreate: { _, _ in },
            onNoteUpdate: { _, _, _ in },
            onEditNoteTap: { _ in },
            onDocumentDelete: { _ in },
            onClearDocumentToOpen: {},
            onClearError: {},
            onRetry: {}
        )
    )
}
