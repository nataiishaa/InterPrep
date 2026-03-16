//
//  ProfileEditView.swift
//  InterPrep
//
//  Редактирование профиля — фото, имя и фамилия
//

import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    let model: Model
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUploadingPhoto = false
    
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
                        isUploadingPhoto = true
                        Task {
                            if let data = await loadImageData(from: newItem) {
                                await MainActor.run {
                                    model.onPhotoSelected(data)
                                    isUploadingPhoto = false
                                    selectedPhotoItem = nil
                                }
                            } else {
                                await MainActor.run { isUploadingPhoto = false }
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
        guard let image = try? await item.loadTransferable(type: Image.self) else { return nil }
        return imageToJPEGData(image: image)
    }
    
    private func imageToJPEGData(image: Image) -> Data? {
        let renderer = ImageRenderer(content: image)
        let scale: CGFloat = {
            let s = UIScreen.main.scale
            guard s > 0, s.isFinite else { return 2.0 }
            return s
        }()
        renderer.scale = scale
        renderer.proposedSize = ProposedViewSize(width: 1024, height: 1024)
        guard let uiImage = renderer.uiImage else { return nil }
        let w = uiImage.size.width, h = uiImage.size.height
        guard w > 0, h > 0, w.isFinite, h.isFinite else { return nil }
        let maxBytes = 2 * 1024 * 1024
        var quality: CGFloat = 0.85
        repeat {
            if let data = uiImage.jpegData(compressionQuality: quality), data.count <= maxBytes {
                return data
            }
            quality -= 0.15
        } while quality >= 0.4
        return uiImage.jpegData(compressionQuality: 0.5)
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
