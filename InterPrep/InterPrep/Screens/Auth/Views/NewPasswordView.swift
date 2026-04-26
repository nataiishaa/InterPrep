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
            LinearGradient(
                colors: [Layout.gradientTop, Layout.gradientBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Layout.mainStackSpacing) {
                    Spacer()
                        .frame(height: Layout.topSpacerHeight)
                    
                    VStack(spacing: Layout.titleBlockSpacing) {
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
                    .padding(.bottom, Layout.titleBottomPadding)
                    
                    VStack(alignment: .leading, spacing: Layout.fieldBlockSpacing) {
                        HStack(spacing: Layout.fieldRowSpacing) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: Layout.leadingIconWidth)
                            
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
                        .cornerRadius(Layout.fieldCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.fieldCornerRadius)
                                .stroke(Color.white.opacity(0.3), lineWidth: Layout.fieldStrokeWidth)
                        )
                    }
                    .padding(.horizontal, Layout.horizontalPadding)
                    
                    VStack(alignment: .leading, spacing: Layout.fieldBlockSpacing) {
                        HStack(spacing: Layout.fieldRowSpacing) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: Layout.leadingIconWidth)
                            
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
                        .cornerRadius(Layout.fieldCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.fieldCornerRadius)
                                .stroke(Color.white.opacity(0.3), lineWidth: Layout.fieldStrokeWidth)
                        )
                    }
                    .padding(.horizontal, Layout.horizontalPadding)
                    
                    if !model.password.isEmpty {
                        HStack(spacing: Layout.strengthBarSpacing) {
                            ForEach(0..<Layout.strengthSegmentCount, id: \.self) { index in
                                Rectangle()
                                    .fill(passwordStrengthColor(for: index))
                                    .frame(height: Layout.strengthBarHeight)
                                    .cornerRadius(Layout.strengthBarCornerRadius)
                            }
                        }
                        .padding(.horizontal, Layout.horizontalPadding)
                        .padding(.top, Layout.strengthBarsTopInset)
                        
                        Text(passwordStrengthText)
                            .font(.caption)
                            .foregroundColor(passwordStrengthColor(for: .zero))
                            .padding(.horizontal, Layout.horizontalPadding)
                            .padding(.top, Layout.strengthCaptionTopInset)
                    }
                    
                    if let errorMessage = model.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, Layout.horizontalPadding)
                            .transition(.opacity)
                    }
                    
                    Spacer()
                    
                    Button {
                        model.onSubmit()
                    } label: {
                        if model.isLoading {
                            ProgressView()
                                .tint(Layout.submitButtonForeground)
                        } else {
                            Text("Сохранить пароль")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: Layout.submitButtonHeight)
                    .background(Color.white)
                    .foregroundColor(Layout.submitButtonForeground)
                    .cornerRadius(Layout.submitButtonCornerRadius)
                    .disabled(model.isLoading || model.password.isEmpty || model.passwordConfirm.isEmpty)
                    .opacity(
                        (model.password.isEmpty || model.passwordConfirm.isEmpty)
                            ? Layout.submitButtonDisabledOpacity
                            : Layout.submitButtonEnabledOpacity
                    )
                    .padding(.horizontal, Layout.horizontalPadding)
                    .padding(.bottom, Layout.bottomPadding)
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

extension NewPasswordView {
    enum Layout {
        static let mainStackSpacing: CGFloat = 24
        static let topSpacerHeight: CGFloat = 40
        static let titleBlockSpacing: CGFloat = 12
        static let titleBottomPadding: CGFloat = 32
        static let fieldBlockSpacing: CGFloat = 8
        static let fieldRowSpacing: CGFloat = 8
        static let leadingIconWidth: CGFloat = 20
        static let fieldCornerRadius: CGFloat = 12
        static let fieldStrokeWidth: CGFloat = 1
        static let horizontalPadding: CGFloat = 32
        static let strengthBarSpacing: CGFloat = 4
        static let strengthSegmentCount = 4
        static let strengthBarHeight: CGFloat = 4
        static let strengthBarCornerRadius: CGFloat = 2
        static let strengthBarsTopInset: CGFloat = -8
        static let strengthCaptionTopInset: CGFloat = -16
        static let submitButtonHeight: CGFloat = 50
        static let submitButtonCornerRadius: CGFloat = 12
        static let submitButtonDisabledOpacity: Double = 0.6
        static let submitButtonEnabledOpacity: Double = 1.0
        static let bottomPadding: CGFloat = 20
        static let gradientTop = Color(red: 0.45, green: 0.5, blue: 0.45)
        static let gradientBottom = Color(red: 0.35, green: 0.4, blue: 0.35)
        static var submitButtonForeground: Color { gradientBottom }
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
