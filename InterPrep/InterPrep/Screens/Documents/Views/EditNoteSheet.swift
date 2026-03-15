//
//  EditNoteSheet.swift
//  InterPrep
//
//  Edit note sheet
//

import SwiftUI

struct EditNoteSheet: View {
    let document: Document
    @State private var noteContent: String
    let onDismiss: () -> Void
    let onSave: (Document, String) -> Void
    
    init(document: Document, onDismiss: @escaping () -> Void, onSave: @escaping (Document, String) -> Void) {
        self.document = document
        self.onDismiss = onDismiss
        self.onSave = onSave
        _noteContent = State(initialValue: document.content ?? "")
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Title (read-only)
                HStack {
                    Text(document.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // Content editor
                TextEditor(text: $noteContent)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        onSave(document, noteContent)
                    }
                    .fontWeight(.semibold)
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
        onSave: { _, _ in }
    )
}
