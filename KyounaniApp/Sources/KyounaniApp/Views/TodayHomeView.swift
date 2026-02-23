#if canImport(SwiftUI)
import SwiftUI

public struct TodayHomeView: View {
    @EnvironmentObject private var appVM: AppViewModel
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
            VStack(alignment: .leading, spacing: KidUITheme.Spacing.sectionGap) {
                childFilter
                todaySection
                nextSection
                tomorrowSection
            }
            .padding(KidUITheme.Spacing.screenPadding)
        }
        .navigationTitle("Today")
        .onAppear { reload() }
        .onChange(of: appVM.filter) { _ in reload() }
        .onChange(of: appVM.parentModeUnlocked) { _ in reload() }
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

        return VStack(alignment: .leading, spacing: KidUITheme.Spacing.itemGap) {
            sectionHeader("きょう")

            if summary.topOccurrences.isEmpty {
                emptyCard(icon: "sun.max", message: "きょうのよていは ないよ")
            } else {
                HStack(spacing: KidUITheme.Spacing.itemGap) {
                    ForEach(summary.topOccurrences, id: \.id) { occ in
                        EventTokenRenderer(event: occ.baseEvent, showTitle: false, iconSize: KidUITheme.Size.largeStamp)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .cardStyle(background: KidUITheme.ColorPalette.todayCard)
                    }

                    if summary.remainingCount > 0 {
                        Text("+\(summary.remainingCount)")
                            .font(KidUITheme.Fonts.plusCount)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                            .cardStyle(background: KidUITheme.ColorPalette.todayCard)
                    }
                }
            }
        }
    }

    private var nextSection: some View {
        VStack(alignment: .leading, spacing: KidUITheme.Spacing.itemGap) {
            sectionHeader("つぎ")

            if let next = calendarVM.todayOccurrences.first(where: { $0.displayStart >= .now }) {
                Button {
                    speechService.speak(next.baseEvent.title)
                    selectedOccurrence = next
                } label: {
                    HStack(spacing: KidUITheme.Spacing.itemGap) {
                        EventTokenRenderer(event: next.baseEvent, showTitle: false, iconSize: KidUITheme.Size.nextCardStamp)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(next.baseEvent.title)
                                .font(KidUITheme.Fonts.cardTitle)
                                .foregroundStyle(.primary)
                            Text("\(timeText(next.displayStart)) ・ \(timeRemainingText(next.displayStart))")
                                .font(KidUITheme.Fonts.supporting)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(KidUITheme.Spacing.cardPadding)
                    .cardStyle(background: KidUITheme.ColorPalette.nextCard)
                }
                .buttonStyle(.plain)
            } else {
                emptyCard(icon: "moon.stars.fill", message: "きょうは おしまい")
            }
        }
    }

    private var tomorrowSection: some View {
        let hasTomorrow = !calendarVM.weekPeekOccurrences.isEmpty
        return VStack(alignment: .leading, spacing: KidUITheme.Spacing.itemGap) {
            sectionHeader("あした")

            if hasTomorrow {
                HStack(spacing: KidUITheme.Spacing.itemGap) {
                    ForEach(calendarVM.weekPeekOccurrences.prefix(2), id: \.id) { occ in
                        EventTokenRenderer(event: occ.baseEvent, showTitle: false, iconSize: KidUITheme.Size.largeStamp)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .cardStyle(background: KidUITheme.ColorPalette.peekCard)
                    }
                }
            } else {
                emptyCard(icon: "calendar", message: "あしたの よていは まだないよ")
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(KidUITheme.Fonts.sectionHeader)
            .padding(.bottom, 2)
    }

    private func emptyCard(icon: String, message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .semibold))
            Text(message)
                .font(KidUITheme.Fonts.cardTitle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(KidUITheme.Spacing.cardPadding)
        .cardStyle(background: KidUITheme.ColorPalette.emptyCard)
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
