import XCTest
@testable import PianoTrainer

final class NoteTests: XCTestCase {
    
    // MARK: - Finger Color Tests (N-01 to N-03)
    
    func testFingerColorMapping() {
        XCTAssertEqual(Finger.thumb.color, "#FF4444", "Thumb should be red")
        XCTAssertEqual(Finger.index.color, "#FF9500", "Index should be orange")
        XCTAssertEqual(Finger.middle.color, "#FFD60A", "Middle should be yellow")
        XCTAssertEqual(Finger.ring.color, "#34C759", "Ring should be green")
        XCTAssertEqual(Finger.pinky.color, "#0A84FF", "Pinky should be blue")
    }
    
    func testInvalidFingerColor() {
        let invalidFinger: Finger = 0
        XCTAssertEqual(invalidFinger.color, "#FFFFFF")
        
        let outOfRange: Finger = 6
        XCTAssertEqual(outOfRange.color, "#FFFFFF")
    }
    
    // MARK: - Finger Name Tests (N-04)
    
    func testFingerNameMapping() {
        XCTAssertEqual(Finger.thumb.name, "Thumb")
        XCTAssertEqual(Finger.index.name, "Index")
        XCTAssertEqual(Finger.middle.name, "Middle")
        XCTAssertEqual(Finger.ring.name, "Ring")
        XCTAssertEqual(Finger.pinky.name, "Pinky")
    }
    
    func testInvalidFingerName() {
        let invalidFinger: Finger = 0
        XCTAssertEqual(invalidFinger.name, "?")
    }
    
    // MARK: - MIDI Note Name Tests (N-05 to N-07)
    
    func testMIDIToNoteName() {
        XCTAssertEqual(60.noteName, "C4", "Middle C")
        XCTAssertEqual(61.noteName, "C#4")
        XCTAssertEqual(62.noteName, "D4")
        XCTAssertEqual(69.noteName, "A4", "A440")
        XCTAssertEqual(72.noteName, "C5")
        XCTAssertEqual(48.noteName, "C3")
    }
    
    func testMIDIOctaveCalculation() {
        XCTAssertEqual(12.noteName, "C0")
        XCTAssertEqual(24.noteName, "C1")
        XCTAssertEqual(36.noteName, "C2")
        XCTAssertEqual(84.noteName, "C6")
    }
    
    // MARK: - Black/White Key Tests (N-08, N-09)
    
    func testBlackKeyDetection() {
        // Black keys: C#, D#, F#, G#, A#
        XCTAssertTrue(61.isBlackKey, "C#4")
        XCTAssertTrue(63.isBlackKey, "D#4")
        XCTAssertTrue(66.isBlackKey, "F#4")
        XCTAssertTrue(68.isBlackKey, "G#4")
        XCTAssertTrue(70.isBlackKey, "A#4")
    }
    
    func testWhiteKeyDetection() {
        // White keys: C, D, E, F, G, A, B
        XCTAssertFalse(60.isBlackKey, "C4")
        XCTAssertFalse(62.isBlackKey, "D4")
        XCTAssertFalse(64.isBlackKey, "E4")
        XCTAssertFalse(65.isBlackKey, "F4")
        XCTAssertFalse(67.isBlackKey, "G4")
        XCTAssertFalse(69.isBlackKey, "A4")
        XCTAssertFalse(71.isBlackKey, "B4")
    }
    
    // MARK: - NoteEvent Tests (N-10, N-11)
    
    func testNoteEventDefaultVelocity() {
        let note = NoteEvent(
            pitch: 60,
            startTime: 0,
            duration: 0.5,
            finger: .thumb,
            hand: .right
        )
        XCTAssertEqual(note.velocity, 80, "Default velocity should be 80")
    }
    
    func testNoteEventCodable() throws {
        let original = NoteEvent(
            pitch: 64,
            startTime: 1.5,
            duration: 0.25,
            finger: .middle,
            hand: .left,
            velocity: 100
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(NoteEvent.self, from: data)
        
        XCTAssertEqual(decoded.pitch, original.pitch)
        XCTAssertEqual(decoded.startTime, original.startTime)
        XCTAssertEqual(decoded.duration, original.duration)
        XCTAssertEqual(decoded.finger, original.finger)
        XCTAssertEqual(decoded.hand, original.hand)
        XCTAssertEqual(decoded.velocity, original.velocity)
    }
    
    // MARK: - Hand Enum Tests (N-12)
    
    func testHandCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let leftData = try encoder.encode(Hand.left)
        let decodedLeft = try decoder.decode(Hand.self, from: leftData)
        XCTAssertEqual(decodedLeft, .left)
        
        let rightData = try encoder.encode(Hand.right)
        let decodedRight = try decoder.decode(Hand.self, from: rightData)
        XCTAssertEqual(decodedRight, .right)
    }
    
    func testHandRawValues() {
        XCTAssertEqual(Hand.left.rawValue, "left")
        XCTAssertEqual(Hand.right.rawValue, "right")
    }
}
