import XCTest
@testable import PianoTrainer

final class ChunkAttemptTests: XCTestCase {
    
    // MARK: - Stars Calculation Tests (P-01 to P-07)
    
    func testStars3AtHighAccuracy() {
        let attempt = ChunkAttempt(chunkId: 1, songId: "test", accuracy: 0.95)
        XCTAssertEqual(attempt.stars, 3)
    }
    
    func testStars2AtMediumAccuracy() {
        let attempt = ChunkAttempt(chunkId: 1, songId: "test", accuracy: 0.75)
        XCTAssertEqual(attempt.stars, 2)
    }
    
    func testStars1AtLowAccuracy() {
        let attempt = ChunkAttempt(chunkId: 1, songId: "test", accuracy: 0.55)
        XCTAssertEqual(attempt.stars, 1)
    }
    
    func testStars0AtVeryLowAccuracy() {
        let attempt = ChunkAttempt(chunkId: 1, songId: "test", accuracy: 0.40)
        XCTAssertEqual(attempt.stars, 0)
    }
    
    func testStarsBoundary90Percent() {
        let attempt = ChunkAttempt(chunkId: 1, songId: "test", accuracy: 0.90)
        XCTAssertEqual(attempt.stars, 3, "Exactly 90% should be 3 stars")
    }
    
    func testStarsBoundary70Percent() {
        let attempt = ChunkAttempt(chunkId: 1, songId: "test", accuracy: 0.70)
        XCTAssertEqual(attempt.stars, 2, "Exactly 70% should be 2 stars")
    }
    
    func testStarsBoundary50Percent() {
        let attempt = ChunkAttempt(chunkId: 1, songId: "test", accuracy: 0.50)
        XCTAssertEqual(attempt.stars, 1, "Exactly 50% should be 1 star")
    }
    
    // MARK: - Initialization Tests
    
    func testChunkAttemptInit() {
        let attempt = ChunkAttempt(chunkId: 5, songId: "song-1", accuracy: 0.85)
        
        XCTAssertEqual(attempt.chunkId, 5)
        XCTAssertEqual(attempt.songId, "song-1")
        XCTAssertEqual(attempt.accuracy, 0.85, accuracy: 0.001)
        XCTAssertEqual(attempt.consecutiveCorrect, 0)
        XCTAssertNotNil(attempt.timestamp)
    }
    
    func testChunkAttemptWithConsecutiveCorrect() {
        let attempt = ChunkAttempt(chunkId: 1, songId: "test", accuracy: 0.80, consecutiveCorrect: 2)
        XCTAssertEqual(attempt.consecutiveCorrect, 2)
    }
    
    // MARK: - Edge Cases
    
    func testZeroAccuracy() {
        let attempt = ChunkAttempt(chunkId: 1, songId: "test", accuracy: 0.0)
        XCTAssertEqual(attempt.stars, 0)
    }
    
    func testPerfectAccuracy() {
        let attempt = ChunkAttempt(chunkId: 1, songId: "test", accuracy: 1.0)
        XCTAssertEqual(attempt.stars, 3)
    }
}

// MARK: - SongProgress Tests

final class SongProgressTests: XCTestCase {
    
    // MARK: - Initialization Tests (P-08)
    
    func testSongProgressInit() {
        let progress = SongProgress(songId: "song-1")
        
        XCTAssertEqual(progress.songId, "song-1")
        XCTAssertTrue(progress.masteredChunkIds.isEmpty)
        XCTAssertEqual(progress.totalPracticeSeconds, 0)
        XCTAssertNotNil(progress.lastPracticed)
    }
    
    // MARK: - Mark Mastered Tests (P-09, P-10)
    
    func testMarkMastered() {
        let progress = SongProgress(songId: "test")
        
        progress.markMastered(chunkId: 1)
        
        XCTAssertTrue(progress.masteredChunkIds.contains(1))
        XCTAssertEqual(progress.masteredChunkIds.count, 1)
    }
    
    func testMarkMasteredDuplicate() {
        let progress = SongProgress(songId: "test")
        
        progress.markMastered(chunkId: 1)
        progress.markMastered(chunkId: 1)  // Duplicate
        
        XCTAssertEqual(progress.masteredChunkIds.count, 1, "Should not add duplicate")
    }
    
    func testMarkMasteredMultiple() {
        let progress = SongProgress(songId: "test")
        
        progress.markMastered(chunkId: 1)
        progress.markMastered(chunkId: 2)
        progress.markMastered(chunkId: 3)
        
        XCTAssertEqual(progress.masteredChunkIds.count, 3)
        XCTAssertTrue(progress.masteredChunkIds.contains(1))
        XCTAssertTrue(progress.masteredChunkIds.contains(2))
        XCTAssertTrue(progress.masteredChunkIds.contains(3))
    }
    
