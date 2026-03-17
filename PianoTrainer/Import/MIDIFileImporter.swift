import Foundation
import AudioToolbox

struct MIDIImportResult: Sendable {
    let bpm: Double
    let timeSignatureNumerator: Int
    let timeSignatureDenominator: Int
    let notes: [NoteEvent]
    let totalDurationSeconds: Double
}

enum MIDIImportError: Error {
    case invalidFile
    case cannotLoadSequence(OSStatus)
    case cannotReadTracks(OSStatus)
}

private struct _MIDIImporterNoteKey: Hashable {
    let trackIndex: UInt32
    let channel: UInt8
    let pitch: UInt8
}

private struct _MIDIImporterPendingOn: Hashable {
    let startBeat: MusicTimeStamp
    let velocity: UInt8
}

/// Imports a Standard MIDI File (.mid/.midi) into the app's `NoteEvent` format.
///
/// Design notes:
/// - Uses `MusicSequence` (AudioToolbox) to avoid third-party dependencies.
/// - Reads note events from all tracks and merges them by time.
/// - Tempo/time signature parsing is "best effort"; falls back to defaults.
struct MIDIFileImporter {

    /// iOS sandbox import requires security-scoped access for Files app URLs.
    static func importMIDI(from url: URL) throws -> MIDIImportResult {
        let needsSecurityScope = url.startAccessingSecurityScopedResource()
        defer {
            if needsSecurityScope { url.stopAccessingSecurityScopedResource() }
        }

        let data = try Data(contentsOf: url)
        return try importMIDI(from: data)
    }

    static func importMIDI(from data: Data) throws -> MIDIImportResult {
        var sequence: MusicSequence?
        NewMusicSequence(&sequence)
        guard let sequence else { throw MIDIImportError.invalidFile }

        let status = MusicSequenceFileLoadData(
            sequence,
            data as CFData,
            MusicSequenceFileTypeID.midiType,
            MusicSequenceLoadFlags.smf_ChannelsToTracks
        )
        guard status == noErr else { throw MIDIImportError.cannotLoadSequence(status) }

        // Defaults if we can't read meta events reliably.
        var bpm: Double = 120
        var tsNum = 4
        var tsDen = 4

        // Best-effort: read the first tempo event from the tempo track.
        if let tempo = firstTempoBPM(sequence: sequence) {
            bpm = tempo
        }

        // Best-effort: read time signature (if present).
        if let ts = firstTimeSignature(sequence: sequence) {
            tsNum = ts.numerator
            tsDen = ts.denominator
        }

        let mergedNotes = try readAllNotes(sequence: sequence, bpm: bpm)
        let totalDuration = mergedNotes.map { $0.startTime + $0.duration }.max() ?? 0

        return MIDIImportResult(
            bpm: bpm,
            timeSignatureNumerator: tsNum,
            timeSignatureDenominator: tsDen,
            notes: mergedNotes.sorted { $0.startTime < $1.startTime },
            totalDurationSeconds: totalDuration
        )
    }

    // MARK: - Parsing helpers

