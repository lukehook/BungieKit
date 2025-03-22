# BungieKit

A Swift package for interacting with the Bungie.net API in Swift applications.

## Features

- Strongly typed API client for Bungie.net endpoints
- Built with Swift Concurrency (async/await)
- Support for OAuth authentication
- Manifest download and management with CoreData
- Destiny 2 reset time calculations

## Requirements

- Swift 5.7+
- iOS 15.0+ / macOS 12.0+ / tvOS 15.0+ / watchOS 8.0+

## Installation

### Swift Package Manager

Add BungieKit to your Swift package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/your-username/BungieKit.git", from: "1.0.0")
]
```

Then add the libraries you need to your target:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "BungieKit", package: "BungieKit"),
        .product(name: "BungieKitManifest", package: "BungieKit") // If you want manifest support
    ]
)
```

## Basic Usage

### Creating a Client

```swift
import BungieKit

// Create a basic client with just an API key
let client = BungieClient.basic(apiKey: "your-api-key")

// Or with full configuration
let config = BungieClient.Configuration(
    apiKey: "your-api-key",
    clientId: "your-oauth-client-id",
    clientSecret: "your-oauth-client-secret"
)
let client = BungieClient(configuration: config)
```

### Making API Requests

```swift
// Get the Destiny 2 manifest
do {
    let manifest = try await client.destinyService.getManifest()
    print("Manifest version: \(manifest.version)")
} catch {
    print("Error getting manifest: \(error)")
}

// Search for a player
do {
    let players = try await client.destinyService.searchDestinyPlayer(searchText: "Guardian")
    for player in players {
        print("\(player.displayName) - \(player.membershipType.displayName)")
    }
} catch {
    print("Error searching for player: \(error)")
}

// Get a player's profile
do {
    let profile = try await client.destinyService.getProfile(
        membershipType: .tigerPsn,
        destinyMembershipId: "12345",
        components: [.profiles, .characters]
    )
    // Process profile data
} catch {
    print("Error getting profile: \(error)")
}
```

### OAuth Authentication

```swift
// Get the authorization URL
let authURL = client.authService?.getAuthorizationURL(
    scopes: [.readBasicUserProfile, .readDestinyInventoryAndVault],
    state: "your-state-token"
)

// Open authURL in a browser, then exchange the code from the callback
do {
    let code = "code-from-callback"
    let tokens = try await client.authService?.exchangeCode(code: code)
    
    // Save tokens.accessToken and tokens.refreshToken for future use
} catch {
    print("Auth error: \(error)")
}
```

### Manifest Management

```swift
import BungieKitManifest

// Create a manifest provider
let manifestProvider = CoreDataManifestProvider()

// Check for and download updates
do {
    let manifest = try await client.destinyService.getManifest()
    
    if manifestProvider.needsUpdate(manifestResponse: manifest) {
        try await manifestProvider.updateManifest(
            manifestResponse: manifest,
            locale: "en"
        ) { progress in
            print("Download progress: \(progress * 100)%")
        }
        print("Manifest updated!")
    } else {
        print("Manifest is up to date")
    }
    
    // Access definitions
    if let itemDef: ItemDefinition = manifestProvider.getDefinition(
        hash: 12345, 
        definitionType: .inventoryItem
    ) {
        print("Item: \(itemDef.displayProperties.name)")
    }
} catch {
    print("Manifest error: \(error)")
}
```

## License

This package is available under the MIT license. See the LICENSE file for more info. 