    // MARK: - isMastered Tests (P-11, P-12)
    
    func testIsMasteredTrue() {
        let progress = SongProgress(songId: "test")
        progress.markMastered(chunkId: 5)
        
        XCTAssertTrue(progress.isMastered(chunkId: 5))
    }
    
    func testIsMasteredFalse() {
        let progress = SongProgress(songId: "test")
        
        XCTAssertFalse(progress.isMastered(chunkId: 5))
    }
    
    // MARK: - Completion Fraction
    
    func testCompletionFraction() {
        let progress = SongProgress(songId: "test")
        progress.markMastered(chunkId: 1)
        progress.markMastered(chunkId: 2)
        
        XCTAssertEqual(progress.completionFraction, 2.0)
    }
}

// MARK: - DailyStreak Tests

final class DailyStreakTests: XCTestCase {
    
    // MARK: - Empty Streak (P-13)
    
    func testEmptyStreak() {
        let streak = DailyStreak()
        XCTAssertEqual(streak.currentStreak, 0)
    }
    
    // MARK: - Single Day (P-14)
    
    func testSingleDayStreak() {
        let streak = DailyStreak()
        streak.recordToday()
        
        XCTAssertEqual(streak.currentStreak, 1)
    }
    
    // MARK: - Consecutive Days (P-15)
    
    func testConsecutiveDaysStreak() {
        let streak = DailyStreak()
        let calendar = Calendar.current
        let today = Date()
        
        // Add dates for consecutive days
        streak.practiceDates = [
            calendar.date(byAdding: .day, value: -2, to: today)!,
            calendar.date(byAdding: .day, value: -1, to: today)!,
            today
        ]
        
        XCTAssertEqual(streak.currentStreak, 3)
    }
    
    // MARK: - Gap in Streak (P-16)
    
    func testStreakWithGap() {
        let streak = DailyStreak()
        let calendar = Calendar.current
        let today = Date()
        
        // Gap: today, yesterday, then skip 2 days
        streak.practiceDates = [
            calendar.date(byAdding: .day, value: -4, to: today)!,  // Too old
            calendar.date(byAdding: .day, value: -1, to: today)!,
            today
        ]
        
        XCTAssertEqual(streak.currentStreak, 2, "Streak should break at gap")
    }
    
    // MARK: - Record Today Duplicate (P-17)
    
    func testRecordTodayDuplicate() {
        let streak = DailyStreak()
        
        streak.recordToday()
        streak.recordToday()  // Duplicate
        streak.recordToday()  // Duplicate
        
        XCTAssertEqual(streak.practiceDates.count, 1, "Should only have one entry for today")
    }
    
    // MARK: - Init
    
    func testDailyStreakInit() {
        let streak = DailyStreak()
        XCTAssertTrue(streak.practiceDates.isEmpty)
    }
    
    // MARK: - Long Streak
    
    func testLongStreak() {
        let streak = DailyStreak()
        let calendar = Calendar.current
        let today = Date()
        
        // Create 10-day streak
        streak.practiceDates = (0..<10).map { dayOffset in
            calendar.date(byAdding: .day, value: -dayOffset, to: today)!
        }
        
        XCTAssertEqual(streak.currentStreak, 10)
    }
    
    // MARK: - Broken Streak at Start
    
    func testBrokenStreakAtStart() {
        let streak = DailyStreak()
        let calendar = Calendar.current
        let today = Date()
        
        // Old dates only, no recent activity
        streak.practiceDates = [
            calendar.date(byAdding: .day, value: -10, to: today)!,
            calendar.date(byAdding: .day, value: -9, to: today)!,
            calendar.date(byAdding: .day, value: -8, to: today)!
        ]
        
        // Current streak should start from most recent date
        XCTAssertGreaterThanOrEqual(streak.currentStreak, 1)
    }
    
    // MARK: - Out of Order Dates
    
    func testOutOfOrderDates() {
        let streak = DailyStreak()
        let calendar = Calendar.current
        let today = Date()
        
        // Dates added out of order
        streak.practiceDates = [
            today,
            calendar.date(byAdding: .day, value: -2, to: today)!,
            calendar.date(byAdding: .day, value: -1, to: today)!
        ]
        
        // Should still calculate correctly (sorted internally)
        XCTAssertEqual(streak.currentStreak, 3)
    }
}
