> [!WARNING]
> This package is currently a work in progress and you may find that not all functionality is working as expected.

# BungieKit

A Swift package for interacting with the Bungie.net API in Swift applications.

## Features

- **Strongly typed API wrapper:**
  - Type-safe API requests and responses
  - Proper Swift enums for all enumerated values
  - Structured error types for robust error handling
  - Swift-native protocols and type definitions

- **Swift Concurrency:**
  - Built with modern async/await pattern
  - Task-based concurrency for efficient network operations
  - Proper async error handling

- **Complete API Coverage:**
  - OAuth authentication flow
  - Player profile and inventory data
  - Game content definitions
  - Stats and activities

- **Manifest Management:**
  - GRDB integration for efficient game database access
  - Type-safe access to dynamic game content
  - Support for multiple languages and content versions

- **Utilities:**
  - Destiny 2 reset time calculations
  - Helper methods for common operations

> [!NOTE]
> BungieKit provides a strongly typed *interface* to the Bungie API (the structure of requests and responses), 
> while the actual game content data (items, activities, etc.) comes from the Destiny 2 manifest database and is accessed 
> through this type-safe interface.

## Requirements

- Swift 5.7+
- iOS 15.0+ / macOS 12.0+ / tvOS 15.0+ / watchOS 8.0+
- Xcode 14.0+

## Installation

### Swift Package Manager

Add BungieKit to your Swift package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/lukehook/BungieKit.git", from: "1.0.0")
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

### Xcode

1. In Xcode, select **File** → **Add Packages...**
2. Search for "BungieKit" in the Swift Package Index
3. Select the package when it appears in the results
4. Select the version rule (e.g., "Up to Next Major")
5. Click **Add Package**
6. Choose the libraries you want to use in your app

## Getting Started

### API Key Requirements

Before using BungieKit, you need to:
1. Create an application on [Bungie.net Developer Portal](https://www.bungie.net/en/Application)
2. Get your API key and OAuth credentials (if you plan to use authentication)
3. Configure your OAuth redirect URL

### Security Recommendations

> [!WARNING]
> 
> API keys and OAuth credentials should be handled securely:
> 
> - **Never** store API keys, client IDs, or client secrets directly in your source code
> - **Never** commit credentials to version control or include them in public repositories
> 
> Remember that your API key is tied to your Bungie.net application and rate limits. Compromised keys can lead to abuse and potential suspension of your application.

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

## API Reference

BungieKit is organized into several service components:

### BungieClient

The main entry point to the API. Manages configuration and provides access to services.

```swift
// Access services through the client
client.authService       // For OAuth flows
client.apiService        // For raw API requests
client.destinyService    // For Destiny 2 specific endpoints
client.resetService      // For reset time calculations
```

### DestinyService

Provides methods for interacting with Destiny 2 API endpoints.

```swift
// Common methods
destinyService.getManifest()
destinyService.searchDestinyPlayer(searchText:)
destinyService.getProfile(membershipType:destinyMembershipId:components:)
destinyService.getCharacter(membershipType:destinyMembershipId:characterId:components:)
destinyService.getItem(membershipType:destinyMembershipId:itemInstanceId:components:)
```

### AuthService

Handles OAuth authentication processes.

```swift
// Key methods
authService.getAuthorizationURL(scopes:state:)
authService.exchangeCode(code:)
authService.refreshToken(refreshToken:)
authService.revokeToken(token:)
```

### ResetService

Utility for determining Destiny 2 reset times.

```swift
// Reset time calculations
resetService.getNextDailyReset()
resetService.getNextWeeklyReset()
resetService.getNextSeasonalReset()
```

### ManifestProvider

Protocol and implementations for managing the Destiny 2 manifest database.

```swift
// Core methods
manifestProvider.needsUpdate(manifestResponse:)
manifestProvider.updateManifest(manifestResponse:locale:progressHandler:)
manifestProvider.getDefinition<T>(hash:definitionType:)
```

## Usage Examples

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
    
    // Access character data
    if let characters = profile.characters?.data {
        for (characterId, character) in characters {
            print("Character: \(character.classType.displayName) - \(character.light) Light")
        }
    }
} catch {
    print("Error getting profile: \(error)")
}
```

### Complete Authentication Flow

```swift
// 1. Generate and store a secure state token
let state = UUID().uuidString
// Store state securely for later verification

