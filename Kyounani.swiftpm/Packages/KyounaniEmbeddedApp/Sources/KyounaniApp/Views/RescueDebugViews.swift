#if canImport(SwiftUI)
import SwiftUI

public struct ParentModeSafeShellView: View {
    @EnvironmentObject private var appVM: AppViewModel
    @StateObject private var safeRepo: InMemoryEventRepository
    @StateObject private var safeStampStore: StampStore

    public init() {
        let repo = InMemoryEventRepository()
        _safeRepo = StateObject(wrappedValue: repo)
        _safeStampStore = StateObject(wrappedValue: StampStore(repository: repo))
    }

    public var body: some View {
        ParentModeView(repo: safeRepo, hideBackupControls: true, hideDiagnosticsEntry: true)
            .environmentObject(safeStampStore)
            .onAppear {
                appVM.safeModeEnabled = true
                DiagnosticsCenter.breadcrumb(event: "openedParentModeSafeShell")
            }
    }
}

public struct RescueDebugRouterView: View {
    let level: RescueDebugLevel
    let repo: EventRepositoryBase
    let onOpenParentMode: () -> Void
    let onOpenSafeParentMode: () -> Void
    let onResetAllData: () -> Void
    let onBackToChildMode: () -> Void

    public init(level: RescueDebugLevel, repo: EventRepositoryBase, onOpenParentMode: @escaping () -> Void, onOpenSafeParentMode: @escaping () -> Void, onResetAllData: @escaping () -> Void, onBackToChildMode: @escaping () -> Void) {
        self.level = level
        self.repo = repo
        self.onOpenParentMode = onOpenParentMode
        self.onOpenSafeParentMode = onOpenSafeParentMode
        self.onResetAllData = onResetAllData
        self.onBackToChildMode = onBackToChildMode
    }

    public var body: some View {
        switch level {
        case .l0:
            RescueL0View(onBackToChildMode: onBackToChildMode)
        case .l1:
            RescueL1View(onBackToChildMode: onBackToChildMode)
        case .l2:
            RescueL2View(onBackToChildMode: onBackToChildMode)
        case .l3:
            RescueL3View(onBackToChildMode: onBackToChildMode)
        case .l4:
            RescueL4View(onOpenSafeParentMode: onOpenSafeParentMode, onBackToChildMode: onBackToChildMode)
        case .l5:
            RescueGateView(repo: repo, onOpenParentMode: onOpenParentMode, onResetAllData: onResetAllData, onBackToChildMode: onBackToChildMode)
        }
    }
}

public struct RescueL0View: View {
    let onBackToChildMode: () -> Void

