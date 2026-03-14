# Piano Trainer iOS App — Technical Design Document

## 1. System Overview

### 1.1 Purpose
Ứng dụng iOS dạy đàn piano thông qua phương pháp **chunk-based learning** với ba kênh học tập:
- **Visual**: Xem bàn tay 2D hoạt hình
- **Auditory**: Nghe chunk nhạc trước khi chơi
- **Kinesthetic**: Xây dựng muscle memory qua luyện tập có phản hồi

### 1.2 Target Platform
- **iOS 17+** (yêu cầu `@Observable`, SwiftData)
- **Devices**: iPhone, iPad
- **Orientation**: Portrait (primary), Landscape (future)

### 1.3 High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                           UI Layer                               │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ SongLibraryView │  │  LessonView     │  │   HandView      │  │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘  │
│           │                    │                    │            │
│  ┌────────┴────────────────────┴────────────────────┴────────┐  │
│  │                     KeyboardView                           │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│                      ViewModel Layer                              │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                   LessonViewModel                           │  │
│  │  • PracticePhase state machine                              │  │
│  │  • Active pitches/fingers tracking                          │  │
│  │  • Grading coordination                                      │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│                       Audio Layer                                 │
│  ┌─────────────────────────┐  ┌─────────────────────────────┐    │
│  │      ChunkPlayer        │  │       InputGrader            │    │
│  │  • AVAudioEngine        │  │  • Timing tolerance          │    │
│  │  • AVAudioUnitSampler   │  │  • Pitch matching            │    │
│  │  • Note scheduling      │  │  • Score calculation         │    │
│  └─────────────────────────┘  └─────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│                       Data Layer                                  │
│  ┌─────────────────────────┐  ┌─────────────────────────────┐    │
│  │    Models (Codable)     │  │    SwiftData (Persistent)    │    │
│  │  • Song, Chunk          │  │  • ChunkAttempt              │    │
│  │  • NoteEvent            │  │  • SongProgress              │    │
│  │  • Hand, Finger         │  │  • DailyStreak               │    │
│  └─────────────────────────┘  └─────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────┘
```

---

## 2. Data Models

### 2.1 Core Music Models

#### NoteEvent
Đơn vị nhỏ nhất của dữ liệu âm nhạc.

```swift
struct NoteEvent: Codable, Identifiable {
    let id: UUID
    let pitch: Int          // MIDI pitch (60 = Middle C)
    let startTime: Double   // Seconds from chunk start
    let duration: Double    // Note length in seconds
    let finger: Finger      // 1-5 (thumb to pinky)
    let hand: Hand          // .left / .right
    let velocity: Int       // 0-127 (loudness)
}
```

**Design Decisions:**
- `pitch` sử dụng MIDI standard (0-127) để tương thích với external MIDI devices
- `startTime` relative to chunk start giúp chunks có thể được di chuyển, reorder
- `velocity` chuẩn MIDI để future-proof cho dynamics teaching

#### Chunk
Đơn vị học tập cơ bản (2-4 bars).

```swift
struct Chunk: Codable, Identifiable {
    let id: Int
    let startBar: Int
    let endBar: Int
    let notes: [NoteEvent]
    
    var totalDuration: Double  // computed
    var sortedNotes: [NoteEvent]  // computed
    var involvedPitches: Set<Int>  // computed
}
```

**Design Decisions:**
- `id` là Int sequential trong song, đủ cho persistence
- Bar range (`startBar`/`endBar`) cho sheet music sync future feature
- Computed properties tránh data duplication

#### Song
Container cho metadata và chunks.

```swift
struct Song: Codable, Identifiable {
    let id: String           // UUID or slug
    let title: String
    let composer: String
    let bpm: Double
    let difficulty: Difficulty
    let timeSignatureNumerator: Int
    let timeSignatureDenominator: Int
    let chunks: [Chunk]
}
```

### 2.2 Finger & Hand Enums

```swift
enum Hand: String, Codable {
    case left = "left"
    case right = "right"
}

typealias Finger = Int  // 1 = thumb ... 5 = pinky

extension Finger {
    var color: String  // Hex color code
    var name: String   // Localized name
}
```

**Color Convention:**

| Finger | Color | Hex |
|--------|-------|-----|
| Thumb (1) | Red | `#FF4444` |
| Index (2) | Orange | `#FF9500` |
| Middle (3) | Yellow | `#FFD60A` |
| Ring (4) | Green | `#34C759` |
| Pinky (5) | Blue | `#0A84FF` |

### 2.3 Persistence Models (SwiftData)

