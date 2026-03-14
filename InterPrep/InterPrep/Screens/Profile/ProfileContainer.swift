//
//  ProfileContainer.swift
//  InterPrep
//
//  Profile feature container
//

import SwiftUI
import ArchitectureCore

public struct ProfileContainer: View {
    @StateObject private var store: ProfileStore
    @State private var showResumeDetailSheet = false
    private let onLogoutComplete: (() -> Void)?
    private let onNavigateToResumeUpload: (() -> Void)?
    
    public init(
        sessionService: (any ProfileSessionService)? = nil,
        onLogoutComplete: (() -> Void)? = nil,
        onNavigateToResumeUpload: (() -> Void)? = nil
    ) {
        _store = StateObject(wrappedValue: Store(
            state: ProfileState(),
            effectHandler: ProfileEffectHandler(sessionService: sessionService)
        ))
        self.onLogoutComplete = onLogoutComplete
        self.onNavigateToResumeUpload = onNavigateToResumeUpload
    }
    
    public var body: some View {
        ProfileView(model: makeModel())
            .onAppear {
                store.send(.onAppear)
            }
            .onChange(of: store.state.authRequired) { _, authRequired in
                if authRequired {
                    onLogoutComplete?()
                    store.send(.clearAuthRequired)
                }
            }
            .sheet(isPresented: $showResumeDetailSheet) {
                ResumeProfileDetailView()
            }
    }
    
    private func makeModel() -> ProfileView.Model {
        .init(
            user: store.state.user,
            statistics: store.state.statistics,
            settings: store.state.settings,
            deleteAccountError: store.state.deleteAccountError,
            onNotificationsToggled: { enabled in
                store.send(.notificationsToggled(enabled))
            },
            onThemeChanged: { theme in
                store.send(.themeChanged(theme))
            },
            onChangeResume: {
                onNavigateToResumeUpload?() ?? store.send(.changeResume)
            },
            onViewResume: {
                showResumeDetailSheet = true
            },
            onLogout: {
                store.send(.logout)
            },
            onDeleteAccount: { password in
                store.send(.deleteAccount(password: password))
            },
            onClearDeleteAccountError: {
                store.send(.clearDeleteAccountError)
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
