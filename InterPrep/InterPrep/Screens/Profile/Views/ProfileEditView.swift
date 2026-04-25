//
//  ProfileEditView.swift
//  InterPrep
//
//  Редактирование профиля — фото, имя и фамилия
//

import PhotosUI
import SwiftUI
import UIKit

struct ProfileEditView: View {
    let model: Model
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUploadingPhoto = false
    @State private var photoError: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Фото профиля") {
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Выбрать из галереи", systemImage: "photo.on.rectangle.angled")
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        guard let newItem else { return }
                        photoError = nil
                        isUploadingPhoto = true
                        Task {
                            if let data = await loadImageData(from: newItem) {
                                await MainActor.run {
                                    model.onPhotoSelected(data)
                                    isUploadingPhoto = false
                                    selectedPhotoItem = nil
                                }
                            } else {
                                await MainActor.run {
                                    photoError = "Не удалось обработать выбранное изображение. Попробуйте другое фото."
                                    isUploadingPhoto = false
                                    selectedPhotoItem = nil
                                }
                            }
                        }
                    }
                    if isUploadingPhoto {
                        HStack {
                            ProgressView()
                            Text("Загрузка…")
                                .foregroundColor(.secondary)
                        }
                    }
                    if let photoError {
                        Text(photoError)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section("Имя и фамилия") {
                    TextField("Имя", text: Binding(
                        get: { model.firstName },
                        set: { model.onFirstNameChanged($0) }
                    ))
                    
                    TextField("Фамилия", text: Binding(
                        get: { model.lastName },
                        set: { model.onLastNameChanged($0) }
                    ))
                }
                
                Section("Почта") {
                    Text(model.email.isEmpty ? "—" : model.email)
                        .foregroundColor(.secondary)
                }
                
                if let error = model.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Редактировать профиль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        model.onCancel()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        model.onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(model.firstName.isEmpty || model.lastName.isEmpty)
                }
            }
        }
    }
}

extension ProfileEditView {
    private func loadImageData(from item: PhotosPickerItem) async -> Data? {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else {
            return nil
        }
        return compressToJPEG(uiImage)
    }
    
    private func compressToJPEG(_ original: UIImage) -> Data? {
        let maxDimension: CGFloat = 800
        let size = original.size
        guard size.width > 0, size.height > 0 else { return nil }
        
        let image: UIImage
        if size.width > maxDimension || size.height > maxDimension {
            let scale = min(maxDimension / size.width, maxDimension / size.height)
            let newSize = CGSize(width: size.width * scale, height: size.height * scale)
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
            image = renderer.image { _ in
                original.draw(in: CGRect(origin: .zero, size: newSize))
            }
        } else {
            image = original
        }
        
        let maxBytes = 512 * 1024
        var quality: CGFloat = 0.7
        while quality >= 0.2 {
            if let jpegData = image.jpegData(compressionQuality: quality), jpegData.count <= maxBytes {
                return jpegData
            }
            quality -= 0.1
        }
        return image.jpegData(compressionQuality: 0.2)
    }
}

#Preview {
    ProfileEditView(model: .init(
        firstName: "Иван",
        lastName: "Иванов",
        email: "ivan@example.com",
        errorMessage: nil,
        onPhotoSelected: { _ in },
        onFirstNameChanged: { _ in },
        onLastNameChanged: { _ in },
        onSave: {},
        onCancel: {}
    ))
}
