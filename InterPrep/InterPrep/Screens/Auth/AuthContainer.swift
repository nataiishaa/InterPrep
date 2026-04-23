//
//  AuthContainer.swift
//  InterPrep
//
//  Container for Auth module
//

import ArchitectureCore
import NetworkService
import ResumeUploadFeature
import SwiftUI

public struct AuthContainer: View {
    @StateObject private var store: AuthStore
    let onAuthComplete: () -> Void
    
    public init(
        store: @autoclosure @escaping () -> AuthStore,
        onAuthComplete: @escaping () -> Void
    ) {
        self._store = StateObject(wrappedValue: store())
        self.onAuthComplete = onAuthComplete
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                currentFlowView
                    .animation(.easeInOut(duration: 0.3), value: store.state.authFlow)
                
                if shouldShowBackButton {
                    VStack {
                        HStack {
                            Button {
                                store.send(.backTapped)
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding()
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                }
                
                if store.state.authFlow == .login {
                    VStack {
                        Spacer()
                        Button {
                            store.send(.showRegistration)
                        } label: {
                            Text("Зарегистрироваться")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.vertical, 12)
                        }
                    }
                }
            }
            .onChange(of: store.state.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    onAuthComplete()
                }
            }
        }
    }
    
    private var shouldShowBackButton: Bool {
        switch store.state.authFlow {
        case .login, .resumeUpload, .fullResumeUpload, .resumeProfileReview:
            return false
        default:
            return true
        }
    }
    
    @ViewBuilder
    private var currentFlowView: some View {
        switch store.state.authFlow {
        case .login:
            LoginView(model: makeLoginModel())
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            
        case .registration:
            RegistrationView(model: makeRegistrationModel())
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            
        case .registrationDetails:
            RegistrationDetailsView(model: makeRegistrationDetailsModel())
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            
        case .passwordReset:
            PasswordResetView(model: makePasswordResetModel())
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            
        case .otpVerification:
            OTPView(model: makeOTPModel())
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            
        case .resumeUpload:
            SimpleResumeUploadView(model: makeSimpleResumeUploadModel())
                .transition(.opacity.combined(with: .scale))
            
        case .fullResumeUpload:
            ResumeUploadView(model: makeFullResumeUploadModel())
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            
        case .resumeProfileReview:
            AuthResumeProfileReviewView(
                onConfirm: { store.send(.profileConfirmTapped) },
                onBack: { store.send(.backTapped) }
            )
            .transition(.opacity.combined(with: .move(edge: .trailing)))
            
        case .newPassword:
            NewPasswordView(model: makeNewPasswordModel())
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
    }
    
    private func makeLoginModel() -> LoginView.Model {
        .init(
            email: store.state.loginEmail,
            password: store.state.loginPassword,
            isLoading: store.state.isLoading,
            errorMessage: store.state.errorMessage,
            onEmailChanged: { store.send(.loginEmailChanged($0)) },
            onPasswordChanged: { store.send(.loginPasswordChanged($0)) },
            onLogin: { store.send(.loginTapped) },
            onForgotPassword: { store.send(.forgotPasswordTapped) }
        )
    }
    
    private func makeRegistrationModel() -> RegistrationView.Model {
        .init(
            firstName: store.state.registrationFirstName,
            lastName: store.state.registrationLastName,
            errorMessage: store.state.errorMessage,
            onFirstNameChanged: { store.send(.registrationFirstNameChanged($0)) },
            onLastNameChanged: { store.send(.registrationLastNameChanged($0)) },
            onContinue: { store.send(.registrationContinueTapped) }
        )
    }
    
    private func makeRegistrationDetailsModel() -> RegistrationDetailsView.Model {
        .init(
            email: store.state.registrationEmail,
            password: store.state.registrationPassword,
            passwordConfirm: store.state.registrationPasswordConfirm,
            isLoading: store.state.isLoading,
            errorMessage: store.state.errorMessage,
            onEmailChanged: { store.send(.registrationEmailChanged($0)) },
            onPasswordChanged: { store.send(.registrationPasswordChanged($0)) },
            onPasswordConfirmChanged: { store.send(.registrationPasswordConfirmChanged($0)) },
            onSubmit: { store.send(.registrationSubmitTapped) }
        )
    }
    
    private func makePasswordResetModel() -> PasswordResetView.Model {
        .init(
            email: store.state.resetEmail,
            isLoading: store.state.isLoading,
            errorMessage: store.state.errorMessage,
            onEmailChanged: { store.send(.resetEmailChanged($0)) },
            onSendCode: { store.send(.sendResetCodeTapped) }
        )
    }
    
    private func makeOTPModel() -> OTPView.Model {
        .init(
            code: store.state.otpCode,
            email: store.state.otpEmail.isEmpty ? nil : store.state.otpEmail,
            isLoading: store.state.isLoading,
            errorMessage: store.state.errorMessage,
            onCodeChanged: { store.send(.otpCodeChanged($0)) },
            onSubmit: { store.send(.otpSubmitTapped) },
            onResend: { store.send(.otpResendTapped) }
        )
    }
    
    private func makeSimpleResumeUploadModel() -> SimpleResumeUploadView.Model {
        .init(
            isLoading: store.state.isLoading,
            onUpload: { store.send(.resumeUploadTapped) },
            onSkip: { store.send(.resumeSkipTapped) }
        )
    }
    
    private func makeFullResumeUploadModel() -> ResumeUploadView.Model {
        .init(
            uploadStatus: store.state.resumeUploadStatus,
            selectedFile: store.state.selectedResumeFile,
            uploadProgress: store.state.resumeUploadProgress,
            errorMessage: store.state.resumeUploadError,
            onFileSelected: { url in
                store.send(.resumeFileSelected(url))
            },
            onUpload: {
                store.send(.resumeUploadFileTapped)
            },
            onCancel: {
                store.send(.resumeUploadCancelTapped)
            },
            onSkip: {
                store.send(.resumeSkipTapped)
            },
            onRemoveFile: {
                store.send(.resumeRemoveFileTapped)
            }
        )
    }
    
    private func makeNewPasswordModel() -> NewPasswordView.Model {
        .init(
            password: store.state.newPassword,
            passwordConfirm: store.state.newPasswordConfirm,
            isLoading: store.state.isLoading,
            errorMessage: store.state.errorMessage,
            onPasswordChanged: { store.send(.newPasswordChanged($0)) },
            onPasswordConfirmChanged: { store.send(.newPasswordConfirmChanged($0)) },
            onSubmit: { store.send(.newPasswordSubmitTapped) }
        )
    }
}