    public var body: some View {
        VStack(spacing: 16) {
            Text("RESCUE L0")
                .font(.title.bold())
            Button("子どもモードに戻る") {
                onBackToChildMode()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

public struct RescueL1View: View {
    let onBackToChildMode: () -> Void
    private let safeModeEnabled = UserDefaults.standard.bool(forKey: "kyounani.safeModeEnabled")

    public var body: some View {
        VStack(spacing: 12) {
            Text("RESCUE L1")
                .font(.title.bold())
            Text("safeModeEnabled=\(safeModeEnabled ? "true" : "false")")
                .font(.footnote.monospaced())
            Button("子どもモードに戻る", action: onBackToChildMode)
        }
        .padding(24)
    }
}

public struct RescueL2View: View {
    let onBackToChildMode: () -> Void
    private let safeModeEnabled = UserDefaults.standard.bool(forKey: "kyounani.safeModeEnabled")
    private let lastBreadcrumb = DiagnosticsCenter.breadcrumbsText(limit: 1)

    public var body: some View {
        VStack(spacing: 12) {
            Text("RESCUE L2").font(.title.bold())
            Text("safeModeEnabled=\(safeModeEnabled ? "true" : "false")")
                .font(.footnote.monospaced())
            Text(lastBreadcrumb.isEmpty ? "breadcrumb=none" : lastBreadcrumb)
                .font(.caption.monospaced())
                .lineLimit(3)
            Button("子どもモードに戻る", action: onBackToChildMode)
        }
        .padding(24)
    }
}

public struct RescueL3View: View {
    let onBackToChildMode: () -> Void
    @State private var safeModeEnabled = UserDefaults.standard.bool(forKey: "kyounani.safeModeEnabled")

    public var body: some View {
        VStack(spacing: 12) {
            Text("RESCUE L3").font(.title.bold())
            Text("safeModeEnabled=\(safeModeEnabled ? "true" : "false")")
                .font(.footnote.monospaced())
            Button("セーフモードON") {
                DiagnosticsCenter.setSafeModeEnabled(true)
                safeModeEnabled = true
            }
            Button("セーフモードOFF") {
                DiagnosticsCenter.setSafeModeEnabled(false)
                safeModeEnabled = false
            }
            Button("子どもモードに戻る", action: onBackToChildMode)
        }
        .padding(24)
    }
}

public struct RescueL4View: View {
    let onOpenSafeParentMode: () -> Void
    let onBackToChildMode: () -> Void
    @State private var safeModeEnabled = UserDefaults.standard.bool(forKey: "kyounani.safeModeEnabled")

    public var body: some View {
        VStack(spacing: 12) {
            Text("RESCUE L4").font(.title.bold())
            Text("safeModeEnabled=\(safeModeEnabled ? "true" : "false")")
                .font(.footnote.monospaced())
            Button("セーフモードON") {
                DiagnosticsCenter.setSafeModeEnabled(true)
                safeModeEnabled = true
            }
            Button("セーフモードOFF") {
                DiagnosticsCenter.setSafeModeEnabled(false)
                safeModeEnabled = false
            }
            Button("親画面へ進む（Safe Shell）") {
                DiagnosticsCenter.setSafeModeEnabled(true)
                onOpenSafeParentMode()
            }
            .buttonStyle(.borderedProminent)
            Button("子どもモードに戻る", action: onBackToChildMode)
        }
        .padding(24)
    }
}

public struct RescueL5View: View {
    let onOpenParentMode: () -> Void
    let onOpenSafeParentMode: () -> Void
    let onResetAllData: () -> Void
    let onBackToChildMode: () -> Void
    @State private var safeModeEnabled = UserDefaults.standard.bool(forKey: "kyounani.safeModeEnabled")
    @State private var showResetConfirm = false

    public var body: some View {
        NavigationStack {
            List {
                Section("RESCUE L5") {
                    Text("safeModeEnabled=\(safeModeEnabled ? "true" : "false")")
                        .font(.footnote.monospaced())
                    Text(DiagnosticsCenter.breadcrumbsText(limit: 1).isEmpty ? "breadcrumb=none" : DiagnosticsCenter.breadcrumbsText(limit: 1))
                        .font(.caption.monospaced())
                }

                Section("操作") {
                    Button("通常モードで親画面を開く") {
                        DiagnosticsCenter.setSafeModeEnabled(false)
                        onOpenParentMode()
                    }
                    Button("セーフモードONで親画面を開く") {
                        DiagnosticsCenter.setSafeModeEnabled(true)
                        onOpenSafeParentMode()
                    }
                    Button("セーフモードをOFFにする") {
                        DiagnosticsCenter.setSafeModeEnabled(false)
                        safeModeEnabled = false
                    }
                    Button("データを全削除", role: .destructive) {
                        showResetConfirm = true
                    }
                    Button("ログをコピー") {
                        #if canImport(UIKit)
                        UIPasteboard.general.string = DiagnosticsCenter.breadcrumbsText(limit: 20)
                        #endif
                    }
                    Button("子どもモードに戻る") {
                        onBackToChildMode()
                    }
                }
            }
            .navigationTitle("Rescue L5")
            .confirmationDialog("本当にデータを全削除しますか？", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("全削除する", role: .destructive) {
                    onResetAllData()
                }
                Button("キャンセル", role: .cancel) {}
            }
        }
    }
}

#endif
