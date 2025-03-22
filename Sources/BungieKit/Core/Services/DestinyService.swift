import Foundation
import OSLog

/// Service for interacting with Destiny 2 API endpoints
public class DestinyService {
    /// The API service for making requests
    private let apiService: APIService
    
    /// Logger for Destiny service
    private let logger = Logger(subsystem: "BungieKit", category: "DestinyService")
    
    /// Creates a new Destiny service
    /// - Parameter apiService: The API service for making requests
    public init(apiService: APIService) {
        self.apiService = apiService
    }
    
    /// Gets the current Destiny 2 manifest
    /// - Returns: The manifest response
    public func getManifest() async throws -> DestinyManifestResponse {
        logger.debug("Getting Destiny manifest")
        return try await apiService.request(
            endpoint: "Destiny2/Manifest/",
            method: .get,
            body: nil,
            queryItems: nil,
            accessToken: nil,
            responseType: DestinyManifestResponse.self
        )
    }
    
    /// Gets a Destiny profile
    /// - Parameters:
    ///   - membershipType: The membership type
    ///   - destinyMembershipId: The Destiny membership ID
    ///   - components: The components to include in the response
    ///   - accessToken: Optional access token for private data
    /// - Returns: The profile response
    public func getProfile(
        membershipType: BungieMembershipType,
        destinyMembershipId: String,
        components: [DestinyComponentType],
        accessToken: String? = nil
    ) async throws -> DestinyProfileResponse {
        logger.debug("Getting profile for \(membershipType.rawValue)/\(destinyMembershipId)")
        
        let componentParams = components.map { String($0.rawValue) }.joined(separator: ",")
        let queryItems = [URLQueryItem(name: "components", value: componentParams)]
        
        return try await apiService.request(
            endpoint: "Destiny2/\(membershipType.rawValue)/Profile/\(destinyMembershipId)/",
            method: .get,
            body: nil,
            queryItems: queryItems,
            accessToken: accessToken,
            responseType: DestinyProfileResponse.self
        )
    }
    
    /// Gets a Destiny character
    /// - Parameters:
    ///   - membershipType: The membership type
    ///   - destinyMembershipId: The Destiny membership ID
    ///   - characterId: The character ID
    ///   - components: The components to include in the response
    ///   - accessToken: Optional access token for private data
    /// - Returns: The character response
    public func getCharacter(
        membershipType: BungieMembershipType,
        destinyMembershipId: String,
        characterId: String,
        components: [DestinyComponentType],
        accessToken: String? = nil
    ) async throws -> DestinyCharacterResponse {
        logger.debug("Getting character \(characterId) for \(membershipType.rawValue)/\(destinyMembershipId)")
        
        let componentParams = components.map { String($0.rawValue) }.joined(separator: ",")
        let queryItems = [URLQueryItem(name: "components", value: componentParams)]
        
        return try await apiService.request(
            endpoint: "Destiny2/\(membershipType.rawValue)/Profile/\(destinyMembershipId)/Character/\(characterId)/",
            method: .get,
            body: nil,
            queryItems: queryItems,
            accessToken: accessToken,
            responseType: DestinyCharacterResponse.self
        )
    }
    
    /// Searches for Destiny players by name
    /// - Parameters:
    ///   - searchText: The player name to search for
    ///   - page: The page number (0-based)
    /// - Returns: The search response
    public func searchDestinyPlayer(
        searchText: String,
        page: Int = 0
    ) async throws -> [UserInfoCard] {
        logger.debug("Searching for player: \(searchText)")
        
        let queryItems = [
            URLQueryItem(name: "displayNamePrefix", value: searchText),
            URLQueryItem(name: "page", value: String(page))
        ]
        
        return try await apiService.request(
            endpoint: "Destiny2/SearchDestinyPlayerByBungieName/",
            method: .post,
            body: ["displayName": searchText, "displayNameCode": "0"],
            queryItems: queryItems,
            accessToken: nil,
            responseType: [UserInfoCard].self
        )
    }
    
