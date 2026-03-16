import Foundation

public actor JobsService {
    private let client: GRPCClient
    private let tokenStorage: TokenStorage
    
    public init(client: GRPCClient, tokenStorage: TokenStorage) {
        self.client = client
        self.tokenStorage = tokenStorage
    }
    
    public func searchJobs(request: SearchJobsRequest) async throws -> SearchJobsResponse {
        guard let token = await tokenStorage.getAccessToken() else {
            throw APIError.unauthorized
        }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await client.makeRequest(
            service: "gateway.BackendGateway",
            method: "SearchJobs",
            body: body,
            token: token
        )
    }
    
    public func addFavorite(request: AddFavoriteRequest) async throws -> AddFavoriteResponse {
        guard let token = await tokenStorage.getAccessToken() else {
            throw APIError.unauthorized
        }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await client.makeRequest(
            service: "gateway.BackendGateway",
            method: "AddFavorite",
            body: body,
            token: token
        )
    }
    
    public func removeFavorite(request: RemoveFavoriteRequest) async throws -> RemoveFavoriteResponse {
        guard let token = await tokenStorage.getAccessToken() else {
            throw APIError.unauthorized
        }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await client.makeRequest(
            service: "gateway.BackendGateway",
            method: "RemoveFavorite",
            body: body,
            token: token
        )
    }
    
    public func listFavorites() async throws -> ListFavoritesResponse {
        guard let token = await tokenStorage.getAccessToken() else {
            throw APIError.unauthorized
        }
        
        return try await client.makeRequest(
            service: "gateway.BackendGateway",
            method: "ListFavorites",
            body: Data("{}".utf8),
            token: token
        )
    }
}
