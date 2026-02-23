#if canImport(SwiftUI)
import SwiftUI

public struct KyounaniRootView: View {
    @StateObject private var appVM = AppViewModel()
    @StateObject private var speech = SpeechService()
    @StateObject private var repository: EventRepositoryBase
    @StateObject private var calendarVM: CalendarViewModel
    @StateObject private var stampStore: StampStore
    @State private var showingGate = false
    @State private var showingParentMode = false

    public init() {
        let holiday = JapaneseHolidayService.bundled()
        let sharedRepository = RepositoryFactory.makeDefaultRepository()
        let engine = RecurrenceEngine(holidayService: holiday)
        _repository = StateObject(wrappedValue: sharedRepository)
        _calendarVM = StateObject(wrappedValue: CalendarViewModel(repository: sharedRepository, engine: engine, holidayService: holiday))
        _stampStore = StateObject(wrappedValue: StampStore(repository: sharedRepository))
    }

    public var body: some View {
        TabView {
            NavigationStack {
                ZStack(alignment: .topTrailing) {
                    TodayHomeView(calendarVM: calendarVM, speechService: speech, repository: repository)
                    if appVM.parentModeUnlocked {
                        Button("親モード") {
                            showingParentMode = true
                        }
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.trailing, 12)
                        .padding(.top, 8)
                    } else {
                        ParentalGateTriggerArea {
                            showingGate = true
                        }
                        .frame(width: 56, height: 56)
                        .contentShape(Rectangle())
                        .padding(.trailing, 8)
                        .padding(.top, 4)
                    }
                }
            }
            .tabItem { Label("Today", systemImage: "sun.max.fill") }
        }
        .environmentObject(appVM)
        .environmentObject(stampStore)
        .onReceive(repository.objectWillChange) { _ in
            stampStore.reload()
        }
        .sheet(isPresented: $showingGate) {
            ParentalGateView()
        }
        .sheet(isPresented: $showingParentMode) {
            ParentModeView(repo: repository)
        }
    }
}

#endif
