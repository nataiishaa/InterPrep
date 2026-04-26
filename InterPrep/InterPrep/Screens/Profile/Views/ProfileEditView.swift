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
                VStack(spacing: Layout.formStackSpacing) {
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
        VStack(spacing: Layout.avatarSectionSpacing) {
            ZStack(alignment: .bottomTrailing) {
                avatarPreview
                    .frame(width: Layout.avatarSide, height: Layout.avatarSide)
                    .clipShape(Circle())
                    .shadow(color: shadowColor, radius: Layout.avatarShadowRadius, x: .zero, y: Layout.avatarShadowY)
                
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: Layout.cameraIconFontSize, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: Layout.cameraButtonSide, height: Layout.cameraButtonSide)
                        .background(Color.brandPrimary)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(.systemGroupedBackground), lineWidth: Layout.cameraButtonRingWidth)
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
                HStack(spacing: Layout.uploadRowSpacing) {
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
        .padding(.vertical, Layout.avatarSectionVerticalPadding)
        .background(Color.cardBackground)
        .cornerRadius(Layout.largeCardCornerRadius)
        .shadow(color: shadowColor, radius: Layout.cardShadowRadius, x: .zero, y: Layout.cardShadowY)
    }
    
    // MARK: - Fields Section
    
    private var fieldsSection: some View {
        VStack(alignment: .leading, spacing: Layout.sectionBlockSpacing) {
            Text("Имя и фамилия")
                .font(.headline)
                .padding(.horizontal, Layout.sectionTitleInset)
            
            VStack(spacing: Layout.fieldsInnerSpacing) {
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
            .cornerRadius(Layout.cardCornerRadius)
            .shadow(color: shadowColor, radius: Layout.cardShadowRadius, x: .zero, y: Layout.cardShadowY)
        }
    }
    
    // MARK: - Email Section
    
    private var emailSection: some View {
        VStack(alignment: .leading, spacing: Layout.sectionBlockSpacing) {
            Text("Почта")
                .font(.headline)
                .padding(.horizontal, Layout.sectionTitleInset)
            
            HStack(spacing: Layout.emailRowSpacing) {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.brandPrimary)
                    .frame(width: Layout.emailIconWidth)
                
                Text(model.email.isEmpty ? "—" : model.email)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(Layout.cardCornerRadius)
            .shadow(color: shadowColor, radius: Layout.cardShadowRadius, x: .zero, y: Layout.cardShadowY)
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
        VStack(alignment: .leading, spacing: EditField.Layout.labelFieldSpacing) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField(label, text: $text)
                .focused($isFocused)
                .padding(.horizontal, EditField.Layout.fieldHorizontalPadding)
                .padding(.vertical, EditField.Layout.fieldVerticalPadding)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(EditField.Layout.fieldCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: EditField.Layout.fieldCornerRadius)
                        .stroke(isFocused ? Color.brandPrimary : Color.clear, lineWidth: EditField.Layout.focusStrokeWidth)
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
                    .font(.system(size: Layout.initialsFontSize, weight: .bold))
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

extension ProfileEditView {
    enum Layout {
        static let formStackSpacing: CGFloat = 24
        static let avatarSectionSpacing: CGFloat = 16
        static let avatarSide: CGFloat = 120
        static let avatarShadowRadius: CGFloat = 8
        static let avatarShadowY: CGFloat = 4
        static let cameraIconFontSize: CGFloat = 14
        static let cameraButtonSide: CGFloat = 36
        static let cameraButtonRingWidth: CGFloat = 3
        static let uploadRowSpacing: CGFloat = 8
        static let avatarSectionVerticalPadding: CGFloat = 20
        static let largeCardCornerRadius: CGFloat = 16
        static let cardCornerRadius: CGFloat = 12
        static let cardShadowRadius: CGFloat = 4
        static let cardShadowY: CGFloat = 2
        static let sectionTitleInset: CGFloat = 4
        static let sectionBlockSpacing: CGFloat = 16
        static let fieldsInnerSpacing: CGFloat = 12
        static let emailRowSpacing: CGFloat = 12
        static let emailIconWidth: CGFloat = 24
        static let initialsFontSize: CGFloat = 36
    }
}

extension EditField {
    enum Layout {
        static let labelFieldSpacing: CGFloat = 6
        static let fieldHorizontalPadding: CGFloat = 12
        static let fieldVerticalPadding: CGFloat = 10
        static let fieldCornerRadius: CGFloat = 10
        static let focusStrokeWidth: CGFloat = 1.5
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
