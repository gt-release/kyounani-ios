#if canImport(SwiftUI)
import SwiftUI

private enum RecurrenceEditTarget {
    case singleOccurrence
    case fromThisDate
    case wholeSeries

    var scopeSummary: EventEditorView.EditScopeSummary {
        switch self {
        case .singleOccurrence:
            return .init(title: "この日だけ", description: "今日（この1回）だけ変更します。")
        case .fromThisDate:
            return .init(title: "以降すべて", description: "今日以降の予定をまとめて変更します。")
        case .wholeSeries:
            return .init(title: "全体", description: "シリーズ全体（開始〜終了）を変更します。")
        }
    }
}

private struct EventEditorContext: Identifiable {
    var id: String { occurrence.id + "-\(targetTag)" }

    let occurrence: EventOccurrence
    let target: RecurrenceEditTarget

    private var targetTag: String {
        switch target {
        case .singleOccurrence: return "single"
        case .fromThisDate: return "from"
        case .wholeSeries: return "whole"
        }
    }
}

private struct EventImpactPreview {
    let previewDates: [Date]
    let countEstimate: Int?
}

private struct EventEditSheetView: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var stampStore: StampStore

    @ObservedObject var repository: EventRepositoryBase

    let context: EventEditorContext
    let onReselectScope: () -> Void

    @State private var isDeleteForSingle = false
    @State private var showDeleteConfirmation = false

    private let recurrenceEngine = RecurrenceEngine(holidayService: JapaneseHolidayService.bundled())

    init(context: EventEditorContext, repository: EventRepositoryBase, onReselectScope: @escaping () -> Void) {
        self.context = context
        self.repository = repository
        self.onReselectScope = onReselectScope
    }

    var body: some View {
        VStack {
            if context.target == .singleOccurrence {
                Toggle("この日の予定を削除する", isOn: $isDeleteForSingle)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            EventEditorView(
                mode: .edit,
                initialEvent: editingSeedEvent(),
                shouldDismissAfterSave: false,
                editScopeSummary: context.target.scopeSummary,
                impactPreviewDates: impactPreview.previewDates,
                impactCountEstimate: impactPreview.countEstimate,
                onSave: { updated in
                    attemptSave(with: updated)
                },
                onReselectScope: {
                    dismiss()
                    onReselectScope()
                }
            )
            .environmentObject(stampStore)
        }
        .alert("この日だけ削除しますか？", isPresented: $showDeleteConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("削除する", role: .destructive) {
                save(with: editingSeedEvent())
                dismiss()
            }
        } message: {
            Text("この操作で選択した日の予定1件だけを削除します。")
        }
    }

    private var impactPreview: EventImpactPreview {
        let base = context.occurrence.baseEvent
        let now = context.occurrence.occurrenceDate
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.startOfDay(for: now)

        let rangeStart: Date
        switch context.target {
        case .singleOccurrence, .fromThisDate:
            rangeStart = start
        case .wholeSeries:
            rangeStart = calendar.startOfDay(for: base.recurrenceRule?.startDate ?? base.startDateTime)
        }

        let rangeEnd = calendar.date(byAdding: .day, value: 90, to: rangeStart) ?? rangeStart
        let range = DateInterval(start: rangeStart, end: rangeEnd)

        var events = repository.fetchEvents()
        if !events.contains(where: { $0.id == base.id }) {
            events.append(base)
        }

        let all = recurrenceEngine
            .occurrences(
                for: events,
                exceptions: repository.fetchExceptions(),
                in: range,
                childFilter: .both,
                includeDraft: true
            )
            .filter { occurrence in
                occurrence.baseEvent.id == base.id || occurrence.baseEvent.id == context.occurrence.baseEvent.id
            }
            .map(\.occurrenceDate)
            .sorted()

        let limited = Array(all.prefix(50))
        return EventImpactPreview(previewDates: Array(limited.prefix(3)), countEstimate: limited.isEmpty ? 0 : limited.count)
    }

    private func editingSeedEvent() -> Event {
        var seed = context.occurrence.baseEvent
        seed.startDateTime = context.occurrence.displayStart
        return seed
    }

    private func attemptSave(with updated: Event) {
        if context.target == .singleOccurrence, isDeleteForSingle {
            showDeleteConfirmation = true
            return
        }

        save(with: updated)
        dismiss()
    }

    private func save(with updated: Event) {
        let base = context.occurrence.baseEvent

        switch context.target {
        case .wholeSeries:
            // baseEvent が repository.events に存在しない場合は、
            // 例外（override/split）の payload を更新して重複生成を防ぐ。
            if repository.fetchEvents().contains(where: { $0.id == base.id }) {
                repository.save(event: updated)
            } else if var sourceException = repository.fetchExceptions().first(where: { $0.overrideEvent?.id == base.id }) {
                sourceException.overrideEvent = updated
                repository.save(exception: sourceException)
            } else {
                repository.save(event: updated)
            }

        case .singleOccurrence:
            if isDeleteForSingle {
                let exception = EventException(
                    eventId: base.id,
                    occurrenceDate: context.occurrence.occurrenceDate,
                    kind: .delete,
                    overrideEvent: nil,
                    splitRule: nil
                )
                repository.save(exception: exception)
                return
            }

            var overrideEvent = updated
            overrideEvent.id = UUID()
            overrideEvent.recurrenceRule = nil

            let exception = EventException(
                eventId: base.id,
                occurrenceDate: context.occurrence.occurrenceDate,
                kind: .override,
                overrideEvent: overrideEvent,
                splitRule: nil
            )
            repository.save(exception: exception)

        case .fromThisDate:
            var splitEvent = updated
            splitEvent.id = UUID()
            if var rule = splitEvent.recurrenceRule {
                rule.startDate = context.occurrence.occurrenceDate
                splitEvent.recurrenceRule = rule
            }

            let exception = EventException(
                eventId: base.id,
                occurrenceDate: context.occurrence.occurrenceDate,
                kind: .splitFromThisDate,
                overrideEvent: splitEvent,
                splitRule: splitEvent.recurrenceRule
            )
            repository.save(exception: exception)
        }
    }
}

