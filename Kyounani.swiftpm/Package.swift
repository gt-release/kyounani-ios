// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KyounaniPlaygrounds",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [
        .package(name: "KyounaniEmbeddedAppPackage", path: "Packages/KyounaniEmbeddedApp")
    ],
    targets: [
        .executableTarget(
            name: "KyounaniPlaygrounds",
            dependencies: [
                .product(name: "KyounaniApp", package: "KyounaniEmbeddedAppPackage")
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
