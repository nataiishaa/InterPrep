//
//  ChatEffectHandler.swift
//  InterPrep
//
//  Chat effect handler
//

import Foundation
import ArchitectureCore

// MARK: - Effect Handler

public actor ChatEffectHandler: EffectHandler {
    public typealias S = ChatState
    
    private let chatService: ChatServiceProtocol
    
    public init(chatService: ChatServiceProtocol) {
        self.chatService = chatService
    }
    
    public func handle(effect: S.Effect) async -> S.Feedback? {
        switch effect {
        case .loadMessages:
            do {
                let messages = try await chatService.fetchMessages()
                // Also load consultant and connect after loading messages
                let consultant = try await chatService.fetchConsultant()
                try await chatService.connect()
                // Note: We can only return one feedback at a time
                // In a real app, you might want to chain these differently
                return .messagesLoaded(messages)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .loadConsultant:
            do {
                let consultant = try await chatService.fetchConsultant()
                return .consultantLoaded(consultant)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .connect:
            do {
                try await chatService.connect()
                return .connectionStatusChanged(true)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .sendMessage(let message):
            do {
                try await chatService.sendMessage(message)
                return .messageSent(message)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
        }
    }
}

// MARK: - Service Protocol

public protocol ChatServiceProtocol: Actor {
    func fetchMessages() async throws -> [ChatMessage]
    func fetchConsultant() async throws -> Consultant
    func connect() async throws
    func disconnect() async
    func sendMessage(_ message: ChatMessage) async throws
}

// MARK: - Mock Service

public final actor ChatServiceMock: ChatServiceProtocol {
    public init() {}
    
    public func fetchMessages() async throws -> [ChatMessage] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return [
            ChatMessage(
                text: "Здравствуйте! Я ваш карьерный консультант. Чем могу помочь?",
                sender: .consultant,
                timestamp: Date().addingTimeInterval(-3600),
                status: .read
            ),
            ChatMessage(
                text: "Привет! Хотел бы обсудить подготовку к интервью",
                sender: .user,
                timestamp: Date().addingTimeInterval(-3500),
                status: .read
            ),
            ChatMessage(
                text: "Отлично! Давайте начнем с того, на какую позицию вы готовитесь?",
                sender: .consultant,
                timestamp: Date().addingTimeInterval(-3400),
                status: .read
            )
        ]
    }
    
    public func fetchConsultant() async throws -> Consultant {
        try await Task.sleep(nanoseconds: 300_000_000)
        return Consultant(
            name: "Анна Петрова",
            title: "Карьерный консультант",
            isOnline: true
        )
    }
    
    public func connect() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    public func disconnect() async {
        try? await Task.sleep(nanoseconds: 200_000_000)
    }
    
    public func sendMessage(_ message: ChatMessage) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Simulate consultant response after 2 seconds
        try await Task.sleep(nanoseconds: 2_000_000_000)
    }
}
