//
//  CalendarServiceImpl.swift
//  InterPrep
//
//  Calendar service implementation using gRPC
//

import CalendarFeature
import Foundation
import NetworkService

public final actor CalendarServiceImpl: CalendarServicing {
    private let networkService: NetworkServiceV2
    
    public init(networkService: NetworkServiceV2 = .shared) {
        self.networkService = networkService
    }
    
    public func createEvent(
        title: String,
        description: String,
        startTime: Date,
        endTime: Date,
        eventType: CalendarEventType
    ) async throws -> CalendarEvent {
        try await createEvent(
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            eventType: eventType,
            location: nil,
            reminderEnabled: false,
            reminderMinutes: 15
        )
    }
    
    // swiftlint:disable:next function_parameter_count
    public func createEvent(
        title: String,
        description: String,
        startTime: Date,
        endTime: Date,
        eventType: CalendarEventType,
        location: String?,
        reminderEnabled: Bool,
        reminderMinutes: Int32
    ) async throws -> CalendarEvent {
        let result = await networkService.createEvent(
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            eventType: mapToProtoEventType(eventType),
            location: location,
            reminderEnabled: reminderEnabled,
            reminderMinutes: reminderMinutes
        )
        
        switch result {
        case .success(let response):
            return mapFromProtoEvent(response.event)
        case .failure(let error):
            throw error
        }
    }
    
    public func listEvents(fromTime: Date, toTime: Date) async throws -> [CalendarEvent] {
        let result = await networkService.listEvents(
            fromTime: fromTime,
            toTime: toTime,
            pageSize: 100,
            pageToken: nil,
            sort: .sortStartAsc
        )
        
        switch result {
        case .success(let response):
            return response.events.map { mapFromProtoEvent($0) }
        case .failure(let error):
            throw error
        }
    }
    
    public func listUpcoming(limit: Int32) async throws -> [CalendarEvent] {
        let result = await networkService.listUpcoming(
            limit: limit,
            fromTime: Date()
        )
        
        switch result {
        case .success(let response):
            return response.events.map { mapFromProtoEvent($0) }
        case .failure(let error):
            throw error
        }
    }
    
    public func updateEvent(
        id: String,
        title: String?,
        description: String?,
        startTime: Date?,
        endTime: Date?
    ) async throws -> CalendarEvent {
        try await updateEvent(
            id: id,
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            eventType: nil,
            location: nil,
            reminderEnabled: nil,
            reminderMinutes: nil,
            completed: nil
        )
    }
    
    // swiftlint:disable:next function_parameter_count
    public func updateEvent(
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
    ) async throws -> CalendarEvent {
        let result = await networkService.updateEvent(
            id: id,
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            eventType: eventType.map { mapToProtoEventType($0) },
            location: location,
            reminderEnabled: reminderEnabled,
            reminderMinutes: reminderMinutes,
            completed: completed
        )
        
        switch result {
        case .success(let response):
            return mapFromProtoEvent(response.event)
        case .failure(let error):
            throw error
        }
    }
    
    public func deleteEvent(id: String) async throws -> Bool {
        let result = await networkService.deleteEvent(id: id)
        
        switch result {
        case .success(let response):
            return response.success
        case .failure(let error):
            throw error
        }
    }
    
    private func mapFromProtoEvent(_ proto: Calendar_Event) -> CalendarEvent {
        CalendarEvent(
            id: proto.id,
            title: proto.title,
            description: proto.hasDescription_p ? proto.description_p : "",
            eventType: mapFromProtoEventType(proto.eventType),
            startTime: Date(timeIntervalSince1970: TimeInterval(proto.startTime.seconds)),
            endTime: Date(timeIntervalSince1970: TimeInterval(proto.endTime.seconds)),
            timezone: proto.hasTimezone ? proto.timezone : nil,
            location: proto.hasLocation ? proto.location : nil,
            relatedVacancyId: proto.hasRelatedVacancyID ? proto.relatedVacancyID : nil,
            reminderEnabled: proto.reminderEnabled,
            reminderMinutes: proto.reminderMinutes,
            completed: proto.completed,
            createdAt: Date(timeIntervalSince1970: TimeInterval(proto.createdAt.seconds)),
            updatedAt: Date(timeIntervalSince1970: TimeInterval(proto.updatedAt.seconds))
        )
    }
    
    private func mapFromProtoEventType(_ proto: Calendar_EventType) -> CalendarEventType {
        switch proto {
        case .unspecified: return .unspecified
        case .interview: return .interview
        case .call: return .call
        case .meeting: return .meeting
        case .testTask: return .testTask
        case .prep: return .prep
        case .deadline: return .deadline
        case .other: return .other
        case .UNRECOGNIZED: return .unspecified
        }
    }
    
    private func mapToProtoEventType(_ type: CalendarEventType) -> Calendar_EventType {
        switch type {
        case .unspecified: return .unspecified
        case .interview: return .interview
        case .call: return .call
        case .meeting: return .meeting
        case .testTask: return .testTask
        case .prep: return .prep
        case .deadline: return .deadline
        case .other: return .other
        }
    }
}
