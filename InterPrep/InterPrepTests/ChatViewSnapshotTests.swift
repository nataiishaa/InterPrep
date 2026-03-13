//
//  ChatViewSnapshotTests.swift
//  ChatFeatureTests
//
//  Snapshot tests for ChatView
//

import XCTest
import SwiftUI
import SnapshotTesting
import ArchitectureCore
@testable import ChatFeature

final class ChatViewSnapshotTests: SnapshotTestCase {
    
    // MARK: - Individual State Tests
    
    func testChatView_welcome() {
        ChatView(model: .fixtureWelcome)
            .test(batch: .regularFullscreen)
    }
    
    func testChatView_withMessages() {
        ChatView(model: .fixtureWithMessages)
            .test(batch: .regularFullscreen)
    }
    
    func testChatView_withButtons() {
        ChatView(model: .fixtureWithButtons)
            .test(batch: .regularFullscreen)
    }
    
    func testChatView_loading() {
        ChatView(model: .fixtureLoading)
            .test(batch: .regularFullscreen)
    }
    
    func testChatView_sending() {
        ChatView(model: .fixtureSending)
            .test(batch: .regularFullscreen)
    }
    
    // MARK: - Extended Device Coverage
    
    func testChatView_allDevices() {
        ChatView(model: .fixtureWelcome)
            .test(batch: .extendedFullscreen)
    }
}