    /// Gets item details
    /// - Parameters:
    ///   - membershipType: The membership type
    ///   - destinyMembershipId: The Destiny membership ID
    ///   - itemInstanceId: The item instance ID
    ///   - components: The components to include in the response
    ///   - accessToken: Optional access token for private data
    /// - Returns: The item response
    public func getItem(
        membershipType: BungieMembershipType,
        destinyMembershipId: String,
        itemInstanceId: String,
        components: [DestinyComponentType],
        accessToken: String? = nil
    ) async throws -> DestinyItemResponse {
        logger.debug("Getting item \(itemInstanceId) for \(membershipType.rawValue)/\(destinyMembershipId)")
        
        let componentParams = components.map { String($0.rawValue) }.joined(separator: ",")
        let queryItems = [URLQueryItem(name: "components", value: componentParams)]
        
        return try await apiService.request(
            endpoint: "Destiny2/\(membershipType.rawValue)/Profile/\(destinyMembershipId)/Item/\(itemInstanceId)/",
            method: .get,
            body: nil,
            queryItems: queryItems,
            accessToken: accessToken,
            responseType: DestinyItemResponse.self
        )
    }
    
    /// Gets the current user's clan information
    /// - Parameter accessToken: The access token
    /// - Returns: The clan response
    public func getClanMemberships(
        accessToken: String
    ) async throws -> GroupUserInfoCard {
        logger.debug("Getting clan memberships")
        
        let response = try await apiService.request(
            endpoint: "GroupV2/GetGroupsForMember/",
            method: .get,
            body: nil,
            queryItems: nil,
            accessToken: accessToken,
            responseType: GetGroupsForMemberResponse.self
        )
        
        guard let results = response.results.first else {
            throw DestinyServiceError.noClanFound
        }
        
        return results.member
    }
}

/// Response from the Destiny manifest endpoint
public struct DestinyManifestResponse: Decodable {
    /// The version of the manifest
    public let version: String
    /// Mobile asset content paths by locale
    public let mobileAssetContentPath: String
    /// Mobile gear asset data bases by locale
    public let mobileGearAssetDataBases: [GearAssetDataBaseDefinition]
    /// Mobile world content paths by locale
    public let mobileWorldContentPaths: [String: String]
    /// JSON world content paths by locale
    public let jsonWorldContentPaths: [String: String]
    /// Content paths by locale
    public let jsonWorldComponentContentPaths: [String: [String: String]]
    
    /// Gets the URL for the world content database for the given locale
    /// - Parameter locale: The locale
    /// - Returns: The URL
    public func getWorldContentURL(locale: String = "en") -> URL? {
        guard let path = mobileWorldContentPaths[locale] else {
            return nil
        }
        
        return URL(string: "https://www.bungie.net\(path)")
    }
}

/// Definition for a gear asset database
public struct GearAssetDataBaseDefinition: Decodable {
    /// The version
    public let version: Int
    /// The path
    public let path: String
}

/// Response from the get profile endpoint
public struct DestinyProfileResponse: Decodable {
    /// Profile data
    public let profile: ProfileResponse?
    /// Characters data
    public let characters: CharactersResponse?
    /// Character inventory data
    public let characterInventories: InventoriesResponse?
    /// Character equipment data
    public let characterEquipment: EquipmentResponse?
    /// Item components data
    public let itemComponents: ItemComponentsResponse?
    /// Character progressions data
    public let characterProgressions: ProgressionsResponse?
    /// Character activities data
    public let characterActivities: ActivitiesResponse?
    /// Profile inventory data
    public let profileInventory: InventoryResponse?
    /// Profile currencies data
    public let profileCurrencies: CurrenciesResponse?
    /// Profile progression data
    public let profileProgression: ProfileProgressionResponse?
    /// Character loadouts data
    public let characterLoadouts: LoadoutsResponse?
}

