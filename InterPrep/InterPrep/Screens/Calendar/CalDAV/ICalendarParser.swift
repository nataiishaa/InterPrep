//
//  ICalendarParser.swift
//  InterPrep
//
//  iCalendar (.ics) format parser and generator
//

import Foundation

/// iCalendar format parser (RFC 5545)
struct ICalendarParser {
    
    static func parse(_ icsData: String) throws -> CalDAVEvent {
        let lines = icsData.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var uid: String?
        var summary: String?
        var description: String?
        var startDate: Date?
        var endDate: Date?
        var location: String?
        
        for line in lines {
            if line.hasPrefix("UID:") {
                uid = String(line.dropFirst(4))
            } else if line.hasPrefix("SUMMARY:") {
                summary = String(line.dropFirst(8))
            } else if line.hasPrefix("DESCRIPTION:") {
                description = String(line.dropFirst(12))
            } else if line.hasPrefix("DTSTART") {
                startDate = parseDateProperty(line)
            } else if line.hasPrefix("DTEND") {
                endDate = parseDateProperty(line)
            } else if line.hasPrefix("LOCATION:") {
                location = String(line.dropFirst(9))
            }
        }
        
        guard let uid = uid,
              let summary = summary,
              let startDate = startDate else {
            throw CalDAVError.parseError
        }
        
        return CalDAVEvent(
            uid: uid,
            summary: summary,
            description: description,
            startDate: startDate,
            endDate: endDate,
            location: location
        )
    }
    
    private static func parseDateProperty(_ line: String) -> Date? {
        // Extract date value after colon
        guard let colonIndex = line.firstIndex(of: ":") else {
            return nil
        }
        
        let dateString = String(line[line.index(after: colonIndex)...])
        
        // Try different date formats
        let formatters = [
            createFormatter("yyyyMMdd'T'HHmmss'Z'"), // UTC
            createFormatter("yyyyMMdd'T'HHmmss"),     // Local
            createFormatter("yyyyMMdd")                // Date only
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    private static func createFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
}

/// iCalendar format generator
struct ICalendarGenerator {
    
    static func generate(_ event: CalDAVEvent) -> String {
        let dateFormatter = createUTCFormatter()
        let startString = dateFormatter.string(from: event.startDate)
        let endString = event.endDate.map { dateFormatter.string(from: $0) } ?? startString
        
        var lines = [
            "BEGIN:VCALENDAR",
            "VERSION:2.0",
            "PRODID:-//InterPrep//Calendar//EN",
            "BEGIN:VEVENT",
            "UID:\(event.uid)",
            "DTSTAMP:\(dateFormatter.string(from: Date()))",
            "DTSTART:\(startString)",
            "DTEND:\(endString)",
            "SUMMARY:\(escapeText(event.summary))"
        ]
        
        if let description = event.description {
            lines.append("DESCRIPTION:\(escapeText(description))")
        }
        
        if let location = event.location {
            lines.append("LOCATION:\(escapeText(location))")
        }
        
        lines.append(contentsOf: [
            "END:VEVENT",
            "END:VCALENDAR"
        ])
        
        return lines.joined(separator: "\r\n")
    }
    
    private static func createUTCFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
    
    private static func escapeText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}

// MARK: - Conversion Extensions

extension CalDAVEvent {
    /// Create from local CalendarEvent (factory to avoid init-in-extension compile issues)
    static func from(calendarEvent event: CalendarState.CalendarEvent) -> CalDAVEvent {
        CalDAVEvent(
            uid: event.id,
            summary: event.title,
            description: event.description.isEmpty ? nil : event.description,
            startDate: event.date,
            endDate: event.endDate ?? Calendar.current.date(byAdding: .hour, value: 1, to: event.date),
            location: nil,
            etag: nil
        )
    }
    
    /// Convert to local CalendarEvent
    func toCalendarEvent() -> CalendarState.CalendarEvent {
        CalendarState.CalendarEvent(
            id: uid,
            title: summary,
            description: description ?? "",
            date: startDate,
            endDate: endDate ?? startDate.addingTimeInterval(3600),
            type: .interview, // Default type
            reminderEnabled: false,
            reminderMinutesBefore: 30,
            isCompleted: false
        )
    }
}
