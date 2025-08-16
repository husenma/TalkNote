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
        // ML and NLP dependencies
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.0"),
        .package(url: "https://github.com/huggingface/swift-transformers.git", from: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "LiveTranscribe",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Transformers", package: "swift-transformers")
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