/// Response components need to be defined based on the actual API response structure
/// These are placeholders that you'll need to fill in with the actual structures
public struct ProfileResponse: Decodable {}
public struct CharactersResponse: Decodable {}
public struct InventoriesResponse: Decodable {}
public struct EquipmentResponse: Decodable {}
public struct ItemComponentsResponse: Decodable {}
public struct ProgressionsResponse: Decodable {}
public struct ActivitiesResponse: Decodable {}
public struct InventoryResponse: Decodable {}
public struct CurrenciesResponse: Decodable {}
public struct ProfileProgressionResponse: Decodable {}
public struct LoadoutsResponse: Decodable {}

/// Response from the get character endpoint
public struct DestinyCharacterResponse: Decodable {
    // Character data
    public let character: CharacterResponse?
    // Inventory data
    public let inventory: InventoryDataResponse?
    // Equipment data
    public let equipment: EquipmentDataResponse?
}

/// Character response components need to be defined based on the actual API response structure
/// These are placeholders that you'll need to fill in with the actual structures
public struct CharacterResponse: Decodable {}
public struct InventoryDataResponse: Decodable {}
public struct EquipmentDataResponse: Decodable {}

/// Response from the get item endpoint
public struct DestinyItemResponse: Decodable {
    // Item data
    public let item: ItemDataResponse?
    // Instance data
    public let instance: ItemInstanceResponse?
    // Stats data
    public let stats: ItemStatsResponse?
    // Perks data
    public let perks: ItemPerksResponse?
}

/// Item response components need to be defined based on the actual API response structure
/// These are placeholders that you'll need to fill in with the actual structures
public struct ItemDataResponse: Decodable {}
public struct ItemInstanceResponse: Decodable {}
public struct ItemStatsResponse: Decodable {}
public struct ItemPerksResponse: Decodable {}

/// Response from the search players endpoint
public struct UserInfoCard: Decodable {
    /// The Bungie.net membership ID
    public let membershipId: String
    /// The display name
    public let displayName: String?
    /// The display name code
    public let displayNameCode: Int?
    /// The Bungie Global Display Name
    public let bungieGlobalDisplayName: String?
    /// The Bungie Global Display Name Code
    public let bungieGlobalDisplayNameCode: Int?
    /// The membership type
    public let membershipType: BungieMembershipType
    /// The icon path
    public let iconPath: String?
    /// The cross save override type
    public let crossSaveOverride: BungieMembershipType
    /// The applicable membership types
    public let applicableMembershipTypes: [BungieMembershipType]
    /// Whether this is a public account
    public let isPublic: Bool
    /// The last seen date
    public let dateLastPlayed: Date?
}

/// Response from the get clan memberships endpoint
public struct GetGroupsForMemberResponse: Decodable {
    /// The results
    public let results: [GroupMembership]
    /// The total results
    public let totalResults: Int
}

/// Group membership
public struct GroupMembership: Decodable {
    /// The member
    public let member: GroupUserInfoCard
    /// The group
    public let group: GroupResponse
}

/// Group response
public struct GroupResponse: Decodable {
    /// The group ID
    public let groupId: String
    /// The name
    public let name: String
    /// The group type
    public let groupType: Int
    /// The creation date
    public let creationDate: Date
    /// The about text
    public let about: String?
}

/// Group user info card
public struct GroupUserInfoCard: Decodable {
    /// The Bungie.net membership ID
    public let membershipId: String?
    /// The display name
    public let displayName: String?
    /// The Bungie Global Display Name
    public let bungieGlobalDisplayName: String?
    /// The Bungie Global Display Name Code
    public let bungieGlobalDisplayNameCode: Int?
    /// The Destiny membership ID
    public let destinyMembershipId: String?
    /// The membership type
    public let destinyMembershipType: BungieMembershipType?
    /// The membership type
    public let membershipType: BungieMembershipType?
    /// The icon path
    public let iconPath: String?
    /// The cross save override type
    public let crossSaveOverride: BungieMembershipType?
    /// The applicable membership types
    public let applicableMembershipTypes: [BungieMembershipType]?
    /// Whether this is a public account
    public let isPublic: Bool?
    /// The member type
    public let memberType: Int?
    /// The join date
    public let joinDate: Date?
}

/// Errors that can occur when using the Destiny service
public enum DestinyServiceError: Error {
    /// No clan was found for the user
    case noClanFound
} 