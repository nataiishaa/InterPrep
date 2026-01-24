//
//  AuthState.swift
//  InterPrep
//
//  Auth module state
//

import Foundation
import ArchitectureCore

public struct AuthState {
    public var authFlow: AuthFlow = .login
    public var isLoading = false
    public var errorMessage: String?
    public var isAuthenticated = false
    
    public init() {}
    
    // Login fields
    public var loginEmail = ""
    public var loginPassword = ""
    
    // Registration fields
    public var registrationFirstName = ""
    public var registrationLastName = ""
    public var registrationEmail = ""
    public var registrationPassword = ""
    public var registrationPasswordConfirm = ""
    
    // Password reset
    public var resetEmail = ""
    
    // OTP verification
    public var otpCode = ""
    public var otpEmail = ""
    
    // Resume upload
    public var hasUploadedResume = false
    
    // New password
    public var newPassword = ""
    public var newPasswordConfirm = ""
    
    public enum AuthFlow: Equatable, Sendable {
        case login
        case registration
        case registrationDetails // После первого экрана регистрации
        case passwordReset
        case otpVerification
        case resumeUpload
        case newPassword
    }
}

extension AuthState: FeatureState {
    public enum Input: Sendable {
        // Navigation
        case showLogin
        case showRegistration
        case showPasswordReset
        case backTapped
        
        // Login
        case loginEmailChanged(String)
        case loginPasswordChanged(String)
        case loginTapped
        case forgotPasswordTapped
        
        // Registration step 1 (Name)
        case registrationFirstNameChanged(String)
        case registrationLastNameChanged(String)
        case registrationContinueTapped
        
        // Registration step 2 (Email & Password)
        case registrationEmailChanged(String)
        case registrationPasswordChanged(String)
        case registrationPasswordConfirmChanged(String)
        case registrationSubmitTapped
        
        // Password reset
        case resetEmailChanged(String)
        case sendResetCodeTapped
        
        // OTP
        case otpCodeChanged(String)
        case otpSubmitTapped
        case otpResendTapped
        
        // Resume upload
        case resumeUploadTapped
        case resumeSkipTapped
        
        // New password
        case newPasswordChanged(String)
        case newPasswordConfirmChanged(String)
        case newPasswordSubmitTapped
    }
    
    public enum Feedback: Sendable {
        case loginSuccess
        case loginFailed(String)
        case registrationSuccess
        case registrationFailed(String)
        case resetCodeSent
        case resetCodeFailed(String)
        case otpVerified
        case otpFailed(String)
        case resumeUploaded
        case passwordChanged
    }
    
    public enum Effect: Sendable {
        case performLogin(email: String, password: String)
        case performRegistration(firstName: String, lastName: String, email: String, password: String)
        case sendResetCode(email: String)
        case verifyOTP(email: String, code: String)
        case uploadResume
        case changePassword(email: String, code: String, newPassword: String)
    }
    
