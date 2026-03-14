import SwiftUI

// MARK: - PianoKeyView

/// A single piano key — either white or black.
struct PianoKeyView: View {

    let pitch: Int
    let isHighlighted: Bool
    let highlightFinger: Finger?
    let onPress: (Int) -> Void

    private var isBlack: Bool { pitch.isBlackKey }

    // MARK: - Geometry

    static let whiteKeyWidth: CGFloat = 44
    static let whiteKeyHeight: CGFloat = 160
    static let blackKeyWidth: CGFloat = 28
    static let blackKeyHeight: CGFloat = 100

    var width: CGFloat  { isBlack ? Self.blackKeyWidth  : Self.whiteKeyWidth  }
    var height: CGFloat { isBlack ? Self.blackKeyHeight : Self.whiteKeyHeight }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: isBlack ? 4 : 6)
                .fill(keyFill)
                .overlay(
                    RoundedRectangle(cornerRadius: isBlack ? 4 : 6)
                        .stroke(Color.black.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: .black.opacity(isBlack ? 0.5 : 0.15), radius: 2, y: 2)

            // Finger indicator dot
            if isHighlighted, let finger = highlightFinger {
                Circle()
                    .fill(Color(hex: finger.color))
                    .frame(width: isBlack ? 14 : 18, height: isBlack ? 14 : 18)
                    .padding(.bottom, isBlack ? 6 : 8)
                    .overlay(
                        Text("\(finger)")
                            .font(.system(size: isBlack ? 8 : 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.bottom, isBlack ? 6 : 8)
                    )
            }
        }
        .frame(width: width, height: height)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress(pitch) }
        )
    }

    // MARK: - Color

    private var keyFill: Color {
        if isHighlighted {
            guard let finger = highlightFinger else {
                return isBlack ? .yellow.opacity(0.8) : .yellow.opacity(0.6)
            }
            return Color(hex: finger.color).opacity(isBlack ? 0.85 : 0.65)
        }
        return isBlack ? .black : .white
    }
}

// MARK: - Color hex init

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")))
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >>  8) & 0xFF) / 255
        let b = Double((rgb      ) & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