    private static func readAllNotes(sequence: MusicSequence, bpm: Double) throws -> [NoteEvent] {
        var trackCount: UInt32 = 0
        var status = MusicSequenceGetTrackCount(sequence, &trackCount)
        guard status == noErr else { throw MIDIImportError.cannotReadTracks(status) }

        let secondsPerBeat = 60.0 / max(1, bpm)

        var pending: [_MIDIImporterNoteKey: [_MIDIImporterPendingOn]] = [:]
        var out: [NoteEvent] = []

        for idx in 0..<trackCount {
            var track: MusicTrack?
            status = MusicSequenceGetIndTrack(sequence, idx, &track)
            guard status == noErr, let track else { continue }

            var iterator: MusicEventIterator?
            NewMusicEventIterator(track, &iterator)
            guard let iterator else { continue }
            defer { DisposeMusicEventIterator(iterator) }

            var hasEvent: DarwinBoolean = false
            MusicEventIteratorHasCurrentEvent(iterator, &hasEvent)

            while hasEvent.boolValue {
                var timeStamp: MusicTimeStamp = 0
                var eventType: MusicEventType = 0
                var eventData: UnsafeRawPointer?
                var eventDataSize: UInt32 = 0

                MusicEventIteratorGetEventInfo(iterator, &timeStamp, &eventType, &eventData, &eventDataSize)

                if eventType == kMusicEventType_MIDINoteMessage, let eventData {
                    let msg = eventData.load(as: MIDINoteMessage.self)

                    // MIDINoteMessage has duration already (beats), so we can convert directly.
                    let startSeconds = Double(timeStamp) * secondsPerBeat
                    let durationSeconds = Double(msg.duration) * secondsPerBeat
                    let pitch = Int(msg.note)
                    let velocity = Int(msg.velocity)

                    let hand: Hand = pitch < 60 ? .left : .right
                    let finger = heuristicFinger(hand: hand, pitch: pitch)

                    out.append(
                        NoteEvent(
                            pitch: pitch,
                            startTime: startSeconds,
                            duration: max(0.01, durationSeconds),
                            finger: finger,
                            hand: hand,
                            velocity: velocity
                        )
                    )
                } else if eventType == kMusicEventType_MIDIChannelMessage, let eventData {
                    // Some MIDI files encode note-on/note-off as channel messages.
                    let msg = eventData.load(as: MIDIChannelMessage.self)
                    let statusNibble = msg.status & 0xF0
                    let channel = msg.status & 0x0F

                    // 0x90 note-on, 0x80 note-off. note-on with velocity 0 is note-off.
                    if statusNibble == 0x90 {
                        let pitch = msg.data1
                        let vel = msg.data2
                        if vel == 0 {
                            // treat as note-off
                            flushNoteOff(
                                trackIndex: idx,
                                channel: channel,
                                pitch: pitch,
                                offBeat: timeStamp,
                                secondsPerBeat: secondsPerBeat,
                                pending: &pending,
                                out: &out
                            )
                        } else {
                            let key = _MIDIImporterNoteKey(trackIndex: idx, channel: channel, pitch: pitch)
                            pending[key, default: []].append(_MIDIImporterPendingOn(startBeat: timeStamp, velocity: vel))
                        }
                    } else if statusNibble == 0x80 {
                        flushNoteOff(
                            trackIndex: idx,
                            channel: channel,
                            pitch: msg.data1,
                            offBeat: timeStamp,
                            secondsPerBeat: secondsPerBeat,
                            pending: &pending,
                            out: &out
                        )
                    }
                }

                MusicEventIteratorNextEvent(iterator)
                MusicEventIteratorHasCurrentEvent(iterator, &hasEvent)
            }
        }

        return out
    }

    private static func flushNoteOff(
        trackIndex: UInt32,
        channel: UInt8,
        pitch: UInt8,
        offBeat: MusicTimeStamp,
        secondsPerBeat: Double,
        pending: inout [_MIDIImporterNoteKey: [_MIDIImporterPendingOn]],
        out: inout [NoteEvent]
    ) {
        let key = _MIDIImporterNoteKey(trackIndex: trackIndex, channel: channel, pitch: pitch)
        guard var stack = pending[key], !stack.isEmpty else { return }

        let on = stack.removeLast()
        pending[key] = stack.isEmpty ? nil : stack

        let startSeconds = Double(on.startBeat) * secondsPerBeat
        let durationSeconds = max(0.01, Double(offBeat - on.startBeat) * secondsPerBeat)
        let pitchInt = Int(pitch)
        let velocityInt = Int(on.velocity)

        let hand: Hand = pitchInt < 60 ? .left : .right
        let finger = heuristicFinger(hand: hand, pitch: pitchInt)

        out.append(
            NoteEvent(
                pitch: pitchInt,
                startTime: startSeconds,
                duration: durationSeconds,
                finger: finger,
                hand: hand,
                velocity: velocityInt
            )
        )
    }