```swift
@Model
final class ChunkAttempt {
    var chunkId: Int
    var songId: String
    var timestamp: Date
    var accuracy: Double        // 0.0 – 1.0
    var consecutiveCorrect: Int
}

@Model
final class SongProgress {
    var songId: String
    var masteredChunkIds: [Int]
    var lastPracticed: Date
    var totalPracticeSeconds: Double
}

@Model
final class DailyStreak {
    var practiceDates: [Date]
    var currentStreak: Int  // computed
}
```

---

## 3. Audio System Architecture

### 3.1 ChunkPlayer Design

```
┌─────────────────────────────────────────────────────────────┐
│                      ChunkPlayer                             │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │ AVAudioEngine│───▶│ Sampler     │───▶│ MainMixer   │───▶ Output
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│                            │                                 │
│                     ┌──────┴──────┐                         │
│                     │  SoundFont  │                         │
│                     │  (Piano.sf2)│                         │
│                     └─────────────┘                         │
├─────────────────────────────────────────────────────────────┤
│  Scheduling: Swift async/await Tasks                        │
│                                                              │
│  for note in chunk.sortedNotes {                            │
│      Task {                                                  │
│          await sleep(note.startTime / tempo)                │
│          sampler.startNote(note.pitch)                      │
│          await sleep(note.duration / tempo)                 │
│          sampler.stopNote(note.pitch)                       │
│      }                                                       │
│  }                                                           │
└─────────────────────────────────────────────────────────────┘
```

**Key Design Choices:**

1. **AVAudioEngine over AVAudioPlayer**: Low-latency, real-time MIDI control
2. **AVAudioUnitSampler**: Native SoundFont support, no external dependencies
3. **Swift async/await over Timer**: Clean cancellation, no race conditions
4. **Callback-based UI sync**: `onNoteOn`, `onNoteOff`, `onChunkFinished`

### 3.2 Timing Flow

```
Time ──────────────────────────────────────────────────────▶

     │ play() called
     ▼
     ┌────────────────────────────────────────────────────┐
     │  Task.sleep(adjustedStartTime)                     │
     └────────────────────────────────────────────────────┘
                                   │
                                   ▼ onNoteOn(pitch, finger, hand)
                                   │
     ┌─────────────────────────────┼──────────────────────┐
     │  sampler.startNote()        │                      │
     │                             │                      │
     │  Task.sleep(adjustedDuration)                      │
     │                             │                      │
     │                             ▼ onNoteOff(pitch)     │
     │  sampler.stopNote()                                │
     └────────────────────────────────────────────────────┘
```

### 3.3 Tempo Adjustment

```swift
let adjustedStart = event.startTime / tempoMultiplier
let adjustedDuration = event.duration / tempoMultiplier
```

- `tempoMultiplier = 1.0`: Original tempo
- `tempoMultiplier = 0.5`: Half speed (slower, for beginners)
- `tempoMultiplier = 0.7`: Default practice speed (70%)

---

## 4. State Management

### 4.1 PracticePhase State Machine

```
                    ┌─────────────┐
                    │   START     │
                    └──────┬──────┘
                           │
                           ▼
              ┌─────────────────────────┐
              │        LISTEN           │◀──────────────┐
              │  App plays, user watches│               │
              └────────────┬────────────┘               │
                           │ user taps "Shadow"         │
                           ▼                            │
              ┌─────────────────────────┐               │
              │        SHADOW           │               │
              │  App plays, user mirrors│               │
              └────────────┬────────────┘               │
                           │ user taps "Practice"       │
                           ▼                            │
              ┌─────────────────────────┐               │
              │       PRACTICE          │               │
              │  User plays, app grades │               │
              └────────────┬────────────┘               │
                           │ chunk finishes             │
                           ▼                            │
              ┌─────────────────────────┐               │
              │        RESULT           │               │
              │  Show score + feedback  │               │
              └────────────┬────────────┘               │
                           │                            │
            ┌──────────────┼──────────────┐             │
            │ accuracy<70% │ accuracy≥70% │             │
            │ OR streak<3  │ AND streak≥3 │             │
            ▼              ▼              │             │
    ┌───────────┐  ┌───────────────┐      │             │
    │  RETRY    │  │   MASTERED    │      │             │
    │ (listen)  │  │  chunk done   │      │             │
    └─────┬─────┘  └───────┬───────┘      │             │
          │                │              │             │
          │                ▼              │             │
          │    ┌─────────────────────┐    │             │
          │    │   NEXT CHUNK?       │    │             │
          │    └──────────┬──────────┘    │             │
          │               │ yes           │             │
          │               ▼               │             │
          └───────────────┴───────────────┴─────────────┘
```

