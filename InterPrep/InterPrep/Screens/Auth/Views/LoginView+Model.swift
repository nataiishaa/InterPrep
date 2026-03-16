//
//  LoginView+Model.swift
//  InterPrep
//
//  Login view model
//

import Foundation

extension LoginView {
    struct Model {
        let email: String
        let password: String
        let isLoading: Bool
        let errorMessage: String?
        let onEmailChanged: (String) -> Void
        let onPasswordChanged: (String) -> Void
        let onLogin: () -> Void
        let onForgotPassword: () -> Void
    }
}

#if DEBUG
extension LoginView.Model {
    static func fixture(
        email: String = "",
        password: String = "",
        isLoading: Bool = false,
        errorMessage: String? = nil,
        onEmailChanged: @escaping (String) -> Void = { _ in },
        onPasswordChanged: @escaping (String) -> Void = { _ in },
        onLogin: @escaping () -> Void = {},
        onForgotPassword: @escaping () -> Void = {}
    ) -> Self {
        .init(
            email: email,
            password: password,
            isLoading: isLoading,
            errorMessage: errorMessage,
            onEmailChanged: onEmailChanged,
            onPasswordChanged: onPasswordChanged,
            onLogin: onLogin,
            onForgotPassword: onForgotPassword
        )
    }
    
    static var loading: Self {
        .fixture(isLoading: true)
    }
    
    static var fixtureWithError: Self {
        .fixture(errorMessage: "Неверный email или пароль")
    }
    
    static var filled: Self {
        .fixture(
            email: "user@example.com",
            password: "password123"
        )
    }
}
#endif
