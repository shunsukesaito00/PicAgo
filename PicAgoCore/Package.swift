// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PicAgoCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "PicAgoCore",
            targets: ["PicAgoCore"]
        )
    ],
    targets: [
        .target(
            name: "PicAgoCore",
            path: "Sources/PicAgoCore"
        ),
        .testTarget(
            name: "PicAgoCoreTests",
            dependencies: ["PicAgoCore"],
            path: "Tests/PicAgoCoreTests"
        )
    ]
)