### 4.2 LessonViewModel State

```swift
@Observable
final class LessonViewModel {
    // Immutable
    let song: Song
    
    // Chunk navigation
    private(set) var currentChunkIndex: Int = 0
    private(set) var phase: PracticePhase = .listen
    
    // Tempo control
    private(set) var tempoMultiplier: Double = 0.7
    
    // Real-time UI state (for keyboard + hand animation)
    private(set) var activePitches: Set<Int> = []
    private(set) var activeFingers: [Int: Finger] = [:]
    private(set) var activeHands: [Int: Hand] = [:]
    
    // Grading
    private(set) var lastGradeResult: GradeResult?
    private(set) var consecutiveCorrect: Int = 0
    private let masteryThreshold = 3
    
    // Audio components
    let player = ChunkPlayer()
    private let grader = InputGrader()
}
```

**Reactive Bindings:**

```swift
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
```

---

## 5. Input Grading Algorithm

### 5.1 Overview

```
User Input               Expected Notes
    │                          │
    ▼                          ▼
┌─────────┐              ┌─────────┐
│ Record  │              │  Load   │
│ Attempts│              │  Chunk  │
└────┬────┘              └────┬────┘
     │                        │
     └──────────┬─────────────┘
                │
                ▼
        ┌───────────────┐
        │    MATCH      │
        │  pitch + time │
        └───────┬───────┘
                │
                ▼
        ┌───────────────┐
        │  CALCULATE    │
        │  accuracy     │
        │  timing error │
        │  stars        │
        └───────────────┘
```

### 5.2 Matching Algorithm

```swift
func grade(against chunk: Chunk, tempoMultiplier: Double) -> GradeResult {
    for event in expected {
        let expectedAbsoluteTime = startTime.addingTimeInterval(
            event.startTime / tempoMultiplier
        )
        
        // Find closest matching attempt:
        // 1. Same pitch
        // 2. Within timing tolerance (±150ms default)
        // 3. Not already matched
        
        for attempt in attempts where !matched.contains(attempt) {
            if attempt.pitch == event.pitch {
                let error = abs(attempt.pressedAt - expectedAbsoluteTime)
                if error < timingTolerance && error < bestError {
                    bestError = error
                    bestMatch = attempt
                }
            }
        }
    }
}
```

### 5.3 Scoring Rules

| Accuracy | Stars | Outcome |
|----------|-------|---------|
| ≥90% | 3 | Excellent |
| ≥70% | 2 | Good (counts toward mastery) |
| ≥50% | 1 | Needs practice |
| <50% | 0 | Retry recommended |

**Mastery Condition:**
- 3 consecutive attempts with accuracy ≥70%
- Streak resets on any attempt <70%

---

## 6. UI Component Hierarchy

### 6.1 View Tree

```
PianoTrainerApp
└── NavigationStack
    ├── SongLibraryView
    │   └── List (grouped by Difficulty)
    │       └── NavigationLink → LessonPlayerView
    │
    └── LessonPlayerView
        ├── VStack
        │   ├── ChunkProgressBar (dot indicators)
        │   │
        │   ├── HStack (Hands)
        │   │   ├── HandView(hand: .left)
        │   │   └── HandView(hand: .right)
        │   │
        │   ├── KeyboardView (2 octaves)
        │   │   └── ForEach pitch in range
        │   │       └── PianoKeyView
        │   │
        │   ├── PhaseControlBar
        │   │   ├── Button("Listen")
        │   │   ├── Button("Shadow")
        │   │   ├── Button("Practice")
        │   │   └── Slider(tempo)
        │   │
        │   └── ScoreView (when phase == .result)
        │       ├── Stars display
        │       ├── Accuracy %
        │       ├── Timing error ms
        │       └── Action buttons
```

### 6.2 KeyboardView Design

```
┌───────────────────────────────────────────────────────────────────────┐
│                           KeyboardView                                 │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │  ZStack                                                          │  │
│  │  ┌─────────────────────────────────────────────────────────────┐│  │
│  │  │ White Keys (C D E F G A B) × 2 octaves                      ││  │
│  │  │ ┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐ ...             ││  │
│  │  │ │ C  ││ D  ││ E  ││ F  ││ G  ││ A  ││ B  │                 ││  │
│  │  │ │    ││    ││    ││    ││    ││    ││    │                 ││  │
│  │  │ │ ●  ││    ││    ││    ││    ││    ││    │ ← finger dot    ││  │
│  │  │ └────┘└────┘└────┘└────┘└────┘└────┘└────┘                 ││  │
│  │  └─────────────────────────────────────────────────────────────┘│  │
│  │  ┌─────────────────────────────────────────────────────────────┐│  │
│  │  │ Black Keys (overlay)                                        ││  │
│  │  │    ┌──┐  ┌──┐     ┌──┐  ┌──┐  ┌──┐                        ││  │
│  │  │    │C#│  │D#│     │F#│  │G#│  │A#│                        ││  │
│  │  │    └──┘  └──┘     └──┘  └──┘  └──┘                        ││  │
│  │  └─────────────────────────────────────────────────────────────┘│  │
│  └─────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────┘
```

