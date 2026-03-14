// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "IFSkillBuiltin",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "IFSkillBuiltin", targets: ["IFSkillBuiltin"]),
    ],
    dependencies: [
        .package(path: "../IFCore"),
        .package(path: "../IFAI"),
        .package(path: "../IFSkillKit"),
    ],
    targets: [
        .target(
            name: "IFSkillBuiltin",
            dependencies: ["IFCore", "IFAI", "IFSkillKit"],
            path: "Sources",
            resources: [.process("Prompts")]
        ),
        .testTarget(name: "IFSkillBuiltinTests", dependencies: ["IFSkillBuiltin"], path: "Tests"),
    ]
)
