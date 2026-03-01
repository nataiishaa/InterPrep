//
//  ChatStateTests.swift
//  ChatFeatureTests
//
//  Unit tests for ChatState reducer
//

import XCTest
import ArchitectureCore
@testable import ChatFeature

final class ChatStateTests: XCTestCase {
    
    // MARK: - Tests
    
    func testOnAppear_sendsWelcomeEffect() {
        var state = ChatState()
        
        let effect = state.reduce(.onAppear)
        
        XCTAssertEqual(effect, .sendWelcomeMessage)
    }
    
    func testInputTextChanged_updatesText() {
        var state = ChatState()
        let newText = "Привет!"
        
        _ = state.reduce(.inputTextChanged(newText))
        
        XCTAssertEqual(state.inputText, newText)
    }
    
    func testSendMessage_whenTextEmpty_doesNothing() {
        var state = ChatState()
        state.inputText = "   "
        
        let effect = state.reduce(.sendMessage)
        
        XCTAssertEqual(effect, .none)
        XCTAssertEqual(state.inputText, "   ")
    }
    
    func testSendMessage_whenTextNotEmpty_addsMessageAndClearsInput() {
        var state = ChatState()
        state.inputText = "Привет!"
        let initialMessageCount = state.messages.count
        
        let effect = state.reduce(.sendMessage)
        
        XCTAssertEqual(state.messages.count, initialMessageCount + 1)
        XCTAssertEqual(state.messages.last?.text, "Привет!")
        XCTAssertEqual(state.messages.last?.sender, .user)
        XCTAssertEqual(state.inputText, "")
        XCTAssertTrue(state.isSending)
        
        if case .sendToConsultant(let message) = effect {
            XCTAssertEqual(message.text, "Привет!")
        } else {
            XCTFail("Expected sendToConsultant effect")
        }
    }
    
    func testButtonTapped_addsUserMessageAndSendsEffect() {
        var state = ChatState()
        let button = MessageButton(
            text: "Помощь в подготовке к собеседованию",
            action: .selectScenario(.interviewPrep)
        )
        let initialMessageCount = state.messages.count
        
        let effect = state.reduce(.buttonTapped(button))
        
        XCTAssertEqual(state.messages.count, initialMessageCount + 1)
        XCTAssertEqual(state.messages.last?.text, button.text)
        XCTAssertEqual(state.messages.last?.sender, .user)
        XCTAssertTrue(state.isSending)
        
        if case .handleButtonAction(let action) = effect {
            XCTAssertEqual(action, button.action)
        } else {
            XCTFail("Expected handleButtonAction effect")
        }
    }
    
    func testConsultantResponded_addsMessageAndStopsSending() {
        var state = ChatState()
        state.isSending = true
        let consultantMessage = ChatMessage(
            text: "Отлично! Чем могу помочь?",
            sender: .consultant,
            buttons: [
                MessageButton(text: "Да", action: .confirm),
                MessageButton(text: "Нет", action: .cancel)
            ]
        )
        let initialMessageCount = state.messages.count
        
        _ = state.reduce(.consultantResponded(consultantMessage))
        
        XCTAssertEqual(state.messages.count, initialMessageCount + 1)
        XCTAssertEqual(state.messages.last?.text, consultantMessage.text)
        XCTAssertEqual(state.messages.last?.sender, .consultant)
        XCTAssertEqual(state.messages.last?.buttons.count, 2)
        XCTAssertFalse(state.isSending)
    }
    
    func testMessageSent_updatesStatus() {
        var state = ChatState()
        let userMessage = ChatMessage(text: "Привет!", sender: .user, status: .sending)
        state.messages = [userMessage]
        
        _ = state.reduce(.messageSent(userMessage.id))
        
        XCTAssertEqual(state.messages.first?.status, .sent)
        XCTAssertFalse(state.isSending)
    }
    
    func testMessageDelivered_updatesStatus() {
        var state = ChatState()
        let userMessage = ChatMessage(text: "Привет!", sender: .user, status: .sent)
        state.messages = [userMessage]
        
        _ = state.reduce(.messageDelivered(userMessage.id))
        
        XCTAssertEqual(state.messages.first?.status, .delivered)
    }
    
    func testMessageRead_updatesStatus() {
        var state = ChatState()
        let userMessage = ChatMessage(text: "Привет!", sender: .user, status: .delivered)
        state.messages = [userMessage]
        
        _ = state.reduce(.messageRead(userMessage.id))
        
        XCTAssertEqual(state.messages.first?.status, .read)
    }
    
    func testErrorOccurred_stopsLoadingAndSending() {
        var state = ChatState()
        state.isLoading = true
        state.isSending = true
        
        _ = state.reduce(.errorOccurred("Network error"))
        
        XCTAssertFalse(state.isLoading)
        XCTAssertFalse(state.isSending)
    }
}
