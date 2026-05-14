//
//  CalendarStoreTests.swift
//  CalendarFeatureTests
//
//  Integration tests for CalendarStore (State + EffectHandler full cycle)
//

import ArchitectureCore
import CacheService
@testable import CalendarFeature
import XCTest

// MARK: - Spy

private actor SpyCalendarService: CalendarServicing {
    var listEventsResult: Result<[CalendarEvent], Error> = .success([])
    var createEventResult: Result<CalendarEvent, Error>?
    var updateEventResult: Result<CalendarEvent, Error>?
    var deleteEventResult: Result<Bool, Error> = .success(true)

    var listEventsCallCount = 0
    var createEventCallCount = 0
    var deleteEventCallCount = 0
    var lastDeletedId: String?

    func listEvents(fromTime: Date, toTime: Date) async throws -> [CalendarEvent] {
        listEventsCallCount += 1
        switch listEventsResult {
        case .success(let events): return events
        case .failure(let error): throw error
        }
    }

    func listUpcoming(limit: Int32) async throws -> [CalendarEvent] { [] }

    func createEvent(
        title: String, description: String, startTime: Date, endTime: Date, eventType: CalendarEventType
    ) async throws -> CalendarEvent {
        try await createEvent(
            title: title, description: description, startTime: startTime, endTime: endTime,
            eventType: eventType, location: nil, reminderEnabled: false, reminderMinutes: 15
        )
    }

    // swiftlint:disable:next function_parameter_count
    func createEvent(
        title: String, description: String, startTime: Date, endTime: Date,
        eventType: CalendarEventType, location: String?,
        reminderEnabled: Bool, reminderMinutes: Int32
    ) async throws -> CalendarEvent {
        createEventCallCount += 1
        if let result = createEventResult {
            switch result {
            case .success(let event): return event
            case .failure(let error): throw error
            }
        }
        return CalendarEvent(
            id: UUID().uuidString, title: title, description: description,
            eventType: eventType, startTime: startTime, endTime: endTime,
            reminderEnabled: reminderEnabled, reminderMinutes: reminderMinutes,
            createdAt: Date(), updatedAt: Date()
        )
    }

    func updateEvent(
        id: String, title: String?, description: String?, startTime: Date?, endTime: Date?
    ) async throws -> CalendarEvent {
        try await updateEvent(
            id: id, title: title, description: description, startTime: startTime, endTime: endTime,
            eventType: nil, location: nil, reminderEnabled: nil, reminderMinutes: nil, completed: nil
        )
    }

    // swiftlint:disable:next function_parameter_count
    func updateEvent(
        id: String, title: String?, description: String?, startTime: Date?, endTime: Date?,
        eventType: CalendarEventType?, location: String?,
        reminderEnabled: Bool?, reminderMinutes: Int32?, completed: Bool?
    ) async throws -> CalendarEvent {
        if let result = updateEventResult {
            switch result {
            case .success(let event): return event
            case .failure(let error): throw error
            }
        }
        return CalendarEvent(
            id: id, title: title ?? "", description: description ?? "",
            eventType: eventType ?? .other, startTime: startTime ?? Date(), endTime: endTime ?? Date(),
            reminderEnabled: reminderEnabled ?? false, reminderMinutes: reminderMinutes ?? 30,
            completed: completed ?? false, createdAt: Date(), updatedAt: Date()
        )
    }

    func deleteEvent(id: String) async throws -> Bool {
        deleteEventCallCount += 1
        lastDeletedId = id
        switch deleteEventResult {
        case .success(let deleted): return deleted
        case .failure(let error): throw error
        }
    }

    func setListEventsResult(_ result: Result<[CalendarEvent], Error>) { listEventsResult = result }
    func setCreateEventResult(_ result: Result<CalendarEvent, Error>) { createEventResult = result }
    func setDeleteEventResult(_ result: Result<Bool, Error>) { deleteEventResult = result }
}

private enum TestError: LocalizedError {
    case network
    var errorDescription: String? { "Network error" }
}

