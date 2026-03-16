//
//  RegistrationDetailsViewSnapshotTests.swift
//  AuthFeatureTests
//
//  Snapshot tests for RegistrationDetailsView
//

import XCTest
import SwiftUI
import SnapshotTesting
@testable import AuthFeature

final class RegistrationDetailsViewSnapshotTests: SnapshotTestCase {

    // MARK: - Tests
    
    func testRegistrationDetailsView_default() {
        let view = RegistrationDetailsView(model: .init(
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
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "default"
        )
    }
    
    func testRegistrationDetailsView_filled() {
        let view = RegistrationDetailsView(model: .init(
            email: "user@example.com",
            password: "password123",
            passwordConfirm: "password123",
            isLoading: false,
            errorMessage: nil,
            onEmailChanged: { _ in },
            onPasswordChanged: { _ in },
            onPasswordConfirmChanged: { _ in },
            onSubmit: {}
        ))
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "filled"
        )
    }
    
    func testRegistrationDetailsView_loading() {
        let view = RegistrationDetailsView(model: .init(
            email: "user@example.com",
            password: "password123",
            passwordConfirm: "password123",
            isLoading: true,
            errorMessage: nil,
            onEmailChanged: { _ in },
            onPasswordChanged: { _ in },
            onPasswordConfirmChanged: { _ in },
            onSubmit: {}
        ))
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "loading"
        )
    }
    
    func testRegistrationDetailsView_withError() {
        let view = RegistrationDetailsView(model: .init(
            email: "user@example.com",
            password: "password123",
            passwordConfirm: "different",
            isLoading: false,
            errorMessage: "Пароли не совпадают",
            onEmailChanged: { _ in },
            onPasswordChanged: { _ in },
            onPasswordConfirmChanged: { _ in },
            onSubmit: {}
        ))
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "withError"
        )
    }
}
