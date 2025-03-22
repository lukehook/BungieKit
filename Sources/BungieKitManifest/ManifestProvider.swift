import Foundation
import OSLog
import BungieKit
import CoreData

/// Protocol for providing Destiny 2 manifest data
public protocol ManifestProvider {
    /// The currently loaded manifest version, if any
    var currentVersion: String? { get }
    
    /// Checks if the manifest needs to be updated
    /// - Parameter manifestResponse: The latest manifest response
    /// - Returns: True if an update is needed, false otherwise
    func needsUpdate(manifestResponse: DestinyManifestResponse) -> Bool
    
    /// Updates the manifest with the latest data
    /// - Parameters:
    ///   - manifestResponse: The latest manifest response
    ///   - locale: The locale to download
    ///   - progressHandler: Optional handler for tracking download progress
    /// - Returns: True if the update succeeded, false otherwise
    func updateManifest(
        manifestResponse: DestinyManifestResponse,
        locale: String,
        progressHandler: ((Double) -> Void)?
    ) async throws -> Bool
    
    /// Gets the definition for the given hash
    /// - Parameters:
    ///   - hash: The definition hash
    ///   - definitionType: The definition type
    /// - Returns: The definition data, or nil if not found
    func getDefinition<T: Decodable>(hash: UInt32, definitionType: DefinitionType) -> T?
}

/// Types of manifest definitions
public enum DefinitionType: String, CaseIterable {
    case inventoryItem = "DestinyInventoryItemDefinition"
    case `class` = "DestinyClassDefinition"
    case race = "DestinyRaceDefinition"
    case gender = "DestinyGenderDefinition"
    case activityMode = "DestinyActivityModeDefinition"
    case activity = "DestinyActivityDefinition"
    case destination = "DestinyDestinationDefinition"
    case place = "DestinyPlaceDefinition"
    case vendor = "DestinyVendorDefinition"
    case talentGrid = "DestinyTalentGridDefinition"
    case statGroup = "DestinyStatGroupDefinition"
    case faction = "DestinyFactionDefinition"
    case season = "DestinySeasonDefinition"
    case seasonPass = "DestinySeasonPassDefinition"
    case collectible = "DestinyCollectibleDefinition"
    case presentationNode = "DestinyPresentationNodeDefinition"
    case record = "DestinyRecordDefinition"
    case lore = "DestinyLoreDefinition"
    case metric = "DestinyMetricDefinition"
    case objective = "DestinyObjectiveDefinition"
    case item = "DestinyItemDefinition"
    case socketType = "DestinySocketTypeDefinition"
    case statDefinition = "DestinyStatDefinition"
    case traitDefinition = "DestinyTraitDefinition"
    case damageType = "DestinyDamageTypeDefinition"
    case power = "DestinyPowerCapDefinition"
    case materialRequirement = "DestinyMaterialRequirementSetDefinition"
}

/// Default implementation of ManifestProvider using CoreData
public class CoreDataManifestProvider: ManifestProvider {
    /// The persistent container for CoreData
    private let persistentContainer: NSPersistentContainer
    
    /// The currently loaded manifest version, if any
    public private(set) var currentVersion: String?
    
    /// Logger for the manifest provider
    private let logger = Logger(subsystem: "BungieKit", category: "ManifestProvider")
    
    /// URL session for downloading manifest files
    private let session: URLSession
    
    /// Creates a new CoreData manifest provider
    /// - Parameters:
    ///   - databaseURL: The URL for storing the CoreData database, or nil to use the default location
    ///   - session: URL session for downloading manifest files
    public init(databaseURL: URL? = nil, session: URLSession = .shared) {
        self.session = session
        
        // Set up CoreData stack
        persistentContainer = NSPersistentContainer(name: "BungieManifest")
        
        if let databaseURL = databaseURL {
            let storeURL = databaseURL.appendingPathComponent("BungieManifest.sqlite")
            let storeDescription = NSPersistentStoreDescription(url: storeURL)
            persistentContainer.persistentStoreDescriptions = [storeDescription]
        }
        
        persistentContainer.loadPersistentStores { [weak self] (storeDescription, error) in
            if let error = error {
                self?.logger.error("Failed to load persistent store: \(error.localizedDescription)")
                return
            }
            
            self?.loadCurrentVersion()
        }
    }
    
