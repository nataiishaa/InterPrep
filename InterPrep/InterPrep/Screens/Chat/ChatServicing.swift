//
//  ChatServicing.swift
//  InterPrep
//
//  Chat service protocol (messages, consultant, connection)
//

import DiscoveryModule
import Foundation

public protocol ChatServicing: Actor {
    func fetchMessages() async throws -> [ChatMessage]
    func fetchConsultant() async throws -> Consultant
    func connect() async throws
    func disconnect() async
    func sendMessage(_ message: ChatMessage) async throws -> ChatMessage?
    func handleButtonAction(_ action: ButtonAction) async throws -> ChatMessage
    func clearHistory() async
    func prepareForVacancy(vacancyId: String) async throws -> String
    func reviewResume() async throws -> (score: Double, recommendations: String)
    func clearChatHistory(conversationId: String?) async throws -> (ok: Bool, deletedConversations: Int)
    func getCoachChatHistory(pageSize: Int, pageOffset: Int) async throws -> [ChatMessage]
    func addChatMessage(conversationId: String?, content: String, isUser: Bool) async throws -> String
}

public protocol FavoritesProviding: Actor {
    func fetchFavorites() async throws -> [DiscoveryState.Vacancy]
}
