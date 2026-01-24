//
//  SimpleResumeUploadView.swift
//  InterPrep
//
//  Simple resume upload view for auth flow
//

import SwiftUI
import DesignSystem

struct SimpleResumeUploadView: View {
    let model: Model
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient.brandBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(minHeight: 20)
                
                // Illustration
                Image("upload_resume")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 280, height: 280)
                    .padding(.bottom, 32)
                
                // Text
                VStack(spacing: 12) {
                    Text("Загрузите свое резюме,\nчтобы получить\nперсональные рекомендации")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Мы подберем вакансии\nспециально для вас")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                    .frame(minHeight: 20)
                
                // Buttons
                VStack(spacing: 16) {
                    Button {
                        model.onUpload()
                    } label: {
                        if model.isLoading {
                            ProgressView()
                                .tint(.brandPrimary)
                        } else {
                            Text("Загрузить резюме")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white)
                    .foregroundColor(.brandPrimary)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .disabled(model.isLoading)
                    
                    Button {
                        model.onSkip()
                    } label: {
                        Text("Пропустить")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Model

extension SimpleResumeUploadView {
    struct Model {
        let isLoading: Bool
        let onUpload: () -> Void
        let onSkip: () -> Void
    }
}

// MARK: - Preview

#Preview {
    SimpleResumeUploadView(model: .init(
        isLoading: false,
        onUpload: {},
        onSkip: {}
    ))
}
