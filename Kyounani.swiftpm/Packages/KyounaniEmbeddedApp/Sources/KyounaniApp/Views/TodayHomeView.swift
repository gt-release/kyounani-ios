#if canImport(SwiftUI)
import SwiftUI

public struct TodayHomeView: View {
    @EnvironmentObject private var appVM: AppViewModel
    @Environment(\.kyounaniTheme) private var theme
    @ObservedObject var calendarVM: CalendarViewModel
    @ObservedObject var speechService: SpeechService
    @ObservedObject var repository: EventRepositoryBase
    @State private var selectedOccurrence: EventOccurrence?

    public init(calendarVM: CalendarViewModel, speechService: SpeechService, repository: EventRepositoryBase) {
        self.calendarVM = calendarVM
        self.speechService = speechService
        self.repository = repository
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.sectionGap) {
                childFilter
                todaySection
                nextSection
                tomorrowSection
            }
            .padding(theme.spacing.screenPadding)
        }
        .navigationTitle("Today")
        .onAppear { reload() }
        .onChange(of: appVM.filter) { reload() }
        .onChange(of: appVM.parentModeUnlocked) { reload() }
        .onReceive(repository.objectWillChange) { _ in reload() }
        .sheet(item: $selectedOccurrence) { occ in
            TimerRingView(targetDate: occ.displayStart)
                .padding()
        }
    }

    private var childFilter: some View {
        Picker("対象", selection: $appVM.filter) {
            Text("息子").tag(ChildScope.son)
            Text("娘").tag(ChildScope.daughter)
            Text("両方").tag(ChildScope.both)
        }
        .pickerStyle(.segmented)
        .padding(.vertical, 2)
    }

    private var todaySection: some View {
        let summary = EventListPresenter.summarizeDay(calendarVM.todayOccurrences)

        return VStack(alignment: .leading, spacing: theme.spacing.itemGap) {
            sectionHeader("きょう")

            if summary.topOccurrences.isEmpty {
                emptyCard(icon: "sun.max", message: "きょうのよていは ないよ")
            } else {
                HStack(spacing: theme.spacing.itemGap) {
                    ForEach(summary.topOccurrences, id: \.id) { occ in
                        EventTokenRenderer(event: occ.baseEvent, showTitle: false, iconSize: theme.stampLarge, occurrenceDate: occ.occurrenceDate)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .cardStyle(background: theme.colors.todayCard)
                    }

                    if summary.remainingCount > 0 {
                        Text("+\(summary.remainingCount)")
                            .font(theme.fonts.plusCount)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                            .cardStyle(background: theme.colors.todayCard)
                    }
                }
            }
        }
    }

    private var nextSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.itemGap) {
            sectionHeader("つぎ")

            if let next = calendarVM.todayOccurrences.first(where: { $0.displayStart >= .now }) {
                Button {
                    speechService.speak(next.baseEvent.title)
                    selectedOccurrence = next
                } label: {
                    HStack(spacing: theme.spacing.itemGap) {
                        EventTokenRenderer(event: next.baseEvent, showTitle: false, iconSize: theme.stampNext, occurrenceDate: next.occurrenceDate)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(next.baseEvent.title)
                                .font(theme.fonts.cardTitle)
                                .foregroundStyle(theme.colors.primaryText)
                            Text("\(timeText(next.displayStart)) ・ \(timeRemainingText(next.displayStart))")
                                .font(theme.fonts.supporting)
                                .foregroundStyle(theme.colors.secondaryText)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(theme.spacing.cardPadding)
                    .cardStyle(background: theme.colors.nextCard)
                }
                .buttonStyle(.plain)
                .minTapTarget()
            } else {
                emptyCard(icon: "moon.stars.fill", message: "きょうは おしまい")
            }
        }
    }

    private var tomorrowSection: some View {
        let hasTomorrow = !calendarVM.weekPeekOccurrences.isEmpty
        return VStack(alignment: .leading, spacing: theme.spacing.itemGap) {
            sectionHeader("あした")

            if hasTomorrow {
                HStack(spacing: theme.spacing.itemGap) {
                    ForEach(calendarVM.weekPeekOccurrences.prefix(2), id: \.id) { occ in
                        EventTokenRenderer(event: occ.baseEvent, showTitle: false, iconSize: theme.stampLarge, occurrenceDate: occ.occurrenceDate)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .cardStyle(background: theme.colors.peekCard)
                    }
                }
            } else {
                emptyCard(icon: "calendar", message: "あしたの よていは まだないよ")
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(theme.fonts.sectionHeader)
            .foregroundStyle(theme.colors.primaryText)
            .padding(.bottom, 2)
    }

    private func emptyCard(icon: String, message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .semibold))
            Text(message)
                .font(theme.fonts.cardTitle)
        }
        .foregroundStyle(theme.colors.primaryText)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing.cardPadding)
        .cardStyle(background: theme.colors.emptyCard)
        .minTapTarget()
    }

    private func reload() {
        calendarVM.refresh(childFilter: appVM.filter, includeDraft: appVM.parentModeUnlocked)
    }

    private func timeRemainingText(_ date: Date) -> String {
        let min = max(0, Int(date.timeIntervalSinceNow / 60))
        return "あと\(min)分"
    }

    private func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#endif