public struct DayDetailView: View {
    @EnvironmentObject private var appVM: AppViewModel
    @ObservedObject var calendarVM: CalendarViewModel
    @ObservedObject var speechService: SpeechService
    @ObservedObject var repository: EventRepositoryBase

    let date: Date
    @State private var selectedOccurrence: EventOccurrence?
    @State private var editingOccurrence: EventOccurrence?
    @State private var editorContext: EventEditorContext?
    @State private var showingRecurrenceEditTargetDialog = false

    public init(date: Date, calendarVM: CalendarViewModel, speechService: SpeechService, repository: EventRepositoryBase) {
        self.date = date
        self.calendarVM = calendarVM
        self.speechService = speechService
        self.repository = repository
    }

    public var body: some View {
        let occurrences = calendarVM.dayOccurrences(on: date, childFilter: appVM.filter, includeDraft: appVM.parentModeUnlocked)

        Group {
            if occurrences.isEmpty {
                Text("この日の予定はありません")
                    .foregroundStyle(.secondary)
            } else {
                List(occurrences, id: \.id) { occurrence in
                    HStack(spacing: 12) {
                        Button {
                            speechService.speak(occurrence.baseEvent.title)
                            selectedOccurrence = occurrence
                        } label: {
                            HStack(spacing: 12) {
                                EventTokenRenderer(event: occurrence.baseEvent, showTitle: false, iconSize: 42)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(occurrence.baseEvent.title)
                                        .font(.headline)
                                    Text(timeText(occurrence.displayStart, allDay: occurrence.baseEvent.isAllDay))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        if appVM.parentModeUnlocked {
                            Button("編集") {
                                startEdit(occurrence)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
        }
        .navigationTitle(titleText)
        .confirmationDialog("どこまで編集しますか？", isPresented: $showingRecurrenceEditTargetDialog, titleVisibility: .visible) {
            Button("この日だけ\n今日（この1回）だけ変える") {
                if let editingOccurrence {
                    editorContext = EventEditorContext(occurrence: editingOccurrence, target: .singleOccurrence)
                }
            }
            Button("以降すべて\n今日以降の予定をまとめて変える") {
                if let editingOccurrence {
                    editorContext = EventEditorContext(occurrence: editingOccurrence, target: .fromThisDate)
                }
            }
            Button("全体\nシリーズ全体（開始〜終了）を変える") {
                if let editingOccurrence {
                    editorContext = EventEditorContext(occurrence: editingOccurrence, target: .wholeSeries)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("編集・削除の影響範囲を選んでください。")
        }
        .sheet(item: $selectedOccurrence) { occ in
            TimerRingView(targetDate: occ.displayStart)
                .padding()
        }
        .sheet(item: $editorContext) { context in
            EventEditSheetView(context: context, repository: repository) {
                editingOccurrence = context.occurrence
                showingRecurrenceEditTargetDialog = true
            }
        }
    }

    private func startEdit(_ occurrence: EventOccurrence) {
        if occurrence.baseEvent.recurrenceRule != nil {
            editingOccurrence = occurrence
            showingRecurrenceEditTargetDialog = true
            return
        }
        editorContext = EventEditorContext(occurrence: occurrence, target: .wholeSeries)
    }

    private var titleText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d(E)"
        return formatter.string(from: date)
    }

    private func timeText(_ date: Date, allDay: Bool) -> String {
        if allDay { return "終日" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#endif
