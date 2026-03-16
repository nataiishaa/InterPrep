//
//  PasswordResetView+Model.swift
//  InterPrep
//
//  Password reset view model
//

import Foundation

extension PasswordResetView {
    struct Model {
        let email: String
        let isLoading: Bool
        let errorMessage: String?
        let onEmailChanged: (String) -> Void
        let onSendCode: () -> Void
    }
}
