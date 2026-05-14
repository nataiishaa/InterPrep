@testable import CalendarFeature
import XCTest

final class ICalendarParserTests: XCTestCase {

    func testParse_validFullEvent_parsesAllFields() throws {
        let icsData = """
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VEVENT
        UID:event-123
        SUMMARY:Собеседование в Яндекс
        DESCRIPTION:Техническое интервью
        DTSTART:20240115T100000Z
        DTEND:20240115T110000Z
        LOCATION:Покровский бульвар 11
        END:VEVENT
        END:VCALENDAR
        """

        let event = try ICalendarParser.parse(icsData)

        XCTAssertEqual(event.uid, "event-123")
        XCTAssertEqual(event.summary, "Собеседование в Яндекс")
        XCTAssertEqual(event.description, "Техническое интервью")
        XCTAssertEqual(event.location, "Покровский бульвар 11")
        XCTAssertNotNil(event.startDate)
        XCTAssertNotNil(event.endDate)
    }

    func testParse_minimalEvent_parsesRequiredFields() throws {
        let icsData = """
        UID:event-456
        SUMMARY:Созвон с HR
        DTSTART:20240120T150000Z
        """

        let event = try ICalendarParser.parse(icsData)

        XCTAssertEqual(event.uid, "event-456")
        XCTAssertEqual(event.summary, "Созвон с HR")
        XCTAssertNotNil(event.startDate)
        XCTAssertNil(event.description)
        XCTAssertNil(event.location)
    }

    func testParse_missingUID_throws() {
        let icsData = """
        SUMMARY:Встреча
        DTSTART:20240115T100000Z
        """
        XCTAssertThrowsError(try ICalendarParser.parse(icsData))
    }

    func testParse_missingSummary_throws() {
        let icsData = """
        UID:event-789
        DTSTART:20240115T100000Z
        """
        XCTAssertThrowsError(try ICalendarParser.parse(icsData))
    }

    func testParse_missingStartDate_throws() {
        let icsData = """
        UID:event-789
        SUMMARY:Встреча
        """
        XCTAssertThrowsError(try ICalendarParser.parse(icsData))
    }

    func testParse_dateFormatWithZ_parsesCorrectly() throws {
        let icsData = """
        UID:event-date
        SUMMARY:Событие
        DTSTART:20240315T143000Z
        """

        let event = try ICalendarParser.parse(icsData)
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: event.startDate)

        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 15)
        XCTAssertEqual(components.hour, 14)
        XCTAssertEqual(components.minute, 30)
    }

    func testParse_dateOnlyFormat_parsesCorrectly() throws {
        let icsData = """
        UID:event-allday
        SUMMARY:Конференция
        DTSTART:20240401
        """

        let event = try ICalendarParser.parse(icsData)
        XCTAssertNotNil(event.startDate)
    }

    func testParse_handlesWhitespace_correctly() throws {
        let icsData = """

          UID:event-spaces
          SUMMARY:  Встреча с командой
          DTSTART:20240115T100000Z

        """

        let event = try ICalendarParser.parse(icsData)
        XCTAssertEqual(event.uid, "event-spaces")
    }

    func testGenerate_fullEvent_includesAllFields() {
        let event = CalDAVEvent(
            uid: "gen-123",
            summary: "Собеседование",
            description: "Техническое интервью",
            startDate: Date(timeIntervalSince1970: 1705312800),
            endDate: Date(timeIntervalSince1970: 1705316400),
            location: "Покровский бульвар 11"
        )

        let icsString = ICalendarGenerator.generate(event)

        XCTAssertTrue(icsString.contains("BEGIN:VCALENDAR"))
        XCTAssertTrue(icsString.contains("END:VCALENDAR"))
        XCTAssertTrue(icsString.contains("BEGIN:VEVENT"))
        XCTAssertTrue(icsString.contains("END:VEVENT"))
        XCTAssertTrue(icsString.contains("UID:gen-123"))
        XCTAssertTrue(icsString.contains("SUMMARY:Собеседование"))
        XCTAssertTrue(icsString.contains("DESCRIPTION:Техническое интервью"))
        XCTAssertTrue(icsString.contains("LOCATION:Покровский бульвар 11"))
        XCTAssertTrue(icsString.contains("DTSTART:"))
        XCTAssertTrue(icsString.contains("DTEND:"))
    }

    func testGenerate_minimalEvent_omitsOptionalFields() {
        let event = CalDAVEvent(
            uid: "gen-minimal",
            summary: "Созвон",
            description: nil,
            startDate: Date(),
            endDate: nil,
            location: nil
        )

        let icsString = ICalendarGenerator.generate(event)

        XCTAssertTrue(icsString.contains("UID:gen-minimal"))
        XCTAssertTrue(icsString.contains("SUMMARY:Созвон"))
        XCTAssertFalse(icsString.contains("DESCRIPTION:"))
        XCTAssertFalse(icsString.contains("LOCATION:"))
    }

    func testGenerate_escapesSpecialCharacters() {
        let event = CalDAVEvent(
            uid: "gen-escape",
            summary: "Встреча, обсуждение; планы",
            description: "Строка1\nСтрока2",
            startDate: Date(),
            endDate: nil,
            location: nil
        )

        let icsString = ICalendarGenerator.generate(event)

        XCTAssertTrue(icsString.contains("SUMMARY:Встреча\\, обсуждение\\; планы"))
        XCTAssertTrue(icsString.contains("DESCRIPTION:Строка1\\nСтрока2"))
    }

    func testGenerate_usesCorrectLineEndings() {
        let event = CalDAVEvent(
            uid: "gen-lines",
            summary: "Тест",
            description: nil,
            startDate: Date(),
            endDate: nil,
            location: nil
        )

        let icsString = ICalendarGenerator.generate(event)
        XCTAssertTrue(icsString.contains("\r\n"))
    }

    func testRoundTrip_parseGenerate_preservesData() throws {
        let originalEvent = CalDAVEvent(
            uid: "roundtrip-123",
            summary: "Важная встреча",
            description: "Обсуждение проекта",
            startDate: Date(timeIntervalSince1970: 1705312800),
            endDate: Date(timeIntervalSince1970: 1705316400),
            location: "Покровский бульвар 11"
        )

        let generated = ICalendarGenerator.generate(originalEvent)
        let parsed = try ICalendarParser.parse(generated)

        XCTAssertEqual(parsed.uid, originalEvent.uid)
        XCTAssertEqual(parsed.summary, originalEvent.summary)
        XCTAssertEqual(parsed.description, originalEvent.description)
        XCTAssertEqual(parsed.location, originalEvent.location)
    }
}