    private static func firstTempoBPM(sequence: MusicSequence) -> Double? {
        var tempoTrack: MusicTrack?
        guard MusicSequenceGetTempoTrack(sequence, &tempoTrack) == noErr, let tempoTrack else { return nil }

        var iterator: MusicEventIterator?
        NewMusicEventIterator(tempoTrack, &iterator)
        guard let iterator else { return nil }
        defer { DisposeMusicEventIterator(iterator) }

        var hasEvent: DarwinBoolean = false
        MusicEventIteratorHasCurrentEvent(iterator, &hasEvent)
        while hasEvent.boolValue {
            var timeStamp: MusicTimeStamp = 0
            var eventType: MusicEventType = 0
            var eventData: UnsafeRawPointer?
            var eventDataSize: UInt32 = 0
            MusicEventIteratorGetEventInfo(iterator, &timeStamp, &eventType, &eventData, &eventDataSize)

            if eventType == kMusicEventType_ExtendedTempo, let eventData {
                let tempo = eventData.load(as: ExtendedTempoEvent.self).bpm
                if tempo > 1 { return Double(tempo) }
            }

            MusicEventIteratorNextEvent(iterator)
            MusicEventIteratorHasCurrentEvent(iterator, &hasEvent)
        }
        return nil
    }

    private static func firstTimeSignature(sequence: MusicSequence) -> (numerator: Int, denominator: Int)? {
        // Many files won't expose TS via MusicSequence; treat as optional.
        // We attempt to read `kMusicEventType_Meta` events and decode type 0x58 (time signature).
        var trackCount: UInt32 = 0
        guard MusicSequenceGetTrackCount(sequence, &trackCount) == noErr else { return nil }

        for idx in 0..<trackCount {
            var track: MusicTrack?
            guard MusicSequenceGetIndTrack(sequence, idx, &track) == noErr, let track else { continue }

            var iterator: MusicEventIterator?
            NewMusicEventIterator(track, &iterator)
            guard let iterator else { continue }
            defer { DisposeMusicEventIterator(iterator) }

            var hasEvent: DarwinBoolean = false
            MusicEventIteratorHasCurrentEvent(iterator, &hasEvent)
            while hasEvent.boolValue {
                var timeStamp: MusicTimeStamp = 0
                var eventType: MusicEventType = 0
                var eventData: UnsafeRawPointer?
                var eventDataSize: UInt32 = 0
                MusicEventIteratorGetEventInfo(iterator, &timeStamp, &eventType, &eventData, &eventDataSize)

                if eventType == kMusicEventType_Meta, let eventData {
                    let meta = eventData.load(as: MIDIMetaEvent.self)
                    // Time signature meta: type 0x58, length 4:
                    // nn dd cc bb where dd is log2(denominator)
                    if meta.metaEventType == 0x58, meta.dataLength >= 4 {
                        let base = withUnsafePointer(to: meta.data) { ptr in
                            UnsafeRawPointer(ptr).assumingMemoryBound(to: UInt8.self)
                        }
                        let nn = Int(base[0])
                        let ddPow = Int(base[1])
                        let denom = 1 << ddPow
                        if nn > 0, denom > 0 {
                            return (nn, denom)
                        }
                    }
                }

                MusicEventIteratorNextEvent(iterator)
                MusicEventIteratorHasCurrentEvent(iterator, &hasEvent)
            }
        }

        return nil
    }

    private static func heuristicFinger(hand: Hand, pitch: Int) -> Finger {
        // Very rough default mapping; users can refine later when fingering UI exists.
        let p = pitch
        switch hand {
        case .right:
            if p <= 60 { return 1 }
            if p <= 62 { return 2 }
            if p <= 64 { return 3 }
            if p <= 66 { return 4 }
            return 5
        case .left:
            if p >= 60 { return 1 }
            if p >= 58 { return 2 }
            if p >= 56 { return 3 }
            if p >= 54 { return 4 }
            return 5
        }
    }
}

