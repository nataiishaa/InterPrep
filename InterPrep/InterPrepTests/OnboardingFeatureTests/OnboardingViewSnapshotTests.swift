//
//  OnboardingViewSnapshotTests.swift
//  OnboardingFeatureTests
//
//  Snapshot tests for OnboardingView
//

@testable import OnboardingFeature
import SnapshotTesting
import SwiftUI
import XCTest

final class OnboardingViewSnapshotTests: SnapshotTestCase {

    // MARK: - Tests
    
    func testOnboardingView_firstPage() {
        let hostingController = UIHostingController(
            rootView: OnboardingView(model: .fixture)
        )
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "firstPage"
        )
    }
    
    func testOnboardingView_lastPage() {
        let hostingController = UIHostingController(
            rootView: OnboardingView(model: .lastPageFixture)
        )
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "lastPage"
        )
    }
    
    func testOnboardingView_iPhone14Pro() {
        let hostingController = UIHostingController(
            rootView: OnboardingView(model: .fixture)
        )
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "iPhone14Pro"
        )
    }
    
    func testOnboardingView_iPhoneSE() {
        let hostingController = UIHostingController(
            rootView: OnboardingView(model: .fixture)
        )
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhoneSe),
            named: "iPhoneSE"
        )
    }
}
