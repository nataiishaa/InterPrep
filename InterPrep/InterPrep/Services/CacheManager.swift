import Foundation

public struct CachedData<T: Codable>: Codable {
    public let data: T
    public let cachedAt: Date
    public let etag: String?

    public init(data: T, cachedAt: Date = Date(), etag: String? = nil) {
        self.data = data
        self.cachedAt = cachedAt
        self.etag = etag
    }

    public var age: TimeInterval {
        Date().timeIntervalSince(cachedAt)
    }
}

public actor CacheManager {
    public static let shared = CacheManager()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = cachesDir.appendingPathComponent("InterPrepOfflineCache", isDirectory: true)

        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    public func save<T: Encodable>(_ data: T, forKey key: String) async throws {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        let encoded = try encoder.encode(data)
        try encoded.write(to: fileURL, options: .atomic)
    }

    public func load<T: Decodable>(forKey key: String, as type: T.Type) async throws -> T? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(T.self, from: data)
    }

    public func remove(forKey key: String) async throws {
        let jsonFileURL = cacheDirectory.appendingPathComponent("\(key).json")
        let cachedFileURL = cacheDirectory.appendingPathComponent("\(key).cached.json")
        let binFileURL = cacheDirectory.appendingPathComponent("\(key).bin")

        try? fileManager.removeItem(at: jsonFileURL)
        try? fileManager.removeItem(at: cachedFileURL)
        try? fileManager.removeItem(at: binFileURL)
    }

    public func exists(forKey key: String) async -> Bool {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        return fileManager.fileExists(atPath: fileURL.path)
    }

    public func saveWithMetadata<T: Codable>(_ data: T, forKey key: String, etag: String? = nil) async throws {
        let cached = CachedData(data: data, cachedAt: Date(), etag: etag)
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cached.json")
        let encoded = try encoder.encode(cached)
        try encoded.write(to: fileURL, options: .atomic)
    }

    public func loadWithMetadata<T: Decodable>(forKey key: String, as type: T.Type) async throws -> CachedData<T>? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cached.json")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(CachedData<T>.self, from: data)
    }

    public func getEtag(forKey key: String) async -> String? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cached.json")

        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        return json["etag"] as? String
    }

    public func getCacheAge(forKey key: String) async -> TimeInterval? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")

        guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
              let modificationDate = attributes[.modificationDate] as? Date else {
            return nil
        }

        return Date().timeIntervalSince(modificationDate)
    }

    public func getCacheDate(forKey key: String) async -> Date? {
        let cachedFileURL = cacheDirectory.appendingPathComponent("\(key).cached.json")
        let regularFileURL = cacheDirectory.appendingPathComponent("\(key).json")

        if fileManager.fileExists(atPath: cachedFileURL.path),
           let data = try? Data(contentsOf: cachedFileURL),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let cachedAtString = json["cachedAt"] as? String,
           let cachedAt = ISO8601DateFormatter().date(from: cachedAtString) {
            return cachedAt
        }

        if let attributes = try? fileManager.attributesOfItem(atPath: regularFileURL.path),
           let modificationDate = attributes[.modificationDate] as? Date {
            return modificationDate
        }

        return nil
    }

    public func isCacheValid(forKey key: String, maxAge: TimeInterval) async -> Bool {
        guard let age = await getCacheAge(forKey: key) else {
            return false
        }
        return age < maxAge
    }

    public func clearAll() async throws {
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for fileURL in contents {
            try? fileManager.removeItem(at: fileURL)
        }
    }

    public func clearExpired(maxAge: TimeInterval) async throws {
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
        let now = Date()

        for fileURL in contents {
            guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                  let modificationDate = attributes[.modificationDate] as? Date else {
                continue
            }

            if now.timeIntervalSince(modificationDate) > maxAge {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }

    public func saveBinary(_ data: Data, forKey key: String) async throws {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).bin")
        try data.write(to: fileURL, options: .atomic)
    }

    public func loadBinary(forKey key: String) async throws -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).bin")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        return try Data(contentsOf: fileURL)
    }

    public func totalCacheSize() async -> Int64 {
        guard let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        var totalSize: Int64 = 0
        for fileURL in contents {
            if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
               let size = attributes[.size] as? Int64 {
                totalSize += size
            }
        }
        return totalSize
    }
}

public enum CacheKey {
    public static func calendarEvents(month: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return "calendar_events_\(formatter.string(from: month))"
    }

    public static let allCalendarEvents = "calendar_events_all"

    public static let profileUser = "profile_user"
    public static let profileStatistics = "profile_statistics"
    public static let profileSettings = "profile_settings"
    public static let profileInterviewsUpcoming = "profile_interviews_upcoming"
    public static let profileInterviewsCompleted = "profile_interviews_completed"

    public static let documentsFolders = "documents_folders"
    public static let documentsRoot = "documents_root"
    public static let documentsRecent = "documents_recent"

    public static func documentFolderContents(folderId: String) -> String {
        return "documents_folder_\(folderId)"
    }

    public static func documentContent(documentId: String) -> String {
        return "document_content_\(documentId)"
    }

    public static func documentMeta(documentId: String) -> String {
        return "document_meta_\(documentId)"
    }

    public static let documentsMaterialIds = "documents_material_ids"

    public static let discoveryVacancies = "discovery_vacancies"

    public static let coachChatHistory = "coach_chat_history"
}
