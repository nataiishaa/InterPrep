//
//  FolderDetailView.swift
//  InterPrep
//
//  Folder detail view with documents
//

import SwiftUI

struct FolderDetailView: View {
    let folder: Folder
    let documents: [Document]
    let onDocumentTap: (Document) -> Void
    let onDocumentDelete: (Document) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if documents.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("Папка пуста")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Добавьте документы в эту папку")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    ForEach(documents) { document in
                        DocumentRowView(document: document)
                            .onTapGesture {
                                onDocumentTap(document)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    onDocumentDelete(document)
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(folder.name)
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        FolderDetailView(
            folder: Folder(
                name: "Базы данных",
                documentsCount: 3,
                color: .blue
            ),
            documents: [
                Document(
                    name: "Резюме iOS Developer.pdf",
                    type: .pdf,
                    size: 245_760
                ),
                Document(
                    name: "Заметки.txt",
                    type: .note,
                    size: 12_288
                ),
                Document(
                    name: "Портфолио.pdf",
                    type: .pdf,
                    size: 1_048_576
                )
            ],
            onDocumentTap: { _ in },
            onDocumentDelete: { _ in }
        )
    }
}

#Preview("Empty Folder") {
    NavigationStack {
        FolderDetailView(
            folder: Folder(
                name: "Пустая папка",
                documentsCount: 0,
                color: .gray
            ),
            documents: [],
            onDocumentTap: { _ in },
            onDocumentDelete: { _ in }
        )
    }
}
