// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "BungieKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "BungieKit",
            targets: ["BungieKit"]),
        .library(
            name: "BungieKitManifest",
            targets: ["BungieKitManifest"])
    ],
    dependencies: [
        // No external dependencies
    ],
    targets: [
        // Core BungieKit target
        .target(
            name: "BungieKit",
            dependencies: []),
        
        // Manifest handling target that includes CoreData
        .target(
            name: "BungieKitManifest",
            dependencies: ["BungieKit"],
            resources: [
                .process("Resources")
            ]),
        
        // Tests
        .testTarget(
            name: "BungieKitTests",
            dependencies: ["BungieKit"]),
        .testTarget(
            name: "BungieKitManifestTests",
            dependencies: ["BungieKitManifest"])
    ]
) 