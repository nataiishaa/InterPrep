//  NewPasswordView.swift
//  InterPrep
//
//  New password screen after OTP verification
//

import SwiftUI

struct NewPasswordView: View {
    let model: Model
    @FocusState private var focusedField: Field?
    @State private var showPassword: Bool = false
    @State private var showPasswordConfirm: Bool = false
    
    init(model: Model) {
        self.model = model
    }
    
    enum Field: Hashable {
        case password
        case passwordConfirm
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background
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
                    Spacer()
                        .frame(height: 40)
                    
                    // Title
                    VStack(spacing: 12) {
                        Text("InterPrep")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Создайте новый пароль")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 32)
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 20)
                            
                            if showPassword {
                                TextField("Новый пароль", text: Binding(
                                    get: { model.password },
                                    set: { model.onPasswordChanged($0) }
                                ))
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                                .autocapitalization(.none)
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .password)
                            } else {
                                SecureField("Новый пароль", text: Binding(
                                    get: { model.password },
                                    set: { model.onPasswordChanged($0) }
                                ))
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .password)
                            }
                            
                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 32)
                    
                    // Password confirm field
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 20)
                            
                            if showPasswordConfirm {
                                TextField("Повторите пароль", text: Binding(
                                    get: { model.passwordConfirm },
                                    set: { model.onPasswordConfirmChanged($0) }
                                ))
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                                .autocapitalization(.none)
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .passwordConfirm)
                                .submitLabel(.done)
                                .onSubmit { model.onSubmit() }
                            } else {
                                SecureField("Повторите пароль", text: Binding(
                                    get: { model.passwordConfirm },
                                    set: { model.onPasswordConfirmChanged($0) }
                                ))
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .passwordConfirm)
                                .submitLabel(.done)
                                .onSubmit { model.onSubmit() }
                            }
                            
                            Button {
                                showPasswordConfirm.toggle()
                            } label: {
                                Image(systemName: showPasswordConfirm ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 32)
                    
                    // Password strength indicator
                    if !model.password.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(0..<4) { index in
                                Rectangle()
                                    .fill(passwordStrengthColor(for: index))
                                    .frame(height: 4)
                                    .cornerRadius(2)
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, -8)
                        
                        Text(passwordStrengthText)
                            .font(.caption)
                            .foregroundColor(passwordStrengthColor(for: 0))
                            .padding(.horizontal, 32)
                            .padding(.top, -16)
                    }
                    
                    // Error message
                    if let errorMessage = model.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 32)
                            .transition(.opacity)
                    }
                    
                    Spacer()
                    
                    // Button
                    Button {
                        model.onSubmit()
                    } label: {
                        if model.isLoading {
                            ProgressView()
                                .tint(Color(red: 0.35, green: 0.4, blue: 0.35))
                        } else {
                            Text("Сохранить пароль")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .foregroundColor(Color(red: 0.35, green: 0.4, blue: 0.35))
                    .cornerRadius(12)
                    .disabled(model.isLoading || model.password.isEmpty || model.passwordConfirm.isEmpty)
                    .opacity((model.password.isEmpty || model.passwordConfirm.isEmpty) ? 0.6 : 1.0)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)
                }
            }
            .onAppear {
                focusedField = .password
            }
        }
    }
    
    // MARK: - Password Strength
    
    private var passwordStrength: Int {
        var strength = 0
        let password = model.password
        
        if password.count >= 6 { strength += 1 }
        if password.count >= 8 { strength += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { strength += 1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil { strength += 1 }
        
        return strength
    }
    
    private var passwordStrengthText: String {
        switch passwordStrength {
        case 0...1: return "Слабый пароль"
        case 2: return "Средний пароль"
        case 3: return "Хороший пароль"
        case 4: return "Отличный пароль"
        default: return ""
        }
    }
    
    private func passwordStrengthColor(for index: Int) -> Color {
        guard index < passwordStrength else {
            return Color.white.opacity(0.3)
        }
        
        switch passwordStrength {
        case 0...1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        default: return .white.opacity(0.3)
        }
    }
}

// MARK: - Preview

#Preview {
    NewPasswordView(model: .init(
        password: "",
        passwordConfirm: "",
        isLoading: false,
        errorMessage: nil,
        onPasswordChanged: { _ in },
        onPasswordConfirmChanged: { _ in },
        onSubmit: {}
    ))
}
