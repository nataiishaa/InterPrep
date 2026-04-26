//
//  ProfileEditView.swift
//  InterPrep
//
//  Редактирование профиля — фото, имя и фамилия
//

import DesignSystem
import PhotosUI
import SwiftUI
import UIKit

struct ProfileEditView: View {
    let model: Model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUploadingPhoto = false
    @State private var photoError: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    avatarSection
                    fieldsSection
                    emailSection
                    
                    if let error = model.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        model.onCancel()
                        dismiss()
                    }
                    .foregroundColor(.brandPrimary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        model.onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.brandPrimary)
                    .disabled(model.firstName.isEmpty || model.lastName.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Avatar Section
    
    private var avatarSection: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                avatarPreview
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
                
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.brandPrimary)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(.systemGroupedBackground), lineWidth: 3)
                        )
                }
                .buttonStyle(.plain)
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
            }
            
            if isUploadingPhoto {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.brandPrimary)
                    Text("Загрузка…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if let photoError {
                Text(photoError)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Text("Нажмите на камеру, чтобы изменить фото")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Fields Section
    
    private var fieldsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Имя и фамилия")
                .font(.headline)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                EditField(
                    label: "Имя",
                    text: Binding(
                        get: { model.firstName },
                        set: { model.onFirstNameChanged($0) }
                    )
                )
                
                EditField(
                    label: "Фамилия",
                    text: Binding(
                        get: { model.lastName },
                        set: { model.onLastNameChanged($0) }
                    )
                )
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
            .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Email Section
    
    private var emailSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Почта")
                .font(.headline)
                .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.brandPrimary)
                    .frame(width: 24)
                
                Text(model.email.isEmpty ? "—" : model.email)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
            .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
        }
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.05)
    }
}

// MARK: - Edit Field

private struct EditField: View {
    let label: String
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField(label, text: $text)
                .focused($isFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isFocused ? Color.brandPrimary : Color.clear, lineWidth: 1.5)
                )
                .tint(.brandPrimary)
        }
    }
}

extension ProfileEditView {
    private var avatarPreview: some View {
        Group {
            if let localURL = model.cachedProfilePhotoURL {
                avatarImageFromFile(localURL)
            } else if let urlString = model.avatarURL, !urlString.isEmpty, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure, .empty:
                        avatarPlaceholder
                    @unknown default:
                        avatarPlaceholder
                    }
                }
            } else {
                avatarPlaceholder
            }
        }
    }
    
    private var avatarPlaceholder: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.brandPrimary, .brandSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Text(avatarInitials)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            )
    }
    
    private var avatarInitials: String {
        let first = model.firstName.prefix(1)
        let last = model.lastName.prefix(1)
        let combined = "\(first)\(last)".uppercased()
        let trimmed = combined.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "?" : trimmed
    }
    
    @ViewBuilder
    private func avatarImageFromFile(_ url: URL) -> some View {
        let filePath = url.path
        if let uiImage = UIImage(contentsOfFile: filePath) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            avatarPlaceholder
        }
    }
    
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
        cachedProfilePhotoURL: nil,
        avatarURL: nil,
        errorMessage: nil,
        onPhotoSelected: { _ in },
        onFirstNameChanged: { _ in },
        onLastNameChanged: { _ in },
        onSave: {},
        onCancel: {}
    ))
}
