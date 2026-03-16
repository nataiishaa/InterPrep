//
//  NewPasswordView+Model.swift
//  InterPrep
//
//  New password view model
//

import Foundation

extension NewPasswordView {
    struct Model {
        let password: String
        let passwordConfirm: String
        let isLoading: Bool
        let errorMessage: String?
        let onPasswordChanged: (String) -> Void
        let onPasswordConfirmChanged: (String) -> Void
        let onSubmit: () -> Void
    }
}