    /// Loads the current manifest version from the database
    private func loadCurrentVersion() {
        let context = persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ManifestVersion")
        fetchRequest.fetchLimit = 1
        
        do {
            if let result = try context.fetch(fetchRequest).first as? NSManagedObject,
               let version = result.value(forKey: "version") as? String {
                currentVersion = version
                logger.debug("Loaded manifest version: \(version)")
            }
        } catch {
            logger.error("Failed to load manifest version: \(error.localizedDescription)")
        }
    }
    
    /// Checks if the manifest needs to be updated
    /// - Parameter manifestResponse: The latest manifest response
    /// - Returns: True if an update is needed, false otherwise
    public func needsUpdate(manifestResponse: DestinyManifestResponse) -> Bool {
        guard let currentVersion = currentVersion else {
            return true
        }
        
        return currentVersion != manifestResponse.version
    }
    
    /// Updates the manifest with the latest data
    /// - Parameters:
    ///   - manifestResponse: The latest manifest response
    ///   - locale: The locale to download
    ///   - progressHandler: Optional handler for tracking download progress
    /// - Returns: True if the update succeeded, false otherwise
    public func updateManifest(
        manifestResponse: DestinyManifestResponse,
        locale: String = "en",
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> Bool {
        guard let manifestURL = manifestResponse.getWorldContentURL(locale: locale) else {
            logger.error("Failed to get manifest URL for locale: \(locale)")
            throw ManifestError.invalidLocale
        }
        
        logger.info("Downloading manifest from: \(manifestURL)")
        
        // Download manifest database file
        let (tempURL, _) = try await downloadFile(from: manifestURL, progressHandler: progressHandler)
        
        // Process the downloaded SQLite database and store in CoreData
        try await importManifest(from: tempURL, version: manifestResponse.version)
        
        // Update the current version
        self.currentVersion = manifestResponse.version
        
        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
        
        return true
    }
    
    /// Downloads a file from the given URL with progress reporting
    /// - Parameters:
    ///   - url: The URL to download from
    ///   - progressHandler: Optional handler for tracking download progress
    /// - Returns: A tuple with the temporary file URL and response
    private func downloadFile(
        from url: URL,
        progressHandler: ((Double) -> Void)?
    ) async throws -> (URL, URLResponse) {
        // Create a download request
        let request = URLRequest(url: url)
        
        // Create a temporary file URL
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("tmp")
        
        // Use the basic download API without progress tracking
        let (downloadURL, response) = try await URLSession.shared.download(from: url)
        
        // Move the downloaded file to our temporary URL
        try FileManager.default.moveItem(at: downloadURL, to: tempURL)
        
        // Call progress handler with completion
        progressHandler?(1.0)
        
        return (tempURL, response)
    }
    
    /// Imports the manifest data from the SQLite database into CoreData
    /// - Parameters:
    ///   - fileURL: The URL of the SQLite database
    ///   - version: The manifest version
    private func importManifest(from fileURL: URL, version: String) async throws {
        // This is a placeholder for the actual implementation
        // In a real implementation, you would:
        // 1. Open the SQLite database
        // 2. Import the definitions into CoreData
        // 3. Save the manifest version
        
        // For now, we'll just save the version
        let context = persistentContainer.newBackgroundContext()
        
        try await context.perform {
            // Delete existing version
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ManifestVersion")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.execute(deleteRequest)
            
            // Create new version
            let versionEntity = NSEntityDescription.insertNewObject(forEntityName: "ManifestVersion", into: context)
            versionEntity.setValue(version, forKey: "version")
            
            try context.save()
        }
    }
    
    /// Gets the definition for the given hash
    /// - Parameters:
    ///   - hash: The definition hash
    ///   - definitionType: The definition type
    /// - Returns: The definition data, or nil if not found
    public func getDefinition<T: Decodable>(hash: UInt32, definitionType: DefinitionType) -> T? {
        // This is a placeholder for the actual implementation
        // In a real implementation, you would:
        // 1. Query CoreData for the definition
        // 2. Parse the JSON data
        // 3. Return the parsed object
        
        return nil
    }
}

/// Errors that can occur when working with the manifest
public enum ManifestError: Error {
    /// The requested locale is not available
    case invalidLocale
    /// The manifest download failed
    case downloadFailed
    /// The manifest import failed
    case importFailed
    /// The definition was not found
    case definitionNotFound
} 
