#if canImport(SwiftUI)
import SwiftUI

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

            Section("Repository") {
                row(title: "有効なRepository", value: repo.repositoryKind.rawValue)
                row(title: "lastError", value: repo.lastErrorMessage ?? "異常なし")
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
    }

    private var hasFailedSelfTest: Bool {
        results.contains(where: { $0.status == .fail })
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
            let encrypted = try BackupCryptoService.exportEncryptedData(payload: payload, passphrase: "self-test")
            let decrypted = try BackupCryptoService.decryptPayload(from: encrypted, passphrase: "self-test")

            let source = BackupCryptoService.summarize(payload: payload)
            let restored = BackupCryptoService.summarize(payload: decrypted)

            if source.stampCount == restored.stampCount,
               source.eventCount == restored.eventCount,
               source.exceptionCount == restored.exceptionCount {
                return SelfTestResult(title: "バックアップ round-trip", status: .pass, message: "件数一致（stamp:\(restored.stampCount), event:\(restored.eventCount), exception:\(restored.exceptionCount)）")
            }

            return SelfTestResult(title: "バックアップ round-trip", status: .fail, message: "件数不一致")
        } catch {
            return SelfTestResult(title: "バックアップ round-trip", status: .fail, message: error.localizedDescription)
        }
    }
}

#endif
