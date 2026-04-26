//
//  PasswordResetView.swift
//  InterPrep
//
//  Password reset screen
//

import SwiftUI

struct PasswordResetView: View {
    let model: Model
    @FocusState private var isFocused: Bool
    
    init(model: Model) {
        self.model = model
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
                    Spacer()
                        .frame(height: 40)
                    
                    VStack(spacing: 8) {
                        Text("InterPrep")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("На какую почту был\nзарегистрирован аккаунт?")
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.bottom, 40)
                    
                    CustomTextField(
                        placeholder: "Почта",
                        text: Binding(
                            get: { model.email },
                            set: { model.onEmailChanged($0) }
                        ),
                        keyboardType: .emailAddress
                    )
                    .focused($isFocused)
                    .submitLabel(.send)
                    .onSubmit { model.onSendCode() }
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
                        model.onSendCode()
                    } label: {
                        if model.isLoading {
                            ProgressView()
                                .tint(Color(red: 0.35, green: 0.4, blue: 0.35))
                        } else {
                            Text("Отправить код")
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
    PasswordResetView(model: .init(
        email: "",
        isLoading: false,
        errorMessage: nil,
        onEmailChanged: { _ in },
        onSendCode: {}
    ))
}
