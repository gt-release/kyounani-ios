// swift-tools-version: 5.9
import PackageDescription

#if canImport(AppleProductTypes)
import AppleProductTypes
#endif

let sharedTargets: [Target] = [
    .target(
        name: "KyounaniApp",
        path: "Packages/KyounaniEmbeddedApp/Sources/KyounaniApp",
        resources: [
            .process("Resources")
        ]
    ),
    .executableTarget(
        name: "KyounaniPlaygrounds",
        dependencies: [
            "KyounaniApp"
        ],
        resources: [
            .process("Resources")
        ]
    )
]

#if canImport(AppleProductTypes)
let products: [Product] = [
    .iOSApplication(
        name: "きょうなに？",
        targets: ["KyounaniPlaygrounds"],
        bundleIdentifier: "dev.kyounani.playgrounds",
        teamIdentifier: "",
        displayVersion: "1.0",
        bundleVersion: "1",
        appIcon: .placeholder(icon: .calendar),
        accentColor: .presetColor(.blue),
        supportedDeviceFamilies: [
            .pad
        ],
        supportedInterfaceOrientations: [
            .portrait,
            .landscapeLeft,
            .landscapeRight
        ]
    )
]
#else
let products: [Product] = [
    .executable(name: "Kyounani", targets: ["KyounaniPlaygrounds"])
]
#endif

let package = Package(
    name: "KyounaniPlaygrounds",
    platforms: [
        .iOS(.v17)
    ],
    products: products,
    targets: sharedTargets
)
