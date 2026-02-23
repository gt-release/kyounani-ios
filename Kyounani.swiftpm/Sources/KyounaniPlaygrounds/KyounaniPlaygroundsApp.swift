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
    @StateObject private var repository: EventRepositoryBase
    @StateObject private var calendarVM: CalendarViewModel
    @StateObject private var stampStore: StampStore
    @State private var showingGate = false
    @State private var showingParentMode = false

    init() {
        let holidayService = JapaneseHolidayService.bundled()
        let repository = RepositoryFactory.makeDefaultRepository()
        let engine = RecurrenceEngine(holidayService: holidayService)
        _repository = StateObject(wrappedValue: repository)
        _calendarVM = StateObject(wrappedValue: CalendarViewModel(repository: repository, engine: engine, holidayService: holidayService))
        _stampStore = StateObject(wrappedValue: StampStore(repository: repository))
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
        .onReceive(repository.objectWillChange) { _ in
            stampStore.reload()
        }
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
}
