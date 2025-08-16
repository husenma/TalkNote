// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LiveTranscribe",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .executable(
            name: "LiveTranscribe",
            targets: ["LiveTranscribe"])
    ],
    dependencies: [
        // Add any external dependencies here if needed
    ],
    targets: [
        .executableTarget(
            name: "LiveTranscribe",
            dependencies: [],
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "LiveTranscribeTests",
            dependencies: ["LiveTranscribe"],
            path: "Tests"
        )
    ]
)
