#if canImport(SwiftUI)
import SwiftUI

public struct TodayHomeView: View {
    @EnvironmentObject private var appVM: AppViewModel
    @Environment(\.kyounaniTheme) private var theme
    @ObservedObject var calendarVM: CalendarViewModel
    @ObservedObject var speechService: SpeechService
    @ObservedObject var repository: EventRepositoryBase
    @State private var selectedOccurrence: EventOccurrence?
    @State private var hiddenGateTapCount = 0
    @State private var lastHiddenGateTapAt: Date?
    private let onRequestParentalGate: () -> Void

    public init(calendarVM: CalendarViewModel, speechService: SpeechService, repository: EventRepositoryBase, onRequestParentalGate: @escaping () -> Void = {}) {
        self.calendarVM = calendarVM
        self.speechService = speechService
        self.repository = repository
        self.onRequestParentalGate = onRequestParentalGate
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.sectionGap) {
                headerDate
                childFilter
                todaySection
                nextSection
                tomorrowSection
            }
            .padding(theme.spacing.screenPadding)
        }
        .background(KidSoftBackground())
        .navigationTitle("Today")
        .onAppear { reload() }
        .onChange(of: appVM.filter) { reload() }
        .onChange(of: appVM.parentModeUnlocked) { reload() }
        .onReceive(repository.objectWillChange) { _ in reload() }
        .sheet(item: $selectedOccurrence) { occ in
            TimerRingView(targetDate: occ.displayStart)
                .padding()
                .presentationDetents([.medium])
        }
    }

    private var headerDate: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(todayHeader())
                .font(theme.fonts.heroDate)
                .foregroundStyle(theme.colors.primaryText)
            Text("きょうのよてい")
                .font(theme.fonts.supporting)
                .foregroundStyle(theme.colors.secondaryText)
        }
    }

    private var childFilter: some View {
        HStack(spacing: 12) {
            childFilterButton(scope: .son, symbol: "figure.stand", color: .blue)
            childFilterButton(scope: .daughter, symbol: "figure.stand", color: .pink)
            childFilterButton(scope: .both, symbol: "person.2.fill", color: .purple)
        }
    }

    private func childFilterButton(scope: ChildScope, symbol: String, color: Color) -> some View {
        let isSelected = appVM.filter == scope
        return Button {
            appVM.filter = scope
        } label: {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(color)
                Text(scopeLabel(scope))
                    .font(theme.fonts.supporting)
                    .foregroundStyle(theme.colors.primaryText)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? color.opacity(0.2) : theme.colors.tabBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? color : theme.colors.secondaryText.opacity(0.2), lineWidth: isSelected ? 2.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .minTapTarget()
    }

    private var todaySection: some View {
        let summary = EventListPresenter.summarizeDay(calendarVM.todayOccurrences)
        return KidSectionIsland(title: "きょう", tint: theme.colors.todayCard, onTitleTap: registerFallbackGateTap) {
            if summary.topOccurrences.isEmpty {
                emptyCard(icon: "sun.max.fill", message: "きょうは おやすみ")
            } else {
                HStack(spacing: theme.spacing.itemGap) {
                    ForEach(summary.topOccurrences, id: \.id) { occ in
                        tappableToken(occ, bgColor: theme.colors.todayCard)
                    }
                    if summary.remainingCount > 0 {
                        Text("+\(summary.remainingCount)")
                            .font(theme.fonts.plusCount)
                            .frame(maxWidth: .infinity, minHeight: 136)
                            .cardStyle(background: theme.colors.todayCard)
                    }
                }
            }
        }
    }

    private var nextSection: some View {
        KidSectionIsland(title: "つぎ", tint: theme.colors.nextCard) {
            if let next = calendarVM.todayOccurrences.first(where: { $0.displayStart >= .now }) {
                Button {
                    speechService.speak(next.baseEvent.title)
                    selectedOccurrence = next
                } label: {
                    HStack(spacing: 14) {
                        EventTokenRenderer(event: next.baseEvent, showTitle: false, iconSize: theme.stampNext, occurrenceDate: next.occurrenceDate)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(next.baseEvent.title)
                                .font(theme.fonts.cardTitle)
                            Text("\(timeText(next.displayStart)) ・ \(timeRemainingText(next.displayStart))")
                                .font(theme.fonts.supporting)
                                .foregroundStyle(theme.colors.secondaryText)
                        }
                        Spacer()
                    }
                    .foregroundStyle(theme.colors.primaryText)
                    .padding(theme.spacing.cardPadding)
                    .frame(maxWidth: .infinity, minHeight: 148, alignment: .leading)
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
        KidSectionIsland(title: "あした", tint: theme.colors.peekCard) {
            if calendarVM.weekPeekOccurrences.isEmpty {
                emptyCard(icon: "calendar", message: "あしたを おたのしみに")
            } else {
                HStack(spacing: theme.spacing.itemGap) {
                    ForEach(calendarVM.weekPeekOccurrences.prefix(2), id: \.id) { occ in
                        tappableToken(occ, bgColor: theme.colors.peekCard)
                    }
                    if calendarVM.weekPeekOccurrences.count > 2 {
                        Text("+\(calendarVM.weekPeekOccurrences.count - 2)")
                            .font(theme.fonts.plusCount)
                            .frame(maxWidth: .infinity, minHeight: 136)
                            .cardStyle(background: theme.colors.peekCard)
                    }
                }
            }
        }
    }

    private func tappableToken(_ occ: EventOccurrence, bgColor: Color) -> some View {
        Button {
            speechService.speak(occ.baseEvent.title)
            selectedOccurrence = occ
        } label: {
            EventTokenRenderer(event: occ.baseEvent, showTitle: false, iconSize: theme.stampLarge, occurrenceDate: occ.occurrenceDate)
                .frame(maxWidth: .infinity, minHeight: 136)
                .cardStyle(background: bgColor)
        }
        .buttonStyle(.plain)
        .minTapTarget()
    }

    private func emptyCard(icon: String, message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 52, weight: .bold))
            Text(message)
                .font(theme.fonts.cardTitle)
        }
        .foregroundStyle(theme.colors.primaryText)
        .frame(maxWidth: .infinity, minHeight: 132)
        .padding(.horizontal, 8)
        .cardStyle(background: theme.colors.emptyCard)
    }

    private func registerFallbackGateTap() {
        let now = Date()
        if let lastHiddenGateTapAt, now.timeIntervalSince(lastHiddenGateTapAt) > 4 {
            hiddenGateTapCount = 0
        }
        hiddenGateTapCount += 1
        lastHiddenGateTapAt = now
        if hiddenGateTapCount >= 7 {
            hiddenGateTapCount = 0
            onRequestParentalGate()
        }
    }

    private func reload() {
        calendarVM.refresh(childFilter: appVM.filter, includeDraft: appVM.parentModeUnlocked)
    }

    private func timeRemainingText(_ date: Date) -> String {
        let min = max(0, Int(date.timeIntervalSinceNow / 60))
        if min >= 60 {
            let hours = min / 60
            let minutes = min % 60
            return "あと\(hours)じかん\(minutes)ふん"
        }
        return "あと\(min)ふん"
    }

    private func scopeLabel(_ scope: ChildScope) -> String {
        switch scope {
        case .son: return "息子"
        case .daughter: return "娘"
        case .both: return "両方"
        }
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "HH:mm"
        return f
    }()

    private static let headerFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M/d E"
        return f
    }()

    private func timeText(_ date: Date) -> String {
        TodayHomeView.timeFormatter.string(from: date)
    }

    private func todayHeader() -> String {
        TodayHomeView.headerFormatter.string(from: .now)
    }
}

#endif
