#if canImport(SwiftUI)
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

private struct SelfTestResult: Identifiable {
    enum Status {
        case pass
        case fail
    }

    let id = UUID()
    let title: String
    let status: Status
    let message: String
}

public struct DiagnosticsView: View {
    @ObservedObject var repo: EventRepositoryBase

    @State private var results: [SelfTestResult] = []
    @State private var ranSelfTest = false
    @State private var breadcrumbs: [BreadcrumbEntry] = []
    @State private var fileLogText = ""

    public init(repo: EventRepositoryBase) {
        self.repo = repo
    }

    public var body: some View {
        List {
            if hasFailedSelfTest {
                Section {
                    Text("セルフテストで失敗が見つかりました。設定とデータを確認してください。")
                        .font(.footnote)
                        .foregroundStyle(.white)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .listRowBackground(Color.clear)
            }

            Section("Crash Marker") {
                row(title: "前回異常終了", value: DiagnosticsCenter.hadUncleanExitLastLaunch ? "疑いあり" : "なし")
                row(title: "セーフモード", value: DiagnosticsCenter.isSafeModeEnabled ? "ON" : "OFF")
            }

            Section("Repository") {
                row(title: "有効なRepository", value: repo.repositoryKind.rawValue)
                row(title: "lastError", value: repo.lastErrorMessage ?? "異常なし")
            }

            Section("Breadcrumb（直近50件）") {
                if breadcrumbs.isEmpty {
                    Text("ログなし")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(breadcrumbs) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.event).font(.subheadline.weight(.semibold))
                            Text(entry.detail).font(.caption)
                            Text(entry.timestamp.formatted(date: .numeric, time: .standard)).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }

                Button("Breadcrumbをコピー") {
                    copyText(DiagnosticsCenter.breadcrumbsText(limit: 50))
                }
            }

            Section("ファイルログ（kyounani.log）") {
                if fileLogText.isEmpty {
                    Text("ログファイルは空です")
                        .foregroundStyle(.secondary)
                } else {
                    Text(fileLogText)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                        .lineLimit(12)
                }

                Button("ファイルログを再読込") {
                    refreshLogs()
                }
                Button("ファイルログをコピー") {
                    copyText(fileLogText)
                }
            }

            Section("バックアップ仕様") {
                row(title: "formatVersion", value: "2")
                row(title: "kdf", value: "PBKDF2-HMAC-SHA256")
                row(title: "cipher", value: "AES-GCM")
            }

            Section("セルフテスト") {
                Button("セルフテストを実行") {
                    runSelfTest()
                }

                if ranSelfTest {
                    ForEach(results) { result in
                        HStack(alignment: .top, spacing: 8) {
                            Text(result.status == .pass ? "✅" : "❌")
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(result.message)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Diagnostics")
        .onAppear {
            refreshLogs()
            DiagnosticsCenter.breadcrumb(event: "openedDiagnostics")
            if let lastError = repo.lastErrorMessage {
                DiagnosticsCenter.breadcrumb(event: "lastError", detail: lastError)
            }
        }
    }

    private func refreshLogs() {
        breadcrumbs = DiagnosticsCenter.recentBreadcrumbs(limit: 50)
        fileLogText = DiagnosticsCenter.readLogFile()
    }

    private var hasFailedSelfTest: Bool {
        results.contains(where: { $0.status == .fail })
    }

    private func copyText(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
    }

    private func row(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func runSelfTest() {
        var next: [SelfTestResult] = []

        let holidayService = JapaneseHolidayService.bundled()
        let holidayCount = holidaySampleCount(from: holidayService)
        if holidayCount > 0 {
            next.append(SelfTestResult(title: "祝日CSV読込", status: .pass, message: "\(holidayCount)件の祝日を確認"))
        } else {
            next.append(SelfTestResult(title: "祝日CSV読込", status: .fail, message: "祝日が0件でした"))
        }

        let recurrenceResult = recurrenceSelfTest(holidayService: holidayService)
        next.append(recurrenceResult)

        let backupResult = backupRoundTripSelfTest()
        next.append(backupResult)

        results = next
        ranSelfTest = true
    }

    private func holidaySampleCount(from holidayService: JapaneseHolidayService) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        return (1...365).reduce(into: 0) { count, offset in
            let target = calendar.date(byAdding: .day, value: offset, to: Date()) ?? Date()
            if holidayService.isHoliday(target) {
                count += 1
            }
        }
    }

    private func recurrenceSelfTest(holidayService: JapaneseHolidayService) -> SelfTestResult {
        let calendar = Calendar(identifier: .gregorian)
        let engine = RecurrenceEngine(holidayService: holidayService)
        let today = calendar.startOfDay(for: Date())
        let weekdays = Set([calendar.component(.weekday, from: today)])
        let event = Event(
            title: "セルフテスト",
            stampId: UUID(),
            childScope: .both,
            visibility: .published,
            isAllDay: false,
            startDateTime: calendar.date(byAdding: .hour, value: 9, to: today) ?? today,
            durationMinutes: 30,
            recurrenceRule: WeeklyRecurrenceRule(
                startDate: today,
                endDate: calendar.date(byAdding: .day, value: 35, to: today),
                weekdays: weekdays,
                skipHolidays: false
            )
        )

        let range = DateInterval(start: today, end: calendar.date(byAdding: .day, value: 35, to: today) ?? today)
        let occurrences = engine.occurrences(for: [event], exceptions: [], in: range, childFilter: .both, includeDraft: false)

        if occurrences.count >= 3 {
            return SelfTestResult(title: "RecurrenceEngine", status: .pass, message: "次回\(min(3, occurrences.count))件を生成")
        }

        return SelfTestResult(title: "RecurrenceEngine", status: .fail, message: "生成件数が不足: \(occurrences.count)件")
    }

    private func backupRoundTripSelfTest() -> SelfTestResult {
        do {
            let payload = BackupPayload(
                stamps: [],
                events: repo.fetchEvents(),
                exceptions: repo.fetchExceptions()
            )
            let encrypted = try BackupCryptoService.exportEncryptedData(payload: payload, passphrase: "123456")
            let restored = try BackupCryptoService.decryptPayload(from: encrypted, passphrase: "123456")
            if restored.events.count == payload.events.count,
               restored.exceptions.count == payload.exceptions.count {
                return SelfTestResult(title: "バックアップround-trip", status: .pass, message: "メモリ上で復号・復元を確認")
            }
            return SelfTestResult(title: "バックアップround-trip", status: .fail, message: "件数不一致")
        } catch {
            return SelfTestResult(title: "バックアップround-trip", status: .fail, message: error.localizedDescription)
        }
    }
}

#endif
