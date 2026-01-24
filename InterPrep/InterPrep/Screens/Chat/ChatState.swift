//
//  ChatState.swift
//  InterPrep
//
//  Chat state management
//

import Foundation
import ArchitectureCore

// MARK: - State

public struct ChatState {
    public var messages: [ChatMessage] = []
    public var inputText: String = ""
    public var isLoading: Bool = false
    public var isSending: Bool = false
    public var isConnected: Bool = false
    public var error: String?
    public var consultant: Consultant?
    
    public init() {}
}

// MARK: - Models

public struct ChatMessage: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let text: String
    public let sender: MessageSender
    public let timestamp: Date
    public let status: MessageStatus
    
    public init(
        id: UUID = UUID(),
        text: String,
        sender: MessageSender,
        timestamp: Date = Date(),
        status: MessageStatus = .sent
    ) {
        self.id = id
        self.text = text
        self.sender = sender
        self.timestamp = timestamp
        self.status = status
    }
}

public enum MessageSender: Equatable, Sendable {
    case user
    case consultant
}

public enum MessageStatus: Equatable, Sendable {
    case sending
    case sent
    case delivered
    case read
    case failed
}

public struct Consultant: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let avatar: String?
    public let title: String
    public let isOnline: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        avatar: String? = nil,
        title: String,
        isOnline: Bool = false
    ) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.title = title
        self.isOnline = isOnline
    }
}

// MARK: - FeatureState

extension ChatState: FeatureState {
    public enum Input: Sendable {
        case onAppear
        case inputTextChanged(String)
        case sendMessage
        case messageReceived(ChatMessage)
    }
    
    public enum Feedback: Sendable {
        case messagesLoaded([ChatMessage])
        case consultantLoaded(Consultant)
        case messageSent(ChatMessage)
        case connectionStatusChanged(Bool)
        case loadingFailed(String)
    }
    
    public enum Effect: Sendable {
        case loadMessages
        case loadConsultant
        case connect
        case sendMessage(ChatMessage)
    }
    
    @MainActor
    public static func reduce(
        state: inout Self,
        with message: Message<Input, Feedback>
    ) -> Effect? {
        switch message {
        case .input(.onAppear):
            state.isLoading = true
            // Note: We can only return one effect, so we'll load messages first
            // The effect handler will chain loading consultant and connecting
            return .loadMessages
            
        case .input(.inputTextChanged(let text)):
            state.inputText = text
            return nil
            
        case .input(.sendMessage):
            guard !state.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }
            
            let message = ChatMessage(
                text: state.inputText,
                sender: .user,
                status: .sending
            )
            
            state.messages.append(message)
            state.inputText = ""
            state.isSending = true
            
            return .sendMessage(message)
            
        case .input(.messageReceived(let message)):
            state.messages.append(message)
            return nil
            
        case .feedback(.messagesLoaded(let messages)):
            state.messages = messages
            state.isLoading = false
            return nil
            
        case .feedback(.consultantLoaded(let consultant)):
            state.consultant = consultant
            return nil
            
        case .feedback(.messageSent(let message)):
            if let index = state.messages.firstIndex(where: { $0.id == message.id }) {
                state.messages[index] = ChatMessage(
                    id: message.id,
                    text: message.text,
                    sender: message.sender,
                    timestamp: message.timestamp,
                    status: .sent
                )
            }
            state.isSending = false
            return nil
            
        case .feedback(.connectionStatusChanged(let isConnected)):
            state.isConnected = isConnected
            return nil
            
        case .feedback(.loadingFailed(let error)):
            state.isLoading = false
            state.isSending = false
            state.error = error
            return nil
        }
    }
}
