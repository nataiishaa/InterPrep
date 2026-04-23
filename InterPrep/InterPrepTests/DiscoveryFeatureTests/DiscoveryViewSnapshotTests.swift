//
//  DiscoveryViewSnapshotTests.swift
//  DiscoveryFeatureTests
//
//  Snapshot tests for DiscoveryView
//

@testable import DiscoveryModule
import SnapshotTesting
import SwiftUI
import XCTest

final class DiscoveryViewSnapshotTests: SnapshotTestCase {

    // MARK: - Tests
    
    func testDiscoveryView_noResume() {
        let view = DiscoveryView(model: .noResume)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "noResume"
        )
    }
    
    func testDiscoveryView_loading() {
        let view = DiscoveryView(model: .loading)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "loading"
        )
    }
    
    func testDiscoveryView_empty() {
        let view = DiscoveryView(model: .empty)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "empty"
        )
    }
    
    func testDiscoveryView_withVacancies() {
        let view = DiscoveryView(model: .withVacancies)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "withVacancies"
        )
    }
    
    func testDiscoveryView_favoritesFilter() {
        let view = DiscoveryView(model: .fixture(
            selectedFilter: .favorites,
            hasResume: true,
            vacancies: [
                .init(id: "1", title: "iOS Developer", company: "Yandex", description: "Описание вакансии...", isFavorite: true),
                .init(id: "2", title: "Swift Developer", company: "Авито", description: "Описание вакансии...", isFavorite: true)
            ]
        ))
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "favoritesFilter"
        )
    }
    
    func testDiscoveryView_iPhone14Pro() {
        let view = DiscoveryView(model: .withVacancies)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "iPhone14Pro"
        )
    }
    
    func testDiscoveryView_iPhoneSE() {
        let view = DiscoveryView(model: .withVacancies)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhoneSe),
            named: "iPhoneSE"
        )
    }
}
