// swift-tools-version:5.7
// Requires Swift 5.7+ and Xcode 14.0+
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
        // Add GRDB dependency
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.16.0"),
        // Add ZIPFoundation for handling zip files
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.16")
    ],
    targets: [
        // Core BungieKit target
        .target(
            name: "BungieKit",
            dependencies: []),
        
        // Manifest handling target with GRDB instead of CoreData
        .target(
            name: "BungieKitManifest",
            dependencies: [
                "BungieKit", 
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation")
            ],
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