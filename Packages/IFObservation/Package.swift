// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "IFObservation",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "IFObservation", targets: ["IFObservation"]),
    ],
    dependencies: [
        .package(path: "../IFCore"),
        .package(path: "../IFStorage"),
    ],
    targets: [
        .target(name: "IFObservation", dependencies: ["IFCore", "IFStorage"], path: "Sources"),
        .testTarget(name: "IFObservationTests", dependencies: ["IFObservation"], path: "Tests"),
    ]
)
