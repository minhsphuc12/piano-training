import XCTest
@testable import PianoTrainer

final class InputGraderTests: XCTestCase {
    
    var grader: InputGrader!
    
    override func setUp() {
        super.setUp()
        grader = InputGrader()
    }
    
    override func tearDown() {
        grader = nil
        super.tearDown()
    }
    
    // MARK: - Test Data Helpers
    
    private func makeNote(pitch: Int, startTime: Double) -> NoteEvent {
        NoteEvent(pitch: pitch, startTime: startTime, duration: 0.5, finger: .thumb, hand: .right)
    }
    
    private func makeChunk(notes: [NoteEvent]) -> Chunk {
        Chunk(id: 1, startBar: 1, endBar: 4, notes: notes)
    }
    
    // MARK: - Accuracy Tests (G-01 to G-03)
    
    func testPerfectTiming() {
        let notes = [
            makeNote(pitch: 60, startTime: 0),
            makeNote(pitch: 62, startTime: 0.5),
            makeNote(pitch: 64, startTime: 1.0)
        ]
        let chunk = makeChunk(notes: notes)
        
        grader.beginGrading()
        
        // Simulate pressing keys at exact times
        grader.recordAttempt(pitch: 60)
        
        // Wait a bit then press next notes
        let expectation = expectation(description: "Delayed input")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.grader.recordAttempt(pitch: 62)
            self.grader.recordAttempt(pitch: 64)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let result = grader.grade(against: chunk, tempoMultiplier: 1.0)
        
        // With immediate presses, first note should match, others depend on timing
        XCTAssertGreaterThanOrEqual(result.correctNotes, 1)
    }
    
    func testAllMissed() {
        let notes = [
            makeNote(pitch: 60, startTime: 0),
            makeNote(pitch: 62, startTime: 0.5)
        ]
        let chunk = makeChunk(notes: notes)
        
        grader.beginGrading()
        // No attempts recorded
        
        let result = grader.grade(against: chunk, tempoMultiplier: 1.0)
        
        XCTAssertEqual(result.accuracy, 0)
        XCTAssertEqual(result.correctNotes, 0)
        XCTAssertEqual(result.totalNotes, 2)
    }
    
    func testPartialCorrect() {
        let notes = [
            makeNote(pitch: 60, startTime: 0),
            makeNote(pitch: 62, startTime: 0.5),
            makeNote(pitch: 64, startTime: 1.0),
            makeNote(pitch: 65, startTime: 1.5)
        ]
        let chunk = makeChunk(notes: notes)
        
        grader.beginGrading()
        // Only press first two notes
        grader.recordAttempt(pitch: 60)
        grader.recordAttempt(pitch: 62)
        
        let result = grader.grade(against: chunk, tempoMultiplier: 1.0)
        
        // First two notes should match (within tolerance since recorded immediately)
        XCTAssertEqual(result.totalNotes, 4)
        // Accuracy depends on timing, but should be <= 0.5 since we missed 2
        XCTAssertLessThanOrEqual(result.accuracy, 0.5)
    }
    
    // MARK: - Wrong Pitch Test (G-04)
    
    func testWrongPitch() {
        let notes = [makeNote(pitch: 60, startTime: 0)]
        let chunk = makeChunk(notes: notes)
        
        grader.beginGrading()
        grader.recordAttempt(pitch: 61)  // Wrong pitch
        
        let result = grader.grade(against: chunk, tempoMultiplier: 1.0)
        
        XCTAssertEqual(result.correctNotes, 0)
        XCTAssertEqual(result.accuracy, 0)
    }
    
    // MARK: - Stars Calculation (G-07 to G-10)
    
    func testStarsCalculation() {
        // Test the GradeResult stars property directly
        let result3Stars = GradeResult(accuracy: 0.95, correctNotes: 19, totalNotes: 20, averageTimingErrorMs: 50)
        XCTAssertEqual(result3Stars.stars, 3)
        
        let result2Stars = GradeResult(accuracy: 0.75, correctNotes: 15, totalNotes: 20, averageTimingErrorMs: 80)
        XCTAssertEqual(result2Stars.stars, 2)
        
        let result1Star = GradeResult(accuracy: 0.55, correctNotes: 11, totalNotes: 20, averageTimingErrorMs: 100)
        XCTAssertEqual(result1Star.stars, 1)
        
        let result0Stars = GradeResult(accuracy: 0.40, correctNotes: 8, totalNotes: 20, averageTimingErrorMs: 150)
        XCTAssertEqual(result0Stars.stars, 0)
    }
    
    func testStarsBoundary90Percent() {
        let result = GradeResult(accuracy: 0.90, correctNotes: 9, totalNotes: 10, averageTimingErrorMs: 50)
        XCTAssertEqual(result.stars, 3, "Exactly 90% should be 3 stars")
    }
    
    func testStarsBoundary70Percent() {
        let result = GradeResult(accuracy: 0.70, correctNotes: 7, totalNotes: 10, averageTimingErrorMs: 80)
        XCTAssertEqual(result.stars, 2, "Exactly 70% should be 2 stars")
    }
    
