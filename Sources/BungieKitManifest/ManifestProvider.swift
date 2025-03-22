import Foundation
import OSLog
import BungieKit
import GRDB
import ZIPFoundation

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

/// Information about the manifest version
struct ManifestVersionRecord: Codable, FetchableRecord, PersistableRecord {
    var version: String
    
    // Table name
    static let databaseTableName = "manifest_version"
}

/// Definition record for storing Destiny definitions
struct DefinitionRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64 // Hash (as signed int64)
    var json: Data // JSON data
    var tableName: String // The table name (not used in records, but for constructing the table name)
    
    // Custom table name based on definition type
    static func databaseTableName(for definitionType: DefinitionType) -> String {
        return definitionType.rawValue
    }
    
    // Table creation SQL for a specific definition type
    static func tableCreationSQL(for definitionType: DefinitionType) -> String {
        return """
        CREATE TABLE IF NOT EXISTS \(databaseTableName(for: definitionType)) (
            id INTEGER PRIMARY KEY,
            json BLOB NOT NULL
        )
        """
    }
    
    // Create an index on the id column
    static func createIndexSQL(for definitionType: DefinitionType) -> String {
        return """
        CREATE INDEX IF NOT EXISTS idx_\(databaseTableName(for: definitionType))_id 
        ON \(databaseTableName(for: definitionType)) (id)
        """
    }
}

/// Default implementation of ManifestProvider using GRDB
public class GRDBManifestProvider: ManifestProvider {
    /// Database connection
    private var dbQueue: DatabaseQueue?
    
    /// The path to the database file
    private let databasePath: URL
    
    /// The currently loaded manifest version, if any
    public private(set) var currentVersion: String?
    
    /// Logger for the manifest provider
    private let logger = Logger(subsystem: "BungieKit", category: "ManifestProvider")
    
    /// URL session for downloading manifest files
    private let session: URLSession
    
    /// Creates a new GRDB manifest provider
    /// - Parameters:
    ///   - databaseURL: The URL for storing the database, or nil to use the default location
    ///   - session: URL session for downloading manifest files
    public init(databaseURL: URL? = nil, session: URLSession = .shared) {
        self.session = session
        
        // Determine database path
        if let databaseURL = databaseURL {
            self.databasePath = databaseURL.appendingPathComponent("BungieManifest.sqlite")
        } else {
            // Use the app support directory by default
            let fileManager = FileManager.default
            let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let bundleID = Bundle.main.bundleIdentifier ?? "com.bungiekit"
            let dbDir = appSupportURL.appendingPathComponent(bundleID, isDirectory: true)
            
            // Create directory if it doesn't exist
            if !fileManager.fileExists(atPath: dbDir.path) {
                try? fileManager.createDirectory(at: dbDir, withIntermediateDirectories: true)
            }
            
            self.databasePath = dbDir.appendingPathComponent("BungieManifest.sqlite")
        }
        
        // Set up database
        setupDatabase()
    }
    
