import Foundation

public actor CalendarService {
    private let client: GRPCClient
    private let tokenStorage: TokenStorage
    
    public init(client: GRPCClient, tokenStorage: TokenStorage) {
        self.client = client
        self.tokenStorage = tokenStorage
    }
    
    // MARK: - Create Event
    
    public func createEvent(request: CreateEventRequest) async throws -> CreateEventResponse {
        guard let token = await tokenStorage.getAccessToken() else {
            throw APIError.unauthorized
        }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(request)
        
        return try await client.makeRequest(
            service: "gateway.BackendGateway",
            method: "CreateEvent",
            body: body,
            token: token
        )
    }
    
    // MARK: - Get Event
    
    public func getEvent(request: GetEventRequest) async throws -> GetEventResponse {
        guard let token = await tokenStorage.getAccessToken() else {
            throw APIError.unauthorized
        }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await client.makeRequest(
            service: "gateway.BackendGateway",
            method: "GetEvent",
            body: body,
            token: token
        )
    }
    
    // MARK: - Update Event
    
    public func updateEvent(request: UpdateEventRequest) async throws -> UpdateEventResponse {
        guard let token = await tokenStorage.getAccessToken() else {
            throw APIError.unauthorized
        }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(request)
        
        return try await client.makeRequest(
            service: "gateway.BackendGateway",
            method: "UpdateEvent",
            body: body,
            token: token
        )
    }
    
    // MARK: - Delete Event
    
    public func deleteEvent(request: DeleteEventRequest) async throws -> DeleteEventResponse {
        guard let token = await tokenStorage.getAccessToken() else {
            throw APIError.unauthorized
        }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await client.makeRequest(
            service: "gateway.BackendGateway",
            method: "DeleteEvent",
            body: body,
            token: token
        )
    }
    
    // MARK: - List Events
    
    public func listEvents(request: ListEventsRequest) async throws -> ListEventsResponse {
        guard let token = await tokenStorage.getAccessToken() else {
            throw APIError.unauthorized
        }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(request)
        
        return try await client.makeRequest(
            service: "gateway.BackendGateway",
            method: "ListEvents",
            body: body,
            token: token
        )
    }
    
    // MARK: - List Upcoming
    
    public func listUpcoming(request: ListUpcomingRequest) async throws -> ListUpcomingResponse {
        guard let token = await tokenStorage.getAccessToken() else {
            throw APIError.unauthorized
        }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(request)
        
        return try await client.makeRequest(
            service: "gateway.BackendGateway",
            method: "ListUpcoming",
            body: body,
            token: token
        )
    }
}
