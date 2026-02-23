import XCTest
@testable import KyounaniApp

final class JapaneseHolidayServiceTests: XCTestCase {
    func testParsesHolidayCSV() {
        let csv = """
        国民の祝日・休日月日,国民の祝日・休日名称
        2024/05/05,こどもの日
        """
        let service = JapaneseHolidayService(csvText: csv)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")

        let date = formatter.date(from: "2024/05/05")!
        XCTAssertEqual(service.holidayName(on: date), "こどもの日")
        XCTAssertTrue(service.isHoliday(date))
    }
}
