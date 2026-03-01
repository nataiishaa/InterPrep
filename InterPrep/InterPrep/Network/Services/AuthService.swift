import Foundation

public actor AuthService {
    private let client: GRPCClient
    private let tokenStorage: TokenStorage
    
    public init(client: GRPCClient, tokenStorage: TokenStorage) {
        self.client = client
        self.tokenStorage = tokenStorage
    }
    
    // MARK: - Register
    
    public func register(request: RegisterRequest) async throws -> RegisterResponse {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        let response: RegisterResponse = try await client.makeRequest(
            service: "gateway.BackendGateway",
            method: "Register",
            body: body,
            token: nil
        )
        
        await saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        return response
    }
    
    // MARK: - Login
    
    public func login(request: LoginRequest) async throws -> LoginResponse {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        let response: LoginResponse = try await client.makeRequest(
            service: "gateway.BackendGateway",
            method: "Login",
            body: body,
            token: nil
        )
        
        await saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        return response
    }
    
    // MARK: - Refresh
    
    public func refresh(request: RefreshRequest) async throws -> RefreshResponse {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        let response: RefreshResponse = try await client.makeRequest(
            service: "gateway.BackendGateway",
            method: "Refresh",
            body: body,
            token: nil
        )
        
        await tokenStorage.setTokens(accessToken: response.accessToken, refreshToken: await tokenStorage.getRefreshToken() ?? "")
        return response
    }
    
    // MARK: - Password Reset
    
    public func checkPasswordResetEmail(request: PasswordResetCheckEmailRequest) async throws -> PasswordResetCheckEmailResponse {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await client.makeRequest(
            service: "gateway.BackendGateway",
            method: "CheckPasswordResetEmail",
            body: body,
            token: nil
        )
    }
    
    public func sendPasswordResetCode(request: PasswordResetSendCodeRequest) async throws -> PasswordResetSendCodeResponse {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await client.makeRequest(
            service: "gateway.BackendGateway",
            method: "SendPasswordResetCode",
            body: body,
            token: nil
        )
    }
    
    public func verifyPasswordReset(request: PasswordResetVerifyRequest) async throws -> PasswordResetVerifyResponse {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await client.makeRequest(
            service: "gateway.BackendGateway",
            method: "VerifyPasswordReset",
            body: body,
            token: nil
        )
    }
    
    // MARK: - Token Management
    
    public func saveTokens(accessToken: String, refreshToken: String) async {
        await tokenStorage.setTokens(accessToken: accessToken, refreshToken: refreshToken)
    }
    
    public func clearTokens() async {
        await tokenStorage.clearTokens()
    }
    
    public func getAccessToken() async -> String? {
        await tokenStorage.getAccessToken()
    }
}
