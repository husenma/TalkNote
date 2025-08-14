// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LiveTranscribe",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "LiveTranscribe",
            targets: ["LiveTranscribe"])
    ],
    targets: [
        .target(
            name: "LiveTranscribe",
            path: "Sources"
        ),
        .testTarget(
            name: "LiveTranscribeTests",
            dependencies: ["LiveTranscribe"],
            path: "Tests"
        )
    ]
)
