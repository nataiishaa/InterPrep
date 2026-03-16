//
//  ChatServicing.swift
//  InterPrep
//
//  Chat service protocol (messages, consultant, connection)
//

import Foundation

public protocol ChatServicing: Actor {
    func fetchMessages() async throws -> [ChatMessage]
    func fetchConsultant() async throws -> Consultant
    func connect() async throws
    func disconnect() async
    /// Отправляет сообщение; возвращает опциональный ответ консультанта (длинный ответ приходит одним сообщением).
    func sendMessage(_ message: ChatMessage) async throws -> ChatMessage?
    func handleButtonAction(_ action: ButtonAction) async throws -> ChatMessage
    /// Сбросить контекст диалога (conversation_id); следующий запрос начнёт новый чат.
    func clearHistory() async
}