    /// Sets up the database connection and schema
    private func setupDatabase() {
        do {
            // Create a database connection
            dbQueue = try DatabaseQueue(path: databasePath.path)
            
            // Migrate the database
            try dbQueue?.write { db in
                // Create version table
                try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS manifest_version (
                    version TEXT NOT NULL
                )
                """)
                
                // No need to create definition tables yet - they'll be created when needed
            }
            
            // Load the current version
            loadCurrentVersion()
            
        } catch {
            logger.error("Failed to setup database: \(error.localizedDescription)")
        }
    }
    
    /// Loads the current manifest version from the database
    private func loadCurrentVersion() {
        do {
            try dbQueue?.read { db in
                if let versionRecord = try ManifestVersionRecord.fetchOne(db) {
                    currentVersion = versionRecord.version
                    logger.debug("Loaded manifest version: \(versionRecord.version)")
                }
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
        
        // Download manifest database file (zip file)
        let (zipURL, _) = try await downloadFile(from: manifestURL, progressHandler: progressHandler)
        
        // Extract the SQLite database from the zip file
        let dbURL = try extractDatabase(from: zipURL)
        
        // Process the extracted SQLite database
        try await importManifest(from: dbURL, version: manifestResponse.version)
        
        // Update the current version
        self.currentVersion = manifestResponse.version
        
        // Clean up
        try? FileManager.default.removeItem(at: zipURL)
        try? FileManager.default.removeItem(at: dbURL)
        
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
        // Create a temporary file URL
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("zip")
        
        // Use the basic download API
        let (downloadURL, response) = try await session.download(from: url)
        
        // Move the downloaded file to our temporary URL
        try FileManager.default.moveItem(at: downloadURL, to: tempURL)
        
        // Call progress handler with completion
        progressHandler?(1.0)
        
        return (tempURL, response)
    }
    
    /// Extracts the SQLite database from the downloaded zip file
    /// - Parameter zipURL: The URL of the zip file
    /// - Returns: The URL of the extracted SQLite database
    private func extractDatabase(from zipURL: URL) throws -> URL {
        let fileManager = FileManager.default
        
        // Create a temporary directory for extraction
        let extractionDir = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: extractionDir, withIntermediateDirectories: true)
        
        // Extract using ZIPFoundation
        let archive = try Archive(url: zipURL, accessMode: .read)
        
        // Find the first entry in the archive (should be the SQLite file)
        var firstEntry: Entry? = nil
        for entry in archive {
            firstEntry = entry
            break
        }
        
        guard let entry = firstEntry else {
            throw ManifestError.importFailed
        }
        
        // Extract to the temporary directory
        let dbURL = extractionDir.appendingPathComponent("world_sql_content.db")
        _ = try archive.extract(entry, to: dbURL)
        
        return dbURL
    }
    
    /// Imports the manifest data from the SQLite database
    /// - Parameters:
    ///   - fileURL: The URL of the SQLite database
    ///   - version: The manifest version
    private func importManifest(from fileURL: URL, version: String) async throws {
        guard let dbQueue = dbQueue else {
            throw ManifestError.importFailed
        }
        
        // Create a new database connection to the source SQLite file
        let sourceDB = try DatabaseQueue(path: fileURL.path)
        
        // Get the list of all tables in the source database that represent definitions
        let definitionTables = try await sourceDB.read { db -> [String] in
            // Query the SQLite master table to get all tables
            let tables = try String.fetchAll(db, sql: "SELECT name FROM sqlite_master WHERE type='table'")
            // Filter to include only definition tables
            return tables.filter { 
                return $0.hasPrefix("Destiny") && $0.hasSuffix("Definition") 
            }
        }
        
        // Start a transaction to import all data
        try await dbQueue.write { db in
            // Delete existing version
            try db.execute(sql: "DELETE FROM manifest_version")
            
            // Insert new version
            let versionRecord = ManifestVersionRecord(version: version)
            try versionRecord.insert(db)
            
            // Process each definition table
            for tableName in definitionTables {
                // Check if this is a definition type we support
                guard let definitionType = DefinitionType.allCases.first(where: { $0.rawValue == tableName }) else {
                    continue
                }
                
                // Create the table if it doesn't exist
                try db.execute(sql: DefinitionRecord.tableCreationSQL(for: definitionType))
                
                // Create an index for faster lookups
                try db.execute(sql: DefinitionRecord.createIndexSQL(for: definitionType))
                
                // Delete existing definitions
                try db.execute(sql: "DELETE FROM \(DefinitionRecord.databaseTableName(for: definitionType))")
                
                // Get records from source database
                let records = try sourceDB.read { sourceDb -> [(Int64, Data)] in
                    var records: [(Int64, Data)] = []
                    let rows = try Row.fetchCursor(sourceDb, sql: "SELECT id, json FROM \(tableName)")
                    while let row = try rows.next() {
                        let id = row["id"] as Int64
                        let json = row["json"] as Data
                        records.append((id, json))
                    }
                    return records
                }
                
                // Insert records into the destination database
                for (id, json) in records {
                    try db.execute(
                        sql: "INSERT INTO \(DefinitionRecord.databaseTableName(for: definitionType)) (id, json) VALUES (?, ?)",
                        arguments: [id, json]
                    )
                }
            }
        }
    }
    
    /// Gets the definition for the given hash
    /// - Parameters:
    ///   - hash: The definition hash
    ///   - definitionType: The definition type
    /// - Returns: The definition data, or nil if not found
    public func getDefinition<T: Decodable>(hash: UInt32, definitionType: DefinitionType) -> T? {
        guard let dbQueue = dbQueue else {
            return nil
        }
        
        do {
            // Convert hash to signed int64 (SQLite stores integers as signed)
            let id = Int64(bitPattern: UInt64(hash) & 0xFFFFFFFF)
            
            // Get the definition JSON from the database
            return try dbQueue.read { db -> T? in
                if let data = try Data.fetchOne(
                    db,
                    sql: "SELECT json FROM \(DefinitionRecord.databaseTableName(for: definitionType)) WHERE id = ?",
                    arguments: [id]
                ) {
                    // Decode the JSON data
                    return try JSONDecoder().decode(T.self, from: data)
                }
                return nil
            }
        } catch {
            logger.error("Failed to get definition: \(error.localizedDescription)")
            return nil
        }
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
