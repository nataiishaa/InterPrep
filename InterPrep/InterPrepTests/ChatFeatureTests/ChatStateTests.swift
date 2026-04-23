//
//  ChatStateTests.swift
//  ChatFeatureTests
//
//  Unit tests for ChatState reducer (Store state logic)
//

import ArchitectureCore
@testable import ChatFeature
import XCTest

@MainActor
final class ChatStateTests: XCTestCase {

    // MARK: - Input tests

    func testOnAppear_returnsLoadMessagesEffect() {
        var state = ChatState()

        let effect = ChatState.reduce(state: &state, with: .input(.onAppear))

        XCTAssertTrue(state.isLoading)
        guard case .loadMessages = effect else {
            XCTFail("Expected loadMessages effect, got \(String(describing: effect))")
            return
        }
    }

    func testInputTextChanged_updatesText() {
        var state = ChatState()
        let newText = "Привет!"

        _ = ChatState.reduce(state: &state, with: .input(.inputTextChanged(newText)))

        XCTAssertEqual(state.inputText, newText)
    }

    func testSendMessage_whenTextEmpty_doesNothing() {
        var state = ChatState()
        state.inputText = "   "

        let effect = ChatState.reduce(state: &state, with: .input(.sendMessage))

        XCTAssertNil(effect)
        XCTAssertEqual(state.inputText, "   ")
    }

    func testSendMessage_whenTextNotEmpty_addsMessageAndClearsInput() {
        var state = ChatState()
        state.inputText = "Привет!"
        let initialMessageCount = state.messages.count

        let effect = ChatState.reduce(state: &state, with: .input(.sendMessage))

        XCTAssertEqual(state.messages.count, initialMessageCount + 1)
        XCTAssertEqual(state.messages.last?.text, "Привет!")
        XCTAssertEqual(state.messages.last?.sender, .user)
        XCTAssertEqual(state.inputText, "")
        XCTAssertTrue(state.isSending)
        guard case .sendMessage(let message) = effect else {
            XCTFail("Expected sendMessage effect, got \(String(describing: effect))")
            return
        }
        XCTAssertEqual(message.text, "Привет!")
    }

    func testButtonTapped_returnsHandleButtonActionEffect() {
        var state = ChatState()
        let button = MessageButton(
            text: "Помощь в подготовке к собеседованию",
            action: .selectScenario(.interviewPrep)
        )

        let effect = ChatState.reduce(state: &state, with: .input(.buttonTapped(button)))

        if case .handleButtonAction(let action) = effect {
            XCTAssertEqual(action, button.action)
        } else {
            XCTFail("Expected handleButtonAction effect")
        }
    }

    func testDismissError_clearsError() {
        var state = ChatState()
        state.error = "Something went wrong"

        _ = ChatState.reduce(state: &state, with: .input(.dismissError))

        XCTAssertNil(state.error)
    }

    // MARK: - Feedback tests

    func testConsultantResponded_appendsMessage() {
        var state = ChatState()
        state.isSending = true
        let consultantMessage = ChatMessage(
            text: "Отлично! Чем могу помочь?",
            sender: .consultant,
            buttons: [
                MessageButton(text: "Да", action: .confirmYes),
                MessageButton(text: "Нет", action: .confirmNo)
            ]
        )
        let initialCount = state.messages.count

        _ = ChatState.reduce(state: &state, with: .feedback(.consultantResponded(consultantMessage)))

        XCTAssertEqual(state.messages.count, initialCount + 1)
        XCTAssertEqual(state.messages.last?.text, consultantMessage.text)
        XCTAssertEqual(state.messages.last?.sender, .consultant)
    }

    func testMessageSent_updatesStatusAndStopsSending() {
        var state = ChatState()
        let userMessage = ChatMessage(text: "Привет!", sender: .user, status: .sending)
        state.messages = [userMessage]
        state.isSending = true

        _ = ChatState.reduce(state: &state, with: .feedback(.messageSent(userMessage, consultantReply: nil)))

        XCTAssertEqual(state.messages.first?.status, .sent)
        XCTAssertFalse(state.isSending)
    }

    func testLoadingFailed_setsErrorAndStopsLoading() {
        var state = ChatState()
        state.isLoading = true
        state.isSending = true

        _ = ChatState.reduce(state: &state, with: .feedback(.loadingFailed("Network error")))

        XCTAssertFalse(state.isLoading)
        XCTAssertFalse(state.isSending)
        XCTAssertEqual(state.error, "Network error")
    }

    func testMessagesLoaded_replacesMessagesAndStopsLoading() {
        var state = ChatState()
        state.isLoading = true
        let messages = [
            ChatMessage(text: "Hi", sender: .user),
            ChatMessage(text: "Hello", sender: .consultant)
        ]

        _ = ChatState.reduce(state: &state, with: .feedback(.messagesLoaded(messages)))

        XCTAssertEqual(state.messages.count, 2)
        XCTAssertFalse(state.isLoading)
    }
}