// 2. Get the authorization URL and redirect user to it
let authURL = client.authService?.getAuthorizationURL(
    scopes: [.readBasicUserProfile, .readDestinyInventoryAndVault],
    state: state
)
// Open authURL in a browser or WebView

// 3. Handle the callback and exchange code for tokens
func handleCallback(url: URL) async {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
          let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
          let returnedState = components.queryItems?.first(where: { $0.name == "state" })?.value,
          returnedState == state else {
        print("Invalid callback or state mismatch")
        return
    }
    
    do {
        let tokens = try await client.authService?.exchangeCode(code: code)
        // Save tokens.accessToken and tokens.refreshToken securely
        UserDefaults.standard.set(tokens?.refreshToken, forKey: "bungie_refresh_token")
        
        // Update client with the token
        client.setAuthToken(tokens?.accessToken)
    } catch {
        print("Auth error: \(error)")
    }
}

// 4. Refresh token when needed
func refreshTokenIfNeeded() async {
    guard let refreshToken = UserDefaults.standard.string(forKey: "bungie_refresh_token") else {
        return
    }
    
    do {
        let tokens = try await client.authService?.refreshToken(refreshToken: refreshToken)
        // Save new tokens
        UserDefaults.standard.set(tokens?.refreshToken, forKey: "bungie_refresh_token")
        client.setAuthToken(tokens?.accessToken)
    } catch {
        print("Refresh token error: \(error)")
        // Handle expired refresh token by re-authenticating
    }
}
```

### WatchOS Authentication Considerations

When implementing OAuth authentication for watchOS apps, there are important limitations to consider:

```swift
// WatchOS apps cannot implement the standard OAuth flow directly
// This is due to:
// 1. Limited web view capabilities on watchOS
// 2. Bungie's security requirements that discourage using web views for auth

// Instead, delegate authentication to the iOS companion app:

// On watchOS app:
func initiateAuthenticationViaCompanion() {
    // Send a request to the companion iOS app to authenticate
    WCSession.default.sendMessage(["request": "authenticate"], replyHandler: { response in
        if let tokens = response["tokens"] as? [String: String] {
            // Store tokens and configure client
            self.client.setAuthToken(tokens["accessToken"])
        }
    }, errorHandler: { error in
        print("Error communicating with iOS app: \(error.localizedDescription)")
    })
}

// On iOS app:
func handleWatchAuthRequest(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
    // Implement the full OAuth flow on iOS
    // After receiving tokens, send them back to the watch app
    authenticateWithBungie { tokens in
        replyHandler(["tokens": tokens])
    }
}
```

This approach not only addresses technical limitations but also complies with Bungie's security guidelines, which strongly discourage using web views for authentication and may block such implementations.

### Working with the Manifest

```swift
import BungieKitManifest

// Initialize manifest provider
let manifestProvider = GRDBManifestProvider()

// Complete manifest update workflow
func updateManifestIfNeeded() async {
    do {
        // 1. Get the current manifest metadata
        let manifest = try await client.destinyService.getManifest()
        
        // 2. Check if we need to update
        if manifestProvider.needsUpdate(manifestResponse: manifest) {
            print("Downloading new manifest version...")
            
            // 3. Download and process the manifest
            try await manifestProvider.updateManifest(
                manifestResponse: manifest,
                locale: "en"
            ) { progress in
                // Update UI with progress
                print("Download progress: \(Int(progress * 100))%")
            }
            
            print("Manifest updated successfully!")
        } else {
            print("Manifest is already up to date")
        }
    } catch {
        print("Manifest error: \(error.localizedDescription)")
    }
}

