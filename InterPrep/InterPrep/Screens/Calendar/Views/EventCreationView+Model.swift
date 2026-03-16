//
//  EventCreationView+Model.swift
//  InterPrep
//
//  Event creation view model
//

import Foundation

extension EventCreationView {
    struct Model {
        let isEditing: Bool
        let title: String
        let description: String
        let startDateTime: Date
        let endDate: Date
        let type: CalendarState.EventType
        let reminderEnabled: Bool
        let reminderMinutes: Int
        let errorMessage: String?
        let onTitleChanged: (String) -> Void
        let onDescriptionChanged: (String) -> Void
        let onStartDateTimeChanged: (Date) -> Void
        let onEndDateChanged: (Date) -> Void
        let onTypeChanged: (CalendarState.EventType) -> Void
        let onReminderToggled: (Bool) -> Void
        let onReminderMinutesChanged: (Int) -> Void
        let onSave: () -> Void
        let onCancel: () -> Void
    }
}
