# BungieKitManifest

This module provides a manifest provider for Destiny 2 definitions using GRDB.swift.

## Overview

The BungieKitManifest module is responsible for:

1. Downloading the Destiny 2 manifest from Bungie.net
2. Extracting and storing the manifest data in a SQLite database
3. Providing access to the definitions through a simple API

## Implementation

The manifest provider uses GRDB.swift to interact with the SQLite database that stores the Destiny 2 definitions. The implementation follows these steps:

1. Download the manifest ZIP file from Bungie.net
2. Extract the SQLite database using ZIPFoundation
3. Import the definitions from the extracted database into our own database
4. Provide access to the definitions through the `getDefinition` method

## Usage

```swift
// Create the manifest provider
let manifestProvider = GRDBManifestProvider()

// Get the latest manifest from Bungie.net
let client = BungieClient(apiKey: "YOUR_API_KEY")
let manifestResponse = try await client.destiny2.getManifest()

// Check if the manifest needs to be updated
if manifestProvider.needsUpdate(manifestResponse: manifestResponse) {
    // Update the manifest
    try await manifestProvider.updateManifest(
        manifestResponse: manifestResponse,
        locale: "en",
        progressHandler: { progress in
            print("Download progress: \(progress * 100)%")
        }
    )
}

// Get a definition from the manifest
let itemDefinition: DestinyInventoryItemDefinition? = manifestProvider.getDefinition(
    hash: 1234567890,
    definitionType: .inventoryItem
)
```

## Database Structure

The manifest database uses the following structure:

- A `manifest_version` table to store the current version
- A table for each definition type (e.g., `DestinyInventoryItemDefinition`)
- Each definition table has `id` and `json` columns
- Indices are created on the `id` columns for efficient lookups 