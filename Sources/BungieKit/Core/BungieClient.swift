import Foundation
import OSLog

/// Main client for interacting with the Bungie API
public class BungieClient {
    
    /// Configuration options for the Bungie API client
    public struct Configuration {
        /// Your registered Bungie API key
        public let apiKey: String
        /// Your app's OAuth client ID (optional, required for authentication)
        public let clientId: String?
        /// Your app's OAuth client secret (optional, required for authentication)
        public let clientSecret: String?
        /// Base URL for the Bungie API
        public let baseUrl: URL
        /// User agent string to identify your app
        public let userAgent: String
        
        /// Creates a new configuration for the Bungie API client
        /// - Parameters:
        ///   - apiKey: Your registered Bungie API key
        ///   - clientId: Your app's OAuth client ID (optional)
        ///   - clientSecret: Your app's OAuth client secret (optional)
        ///   - baseUrl: Base URL for the Bungie API
        ///   - userAgent: User agent string to identify your app
        public init(
            apiKey: String,
            clientId: String? = nil,
            clientSecret: String? = nil,
            baseUrl: URL = URL(string: "https://www.bungie.net/Platform")!,
            userAgent: String = "BungieKit"
        ) {
            self.apiKey = apiKey
            self.clientId = clientId
            self.clientSecret = clientSecret
            self.baseUrl = baseUrl
            self.userAgent = userAgent
        }
    }
    
    /// The client configuration
    public let configuration: Configuration
    
    /// Service for making API requests
    public let apiService: APIService
    
    /// Service for handling authentication
    public let authService: AuthService?
    
    /// Service for interacting with Destiny 2 API endpoints
    public let destinyService: DestinyService
    
    /// Service for calculating reset times
    public let resetService: ResetService
    
    /// Logger for the client
    private let logger = Logger(subsystem: "BungieKit", category: "BungieClient")
    
    /// Creates a new Bungie API client with the given configuration
    /// - Parameters:
    ///   - configuration: Configuration for the client
    ///   - apiService: Service for making API requests (optional, will create a default one if not provided)
    ///   - authService: Service for handling authentication (optional)
    ///   - destinyService: Service for interacting with Destiny 2 API endpoints (optional)
    ///   - resetService: Service for calculating reset times (optional)
    public init(
        configuration: Configuration,
        apiService: APIService? = nil,
        authService: AuthService? = nil,
        destinyService: DestinyService? = nil,
        resetService: ResetService? = nil
    ) {
        self.configuration = configuration
        
        // Initialize API service
        let apiServiceInstance = apiService ?? DefaultAPIService(configuration: configuration)
        self.apiService = apiServiceInstance
        
        // Initialize auth service if credentials are provided
        if configuration.clientId != nil && configuration.clientSecret != nil {
            self.authService = authService ?? DefaultAuthService(
                configuration: configuration,
                apiService: apiServiceInstance
            )
        } else {
            self.authService = authService
        }
        
        // Initialize Destiny service
        self.destinyService = destinyService ?? DestinyService(apiService: apiServiceInstance)
        
        // Initialize reset service
        self.resetService = resetService ?? ResetService()
        
        logger.info("BungieClient initialized")
    }
    
    /// Creates a basic client with just an API key
    /// - Parameter apiKey: Your registered Bungie API key
    /// - Returns: A configured BungieClient instance
    public static func basic(apiKey: String) -> BungieClient {
        return BungieClient(configuration: Configuration(apiKey: apiKey))
    }
} 