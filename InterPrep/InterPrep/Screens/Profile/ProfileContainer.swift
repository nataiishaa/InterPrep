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
            errorMessage: store.state.errorMessage,
            onFirstNameChanged: { name in
                store.send(.firstNameChanged(name))
            },
            onLastNameChanged: { name in
                store.send(.lastNameChanged(name))
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
