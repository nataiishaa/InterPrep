//
//  LoginViewSnapshotTests.swift
//  AuthFeatureTests
//
//  Snapshot tests for LoginView
//

import XCTest
import SwiftUI
import SnapshotTesting
@testable import AuthFeature

final class LoginViewSnapshotTests: SnapshotTestCase {

    // MARK: - Tests
    
    func testLoginView_default() {
        let view = LoginView(model: .fixture())
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "default"
        )
    }
    
    func testLoginView_filled() {
        let view = LoginView(model: .fixture(
            email: "user@example.com",
            password: "password123"
        ))
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "filled"
        )
    }
    
    func testLoginView_loading() {
        let view = LoginView(model: .fixture(isLoading: true))
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "loading"
        )
    }
    
    func testLoginView_withError() {
        let view = LoginView(model: .fixture(
            errorMessage: "Неверный email или пароль"
        ))
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "withError"
        )
    }
    
    func testLoginView_iPhone14Pro() {
        let view = LoginView(model: .fixture())
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "iPhone14Pro"
        )
    }
    
    func testLoginView_iPhoneSE() {
        let view = LoginView(model: .fixture())
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhoneSe),
            named: "iPhoneSE"
        )
    }
}
