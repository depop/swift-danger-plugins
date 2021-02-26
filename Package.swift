// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CoverageHighlighter",
    products: [
        .library(
            name: "CoverageHighlighter",
            targets: ["CoverageHighlighter"]),
    ],
    dependencies: [
        .package(name: "danger-swift", url: "https://github.com/danger/danger-swift.git", from: "3.7.2")
    ],
    targets: [
        .target(
            name: "CoverageHighlighter",
            dependencies: [
                .product(name: "Danger", package: "danger-swift") // Needs to be commented for dev + tests
            ]),
        .testTarget(
            name: "CoverageHighlighterTests",
            dependencies: ["CoverageHighlighter",
               // .product(name: "DangerFixtures", package: "danger-swift") // Needs to be uncommented for dev + tests
            ],
            resources: [
                .process("Results")
            ]
        ),
    ]
)
