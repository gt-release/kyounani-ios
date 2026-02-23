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
            VStack(alignment: .leading, spacing: 20) {
                Picker("対象", selection: $appVM.filter) {
                    Text("息子").tag(ChildScope.son)
                    Text("娘").tag(ChildScope.daughter)
                    Text("両方").tag(ChildScope.both)
                }
                .pickerStyle(.segmented)

                NavigationLink {
                    CalendarRootView(calendarVM: calendarVM, speechService: speechService, repository: repository)
                } label: {
                    Label("カレンダー", systemImage: "calendar")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(12)
                }

                todayStamps
                nextCard
                peeks
            }
            .padding()
        }
        .navigationTitle("きょう")
        .onAppear { reload() }
        .onChange(of: appVM.filter) { _ in reload() }
        .onChange(of: appVM.parentModeUnlocked) { _ in reload() }
        .onReceive(repository.objectWillChange) { _ in
            reload()
        }
        .sheet(item: $selectedOccurrence) { occ in
            TimerRingView(targetDate: occ.displayStart)
                .padding()
        }
    }

    private var todayStamps: some View {
        let summary = EventListPresenter.summarizeDay(calendarVM.todayOccurrences)
        return VStack(alignment: .leading, spacing: 8) {
            Text("きょうのよてい")
            HStack {
                ForEach(summary.topOccurrences, id: \.id) { occ in
                    EventTokenRenderer(event: occ.baseEvent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.12))
                        .clipShape(Capsule())
                }
                if summary.remainingCount > 0 {
                    Text("+\(summary.remainingCount)")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var nextCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("つぎのよてい")
            if let next = calendarVM.todayOccurrences.first(where: { $0.displayStart >= .now }) {
                Button {
                    speechService.speak(next.baseEvent.title)
                    selectedOccurrence = next
                } label: {
                    HStack(spacing: 12) {
                        EventTokenRenderer(event: next.baseEvent, showTitle: false, iconSize: 48)
                        VStack(alignment: .leading) {
                            Text(next.baseEvent.title).font(.title3.bold())
                            Text(timeRemainingText(next.displayStart))
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(16)
                }
            } else {
                Text("きょうのよていは おしまい")
            }
        }
    }

    private var peeks: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("あしたから")
            ForEach(calendarVM.weekPeekOccurrences.prefix(2), id: \.id) { occ in
                EventTokenRenderer(event: occ.baseEvent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    private func reload() {
        calendarVM.refresh(childFilter: appVM.filter, includeDraft: appVM.parentModeUnlocked)
    }

    private func timeRemainingText(_ date: Date) -> String {
        let min = max(0, Int(date.timeIntervalSinceNow / 60))
        return "あと\(min)分"
    }
}

#endif
