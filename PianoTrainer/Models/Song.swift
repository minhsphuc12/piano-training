import Foundation

// MARK: - Chunk

/// A small, learnable segment of a song (typically 2–4 bars)
struct Chunk: Codable, Identifiable {
    let id: Int
    let startBar: Int
    let endBar: Int
    let notes: [NoteEvent]

    /// Duration of the chunk in seconds (end of last note)
    var totalDuration: Double {
        notes.map { $0.startTime + $0.duration }.max() ?? 0
    }

    /// All notes sorted by start time
    var sortedNotes: [NoteEvent] {
        notes.sorted { $0.startTime < $1.startTime }
    }

    /// Unique pitches that appear in this chunk (for keyboard highlighting)
    var involvedPitches: Set<Int> {
        Set(notes.map(\.pitch))
    }
}

// MARK: - Difficulty

enum Difficulty: String, Codable, CaseIterable {
    case beginner     = "Beginner"
    case intermediate = "Intermediate"
    case advanced     = "Advanced"
}

// MARK: - Song

struct Song: Codable, Identifiable {
    let id: String
    let title: String
    let composer: String
    let bpm: Double
    let difficulty: Difficulty
    let timeSignatureNumerator: Int    // e.g. 3 in 3/4
    let timeSignatureDenominator: Int  // e.g. 4 in 3/4
    let chunks: [Chunk]

    /// Total number of bars across all chunks
    var totalBars: Int {
        chunks.map(\.endBar).max() ?? 0
    }
}

// MARK: - Song Library (bundled JSON)

struct SongLibrary {
    static func load() -> [Song] {
        guard
            let url = Bundle.main.url(forResource: "SampleSongs", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let songs = try? JSONDecoder().decode([Song].self, from: data)
        else {
            return []
        }
        return songs
    }
}
