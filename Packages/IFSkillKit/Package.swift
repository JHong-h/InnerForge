// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "IFSkillKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "IFSkillKit", targets: ["IFSkillKit"]),
    ],
    dependencies: [
        .package(path: "../IFCore"),
        .package(path: "../IFStorage"),
        .package(path: "../IFAI"),
    ],
    targets: [
        .target(name: "IFSkillKit", dependencies: ["IFCore", "IFStorage", "IFAI"], path: "Sources"),
        .testTarget(name: "IFSkillKitTests", dependencies: ["IFSkillKit"], path: "Tests"),
    ]
)
