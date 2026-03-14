import SwiftUI

// MARK: - ScoreView

/// Shows the result after a practice attempt — stars, accuracy, timing.
struct ScoreView: View {

    let result: GradeResult
    let onRetry: () -> Void
    let onContinue: () -> Void

    @State private var starsShown = 0
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Result")
                .font(.title2.bold())

            // Stars
            HStack(spacing: 8) {
                ForEach(1...3, id: \.self) { i in
                    Image(systemName: i <= starsShown ? "star.fill" : "star")
                        .font(.system(size: 40))
                        .foregroundColor(i <= starsShown ? .yellow : .gray.opacity(0.3))
                        .scaleEffect(appeared && i <= result.stars ? 1.2 : 1.0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.5)
                                .delay(Double(i) * 0.15),
                            value: appeared
                        )
                }
            }

            // Stats
            HStack(spacing: 32) {
                statBlock(
                    label: "Accuracy",
                    value: "\(Int(result.accuracy * 100))%",
                    color: accuracyColor
                )
                statBlock(
                    label: "Notes Hit",
                    value: "\(result.correctNotes)/\(result.totalNotes)",
                    color: .blue
                )
                statBlock(
                    label: "Avg Error",
                    value: "\(Int(result.averageTimingErrorMs))ms",
                    color: .orange
                )
            }

            // Actions
            HStack(spacing: 16) {
                Button(action: onRetry) {
                    Label("Retry", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: onContinue) {
                    Label("Continue", systemImage: "arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(result.stars == 0)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 12)
        .onAppear {
            appeared = true
            animateStars()
        }
    }

    @ViewBuilder
    private func statBlock(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var accuracyColor: Color {
        switch result.accuracy {
        case 0.9...: return .green
        case 0.7...: return .orange
        default:     return .red
        }
    }

    private func animateStars() {
        for i in 1...3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                if i <= result.stars { starsShown = i }
            }
        }
    }
}
