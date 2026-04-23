//
//  ProfileContainer.swift
//  InterPrep
//
//  Profile feature container
//

import ArchitectureCore
import NotificationService
import SwiftUI

public struct ProfileContainer: View {
    @StateObject private var store: ProfileStore
    @StateObject private var notificationManager = NotificationManager.shared
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
                store.send(.refresh)
            } content: {
                ResumeProfileDetailView(
                    userId: store.state.user?.id,
                    onUploadNewResume: {
                        showResumeDetailSheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onNavigateToResumeUpload?() ?? store.send(.changeResume)
                        }
                    }
                )
            }
    }
    
    private func makeModel() -> ProfileView.Model {
        .init(
            user: store.state.user,
            cachedProfilePhotoURL: store.state.cachedProfilePhotoURL,
            statistics: store.state.statistics,
            settings: store.state.settings,
            deleteAccountError: store.state.deleteAccountError,
            selectedInterviewTab: store.state.selectedInterviewTab,
            upcomingInterviews: store.state.upcomingInterviews,
            completedInterviews: store.state.completedInterviews,
            isLoadingInterviews: store.state.isLoadingInterviews,
            hasResumeData: store.state.hasResumeData,
            isOfflineMode: store.state.isOfflineMode,
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
            onInterviewTabChanged: { tab in
                store.send(.interviewTabChanged(tab))
            },
            onInterviewTapped: { interview in
                store.send(.interviewTapped(interview))
            },
            onEditProfileTapped: {
                store.send(.startEditingProfile)
            },
            editModel: makeEditModel()
        )
    }
    
    private func makeEditModel() -> ProfileEditView.Model {
        .init(
            firstName: store.state.user?.firstName ?? store.state.editedFirstName,
            lastName: store.state.user?.lastName ?? store.state.editedLastName,
            email: store.state.user?.email ?? "",
            errorMessage: store.state.errorMessage,
            onPhotoSelected: { data in
                store.send(.uploadProfilePhoto(data))
            },
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
