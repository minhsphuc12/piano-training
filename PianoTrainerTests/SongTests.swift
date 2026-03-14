import XCTest
@testable import PianoTrainer

final class SongTests: XCTestCase {
    
    // MARK: - Test Data Helpers
    
    private func makeNote(pitch: Int, startTime: Double, duration: Double = 0.5) -> NoteEvent {
        NoteEvent(pitch: pitch, startTime: startTime, duration: duration, finger: .thumb, hand: .right)
    }
    
    private func makeChunk(id: Int, startBar: Int, endBar: Int, notes: [NoteEvent]) -> Chunk {
        Chunk(id: id, startBar: startBar, endBar: endBar, notes: notes)
    }
    
    // MARK: - Chunk Tests (S-01 to S-04)
    
    func testChunkTotalDuration() {
        let notes = [
            makeNote(pitch: 60, startTime: 0, duration: 0.5),
            makeNote(pitch: 62, startTime: 1, duration: 0.5),
            makeNote(pitch: 64, startTime: 2, duration: 0.5)
        ]
        let chunk = makeChunk(id: 1, startBar: 1, endBar: 2, notes: notes)
        
        XCTAssertEqual(chunk.totalDuration, 2.5, accuracy: 0.001)
    }
    
    func testChunkTotalDurationEmpty() {
        let chunk = makeChunk(id: 1, startBar: 1, endBar: 2, notes: [])
        XCTAssertEqual(chunk.totalDuration, 0)
    }
    
    func testChunkSortedNotes() {
        let notes = [
            makeNote(pitch: 64, startTime: 2),
            makeNote(pitch: 60, startTime: 0),
            makeNote(pitch: 62, startTime: 1)
        ]
        let chunk = makeChunk(id: 1, startBar: 1, endBar: 2, notes: notes)
        let sorted = chunk.sortedNotes
        
        XCTAssertEqual(sorted[0].startTime, 0)
        XCTAssertEqual(sorted[1].startTime, 1)
        XCTAssertEqual(sorted[2].startTime, 2)
    }
    
    func testChunkInvolvedPitches() {
        let notes = [
            makeNote(pitch: 60, startTime: 0),
            makeNote(pitch: 62, startTime: 1),
            makeNote(pitch: 60, startTime: 2),  // duplicate pitch
            makeNote(pitch: 64, startTime: 3)
        ]
        let chunk = makeChunk(id: 1, startBar: 1, endBar: 4, notes: notes)
        
        let pitches = chunk.involvedPitches
        XCTAssertEqual(pitches.count, 3, "Should have unique pitches only")
        XCTAssertTrue(pitches.contains(60))
        XCTAssertTrue(pitches.contains(62))
        XCTAssertTrue(pitches.contains(64))
    }
    
    // MARK: - Song Tests (S-05 to S-07)
    
    func testSongTotalBars() {
        let chunks = [
            makeChunk(id: 1, startBar: 1, endBar: 4, notes: []),
            makeChunk(id: 2, startBar: 5, endBar: 8, notes: []),
            makeChunk(id: 3, startBar: 9, endBar: 12, notes: [])
        ]
        let song = Song(
            id: "test",
            title: "Test Song",
            composer: "Test",
            bpm: 120,
            difficulty: .beginner,
            timeSignatureNumerator: 4,
            timeSignatureDenominator: 4,
            chunks: chunks
        )
        
        XCTAssertEqual(song.totalBars, 12)
    }
    
    func testSongTotalBarsEmpty() {
        let song = Song(
            id: "test",
            title: "Test Song",
            composer: "Test",
            bpm: 120,
            difficulty: .beginner,
            timeSignatureNumerator: 4,
            timeSignatureDenominator: 4,
            chunks: []
        )
        
        XCTAssertEqual(song.totalBars, 0)
    }
    
    func testDifficultyEnum() {
        XCTAssertEqual(Difficulty.beginner.rawValue, "Beginner")
        XCTAssertEqual(Difficulty.intermediate.rawValue, "Intermediate")
        XCTAssertEqual(Difficulty.advanced.rawValue, "Advanced")
        XCTAssertEqual(Difficulty.allCases.count, 3)
    }
    
    // MARK: - Codable Tests (S-08)
    
    func testSongCodable() throws {
        let json = """
        {
            "id": "test-song",
            "title": "Test",
            "composer": "Tester",
            "bpm": 100,
            "difficulty": "Beginner",
            "timeSignatureNumerator": 3,
            "timeSignatureDenominator": 4,
            "chunks": [
                {
                    "id": 1,
                    "startBar": 1,
                    "endBar": 4,
                    "notes": [
                        {
                            "id": "550e8400-e29b-41d4-a716-446655440000",
                            "pitch": 60,
                            "startTime": 0.0,
                            "duration": 0.5,
                            "finger": 1,
                            "hand": "right",
                            "velocity": 80
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let song = try decoder.decode(Song.self, from: json)
        
        XCTAssertEqual(song.id, "test-song")
        XCTAssertEqual(song.title, "Test")
        XCTAssertEqual(song.composer, "Tester")
        XCTAssertEqual(song.bpm, 100)
        XCTAssertEqual(song.difficulty, .beginner)
        XCTAssertEqual(song.timeSignatureNumerator, 3)
        XCTAssertEqual(song.timeSignatureDenominator, 4)
        XCTAssertEqual(song.chunks.count, 1)
        XCTAssertEqual(song.chunks[0].notes.count, 1)
        XCTAssertEqual(song.chunks[0].notes[0].pitch, 60)
    }
    
    // MARK: - Chunk Identifiable
    
    func testChunkIdentifiable() {
        let chunk = makeChunk(id: 42, startBar: 1, endBar: 4, notes: [])
        XCTAssertEqual(chunk.id, 42)
    }
    
    // MARK: - Song Identifiable
    
    func testSongIdentifiable() {
        let song = Song(
            id: "unique-id",
            title: "Test",
            composer: "Test",
            bpm: 120,
            difficulty: .beginner,
            timeSignatureNumerator: 4,
            timeSignatureDenominator: 4,
            chunks: []
        )
        XCTAssertEqual(song.id, "unique-id")
    }
}
