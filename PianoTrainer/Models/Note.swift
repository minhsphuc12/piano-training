import Foundation

// MARK: - Hand

enum Hand: String, Codable {
    case left = "left"
    case right = "right"
}

// MARK: - Finger

/// 1 = thumb, 2 = index, 3 = middle, 4 = ring, 5 = pinky
typealias Finger = Int

extension Finger {
    static let thumb: Finger = 1
    static let index: Finger = 2
    static let middle: Finger = 3
    static let ring: Finger = 4
    static let pinky: Finger = 5

    var color: String {
        switch self {
        case 1: return "#FF4444" // red   - thumb
        case 2: return "#FF9500" // orange - index
        case 3: return "#FFD60A" // yellow - middle
        case 4: return "#34C759" // green  - ring
        case 5: return "#0A84FF" // blue   - pinky
        default: return "#FFFFFF"
        }
    }

    var name: String {
        switch self {
        case 1: return "Thumb"
        case 2: return "Index"
        case 3: return "Middle"
        case 4: return "Ring"
        case 5: return "Pinky"
        default: return "?"
        }
    }
}

// MARK: - NoteEvent

struct NoteEvent: Codable, Identifiable {
    let id: UUID
    /// MIDI pitch number (60 = Middle C)
    let pitch: Int
    /// Seconds from the start of this chunk
    let startTime: Double
    /// Duration in seconds
    let duration: Double
    /// Which finger presses this key (1–5)
    let finger: Finger
    /// Which hand
    let hand: Hand
    /// Velocity 0–127
    let velocity: Int

    init(
        id: UUID = UUID(),
        pitch: Int,
        startTime: Double,
        duration: Double,
        finger: Finger,
        hand: Hand,
        velocity: Int = 80
    ) {
        self.id = id
        self.pitch = pitch
        self.startTime = startTime
        self.duration = duration
        self.finger = finger
        self.hand = hand
        self.velocity = velocity
    }
}

// MARK: - MIDI pitch helpers

extension Int {
    /// e.g. 60 -> "C4"
    var noteName: String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = (self / 12) - 1
        let name = noteNames[self % 12]
        return "\(name)\(octave)"
    }

    var isBlackKey: Bool {
        let blackKeys = [1, 3, 6, 8, 10] // offsets within octave
        return blackKeys.contains(self % 12)
    }
}
