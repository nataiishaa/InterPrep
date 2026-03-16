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
            let nsError = error as NSError
            let isConnectionError = nsError.domain == NSURLErrorDomain && (
                nsError.code == NSURLErrorNotConnectedToInternet ||
                nsError.code == NSURLErrorNetworkConnectionLost ||
                nsError.code == NSURLErrorTimedOut ||
                nsError.code == NSURLErrorCannotConnectToHost
            )
            if isConnectionError && protoRequest.shouldRetry {
                let attempt = protoRequest.retryPolicy?.currentRetry ?? 0
                let delaySec = 2.0 * pow(2.0, Double(attempt))
                try? await Task.sleep(nanoseconds: UInt64(delaySec * 1_000_000_000))
                return await performInternal(
                    request: protoRequest.withReducedRetries(),
                    tokenWasSet: tokenWasSet
                )
            }
            return .failure(.transportError(error))
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
            return .failure(.apiError(APIError.from(httpStatusCode: 400, body: data)))
            
        case 401:
            await tokenProvider.authenticateIfNeeded()
            if tokenWasSet {
                let deauthorizedRequest = protoRequest.deauthorized()
                return await performInternal(request: deauthorizedRequest, tokenWasSet: false)
            } else {
                return .failure(.unauthorized)
            }
            
        case 403, 404, 409, 412, 429:
            return .failure(.apiError(APIError.from(httpStatusCode: httpResponse.statusCode, body: data)))
            
        default:
            if (500...599).contains(httpResponse.statusCode) {
                return .failure(.apiError(APIError.from(httpStatusCode: httpResponse.statusCode, body: data)))
            }
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
    }
}
