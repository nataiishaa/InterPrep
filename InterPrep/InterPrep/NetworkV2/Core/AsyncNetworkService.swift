import Foundation
import SwiftProtobuf

// MARK: - Token Provider

public protocol TokenProvider: Sendable {
    func provideToken() async -> String?
    func authenticateIfNeeded() async
}

public actor DefaultTokenProvider: TokenProvider {
    private let tokenStorage: TokenStorage
    
    public init(tokenStorage: TokenStorage) {
        self.tokenStorage = tokenStorage
    }
    
    public func provideToken() async -> String? {
        await tokenStorage.getAccessToken()
    }
    
    public func authenticateIfNeeded() async {
        // TODO: Implement re-authentication logic
        print("⚠️ Token expired, need to re-authenticate")
    }
}

// MARK: - Network Response Observer

public protocol NetworkResponseObserver: Sendable {
    func observe(request: URLRequest, response: HTTPURLResponse?, data: Data?, error: Error?) async
}

// MARK: - Async Network Service

public actor AsyncNetworkService {
    private let session: URLSession
    private let tokenProvider: TokenProvider
    private let responseObservers: [NetworkResponseObserver]
    
    public init(
        session: URLSession = .shared,
        tokenProvider: TokenProvider,
        responseObservers: [NetworkResponseObserver] = []
    ) {
        self.session = session
        self.tokenProvider = tokenProvider
        self.responseObservers = responseObservers
    }
    
    // MARK: - Perform Request
    
    public func perform<Response: Message>(
        _ protoRequest: ProtoRequest<Response>
    ) async -> Result<Response, NetworkError> {
        // Authorize request if token available
        let authorizedRequest: ProtoRequest<Response>
        if let token = await tokenProvider.provideToken() {
            authorizedRequest = protoRequest.authorized(with: token)
        } else {
            authorizedRequest = protoRequest
        }
        
        return await performInternal(request: authorizedRequest, tokenWasSet: authorizedRequest.token != nil)
    }
    
    // MARK: - Internal Perform
    
    private func performInternal<Response: Message>(
        request protoRequest: ProtoRequest<Response>,
        tokenWasSet: Bool = false
    ) async -> Result<Response, NetworkError> {
        do {
            // Convert to URLRequest
            let urlRequest = try await protoRequest.makeURLRequest()
            
            // Perform network request
            let (data, urlResponse) = try await session.data(for: urlRequest)
            
            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                await notifyObservers(request: urlRequest, response: nil, data: data, error: NetworkError.unknown)
                return .failure(.unknown)
            }
            
            // Notify observers
            await notifyObservers(request: urlRequest, response: httpResponse, data: data, error: nil)
            
            // Handle response
            return await handleResponse(
                httpResponse: httpResponse,
                data: data,
                protoRequest: protoRequest,
                tokenWasSet: tokenWasSet
            )
            
        } catch {
            return .failure(.unknown)
        }
    }
    
    // MARK: - Handle Response
    
    private func handleResponse<Response: Message>(
        httpResponse: HTTPURLResponse,
        data: Data,
        protoRequest: ProtoRequest<Response>,
        tokenWasSet: Bool
    ) async -> Result<Response, NetworkError> {
        switch httpResponse.statusCode {
        case 200...299:
            // Success - decode response
            do {
                let response = try await protoRequest.decodingStrategy(data)
                return .success(response)
            } catch {
                return .failure(.decodingFailed(error))
            }
            
        case 400:
            // Bad Request
            return .failure(.httpError(400, data))
            
        case 401:
            // Unauthorized
            await tokenProvider.authenticateIfNeeded()
            
            // If request had token and got 401, retry without token
            if tokenWasSet {
                let deauthorizedRequest = protoRequest.deauthorized()
                return await performInternal(request: deauthorizedRequest, tokenWasSet: false)
            } else {
                return .failure(.unauthorized)
            }
            
        default:
            // Other errors - check retry policy
            if protoRequest.shouldRetry {
                return await performInternal(
                    request: protoRequest.withReducedRetries(),
                    tokenWasSet: tokenWasSet
                )
            } else {
                return .failure(.httpError(httpResponse.statusCode, data))
            }
        }
    }
    
    // MARK: - Observers
    
    private func notifyObservers(
        request: URLRequest,
        response: HTTPURLResponse?,
        data: Data?,
        error: Error?
    ) async {
        for observer in responseObservers {
            await observer.observe(request: request, response: response, data: data, error: error)
        }
    }
}

// MARK: - Logging Observer

public struct LoggingObserver: NetworkResponseObserver {
    public init() {}
    
    public func observe(request: URLRequest, response: HTTPURLResponse?, data: Data?, error: Error?) async {
        print("🌐 Network Request:")
        print("   URL: \(request.url?.absoluteString ?? "N/A")")
        print("   Method: \(request.httpMethod ?? "N/A")")
        
        if let response = response {
            print("   Status: \(response.statusCode)")
        }
        
        if let error = error {
            print("   Error: \(error.localizedDescription)")
        }
        
        if let data = data {
            print("   Data size: \(data.count) bytes")
        }
    }
}
