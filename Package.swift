// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ClinicalScribe",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ClinicalScribe",
            targets: ["ClinicalScribe"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ClinicalScribe",
            dependencies: [],
            path: "Sources/ClinicalScribe"
        ),
    ]
)
