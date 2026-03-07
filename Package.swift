// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "VATIdValidator",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v7),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "VATIdValidator",
            targets: ["VATIdValidator"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-docc-plugin",
            from: "1.3.0"
        ),
    ],
    targets: [
        .target(name: "VATIdValidator"),
        .testTarget(
            name: "VATIdValidatorTests",
            dependencies: ["VATIdValidator"]
        ),
    ]
)
