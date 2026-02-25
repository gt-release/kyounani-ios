#if canImport(Foundation)
import Foundation

public struct BreadcrumbEntry: Codable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let event: String
    public let detail: String

    public init(id: UUID = UUID(), timestamp: Date = Date(), event: String, detail: String = "") {
        self.id = id
        self.timestamp = timestamp
        self.event = event
        self.detail = detail
    }
}

public enum DiagnosticsCenter {
    private enum Keys {
        static let didCleanExit = "kyounani.didCleanExit"
        static let safeModeEnabled = "kyounani.safeModeEnabled"
        static let breadcrumbs = "kyounani.breadcrumbs"
        static let previousUncleanExit = "kyounani.previousUncleanExit"
        static let lastErrorMessage = "kyounani.lastErrorMessage"
        static let lastRepoTypeLabel = "kyounani.lastRepoTypeLabel"
    }

    private static let maxStoredBreadcrumbs = 200

    public static func markAppLaunched() -> Bool {
        let defaults = UserDefaults.standard
        let previousCleanExit = defaults.object(forKey: Keys.didCleanExit) as? Bool ?? true
        defaults.set(!previousCleanExit, forKey: Keys.previousUncleanExit)
        defaults.set(false, forKey: Keys.didCleanExit)
        breadcrumb(event: "appLaunch", detail: "previousCleanExit=\(previousCleanExit)")
        return !previousCleanExit
    }

    public static func markCleanExit(reason: String) {
        UserDefaults.standard.set(true, forKey: Keys.didCleanExit)
        breadcrumb(event: "markCleanExit", detail: reason)
    }

    public static var hadUncleanExitLastLaunch: Bool {
        UserDefaults.standard.bool(forKey: Keys.previousUncleanExit)
    }

    public static var lastErrorMessage: String? {
        UserDefaults.standard.string(forKey: Keys.lastErrorMessage)
    }

    public static func setLastErrorMessage(_ value: String) {
        UserDefaults.standard.set(value, forKey: Keys.lastErrorMessage)
    }

    public static var lastRepoTypeLabel: String? {
        UserDefaults.standard.string(forKey: Keys.lastRepoTypeLabel)
    }

    public static func setLastRepoTypeLabel(_ value: String) {
        UserDefaults.standard.set(value, forKey: Keys.lastRepoTypeLabel)
    }

    public static var isSafeModeEnabled: Bool {
        UserDefaults.standard.bool(forKey: Keys.safeModeEnabled)
    }

    public static func setSafeModeEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Keys.safeModeEnabled)
        breadcrumb(event: "safeModeChanged", detail: "enabled=\(enabled)")
    }

    public static func breadcrumb(event: String, detail: String = "") {
        let entry = BreadcrumbEntry(event: event, detail: detail)
        var entries = readBreadcrumbsInternal()
        entries.append(entry)
        if entries.count > maxStoredBreadcrumbs {
            entries = Array(entries.suffix(maxStoredBreadcrumbs))
        }
        saveBreadcrumbsInternal(entries)
        appendFileLog(line: "[\(event)] \(detail)")
    }

    public static func recentBreadcrumbs(limit: Int = 50) -> [BreadcrumbEntry] {
        Array(readBreadcrumbsInternal().suffix(limit).reversed())
    }

    public static func breadcrumbsText(limit: Int = 50) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return recentBreadcrumbs(limit: limit)
            .map { "\(formatter.string(from: $0.timestamp)) | \($0.event) | \($0.detail)" }
            .joined(separator: "\n")
    }

    public static func readLogFile() -> String {
        guard let data = try? Data(contentsOf: logFileURL()),
              let text = String(data: data, encoding: .utf8) else {
            return ""
        }
        return text
    }

    public static func appendFileLog(line: String) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let line = "\(formatter.string(from: Date())) \(line)\n"

        do {
            let url = logFileURL()
            try ensureDirectoryExists(url.deletingLastPathComponent())
            if FileManager.default.fileExists(atPath: url.path) {
                let handle = try FileHandle(forWritingTo: url)
                defer { try? handle.close() }
                try handle.seekToEnd()
                if let data = line.data(using: .utf8) {
                    try handle.write(contentsOf: data)
                }
            } else {
                try line.write(to: url, atomically: true, encoding: .utf8)
            }
        } catch {
            // ignore logging failures
        }
    }

    private static func readBreadcrumbsInternal() -> [BreadcrumbEntry] {
        guard let data = UserDefaults.standard.data(forKey: Keys.breadcrumbs),
              let entries = try? JSONDecoder().decode([BreadcrumbEntry].self, from: data) else {
            return []
        }
        return entries
    }

    private static func saveBreadcrumbsInternal(_ entries: [BreadcrumbEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: Keys.breadcrumbs)
    }

    private static func logFileURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base
            .appendingPathComponent("Kyounani", isDirectory: true)
            .appendingPathComponent("kyounani.log")
    }

    private static func ensureDirectoryExists(_ directoryURL: URL) throws {
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
    }
}

#endif
