import SwiftUI

// MARK: - FingerPath

/// Defines the resting and pressed Path for each finger (1–5) of one hand.
/// Coordinates are normalized to a 200×200 viewBox.

struct FingerJoint {
    let base: CGPoint     // knuckle / base of finger
    let tip: CGPoint      // fingertip
    let width: CGFloat
}

enum FingerPath {

    /// Resting joint positions for right hand, normalized 0–1 in a 200×240 space
    static func joints(finger: Finger, hand: Hand, pressed: Bool) -> FingerJoint {
        let mirror: CGFloat = hand == .left ? -1 : 1
        let cx: CGFloat = 100  // center x
        let pressShift: CGFloat = pressed ? 12 : 0

        switch finger {
        case 1: // Thumb
            let bx = cx + mirror * (-55)
            return FingerJoint(
                base: CGPoint(x: bx, y: 170),
                tip:  CGPoint(x: bx + mirror * (-10), y: 130 + pressShift),
                width: 18
            )
        case 2: // Index
            return FingerJoint(
                base: CGPoint(x: cx + mirror * (-30), y: 160),
                tip:  CGPoint(x: cx + mirror * (-30), y: 90  + pressShift),
                width: 14
            )
        case 3: // Middle
            return FingerJoint(
                base: CGPoint(x: cx + mirror * (-10), y: 155),
                tip:  CGPoint(x: cx + mirror * (-10), y: 80  + pressShift),
                width: 14
            )
        case 4: // Ring
            return FingerJoint(
                base: CGPoint(x: cx + mirror * (10), y: 158),
                tip:  CGPoint(x: cx + mirror * (10), y: 90  + pressShift),
                width: 13
            )
        case 5: // Pinky
            return FingerJoint(
                base: CGPoint(x: cx + mirror * (28), y: 165),
                tip:  CGPoint(x: cx + mirror * (28), y: 110 + pressShift),
                width: 11
            )
        default:
            return FingerJoint(
                base: CGPoint(x: cx, y: 160),
                tip:  CGPoint(x: cx, y: 100),
                width: 12
            )
        }
    }
}

// MARK: - SingleFingerShape

/// A capsule-shaped finger drawn from base to tip.
struct FingerShape: Shape {
    let joint: FingerJoint

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let dx = joint.tip.x - joint.base.x
        let dy = joint.tip.y - joint.base.y
        let length = sqrt(dx * dx + dy * dy)
        guard length > 0 else { return p }

        // Normal vector (perpendicular)
        let nx = -dy / length * joint.width / 2
        let ny =  dx / length * joint.width / 2

        p.move(to: CGPoint(x: joint.base.x + nx, y: joint.base.y + ny))
        p.addLine(to: CGPoint(x: joint.tip.x + nx, y: joint.tip.y + ny))
        // Round tip
        p.addArc(
            center: joint.tip,
            radius: joint.width / 2,
            startAngle: .radians(atan2(Double(ny), Double(nx))),
            endAngle:   .radians(atan2(Double(-ny), Double(-nx))),
            clockwise: false
        )
        p.addLine(to: CGPoint(x: joint.base.x - nx, y: joint.base.y - ny))
        p.closeSubpath()
        return p
    }
}
