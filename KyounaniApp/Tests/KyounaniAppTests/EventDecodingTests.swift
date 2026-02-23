import XCTest
@testable import KyounaniApp

final class EventDecodingTests: XCTestCase {
    func testMissingStampIdFallsBackToDefault() throws {
        let json = """
        {
          "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
          "title": "てすと",
          "childScope": "both",
          "visibility": "published",
          "isAllDay": false,
          "startDateTime": "2026-01-01T00:00:00Z",
          "durationMinutes": 30,
          "createdAt": "2026-01-01T00:00:00Z",
          "updatedAt": "2026-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let event = try decoder.decode(Event.self, from: json)
        XCTAssertEqual(event.stampId, Stamp.defaultStampId)
    }
}
