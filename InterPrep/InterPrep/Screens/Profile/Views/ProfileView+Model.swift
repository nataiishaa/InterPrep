//
//  ProfileView+Model.swift
//  InterPrep
//
//  Profile view model
//

import Foundation

extension ProfileView {
    struct Model {
        let user: ProfileState.User?
        let cachedProfilePhotoURL: URL?
        let statistics: ProfileState.Statistics
        let settings: ProfileState.AppSettings
        let deleteAccountError: String?
        let selectedInterviewTab: ProfileState.InterviewTab
        let upcomingInterviews: [ProfileState.Interview]
        let completedInterviews: [ProfileState.Interview]
        let isLoadingInterviews: Bool
        let onNotificationsToggled: (Bool) -> Void
        let onThemeChanged: (ProfileState.AppSettings.Theme) -> Void
        let onChangeResume: () -> Void
        let onViewResume: () -> Void
        let onLogout: () -> Void
        let onDeleteAccount: (String) -> Void
        let onClearDeleteAccountError: () -> Void
        let onInterviewTabChanged: (ProfileState.InterviewTab) -> Void
        let onInterviewTapped: (ProfileState.Interview) -> Void
        let onEditProfileTapped: (() -> Void)?
        let editModel: ProfileEditView.Model
    }
}
