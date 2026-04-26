//
//  RegistrationDetailsView.swift
//  InterPrep
//
//  Registration screen view (Step 2 - Email & Password)
//

import SwiftUI

struct RegistrationDetailsView: View {
    let model: Model
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password, passwordConfirm
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [
                    Color(red: 0.45, green: 0.5, blue: 0.45),
                    Color(red: 0.35, green: 0.4, blue: 0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 30, height: 4)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 30, height: 4)
                    }
                    .padding(.top, 60)
                    
                    Spacer()
                        .frame(height: 20)
                    
                    Text("Регистрация")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.bottom, 40)
                    
                    VStack(spacing: 16) {
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
                        
                        CustomTextField(
                            placeholder: "Пароль",
                            text: Binding(
                                get: { model.password },
                                set: { model.onPasswordChanged($0) }
                            ),
                            isSecure: true
                        )
                        .focused($focusedField, equals: .password)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .passwordConfirm }
                        
                        CustomTextField(
                            placeholder: "Повторите пароль",
                            text: Binding(
                                get: { model.passwordConfirm },
                                set: { model.onPasswordConfirmChanged($0) }
                            ),
                            isSecure: true
                        )
                        .focused($focusedField, equals: .passwordConfirm)
                        .submitLabel(.go)
                        .onSubmit { model.onSubmit() }
                    }
                    .padding(.horizontal, 32)
                    
                    if let errorMessage = model.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 32)
                            .transition(.opacity)
                    }
                    
                    Spacer()
                    
                    Button {
                        model.onSubmit()
                    } label: {
                        if model.isLoading {
                            ProgressView()
                                .tint(Color(red: 0.35, green: 0.4, blue: 0.35))
                        } else {
                            Text("Зарегистрироваться")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .foregroundColor(Color(red: 0.35, green: 0.4, blue: 0.35))
                    .cornerRadius(12)
                    .disabled(model.isLoading)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RegistrationDetailsView(model: .init(
        email: "",
        password: "",
        passwordConfirm: "",
        isLoading: false,
        errorMessage: nil,
        onEmailChanged: { _ in },
        onPasswordChanged: { _ in },
        onPasswordConfirmChanged: { _ in },
        onSubmit: {}
    ))
}
