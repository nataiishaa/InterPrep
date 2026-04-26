//
//  DocumentsView.swift
//  InterPrep
//
//  Documents main view
//

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
            VStack(spacing: 0) {
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
                        Button { guardOffline { model.onCreateFolderTap() } } label: {
                            Label("Создать папку", systemImage: "folder.badge.plus")
                        }
                        .disabled(isOffline)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(isOffline ? .secondary : .brandPrimary)
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
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                    .padding(.bottom, 80)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showOfflineToast)
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
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Мое хранилище")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textOnBackground)
                    if model.isLoading && model.folders.isEmpty && model.rootDocuments.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        if !model.folders.isEmpty {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(model.folders) { folder in
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
                        }
                        if !model.rootDocuments.isEmpty {
                            VStack(spacing: 12) {
                                ForEach(model.rootDocuments) { document in
                                    documentRow(document)
                                }
                            }
                        }
                        if model.folders.isEmpty && model.rootDocuments.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.secondary.opacity(0.5))
                                Text("Хранилище пусто")
                                    .foregroundColor(.secondary)
                                Text("Создайте папку или загрузите файл")
                                    .font(.caption)
                                    .foregroundColor(.secondary.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        }
                    }
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Недавнее")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textOnBackground)
                    if model.recentDocuments.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("Нет документов")
                                .foregroundColor(.secondary)
                            Text("Загрузите файл или создайте заметку")
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(model.recentDocuments) { document in
                                documentRow(document)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
    }

    private func folderContentView(folder: Folder) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                if model.isLoading && model.folderContentsFolders.isEmpty && model.folderContentsDocuments.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else {
                    if !model.folderContentsFolders.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Папки")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.textOnBackground)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(model.folderContentsFolders) { folder in
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
                        }
                        .padding(.horizontal)
                    }
                    if !model.folderContentsDocuments.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Файлы")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.textOnBackground)
                            VStack(spacing: 12) {
                                ForEach(model.folderContentsDocuments) { document in
                                    documentRow(document)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    if model.folderContentsFolders.isEmpty && model.folderContentsDocuments.isEmpty && !model.isLoading {
                        Text("Папка пуста")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private func documentRow(_ document: Document) -> some View {
        let canEditAsNote = document.isNote || document.type == .other
        return DocumentRowView(document: document)
            .onTapGesture {
                if isOffline && !canEditAsNote {
                    guardOffline {}
                } else {
                    model.onDocumentTap(document)
                }
            }
            .contextMenu {
                if canEditAsNote {
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

private struct DocumentsRenameFolderSheet: View {
    let folder: Folder
    let onSave: (String) -> Void
    let onDismiss: () -> Void
    @State private var name: String
    @FocusState private var isFieldFocused: Bool

    init(folder: Folder, onSave: @escaping (String) -> Void, onDismiss: @escaping () -> Void) {
        self.folder = folder
        self.onSave = onSave
        self.onDismiss = onDismiss
        _name = State(initialValue: folder.name)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Название папки", text: $name)
                    .focused($isFieldFocused)
                    .onAppear { isFieldFocused = true }
            }
            .navigationTitle("Переименовать папку")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty { onSave(trimmed) }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

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