**Range:** C4 (60) → B5 (83) = 2 octaves

### 6.3 HandView Animation

```swift
struct HandView: View {
    var hand: Hand
    var activeFingers: Set<Finger>
    
    var body: some View {
        ZStack {
            palmShape
            ForEach(fingers) { finger in
                FingerShape(joint: joints(finger, pressed: isActive))
                    .fill(isActive ? finger.color : skinColor)
                    .animation(.spring(response: 0.18))
            }
        }
    }
}
```

**Animation specs:**
- Spring response: 0.18s
- Damping fraction: 0.5
- Finger press visual: color fill + slight y-offset

---

## 7. Data Flow Diagrams

### 7.1 Listen Phase

```
User taps "Listen"
        │
        ▼
┌───────────────┐
│LessonViewModel│
│ .startListen()│
└───────┬───────┘
        │ play(chunk, tempo)
        ▼
┌───────────────┐
│  ChunkPlayer  │
│  schedules    │
│  note tasks   │
└───────┬───────┘
        │
   ┌────┴────┐
   │ for each│
   │  note   │
   └────┬────┘
        │
        ▼
┌───────────────┐         ┌───────────────┐
│  onNoteOn()   │────────▶│  ViewModel    │
│  callback     │         │  updates:     │
└───────────────┘         │ activePitches │
                          │ activeFingers │
                          │ activeHands   │
                          └───────┬───────┘
                                  │
                    ┌─────────────┴─────────────┐
                    ▼                           ▼
            ┌───────────────┐           ┌───────────────┐
            │  KeyboardView │           │   HandView    │
            │  highlights   │           │  finger press │
            │  keys         │           │  animation    │
            └───────────────┘           └───────────────┘
```

### 7.2 Practice Phase

```
User taps "Practice"
        │
        ▼
┌───────────────┐
│LessonViewModel│
│.startPractice()│
└───────┬───────┘
        │
   ┌────┴────────────────────┐
   │                         │
   ▼                         ▼
┌───────────────┐    ┌───────────────┐
│  ChunkPlayer  │    │  InputGrader  │
│  plays audio  │    │.beginGrading()│
└───────────────┘    └───────┬───────┘
                             │
                             │ (grader records start time)
                             │
        User presses keys    │
              │              │
              ▼              │
      ┌───────────────┐      │
      │  KeyboardView │      │
      │  touch event  │      │
      └───────┬───────┘      │
              │              │
              ▼              │
      ┌───────────────┐      │
      │  ViewModel    │      │
      │.userPressedKey│──────┤
      └───────────────┘      │
              │              │
              ▼              ▼
      ┌───────────────┐  ┌───────────────┐
      │  ChunkPlayer  │  │  InputGrader  │
      │.previewNote() │  │.recordAttempt │
      └───────────────┘  │  (pitch,time) │
                         └───────────────┘
                                 │
            Chunk finishes       │
                    │            │
                    ▼            │
            ┌───────────────┐    │
            │  onChunk      │    │
            │  Finished()   │    │
            └───────┬───────┘    │
                    │            │
                    ▼            ▼
            ┌─────────────────────────┐
            │  grader.grade(chunk)    │
            │  → GradeResult          │
            └───────────┬─────────────┘
                        │
                        ▼
            ┌─────────────────────────┐
            │  Update state:          │
            │  • lastGradeResult      │
            │  • consecutiveCorrect   │
            │  • phase → .result      │
            │           or .mastered  │
            └─────────────────────────┘
```

---

## 8. Error Handling Strategy

### 8.1 Audio Errors

| Error | Handling |
|-------|----------|
| SoundFont not found | Fallback to built-in iOS General MIDI |
| AVAudioSession activation fails | Log warning, continue with degraded audio |
| Engine fails to start | Show user alert, disable audio features |

### 8.2 Data Errors

| Error | Handling |
|-------|----------|
| JSON decode fails | Return empty song list, log error |
| SwiftData save fails | Retry once, then show error toast |
| Invalid MIDI pitch | Clamp to 0-127 range |

