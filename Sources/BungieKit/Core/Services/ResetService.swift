import Foundation

/// Service for calculating Destiny 2 reset times
public class ResetService {
    /// The base date for reset calculations
    private let referenceDate = Date(timeIntervalSince1970: 1293840000) // January 1, 2011, 00:00:00 UTC
    
    /// Constants for time intervals
    private struct TimeIntervals {
        /// Seconds in a day
        static let day: TimeInterval = 86400
        /// Seconds in a week
        static let week: TimeInterval = 604800
        /// Days in a week
        static let daysInWeek = 7
        /// Hour of daily reset (17:00 UTC)
        static let resetHour = 17
    }
    
    /// Gets the date of the next daily reset
    /// - Parameter date: The reference date (defaults to now)
    /// - Returns: The date of the next daily reset
    public func getNextDailyReset(after date: Date = Date()) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Set to 17:00 UTC
        components.hour = TimeIntervals.resetHour
        components.minute = 0
        components.second = 0
        
        let resetDate = calendar.date(from: components)!
        
        // If the date has already passed today's reset, add a day
        if date >= resetDate {
            return calendar.date(byAdding: .day, value: 1, to: resetDate)!
        } else {
            return resetDate
        }
    }
    
    /// Gets the date of the next weekly reset (Tuesday at 17:00 UTC)
    /// - Parameter date: The reference date (defaults to now)
    /// - Returns: The date of the next weekly reset
    public func getNextWeeklyReset(after date: Date = Date()) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
        
        // Set to 17:00 UTC
        components.hour = TimeIntervals.resetHour
        components.minute = 0
        components.second = 0
        
        // Find the days until the next Tuesday (weekday 3 in Calendar)
        let currentWeekday = components.weekday!
        let daysUntilTuesday = (3 - currentWeekday + 7) % 7
        
        let baseResetDate = calendar.date(from: components)!
        var nextResetDate = calendar.date(byAdding: .day, value: daysUntilTuesday, to: baseResetDate)!
        
        // If it's Tuesday and past reset time, go to next week
        if daysUntilTuesday == 0 && date >= nextResetDate {
            nextResetDate = calendar.date(byAdding: .day, value: 7, to: nextResetDate)!
        }
        
        return nextResetDate
    }
    
    /// Calculates the current season by estimating from a known season start date
    /// Note: This is an approximation - for exact values, use the Destiny API
    /// - Parameter date: The date to calculate for (defaults to now)
    /// - Returns: The estimated season number
    public func estimateCurrentSeason(at date: Date = Date()) -> Int {
        // Season 15 started on August 24, 2021
        let season15StartDate = Date(timeIntervalSince1970: 1629817200)
        let knownSeason = 15
        
        // Average season length in seconds (13 weeks)
        let seasonLengthInSeconds: TimeInterval = TimeIntervals.week * 13
        
        let secondsSinceSeason15 = date.timeIntervalSince(season15StartDate)
        let seasonsPassed = Int(secondsSinceSeason15 / seasonLengthInSeconds)
        
        return knownSeason + seasonsPassed
    }
    
    /// Gets the time until the next daily reset
    /// - Parameter date: The reference date (defaults to now)
    /// - Returns: The time interval until the next daily reset
    public func timeUntilDailyReset(from date: Date = Date()) -> TimeInterval {
        let nextReset = getNextDailyReset(after: date)
        return nextReset.timeIntervalSince(date)
    }
    
    /// Gets the time until the next weekly reset
    /// - Parameter date: The reference date (defaults to now)
    /// - Returns: The time interval until the next weekly reset
    public func timeUntilWeeklyReset(from date: Date = Date()) -> TimeInterval {
        let nextReset = getNextWeeklyReset(after: date)
        return nextReset.timeIntervalSince(date)
    }
} 