//
//  RegistrationDetailsView+Model.swift
//  InterPrep
//
//  Registration details view model
//

import Foundation

extension RegistrationDetailsView {
    struct Model {
        let email: String
        let password: String
        let passwordConfirm: String
        let isLoading: Bool
        let errorMessage: String?
        let onEmailChanged: (String) -> Void
        let onPasswordChanged: (String) -> Void
        let onPasswordConfirmChanged: (String) -> Void
        let onSubmit: () -> Void
    }
}
