//
//  ChatServiceImpl.swift
//  InterPrep
//
//  Real implementation of ChatService using NetworkServiceV2
//

import Foundation
import ChatFeature

public final actor ChatServiceImpl: ChatServiceProtocol {
    
    public init() {
    }
    
    public func sendMessage(_ message: String) async throws -> String {
        // TODO: Implement real chat service with NetworkServiceV2
        // Currently using mock due to internal type restrictions
        print("⚠️ Chat service not fully implemented yet")
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return "Это тестовый ответ. Интеграция с AI будет добавлена позже."
    }
    
    public func loadChatHistory() async throws -> [ChatMessage] {
        // TODO: Implement chat history loading if backend supports it
        print("⚠️ Chat history not implemented yet")
        return []
    }
}
