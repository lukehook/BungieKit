import Foundation
import OSLog

/// Protocol for authentication with the Bungie API
public protocol AuthService {
    /// Gets the authorization URL for the given scopes
    /// - Parameters:
    ///   - scopes: The requested OAuth scopes
    ///   - state: A state string to verify the callback
    /// - Returns: The authorization URL
    func getAuthorizationURL(scopes: [OAuthScope], state: String) -> URL
    
    /// Exchanges an authorization code for access and refresh tokens
    /// - Parameter code: The authorization code from the callback
    /// - Returns: The token response
    func exchangeCode(code: String) async throws -> TokenResponse
    
    /// Refreshes an access token using a refresh token
    /// - Parameter refreshToken: The refresh token
    /// - Returns: The new token response
    func refreshToken(refreshToken: String) async throws -> TokenResponse
}

/// Default implementation of AuthService
public class DefaultAuthService: AuthService {
    /// Configuration for the auth service
    private let configuration: BungieClient.Configuration
    
    /// API service for making requests
    private let apiService: APIService
    
    /// Logger for auth service
    private let logger = Logger(subsystem: "BungieKit", category: "AuthService")
    
    /// Creates a new auth service with the given configuration
    /// - Parameters:
    ///   - configuration: Configuration for the client
    ///   - apiService: API service for making requests
    public init(configuration: BungieClient.Configuration, apiService: APIService) {
        self.configuration = configuration
        self.apiService = apiService
        
        guard configuration.clientId != nil, configuration.clientSecret != nil else {
            logger.warning("AuthService initialized without client ID or secret")
            return
        }
    }
    
    /// Gets the authorization URL for the given scopes
    /// - Parameters:
    ///   - scopes: The requested OAuth scopes
    ///   - state: A state string to verify the callback
    /// - Returns: The authorization URL
    public func getAuthorizationURL(scopes: [OAuthScope], state: String) -> URL {
        guard let clientId = configuration.clientId else {
            fatalError("Cannot create authorization URL without client ID")
        }
        
        var components = URLComponents(string: "https://www.bungie.net/en/OAuth/Authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "state", value: state)
        ]
        
        if !scopes.isEmpty {
            let scopesString = scopes.map { $0.rawValue }.joined(separator: " ")
            components.queryItems?.append(URLQueryItem(name: "scope", value: scopesString))
        }
        
        return components.url!
    }
    
    /// Exchanges an authorization code for access and refresh tokens
    /// - Parameter code: The authorization code from the callback
    /// - Returns: The token response
    public func exchangeCode(code: String) async throws -> TokenResponse {
        guard let clientId = configuration.clientId, let clientSecret = configuration.clientSecret else {
            throw AuthError.missingCredentials
        }
        
        let body = TokenRequest(
            grantType: "authorization_code",
            code: code,
            clientId: clientId,
            clientSecret: clientSecret
        )
        
        return try await apiService.request(
            endpoint: "App/OAuth/Token/",
            method: .post,
            body: body,
            queryItems: nil,
            accessToken: nil,
            responseType: TokenResponse.self
        )
    }
    
    /// Refreshes an access token using a refresh token
    /// - Parameter refreshToken: The refresh token
    /// - Returns: The new token response
    public func refreshToken(refreshToken: String) async throws -> TokenResponse {
        guard let clientId = configuration.clientId, let clientSecret = configuration.clientSecret else {
            throw AuthError.missingCredentials
        }
        
        let body = TokenRequest(
            grantType: "refresh_token",
            refreshToken: refreshToken,
            clientId: clientId,
            clientSecret: clientSecret
        )
        
        return try await apiService.request(
            endpoint: "App/OAuth/Token/",
            method: .post,
            body: body,
            queryItems: nil,
            accessToken: nil,
            responseType: TokenResponse.self
        )
    }
}

/// OAuth scopes for Bungie API
public enum OAuthScope: String {
    case readBasicUserProfile = "ReadBasicUserProfile"
    case readGroups = "ReadGroups"
    case writeGroups = "WriteGroups"
    case adminGroups = "AdminGroups"
    case moveEquipDestinyItems = "MoveEquipDestinyItems"
    case readDestinyInventoryAndVault = "ReadDestinyInventoryAndVault"
    case readUserData = "ReadUserData"
    case editUserData = "EditUserData"
    case readAndApplyTokens = "ReadAndApplyTokens"
    case advancedWriteActions = "AdvancedWriteActions"
}

/// Request body for token requests
struct TokenRequest: Encodable {
    let grantType: String
    let code: String?
    let refreshToken: String?
    let clientId: String
    let clientSecret: String
    
    init(
        grantType: String,
        code: String? = nil,
        refreshToken: String? = nil,
        clientId: String,
        clientSecret: String
    ) {
        self.grantType = grantType
        self.code = code
        self.refreshToken = refreshToken
        self.clientId = clientId
        self.clientSecret = clientSecret
    }
}

/// Response from token requests
public struct TokenResponse: Decodable {
    /// The access token
    public let accessToken: String
    /// The token type (e.g. "Bearer")
    public let tokenType: String
    /// The expiration time in seconds
    public let expiresIn: Int
    /// The refresh token
    public let refreshToken: String
    /// The refresh token expiration time in seconds
    public let refreshExpiresIn: Int
    /// The membership ID of the authenticated user
    public let membershipId: String
    
    /// Estimated date when the token will expire
    public var estimatedExpirationDate: Date {
        return Date().addingTimeInterval(TimeInterval(expiresIn))
    }
    
    /// Estimated date when the refresh token will expire
    public var estimatedRefreshExpirationDate: Date {
        return Date().addingTimeInterval(TimeInterval(refreshExpiresIn))
    }
}

/// Errors that can occur during authentication
public enum AuthError: Error {
    /// The client ID or secret is missing
    case missingCredentials
    /// The authorization code is invalid
    case invalidAuthorizationCode
    /// The token is invalid
    case invalidToken
    /// The refresh token is invalid
    case invalidRefreshToken
} 