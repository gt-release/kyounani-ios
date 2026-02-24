// swift-tools-version: 5.9
import PackageDescription

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