    @MainActor
    public static func reduce(
        state: inout Self,
        with message: Message<Input, Feedback>
    ) -> Effect? {
        switch message {
        // MARK: - Navigation
        case .input(.showLogin):
            state.authFlow = .login
            state.errorMessage = nil
            
        case .input(.showRegistration):
            state.authFlow = .registration
            state.errorMessage = nil
            
        case .input(.showPasswordReset):
            state.authFlow = .passwordReset
            state.errorMessage = nil
            
        case .input(.backTapped):
            switch state.authFlow {
            case .registrationDetails:
                state.authFlow = .registration
            case .otpVerification:
                state.authFlow = .passwordReset
            case .newPassword:
                state.authFlow = .otpVerification
            default:
                state.authFlow = .login
            }
            state.errorMessage = nil
            
        // MARK: - Login
        case let .input(.loginEmailChanged(email)):
            state.loginEmail = email
            state.errorMessage = nil
            
        case let .input(.loginPasswordChanged(password)):
            state.loginPassword = password
            state.errorMessage = nil
            
        case .input(.loginTapped):
            guard !state.loginEmail.isEmpty, !state.loginPassword.isEmpty else {
                state.errorMessage = "Заполните все поля"
                return nil
            }
            state.isLoading = true
            state.errorMessage = nil
            return .performLogin(email: state.loginEmail, password: state.loginPassword)
            
        case .input(.forgotPasswordTapped):
            state.authFlow = .passwordReset
            
        // MARK: - Registration Step 1
        case let .input(.registrationFirstNameChanged(name)):
            state.registrationFirstName = name
            state.errorMessage = nil
            
        case let .input(.registrationLastNameChanged(name)):
            state.registrationLastName = name
            state.errorMessage = nil
            
        case .input(.registrationContinueTapped):
            guard !state.registrationFirstName.isEmpty, !state.registrationLastName.isEmpty else {
                state.errorMessage = "Заполните все поля"
                return nil
            }
            state.authFlow = .registrationDetails
            state.errorMessage = nil
            
        // MARK: - Registration Step 2
        case let .input(.registrationEmailChanged(email)):
            state.registrationEmail = email
            state.errorMessage = nil
            
        case let .input(.registrationPasswordChanged(password)):
            state.registrationPassword = password
            state.errorMessage = nil
            
        case let .input(.registrationPasswordConfirmChanged(password)):
            state.registrationPasswordConfirm = password
            state.errorMessage = nil
            
        case .input(.registrationSubmitTapped):
            guard !state.registrationEmail.isEmpty,
                  !state.registrationPassword.isEmpty,
                  !state.registrationPasswordConfirm.isEmpty else {
                state.errorMessage = "Заполните все поля"
                return nil
            }
            guard state.registrationPassword == state.registrationPasswordConfirm else {
                state.errorMessage = "Пароли не совпадают"
                return nil
            }
            guard state.registrationPassword.count >= 6 else {
                state.errorMessage = "Пароль должен содержать минимум 6 символов"
                return nil
            }
            state.isLoading = true
            state.errorMessage = nil
            return .performRegistration(
                firstName: state.registrationFirstName,
                lastName: state.registrationLastName,
                email: state.registrationEmail,
                password: state.registrationPassword
            )
            
        // MARK: - Password Reset
        case let .input(.resetEmailChanged(email)):
            state.resetEmail = email
            state.errorMessage = nil
            
        case .input(.sendResetCodeTapped):
            guard !state.resetEmail.isEmpty else {
                state.errorMessage = "Введите email"
                return nil
            }
            state.isLoading = true
            state.errorMessage = nil
            return .sendResetCode(email: state.resetEmail)
            
        // MARK: - OTP
        case let .input(.otpCodeChanged(code)):
            state.otpCode = code
            state.errorMessage = nil
            
        case .input(.otpSubmitTapped):
            guard state.otpCode.count == 4 else {
                state.errorMessage = "Введите код из 4 цифр"
                return nil
            }
            state.isLoading = true
            return .verifyOTP(email: state.otpEmail, code: state.otpCode)
            
        case .input(.otpResendTapped):
            return .sendResetCode(email: state.otpEmail)
            
        // MARK: - Resume Upload
        case .input(.resumeUploadTapped):
            state.isLoading = true
            return .uploadResume
            
        case .input(.resumeSkipTapped):
            state.isAuthenticated = true
            
        // MARK: - New Password
        case let .input(.newPasswordChanged(password)):
            state.newPassword = password
            state.errorMessage = nil
            
        case let .input(.newPasswordConfirmChanged(password)):
            state.newPasswordConfirm = password
            state.errorMessage = nil
            
        case .input(.newPasswordSubmitTapped):
            guard !state.newPassword.isEmpty, !state.newPasswordConfirm.isEmpty else {
                state.errorMessage = "Заполните все поля"
                return nil
            }
            guard state.newPassword == state.newPasswordConfirm else {
                state.errorMessage = "Пароли не совпадают"
                return nil
            }
            guard state.newPassword.count >= 6 else {
                state.errorMessage = "Пароль должен содержать минимум 6 символов"
                return nil
            }
            state.isLoading = true
            state.errorMessage = nil
            return .changePassword(email: state.otpEmail, code: state.otpCode, newPassword: state.newPassword)
            
        // MARK: - Feedback
        case .feedback(.loginSuccess):
            state.isLoading = false
            state.isAuthenticated = true
            
        case let .feedback(.loginFailed(error)):
            state.isLoading = false
            state.errorMessage = error
            
        case .feedback(.registrationSuccess):
            state.isLoading = false
            state.authFlow = .resumeUpload
            
        case let .feedback(.registrationFailed(error)):
            state.isLoading = false
            state.errorMessage = error
            
        case .feedback(.resetCodeSent):
            state.isLoading = false
            state.otpEmail = state.resetEmail
            state.authFlow = .otpVerification
            
        case let .feedback(.resetCodeFailed(error)):
            state.isLoading = false
            state.errorMessage = error
            
        case .feedback(.otpVerified):
            state.isLoading = false
            state.authFlow = .newPassword
            
        case let .feedback(.otpFailed(error)):
            state.isLoading = false
            state.errorMessage = error
            
        case .feedback(.resumeUploaded):
            state.isLoading = false
            state.hasUploadedResume = true
            state.isAuthenticated = true
            
        case .feedback(.passwordChanged):
            state.isLoading = false
            state.authFlow = .login
        }
        
        return nil
    }
}
