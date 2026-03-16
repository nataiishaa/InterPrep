//
//  PasswordResetViewSnapshotTests.swift
//  AuthFeatureTests
//
//  Snapshot tests for PasswordResetView
//

import XCTest
import SwiftUI
import SnapshotTesting
@testable import AuthFeature

final class PasswordResetViewSnapshotTests: SnapshotTestCase {

    // MARK: - Tests
    
    func testPasswordResetView_default() {
        let view = PasswordResetView(model: .init(
            email: "",
            isLoading: false,
            errorMessage: nil,
            onEmailChanged: { _ in },
            onSendCode: {}
        ))
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "default"
        )
    }
    
    func testPasswordResetView_filled() {
        let view = PasswordResetView(model: .init(
            email: "user@example.com",
            isLoading: false,
            errorMessage: nil,
            onEmailChanged: { _ in },
            onSendCode: {}
        ))
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "filled"
        )
    }
    
    func testPasswordResetView_loading() {
        let view = PasswordResetView(model: .init(
            email: "user@example.com",
            isLoading: true,
            errorMessage: nil,
            onEmailChanged: { _ in },
            onSendCode: {}
        ))
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "loading"
        )
    }
    
    func testPasswordResetView_withError() {
        let view = PasswordResetView(model: .init(
            email: "invalid",
            isLoading: false,
            errorMessage: "Введите корректный email",
            onEmailChanged: { _ in },
            onSendCode: {}
        ))
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "withError"
        )
    }
}
