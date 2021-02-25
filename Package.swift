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
        .package(name: "danger-swift", url: "https://github.com/danger/danger-swift.git", from: "3.7.2") // dev
    ],
    targets: [
        .target(
            name: "CoverageHighlighter",
            dependencies: [
                .product(name: "Danger", package: "danger-swift") // dev
            ]),
        .testTarget(
            name: "CoverageHighlighterTests",
            dependencies: ["CoverageHighlighter",
                //.product(name: "DangerFixtures", package: "danger-swift") //dev
            ]),
    ]
)
