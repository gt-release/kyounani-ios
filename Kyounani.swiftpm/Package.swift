// swift-tools-version: 5.9
import PackageDescription
#if canImport(AppleProductTypes)
import AppleProductTypes
#endif

#if canImport(AppleProductTypes)
let package = Package(
    name: "KyounaniPlaygrounds",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .iOSApplication(
            name: "Kyounani",
            targets: ["KyounaniPlaygrounds"],
            bundleIdentifier: "com.kyounani.playgrounds",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .star),
            accentColor: .presetColor(.blue),
            supportedDeviceFamilies: [
                .pad
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft
            ]
        )
    ],
    targets: kyounaniTargets
)
#else
let package = Package(
    name: "KyounaniPlaygrounds",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(name: "Kyounani", targets: ["KyounaniPlaygrounds"])
    ],
    targets: kyounaniTargets
)
#endif

private let kyounaniTargets: [Target] = [
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
