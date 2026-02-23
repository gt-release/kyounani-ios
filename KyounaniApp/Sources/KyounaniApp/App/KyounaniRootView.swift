#if canImport(SwiftUI)
import SwiftUI

public struct KyounaniRootView: View {
    @StateObject private var appVM = AppViewModel()
    @StateObject private var speech = SpeechService()
    @StateObject private var repository: InMemoryEventRepository
    @StateObject private var calendarVM: CalendarViewModel

    public init() {
        let holiday = JapaneseHolidayService.bundled()
        let sharedRepository = InMemoryEventRepository()
        let engine = RecurrenceEngine(holidayService: holiday)
        _repository = StateObject(wrappedValue: sharedRepository)
        _calendarVM = StateObject(wrappedValue: CalendarViewModel(repository: sharedRepository, engine: engine, holidayService: holiday))
    }

    public var body: some View {
        TabView {
            NavigationStack {
                TodayHomeView(calendarVM: calendarVM, speechService: speech, repository: repository)
            }
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
