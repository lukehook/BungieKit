import XCTest
@testable import BungieKit

final class ResetServiceTests: XCTestCase {
    var resetService: ResetService!
    
    override func setUp() {
        super.setUp()
        resetService = ResetService()
    }
    
    override func tearDown() {
        resetService = nil
        super.tearDown()
    }
    
    func testDailyReset() {
        // Create a reference date at 16:59:59 UTC (just before reset)
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2023
        components.month = 1
        components.day = 1
        components.hour = 16
        components.minute = 59
        components.second = 59
        
        let justBeforeReset = calendar.date(from: components)!
        
        // The next reset should be at 17:00:00 UTC on the same day
        let expectedReset = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: justBeforeReset)!
        
        let nextReset = resetService.getNextDailyReset(after: justBeforeReset)
        XCTAssertEqual(nextReset, expectedReset)
        
        // Test a time just after reset
        let justAfterReset = calendar.date(byAdding: .second, value: 2, to: expectedReset)!
        
        // The next reset should be at 17:00:00 UTC the next day
        let expectedNextDayReset = calendar.date(byAdding: .day, value: 1, to: expectedReset)!
        
        let nextDayReset = resetService.getNextDailyReset(after: justAfterReset)
        XCTAssertEqual(nextDayReset, expectedNextDayReset)
    }
    
    func testWeeklyReset() {
        // Create a date for Monday, January 2, 2023 at 16:59:59 UTC (day before reset, just before 17:00)
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2023
        components.month = 1
        components.day = 2 // Monday
        components.hour = 16
        components.minute = 59
        components.second = 59
        
        let mondayBeforeReset = calendar.date(from: components)!
        
        // The next reset should be Tuesday, January 3, 2023 at 17:00:00 UTC
        components.day = 3 // Tuesday
        components.hour = 17
        components.minute = 0
        components.second = 0
        let expectedTuesdayReset = calendar.date(from: components)!
        
        let nextReset = resetService.getNextWeeklyReset(after: mondayBeforeReset)
        XCTAssertEqual(nextReset, expectedTuesdayReset)
        
        // Test a time just after Tuesday's reset
        let justAfterTuesdayReset = calendar.date(byAdding: .second, value: 2, to: expectedTuesdayReset)!
        
        // The next reset should be next Tuesday at 17:00:00 UTC
        let expectedNextTuesdayReset = calendar.date(byAdding: .day, value: 7, to: expectedTuesdayReset)!
        
        let nextWeekReset = resetService.getNextWeeklyReset(after: justAfterTuesdayReset)
        XCTAssertEqual(nextWeekReset, expectedNextTuesdayReset)
    }
    
    func testTimeUntilReset() {
        // Create a date 1 hour before daily reset
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2023
        components.month = 1
        components.day = 1
        components.hour = 16
        components.minute = 0
        components.second = 0
        
        let oneHourBeforeReset = calendar.date(from: components)!
        
        // We should have 1 hour until reset
        let timeUntilDaily = resetService.timeUntilDailyReset(from: oneHourBeforeReset)
        XCTAssertEqual(timeUntilDaily, 3600, accuracy: 1) // 3600 seconds = 1 hour
        
        // Test time until weekly reset (assuming January 1, 2023 is a Sunday)
        // So reset is on Tuesday, January 3, 2023 at 17:00:00 UTC
        // That's 2 days and 1 hour from our test date
        let timeUntilWeekly = resetService.timeUntilWeeklyReset(from: oneHourBeforeReset)
        XCTAssertEqual(timeUntilWeekly, 2 * 86400 + 3600, accuracy: 1) // 2 days + 1 hour
    }
} 