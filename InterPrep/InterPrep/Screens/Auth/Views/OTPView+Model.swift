//
//  OTPView+Model.swift
//  InterPrep
//
//  OTP view model
//

import Foundation

extension OTPView {
    struct Model {
        let code: String
        let email: String?
        let isLoading: Bool
        let errorMessage: String?
        let onCodeChanged: (String) -> Void
        let onSubmit: () -> Void
        let onResend: () -> Void
    }
}
