//
//  ProfileContainer.swift
//  InterPrep
//
//  Profile feature container
//

import SwiftUI
import ArchitectureCore

public struct ProfileContainer: View {
    @StateObject private var store: Store<ProfileState, ProfileEffectHandler>
    
    public init() {
        _store = StateObject(wrappedValue: Store(
            state: ProfileState(),
            effectHandler: ProfileEffectHandler()
        ))
    }
    
    public var body: some View {
        ProfileView(model: makeModel())
            .onAppear {
                store.send(.onAppear)
            }
    }
    
    private func makeModel() -> ProfileView.Model {
        .init(
            user: store.state.user,
            statistics: store.state.statistics,
            settings: store.state.settings,
            onNotificationsToggled: { enabled in
                store.send(.notificationsToggled(enabled))
            },
            onEmailNotificationsToggled: { enabled in
                store.send(.emailNotificationsToggled(enabled))
            },
            onThemeChanged: { theme in
                store.send(.themeChanged(theme))
            },
            onChangeResume: {
                store.send(.changeResume)
            },
            onExportData: {
                store.send(.exportData)
            },
            onLogout: {
                store.send(.logout)
            },
            onDeleteAccount: {
                store.send(.deleteAccount)
            },
            editModel: makeEditModel()
        )
    }
    
    private func makeEditModel() -> ProfileEditView.Model {
        .init(
            firstName: store.state.editedFirstName,
            lastName: store.state.editedLastName,
            email: store.state.editedEmail,
            phone: store.state.editedPhone,
            position: store.state.editedPosition,
            experience: store.state.editedExperience,
            errorMessage: store.state.errorMessage,
            onFirstNameChanged: { name in
                store.send(.firstNameChanged(name))
            },
            onLastNameChanged: { name in
                store.send(.lastNameChanged(name))
            },
            onEmailChanged: { email in
                store.send(.emailChanged(email))
            },
            onPhoneChanged: { phone in
                store.send(.phoneChanged(phone))
            },
            onPositionChanged: { position in
                store.send(.positionChanged(position))
            },
            onExperienceChanged: { experience in
                store.send(.experienceChanged(experience))
            },
            onSave: {
                store.send(.saveProfile)
            },
            onCancel: {
                store.send(.cancelEditingProfile)
            }
        )
    }
}

// MARK: - Preview

#Preview {
    ProfileContainer()
}
