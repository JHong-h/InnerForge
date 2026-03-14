// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "IFAI",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "IFAI", targets: ["IFAI"]),
    ],
    dependencies: [
        .package(path: "../IFCore"),
        .package(path: "../IFStorage"),
    ],
    targets: [
        .target(name: "IFAI", dependencies: ["IFCore", "IFStorage"], path: "Sources"),
        .testTarget(name: "IFAITests", dependencies: ["IFAI"], path: "Tests"),
    ]
)
