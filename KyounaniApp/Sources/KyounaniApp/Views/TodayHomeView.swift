#if canImport(SwiftUI)
import SwiftUI

public struct TodayHomeView: View {
    @EnvironmentObject private var appVM: AppViewModel
    @ObservedObject var calendarVM: CalendarViewModel
    @ObservedObject var speechService: SpeechService
    @ObservedObject var repository: InMemoryEventRepository
    @State private var selectedOccurrence: EventOccurrence?

    public init(calendarVM: CalendarViewModel, speechService: SpeechService, repository: InMemoryEventRepository) {
        self.calendarVM = calendarVM
        self.speechService = speechService
        self.repository = repository
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Picker("対象", selection: $appVM.filter) {
                Text("息子").tag(ChildScope.son)
                Text("娘").tag(ChildScope.daughter)
                Text("両方").tag(ChildScope.both)
            }
            .pickerStyle(.segmented)

            todayStamps
            nextCard
            peeks
            Spacer()
        }
        .padding()
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
        VStack(alignment: .leading) {
            Text("きょうのよてい")
            HStack {
                ForEach(calendarVM.todayOccurrences.prefix(2), id: \.id) { occ in
                    stampCapsule(title: occ.baseEvent.title)
                }
                if calendarVM.todayOccurrences.count > 2 {
                    stampCapsule(title: "+\(calendarVM.todayOccurrences.count - 2)")
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
                    VStack(alignment: .leading) {
                        Text(next.baseEvent.title).font(.title2.bold())
                        Text(timeRemainingText(next.displayStart))
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
                stampCapsule(title: occ.baseEvent.title)
            }
        }
    }

    private func stampCapsule(title: String) -> some View {
        Text(title)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.green.opacity(0.2))
            .clipShape(Capsule())
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
