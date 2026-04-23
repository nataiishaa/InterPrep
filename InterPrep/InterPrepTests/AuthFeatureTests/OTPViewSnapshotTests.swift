//
//  OTPViewSnapshotTests.swift
//  AuthFeatureTests
//
//  Snapshot tests for OTPView
//

@testable import AuthFeature
import SnapshotTesting
import SwiftUI
import XCTest

final class OTPViewSnapshotTests: SnapshotTestCase {

    // MARK: - Tests
    
    func testOTPView_default() {
        let view = OTPView(model: .init(
            code: "",
            email: nil,
            isLoading: false,
            errorMessage: nil,
            onCodeChanged: { _ in },
            onSubmit: {},
            onResend: {}
        ))
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "default"
        )
    }
    
    func testOTPView_loading() {
        let view = OTPView(model: .init(
            code: "1234",
            email: nil,
            isLoading: true,
            errorMessage: nil,
            onCodeChanged: { _ in },
            onSubmit: {},
            onResend: {}
        ))
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "loading"
        )
    }
    
    func testOTPView_withError() {
        let view = OTPView(model: .init(
            code: "1234",
            email: nil,
            isLoading: false,
            errorMessage: "Неверный код",
            onCodeChanged: { _ in },
            onSubmit: {},
            onResend: {}
        ))
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "withError"
        )
    }
}
