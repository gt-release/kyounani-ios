#if canImport(SwiftUI)
import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

private struct BuiltinStampDefinition: Codable {
    var id: UUID
    var name: String
    var symbolName: String
}

@MainActor
public final class StampStore: ObservableObject {
    @Published public private(set) var stamps: [Stamp] = []

    private let repository: EventRepositoryBase

    private static let fallbackBuiltinDefinitions: [BuiltinStampDefinition] = [
        .init(id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, name: "ようちえん", symbolName: "figure.and.child.holdinghands"),
        .init(id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!, name: "びょういん", symbolName: "cross.case.fill"),
        .init(id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!, name: "こうえん", symbolName: "leaf.fill"),
        .init(id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!, name: "りょういく", symbolName: "hands.sparkles.fill"),
        .init(id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!, name: "かいもの", symbolName: "cart.fill"),
        .init(id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!, name: "がいしょく", symbolName: "fork.knife"),
        .init(id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!, name: "きせい", symbolName: "house.fill"),
        .init(id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!, name: "たんじょうび", symbolName: "birthday.cake.fill")
    ]

    private static let legacyBuiltinToSymbol: [String: String] = [
        "kindergarten": "figure.and.child.holdinghands",
        "hospital": "cross.case.fill",
        "park": "leaf.fill",
        "therapy": "hands.sparkles.fill",
        "shopping": "cart.fill",
        "dining": "fork.knife",
        "homecoming": "house.fill",
        "birthday": "birthday.cake.fill"
    ]

    public var defaultStampId: UUID {
        Self.fallbackBuiltinDefinitions.first?.id ?? UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    }

    public init(repository: EventRepositoryBase) {
        self.repository = repository
        reload()
        seedBuiltinIfMissing()
    }

    public func stamp(for id: UUID) -> Stamp {
        stamps.first(where: { $0.id == id }) ?? Stamp(id: defaultStampId, name: "デフォルト", kind: .systemSymbol, imageLocation: "symbol:questionmark.circle.fill", isBuiltin: true)
    }

    public func image(for stamp: Stamp) -> Image? {
        switch stamp.kind {
        case .systemSymbol:
            if stamp.imageLocation.hasPrefix("symbol:") {
                let symbolName = String(stamp.imageLocation.dropFirst("symbol:".count))
                return Image(systemName: symbolName)
            }
            if stamp.imageLocation.hasPrefix("builtin:") {
                let legacyName = String(stamp.imageLocation.dropFirst("builtin:".count))
                let symbolName = Self.legacyBuiltinToSymbol[legacyName] ?? "questionmark.circle.fill"
                return Image(systemName: symbolName)
            }
            return Image(systemName: "questionmark.circle.fill")
        case .customImage:
            return imageFromURL(url: userImageURL(filename: stamp.imageLocation))
        }
    }

    public func ensureStampIdForDisplay(_ stampId: UUID?) -> UUID {
        guard let stampId, stamps.contains(where: { $0.id == stampId }) else { return defaultStampId }
        return stampId
    }

    public func reload() {
        stamps = repository.fetchStamps().sorted { lhs, rhs in
            if lhs.isBuiltin != rhs.isBuiltin {
                return lhs.isBuiltin && !rhs.isBuiltin
            }
            return lhs.name < rhs.name
        }
    }

    @discardableResult
    public func addUserStamp(name: String, imageData: Data) -> Bool {
        #if canImport(UIKit)
        guard let uiImage = UIImage(data: imageData),
              let cropped = uiImage.centerCroppedSquare(),
              let pngData = cropped.pngData() else {
            return false
        }

        let id = UUID()
        let filename = "\(id.uuidString).png"
        let url = userImageURL(filename: filename)

        do {
            try ensureAppSupportDirectory()
            try pngData.write(to: url, options: .atomic)
            repository.save(stamp: Stamp(id: id, name: name, kind: .customImage, imageLocation: filename, isBuiltin: false))
            reload()
            return true
        } catch {
            return false
        }
        #else
        return false
        #endif
    }

    @discardableResult
    public func deleteUserStamp(id: UUID) -> Bool {
        guard let stamp = stamps.first(where: { $0.id == id }), !stamp.isBuiltin else { return false }

        do {
            repository.delete(stampID: id)
            let imageURL = userImageURL(filename: stamp.imageLocation)
            if FileManager.default.fileExists(atPath: imageURL.path) {
                try FileManager.default.removeItem(at: imageURL)
            }
            reload()
            return true
        } catch {
            return false
        }
    }

    private func seedBuiltinIfMissing() {
        guard repository.fetchStamps().isEmpty else { return }
        let definitions = loadBuiltinDefinitions()
        for definition in definitions {
            repository.save(stamp: Stamp(id: definition.id, name: definition.name, kind: .systemSymbol, imageLocation: "symbol:\(definition.symbolName)", isBuiltin: true))
        }
        reload()
    }

    private func loadBuiltinDefinitions() -> [BuiltinStampDefinition] {
        let candidateBundles: [Bundle] = [Bundle.module, .main]
        for bundle in candidateBundles {
            guard let url = bundle.url(forResource: "builtin_stamps", withExtension: "json", subdirectory: "Stamps"),
                  let data = try? Data(contentsOf: url),
                  let parsed = try? JSONDecoder().decode([BuiltinStampDefinition].self, from: data),
                  !parsed.isEmpty else {
                continue
            }
            return parsed
        }
        return Self.fallbackBuiltinDefinitions
    }

    private func imageFromURL(url: URL) -> Image? {
        #if canImport(UIKit)
        guard let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
        #else
        return nil
        #endif
    }

    private func ensureAppSupportDirectory() throws {
        let dir = appSupportDirectory()
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    private func appSupportDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("Kyounani", isDirectory: true)
    }

    private func userImageURL(filename: String) -> URL {
        appSupportDirectory().appendingPathComponent(filename)
    }
}

#if canImport(UIKit)
private extension UIImage {
    func centerCroppedSquare() -> UIImage? {
        guard let cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        let size = min(width, height)
        let x = (width - size) / 2
        let y = (height - size) / 2
        let rect = CGRect(x: x, y: y, width: size, height: size)
        guard let cropped = cgImage.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cropped, scale: scale, orientation: imageOrientation)
    }
}
#endif

#endif
