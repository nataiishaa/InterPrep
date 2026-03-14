import Foundation
import SwiftProtobuf

// MARK: - HTTP Method

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

// MARK: - HTTP Header

public struct HTTPHeader: Sendable {
    public let name: String
    public let value: String
    
    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
    
    public static func authorization(_ token: String) -> HTTPHeader {
        HTTPHeader(name: "Authorization", value: "Bearer \(token)")
    }
    
    public static func contentType(_ type: ContentType) -> HTTPHeader {
        HTTPHeader(name: "Content-Type", value: type.rawValue)
    }
}

// MARK: - Content Type

public enum ContentType: String, Sendable {
    case protobuf = "application/x-protobuf"
    case json = "application/json"
}

// MARK: - Retry Policy

public struct RetryPolicy: Sendable {
    public let maxRetries: Int
    public var currentRetry: Int
    
    public init(maxRetries: Int) {
        self.maxRetries = maxRetries
        self.currentRetry = 0
    }
    
    public var shouldRetry: Bool {
        currentRetry < maxRetries
    }
    
    public mutating func incrementRetry() {
        currentRetry += 1
    }
}

// MARK: - Proto Request

public struct ProtoRequest<Response: Message>: Sendable {
    public typealias DecodingStrategy = (Data) async throws -> Response
    public typealias EncodingStrategy = (any Message) async throws -> Data
    
    public let urlComponents: URLComponents
    public let messageToEncode: (any Message)?
    public let decodingStrategy: DecodingStrategy
    public let encodingStrategy: EncodingStrategy
    public let method: HTTPMethod
    public let headers: [HTTPHeader]
    public let cachePolicy: URLRequest.CachePolicy
    public let timeout: TimeInterval
    public var retryPolicy: RetryPolicy?
    public var token: String?
    
    init(
        urlComponents: URLComponents,
        messageToEncode: (any Message)?,
        decodingStrategy: @escaping DecodingStrategy,
        encodingStrategy: @escaping EncodingStrategy,
        method: HTTPMethod,
        headers: [HTTPHeader],
        cachePolicy: URLRequest.CachePolicy,
        timeout: TimeInterval,
        retryPolicy: RetryPolicy?
    ) {
        self.urlComponents = urlComponents
        self.messageToEncode = messageToEncode
        self.decodingStrategy = decodingStrategy
        self.encodingStrategy = encodingStrategy
        self.method = method
        self.headers = headers
        self.cachePolicy = cachePolicy
        self.timeout = timeout
        self.retryPolicy = retryPolicy
    }
    
    // MARK: - Authorization
    
    public func authorized(with token: String) -> Self {
        var copy = self
        copy.token = token
        return copy
    }
    
    public func deauthorized() -> Self {
        var copy = self
        copy.token = nil
        return copy
    }
    
    // MARK: - Retry
    
    public var shouldRetry: Bool {
        retryPolicy?.shouldRetry ?? false
    }
    
    public func withReducedRetries() -> Self {
        var copy = self
        copy.retryPolicy?.incrementRetry()
        return copy
    }
    
    // MARK: - URLRequest Conversion
    
    public func makeURLRequest() async throws -> URLRequest {
        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.cachePolicy = cachePolicy
        request.timeoutInterval = timeout
        
        // Headers for protobuf over HTTP
        request.setValue("InterPrep/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/x-protobuf", forHTTPHeaderField: "Content-Type")
        request.setValue("application/x-protobuf", forHTTPHeaderField: "Accept")
        
        // Add headers
        for header in headers {
            request.setValue(header.value, forHTTPHeaderField: header.name)
        }
        
        // Add authorization if present
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Encode body if present
        if let message = messageToEncode {
            request.httpBody = try await encodingStrategy(message)
        }
        
        return request
    }
}

// MARK: - Network Error

public enum NetworkError: Error, LocalizedError {
    case invalidURL
    case encodingFailed(Error)
    case decodingFailed(Error)
    case httpError(Int, Data?)
    case unauthorized
    case noData
    case transportError(Error)
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .encodingFailed(let error):
            return "Encoding failed: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Decoding failed: \(error.localizedDescription)"
        case .httpError(let code, _):
            return "HTTP error: \(code)"
        case .unauthorized:
            return "Unauthorized"
        case .noData:
            return "No data received"
        case .transportError(let error):
            return (error as NSError).localizedDescription
        case .unknown:
            return "Unknown error"
        }
    }
    
    /// True if this is a connection/transport failure (e.g. connection lost, timeout, no network).
    public var isConnectionError: Bool {
        if case .transportError(let error) = self {
            let ns = error as NSError
            return ns.domain == NSURLErrorDomain && (
                ns.code == NSURLErrorNotConnectedToInternet ||
                ns.code == NSURLErrorNetworkConnectionLost ||
                ns.code == NSURLErrorTimedOut ||
                ns.code == NSURLErrorCannotConnectToHost
            )
        }
        return false
    }
}
