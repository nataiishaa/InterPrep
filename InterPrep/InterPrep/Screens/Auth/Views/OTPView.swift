//
//  OTPView.swift
//  InterPrep
//
//  OTP verification screen
//

import SwiftUI

struct OTPView: View {
    let model: Model
    @FocusState private var focusedField: Int?
    @State private var otpDigits: [String] = ["", "", "", "", "", ""]
    @State private var resendTimer: Int = 60
    @State private var canResend: Bool = false
    
    init(model: Model) {
        self.model = model
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
                        
                        Text("Введите код подтверждения")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        if let email = model.email {
                            Text("Код отправлен на")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(email)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        } else {
                            Text("Код отправлен на вашу почту")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 32)
                    
                    // OTP Fields
                    HStack(spacing: 8) {
                        ForEach(0..<6, id: \.self) { index in
                            OTPDigitField(
                                digit: Binding(
                                    get: { otpDigits[index] },
                                    set: { newValue in
                                        handleDigitChange(at: index, newValue: newValue)
                                    }
                                ),
                                index: index,
                                focusedField: $focusedField
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Resend button
                    Button {
                        if canResend {
                            model.onResend()
                            startResendTimer()
                        }
                    } label: {
                        if canResend {
                            Text("Отправить код повторно")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        } else {
                            Text("Отправить повторно через \(resendTimer) сек")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .disabled(!canResend)
                    .padding(.top, 8)
                    
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
                            Text("Отправить")
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
            .onAppear {
                focusedField = 0
                startResendTimer()
            }
        }
    }
    
    private func startResendTimer() {
        canResend = false
        resendTimer = 60
        
        Task {
            while resendTimer > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    resendTimer -= 1
                    if resendTimer == 0 {
                        canResend = true
                    }
                }
            }
        }
    }
    
    private func handleDigitChange(at index: Int, newValue: String) {
        // Если вставили несколько символов (например, из буфера обмена)
        if newValue.count > 1 {
            let digits = Array(newValue.prefix(6))
            for (i, char) in digits.enumerated() where i < 6 {
                otpDigits[i] = String(char)
            }
            updateFullCode()
            // Фокус на последнее заполненное поле или на первое пустое
            if digits.count == 6 {
                focusedField = nil
            } else {
                focusedField = min(digits.count, 5)
            }
            return
        }
        
        // Обычный ввод одного символа
        if newValue.count <= 1 {
            otpDigits[index] = newValue
            updateFullCode()
            
            // Автоматический переход к следующему полю
            if !newValue.isEmpty && index < 5 {
                focusedField = index + 1
            }
        }
    }
    
    private func updateFullCode() {
        let code = otpDigits.joined()
        model.onCodeChanged(code)
    }
}

// MARK: - OTP Digit Field

struct OTPDigitField: View {
    @Binding var digit: String
    let index: Int
    @FocusState.Binding var focusedField: Int?
    
    init(digit: Binding<String>, index: Int, focusedField: FocusState<Int?>.Binding) {
        self._digit = digit
        self.index = index
        self._focusedField = focusedField
    }
    
    var body: some View {
        ZStack {
            // Скрытое текстовое поле для ввода
            TextField("", text: $digit)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.title2)
                .fontWeight(.semibold)
                .frame(width: 50, height: 56)
                .opacity(0.01)
                .focused($focusedField, equals: index)
                .onChange(of: digit) { _, newValue in
                    // Ограничиваем ввод одним символом
                    if newValue.count > 1 {
                        digit = String(newValue.prefix(1))
                    }
                }
            
            // Визуальное представление
            Text(digit.isEmpty ? "" : digit)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.35, green: 0.4, blue: 0.35))
                .frame(width: 50, height: 56)
                .background(Color.white.opacity(digit.isEmpty ? 0.7 : 0.95))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focusedField == index ? Color.white : Color.white.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: focusedField == index ? Color.white.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 0)
        }
    }
}

// MARK: - Preview

#Preview {
    OTPView(model: .init(
        code: "",
        email: "ivan@mail.ru",
        isLoading: false,
        errorMessage: nil,
        onCodeChanged: { _ in },
        onSubmit: {},
        onResend: {}
    ))
}
