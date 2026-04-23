//
//  CalendarServicing.swift
//  InterPrep
//
//  Calendar service protocol (events CRUD and listing)
//

import Foundation

public protocol CalendarServicing: Actor {
    func createEvent(
        title: String,
        description: String,
        startTime: Date,
        endTime: Date,
        eventType: CalendarEventType
    ) async throws -> CalendarEvent
    
    // swiftlint:disable:next function_parameter_count
    func createEvent(
        title: String,
        description: String,
        startTime: Date,
        endTime: Date,
        eventType: CalendarEventType,
        location: String?,
        reminderEnabled: Bool,
        reminderMinutes: Int32
    ) async throws -> CalendarEvent
    
    func listEvents(fromTime: Date, toTime: Date) async throws -> [CalendarEvent]
    func listUpcoming(limit: Int32) async throws -> [CalendarEvent]
    
    func updateEvent(
        id: String,
        title: String?,
        description: String?,
        startTime: Date?,
        endTime: Date?
    ) async throws -> CalendarEvent
    
    // swiftlint:disable:next function_parameter_count
    func updateEvent(
        id: String,
        title: String?,
        description: String?,
        startTime: Date?,
        endTime: Date?,
        eventType: CalendarEventType?,
        location: String?,
        reminderEnabled: Bool?,
        reminderMinutes: Int32?,
        completed: Bool?
    ) async throws -> CalendarEvent
    
    func deleteEvent(id: String) async throws -> Bool
}
