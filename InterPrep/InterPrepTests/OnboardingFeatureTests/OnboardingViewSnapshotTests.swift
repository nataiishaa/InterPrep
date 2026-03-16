//
//  OnboardingViewSnapshotTests.swift
//  OnboardingFeatureTests
//
//  Snapshot tests for OnboardingView
//

import XCTest
import SwiftUI
import SnapshotTesting
@testable import OnboardingFeature

final class OnboardingViewSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set to true when recording new snapshots
        // isRecording = true
    }
    
    // MARK: - Tests
    
    func testOnboardingView_firstPage() {
        let view = OnboardingView(model: .fixture)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "firstPage"
        )
    }
    
    func testOnboardingView_lastPage() {
        let view = OnboardingView(model: .lastPageFixture)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "lastPage"
        )
    }
    
    func testOnboardingView_middlePage() {
        let view = OnboardingView(model: .init(
            currentPage: 1,
            pages: [
                .init(
                    id: 0,
                    imageName: "video.circle.fill",
                    title: "Ищите работу в пару кликов",
                    description: "Не тратьте время на просмотр неинтересных для вас вакансий"
                ),
                .init(
                    id: 1,
                    imageName: "calendar.circle.fill",
                    title: "Планируйте собеседования",
                    description: "Календарь и материалы для подготовки. Все в одном приложении."
                ),
                .init(
                    id: 2,
                    imageName: "chart.line.uptrend.xyaxis.circle.fill",
                    title: "Прокачивайте карьеру",
                    description: "Карьерный консунтант подскажет, что улучшить в навыках и куда расти дальше"
                )
            ],
            isLastPage: false,
            onNext: {},
            onPrevious: {},
            onPageChanged: { _ in },
            onSkip: {},
            onGetStarted: {},
            onRegister: {}
        ))
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "middlePage"
        )
    }
    
    func testOnboardingView_iPhone14Pro() {
        let view = OnboardingView(model: .fixture)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone14Pro),
            named: "iPhone14Pro"
        )
    }
    
    func testOnboardingView_iPhoneSE() {
        let view = OnboardingView(model: .fixture)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhoneSe),
            named: "iPhoneSE"
        )
    }
}
