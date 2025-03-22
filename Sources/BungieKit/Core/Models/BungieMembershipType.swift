import Foundation

/// The types of membership the Bungie system supports
/// This is the external facing enum used to distinguish between types of accounts
public enum BungieMembershipType: Int, Codable {
    /// None
    case none = 0
    /// TigerXbox (Xbox Live)
    case tigerXbox = 1
    /// TigerPsn (PlayStation Network)
    case tigerPsn = 2
    /// TigerSteam (Steam)
    case tigerSteam = 3
    /// TigerBlizzard (Battle.net)
    case tigerBlizzard = 4
    /// TigerStadia (Google Stadia)
    case tigerStadia = 5
    /// TigerEgs (Epic Games Store)
    case tigerEgs = 6
    /// TigerDemon
    case tigerDemon = 10
    /// BungieNext (Bungie.net)
    case bungieNext = 254
    /// All (not a real membership type, used for queries)
    case all = -1
    
    public var displayName: String {
        switch self {
        case .none:
            return "None"
        case .tigerXbox:
            return "Xbox"
        case .tigerPsn:
            return "PlayStation"
        case .tigerSteam:
            return "Steam"
        case .tigerBlizzard:
            return "Battle.net"
        case .tigerStadia:
            return "Stadia"
        case .tigerEgs:
            return "Epic Games"
        case .tigerDemon:
            return "Demon"
        case .bungieNext:
            return "Bungie.net"
        case .all:
            return "All"
        }
    }
} 