// MARK: - Tests

@MainActor
final class CalendarStoreTests: XCTestCase {
    private var calendarService: SpyCalendarService!
    private var store: CalendarStore!

    override func setUp() async throws {
        try await super.setUp()
        try? await CacheManager.shared.clearAll()
        calendarService = SpyCalendarService()
        store = CalendarStore(
            state: CalendarState(),
            effectHandler: CalendarEffectHandler(calendarService: calendarService)
        )
    }

    override func tearDown() {
        store = nil
        calendarService = nil
        super.tearDown()
    }

    private func waitForEffects() async {
        try? await Task.sleep(nanoseconds: 150_000_000)
        await Task.yield()
    }

    // MARK: - onAppear

    func test_onAppear_success_loadsEvents() async {
        let event = CalendarEvent(
            id: "e1", title: "Собеседование", description: "Яндекс",
            eventType: .interview, startTime: Date(), endTime: Date().addingTimeInterval(3600),
            reminderEnabled: false, reminderMinutes: 0, createdAt: Date(), updatedAt: Date()
        )
        await calendarService.setListEventsResult(.success([event]))

        store.send(.onAppear)

        XCTAssertTrue(store.state.isLoading)

        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertEqual(store.state.events.count, 1)
        XCTAssertEqual(store.state.events.first?.title, "Собеседование")
    }

    func test_onAppear_failure_showsError() async {
        await calendarService.setListEventsResult(.failure(TestError.network))

        store.send(.onAppear)

        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertNotNil(store.state.errorMessage)
    }

    // MARK: - Date Selection

    func test_dateSelected_updatesDate() {
        let tomorrow = Date().addingTimeInterval(86400)

        store.send(.dateSelected(tomorrow))

        XCTAssertTrue(Calendar.current.isDate(store.state.selectedDate, inSameDayAs: tomorrow))
    }

    // MARK: - Month Changed

    func test_monthChanged_updatesMonthAndLoadsEvents() async {
        let nextMonth = Date().addingTimeInterval(30 * 86400)
        await calendarService.setListEventsResult(.success([]))

        store.send(.monthChanged(nextMonth))

        XCTAssertEqual(store.state.currentMonth, nextMonth)
        XCTAssertTrue(store.state.isLoading)

        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        let callCount = await calendarService.listEventsCallCount
        XCTAssertEqual(callCount, 1)
    }

    // MARK: - Create Event

    func test_createEventTapped_showsForm() {
        store.send(.createEventTapped)

        XCTAssertTrue(store.state.isCreatingEvent)
        XCTAssertNil(store.state.editingEventId)
        XCTAssertEqual(store.state.newEventTitle, "")
    }

    func test_cancelEventCreation_hidesForm() {
        store.send(.createEventTapped)
        XCTAssertTrue(store.state.isCreatingEvent)

        store.send(.cancelEventCreation)

        XCTAssertFalse(store.state.isCreatingEvent)
        XCTAssertNil(store.state.errorMessage)
    }

    func test_saveEventTapped_emptyTitle_showsError() {
        store.send(.createEventTapped)
        store.send(.eventTitleChanged(""))

        store.send(.saveEventTapped)

        XCTAssertEqual(store.state.errorMessage, "Введите название события")
        XCTAssertFalse(store.state.isLoading)
    }

    func test_saveEventTapped_validTitle_createsEvent() async {
        store.send(.createEventTapped)
        store.send(.eventTitleChanged("Собеседование"))
        store.send(.eventDescriptionChanged("Техническое"))

        let futureDate = Date().addingTimeInterval(86400)
        let futureEnd = futureDate.addingTimeInterval(3600)
        store.send(.eventDateChanged(futureDate))
        store.send(.eventEndDateChanged(futureEnd))

        store.send(.saveEventTapped)

        XCTAssertTrue(store.state.isLoading)

        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertFalse(store.state.isCreatingEvent)
        XCTAssertFalse(store.state.events.isEmpty)
        let callCount = await calendarService.createEventCallCount
        XCTAssertEqual(callCount, 1)
    }

