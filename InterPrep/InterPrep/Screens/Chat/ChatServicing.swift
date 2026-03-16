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
    func sendMessage(_ message: ChatMessage) async throws -> ChatMessage?
    func handleButtonAction(_ action: ButtonAction) async throws -> ChatMessage
    func clearHistory() async
}
