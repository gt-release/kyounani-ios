#if canImport(SwiftUI)
import SwiftUI

private enum RecurrenceEditTarget {
    case singleOccurrence
    case fromThisDate
    case wholeSeries
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

private struct EventEditSheetView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var repository: InMemoryEventRepository

    let context: EventEditorContext

    @State private var title: String
    @State private var startDateTime: Date
    @State private var durationMinutes: Int
    @State private var isDeleteForSingle = false

    init(context: EventEditorContext, repository: InMemoryEventRepository) {
        self.context = context
        self.repository = repository
        _title = State(initialValue: context.occurrence.baseEvent.title)
        _startDateTime = State(initialValue: context.occurrence.displayStart)
        _durationMinutes = State(initialValue: max(5, context.occurrence.baseEvent.durationMinutes ?? 30))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("編集") {
                    TextField("タイトル", text: $title)
                    DatePicker("開始", selection: $startDateTime)
                    Stepper(value: $durationMinutes, in: 5...24*60, step: 5) {
                        Text("時間: \(durationMinutes)分")
                    }
                }

                if context.target == .singleOccurrence {
                    Section("この日だけ") {
                        Toggle("この日の予定を削除する", isOn: $isDeleteForSingle)
                    }
                }
            }
            .navigationTitle(modeTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                        dismiss()
                    }
                }
            }
        }
    }

    private var modeTitle: String {
        switch context.target {
        case .singleOccurrence: return "この日だけ編集"
        case .fromThisDate: return "以降を編集"
        case .wholeSeries: return "全体を編集"
        }
    }

    private func save() {
        let base = context.occurrence.baseEvent
        let now = Date()

        switch context.target {
        case .wholeSeries:
            var updated = base
            updated.title = title
            updated.startDateTime = startDateTime
            updated.durationMinutes = durationMinutes
            updated.updatedAt = now

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

            var overrideEvent = base
            overrideEvent.id = UUID()
            overrideEvent.recurrenceRule = nil
            overrideEvent.title = title
            overrideEvent.startDateTime = startDateTime
            overrideEvent.durationMinutes = durationMinutes
            overrideEvent.updatedAt = now

            let exception = EventException(
                eventId: base.id,
                occurrenceDate: context.occurrence.occurrenceDate,
                kind: .override,
                overrideEvent: overrideEvent,
                splitRule: nil
            )
            repository.save(exception: exception)

        case .fromThisDate:
            var splitEvent = base
            splitEvent.id = UUID()
            splitEvent.title = title
            splitEvent.startDateTime = startDateTime
            splitEvent.durationMinutes = durationMinutes
            splitEvent.updatedAt = now
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
    @ObservedObject var repository: InMemoryEventRepository

    let date: Date
    @State private var selectedOccurrence: EventOccurrence?
    @State private var editingOccurrence: EventOccurrence?
    @State private var editorContext: EventEditorContext?
    @State private var showingRecurrenceEditTargetDialog = false

    public init(date: Date, calendarVM: CalendarViewModel, speechService: SpeechService, repository: InMemoryEventRepository) {
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
            Button("この日だけ") {
                if let editingOccurrence {
                    editorContext = EventEditorContext(occurrence: editingOccurrence, target: .singleOccurrence)
                }
            }
            Button("以降すべて") {
                if let editingOccurrence {
                    editorContext = EventEditorContext(occurrence: editingOccurrence, target: .fromThisDate)
                }
            }
            Button("全体") {
                if let editingOccurrence {
                    editorContext = EventEditorContext(occurrence: editingOccurrence, target: .wholeSeries)
                }
            }
            Button("キャンセル", role: .cancel) {}
        }
        .sheet(item: $selectedOccurrence) { occ in
            TimerRingView(targetDate: occ.displayStart)
                .padding()
        }
        .sheet(item: $editorContext) { context in
            EventEditSheetView(context: context, repository: repository)
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
