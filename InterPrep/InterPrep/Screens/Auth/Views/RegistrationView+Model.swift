//
//  RegistrationView+Model.swift
//  InterPrep
//
//  Registration view model
//

import Foundation

extension RegistrationView {
    struct Model {
        let firstName: String
        let lastName: String
        let errorMessage: String?
        let onFirstNameChanged: (String) -> Void
        let onLastNameChanged: (String) -> Void
        let onContinue: () -> Void
    }
}
