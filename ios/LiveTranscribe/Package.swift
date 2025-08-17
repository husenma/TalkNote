// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LiveTranscribe",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "LiveTranscribe",
            targets: ["LiveTranscribe"])
    ],
    dependencies: [
        // ML and NLP dependencies
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.0")
        // Note: WhisperKit functionality replaced with enhanced Apple Speech framework
        // Removed swift-transformers as it's not needed for basic language detection
    ],
    targets: [
        .target(
            name: "LiveTranscribe",
            dependencies: [
                .product(name: "Collections", package: "swift-collections")
            ],
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
