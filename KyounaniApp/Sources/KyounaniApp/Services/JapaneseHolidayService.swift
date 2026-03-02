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
        let candidateBundles = ResourceBundleLocator.candidateBundles()
        let candidateNames = ["syukujitsu", "syukujitsu_sample"]

        for bundle in candidateBundles {
            for name in candidateNames {
                guard let url = bundle.url(forResource: name, withExtension: "csv"),
                      let csv = try? String(contentsOf: url) else {
                    continue
                }
                return JapaneseHolidayService(csvText: csv)
            }
        }

        return JapaneseHolidayService(csvText: "")
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
                let dateKey = normalizedDateKey(cols[0].trimmingCharacters(in: .whitespaces))
                guard !dateKey.isEmpty else { return }
                partialResult[dateKey] = cols[1].trimmingCharacters(in: .whitespaces)
            }
    }

    private static func normalizedDateKey(_ raw: String) -> String {
        let parts = raw.split(separator: "/")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            return raw
        }
        return String(format: "%04d/%02d/%02d", year, month, day)
    }
}
