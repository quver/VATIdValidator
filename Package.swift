// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "VATIdValidator",
    products: [
        .library(
            name: "VATIdValidator",
            targets: ["VATIdValidator"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "VATIdValidator",
            dependencies: []),
        .testTarget(
            name: "VATIdValidatorTests",
            dependencies: ["VATIdValidator"]),
    ]
)
