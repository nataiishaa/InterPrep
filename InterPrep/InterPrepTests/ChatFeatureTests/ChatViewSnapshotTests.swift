//
//  ChatViewSnapshotTests.swift
//  ChatFeatureTests
//
//  Snapshot tests for ChatView
//

import XCTest
import SwiftUI
import SnapshotTesting
@testable import ChatFeature

final class ChatViewSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set to true when recording new snapshots
        // isRecording = true
    }
    
    // MARK: - Tests
    
    func testChatView_welcome() {
        let view = ChatView(model: .fixtureWelcome)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "welcome"
        )
    }
    
    func testChatView_withMessages() {
        let view = ChatView(model: .fixtureWithMessages)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "withMessages"
        )
    }
    
    func testChatView_withButtons() {
        let view = ChatView(model: .fixtureWithButtons)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "withButtons"
        )
    }
    
    func testChatView_loading() {
        let view = ChatView(model: .fixtureLoading)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "loading"
        )
    }
    
    func testChatView_sending() {
        let view = ChatView(model: .fixtureSending)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "sending"
        )
    }
    
    func testChatView_iPhone14Pro() {
        let view = ChatView(model: .fixtureWelcome)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone14Pro),
            named: "iPhone14Pro"
        )
    }
    
    func testChatView_iPhoneSE() {
        let view = ChatView(model: .fixtureWelcome)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhoneSe),
            named: "iPhoneSE"
        )
    }
}
