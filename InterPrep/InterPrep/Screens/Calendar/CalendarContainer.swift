//
//  CalendarContainer.swift
//  InterPrep
//
//  Calendar feature container
//

import ArchitectureCore
import NetworkMonitorService
import SwiftUI

public struct CalendarContainer: View {
    @State private var store: CalendarStore
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    
    public init(store: CalendarStore) {
        self.store = store
    }
    
    public init() {
        self.store = Store(
            state: CalendarState(),
            effectHandler: CalendarEffectHandler(calendarService: MockCalendarService())
        )
    }
    
    public var body: some View {
        CalendarView(model: makeModel())
            .onAppear {
                store.send(.onAppear)
            }
            .onChange(of: networkMonitor.isConnected) { _, isConnected in
                if isConnected && store.state.isOfflineMode {
                    store.send(.retryTapped)
                }
            }
    }
    
    private func makeModel() -> CalendarView.Model {
        .init(
            selectedDate: store.state.selectedDate,
            currentMonth: store.state.currentMonth,
            events: store.state.events,
            isCreatingEvent: store.state.isCreatingEvent,
            isOfflineMode: store.state.isOfflineMode,
            errorMessage: store.state.errorMessage,
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
            onEditEvent: { event in
                store.send(.editEvent(event))
            },
            onSyncCompleted: { events in
                store.send(.syncCompleted(events))
            },
            onRetry: {
                store.send(.retryTapped)
            },
            eventCreationModel: makeEventCreationModel()
        )
    }
    
    private func makeEventCreationModel() -> EventCreationView.Model {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: store.state.newEventDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: store.state.newEventTime)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        let startDateTime = calendar.date(from: combinedComponents) ?? Date()
        
        return .init(
            isEditing: store.state.editingEventId != nil,
            title: store.state.newEventTitle,
            description: store.state.newEventDescription,
            startDateTime: startDateTime,
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
            onStartDateTimeChanged: { dateTime in
                store.send(.eventDateChanged(dateTime))
                store.send(.eventTimeChanged(dateTime))
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
