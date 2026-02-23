import KyounaniApp
import SwiftUI

@main
struct KyounaniPlaygroundsApp: App {
    var body: some Scene {
        WindowGroup {
            PlaygroundsRootView()
        }
    }
}

private struct PlaygroundsRootView: View {
    @StateObject private var appVM = AppViewModel()
    @StateObject private var speechService = SpeechService()
    @StateObject private var stampStore = StampStore()
    @StateObject private var repository: InMemoryEventRepository
    @StateObject private var calendarVM: CalendarViewModel
    @State private var showingGate = false
    @State private var showingParentMode = false

    init() {
        let holidayService = JapaneseHolidayService.bundled()
        let repository = InMemoryEventRepository(events: Self.seedEvents(), exceptions: Self.seedExceptions())
        let engine = RecurrenceEngine(holidayService: holidayService)
        _repository = StateObject(wrappedValue: repository)
        _calendarVM = StateObject(wrappedValue: CalendarViewModel(repository: repository, engine: engine, holidayService: holidayService))
    }

    var body: some View {
        NavigationStack {
            TodayHomeView(calendarVM: calendarVM, speechService: speechService, repository: repository)
                .navigationTitle("きょうなに")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(appVM.parentModeUnlocked ? "親モード" : "解除") {
                            if appVM.parentModeUnlocked {
                                showingParentMode = true
                            } else {
                                showingGate = true
                            }
                        }
                    }
                }
        }
        .environmentObject(appVM)
        .environmentObject(stampStore)
        .sheet(isPresented: $showingGate) {
            ParentalGateView()
                .environmentObject(appVM)
        }
        .sheet(isPresented: $showingParentMode) {
            ParentModeView(repo: repository)
                .environmentObject(appVM)
                .environmentObject(stampStore)
        }
    }


    private static let sampleRecurringEventId = UUID(uuidString: "99999999-9999-9999-9999-999999999999")!

    private static func seedExceptions() -> [EventException] {
        let cal = Calendar(identifier: .gregorian)
        let ruleStart = startOfCurrentWeek()
        let targetWeekday = 2 // Monday

        guard let firstMonday = nextWeekday(targetWeekday, from: ruleStart),
              let secondMonday = cal.date(byAdding: .day, value: 7, to: firstMonday),
              let thirdMonday = cal.date(byAdding: .day, value: 14, to: firstMonday) else {
            return []
        }

        let weeklyBase = Event(
            id: sampleRecurringEventId,
            title: "スイミング",
            stampId: UUID(uuidString: "66666666-6666-6666-6666-666666666666") ?? Stamp.defaultStampId,
            childScope: .both,
            visibility: .published,
            isAllDay: false,
            startDateTime: dateAt(hour: 16, minute: 0, on: firstMonday),
            durationMinutes: 50,
            recurrenceRule: WeeklyRecurrenceRule(startDate: ruleStart, endDate: nil, weekdays: [targetWeekday], skipHolidays: false)
        )

        var oneDayOverride = weeklyBase
        oneDayOverride.id = UUID()
        oneDayOverride.recurrenceRule = nil
        oneDayOverride.title = "スイミング（この日だけ時間変更）"
        oneDayOverride.startDateTime = dateAt(hour: 17, minute: 0, on: secondMonday)
        oneDayOverride.durationMinutes = 40

        var fromThisDate = weeklyBase
        fromThisDate.id = UUID()
        fromThisDate.title = "スイミング（以降はコーチ変更）"
        fromThisDate.startDateTime = dateAt(hour: 18, minute: 0, on: thirdMonday)
        fromThisDate.durationMinutes = 60
        if var rule = fromThisDate.recurrenceRule {
            rule.startDate = thirdMonday
            fromThisDate.recurrenceRule = rule
        }

        return [
            EventException(
                eventId: weeklyBase.id,
                occurrenceDate: secondMonday,
                kind: .override,
                overrideEvent: oneDayOverride,
                splitRule: nil
            ),
            EventException(
                eventId: weeklyBase.id,
                occurrenceDate: thirdMonday,
                kind: .splitFromThisDate,
                overrideEvent: fromThisDate,
                splitRule: fromThisDate.recurrenceRule
            )
        ]
    }

    private static func startOfCurrentWeek() -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 1
        let now = Date()
        let weekday = cal.component(.weekday, from: now)
        let offset = weekday - cal.firstWeekday
        return cal.startOfDay(for: cal.date(byAdding: .day, value: -offset, to: now) ?? now)
    }

    private static func nextWeekday(_ weekday: Int, from date: Date) -> Date? {
        let cal = Calendar(identifier: .gregorian)
        for offset in 0..<14 {
            guard let candidate = cal.date(byAdding: .day, value: offset, to: date) else { continue }
            if cal.component(.weekday, from: candidate) == weekday {
                return cal.startOfDay(for: candidate)
            }
        }
        return nil
    }

    private static func dateAt(hour: Int, minute: Int, on date: Date) -> Date {
        let cal = Calendar(identifier: .gregorian)
        return cal.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
    }

    private static func seedEvents() -> [Event] {
        let now = Date()
        return [
            Event(
                title: "ようちえん",
                stampId: Stamp.defaultStampId,
                childScope: .both,
                visibility: .published,
                isAllDay: false,
                startDateTime: now.addingTimeInterval(40 * 60),
                durationMinutes: 180,
                recurrenceRule: nil
            ),
            Event(
                id: sampleRecurringEventId,
                title: "スイミング",
                stampId: UUID(uuidString: "66666666-6666-6666-6666-666666666666") ?? Stamp.defaultStampId,
                childScope: .both,
                visibility: .published,
                isAllDay: false,
                startDateTime: dateAt(hour: 16, minute: 0, on: nextWeekday(2, from: startOfCurrentWeek()) ?? now),
                durationMinutes: 50,
                recurrenceRule: WeeklyRecurrenceRule(
                    startDate: startOfCurrentWeek(),
                    endDate: nil,
                    weekdays: [2],
                    skipHolidays: false
                )
            ),
            Event(
                title: "おやつ",
                stampId: UUID(uuidString: "55555555-5555-5555-5555-555555555555") ?? Stamp.defaultStampId,
                childScope: .son,
                visibility: .published,
                isAllDay: false,
                startDateTime: now.addingTimeInterval(2 * 3600),
                durationMinutes: 20,
                recurrenceRule: nil
            ),
            Event(
                title: "したがき: ほごしゃだけ",
                stampId: UUID(uuidString: "88888888-8888-8888-8888-888888888888") ?? Stamp.defaultStampId,
                childScope: .daughter,
                visibility: .draft,
                isAllDay: false,
                startDateTime: now.addingTimeInterval(90 * 60),
                durationMinutes: 30,
                recurrenceRule: nil
            )
        ]
    }
}
