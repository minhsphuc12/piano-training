import SwiftUI

// MARK: - ChunkProgressBar

/// Visual map of all chunks in the song — dots that fill as mastered.
struct ChunkProgressBar: View {

    let totalChunks: Int
    let currentChunk: Int
    let masteredChunks: Set<Int>

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalChunks, id: \.self) { i in
                chunkDot(index: i)
            }
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func chunkDot(index: Int) -> some View {
        let isMastered = masteredChunks.contains(index)
        let isCurrent  = index == currentChunk

        ZStack {
            Circle()
                .fill(dotFill(mastered: isMastered, current: isCurrent))
                .frame(width: dotSize(current: isCurrent), height: dotSize(current: isCurrent))
                .overlay(
                    Circle().stroke(isCurrent ? Color.blue : Color.clear, lineWidth: 2)
                )

            if isMastered {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .animation(.spring(response: 0.3), value: isMastered)
    }

    private func dotFill(mastered: Bool, current: Bool) -> Color {
        if mastered { return .green }
        if current  { return .blue.opacity(0.3) }
        return .gray.opacity(0.25)
    }

    private func dotSize(current: Bool) -> CGFloat {
        current ? 18 : 14
    }
}