    func testStarsBoundary50Percent() {
        let result = GradeResult(accuracy: 0.50, correctNotes: 5, totalNotes: 10, averageTimingErrorMs: 100)
        XCTAssertEqual(result.stars, 1, "Exactly 50% should be 1 star")
    }
    
    // MARK: - Tempo Multiplier Test (G-11)
    
    func testTempoMultiplier() {
        let notes = [makeNote(pitch: 60, startTime: 1.0)]
        let chunk = makeChunk(notes: notes)
        
        grader.beginGrading()
        // At 0.5x tempo, the note at 1.0s should be expected at 2.0s
        grader.recordAttempt(pitch: 60)  // Pressed immediately (too early)
        
        let result = grader.grade(against: chunk, tempoMultiplier: 0.5)
        
        // Should not match because timing is way off
        XCTAssertEqual(result.correctNotes, 0)
    }
    
    // MARK: - No Begin Grading Test (G-13)
    
    func testNoChunkStart() {
        let notes = [makeNote(pitch: 60, startTime: 0)]
        let chunk = makeChunk(notes: notes)
        
        // Don't call beginGrading()
        grader.recordAttempt(pitch: 60)
        
        let result = grader.grade(against: chunk, tempoMultiplier: 1.0)
        
        XCTAssertEqual(result.accuracy, 0)
        XCTAssertEqual(result.averageTimingErrorMs, 999)
    }
    
    // MARK: - Empty Chunk Test (G-14)
    
    func testEmptyChunk() {
        let chunk = makeChunk(notes: [])
        
        grader.beginGrading()
        grader.recordAttempt(pitch: 60)
        
        let result = grader.grade(against: chunk, tempoMultiplier: 1.0)
        
        XCTAssertEqual(result.accuracy, 0)
        XCTAssertEqual(result.totalNotes, 0)
    }
    
    // MARK: - Duplicate Pitch Handling (G-15)
    
    func testDuplicatePitchHandling() {
        // Same pitch appears twice at different times
        let notes = [
            makeNote(pitch: 60, startTime: 0),
            makeNote(pitch: 60, startTime: 0.5)
        ]
        let chunk = makeChunk(notes: notes)
        
        grader.beginGrading()
        grader.recordAttempt(pitch: 60)
        grader.recordAttempt(pitch: 60)
        
        let result = grader.grade(against: chunk, tempoMultiplier: 1.0)
        
        // Both attempts should potentially match both notes
        XCTAssertEqual(result.totalNotes, 2)
        // At least the first one should match (immediate timing)
        XCTAssertGreaterThanOrEqual(result.correctNotes, 1)
    }
    
    // MARK: - Extra Attempts Test (G-16)
    
    func testExtraAttempts() {
        let notes = [makeNote(pitch: 60, startTime: 0)]
        let chunk = makeChunk(notes: notes)
        
        grader.beginGrading()
        grader.recordAttempt(pitch: 60)
        grader.recordAttempt(pitch: 60)  // Extra attempt
        grader.recordAttempt(pitch: 62)  // Wrong pitch
        
        let result = grader.grade(against: chunk, tempoMultiplier: 1.0)
        
        // Should only match one expected note
        XCTAssertLessThanOrEqual(result.correctNotes, 1)
        XCTAssertEqual(result.totalNotes, 1)
    }
    
    // MARK: - Timing Tolerance Tests
    
    func testTimingToleranceDefault() {
        XCTAssertEqual(grader.timingToleranceSeconds, 0.15)
    }
    
    func testTimingToleranceCustom() {
        grader.timingToleranceSeconds = 0.2
        XCTAssertEqual(grader.timingToleranceSeconds, 0.2)
    }
    
    // MARK: - Average Timing Error Test (G-12)
    
    func testAverageTimingError() {
        // When no correct notes, error should be 999
        let result = GradeResult(accuracy: 0, correctNotes: 0, totalNotes: 5, averageTimingErrorMs: 999)
        XCTAssertEqual(result.averageTimingErrorMs, 999)
        
        // Normal case with correct notes
        let resultNormal = GradeResult(accuracy: 0.8, correctNotes: 4, totalNotes: 5, averageTimingErrorMs: 75.5)
        XCTAssertEqual(resultNormal.averageTimingErrorMs, 75.5, accuracy: 0.1)
    }
    
    // MARK: - Reset State Test
    
    func testBeginGradingResetsState() {
        let notes = [makeNote(pitch: 60, startTime: 0)]
        let chunk = makeChunk(notes: notes)
        
        // First grading session
        grader.beginGrading()
        grader.recordAttempt(pitch: 60)
        _ = grader.grade(against: chunk, tempoMultiplier: 1.0)
        
        // Second grading session - should be fresh
        grader.beginGrading()
        // No attempts this time
        let result = grader.grade(against: chunk, tempoMultiplier: 1.0)
        
        XCTAssertEqual(result.correctNotes, 0, "Previous attempts should be cleared")
    }
}
