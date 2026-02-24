// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KyounaniEmbeddedAppPackage",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "KyounaniApp", targets: ["KyounaniApp"])
    ],
    targets: [
        .target(
            name: "KyounaniApp",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "KyounaniAppTests",
            dependencies: ["KyounaniApp"]
        )
    ]
)
