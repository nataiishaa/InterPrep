import Foundation

public actor UserService {
    private let client: GRPCClient
    private let tokenStorage: TokenStorage
    
    public init(client: GRPCClient, tokenStorage: TokenStorage) {
        self.client = client
        self.tokenStorage = tokenStorage
    }
    
    // MARK: - Get Me
    
    public func getMe() async throws -> GetMeResponse {
        guard let token = await tokenStorage.getAccessToken() else {
            throw APIError.unauthorized
        }
        
        return try await client.makeRequest(
            service: "gateway.BackendGateway",
            method: "GetMe",
            body: Data("{}".utf8),
            token: token
        )
    }
    
    // MARK: - Resume Profile
    
    public func getResumeProfile() async throws -> GetResumeProfileResponse {
        guard let token = await tokenStorage.getAccessToken() else {
            throw APIError.unauthorized
        }
        
        return try await client.makeRequest(
            service: "gateway.BackendGateway",
            method: "GetResumeProfile",
            body: Data("{}".utf8),
            token: token
        )
    }
    
    public func updateResumeProfile(request: UpdateResumeProfileRequest) async throws -> UpdateResumeProfileResponse {
        guard let token = await tokenStorage.getAccessToken() else {
            throw APIError.unauthorized
        }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await client.makeRequest(
            service: "gateway.BackendGateway",
            method: "UpdateResumeProfile",
            body: body,
            token: token
        )
    }
    
    // MARK: - User Profile
    
    public func updateUserProfile(request: UpdateUserProfileRequest) async throws -> UpdateUserProfileResponse {
        guard let token = await tokenStorage.getAccessToken() else {
            throw APIError.unauthorized
        }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await client.makeRequest(
            service: "gateway.BackendGateway",
            method: "UpdateUserProfile",
            body: body,
            token: token
        )
    }
    
    // MARK: - Delete Account
    
    public func deleteAccount(request: DeleteAccountRequest) async throws -> DeleteAccountResponse {
        guard let token = await tokenStorage.getAccessToken() else {
            throw APIError.unauthorized
        }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await client.makeRequest(
            service: "gateway.BackendGateway",
            method: "DeleteAccount",
            body: body,
            token: token
        )
    }
}
