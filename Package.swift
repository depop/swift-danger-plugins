// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "CoverageHighlighter",
    products: [
        .library(
            name: "CoverageHighlighter",
            targets: ["CoverageHighlighter"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/danger/danger-swift.git",
            from: "3.0.0")
    ],
    targets: [
        .target(
            name: "CoverageHighlighter",
            dependencies: ["danger-swift"]),
        .testTarget(
            name: "CoverageHighlighterTests",
            dependencies: ["CoverageHighlighter"]),
    ]
)