// Accessing definitions
func lookupItem(hash: Int) -> String {
    if let itemDef: DestinyInventoryItemDefinition = manifestProvider.getDefinition(
        hash: hash, 
        definitionType: .inventoryItem
    ) {
        return itemDef.displayProperties.name
    }
    return "Unknown Item"
}

// Working with collections of definitions
func getAllWeapons() -> [DestinyInventoryItemDefinition] {
    return manifestProvider.getDefinitions(
        definitionType: .inventoryItem,
        predicate: NSPredicate(format: "itemType == %d", ItemType.weapon.rawValue)
    )
}
```

### Error Handling

```swift
do {
    let profile = try await client.destinyService.getProfile(
        membershipType: .tigerPsn,
        destinyMembershipId: "12345",
        components: [.profiles, .characters]
    )
    // Process profile...
} catch let error as BungieAPIError {
    switch error {
    case .apiError(let errorResponse):
        print("API Error: \(errorResponse.errorStatus) - \(errorResponse.message)")
        
        // Handle specific error codes
        if errorResponse.errorCode == 1601 {
            print("Too many requests, implement backoff")
        } else if errorResponse.errorCode == 2101 {
            print("API key invalid or missing")
        }
        
    case .httpError(let statusCode):
        print("HTTP Error: \(statusCode)")
        
    case .invalidResponse:
        print("Invalid response format")
        
    case .networkError(let underlyingError):
        print("Network error: \(underlyingError.localizedDescription)")
        
    case .jsonDecodingError(let decodingError):
        print("JSON decoding failed: \(decodingError.localizedDescription)")
    }
} catch {
    print("Unknown error: \(error)")
}
```

### Reset Time Calculations

```swift
// Get the next daily reset
let nextDaily = client.resetService.getNextDailyReset()
print("Next daily reset: \(nextDaily)")

// Check if an activity has reset since last check
let lastPlayed = Date(timeIntervalSinceNow: -172800) // 2 days ago
let hasReset = client.resetService.hasResetOccurred(since: lastPlayed, resetType: .weekly)
print("Weekly reset has occurred since last played: \(hasReset)")

// Get time until next reset
let timeUntilReset = client.resetService.timeUntilNextReset(resetType: .seasonal)
let hoursLeft = Int(timeUntilReset / 3600)
print("Time until seasonal reset: \(hoursLeft) hours")
```

## Advanced Usage

### Custom API Requests

```swift
// Make a request to an endpoint not specifically implemented
let path = "/Platform/Destiny2/Armory/Search/DestinyInventoryItemDefinition/scout%20rifle/"
do {
    let response: DestinyEntitySearchResult = try await client.apiService.request(
        method: .get,
        path: path,
        queryItems: [URLQueryItem(name: "page", value: "0")]
    )
    print("Found \(response.results.count) items")
} catch {
    print("Custom request error: \(error)")
}
```

### Working with Components

```swift
// Request multiple components in a single call
let components: [DestinyComponentType] = [
    .profiles,
    .characters,
    .characterInventories,
    .characterEquipment,
    .itemInstances,
    .itemStats
]

do {
    let profile = try await client.destinyService.getProfile(
        membershipType: .tigerPsn,
        destinyMembershipId: "12345",
        components: components
    )
    
    // Access equipped items for a character
    if let characters = profile.characters?.data,
       let characterId = characters.keys.first,
       let equipment = profile.characterEquipment?.data?[characterId]?.items {
        
        for item in equipment {
            print("Equipped item: \(item.itemHash)")
            
            // Get instance details for the item
            if let instance = profile.itemComponents?.instances?.data?[item.itemInstanceId ?? ""] {
                print("Power level: \(instance.primaryStat?.value ?? 0)")
            }
        }
    }
} catch {
    print("Error: \(error)")
}
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This package is available under the MIT license. See the LICENSE file for more info. 
