import SwiftUI

// MARK: - HandView

/// Renders an animated 2D hand with finger-press animations.
/// Each finger lights up with its assigned color when active.
struct HandView: View {

    var hand: Hand = .right
    /// Which fingers are currently pressing (1–5)
    var activeFingers: Set<Finger> = []
    /// Animate position — horizontal offset for thumb-under technique
    var positionOffset: CGFloat = 0

    private let viewSize = CGSize(width: 200, height: 240)
    private let fingers: [Finger] = [1, 2, 3, 4, 5]

    // MARK: - Body

    var body: some View {
        ZStack {
            // Palm
            palmShape
                .fill(Color(red: 0.96, green: 0.82, blue: 0.70))
                .overlay(palmShape.stroke(Color(red: 0.75, green: 0.60, blue: 0.48), lineWidth: 1.5))

            // Fingers
            ForEach(fingers, id: \.self) { finger in
                fingerView(finger: finger)
            }

            // Hand label
            Text(hand == .right ? "R" : "L")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.gray.opacity(0.5))
                .offset(y: 100)
        }
        .frame(width: viewSize.width, height: viewSize.height)
        .offset(x: positionOffset)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: positionOffset)
    }

    // MARK: - Finger view

    @ViewBuilder
    private func fingerView(finger: Finger) -> some View {
        let isActive = activeFingers.contains(finger)
        let joint = FingerPath.joints(finger: finger, hand: hand, pressed: isActive)
        let color = Color(hex: finger.color)

        FingerShape(joint: joint)
            .fill(isActive ? color.opacity(0.85) : Color(red: 0.96, green: 0.82, blue: 0.70))
            .overlay(
                FingerShape(joint: joint)
                    .stroke(isActive ? color : Color(red: 0.75, green: 0.60, blue: 0.48), lineWidth: 1.5)
            )
            .animation(.spring(response: 0.18, dampingFraction: 0.5), value: isActive)
    }

    // MARK: - Palm shape

    private var palmShape: some Shape {
        RoundedRectangle(cornerRadius: 16)
            .size(width: 100, height: 90)
            .offset(x: hand == .right ? 48 : 52, y: 155)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 40) {
        HandView(hand: .left, activeFingers: [3, 5])
        HandView(hand: .right, activeFingers: [1, 3])
    }
    .padding()
    .background(Color(.systemBackground))
}
