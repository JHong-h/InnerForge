// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "IFCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "IFCore", targets: ["IFCore"]),
    ],
    targets: [
        .target(name: "IFCore", path: "Sources"),
        .testTarget(name: "IFCoreTests", dependencies: ["IFCore"], path: "Tests"),
    ]
)
