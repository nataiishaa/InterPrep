//
//  OTPViewSnapshotTests.swift
//  AuthFeatureTests
//
//  Snapshot tests for OTPView
//

import XCTest
import SwiftUI
import SnapshotTesting
@testable import AuthFeature

final class OTPViewSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set to true when recording new snapshots
        // isRecording = true
    }
    
    // MARK: - Tests
    
    func testOTPView_default() {
        let view = OTPView(model: .init(
            code: "",
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
