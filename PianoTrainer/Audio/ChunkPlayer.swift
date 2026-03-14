import AVFoundation
import Foundation

// MARK: - ChunkPlayer

/// Plays a sequence of NoteEvents using AVAudioEngine + AVAudioUnitSampler.
/// Also fires callbacks so the UI can sync key highlights and hand animation.
@Observable
final class ChunkPlayer {

    // MARK: - Callbacks (set by ViewModel)

    /// Called when a note begins: (pitch, finger, hand)
    var onNoteOn: ((Int, Finger, Hand) -> Void)?
    /// Called when a note ends: (pitch)
    var onNoteOff: ((Int) -> Void)?
    /// Called when playback finishes the chunk
    var onChunkFinished: (() -> Void)?

    // MARK: - State

    private(set) var isPlaying = false
    private(set) var currentTempoMultiplier: Double = 1.0

    // MARK: - Audio

    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()
    private var scheduledTasks: [Task<Void, Never>] = []

    // MARK: - Init

    init() {
        setupAudioEngine()
    }

    // MARK: - Setup

    private func setupAudioEngine() {
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)

        // Load bundled SoundFont if present; falls back to iOS built-in General MIDI piano
        if let sfURL = Bundle.main.url(forResource: "Piano", withExtension: "sf2") {
            try? sampler.loadSoundBankInstrument(
                at: sfURL,
                program: 0,
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: UInt8(kAUSampler_DefaultBankLSB)
            )
        } else {
            // Use the device's built-in Acoustic Grand Piano (program 0, bank 0)
            try? sampler.loadInstrument(at: builtInPianoURL())
        }

        try? engine.start()

        // Configure audio session
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
    }

    // MARK: - Playback

    func play(chunk: Chunk, tempoMultiplier: Double = 1.0) {
        stop()
        isPlaying = true
        currentTempoMultiplier = tempoMultiplier

        // Schedule each note as an async sleep + MIDI send
        for event in chunk.sortedNotes {
            let adjustedStart = event.startTime / tempoMultiplier
            let adjustedDuration = event.duration / tempoMultiplier
            let pitch = event.pitch
            let velocity = event.velocity
            let finger = event.finger
            let hand = event.hand

            let task = Task {
                let nanos = UInt64(adjustedStart * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanos)
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.sampler.startNote(UInt8(pitch), withVelocity: UInt8(velocity), onChannel: 0)
                    self.onNoteOn?(pitch, finger, hand)
                }

                let offNanos = UInt64(adjustedDuration * 1_000_000_000)
                try? await Task.sleep(nanoseconds: offNanos)
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.sampler.stopNote(UInt8(pitch), onChannel: 0)
                    self.onNoteOff?(pitch)
                }
            }
            scheduledTasks.append(task)
        }

        // Finish callback
        let totalDuration = chunk.totalDuration / tempoMultiplier
        let finishTask = Task {
            let nanos = UInt64(totalDuration * 1_000_000_000) + 200_000_000
            try? await Task.sleep(nanoseconds: nanos)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.isPlaying = false
                self.onChunkFinished?()
            }
        }
        scheduledTasks.append(finishTask)
    }

    func stop() {
        scheduledTasks.forEach { $0.cancel() }
        scheduledTasks.removeAll()
        isPlaying = false
        // All notes off
        for pitch in 0..<128 {
            sampler.stopNote(UInt8(pitch), onChannel: 0)
        }
    }

    // MARK: - Built-in instrument fallback

    /// Returns URL to the iOS built-in General MIDI soundbank, used when no .sf2 is bundled.
    private func builtInPianoURL() -> URL {
        // iOS ships a DLS/SF2 at this path for General MIDI playback
        let paths = [
            "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls",
            "/Library/Audio/Sound Banks/GS Instruments.dls"
        ]
        for path in paths {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: path) { return url }
        }
        // Absolute fallback — sampler will use its own default patch
        return URL(fileURLWithPath: paths[0])
    }

    // MARK: - Single Note Preview (for keyboard touch)

    func previewNote(pitch: Int, velocity: Int = 80) {
        sampler.startNote(UInt8(pitch), withVelocity: UInt8(velocity), onChannel: 0)
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            await MainActor.run {
                self.sampler.stopNote(UInt8(pitch), onChannel: 0)
            }
        }
    }
}
