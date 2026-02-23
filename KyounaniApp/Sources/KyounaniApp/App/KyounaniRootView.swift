#if canImport(SwiftUI)
import SwiftUI

public struct KyounaniRootView: View {
    @StateObject private var appVM = AppViewModel()
    @StateObject private var speech = SpeechService()
    @StateObject private var repository = InMemoryEventRepository()
    @StateObject private var calendarVM: CalendarViewModel

    public init() {
        let holiday = JapaneseHolidayService.bundled()
        let repository = InMemoryEventRepository()
        let engine = RecurrenceEngine(holidayService: holiday)
        _calendarVM = StateObject(wrappedValue: CalendarViewModel(repository: repository, engine: engine))
    }

    public var body: some View {
        TabView {
            TodayHomeView(calendarVM: calendarVM, speechService: speech)
                .tabItem { Label("Today", systemImage: "sun.max.fill") }

            if appVM.parentModeUnlocked {
                ParentModeView(repo: repository)
                    .tabItem { Label("親", systemImage: "person.crop.circle.badge.checkmark") }
            } else {
                ParentalGateView()
                    .tabItem { Label("解除", systemImage: "lock.fill") }
            }
        }
        .environmentObject(appVM)
    }
}

#endif
