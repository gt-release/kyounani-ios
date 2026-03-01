#if canImport(SwiftUI)
import Foundation

@MainActor
public final class AppViewModel: ObservableObject {
    private enum Keys {
        static let themePreset = "kyounani.themePreset"
    }

    @Published public private(set) var parentModeUnlocked = false
    @Published public var filter: ChildScope = .both
    @Published public var failedGateAttempts = 0
    @Published public var gateCooldownUntil: Date?
    @Published public var emergencyCodeEnabled = false
    @Published public private(set) var hadUncleanExitLastLaunch = false
    @Published public var safeModeEnabled: Bool {
        didSet {
            DiagnosticsCenter.setSafeModeEnabled(safeModeEnabled)
        }
    }
    @Published public var themePreset: ThemePreset {
        didSet {
            UserDefaults.standard.set(themePreset.rawValue, forKey: Keys.themePreset)
        }
    }

    private let validSequence = [0, 2, 1, 3]

    public init() {
        let raw = UserDefaults.standard.string(forKey: Keys.themePreset)
        themePreset = ThemePreset(rawValue: raw ?? "") ?? .kid
        safeModeEnabled = DiagnosticsCenter.isSafeModeEnabled
        hadUncleanExitLastLaunch = DiagnosticsCenter.markAppLaunched()
    }

    public var theme: KyounaniTheme {
        KyounaniTheme.preset(themePreset)
    }

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
            DiagnosticsCenter.breadcrumb(event: "enteredParentMode")
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
        DiagnosticsCenter.breadcrumb(event: "lockedToChildMode")
    }

    public func markCleanExit(reason: String) {
        DiagnosticsCenter.markCleanExit(reason: reason)
    }

}

#endif
