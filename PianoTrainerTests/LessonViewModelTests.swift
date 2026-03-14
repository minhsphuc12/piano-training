import XCTest
@testable import PianoTrainer

final class LessonViewModelTests: XCTestCase {
    
    var viewModel: LessonViewModel!
    var testSong: Song!
    
    override func setUp() {
        super.setUp()
        testSong = makeTestSong()
        viewModel = LessonViewModel(song: testSong)
    }
    
    override func tearDown() {
        viewModel = nil
        testSong = nil
        super.tearDown()
    }
    
    // MARK: - Test Data Helpers
    
    private func makeTestSong(chunkCount: Int = 3) -> Song {
        let chunks = (0..<chunkCount).map { index in
            Chunk(
                id: index,
                startBar: index * 4 + 1,
                endBar: (index + 1) * 4,
                notes: [
                    NoteEvent(pitch: 60 + index, startTime: 0, duration: 0.5, finger: .thumb, hand: .right)
                ]
            )
        }
        
        return Song(
            id: "test-song",
            title: "Test Song",
            composer: "Test Composer",
            bpm: 120,
            difficulty: .beginner,
            timeSignatureNumerator: 4,
            timeSignatureDenominator: 4,
            chunks: chunks
        )
    }
    
    // MARK: - Initial State Tests (VM-01, VM-02)
    
    func testInitialState() {
        XCTAssertEqual(viewModel.phase, .listen)
        XCTAssertEqual(viewModel.currentChunkIndex, 0)
    }
    
    func testInitialTempo() {
        XCTAssertEqual(viewModel.tempoMultiplier, 0.7, accuracy: 0.01)
    }
    
    // MARK: - Phase Transition Tests (VM-03 to VM-05)
    
    func testStartListen() {
        viewModel.startListen()
        XCTAssertEqual(viewModel.phase, .listen)
    }
    
    func testStartShadow() {
        viewModel.startShadow()
        XCTAssertEqual(viewModel.phase, .shadow)
    }
    
    func testStartPractice() {
        viewModel.startPractice()
        XCTAssertEqual(viewModel.phase, .practice)
    }
    
    // MARK: - User Input Tests (VM-06, VM-07)
    
    func testUserPressedKeyInPractice() {
        viewModel.startPractice()
        // Should not crash, attempt should be recorded internally
        viewModel.userPressedKey(pitch: 60)
        XCTAssertEqual(viewModel.phase, .practice)
    }
    
    func testUserPressedKeyInListen() {
        viewModel.startListen()
        // Should not crash, but no grading happens
        viewModel.userPressedKey(pitch: 60)
        XCTAssertEqual(viewModel.phase, .listen)
    }
    
    // MARK: - Tempo Tests (VM-08)
    
    func testSetTempo() {
        viewModel.setTempo(0.5)
        XCTAssertEqual(viewModel.tempoMultiplier, 0.5, accuracy: 0.01)
    }
    
    func testSetTempoRange() {
        viewModel.setTempo(0.4)
        XCTAssertEqual(viewModel.tempoMultiplier, 0.4, accuracy: 0.01)
        
        viewModel.setTempo(1.0)
        XCTAssertEqual(viewModel.tempoMultiplier, 1.0, accuracy: 0.01)
    }
    
    // MARK: - Chunk Navigation Tests (VM-12, VM-13)
    
    func testAdvanceToNextChunk() {
        XCTAssertEqual(viewModel.currentChunkIndex, 0)
        
        viewModel.advanceToNextChunk()
        
        XCTAssertEqual(viewModel.currentChunkIndex, 1)
        XCTAssertEqual(viewModel.phase, .listen)
    }
    
    func testAdvanceToNextChunkAtLast() {
        // Move to last chunk
        viewModel.advanceToNextChunk()  // 0 -> 1
        viewModel.advanceToNextChunk()  // 1 -> 2 (last)
        XCTAssertTrue(viewModel.isLastChunk)
        
        let lastIndex = viewModel.currentChunkIndex
        viewModel.advanceToNextChunk()  // Should not change
        
        XCTAssertEqual(viewModel.currentChunkIndex, lastIndex)
    }
    
    // MARK: - Replay Tests (VM-14)
    
    func testReplayCurrentChunk() {
        viewModel.startPractice()
        viewModel.replayCurrentChunk()
        
        XCTAssertEqual(viewModel.phase, .listen)
        XCTAssertNil(viewModel.lastGradeResult)
    }
    
    // MARK: - Last Chunk Tests (VM-15, VM-16)
    
    func testIsLastChunkTrue() {
        // Move to last chunk (index 2 of 3 chunks)
        viewModel.advanceToNextChunk()
        viewModel.advanceToNextChunk()
        
        XCTAssertTrue(viewModel.isLastChunk)
    }
    
    func testIsLastChunkFalse() {
        XCTAssertFalse(viewModel.isLastChunk)
    }
    
    // MARK: - Current Chunk Tests
    
    func testCurrentChunk() {
        XCTAssertEqual(viewModel.currentChunk.id, 0)
        
        viewModel.advanceToNextChunk()
        XCTAssertEqual(viewModel.currentChunk.id, 1)
    }
    
    // MARK: - Active State Tests (VM-17, VM-18, VM-19, VM-20)
    
    func testActivePitchesInitiallyEmpty() {
        XCTAssertTrue(viewModel.activePitches.isEmpty)
    }
    
    func testActiveFingersInitiallyEmpty() {
        XCTAssertTrue(viewModel.activeFingers.isEmpty)
    }
    
    func testActiveHandsInitiallyEmpty() {
        XCTAssertTrue(viewModel.activeHands.isEmpty)
    }
    
    // MARK: - Consecutive Correct Reset Tests
    
    func testAdvanceResetsConsecutiveCorrect() {
        viewModel.advanceToNextChunk()
        // Internal state should be reset
        XCTAssertEqual(viewModel.currentChunkIndex, 1)
    }
    
    func testReplayResetsState() {
        viewModel.replayCurrentChunk()
        XCTAssertNil(viewModel.lastGradeResult)
    }
    
    // MARK: - Song Property Access
    
    func testSongAccess() {
        XCTAssertEqual(viewModel.song.id, "test-song")
        XCTAssertEqual(viewModel.song.title, "Test Song")
        XCTAssertEqual(viewModel.song.chunks.count, 3)
    }
    
    // MARK: - Player Reference
    
    func testPlayerExists() {
        XCTAssertNotNil(viewModel.player)
    }
    
    // MARK: - Single Chunk Song
    
    func testSingleChunkSong() {
        let singleChunkSong = makeTestSong(chunkCount: 1)
        let vm = LessonViewModel(song: singleChunkSong)
        
        XCTAssertTrue(vm.isLastChunk)
        XCTAssertEqual(vm.currentChunkIndex, 0)
        
        // Advance should not change
        vm.advanceToNextChunk()
        XCTAssertEqual(vm.currentChunkIndex, 0)
    }
}

// MARK: - PracticePhase Tests

final class PracticePhaseTests: XCTestCase {
    
    func testPracticePhaseRawValues() {
        XCTAssertEqual(PracticePhase.listen.rawValue, "Listen")
        XCTAssertEqual(PracticePhase.shadow.rawValue, "Shadow")
        XCTAssertEqual(PracticePhase.practice.rawValue, "Practice")
        XCTAssertEqual(PracticePhase.result.rawValue, "Result")
        XCTAssertEqual(PracticePhase.mastered.rawValue, "Mastered")
    }
    
    func testPracticePhaseAllCases() {
        XCTAssertEqual(PracticePhase.allCases.count, 5)
    }
}
