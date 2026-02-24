import Foundation

enum ResourceBundleLocator {
    private final class BundleToken {}

    static func candidateBundles() -> [Bundle] {
        var bundles: [Bundle] = [
            .main,
            Bundle(for: BundleToken.self)
        ]

        bundles.append(contentsOf: Bundle.allBundles)
        bundles.append(contentsOf: Bundle.allFrameworks)

        var unique: [Bundle] = []
        var seenPaths = Set<String>()
        for bundle in bundles {
            let path = bundle.bundlePath
            guard seenPaths.insert(path).inserted else { continue }
            unique.append(bundle)
        }
        return unique
    }
}

