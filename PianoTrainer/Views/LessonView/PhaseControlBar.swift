import SwiftUI

// MARK: - PhaseControlBar

/// Bottom control strip: phase buttons + tempo slider.
struct PhaseControlBar: View {

    @Binding var tempoMultiplier: Double
    let phase: PracticePhase
    let isPlaying: Bool

    let onListen:   () -> Void
    let onShadow:   () -> Void
    let onPractice: () -> Void
    let onStop:     () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Phase buttons
            HStack(spacing: 12) {
                phaseButton(
                    title: "Listen",
                    icon: "ear.fill",
                    color: .blue,
                    isActive: phase == .listen,
                    action: onListen
                )
                phaseButton(
                    title: "Shadow",
                    icon: "hand.raised.fill",
                    color: .purple,
                    isActive: phase == .shadow,
                    action: onShadow
                )
                phaseButton(
                    title: "Play",
                    icon: "music.note",
                    color: .green,
                    isActive: phase == .practice,
                    action: onPractice
                )

                if isPlaying {
                    Button(action: onStop) {
                        Image(systemName: "stop.fill")
                            .foregroundColor(.red)
                            .frame(width: 44, height: 44)
                            .background(Color.red.opacity(0.12))
                            .clipShape(Circle())
                    }
                }
            }

            // Tempo slider
            HStack {
                Image(systemName: "tortoise.fill")
                    .foregroundColor(.secondary)
                Slider(value: $tempoMultiplier, in: 0.4...1.0, step: 0.05)
                    .tint(.blue)
                Image(systemName: "hare.fill")
                    .foregroundColor(.secondary)
                Text("\(Int(tempoMultiplier * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
                    .frame(width: 36)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func phaseButton(
        title: String,
        icon: String,
        color: Color,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.caption2.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundColor(isActive ? .white : color)
            .background(isActive ? color : color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
