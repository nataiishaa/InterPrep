import Combine
import Foundation
import NetworkService

public enum PendingOperation: Codable, Sendable {
    case createCalendarEvent(title: String, description: String, startTime: Date, endTime: Date, eventType: String, reminderEnabled: Bool, reminderMinutes: Int32)
    case updateCalendarEvent(id: String, title: String, description: String, startTime: Date, endTime: Date, eventType: String, reminderEnabled: Bool, reminderMinutes: Int32, completed: Bool)
    case deleteCalendarEvent(id: String)

    case updateProfile(firstName: String, lastName: String)
    case uploadProfilePhoto(data: Data)

    case createFolder(name: String, parentId: UInt32?)
    case uploadDocument(data: Data, filename: String, folderId: UInt32?)
    case createNote(title: String, content: String, parentId: UInt32?)
    case deleteDocument(id: UUID)

    case addFavoriteVacancy(vacancyId: String)
    case removeFavoriteVacancy(vacancyId: String)
}

public struct PendingOperationItem: Codable, Identifiable, Sendable {
    public let id: UUID
    public let operation: PendingOperation
    public let timestamp: Date
    public private(set) var retryCount: Int

    public init(id: UUID = UUID(), operation: PendingOperation, timestamp: Date = Date(), retryCount: Int = 0) {
        self.id = id
        self.operation = operation
        self.timestamp = timestamp
        self.retryCount = retryCount
    }

    public mutating func incrementRetry() {
        retryCount += 1
    }
}

public enum SyncResult: Sendable {
    case success
    case retryLater
    case permanentFailure
}

@MainActor
public final class OfflineSyncManager: ObservableObject {
    public static let shared = OfflineSyncManager()

    @Published public private(set) var pendingOperations: [PendingOperationItem] = []
    @Published public private(set) var isSyncing: Bool = false
    @Published public private(set) var lastSyncAttempt: Date?
    @Published public private(set) var failedOperationsCount: Int = 0

    private let cacheKey = "pending_operations"
    private let maxRetries = 3
    private var cancellables = Set<AnyCancellable>()
    private var _networkService: NetworkServiceV2?
    private var networkService: NetworkServiceV2 {
        if _networkService == nil {
            _networkService = NetworkServiceV2.shared
        }
        return _networkService!
    }

    private init() {
        loadPendingOperations()
        DispatchQueue.main.async { [weak self] in
            self?.observeNetworkChanges()
        }
    }

    private func observeNetworkChanges() {
        NetworkMonitor.shared.$isConnected
            .dropFirst()
            .removeDuplicates()
            .filter { $0 }
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
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
        failedOperationsCount = 0
        savePendingOperations()
    }

