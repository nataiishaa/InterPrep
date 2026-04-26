//
//  DocumentsRenameFolderSheet.swift
//  InterPrep
//
//  Created by Наталья Захарова on 26/4/2026.
//

import SwiftUI

struct DocumentsRenameFolderSheet: View {
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

