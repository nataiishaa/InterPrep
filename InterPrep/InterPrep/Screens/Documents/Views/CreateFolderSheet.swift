//
//  CreateFolderSheet.swift
//  InterPrep
//
//  Create folder sheet
//

import SwiftUI

struct CreateFolderSheet: View {
    @State private var folderName: String = ""
    let onDismiss: () -> Void
    let onCreate: (String) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Название папки", text: $folderName)
                } header: {
                    Text("Новая папка")
                }
            }
            .navigationTitle("Создать папку")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Создать") {
                        onCreate(folderName)
                    }
                    .disabled(folderName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    CreateFolderSheet(
        onDismiss: {},
        onCreate: { _ in }
    )
}
