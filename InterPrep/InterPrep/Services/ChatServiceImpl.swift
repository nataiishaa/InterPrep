//
//  ChatServiceImpl.swift
//  InterPrep
//
//  Real implementation of ChatService using NetworkServiceV2
//

import Foundation
import ChatFeature

public final actor ChatServiceImpl {
    private let mock = ChatServiceMock()
    
    public init() {}
    
    public func fetchMessages() async throws -> [ChatMessage] {
        try await mock.fetchMessages()
    }
    
    public func fetchConsultant() async throws -> Consultant {
        try await mock.fetchConsultant()
    }
    
    public func connect() async throws {
        try await mock.connect()
    }
    
    public func disconnect() async {
        await mock.disconnect()
    }
    
    public func sendMessage(_ message: ChatMessage) async throws -> ChatMessage? {
        try await mock.sendMessage(message)
    }
    
    public func handleButtonAction(_ action: ButtonAction) async throws -> ChatMessage {
        try await mock.handleButtonAction(action)
    }
}
