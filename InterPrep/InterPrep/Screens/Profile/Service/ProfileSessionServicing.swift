import Foundation

public struct ProfileSessionError: Error, Sendable, LocalizedError {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var errorDescription: String? { message }
}

public protocol ProfileSessionServicing: Sendable {
    func clearTokens() async
    func deleteAccount(password: String) async -> Result<Void, ProfileSessionError>
}
