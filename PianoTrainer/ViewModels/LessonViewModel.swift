import Foundation
import SwiftUI

// MARK: - PracticePhase

enum PracticePhase: String, CaseIterable {
    case listen   = "Listen"    // app plays, user watches
    case shadow   = "Shadow"    // user mirrors, no grading
    case practice = "Practice"  // user plays, graded
    case result   = "Result"    // show score, decide next step
    case mastered = "Mastered"  // chunk complete
}

// MARK: - LessonViewModel

@Observable
final class LessonViewModel {

    // MARK: - Song & Chunk

    let song: Song
    private(set) var currentChunkIndex: Int = 0
    private(set) var phase: PracticePhase = .listen
    private(set) var tempoMultiplier: Double = 0.7

    var currentChunk: Chunk { song.chunks[currentChunkIndex] }
    var isLastChunk: Bool { currentChunkIndex == song.chunks.count - 1 }

    // MARK: - Active note state (for UI sync)

    /// Pitches currently being played (for keyboard highlight)
    private(set) var activePitches: Set<Int> = []
    /// Finger currently pressing each pitch
    private(set) var activeFingers: [Int: Finger] = [:]
    /// Hand currently pressing each pitch
    private(set) var activeHands: [Int: Hand] = [:]

    // MARK: - Grading

    private(set) var lastGradeResult: GradeResult?
    private(set) var consecutiveCorrect: Int = 0
    private let masteryThreshold = 3

    // MARK: - Audio

    let player = ChunkPlayer()
    private let grader = InputGrader()

    // MARK: - Init

    init(song: Song) {
        self.song = song
        bindPlayerCallbacks()
    }

    // MARK: - Player Binding

    private func bindPlayerCallbacks() {
        player.onNoteOn = { [weak self] pitch, finger, hand in
            self?.activePitches.insert(pitch)
            self?.activeFingers[pitch] = finger
            self?.activeHands[pitch] = hand
        }
        player.onNoteOff = { [weak self] pitch in
            self?.activePitches.remove(pitch)
            self?.activeFingers.removeValue(forKey: pitch)
            self?.activeHands.removeValue(forKey: pitch)
        }
        player.onChunkFinished = { [weak self] in
            self?.handleChunkFinished()
        }
    }

    // MARK: - Phase transitions

    func startListen() {
        phase = .listen
        player.play(chunk: currentChunk, tempoMultiplier: tempoMultiplier)
    }

    func startShadow() {
        phase = .shadow
        player.play(chunk: currentChunk, tempoMultiplier: tempoMultiplier)
    }

    func startPractice() {
        phase = .practice
        grader.beginGrading()
        // Play the chunk alongside so user hears the beat
        // (can be toggled off in settings)
        player.play(chunk: currentChunk, tempoMultiplier: tempoMultiplier)
    }

    /// Called by keyboard view when user presses a key
    func userPressedKey(pitch: Int) {
        if phase == .practice {
            grader.recordAttempt(pitch: pitch)
        }
        player.previewNote(pitch: pitch)
    }

    func setTempo(_ multiplier: Double) {
        tempoMultiplier = multiplier
        player.stop()
    }

    // MARK: - Internal

    private func handleChunkFinished() {
        if phase == .practice {
            let result = grader.grade(against: currentChunk, tempoMultiplier: tempoMultiplier)
            lastGradeResult = result

            if result.accuracy >= 0.7 {
                consecutiveCorrect += 1
            } else {
                consecutiveCorrect = 0
            }

            if consecutiveCorrect >= masteryThreshold {
                phase = .mastered
            } else {
                phase = .result
            }
        }
    }

    func advanceToNextChunk() {
        guard !isLastChunk else { return }
        currentChunkIndex += 1
        consecutiveCorrect = 0
        lastGradeResult = nil
        phase = .listen
        startListen()
    }

    func replayCurrentChunk() {
        consecutiveCorrect = 0
        lastGradeResult = nil
        startListen()
    }
    
    // MARK: - Manual Navigation
    
    /// Move to the next chunk manually (user-initiated)
    func goToNextChunk() {
        guard !isLastChunk else { return }
        player.stop()
        currentChunkIndex += 1
        consecutiveCorrect = 0
        lastGradeResult = nil
        phase = .listen
        startListen()
    }
    
    /// Move to the previous chunk manually (user-initiated)
    func goToPreviousChunk() {
        guard currentChunkIndex > 0 else { return }
        player.stop()
        currentChunkIndex -= 1
        consecutiveCorrect = 0
        lastGradeResult = nil
        phase = .listen
        startListen()
    }
}
