// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "IFStorage",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "IFStorage", targets: ["IFStorage"]),
    ],
    dependencies: [
        .package(path: "../IFCore"),
    ],
    targets: [
        .target(name: "IFStorage", dependencies: ["IFCore"], path: "Sources"),
        .testTarget(name: "IFStorageTests", dependencies: ["IFStorage"], path: "Tests"),
    ]
)
