import XCTest
@testable import BungieKit

final class BungieClientTests: XCTestCase {
    func testBasicClient() {
        let apiKey = "test-api-key"
        let client = BungieClient.basic(apiKey: apiKey)
        
        XCTAssertEqual(client.configuration.apiKey, apiKey)
        XCTAssertEqual(client.configuration.baseUrl, URL(string: "https://www.bungie.net/Platform")!)
        XCTAssertEqual(client.configuration.userAgent, "BungieKit")
    }
    
    func testCustomConfigurationClient() {
        let apiKey = "test-api-key"
        let clientId = "test-client-id"
        let clientSecret = "test-client-secret"
        let baseUrl = URL(string: "https://custom.url")!
        let userAgent = "CustomAgent"
        
        let configuration = BungieClient.Configuration(
            apiKey: apiKey,
            clientId: clientId,
            clientSecret: clientSecret,
            baseUrl: baseUrl,
            userAgent: userAgent
        )
        
        let client = BungieClient(configuration: configuration)
        
        XCTAssertEqual(client.configuration.apiKey, apiKey)
        XCTAssertEqual(client.configuration.clientId, clientId)
        XCTAssertEqual(client.configuration.clientSecret, clientSecret)
        XCTAssertEqual(client.configuration.baseUrl, baseUrl)
        XCTAssertEqual(client.configuration.userAgent, userAgent)
    }
    
    func testMockBungieClientServices() {
        // Create a mock API service
        let mockAPIService = MockAPIService()
        
        // Create a client with the mock service
        let client = BungieClient(
            configuration: BungieClient.Configuration(apiKey: "test-api-key"),
            apiService: mockAPIService
        )
        
        // Verify the client is using the mock service
        XCTAssertTrue(client.apiService is MockAPIService)
    }
}

// MARK: - Mocks for testing

/// Mock API service for testing
class MockAPIService: APIService {
    var requestCalled = false
    var endpoint: String?
    var method: HTTPMethod?
    var body: Any?
    var queryItems: [URLQueryItem]?
    var accessToken: String?
    
    var mockResponseToReturn: Any?
    var errorToThrow: Error?
    
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable?,
        queryItems: [URLQueryItem]?,
        accessToken: String?,
        responseType: T.Type
    ) async throws -> T {
        requestCalled = true
        self.endpoint = endpoint
        self.method = method
        self.body = body
        self.queryItems = queryItems
        self.accessToken = accessToken
        
        if let error = errorToThrow {
            throw error
        }
        
        if let mockResponseToReturn = mockResponseToReturn as? T {
            return mockResponseToReturn
        }
        
        // Default fallback if the type doesn't match
        throw BungieAPIError.invalidResponse
    }
} 