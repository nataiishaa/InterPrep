//
//  CreateNoteSheet.swift
//  InterPrep
//
//  Create note sheet
//

import SwiftUI

struct CreateNoteSheet: View {
    @State private var noteTitle: String = ""
    @State private var noteContent: String = ""
    let onDismiss: () -> Void
    let onCreate: (String, String) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Title field
                TextField("Название заметки", text: $noteTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                    .background(Color(.systemBackground))
                
                Divider()
                
                // Content editor
                TextEditor(text: $noteContent)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Новая заметка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Создать") {
                        onCreate(noteTitle, noteContent)
                    }
                    .disabled(noteTitle.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CreateNoteSheet(
        onDismiss: {},
        onCreate: { _, _ in }
    )
}
