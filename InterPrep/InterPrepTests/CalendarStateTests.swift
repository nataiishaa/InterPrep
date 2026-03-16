//
//  CalendarStateTests.swift
//  InterPrepTests
//
//  Unit tests for CalendarState reducer (Store state logic)
//

import XCTest
import ArchitectureCore
@testable import CalendarFeature

@MainActor
final class CalendarStateTests: XCTestCase {

    func testOnAppear_returnsLoadEvents() {
        var state = CalendarState()
        let month = state.currentMonth

        let effect = CalendarState.reduce(state: &state, with: .input(.onAppear))

        XCTAssertTrue(state.isLoading)
        guard case .loadEvents(let date) = effect else {
            XCTFail("Expected loadEvents")
            return
        }
        XCTAssertTrue(Calendar.current.isDate(date, equalTo: month, toGranularity: .month))
    }

    func testDateSelected_updatesSelectedDate() {
        var state = CalendarState()
        let date = Date().addingTimeInterval(86400)

        _ = CalendarState.reduce(state: &state, with: .input(.dateSelected(date)))

        XCTAssertTrue(Calendar.current.isDate(state.selectedDate, inSameDayAs: date))
    }

    func testMonthChanged_returnsLoadEvents() {
        var state = CalendarState()
        let newMonth = Date().addingTimeInterval(30 * 86400)

        let effect = CalendarState.reduce(state: &state, with: .input(.monthChanged(newMonth)))

        XCTAssertEqual(state.currentMonth, newMonth)
        XCTAssertTrue(state.isLoading)
        guard case .loadEvents(let date) = effect else {
            XCTFail("Expected loadEvents")
            return
        }
        XCTAssertTrue(Calendar.current.isDate(date, equalTo: newMonth, toGranularity: .month))
    }

    func testCreateEventTapped_setsCreatingAndResetsForm() {
        var state = CalendarState()
        state.selectedDate = Date()
        state.isCreatingEvent = false

        _ = CalendarState.reduce(state: &state, with: .input(.createEventTapped))

        XCTAssertTrue(state.isCreatingEvent)
        XCTAssertNil(state.editingEventId)
        XCTAssertEqual(state.newEventTitle, "")
    }

    func testCancelEventCreation_resetsCreating() {
        var state = CalendarState()
        state.isCreatingEvent = true
        state.errorMessage = "Err"

        _ = CalendarState.reduce(state: &state, with: .input(.cancelEventCreation))

        XCTAssertFalse(state.isCreatingEvent)
        XCTAssertNil(state.editingEventId)
        XCTAssertNil(state.errorMessage)
    }

    func testEventTitleChanged_updatesTitleAndClearsError() {
        var state = CalendarState()
        state.errorMessage = "Old"

        _ = CalendarState.reduce(state: &state, with: .input(.eventTitleChanged("Meeting")))

        XCTAssertEqual(state.newEventTitle, "Meeting")
        XCTAssertNil(state.errorMessage)
    }

    func testSaveEventTapped_whenTitleEmpty_setsError() {
        var state = CalendarState()
        state.newEventTitle = ""
        state.newEventDate = Date()
        state.newEventTime = Date()

        let effect = CalendarState.reduce(state: &state, with: .input(.saveEventTapped))

        XCTAssertNil(effect)
        XCTAssertEqual(state.errorMessage, "Введите название события")
    }

    func testFeedback_eventsLoaded_updatesState() {
        var state = CalendarState()
        state.isLoading = true
        let event = CalendarState.CalendarEvent(title: "E", description: "D", date: Date(), type: .interview)

        _ = CalendarState.reduce(state: &state, with: .feedback(.eventsLoaded([event])))

        XCTAssertFalse(state.isLoading)
        XCTAssertEqual(state.events.count, 1)
        XCTAssertEqual(state.events[0].title, "E")
    }

    func testFeedback_loadingFailed_setsError() {
        var state = CalendarState()
        state.isLoading = true

        _ = CalendarState.reduce(state: &state, with: .feedback(.loadingFailed("Fail")))

        XCTAssertFalse(state.isLoading)
        XCTAssertEqual(state.errorMessage, "Fail")
    }

    func testInput_syncCompleted_replacesEvents() {
        var state = CalendarState()
        let event = CalendarState.CalendarEvent(title: "Synced", description: "", date: Date(), type: .other)

        _ = CalendarState.reduce(state: &state, with: .input(.syncCompleted([event])))

        XCTAssertEqual(state.events.count, 1)
        XCTAssertEqual(state.events[0].title, "Synced")
    }
}
