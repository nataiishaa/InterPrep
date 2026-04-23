//
//  LoginView.swift
//  InterPrep
//
//  Login screen view
//

import DesignSystem
import SwiftUI

struct LoginView: View {
    let model: Model
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    init(model: Model) {
        self.model = model
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Layout.sectionSpacing) {
                Spacer()
                    .frame(height: Layout.topSpacing)
                
                titleSection
                
                formSection
                
                errorSection
                
                Spacer()
                
                loginButton
            }
        }
        .background(backgroundGradient)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("InterPrep")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            
            Text("Уже есть аккаунт?\nВойдите, чтобы продолжить")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.textSecondary)
        }
        .padding(.bottom, Layout.titleBottomPadding)
    }
    
    @ViewBuilder
    private var formSection: some View {
        VStack(spacing: Layout.fieldSpacing) {
            emailField
            passwordField
            forgotPasswordButton
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }
    
    @ViewBuilder
    private var emailField: some View {
        CustomTextField(
            placeholder: "Почта",
            text: Binding(
                get: { model.email },
                set: { model.onEmailChanged($0) }
            ),
            keyboardType: .emailAddress
        )
        .focused($focusedField, equals: .email)
        .submitLabel(.next)
        .onSubmit { focusedField = .password }
    }
    
    @ViewBuilder
    private var passwordField: some View {
        CustomTextField(
            placeholder: "Пароль",
            text: Binding(
                get: { model.password },
                set: { model.onPasswordChanged($0) }
            ),
            isSecure: true
        )
        .focused($focusedField, equals: .password)
        .submitLabel(.go)
        .onSubmit { model.onLogin() }
    }
    
    @ViewBuilder
    private var forgotPasswordButton: some View {
        Button {
            model.onForgotPassword()
        } label: {
            Text("Забыли пароль?")
                .font(.subheadline)
                .foregroundColor(.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var errorSection: some View {
        if let errorMessage = model.errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundColor(.errorText)
                .padding(.horizontal, Layout.horizontalPadding)
                .transition(.opacity)
        }
    }
    
    @ViewBuilder
    private var loginButton: some View {
        VStack(spacing: Layout.fieldSpacing) {
            Button {
                model.onLogin()
            } label: {
                if model.isLoading {
                    ProgressView()
                        .tint(.brandPrimary)
                } else {
                    Text("Продолжить")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: Layout.buttonHeight)
            .background(Color.buttonBackground)
            .foregroundColor(.buttonText)
            .cornerRadius(12)
            .disabled(model.isLoading)
            .padding(.horizontal, Layout.horizontalPadding)
        }
        .padding(.bottom, Layout.bottomPadding)
    }
    
    @ViewBuilder
    private var backgroundGradient: some View {
        LinearGradient.brandBackground
            .ignoresSafeArea()
    }
}

// MARK: - Layout

private extension LoginView {
    enum Layout {
        static var topSpacing: CGFloat { 40 }
        static var titleBottomPadding: CGFloat { 40 }
        static var fieldSpacing: CGFloat { 16 }
        static var horizontalPadding: CGFloat { 32 }
        static var buttonHeight: CGFloat { 50 }
        static var bottomPadding: CGFloat { 20 }
        static var sectionSpacing: CGFloat { 24 }
    }
}

struct LoginViewPreviews: SwiftUI.PreviewProvider {
    static var previews: some View {
        Group {
            LoginView(model: .fixture())
                .previewDisplayName("Default")
            LoginView(model: .loading)
                .previewDisplayName("Loading")
            LoginView(model: .fixtureWithError)
                .previewDisplayName("With Error")
            LoginView(model: .filled)
                .previewDisplayName("Filled")
        }
    }
}
