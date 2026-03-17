import Foundation

// MARK: - Chunk

/// A small, learnable segment of a song (typically 2–4 bars)
struct Chunk: Codable, Identifiable, Hashable {
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
    case beginner     = "beginner"
    case intermediate = "intermediate"
    case advanced     = "advanced"
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .beginner:     return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced:     return "Advanced"
        }
    }
}

// MARK: - Song

struct Song: Codable, Identifiable, Hashable {
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

// MARK: - Song Library (bundled JSON + imported songs)

struct SongLibrary {
    static func load() -> [Song] {
        let bundled = loadBundled()
        let imported = SongStore.loadAll()

        // If an imported song shares an id with a bundled song, prefer imported.
        var byId: [String: Song] = [:]
        for song in bundled { byId[song.id] = song }
        for song in imported { byId[song.id] = song }

        return byId.values.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    static func loadBundled() -> [Song] {
        guard let url = Bundle.main.url(forResource: "SampleSongs", withExtension: "json") else {
            print("⚠️ SampleSongs.json not found in bundle")
            return []
        }

        guard let data = try? Data(contentsOf: url) else {
            print("⚠️ Could not load data from SampleSongs.json")
            return []
        }

        do {
            let songs = try JSONDecoder().decode([Song].self, from: data)
            print("✅ Loaded \(songs.count) bundled songs")
            return songs
        } catch {
            print("⚠️ Failed to decode SampleSongs.json: \(error)")
            return []
        }
    }
}
