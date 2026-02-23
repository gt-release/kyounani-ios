#if canImport(SwiftUI)
import SwiftUI

public struct ParentalGateView: View {
    @EnvironmentObject private var appVM: AppViewModel
    @State private var sequence: [Int] = []
    @State private var emergencyCode = ""

    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            Text("ペアレンタルゲート")
                .font(.title2.bold())

            if appVM.isInCooldown {
                Text("しばらく待ってから、もういちど")
                    .foregroundStyle(.red)
            }

            LazyVGrid(columns: [GridItem(), GridItem()]) {
                ForEach(0..<4) { index in
                    Button("●") {
                        sequence.append(index)
                        if sequence.count == 4 {
                            _ = appVM.tryUnlock(sequence: sequence, emergencyCode: nil)
                            sequence.removeAll()
                        }
                    }
                    .font(.largeTitle)
                    .padding()
                }
            }

            if appVM.emergencyCodeEnabled {
                TextField("緊急コード", text: $emergencyCode)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                Button("コードで解除") {
                    _ = appVM.tryUnlock(sequence: [], emergencyCode: emergencyCode)
                    emergencyCode = ""
                }
            }
        }
        .padding()
    }
}

#endif
