//
//  AuthState.swift
//  InterPrep
//
//  Auth module state
//

import ArchitectureCore
import Foundation
import ResumeUploadFeature

public struct AuthState {
    public var authFlow: AuthFlow = .login
    public var isLoading = false
    public var errorMessage: String?
    public var isAuthenticated = false
    
    public init() {}

    public var loginEmail = ""
    public var loginPassword = ""

    public var registrationFirstName = ""
    public var registrationLastName = ""
    public var registrationEmail = ""
    public var registrationPassword = ""
    public var registrationPasswordConfirm = ""
    
    public var resetEmail = ""
    
    public var otpCode = ""
    public var otpEmail = ""
    public var hasUploadedResume = false
    
    public var newPassword = ""
    public var newPasswordConfirm = ""
    
    public var resumeUploadStatus: ResumeUploadState.UploadStatus = .idle
    public var selectedResumeFile: ResumeUploadState.SelectedFile?
    public var resumeUploadProgress: Double = 0.0
    public var resumeUploadError: String?
    
    public enum AuthFlow: Equatable, Sendable {
        case login
        case registration
        case registrationDetails
        case passwordReset
        case otpVerification
        case resumeUpload
        case fullResumeUpload
        case resumeProfileReview
        case newPassword
    }
}

extension AuthState: FeatureState {
    public enum Input: Sendable {
        case showLogin
        case showRegistration
        case showPasswordReset
        case backTapped
        
        case loginEmailChanged(String)
        case loginPasswordChanged(String)
        case loginTapped
        case forgotPasswordTapped
        
        case registrationFirstNameChanged(String)
        case registrationLastNameChanged(String)
        case registrationContinueTapped
        
        case registrationEmailChanged(String)
        case registrationPasswordChanged(String)
        case registrationPasswordConfirmChanged(String)
        case registrationSubmitTapped

        case resetEmailChanged(String)
        case sendResetCodeTapped
        
        case otpCodeChanged(String)
        case otpSubmitTapped
        case otpResendTapped
        
        case resumeUploadTapped
        case resumeSkipTapped
        
        case resumeFileSelected(URL)
        case resumeUploadFileTapped
        case resumeRemoveFileTapped
        case resumeUploadCancelTapped
        
        case profileConfirmTapped
        
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
        
        case resumeFileValidated(ResumeUploadState.SelectedFile)
        case resumeFileValidationFailed(String)
        case resumeUploadProgress(Double)
        case resumeUploadCompleted
        case resumeUploadFailed(String)
    }
    
    public enum Effect: Sendable {
        case performLogin(email: String, password: String)
        case performRegistration(firstName: String, lastName: String, email: String, password: String)
        case sendResetCode(email: String)
        case verifyOTP(email: String, code: String)
        case uploadResume
        case changePassword(email: String, code: String, newPassword: String)
        
        case validateResumeFile(URL)
        case uploadResumeFile(ResumeUploadState.SelectedFile)
        case cancelResumeUpload
    }
    
    @MainActor
    public static func reduce(
        state: inout Self,
        with message: Message<Input, Feedback>
    ) -> Effect? {
        switch message {
        case .input(let input):
            return handleInput(state: &state, input: input)
        case .feedback(let feedback):
            return handleFeedback(state: &state, feedback: feedback)
        }
    }
    
    @MainActor
    // swiftlint:disable:next function_body_length
    private static func handleInput(state: inout Self, input: Input) -> Effect? {
        switch input {
        case .showLogin:
            state.authFlow = .login
            state.errorMessage = nil
            
        case .showRegistration:
            state.authFlow = .registration
            state.errorMessage = nil
            
        case .showPasswordReset:
            state.authFlow = .passwordReset
            state.errorMessage = nil
            
        case .backTapped:
            handleBackTapped(state: &state)
            state.errorMessage = nil
            
        case let .loginEmailChanged(email):
            state.loginEmail = email
            state.errorMessage = nil
            
        case let .loginPasswordChanged(password):
            state.loginPassword = password
            state.errorMessage = nil
            
        case .loginTapped:
            return handleLoginTapped(state: &state)
            
        case .forgotPasswordTapped:
            state.authFlow = .passwordReset
            
        case let .registrationFirstNameChanged(name):
            state.registrationFirstName = name
            state.errorMessage = nil
            
        case let .registrationLastNameChanged(name):
            state.registrationLastName = name
            state.errorMessage = nil
            
        case .registrationContinueTapped:
            return handleRegistrationContinue(state: &state)
            
        case let .registrationEmailChanged(email):
            state.registrationEmail = email
            state.errorMessage = nil
            
        case let .registrationPasswordChanged(password):
            state.registrationPassword = password
            state.errorMessage = nil
            
        case let .registrationPasswordConfirmChanged(password):
            state.registrationPasswordConfirm = password
            state.errorMessage = nil
            
        case .registrationSubmitTapped:
            return handleRegistrationSubmit(state: &state)
            
        case let .resetEmailChanged(email):
            state.resetEmail = email
            state.errorMessage = nil
            
        case .sendResetCodeTapped:
            return handleSendResetCode(state: &state)
            
        case let .otpCodeChanged(code):
            state.otpCode = code
            state.errorMessage = nil
            
        case .otpSubmitTapped:
            return handleOTPSubmit(state: &state)
            
        case .otpResendTapped:
            return .sendResetCode(email: state.otpEmail)
            
        case .resumeUploadTapped:
            state.authFlow = .fullResumeUpload
            state.resumeUploadStatus = .idle
            state.selectedResumeFile = nil
            state.resumeUploadError = nil
            
        case .resumeSkipTapped:
            state.isAuthenticated = true
            
        case let .resumeFileSelected(url):
            state.resumeUploadStatus = .idle
            state.resumeUploadError = nil
            return .validateResumeFile(url)
            
        case .resumeUploadFileTapped:
            guard let file = state.selectedResumeFile else { return nil }
            state.resumeUploadStatus = .uploading
            state.resumeUploadProgress = 0.0
            state.resumeUploadError = nil
            return .uploadResumeFile(file)
            
        case .resumeRemoveFileTapped:
            state.selectedResumeFile = nil
            state.resumeUploadStatus = .idle
            state.resumeUploadProgress = 0.0
            state.resumeUploadError = nil
            
        case .resumeUploadCancelTapped:
            if state.resumeUploadStatus == .uploading {
                return .cancelResumeUpload
            }
            state.authFlow = .resumeUpload
            state.resumeUploadStatus = .idle
            state.selectedResumeFile = nil
            
        case .profileConfirmTapped:
            state.isAuthenticated = true
            
        case let .newPasswordChanged(password):
            state.newPassword = password
            state.errorMessage = nil
            
        case let .newPasswordConfirmChanged(password):
            state.newPasswordConfirm = password
            state.errorMessage = nil
            
        case .newPasswordSubmitTapped:
            return handleNewPasswordSubmit(state: &state)
        }
        
        return nil
    }
    
