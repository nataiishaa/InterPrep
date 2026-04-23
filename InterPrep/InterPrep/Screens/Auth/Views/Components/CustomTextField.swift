//
//  CustomTextField.swift
//  InterPrep
//
//  Custom text field component
//

import SwiftUI

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    
    @State private var isSecureVisible: Bool = false
    
    init(
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default
    ) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.keyboardType = keyboardType
    }
    
    var body: some View {
        HStack {
            if isSecure && !isSecureVisible {
                SecureField(placeholder, text: $text)
                    .textContentType(.password)
                    .autocorrectionDisabled()
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textContentType(isSecure ? .password : .emailAddress)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                    .autocorrectionDisabled(keyboardType == .emailAddress)
            }
            
            if isSecure {
                Button(action: {
                    isSecureVisible.toggle()
                }, label: {
                    Image(systemName: isSecureVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.iconTint)
                })
            }
        }
        .padding()
        .background(Color.fieldBackground)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        CustomTextField(
            placeholder: "Email",
            text: .constant(""),
            keyboardType: .emailAddress
        )
        
        CustomTextField(
            placeholder: "Password",
            text: .constant(""),
            isSecure: true
        )
    }
    .padding()
    .background(Color.gray)
}
