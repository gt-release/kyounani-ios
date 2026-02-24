// swift-tools-version: 5.9
import PackageDescription

#if os(iOS)
let package = Package(
    name: "KyounaniPlaygrounds",
    platforms: [
        .iOS(.v17)
    ],
    products: [
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
    ],
    targets: [
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
)
#else
let package = Package(
    name: "KyounaniPlaygrounds",
    platforms: [
        .iOS(.v17)
    ],
    targets: [
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
)
#endif
