import Foundation

/// Response from the Destiny 2 Manifest API
public struct DestinyManifestResponse: Codable {
    /// The current version of the manifest
    public let version: String
    
    /// Path to mobile world content files by locale
    public let mobileWorldContentPaths: [String: String]
    
    /// Creates a new DestinyManifestResponse
    /// - Parameters:
    ///   - version: The current version of the manifest
    ///   - mobileWorldContentPaths: Path to mobile world content files by locale
    public init(version: String, mobileWorldContentPaths: [String: String]) {
        self.version = version
        self.mobileWorldContentPaths = mobileWorldContentPaths
    }
    
    /// Gets the URL for the world content for the specified locale
    /// - Parameter locale: The locale to get
    /// - Returns: The URL for the world content, or nil if not found
    public func getWorldContentURL(locale: String) -> URL? {
        guard let path = mobileWorldContentPaths[locale] else {
            return nil
        }
        
        // If the path is a full URL, use it directly
        if path.hasPrefix("http") {
            return URL(string: path)
        }
        
        // Otherwise, assume it's a relative path on the Bungie.net domain
        return URL(string: "https://www.bungie.net\(path)")
    }
} 