//
//  UploadFileSheet.swift
//  InterPrep
//
//  Upload file sheet
//

import SwiftUI
import UniformTypeIdentifiers

struct UploadFileSheet: View {
    @State private var showingDocumentPicker = false
    let onDismiss: () -> Void
    let onFileSelected: ((URL) -> Void)?
    
    init(onDismiss: @escaping () -> Void, onFileSelected: ((URL) -> Void)? = nil) {
        self.onDismiss = onDismiss
        self.onFileSelected = onFileSelected
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "arrow.up.doc.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("Загрузить файл")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Выберите файл для загрузки")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Button {
                    showingDocumentPicker = true
                } label: {
                    Text("Выбрать файл")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Загрузка файла")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        onDismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showingDocumentPicker,
                allowedContentTypes: [.pdf, .plainText, .image, .data],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        onFileSelected?(url)
                        onDismiss()
                    }
                case .failure:
                    break
                }
            }
        }
    }
}

#Preview {
    UploadFileSheet(onDismiss: {})
}
