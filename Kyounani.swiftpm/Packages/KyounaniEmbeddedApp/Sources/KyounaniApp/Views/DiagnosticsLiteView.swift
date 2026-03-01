#if canImport(SwiftUI)
import SwiftUI

public struct DiagnosticsLiteView: View {
    @ObservedObject var repo: EventRepositoryBase

    public init(repo: EventRepositoryBase) {
        self.repo = repo
    }

    public var body: some View {
        List {
            Section("Lite") {
                row("前回異常終了", DiagnosticsCenter.hadUncleanExitLastLaunch ? "疑いあり" : "なし")
                row("セーフモード", DiagnosticsCenter.isSafeModeEnabled ? "ON" : "OFF")
                row("repoType(記録)", DiagnosticsCenter.lastRepoTypeLabel ?? "不明")
                row("lastError", DiagnosticsCenter.lastErrorMessage ?? repo.lastErrorMessage ?? "なし")
            }

            Section("Breadcrumb") {
                ForEach(DiagnosticsCenter.recentBreadcrumbs(limit: 20)) { entry in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.event).font(.subheadline.weight(.semibold))
                        Text(entry.detail).font(.caption)
                    }
                }
            }

            Section {
                NavigationLink("Diagnostics Full") {
                    DiagnosticsFullView(repo: repo)
                }
            }
        }
        .navigationTitle("Diagnostics Lite")
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }
}

#endif