    private func loadPendingOperations() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let operations = try? JSONDecoder().decode([PendingOperationItem].self, from: data) else {
            return
        }
        pendingOperations = operations
        failedOperationsCount = operations.filter { $0.retryCount >= maxRetries }.count
    }

    private func savePendingOperations() {
        guard let data = try? JSONEncoder().encode(pendingOperations) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
    }

    public func syncPendingOperations() async {
        guard !isSyncing, !pendingOperations.isEmpty else { return }
        guard NetworkMonitor.shared.isConnected else { return }

        isSyncing = true
        lastSyncAttempt = Date()
        defer { isSyncing = false }

        var completedIds: [UUID] = []
        var permanentFailureIds: [UUID] = []
        var updatedItems: [PendingOperationItem] = []

        for var item in pendingOperations {
            if item.retryCount >= maxRetries {
                permanentFailureIds.append(item.id)
                continue
            }

            let result = await executeOperation(item.operation)

            switch result {
            case .success:
                completedIds.append(item.id)
            case .retryLater:
                item.incrementRetry()
                updatedItems.append(item)
            case .permanentFailure:
                permanentFailureIds.append(item.id)
            }
        }

        pendingOperations.removeAll { completedIds.contains($0.id) || permanentFailureIds.contains($0.id) }

        for updated in updatedItems {
            if let index = pendingOperations.firstIndex(where: { $0.id == updated.id }) {
                pendingOperations[index] = updated
            }
        }

        failedOperationsCount = pendingOperations.filter { $0.retryCount >= maxRetries }.count

        savePendingOperations()
    }

    private func executeOperation(_ operation: PendingOperation) async -> SyncResult {
        switch operation {
        case let .createCalendarEvent(title, description, startTime, endTime, eventType, reminderEnabled, reminderMinutes):
            return await executeCreateCalendarEvent(
                title: title,
                description: description,
                startTime: startTime,
                endTime: endTime,
                eventType: eventType,
                reminderEnabled: reminderEnabled,
                reminderMinutes: reminderMinutes
            )

        case let .updateCalendarEvent(id, title, description, startTime, endTime, eventType, reminderEnabled, reminderMinutes, completed):
            return await executeUpdateCalendarEvent(
                id: id,
                title: title,
                description: description,
                startTime: startTime,
                endTime: endTime,
                eventType: eventType,
                reminderEnabled: reminderEnabled,
                reminderMinutes: reminderMinutes,
                completed: completed
            )

        case let .deleteCalendarEvent(id):
            return await executeDeleteCalendarEvent(id: id)

        case let .updateProfile(firstName, lastName):
            return await executeUpdateProfile(firstName: firstName, lastName: lastName)

        case let .uploadProfilePhoto(data):
            return await executeUploadProfilePhoto(data: data)

        case let .createFolder(name, parentId):
            return await executeCreateFolder(name: name, parentId: parentId)

        case let .uploadDocument(data, filename, folderId):
            return await executeUploadDocument(data: data, filename: filename, folderId: folderId)

        case let .createNote(title, content, parentId):
            return await executeCreateNote(title: title, content: content, parentId: parentId)

        case let .deleteDocument(id):
            return await executeDeleteDocument(id: id)

        case let .addFavoriteVacancy(vacancyId):
            return await executeAddFavorite(vacancyId: vacancyId)

        case let .removeFavoriteVacancy(vacancyId):
            return await executeRemoveFavorite(vacancyId: vacancyId)
        }
    }

    // swiftlint:disable:next function_parameter_count
    private func executeCreateCalendarEvent(
        title: String,
        description: String,
        startTime: Date,
        endTime: Date,
        eventType: String,
        reminderEnabled: Bool,
        reminderMinutes: Int32
    ) async -> SyncResult {
        let protoType = mapStringToCalendarEventType(eventType)
        let result = await networkService.createEvent(
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            eventType: protoType,
            location: nil,
            reminderEnabled: reminderEnabled,
            reminderMinutes: reminderMinutes
        )
        return mapNetworkResult(result)
    }

    // swiftlint:disable:next function_parameter_count
    private func executeUpdateCalendarEvent(
        id: String,
        title: String,
        description: String,
        startTime: Date,
        endTime: Date,
        eventType: String,
        reminderEnabled: Bool,
        reminderMinutes: Int32,
        completed: Bool
    ) async -> SyncResult {
        let protoType = mapStringToCalendarEventType(eventType)
        let result = await networkService.updateEvent(
            id: id,
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            eventType: protoType,
            location: nil,
            reminderEnabled: reminderEnabled,
            reminderMinutes: reminderMinutes,
            completed: completed
        )
        return mapNetworkResult(result)
    }

    private func executeDeleteCalendarEvent(id: String) async -> SyncResult {
        let result = await networkService.deleteEvent(id: id)
        return mapNetworkResult(result)
    }

    private func executeUpdateProfile(firstName: String, lastName: String) async -> SyncResult {
        let result = await networkService.updateUserProfile(firstName: firstName, lastName: lastName)
        return mapNetworkResult(result)
    }

    private func executeUploadProfilePhoto(data: Data) async -> SyncResult {
        let result = await networkService.uploadProfilePhoto(imageData: data)
        return mapNetworkResult(result)
    }

    private func executeCreateFolder(name: String, parentId: UInt32?) async -> SyncResult {
        let result = await networkService.createFolder(name: name, parentId: parentId)
        return mapNetworkResult(result)
    }

    private func executeUploadDocument(data: Data, filename: String, folderId: UInt32?) async -> SyncResult {
        let result = await networkService.uploadFile(fileContent: data, filename: filename, parentId: folderId)
        return mapNetworkResult(result)
    }

    private func executeCreateNote(title: String, content: String, parentId: UInt32?) async -> SyncResult {
        let result = await networkService.createLink(name: title, url: "", title: title, description: content, parentId: parentId)
        return mapNetworkResult(result)
    }

    private func executeDeleteDocument(id: UUID) async -> SyncResult {
        return .success
    }

    private func executeAddFavorite(vacancyId: String) async -> SyncResult {
        let result = await networkService.addFavorite(vacancyId: vacancyId)
        return mapNetworkResult(result)
    }

    private func executeRemoveFavorite(vacancyId: String) async -> SyncResult {
        let result = await networkService.removeFavorite(vacancyId: vacancyId)
        return mapNetworkResult(result)
    }

    private func mapNetworkResult<T>(_ result: Result<T, NetworkError>) -> SyncResult {
        switch result {
        case .success:
            return .success
        case .failure(let error):
            if error.isConnectionError {
                return .retryLater
            }
            if case .unauthorized = error {
                return .permanentFailure
            }
            if let apiError = error.asAPIError {
                switch apiError.code {
                case .invalidArgument, .permissionDenied, .notFound, .alreadyExists, .failedPrecondition:
                    return .permanentFailure
                case .unauthenticated:
                    return .permanentFailure
                case .internalError, .resourceExhausted, .unknown:
                    return .retryLater
                }
            }
            return .retryLater
        }
    }

    private func mapStringToCalendarEventType(_ string: String) -> Calendar_EventType {
        switch string.lowercased() {
        case "interview": return .interview
        case "call": return .call
        case "meeting": return .meeting
        case "test", "testtask": return .testTask
        case "prep": return .prep
        case "deadline": return .deadline
        case "other": return .other
        default: return .unspecified
        }
    }

    public var hasPendingOperations: Bool {
        !pendingOperations.isEmpty
    }

    public var pendingCount: Int {
        pendingOperations.count
    }

    public var hasFailedOperations: Bool {
        failedOperationsCount > 0
    }

    public func retryFailedOperations() {
        for index in pendingOperations.indices {
            pendingOperations[index] = PendingOperationItem(
                id: pendingOperations[index].id,
                operation: pendingOperations[index].operation,
                timestamp: pendingOperations[index].timestamp,
                retryCount: 0
            )
        }
        failedOperationsCount = 0
        savePendingOperations()

        Task {
            await syncPendingOperations()
        }
    }
}
