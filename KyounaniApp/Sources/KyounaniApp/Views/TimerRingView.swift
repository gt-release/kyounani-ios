#if canImport(SwiftUI)
import SwiftUI

public struct TimerRingView: View {
    public let targetDate: Date
    @State private var now = Date()

    public init(targetDate: Date) {
        self.targetDate = targetDate
    }

    public var body: some View {
        VStack {
            ZStack {
                ForEach(0..<ringCount, id: \.self) { idx in
                    let fraction = progressForRing(index: idx)
                    Circle()
                        .stroke(Color.blue.opacity(0.15 + Double(idx) * 0.15), lineWidth: 16)
                        .frame(width: 200 - CGFloat(idx * 18), height: 200 - CGFloat(idx * 18))
                    Circle()
                        .trim(from: 0, to: fraction)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 200 - CGFloat(idx * 18), height: 200 - CGFloat(idx * 18))
                }
            }
            Text(labelText)
                .font(.title3.bold())
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { value in
            now = value
        }
    }

    private var remaining: TimeInterval {
        max(0, targetDate.timeIntervalSince(now))
    }

    private var ringCount: Int {
        max(1, Int(ceil(remaining / 3600)))
    }

    private func progressForRing(index: Int) -> CGFloat {
        let lower = Double(index) * 3600
        let remainingInThisRing = min(max(remaining - lower, 0), 3600)
        return CGFloat(remainingInThisRing / 3600)
    }

    private var labelText: String {
        if remaining <= 0 { return "はじまった！" }
        let minutes = Int(remaining / 60)
        return "あと \(minutes)分"
    }
}

#endif
