//
//  CalendarView+Model.swift
//  InterPrep
//
//  Calendar view model
//

import Foundation

extension CalendarView {
    struct Model {
        let selectedDate: Date
        let currentMonth: Date
        let events: [CalendarState.CalendarEvent]
        let isCreatingEvent: Bool
        let onDateSelected: (Date) -> Void
        let onMonthChanged: (Date) -> Void
        let onCreateEventTapped: () -> Void
        let onCancelEventCreation: () -> Void
        let onDeleteEvent: (String) -> Void
        let onEditEvent: (CalendarState.CalendarEvent) -> Void
        let onSyncCompleted: ([CalendarState.CalendarEvent]) -> Void
        let eventCreationModel: EventCreationView.Model
    }
}
