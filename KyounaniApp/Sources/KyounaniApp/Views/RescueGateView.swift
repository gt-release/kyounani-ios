#if canImport(SwiftUI)
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

public struct RescueGateView: View {
    @EnvironmentObject private var appVM: AppViewModel
    @ObservedObject private var repo: EventRepositoryBase

    private let onOpenParentMode: () -> Void
    private let onResetAllData: () -> Void
    private let onBackToChildMode: () -> Void

    @State private var showResetConfirm = false

    public init(repo: EventRepositoryBase, onOpenParentMode: @escaping () -> Void, onResetAllData: @escaping () -> Void, onBackToChildMode: @escaping () -> Void) {
        self.repo = repo
        self.onOpenParentMode = onOpenParentMode
        self.onResetAllData = onResetAllData
        self.onBackToChildMode = onBackToChildMode
    }

    public var body: some View {
        NavigationStack {
            List {
                Section("Rescue Diagnostics (Crash-safe)") {
                    row("前回クラッシュ", DiagnosticsCenter.hadUncleanExitLastLaunch ? "疑いあり" : "なし")
                    row("didCleanExit", UserDefaults.standard.bool(forKey: "kyounani.didCleanExit") ? "true" : "false")
                    row("セーフモード", appVM.safeModeEnabled ? "ON" : "OFF")
                    row("lastError", DiagnosticsCenter.lastErrorMessage ?? "なし")
                    row("repoType(前回記録)", DiagnosticsCenter.lastRepoTypeLabel ?? "不明")
                    row("App Version", appVersionText)
                }

                Section("Breadcrumb (直近20)") {
                    let lines = DiagnosticsCenter.recentBreadcrumbs(limit: 20)
                    if lines.isEmpty {
                        Text("ログなし").foregroundStyle(.secondary)
                    } else {
                        ForEach(lines) { entry in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.event).font(.subheadline.weight(.semibold))
                                Text(entry.detail).font(.caption)
                            }
                        }
                    }
                }

                Section("操作") {
                    Button("通常モードで親画面を開く") {
                        DiagnosticsCenter.breadcrumb(event: "openedParentModeView", detail: "fromRescue normal")
                        onOpenParentMode()
                    }

                    Button("セーフモードONで親画面を開く") {
                        appVM.safeModeEnabled = true
                        DiagnosticsCenter.breadcrumb(event: "openedParentModeView", detail: "fromRescue safeModeOn")
                        onOpenParentMode()
                    }

                    Button("セーフモードをOFFにする") {
                        appVM.safeModeEnabled = false
                    }

                    Button("データを全削除", role: .destructive) {
                        showResetConfirm = true
                    }

                    Button("ログをコピー") {
                        copyLogs()
                    }

                    NavigationLink("Diagnostics Full を開く") {
                        DiagnosticsFullView(repo: repo)
                    }

                    Button("子どもモードに戻る") {
                        onBackToChildMode()
                    }
                }
            }
            .navigationTitle("Rescue Gate")
            .onAppear {
                DiagnosticsCenter.breadcrumb(event: "openedRescueGateView")
            }
            .confirmationDialog("本当にデータを全削除しますか？", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("全削除する", role: .destructive) {
                    onResetAllData()
                }
                Button("キャンセル", role: .cancel) {}
            }
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }

    private var appVersionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "\(version) (\(build))"
    }

    private func copyLogs() {
        let text = [
            "didCleanExit=\(UserDefaults.standard.bool(forKey: "kyounani.didCleanExit"))",
            "safeMode=\(appVM.safeModeEnabled)",
            "repoType=\(DiagnosticsCenter.lastRepoTypeLabel ?? "unknown")",
            "lastError=\(DiagnosticsCenter.lastErrorMessage ?? "")",
            DiagnosticsCenter.breadcrumbsText(limit: 20)
        ].joined(separator: "\n")
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
    }
}

#endif
