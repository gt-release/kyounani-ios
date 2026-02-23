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
        let repository = InMemoryEventRepository(events: Self.seedEvents(), exceptions: [])
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
