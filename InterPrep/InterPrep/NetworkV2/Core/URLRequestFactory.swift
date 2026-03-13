import Foundation
import SwiftProtobuf

// MARK: - Content Type Provider

public protocol ContentTypeProvider: Sendable {
    var contentType: ContentType { get }
}

public struct DefaultContentTypeProvider: ContentTypeProvider, Sendable {
    public let contentType: ContentType
    
    /// По умолчанию шлём JSON, чтобы совпасть с тем, как ты дергаешь API руками.
    public init(contentType: ContentType = .json) {
        self.contentType = contentType
    }
}

// MARK: - Network Provider

public protocol NetworkProvider: Sendable {
    var scheme: String { get }
    var host: String { get }
    var port: Int? { get }
}

public struct DefaultNetworkProvider: NetworkProvider, Sendable {
    public let scheme: String
    public let host: String
    public let port: Int?
    
    public init(scheme: String = "http", host: String = "193.124.33.223", port: Int? = 9090) {
        self.scheme = scheme
        self.host = host
        self.port = port
    }
}

// MARK: - URL Request Factory

public final class URLRequestFactory: Sendable {
    private let contentTypeProvider: ContentTypeProvider
    private let networkProvider: NetworkProvider
    
    public init(
        contentTypeProvider: ContentTypeProvider = DefaultContentTypeProvider(),
        networkProvider: NetworkProvider = DefaultNetworkProvider()
    ) {
        self.contentTypeProvider = contentTypeProvider
        self.networkProvider = networkProvider
    }
    
    // MARK: - Assemble Request
    
    public func assemble<Response: Message>(
        path: String,
        method: HTTPMethod = .post,
        message: (any Message)? = nil,
        headers: [HTTPHeader] = [],
        queryItems: [URLQueryItem] = [],
        cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalAndRemoteCacheData,
        timeout: TimeInterval = 60,
        retryPolicy: RetryPolicy? = nil
    ) -> ProtoRequest<Response> {
        var components = URLComponents()
        components.scheme = networkProvider.scheme
        components.host = networkProvider.host
        components.port = networkProvider.port
        components.path = path
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        
        let contentTypeHeader = HTTPHeader.contentType(contentTypeProvider.contentType)
        let allHeaders = [contentTypeHeader] + headers
        
        return ProtoRequest(
            urlComponents: components,
            messageToEncode: message,
            decodingStrategy: decode,
            encodingStrategy: encode,
            method: method,
            headers: allHeaders,
            cachePolicy: cachePolicy,
            timeout: timeout,
            retryPolicy: retryPolicy
        )
    }
    
    // MARK: - Encoding
    
    private func encode(message: any Message) async throws -> Data {
        do {
            switch contentTypeProvider.contentType {
            case .protobuf:
                return try message.serializedData()
            case .json:
                return try message.jsonUTF8Data()
            }
        } catch {
            throw NetworkError.encodingFailed(error)
        }
    }
    
    // MARK: - Decoding
    
    private func decode<Response: Message>(data: Data) async throws -> Response {
        do {
            switch contentTypeProvider.contentType {
            case .protobuf:
                return try Response(serializedData: data)
            case .json:
                var options = JSONDecodingOptions()
                options.ignoreUnknownFields = true
                return try Response(jsonUTF8Data: data, options: options)
            }
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
}
