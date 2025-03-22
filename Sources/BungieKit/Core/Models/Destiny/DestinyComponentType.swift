import Foundation

/// Enum for destiny component types to request
/// These are used in many Destiny API requests to specify which components to return
public enum DestinyComponentType: Int, Encodable {
    /// No components
    case none = 0
    
    // Profile components (100-199)
    
    /// Profiles is the most basic component, only relevant when calling GetProfile. This returns basic information about the profile, which is almost nothing: a list of characterIds, some information about the last time you logged in, and that most sobering statistic: how long you've played.
    case profiles = 100
    /// Only applicable for GetProfile, this will return information about receipts for refundable vendor items.
    case vendorReceipts = 101
    /// Asking for this will get you the profile-level inventories, such as your Vault buckets (yeah, the Vault is really inventory buckets located on your Profile)
    case profileInventories = 102
    /// This will get you a summary of items on your Profile that we consider to be "currencies", such as Glimmer.
    case profileCurrencies = 103
    /// This will get you any progression-related information that exists on a Profile-wide level, across all characters.
    case profileProgression = 104
    /// This will get you information about the silver that this profile has on every platform on which it plays.
    case platformSilver = 105
    
    // Character components (200-299)
    
    /// This will get you summary info about each of the characters in the profile.
    case characters = 200
    /// This will get you information about any non-equipped items on the character or character(s) in question, if you're allowed to see it.
    case characterInventories = 201
    /// This will get you information about the progression (faction, experience, etc...) of the character(s).
    case characterProgressions = 202
    /// This will get you just enough information to be able to render the character(s) in 3D if you have rendering capabilities.
    case characterRenderData = 203
    /// This will return info about activities that a user can see and gating on it.
    case characterActivities = 204
    /// This will return info about the equipped items on the character(s).
    case characterEquipment = 205
    /// This will return info about the loadouts of the character(s).
    case characterLoadouts = 206
    
    // Item components (300-399)
    
    /// This will return basic info about instanced items - whether they can be equipped, their tracked status, and some info commonly needed in many places.
    case itemInstances = 300
    /// Items can have objectives (DestinyObjectiveDefinition) that are represented as quests, human readable flags, or whatever. This will return info about objectives for the item.
    case itemObjectives = 301
    /// Items can have perks (DestinyPerkDefinition). This will return info about perks for the item.
    case itemPerks = 302
    /// Items can have renderable stats, such as Attack, Defense etc... This will return info about stats for the item.
    case itemRenderData = 303
    /// Items can have stats, such as Attack, Defense etc... This will return info about stats for the item.
    case itemStats = 304
    /// Items can have sockets, where plugs can be inserted. This will return info about the sockets for the item.
    case itemSockets = 305
    /// Items can have talent grids, though that's mostly a D1 feature.
    case itemTalentGrids = 306
    /// Items that can be equipped have an "Plug" of the item that is provided by the item. This will return info about the plug for the item.
    case itemCommonData = 307
    /// Items that can be equipped have a "plug" with reusable plug data.
    case itemPlugStates = 308
    /// Items that can have reusable plugs can return objectives associated with those plugs.
    case itemPlugObjectives = 309
    /// Information about the Reusable Plugs for the item.
    case itemReusablePlugs = 310
    /// Information about objectives for Pursuit-type items.
    case itemUninstancedItemObjectives = 311
    
    // Vendor components (400-499)
    
    /// When obtaining vendor information, this will return information about the vendor.
    case vendors = 400
    /// When obtaining vendor information, this will return information about the categories of items provided by the vendor.
    case vendorCategories = 401
    /// When obtaining vendor information, this will return information about the categories and items available from the vendor.
    case vendorSales = 402
    
    // Profile-wide components (500-599)
    
    /// Returns summary information about the kiosks in the Destiny game world.
    case kiosks = 500
    /// Returns information about instanced Destiny Items available (across all characters, and the shared inventory)
    case currencyLookups = 600
    /// Returns summary info about presentation nodes for a Profile.
    case presentationNodes = 700
    /// Returns summary info about Records for a Profile.
    case records = 800
    /// Returns summary info about collectibles for a Profile.
    case collectibles = 900
    /// Returns information about tracked titles for a Profile.
    case transitory = 1000
    /// Returns summary information about the craftable items for the provided Destiny Profile.
    case metrics = 1100
    /// Returns a profile's string variables.
    case stringVariables = 1200
    /// Returns a profile's craftables information.
    case craftables = 1300
    /// Returns a profile's social commendations.
    case socialCommendations = 1400
} 