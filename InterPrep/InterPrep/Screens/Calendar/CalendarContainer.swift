//
//  CalendarContainer.swift
//  InterPrep
//
//  Calendar feature container
//

import SwiftUI
import ArchitectureCore

public struct CalendarContainer: View {
    @StateObject private var store: CalendarStore
    
    public init(store: CalendarStore) {
        _store = StateObject(wrappedValue: store)
    }
    
    public init() {
        // Mock service for preview - will be replaced by real service from AppGraph
        _store = StateObject(wrappedValue: Store(
            state: CalendarState(),
            effectHandler: CalendarEffectHandler(calendarService: MockCalendarService())
        ))
    }
    
    public var body: some View {
        CalendarView(model: makeModel())
            .onAppear {
                store.send(.onAppear)
            }
    }
    
    private func makeModel() -> CalendarView.Model {
        .init(
            selectedDate: store.state.selectedDate,
            currentMonth: store.state.currentMonth,
            events: store.state.events,
            isCreatingEvent: store.state.isCreatingEvent,
            onDateSelected: { date in
                store.send(.dateSelected(date))
            },
            onMonthChanged: { date in
                store.send(.monthChanged(date))
            },
            onCreateEventTapped: {
                store.send(.createEventTapped)
            },
            onCancelEventCreation: {
                store.send(.cancelEventCreation)
            },
            onDeleteEvent: { id in
                store.send(.deleteEvent(id))
            },
            onToggleEventCompletion: { id in
                store.send(.toggleEventCompletion(id))
            },
            onEditEvent: { event in
                store.send(.editEvent(event))
            },
            onSyncCompleted: { events in
                store.send(.syncCompleted(events))
            },
            eventCreationModel: makeEventCreationModel()
        )
    }
    
    private func makeEventCreationModel() -> EventCreationView.Model {
        .init(
            title: store.state.newEventTitle,
            description: store.state.newEventDescription,
            date: store.state.newEventDate,
            time: store.state.newEventTime,
            endDate: store.state.newEventEndDate,
            type: store.state.newEventType,
            reminderEnabled: store.state.newEventReminderEnabled,
            reminderMinutes: store.state.newEventReminderMinutes,
            errorMessage: store.state.errorMessage,
            onTitleChanged: { title in
                store.send(.eventTitleChanged(title))
            },
            onDescriptionChanged: { description in
                store.send(.eventDescriptionChanged(description))
            },
            onDateChanged: { date in
                store.send(.eventDateChanged(date))
            },
            onTimeChanged: { time in
                store.send(.eventTimeChanged(time))
            },
            onEndDateChanged: { date in
                store.send(.eventEndDateChanged(date))
            },
            onTypeChanged: { type in
                store.send(.eventTypeChanged(type))
            },
            onReminderToggled: { enabled in
                store.send(.eventReminderToggled(enabled))
            },
            onReminderMinutesChanged: { minutes in
                store.send(.eventReminderMinutesChanged(minutes))
            },
            onSave: {
                store.send(.saveEventTapped)
            },
            onCancel: {
                store.send(.cancelEventCreation)
            }
        )
    }
}

// MARK: - Preview

#Preview {
    CalendarContainer()
}
