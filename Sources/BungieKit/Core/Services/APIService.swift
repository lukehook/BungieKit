import Foundation
import OSLog

/// Protocol for making requests to the Bungie API
public protocol APIService {
    /// Makes a request to the Bungie API
    /// - Parameters:
    ///   - endpoint: The API endpoint path
    ///   - method: HTTP method
    ///   - body: Optional request body
    ///   - queryItems: Optional query parameters
    ///   - accessToken: Optional OAuth access token
    ///   - responseType: The expected response type
    /// - Returns: The decoded response, or throws an error if the request fails
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable?,
        queryItems: [URLQueryItem]?,
        accessToken: String?,
        responseType: T.Type
    ) async throws -> T
}

/// Default implementation of APIService
public class DefaultAPIService: APIService {
    /// Configuration for the API service
    private let configuration: BungieClient.Configuration
    
    /// URL session for making HTTP requests
    private let session: URLSession
    
    /// Logger for API requests
    private let logger = Logger(subsystem: "BungieKit", category: "APIService")
    
    /// Creates a new API service with the given configuration
    /// - Parameters:
    ///   - configuration: Configuration for the client
    ///   - session: URL session for making HTTP requests
    public init(configuration: BungieClient.Configuration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }
    
    /// Makes a request to the Bungie API
    /// - Parameters:
    ///   - endpoint: The API endpoint path
    ///   - method: HTTP method
    ///   - body: Optional request body
    ///   - queryItems: Optional query parameters
    ///   - accessToken: Optional OAuth access token
    ///   - responseType: The expected response type
    /// - Returns: The decoded response, or throws an error if the request fails
    public func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil,
        accessToken: String? = nil,
        responseType: T.Type
    ) async throws -> T {
        var components = URLComponents(url: configuration.baseUrl.appendingPathComponent(endpoint), resolvingAgainstBaseURL: true)
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            logger.error("Invalid URL: \(endpoint)")
            throw BungieAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Add headers
        request.addValue(configuration.apiKey, forHTTPHeaderField: "X-API-Key")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(configuration.userAgent, forHTTPHeaderField: "User-Agent")
        
        if let accessToken = accessToken {
            request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        // Add body if provided
        if let body = body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(body)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BungieAPIError.invalidResponse
            }
            
            logger.debug("API Response: \(httpResponse.statusCode) for \(endpoint)")
            
            // Check for successful status code
            guard (200...299).contains(httpResponse.statusCode) else {
                throw handleErrorResponse(data: data, statusCode: httpResponse.statusCode)
            }
            
            do {
                // Parse the Bungie API response
                let bungieResponse = try parseResponseData(data: data, responseType: responseType)
                return bungieResponse
            } catch {
                logger.error("Failed to decode response: \(error)")
                throw BungieAPIError.decodingError(error)
            }
        } catch let error as BungieAPIError {
            throw error
        } catch {
            logger.error("Network error: \(error)")
            throw BungieAPIError.networkError(error)
        }
    }
    
    /// Parses the response data from the Bungie API
    /// - Parameters:
    ///   - data: The response data
    ///   - responseType: The expected response type
    /// - Returns: The decoded response
    private func parseResponseData<T: Decodable>(data: Data, responseType: T.Type) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        if responseType == Data.self {
            // If the caller just wants the raw data, return it
            return data as! T
        }
        
        // Try to decode as a BungieResponse first
        do {
            let bungieResponse = try decoder.decode(BungieResponse<T>.self, from: data)
            
            if let errorCode = bungieResponse.errorCode, errorCode != 1 {
                throw BungieAPIError.apiError(code: errorCode, message: bungieResponse.message ?? "Unknown error")
            }
            
            guard let response = bungieResponse.response else {
                throw BungieAPIError.emptyResponse
            }
            
            return response
        } catch {
            // If that fails, try to decode directly as the response type
            return try decoder.decode(T.self, from: data)
        }
    }
    
    /// Handles error responses from the Bungie API
    /// - Parameters:
    ///   - data: The error response data
    ///   - statusCode: The HTTP status code
    /// - Returns: An appropriate error
    private func handleErrorResponse(data: Data, statusCode: Int) -> Error {
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let errorResponse = try decoder.decode(BungieResponse<Empty>.self, from: data)
            return BungieAPIError.apiError(
                code: errorResponse.errorCode ?? 0,
                message: errorResponse.message ?? "Unknown error"
            )
        } catch {
            return BungieAPIError.httpError(statusCode)
        }
    }
}

/// HTTP methods for API requests
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// Generic response wrapper for Bungie API responses
public struct BungieResponse<T: Decodable>: Decodable {
    /// The response data
    public let response: T?
    /// The error code (1 = success)
    public let errorCode: Int?
    /// The throttle seconds
    public let throttleSeconds: Int?
    /// The error status
    public let errorStatus: String?
    /// The error message
    public let message: String?
    /// Detailed error trace info
    public let messageData: [String: String]?
}

/// Empty struct for responses with no data
public struct Empty: Decodable {}

/// Errors that can occur when making API requests
public enum BungieAPIError: Error {
    /// The URL was invalid
    case invalidURL
    /// The response was invalid
    case invalidResponse
    /// The response was empty
    case emptyResponse
    /// A network error occurred
    case networkError(Error)
    /// An HTTP error occurred
    case httpError(Int)
    /// An API error occurred
    case apiError(code: Int, message: String)
    /// An error occurred while decoding the response
    case decodingError(Error)
} 