//
//  RegistrationView.swift
//  InterPrep
//
//  Registration screen view (Step 1 - Name)
//

import SwiftUI

struct RegistrationView: View {
    let model: Model
    @FocusState private var focusedField: Field?
    
    enum Field {
        case firstName, lastName
    }
    
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
                    // Progress indicator
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 30, height: 4)
                        
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 30, height: 4)
                    }
                    .padding(.top, 60)
                    
                    Spacer()
                        .frame(height: 20)
                    
                    // Title
                    Text("Давайте знакомиться!\nКак вас зовут?")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.bottom, 40)
                    
                    // Form
                    VStack(spacing: 16) {
                        CustomTextField(
                            placeholder: "Имя",
                            text: Binding(
                                get: { model.firstName },
                                set: { model.onFirstNameChanged($0) }
                            )
                        )
                        .focused($focusedField, equals: .firstName)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .lastName }
                        
                        CustomTextField(
                            placeholder: "Фамилия",
                            text: Binding(
                                get: { model.lastName },
                                set: { model.onLastNameChanged($0) }
                            )
                        )
                        .focused($focusedField, equals: .lastName)
                        .submitLabel(.continue)
                        .onSubmit { model.onContinue() }
                    }
                    .padding(.horizontal, 32)
                    
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
                        model.onContinue()
                    } label: {
                        Text("Продолжить")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .foregroundColor(Color(red: 0.35, green: 0.4, blue: 0.35))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RegistrationView(model: .init(
        firstName: "",
        lastName: "",
        errorMessage: nil,
        onFirstNameChanged: { _ in },
        onLastNameChanged: { _ in },
        onContinue: {}
    ))
}
