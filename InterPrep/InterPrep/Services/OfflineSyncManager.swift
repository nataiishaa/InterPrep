//
//  OfflineSyncManager.swift
//  InterPrep
//
//  Manages pending operations for sync when connection is restored
//

import Foundation
import Combine

public enum PendingOperation: Codable, Sendable {
    case createCalendarEvent(title: String, description: String, startTime: Date, endTime: Date, eventType: String, reminderEnabled: Bool, reminderMinutes: Int32)
    case updateCalendarEvent(id: String, title: String, description: String, startTime: Date, endTime: Date, eventType: String, reminderEnabled: Bool, reminderMinutes: Int32, completed: Bool)
    case deleteCalendarEvent(id: String)
    
    case updateProfile(firstName: String, lastName: String)
    case uploadProfilePhoto(data: Data)
    
    case createFolder(name: String, parentId: UInt32?)
    case uploadDocument(data: Data, filename: String, folderId: UUID?)
    case createNote(title: String, content: String, parentId: UInt32?)
    case deleteDocument(id: UUID)
}

public struct PendingOperationItem: Codable, Identifiable, Sendable {
    public let id: UUID
    public let operation: PendingOperation
    public let timestamp: Date
    
    public init(id: UUID = UUID(), operation: PendingOperation, timestamp: Date = Date()) {
        self.id = id
        self.operation = operation
        self.timestamp = timestamp
    }
}

@MainActor
public final class OfflineSyncManager: ObservableObject {
    public static let shared = OfflineSyncManager()
    
    @Published public private(set) var pendingOperations: [PendingOperationItem] = []
    @Published public private(set) var isSyncing: Bool = false
    
    private let cacheKey = "pending_operations"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadPendingOperations()
        observeNetworkChanges()
    }
    
    private func observeNetworkChanges() {
        NetworkMonitor.shared.$isConnected
            .dropFirst()
            .filter { $0 }
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.syncPendingOperations()
                }
            }
            .store(in: &cancellables)
    }
    
    public func addOperation(_ operation: PendingOperation) {
        let item = PendingOperationItem(operation: operation)
        pendingOperations.append(item)
        savePendingOperations()
    }
    
    public func removeOperation(_ id: UUID) {
        pendingOperations.removeAll { $0.id == id }
        savePendingOperations()
    }
    
    public func clearAll() {
        pendingOperations.removeAll()
        savePendingOperations()
    }
    
    private func loadPendingOperations() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let operations = try? JSONDecoder().decode([PendingOperationItem].self, from: data) else {
            return
        }
        pendingOperations = operations
    }
    
    private func savePendingOperations() {
        guard let data = try? JSONEncoder().encode(pendingOperations) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
    }
    
    public func syncPendingOperations() async {
        guard !isSyncing, !pendingOperations.isEmpty else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        let operations = pendingOperations
        
        for item in operations {
            let success = await executeOperation(item.operation)
            if success {
                removeOperation(item.id)
            }
        }
    }
    
    private func executeOperation(_ operation: PendingOperation) async -> Bool {
        return false
    }
    
    public var hasPendingOperations: Bool {
        !pendingOperations.isEmpty
    }
    
    public var pendingCount: Int {
        pendingOperations.count
    }
}
