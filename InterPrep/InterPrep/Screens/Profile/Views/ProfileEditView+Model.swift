//
//  ProfileEditView+Model.swift
//  InterPrep
//
//  Profile edit view model
//

import Foundation

extension ProfileEditView {
    struct Model {
        let firstName: String
        let lastName: String
        let email: String
        let cachedProfilePhotoURL: URL?
        let avatarURL: String?
        let errorMessage: String?
        let onPhotoSelected: (Data) -> Void
        let onFirstNameChanged: (String) -> Void
        let onLastNameChanged: (String) -> Void
        let onSave: () -> Void
        let onCancel: () -> Void
    }
}
