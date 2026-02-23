import XCTest
@testable import KyounaniApp

private struct MockHoliday: HolidayService {
    let holidayDates: Set<String>
    private let formatter: DateFormatter

    init(holidayDates: Set<String>) {
        self.holidayDates = holidayDates
        formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
    }

    func holidayName(on date: Date) -> String? {
        holidayDates.contains(formatter.string(from: date)) ? "holiday" : nil
    }

    func isHoliday(_ date: Date) -> Bool {
        holidayName(on: date) != nil
    }
}

final class RecurrenceEngineTests: XCTestCase {
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy/MM/dd HH:mm"
        f.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return f
    }()

    func testWeeklyGeneration() {
        let engine = RecurrenceEngine(holidayService: MockHoliday(holidayDates: []))
        let base = makeEvent(start: "2024/04/01 10:00", weekdays: [2])
        let result = engine.occurrences(
            for: [base],
            exceptions: [],
            in: DateInterval(start: date("2024/04/01 00:00"), end: date("2024/04/15 00:00")),
            childFilter: .both,
            includeDraft: true
        )
        XCTAssertEqual(result.count, 2)
    }

    func testSkipHoliday() {
        let engine = RecurrenceEngine(holidayService: MockHoliday(holidayDates: ["2024/04/08"]))
        let base = makeEvent(start: "2024/04/01 10:00", weekdays: [2], skipHolidays: true)
        let result = engine.occurrences(
            for: [base],
            exceptions: [],
            in: DateInterval(start: date("2024/04/01 00:00"), end: date("2024/04/15 00:00")),
            childFilter: .both,
            includeDraft: true
        )
        XCTAssertEqual(result.count, 1)
    }

    func testOverrideAndDelete() {
        let engine = RecurrenceEngine(holidayService: MockHoliday(holidayDates: []))
        let base = makeEvent(start: "2024/04/01 10:00", weekdays: [2])
        var overrideEvent = base
        overrideEvent.title = "病院"
        overrideEvent.startDateTime = date("2024/04/08 14:00")

        let exceptions = [
            EventException(eventId: base.id, occurrenceDate: date("2024/04/08 00:00"), kind: .override, overrideEvent: overrideEvent, splitRule: nil),
            EventException(eventId: base.id, occurrenceDate: date("2024/04/01 00:00"), kind: .delete, overrideEvent: nil, splitRule: nil)
        ]
        let result = engine.occurrences(
            for: [base],
            exceptions: exceptions,
            in: DateInterval(start: date("2024/04/01 00:00"), end: date("2024/04/15 00:00")),
            childFilter: .both,
            includeDraft: true
        )
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.baseEvent.title, "病院")
    }

    func testModifyFromThisDate() {
        let engine = RecurrenceEngine(holidayService: MockHoliday(holidayDates: []))
        let base = makeEvent(start: "2024/04/01 10:00", weekdays: [2])
        let changed = makeEvent(start: "2024/04/08 16:00", weekdays: [4])

        let exceptions = [
            EventException(eventId: base.id, occurrenceDate: date("2024/04/08 00:00"), kind: .splitFromThisDate, overrideEvent: changed, splitRule: changed.recurrenceRule)
        ]

        let result = engine.occurrences(
            for: [base],
            exceptions: exceptions,
            in: DateInterval(start: date("2024/04/01 00:00"), end: date("2024/04/20 00:00")),
            childFilter: .both,
            includeDraft: true
        )

        XCTAssertTrue(result.contains(where: { formatter.string(from: $0.displayStart) == "2024/04/01 10:00" }))
        XCTAssertTrue(result.contains(where: { formatter.string(from: $0.displayStart) == "2024/04/10 16:00" }))
        XCTAssertFalse(result.contains(where: { formatter.string(from: $0.displayStart) == "2024/04/08 10:00" }))
    }

    private func makeEvent(start: String, weekdays: Set<Int>, skipHolidays: Bool = false) -> Event {
        Event(
            title: "幼稚園",
            stampId: UUID(),
            childScope: .both,
            visibility: .published,
            isAllDay: false,
            startDateTime: date(start),
            durationMinutes: 60,
            recurrenceRule: WeeklyRecurrenceRule(
                startDate: date("2024/04/01 00:00"),
                endDate: date("2024/04/30 00:00"),
                weekdays: weekdays,
                skipHolidays: skipHolidays
            )
        )
    }

    private func date(_ value: String) -> Date {
        formatter.date(from: value)!
    }
}
