import Foundation
import SwiftProtobuf

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
    }
}

public actor RefreshingTokenProvider: TokenProvider {
    private let tokenStorage: TokenStorage
    private let refreshTokenHandler: (String) async -> Result<(accessToken: String, refreshToken: String), Error>
    private var isRefreshing = false
    private var refreshTask: Task<Void, Never>?
    
    public init(
        tokenStorage: TokenStorage,
        refreshTokenHandler: @escaping (String) async -> Result<(accessToken: String, refreshToken: String), Error>
    ) {
        self.tokenStorage = tokenStorage
        self.refreshTokenHandler = refreshTokenHandler
    }
    
    public func provideToken() async -> String? {
        await tokenStorage.getAccessToken()
    }
    
    public func authenticateIfNeeded() async {
        guard !isRefreshing else {
            await refreshTask?.value
            return
        }
        
        guard let refreshToken = await tokenStorage.getRefreshToken() else {
            await tokenStorage.clearTokens()
            return
        }
        
        isRefreshing = true
        let task = Task {
            let result = await refreshTokenHandler(refreshToken)
            
            switch result {
            case .success(let tokens):
                await tokenStorage.setTokens(
                    accessToken: tokens.accessToken,
                    refreshToken: tokens.refreshToken
                )
            case .failure:
                await tokenStorage.clearTokens()
            }
            
            isRefreshing = false
            refreshTask = nil
        }
        
        refreshTask = task
        await task.value
    }
}

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
            
            #if DEBUG
            print("[Network] >>> \(urlRequest.httpMethod ?? "?") \(urlRequest.url?.absoluteString ?? "?")")
            print("[Network] Content-Type: \(urlRequest.value(forHTTPHeaderField: "Content-Type") ?? "?")")
            if let body = urlRequest.httpBody, let str = String(data: body, encoding: .utf8) {
                print("[Network] Body: \(str.prefix(500))")
            }
            #endif
            
            // Perform network request
            let (data, urlResponse) = try await session.data(for: urlRequest)
            
            #if DEBUG
            print("[Network] <<< Response received, \(data.count) bytes")
            #endif
            
            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                await notifyObservers(request: urlRequest, response: nil, data: data, error: NetworkError.unknown)
                return .failure(.unknown)
            }
            
            #if DEBUG
            print("[Network] <<< HTTP \(httpResponse.statusCode)")
            if let str = String(data: data, encoding: .utf8) {
                print("[Network] Response: \(str.prefix(500))")
            }
            #endif
            
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
            #if DEBUG
            print("[Network] !!! Error: \(error)")
            #endif
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
                #if DEBUG
                print("[Network] Retrying in \(delaySec)s (attempt \(attempt + 1))")
                #endif
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
            if tokenWasSet {
                await tokenProvider.authenticateIfNeeded()
                
                if let newToken = await tokenProvider.provideToken() {
                    let reauthorizedRequest = protoRequest.authorized(with: newToken)
                    return await performInternal(request: reauthorizedRequest, tokenWasSet: false)
                } else {
                    return .failure(.unauthorized)
                }
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
