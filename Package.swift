// swift-tools-version: 5.10
import PackageDescription

// This is the workspace-level Package.swift for resolving all local packages.
// The actual app target is in InnerForgeApp/ (Xcode project).
let package = Package(
    name: "InnerForgeWorkspace",
    platforms: [.macOS(.v14)],
    products: [],
    dependencies: [
        .package(path: "Packages/IFCore"),
        .package(path: "Packages/IFStorage"),
        .package(path: "Packages/IFAI"),
        .package(path: "Packages/IFSkillKit"),
        .package(path: "Packages/IFSkillBuiltin"),
        .package(path: "Packages/IFObservation"),
        .package(path: "Packages/IFAnalysis"),
        .package(path: "Packages/IFUIComponents"),
    ],
    targets: []
)
