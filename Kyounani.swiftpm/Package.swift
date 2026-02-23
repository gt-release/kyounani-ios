// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KyounaniPlaygrounds",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [
        .package(path: "../KyounaniApp")
    ],
    targets: [
        .executableTarget(
            name: "KyounaniPlaygrounds",
            dependencies: [
                .product(name: "KyounaniApp", package: "KyounaniApp")
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
