//
//  CacheManager.swift
//  InterPrep
//
//  Cache manager for offline mode support
//

import Foundation

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
    
    // MARK: - Generic Cache Operations
    
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
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        try? fileManager.removeItem(at: fileURL)
    }
    
    public func exists(forKey key: String) async -> Bool {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    // MARK: - Cache Age
    
    public func getCacheAge(forKey key: String) async -> TimeInterval? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        
        guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
              let modificationDate = attributes[.modificationDate] as? Date else {
            return nil
        }
        
        return Date().timeIntervalSince(modificationDate)
    }
    
    public func isCacheValid(forKey key: String, maxAge: TimeInterval) async -> Bool {
        guard let age = await getCacheAge(forKey: key) else {
            return false
        }
        return age < maxAge
    }
    
    // MARK: - Clear All Cache
    
    public func clearAll() async throws {
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for fileURL in contents {
            try? fileManager.removeItem(at: fileURL)
        }
    }
    
    // MARK: - Binary Data Cache (for documents, images)
    
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
}

// MARK: - Cache Keys

public enum CacheKey {
    // Calendar
    public static func calendarEvents(month: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return "calendar_events_\(formatter.string(from: month))"
    }
    
    public static let allCalendarEvents = "calendar_events_all"
    
    // Profile
    public static let profileUser = "profile_user"
    public static let profileStatistics = "profile_statistics"
    public static let profileSettings = "profile_settings"
    public static let profileInterviewsUpcoming = "profile_interviews_upcoming"
    public static let profileInterviewsCompleted = "profile_interviews_completed"
    
    // Documents
    public static let documentsFolders = "documents_folders"
    public static let documentsRoot = "documents_root"
    public static let documentsRecent = "documents_recent"
    
    public static func documentFolderContents(folderId: String) -> String {
        return "documents_folder_\(folderId)"
    }
    
    public static func documentContent(documentId: String) -> String {
        return "document_content_\(documentId)"
    }
    
    // Discovery
    public static let discoveryVacancies = "discovery_vacancies"
    
    /// Last successful coach chat history (user/assistant text only; for offline read).
    public static let coachChatHistory = "coach_chat_history"
}
