#if canImport(SwiftUI)
import Foundation

@MainActor
public final class AppViewModel: ObservableObject {
    @Published public private(set) var parentModeUnlocked = false
    @Published public var filter: ChildScope = .both
    @Published public var failedGateAttempts = 0
    @Published public var gateCooldownUntil: Date?
    @Published public var emergencyCodeEnabled = false

    private let validSequence = [0, 2, 1, 3]

    public init() {}

    public var isInCooldown: Bool {
        if let gateCooldownUntil { return gateCooldownUntil > .now }
        return false
    }

    public func tryUnlock(sequence: [Int], emergencyCode: String?) -> Bool {
        guard !isInCooldown else { return false }
        if sequence == validSequence || (emergencyCodeEnabled && emergencyCode == "0428") {
            parentModeUnlocked = true
            failedGateAttempts = 0
            gateCooldownUntil = nil
            return true
        }

        failedGateAttempts += 1
        if failedGateAttempts >= 3 {
            gateCooldownUntil = Date().addingTimeInterval(30)
            failedGateAttempts = 0
        }
        return false
    }

    public func lockToChildMode() {
        parentModeUnlocked = false
    }
}

#endif
