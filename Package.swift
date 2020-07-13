// swift-tools-version:5.2
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
        // Dependencies declare other packages that this package depends on.
      .package(url: "https://github.com/danger/danger-swift.git", from: "3.3.2")
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
