import Foundation
import NetworkService

public enum DataSource: Sendable {
    case network
    case cache(updatedAt: Date)
}

public struct OfflineResult<T: Sendable>: Sendable {
    public let data: T
    public let source: DataSource

    public init(data: T, source: DataSource) {
        self.data = data
        self.source = source
    }

    public var isFromCache: Bool {
        if case .cache = source { return true }
        return false
    }

    public var cacheDate: Date? {
        if case .cache(let date) = source { return date }
        return nil
    }
}

public actor OfflineDataProvider {
    private let cacheManager = CacheManager.shared

    public init() {}

    public func fetch<T: Codable & Sendable>(
        cacheKey: String,
        maxCacheAge: TimeInterval = 86400,
        networkFetch: @Sendable () async throws -> T
    ) async -> Result<OfflineResult<T>, Error> {
        do {
            let data = try await networkFetch()

            try? await cacheManager.saveWithMetadata(data, forKey: cacheKey)

            return .success(OfflineResult(data: data, source: .network))
        } catch {
            let isConnectionError: Bool
            if let networkError = error as? NetworkError {
                isConnectionError = networkError.isConnectionError
            } else {
                let desc = error.localizedDescription.lowercased()
                isConnectionError = desc.contains("connection") || desc.contains("network") || desc.contains("offline")
            }

            if isConnectionError {
                if let cached = try? await cacheManager.loadWithMetadata(forKey: cacheKey, as: T.self) {
                    return .success(OfflineResult(data: cached.data, source: .cache(updatedAt: cached.cachedAt)))
                }
            }

            return .failure(error)
        }
    }

    public func fetchWithFallback<T: Codable & Sendable>(
        cacheKey: String,
        networkFetch: @Sendable () async throws -> T
    ) async -> Result<OfflineResult<T>, Error> {
        do {
            let data = try await networkFetch()
            try? await cacheManager.saveWithMetadata(data, forKey: cacheKey)
            return .success(OfflineResult(data: data, source: .network))
        } catch {
            if let cached = try? await cacheManager.loadWithMetadata(forKey: cacheKey, as: T.self) {
                return .success(OfflineResult(data: cached.data, source: .cache(updatedAt: cached.cachedAt)))
            }
            return .failure(error)
        }
    }

    public func getCached<T: Codable>(forKey key: String, as type: T.Type) async -> CachedData<T>? {
        try? await cacheManager.loadWithMetadata(forKey: key, as: type)
    }

    public func invalidateCache(forKey key: String) async {
        try? await cacheManager.remove(forKey: key)
    }
}

public extension OfflineDataProvider {
    func fetchList<T: Codable & Sendable>(
        cacheKey: String,
        networkFetch: @Sendable () async throws -> [T]
    ) async -> Result<OfflineResult<[T]>, Error> {
        await fetch(cacheKey: cacheKey, networkFetch: networkFetch)
    }
}
