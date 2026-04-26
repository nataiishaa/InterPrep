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
    
    func testOnboardingView_middlePage() {
        let model = OnboardingView.Model(
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
        )
        let hostingController = UIHostingController(
            rootView: OnboardingView(model: model)
        )
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "middlePage"
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
