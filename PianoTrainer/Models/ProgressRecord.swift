import Foundation
import SwiftData

// MARK: - ChunkAttempt

@Model
final class ChunkAttempt {
    var chunkId: Int
    var songId: String
    var timestamp: Date
    /// 0.0 – 1.0 timing accuracy
    var accuracy: Double
    /// How many consecutive correct plays this session
    var consecutiveCorrect: Int

    init(chunkId: Int, songId: String, accuracy: Double, consecutiveCorrect: Int = 0) {
        self.chunkId = chunkId
        self.songId = songId
        self.timestamp = Date()
        self.accuracy = accuracy
        self.consecutiveCorrect = consecutiveCorrect
    }

    var stars: Int {
        switch accuracy {
        case 0.9...: return 3
        case 0.7...: return 2
        case 0.5...: return 1
        default:     return 0
        }
    }
}

// MARK: - SongProgress

@Model
final class SongProgress {
    var songId: String
    var masteredChunkIds: [Int]
    var lastPracticed: Date
    var totalPracticeSeconds: Double

    init(songId: String) {
        self.songId = songId
        self.masteredChunkIds = []
        self.lastPracticed = Date()
        self.totalPracticeSeconds = 0
    }

    var completionFraction: Double {
        // Caller fills in total chunk count
        Double(masteredChunkIds.count)
    }

    func isMastered(chunkId: Int) -> Bool {
        masteredChunkIds.contains(chunkId)
    }

    func markMastered(chunkId: Int) {
        if !masteredChunkIds.contains(chunkId) {
            masteredChunkIds.append(chunkId)
        }
    }
}

// MARK: - DailyStreak

@Model
final class DailyStreak {
    var practiceDates: [Date]

    init() {
        self.practiceDates = []
    }

    var currentStreak: Int {
        let cal = Calendar.current
        let sorted = practiceDates
            .map { cal.startOfDay(for: $0) }
            .sorted(by: >)
        guard !sorted.isEmpty else { return 0 }

        var streak = 1
        var prev = sorted[0]
        for date in sorted.dropFirst() {
            guard let diff = cal.dateComponents([.day], from: date, to: prev).day,
                  diff == 1 else { break }
            streak += 1
            prev = date
        }
        return streak
    }

    func recordToday() {
        let today = Calendar.current.startOfDay(for: Date())
        if !practiceDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: today) }) {
            practiceDates.append(today)
        }
    }
}
