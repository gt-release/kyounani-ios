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
        HStack(spacing: 10) {
            childFilterButton(scope: .son, symbol: "figure.stand", color: .blue)
            childFilterButton(scope: .daughter, symbol: "figure.stand", color: .pink)
            childFilterButton(scope: .both, symbol: "person.2.fill", color: .purple)
        }
        .padding(.vertical, 2)
    }

    private func childFilterButton(scope: ChildScope, symbol: String, color: Color) -> some View {
        let isSelected = appVM.filter == scope
        return Button {
            appVM.filter = scope
        } label: {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(color)
                Text(scopeLabel(scope))
                    .font(.caption.bold())
                    .foregroundStyle(theme.colors.primaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? color.opacity(0.2) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? color : theme.colors.secondaryText.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .minTapTarget()
    }

    private var todaySection: some View {
        let summary = EventListPresenter.summarizeDay(calendarVM.todayOccurrences)

        return VStack(alignment: .leading, spacing: theme.spacing.itemGap) {
            sectionHeader("きょう", enablesFallbackGate: true)

            if summary.topOccurrences.isEmpty {
                emptyCard(icon: "sun.max.fill", message: "きょうは おやすみ")
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
        .padding(theme.spacing.cardPadding)
        .cardStyle(background: theme.colors.todayCard.opacity(0.5))
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
        .padding(theme.spacing.cardPadding)
        .cardStyle(background: theme.colors.nextCard.opacity(0.45))
    }

    private var tomorrowSection: some View {
        let hasTomorrow = !calendarVM.tomorrowOccurrences.isEmpty
        return VStack(alignment: .leading, spacing: theme.spacing.itemGap) {
            sectionHeader("あした")

            if hasTomorrow {
                HStack(spacing: theme.spacing.itemGap) {
                    ForEach(calendarVM.tomorrowOccurrences.prefix(2), id: \.id) { occ in
                        EventTokenRenderer(event: occ.baseEvent, showTitle: false, iconSize: theme.stampLarge, occurrenceDate: occ.occurrenceDate)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .cardStyle(background: theme.colors.peekCard)
                    }
                }
            } else {
                emptyCard(icon: "calendar", message: "あしたを おたのしみに")
            }
        }
        .padding(theme.spacing.cardPadding)
        .cardStyle(background: theme.colors.peekCard.opacity(0.5))
    }

    private func sectionHeader(_ title: String, enablesFallbackGate: Bool = false) -> some View {
        Text(title)
            .font(theme.fonts.sectionHeader)
            .foregroundStyle(theme.colors.primaryText)
            .padding(.bottom, 2)
            .onTapGesture {
                guard enablesFallbackGate else { return }
                registerFallbackGateTap()
            }
    }

    private func emptyCard(icon: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 44, weight: .bold))
            Text(message)
                .font(theme.fonts.cardTitle)
                .fontWeight(.heavy)
        }
        .foregroundStyle(theme.colors.primaryText)
        .frame(maxWidth: .infinity)
        .padding(theme.spacing.cardPadding)
        .cardStyle(background: theme.colors.emptyCard)
        .minTapTarget()
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

    private func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#endif