### 8.3 Graceful Degradation

```swift
// SoundFont fallback
if let sfURL = Bundle.main.url(forResource: "Piano", withExtension: "sf2") {
    try? sampler.loadSoundBankInstrument(at: sfURL, ...)
} else {
    try? sampler.loadInstrument(at: builtInPianoURL())
}
```

---

## 9. Performance Considerations

### 9.1 Memory Management

- **ChunkPlayer**: Tasks are stored in array, cancelled on `stop()`
- **ViewModel**: Weak self in callbacks to prevent retain cycles
- **SwiftData**: Lazy loading for large song libraries

### 9.2 UI Performance

- **Keyboard animation**: Only changed keys re-render via `@Observable`
- **Hand animation**: Spring animation handled by SwiftUI, no manual frame updates
- **Large lists**: `LazyVStack` for song library

### 9.3 Audio Latency

| Factor | Optimization |
|--------|--------------|
| Note scheduling | async/await với nanosecond precision |
| Audio session | `.playback` mode, low buffer |
| SoundFont loading | Done once at init, cached in sampler |

---

## 10. Security & Privacy

### 10.1 Data Privacy

- **No network calls**: All data bundled locally
- **No analytics**: No tracking or telemetry
- **SwiftData**: Local-only storage, no cloud sync (Phase 4 sẽ add optional iCloud)

### 10.2 Input Validation

```swift
// Pitch validation
guard (0...127).contains(pitch) else { return }

// Velocity validation
let safeVelocity = min(127, max(0, velocity))

// Timing validation
guard startTime >= 0, duration > 0 else { return }
```

---

## 11. Testing Strategy

### 11.1 Unit Tests

| Component | Tests |
|-----------|-------|
| `NoteEvent` | Codable round-trip, pitch helpers |
| `Chunk` | Duration calculation, sorting |
| `InputGrader` | Accuracy calculation, timing tolerance |
| `GradeResult` | Stars calculation |

### 11.2 Integration Tests

| Flow | Test |
|------|------|
| Listen phase | Play chunk, verify callbacks fire in order |
| Practice phase | Simulate key presses, verify grading |
| Mastery | 3 correct attempts → phase transition |

### 11.3 UI Tests

| Screen | Tests |
|--------|-------|
| SongLibraryView | Song list displays, navigation works |
| KeyboardView | Key highlights on note, touch response |
| ScoreView | Stars display correctly per accuracy |

---

## 12. Future Architecture Extensions

### 12.1 CoreMIDI Integration (Phase 2)

```
┌─────────────────┐
│  MIDIManager    │
│  (new class)    │
└────────┬────────┘
         │ delegates to
         ▼
┌─────────────────┐
│  InputGrader    │ ← same grading logic
└─────────────────┘
```

### 12.2 Sheet Music View (Phase 3)

```
┌─────────────────────────────────────┐
│         SheetMusicView              │
│  ┌───────────────────────────────┐  │
│  │ StaffRenderer (custom Canvas) │  │
│  │ • Current note highlight      │  │
│  │ • Scroll with playback        │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

### 12.3 iCloud Sync (Phase 4)

```
SwiftData + CloudKit
    │
    ▼
┌───────────────────────────────────┐
│  @Model with iCloud container     │
│  • ChunkAttempt → synced          │
│  • SongProgress → synced          │
│  • DailyStreak → synced           │
└───────────────────────────────────┘
```

---

## 13. Dependencies

### 13.1 First-Party

| Framework | Usage |
|-----------|-------|
| SwiftUI | UI framework |
| SwiftData | Persistence |
| AVFoundation | Audio engine, sampler |
| Combine | (minimal, for publishers if needed) |

### 13.2 Third-Party

**None** — App is dependency-free for maximum stability.

### 13.3 Optional Assets

| Asset | Purpose | Default |
|-------|---------|---------|
| `Piano.sf2` | High-quality piano sound | Falls back to iOS General MIDI |

---

## 14. Glossary

| Term | Definition |
|------|------------|
| **Chunk** | 2-4 bar segment of a song, the learning unit |
| **Phase** | Current stage in learning loop (Listen/Shadow/Practice/Result/Mastered) |
| **Mastery** | 3 consecutive practice attempts with ≥70% accuracy |
| **Finger dot** | Colored circle on piano key indicating which finger to use |
| **Tempo multiplier** | Speed adjustment (0.4 = slow, 1.0 = original) |
| **Timing tolerance** | Window for correct note timing (default ±150ms) |

---

## 15. Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-03-14 | Initial technical design document |
