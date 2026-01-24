//
//  OTPView.swift
//  InterPrep
//
//  OTP verification screen
//

import SwiftUI

struct OTPView: View {
    let model: Model
    @FocusState private var isFocused: Bool
    @State private var otpDigits: [String] = ["", "", "", ""]
    
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
                    VStack(spacing: 8) {
                        Text("InterPrep")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Введите код из письма на\nпочте")
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.bottom, 40)
                    
                    // OTP Fields
                    HStack(spacing: 12) {
                        ForEach(0..<4, id: \.self) { index in
                            OTPDigitField(
                                digit: Binding(
                                    get: { otpDigits[index] },
                                    set: { newValue in
                                        if newValue.count <= 1 {
                                            otpDigits[index] = newValue
                                            updateFullCode()
                                        }
                                    }
                                ),
                                isFocused: $isFocused
                            )
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    // Resend button
                    Button {
                        model.onResend()
                    } label: {
                        Text("Отправить код повторно")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
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
                isFocused = true
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
    var isFocused: FocusState<Bool>.Binding
    
    init(digit: Binding<String>, isFocused: FocusState<Bool>.Binding) {
        self._digit = digit
        self.isFocused = isFocused
    }
    
    var body: some View {
        TextField("", text: $digit)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.title)
            .frame(width: 60, height: 60)
            .background(Color.white.opacity(0.9))
            .cornerRadius(12)
            .focused(isFocused)
    }
}

// MARK: - Model

extension OTPView {
    struct Model {
        let code: String
        let isLoading: Bool
        let errorMessage: String?
        let onCodeChanged: (String) -> Void
        let onSubmit: () -> Void
        let onResend: () -> Void
    }
}

// MARK: - Preview

#Preview {
    OTPView(model: .init(
        code: "",
        isLoading: false,
        errorMessage: nil,
        onCodeChanged: { _ in },
        onSubmit: {},
        onResend: {}
    ))
}
