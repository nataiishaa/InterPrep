//
//  RegistrationViewSnapshotTests.swift
//  AuthFeatureTests
//
//  Snapshot tests for RegistrationView
//

@testable import AuthFeature
import SnapshotTesting
import SwiftUI
import XCTest

final class RegistrationViewSnapshotTests: SnapshotTestCase {

    // MARK: - Tests
    
    func testRegistrationView_default() {
        let view = RegistrationView(model: .init(
            firstName: "",
            lastName: "",
            errorMessage: nil,
            onFirstNameChanged: { _ in },
            onLastNameChanged: { _ in },
            onContinue: {}
        ))
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "default"
        )
    }
    
    func testRegistrationView_filled() {
        let view = RegistrationView(model: .init(
            firstName: "Иван",
            lastName: "Иванов",
            errorMessage: nil,
            onFirstNameChanged: { _ in },
            onLastNameChanged: { _ in },
            onContinue: {}
        ))
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "filled"
        )
    }
    
    func testRegistrationView_withError() {
        let view = RegistrationView(model: .init(
            firstName: "",
            lastName: "",
            errorMessage: "Заполните все поля",
            onFirstNameChanged: { _ in },
            onLastNameChanged: { _ in },
            onContinue: {}
        ))
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "withError"
        )
    }
}
