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
            ZStack(alignment: .topTrailing) {
                TodayHomeView(calendarVM: calendarVM, speechService: speechService, repository: repository)
                    .navigationTitle("きょうなに")

                gateEntryView
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

    @ViewBuilder
    private var gateEntryView: some View {
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
            .accessibilityLabel("親モード解除ジェスチャー領域")
            .accessibilityHint("右上で3本指で2秒長押しするとペアレンタルゲートが開きます")
        }
    }
}