    // MARK: - Event Title Changed

    func test_eventTitleChanged_updatesAndClearsError() {
        store.send(.createEventTapped)
        store.send(.saveEventTapped)
        XCTAssertEqual(store.state.errorMessage, "Введите название события")

        store.send(.eventTitleChanged("Встреча"))

        XCTAssertEqual(store.state.newEventTitle, "Встреча")
        XCTAssertNil(store.state.errorMessage)
    }

    // MARK: - Delete Event

    func test_deleteEvent_success_removesEvent() async {
        let event = CalendarEvent(
            id: "e1", title: "Событие", description: "",
            eventType: .other, startTime: Date(), endTime: Date().addingTimeInterval(3600),
            reminderEnabled: false, reminderMinutes: 0, createdAt: Date(), updatedAt: Date()
        )
        await calendarService.setListEventsResult(.success([event]))
        store.send(.onAppear)
        await waitForEffects()

        XCTAssertEqual(store.state.events.count, 1)

        store.send(.deleteEvent("e1"))

        await waitForEffects()

        XCTAssertTrue(store.state.events.isEmpty)
        let callCount = await calendarService.deleteEventCallCount
        XCTAssertEqual(callCount, 1)
    }

    func test_deleteEvent_failure_showsError() async {
        let event = CalendarEvent(
            id: "e1", title: "Событие", description: "",
            eventType: .other, startTime: Date(), endTime: Date().addingTimeInterval(3600),
            reminderEnabled: false, reminderMinutes: 0, createdAt: Date(), updatedAt: Date()
        )
        await calendarService.setListEventsResult(.success([event]))
        store.send(.onAppear)
        await waitForEffects()

        await calendarService.setDeleteEventResult(.failure(TestError.network))
        store.send(.deleteEvent("e1"))

        await waitForEffects()

        XCTAssertNotNil(store.state.errorMessage)
    }

    // MARK: - Edit Event

    func test_editEvent_populatesForm() {
        let event = CalendarState.CalendarEvent(
            id: "e1", title: "Встреча", description: "Обсуждение",
            date: Date(), type: .meeting, reminderEnabled: true, reminderMinutesBefore: 15
        )

        store.send(.editEvent(event))

        XCTAssertTrue(store.state.isCreatingEvent)
        XCTAssertEqual(store.state.editingEventId, "e1")
        XCTAssertEqual(store.state.newEventTitle, "Встреча")
        XCTAssertEqual(store.state.newEventDescription, "Обсуждение")
        XCTAssertEqual(store.state.newEventType, .meeting)
    }

    // MARK: - Sync Completed

    func test_syncCompleted_replacesEvents() {
        let events = [
            CalendarState.CalendarEvent(title: "Synced", description: "", date: Date(), type: .other)
        ]

        store.send(.syncCompleted(events))

        XCTAssertEqual(store.state.events.count, 1)
        XCTAssertEqual(store.state.events.first?.title, "Synced")
    }

    // MARK: - Retry

    func test_retryTapped_clearsErrorAndReloads() async {
        await calendarService.setListEventsResult(.failure(TestError.network))
        store.send(.onAppear)
        await waitForEffects()

        XCTAssertNotNil(store.state.errorMessage)

        await calendarService.setListEventsResult(.success([]))
        store.send(.retryTapped)

        XCTAssertNil(store.state.errorMessage)
        XCTAssertTrue(store.state.isLoading)

        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
    }

    // MARK: - Event Type

    func test_eventTypeChanged_updatesType() {
        store.send(.createEventTapped)

        store.send(.eventTypeChanged(.call))

        XCTAssertEqual(store.state.newEventType, .call)
    }

    // MARK: - Reminder

    func test_eventReminderToggled_updatesReminder() {
        store.send(.createEventTapped)
        XCTAssertTrue(store.state.newEventReminderEnabled)

        store.send(.eventReminderToggled(false))

        XCTAssertFalse(store.state.newEventReminderEnabled)
    }
}
