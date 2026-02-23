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
    @StateObject private var repository: InMemoryEventRepository
    @StateObject private var calendarVM: CalendarViewModel
    @State private var showingGate = false
    @State private var showingParentMode = false

    init() {
        let holidayService = JapaneseHolidayService.bundled()
        let repository = InMemoryEventRepository(events: Self.seedEvents(), exceptions: [])
        let engine = RecurrenceEngine(holidayService: holidayService)
        _repository = StateObject(wrappedValue: repository)
        _calendarVM = StateObject(wrappedValue: CalendarViewModel(repository: repository, engine: engine))
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
        .sheet(isPresented: $showingGate) {
            ParentalGateView()
                .environmentObject(appVM)
        }
        .sheet(isPresented: $showingParentMode) {
            ParentModeView(repo: repository)
                .environmentObject(appVM)
        }
    }

    private static func seedEvents() -> [Event] {
        let now = Date()
        return [
            Event(
                title: "ようちえん",
                stampId: UUID(),
                childScope: .both,
                visibility: .published,
                isAllDay: false,
                startDateTime: now.addingTimeInterval(40 * 60),
                durationMinutes: 180,
                recurrenceRule: nil
            ),
            Event(
                title: "おやつ",
                stampId: UUID(),
                childScope: .son,
                visibility: .published,
                isAllDay: false,
                startDateTime: now.addingTimeInterval(2 * 3600),
                durationMinutes: 20,
                recurrenceRule: nil
            ),
            Event(
                title: "したがき: ほごしゃだけ",
                stampId: UUID(),
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
