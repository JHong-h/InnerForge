// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "IFAnalysis",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "IFAnalysis", targets: ["IFAnalysis"]),
    ],
    dependencies: [
        .package(path: "../IFCore"),
        .package(path: "../IFAI"),
        .package(path: "../IFSkillKit"),
    ],
    targets: [
        .target(name: "IFAnalysis", dependencies: ["IFCore", "IFAI", "IFSkillKit"], path: "Sources"),
        .testTarget(name: "IFAnalysisTests", dependencies: ["IFAnalysis"], path: "Tests"),
    ]
)
