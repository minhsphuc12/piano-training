import SwiftUI

// MARK: - KeyboardView

/// Renders a 2-octave (or configurable) piano keyboard.
/// White keys are laid out first; black keys are overlaid at their proper positions.
struct KeyboardView: View {

    // MARK: - Configuration

    /// Starting MIDI pitch (default 48 = C3, gives comfortable 2-octave range)
    var startPitch: Int = 48
    /// Number of octaves to display
    var octaveCount: Int = 2

    // MARK: - State from ViewModel

    var activePitches: Set<Int>
    var activeFingers: [Int: Finger]
    var onKeyPress: (Int) -> Void

    // MARK: - Layout helpers

    private var allPitches: [Int] {
        (startPitch..<(startPitch + octaveCount * 12)).map { $0 }
    }

    private var whitePitches: [Int] {
        allPitches.filter { !$0.isBlackKey }
    }

    /// Maps a pitch to its x-offset within the keyboard
    private func xOffset(for pitch: Int) -> CGFloat {
        // Find position of the white key to the left of this black key
        let noteInOctave = pitch % 12
        let blackKeyOffsets: [Int: CGFloat] = [
            1: 0.65, 3: 1.65, 6: 3.65, 8: 4.65, 10: 5.65
        ]
        guard let fraction = blackKeyOffsets[noteInOctave] else { return 0 }

        let octaveOffset = CGFloat((pitch - startPitch) / 12)
        let keysPerOctave: CGFloat = 7 // white keys per octave
        return (octaveOffset * keysPerOctave + fraction) * PianoKeyView.whiteKeyWidth
    }

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                // White keys row
                HStack(spacing: 1) {
                    ForEach(whitePitches, id: \.self) { pitch in
                        PianoKeyView(
                            pitch: pitch,
                            isHighlighted: activePitches.contains(pitch),
                            highlightFinger: activeFingers[pitch],
                            onPress: onKeyPress
                        )
                    }
                }

                // Black keys overlaid
                ForEach(allPitches.filter(\.isBlackKey), id: \.self) { pitch in
                    PianoKeyView(
                        pitch: pitch,
                        isHighlighted: activePitches.contains(pitch),
                        highlightFinger: activeFingers[pitch],
                        onPress: onKeyPress
                    )
                    .offset(x: xOffset(for: pitch), y: 0)
                }
            }
            .padding(.horizontal, 12)
        }
        .frame(height: PianoKeyView.whiteKeyHeight + 20)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    KeyboardView(
        activePitches: [60, 64, 67],  // C major chord
        activeFingers: [60: 1, 64: 3, 67: 5],
        onKeyPress: { _ in }
    )
    .padding()
}