    @MainActor
    private static func handleFeedback(state: inout Self, feedback: Feedback) -> Effect? {
        switch feedback {
        case .loginSuccess:
            state.isLoading = false
            state.isAuthenticated = true
            
        case let .loginFailed(error):
            state.isLoading = false
            state.errorMessage = error
            
        case .registrationSuccess:
            state.isLoading = false
            state.authFlow = .resumeUpload
            
        case let .registrationFailed(error):
            state.isLoading = false
            state.errorMessage = error
            
        case .resetCodeSent:
            state.isLoading = false
            state.otpEmail = state.resetEmail
            state.authFlow = .otpVerification
            
        case let .resetCodeFailed(error):
            state.isLoading = false
            state.errorMessage = error
            
        case .otpVerified:
            state.isLoading = false
            state.authFlow = .newPassword
            
        case let .otpFailed(error):
            state.isLoading = false
            state.errorMessage = error
            
        case .resumeUploaded:
            state.isLoading = false
            state.hasUploadedResume = true
            state.isAuthenticated = true
            
        case let .resumeFileValidated(file):
            state.selectedResumeFile = file
            state.resumeUploadStatus = .selected
            
        case let .resumeFileValidationFailed(error):
            state.resumeUploadError = error
            state.resumeUploadStatus = .failed
            
        case let .resumeUploadProgress(progress):
            state.resumeUploadProgress = progress
            
        case .resumeUploadCompleted:
            state.resumeUploadStatus = .success
            state.resumeUploadProgress = 1.0
            state.hasUploadedResume = true
            state.authFlow = .resumeProfileReview
            
        case let .resumeUploadFailed(error):
            state.resumeUploadStatus = .failed
            state.resumeUploadError = error
            state.resumeUploadProgress = 0.0
            
        case .passwordChanged:
            state.isLoading = false
            state.authFlow = .login
        }
        
        return nil
    }
    
    @MainActor
    private static func handleBackTapped(state: inout Self) {
        switch state.authFlow {
        case .registrationDetails:
            state.authFlow = .registration
        case .otpVerification:
            state.authFlow = .passwordReset
        case .newPassword:
            state.authFlow = .otpVerification
        case .fullResumeUpload:
            state.authFlow = .resumeUpload
            state.resumeUploadStatus = .idle
            state.selectedResumeFile = nil
            state.resumeUploadError = nil
        case .resumeProfileReview:
            state.isAuthenticated = true
        default:
            state.authFlow = .login
        }
    }
    
    @MainActor
    private static func handleLoginTapped(state: inout Self) -> Effect? {
        guard !state.loginEmail.isEmpty, !state.loginPassword.isEmpty else {
            state.errorMessage = "Заполните все поля"
            return nil
        }
        state.isLoading = true
        state.errorMessage = nil
        return .performLogin(email: state.loginEmail, password: state.loginPassword)
    }
    
    @MainActor
    private static func handleRegistrationContinue(state: inout Self) -> Effect? {
        guard !state.registrationFirstName.isEmpty, !state.registrationLastName.isEmpty else {
            state.errorMessage = "Заполните все поля"
            return nil
        }
        state.authFlow = .registrationDetails
        state.errorMessage = nil
        return nil
    }
    
    @MainActor
    private static func handleRegistrationSubmit(state: inout Self) -> Effect? {
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
    }
    
    @MainActor
    private static func handleSendResetCode(state: inout Self) -> Effect? {
        guard !state.resetEmail.isEmpty else {
            state.errorMessage = "Введите email"
            return nil
        }
        state.isLoading = true
        state.errorMessage = nil
        return .sendResetCode(email: state.resetEmail)
    }
    
    @MainActor
    private static func handleOTPSubmit(state: inout Self) -> Effect? {
        guard state.otpCode.count == 6 else {
            state.errorMessage = "Введите код из 6 символов"
            return nil
        }
        state.isLoading = true
        return .verifyOTP(email: state.otpEmail, code: state.otpCode)
    }
    
    @MainActor
    private static func handleNewPasswordSubmit(state: inout Self) -> Effect? {
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
    }
}
