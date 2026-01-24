//
//  ProfileEditView.swift
//  InterPrep
//
//  Profile edit form
//

import SwiftUI

struct ProfileEditView: View {
    let model: Model
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Основная информация") {
                    TextField("Имя", text: Binding(
                        get: { model.firstName },
                        set: { model.onFirstNameChanged($0) }
                    ))
                    
                    TextField("Фамилия", text: Binding(
                        get: { model.lastName },
                        set: { model.onLastNameChanged($0) }
                    ))
                    
                    TextField("Email", text: Binding(
                        get: { model.email },
                        set: { model.onEmailChanged($0) }
                    ))
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                }
                
                Section("Контакты") {
                    TextField("Телефон", text: Binding(
                        get: { model.phone },
                        set: { model.onPhoneChanged($0) }
                    ))
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                }
                
                Section("Профессиональная информация") {
                    TextField("Должность", text: Binding(
                        get: { model.position },
                        set: { model.onPositionChanged($0) }
                    ))
                    
                    TextField("Опыт работы", text: Binding(
                        get: { model.experience },
                        set: { model.onExperienceChanged($0) }
                    ))
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
                    .disabled(model.firstName.isEmpty || model.lastName.isEmpty || model.email.isEmpty)
                }
            }
        }
    }
}

// MARK: - Model

extension ProfileEditView {
    struct Model {
        let firstName: String
        let lastName: String
        let email: String
        let phone: String
        let position: String
        let experience: String
        let errorMessage: String?
        let onFirstNameChanged: (String) -> Void
        let onLastNameChanged: (String) -> Void
        let onEmailChanged: (String) -> Void
        let onPhoneChanged: (String) -> Void
        let onPositionChanged: (String) -> Void
        let onExperienceChanged: (String) -> Void
        let onSave: () -> Void
        let onCancel: () -> Void
    }
}

// MARK: - Preview

#Preview {
    ProfileEditView(model: .init(
        firstName: "Иван",
        lastName: "Иванов",
        email: "ivan@example.com",
        phone: "+7 999 123-45-67",
        position: "iOS Developer",
        experience: "3 года",
        errorMessage: nil,
        onFirstNameChanged: { _ in },
        onLastNameChanged: { _ in },
        onEmailChanged: { _ in },
        onPhoneChanged: { _ in },
        onPositionChanged: { _ in },
        onExperienceChanged: { _ in },
        onSave: {},
        onCancel: {}
    ))
}
