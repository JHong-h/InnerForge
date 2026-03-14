// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "IFUIComponents",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "IFUIComponents", targets: ["IFUIComponents"]),
    ],
    dependencies: [
        .package(path: "../IFCore"),
    ],
    targets: [
        .target(name: "IFUIComponents", dependencies: ["IFCore"], path: "Sources"),
        .testTarget(name: "IFUIComponentsTests", dependencies: ["IFUIComponents"], path: "Tests"),
    ]
)
