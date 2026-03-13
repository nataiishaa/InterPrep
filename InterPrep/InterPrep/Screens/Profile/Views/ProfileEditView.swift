//
//  ProfileEditView.swift
//  InterPrep
//
//  Редактирование профиля — только имя и фамилия
//

import SwiftUI

struct ProfileEditView: View {
    let model: Model
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
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

// MARK: - Model

extension ProfileEditView {
    struct Model {
        let firstName: String
        let lastName: String
        let errorMessage: String?
        let onFirstNameChanged: (String) -> Void
        let onLastNameChanged: (String) -> Void
        let onSave: () -> Void
        let onCancel: () -> Void
    }
}

// MARK: - Preview

#Preview {
    ProfileEditView(model: .init(
        firstName: "Иван",
        lastName: "Иванов",
        errorMessage: nil,
        onFirstNameChanged: { _ in },
        onLastNameChanged: { _ in },
        onSave: {},
        onCancel: {}
    ))
}
