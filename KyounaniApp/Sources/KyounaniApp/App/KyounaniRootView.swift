#if canImport(SwiftUI)
import SwiftUI

public struct KyounaniRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appVM = AppViewModel()
    @StateObject private var speech = SpeechService()
    @StateObject private var repository: EventRepositoryBase
    @StateObject private var calendarVM: CalendarViewModel
    @StateObject private var stampStore: StampStore
    @State private var showingGate = false
    @State private var showingRescueGate = false
    @State private var showingParentMode = false
    @State private var showingSafeParentMode = false
    @State private var showCrashBanner = false

    public init() {
        let holiday = JapaneseHolidayService.bundled()
        let sharedRepository = RepositoryFactory.makeDefaultRepository()
        let engine = RecurrenceEngine(holidayService: holiday)
        _repository = StateObject(wrappedValue: sharedRepository)
        _calendarVM = StateObject(wrappedValue: CalendarViewModel(repository: sharedRepository, engine: engine, holidayService: holiday))
        _stampStore = StateObject(wrappedValue: StampStore(repository: sharedRepository))
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView {
                NavigationStack {
                    TodayHomeView(calendarVM: calendarVM, speechService: speech, repository: repository, onRequestParentalGate: {
                        showingGate = true
                    })
                }
                .tabItem { Label("Today", systemImage: "sun.max.fill") }

                NavigationStack {
                    CalendarRootView(calendarVM: calendarVM, speechService: speech, repository: repository)
                }
                .tabItem { Label("Calendar", systemImage: "calendar") }
            }

            if showCrashBanner {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text("前回、異常終了の可能性があります")
                            .font(.caption.bold())
                        Spacer()
                        Button("診断") {
                            showingGate = true
                            showCrashBanner = false
                        }
                        .font(.caption.bold())
                    }
                    .padding(10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .zIndex(20)
            }

            if appVM.parentModeUnlocked {
                Button("親モード") {
                    let level = DiagnosticsCenter.rescueDebugLevel
                    DiagnosticsCenter.breadcrumb(event: "openingRescue\(level.rawValue)")
                    showingRescueGate = true
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
                .frame(width: 110, height: 110)
                .padding(10)
                .contentShape(Rectangle())
                .zIndex(10)
                .overlay(alignment: .topTrailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Image(systemName: "hand.tap")
                            .font(.caption.bold())
                        Text("親モード")
                            .font(.caption2.bold())
                        Text("右上を2本指で2秒")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
                .padding(.trailing, 2)
                .padding(.top, 2)
            }
        }
        .environmentObject(appVM)
        .environmentObject(stampStore)
        .environment(\.kyounaniTheme, appVM.theme)
        .tint(appVM.theme.colors.accent)
        .dynamicTypeSize(.medium ... .accessibility5)
        .onAppear {
            showCrashBanner = appVM.hadUncleanExitLastLaunch
        }
        .onReceive(repository.objectWillChange) { _ in
            stampStore.reload()
        }
        .onReceive(repository.$lastErrorMessage) { message in
            if let message {
                DiagnosticsCenter.breadcrumb(event: "lastError", detail: message)
            }
        }
        .onChange(of: appVM.parentModeUnlocked) {
            if appVM.parentModeUnlocked {
                let level = DiagnosticsCenter.rescueDebugLevel
                DiagnosticsCenter.breadcrumb(event: "openingRescue\(level.rawValue)")
                showingRescueGate = true
            } else {
                showingRescueGate = false
                showingParentMode = false
                showingSafeParentMode = false
            }
        }
        .onChange(of: scenePhase) {
            if scenePhase == .background {
                appVM.markCleanExit(reason: "scenePhase.background")
            }
        }
        .sheet(isPresented: $showingGate) {
            ParentalGateView()
                .environmentObject(appVM)
        }
        .sheet(isPresented: $showingRescueGate) {
            RescueDebugRouterView(
                level: DiagnosticsCenter.rescueDebugLevel,
                onOpenParentMode: {
                    showingParentMode = true
                },
                onOpenSafeParentMode: {
                    showingSafeParentMode = true
                },
                onResetAllData: {
                    resetAllData()
                },
                onBackToChildMode: {
                    appVM.lockToChildMode()
                    showingRescueGate = false
                }
            )
            .environmentObject(appVM)
            .environmentObject(stampStore)
        }
        .sheet(isPresented: $showingParentMode) {
            ParentModeView(repo: repository)
                .environmentObject(appVM)
                .environmentObject(stampStore)
        }
        .sheet(isPresented: $showingSafeParentMode) {
            ParentModeSafeShellView()
                .environmentObject(appVM)
        }
    }

    private func resetAllData() {
        repository.replaceAll(events: [], exceptions: [], stamps: [])
        stampStore.removeAllCustomImageFiles()
        stampStore.reseedBuiltinStampsIfNeeded()
        stampStore.reload()
        DiagnosticsCenter.breadcrumb(event: "resetAllData", detail: "fromRescueGate")
    }

}

#endif
