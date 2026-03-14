import Foundation

// MARK: - NoteAttempt

struct NoteAttempt {
    let pitch: Int
    let pressedAt: Date
}

// MARK: - GradeResult

struct GradeResult {
    let accuracy: Double        // 0.0 – 1.0
    let correctNotes: Int
    let totalNotes: Int
    let averageTimingErrorMs: Double

    var stars: Int {
        switch accuracy {
        case 0.9...: return 3
        case 0.7...: return 2
        case 0.5...: return 1
        default:     return 0
        }
    }
}

// MARK: - InputGrader

/// Compares the user's note attempts against expected NoteEvents and scores them.
final class InputGrader {

    /// Timing tolerance window in seconds. Notes pressed within this window count as correct.
    var timingToleranceSeconds: Double = 0.15

    private var attempts: [NoteAttempt] = []
    private var chunkStartTime: Date?

    func beginGrading() {
        attempts = []
        chunkStartTime = Date()
    }

    func recordAttempt(pitch: Int) {
        attempts.append(NoteAttempt(pitch: pitch, pressedAt: Date()))
    }

    func grade(against chunk: Chunk, tempoMultiplier: Double) -> GradeResult {
        guard let startTime = chunkStartTime else {
            return GradeResult(accuracy: 0, correctNotes: 0, totalNotes: chunk.notes.count, averageTimingErrorMs: 999)
        }

        let expected = chunk.sortedNotes
        var correctCount = 0
        var totalTimingError: Double = 0
        var matchedAttemptIndices = Set<Int>()

        for event in expected {
            let expectedAbsoluteTime = startTime.addingTimeInterval(event.startTime / tempoMultiplier)

            // Find closest matching attempt with correct pitch within tolerance
            var bestError = Double.infinity
            var bestIdx: Int? = nil

            for (i, attempt) in attempts.enumerated() where !matchedAttemptIndices.contains(i) {
                guard attempt.pitch == event.pitch else { continue }
                let error = abs(attempt.pressedAt.timeIntervalSince(expectedAbsoluteTime))
                if error < timingToleranceSeconds && error < bestError {
                    bestError = error
                    bestIdx = i
                }
            }

            if let idx = bestIdx {
                correctCount += 1
                totalTimingError += bestError
                matchedAttemptIndices.insert(idx)
            }
        }

        let accuracy = expected.isEmpty ? 0 : Double(correctCount) / Double(expected.count)
        let avgErrorMs = correctCount > 0 ? (totalTimingError / Double(correctCount)) * 1000 : 999

        return GradeResult(
            accuracy: accuracy,
            correctNotes: correctCount,
            totalNotes: expected.count,
            averageTimingErrorMs: avgErrorMs
        )
    }
}
