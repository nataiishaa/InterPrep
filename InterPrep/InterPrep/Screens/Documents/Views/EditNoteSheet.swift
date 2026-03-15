//
//  EditNoteSheet.swift
//  InterPrep
//
//  Edit note sheet
//

import SwiftUI

struct EditNoteSheet: View {
    let document: Document
    @State private var noteName: String
    @State private var noteContent: String
    let onDismiss: () -> Void
    let onSave: (Document, String, String) -> Void
    var onDelete: (() -> Void)? = nil

    init(document: Document, onDismiss: @escaping () -> Void, onSave: @escaping (Document, String, String) -> Void, onDelete: (() -> Void)? = nil) {
        self.document = document
        self.onDismiss = onDismiss
        self.onSave = onSave
        self.onDelete = onDelete
        _noteName = State(initialValue: document.name)
        _noteContent = State(initialValue: document.content ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField("Название заметки", text: $noteName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                    .background(Color(.systemBackground))

                Divider()

                TextEditor(text: $noteContent)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 120, maxHeight: .infinity)
            }
            .navigationTitle("Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { onDismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        onSave(document, noteName.trimmingCharacters(in: .whitespacesAndNewlines), noteContent)
                    }
                    .fontWeight(.semibold)
                    .disabled(noteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                if onDelete != nil {
                    ToolbarItem(placement: .bottomBar) {
                        Button(role: .destructive) {
                            onDelete?()
                        } label: {
                            Label("Удалить заметку", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EditNoteSheet(
        document: Document(
            name: "Моя заметка",
            type: .note,
            content: "Содержимое заметки"
        ),
        onDismiss: {},
        onSave: { _, _, _ in }
    )
}
