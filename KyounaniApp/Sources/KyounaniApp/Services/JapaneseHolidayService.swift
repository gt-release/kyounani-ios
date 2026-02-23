import Foundation

public protocol HolidayService {
    func holidayName(on date: Date) -> String?
    func isHoliday(_ date: Date) -> Bool
}

public final class JapaneseHolidayService: HolidayService {
    private let holidaysByDay: [String: String]
    private let calendar: Calendar
    private let formatter: DateFormatter

    public init(csvText: String, calendar: Calendar = Calendar(identifier: .gregorian)) {
        var jpCalendar = calendar
        jpCalendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        self.calendar = jpCalendar
        self.formatter = DateFormatter()
        formatter.calendar = jpCalendar
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = jpCalendar.timeZone
        formatter.dateFormat = "yyyy/MM/dd"
        self.holidaysByDay = JapaneseHolidayService.parse(csvText: csvText)
    }

    public static func bundled() -> JapaneseHolidayService {
        let bundle = Bundle.module
        let url = bundle.url(forResource: "syukujitsu_sample", withExtension: "csv")
        let csv = (try? url.flatMap { try String(contentsOf: $0) }) ?? ""
        return JapaneseHolidayService(csvText: csv)
    }

    public func holidayName(on date: Date) -> String? {
        holidaysByDay[formatter.string(from: date)]
    }

    public func isHoliday(_ date: Date) -> Bool {
        holidayName(on: date) != nil
    }

    private static func parse(csvText: String) -> [String: String] {
        csvText
            .split(separator: "\n")
            .dropFirst()
            .reduce(into: [String: String]()) { partialResult, line in
                let cols = line.split(separator: ",", maxSplits: 1).map(String.init)
                guard cols.count == 2 else { return }
                partialResult[cols[0].trimmingCharacters(in: .whitespaces)] = cols[1].trimmingCharacters(in: .whitespaces)
            }
    }
}
