# Piano Trainer iOS App — Project Plan

## What We Decided

### Core Problem
Build an iOS app that teaches piano through **three simultaneous learning channels**:
- **Visual** — watch a 2D animated hand show which finger presses which key
- **Auditory** — hear each chunk of music before playing it
- **Kinesthetic** — build muscle memory through guided, graded repetition

### Learning Loop (key design decision)
Instead of playing a full song, the app breaks every song into **chunks** (2–4 bars) and cycles through:
```
Listen → Shadow → Practice → Score → (repeat until mastered) → next chunk
```
- **Listen**: App plays the chunk. Keys highlight. Hand animates. User just watches + listens.
- **Shadow**: App plays again. User mirrors the hand movement with no grading pressure.
- **Practice**: User plays. App grades timing accuracy (±150ms window).
- **Mastery**: 3 consecutive correct plays (≥70% accuracy) → chunk is marked done → advance.

### Architecture Decisions
| Decision | Choice | Reason |
|---|---|---|
| UI framework | SwiftUI + `@Observable` | iOS 17+, less boilerplate than `ObservableObject` |
| Audio | AVAudioEngine + AVAudioUnitSampler | Low latency, SoundFont support, built-in fallback |
| Note scheduling | Swift async/await Tasks | Clean cancellation, no timer race conditions |
| Storage | SwiftData | Native iOS 17 persistence, no third-party deps |
| Song format | JSON (bundled) | Easy to edit, version, and expand |
| Hand animation | 2D SwiftUI shapes | Faster to build than 3D SceneKit; sufficient for the learning goal |
| Finger colors | Thumb=red, Index=orange, Middle=yellow, Ring=green, Pinky=blue | Consistent across keyboard keys and hand view |

---

## What Is Already Built

### Project structure
```
piano-training/
├── project.yml                          ← XcodeGen config
├── PianoTrainer.xcodeproj               ← Generated Xcode project ✓
└── PianoTrainer/
    ├── PianoTrainerApp.swift            ← App entry + SwiftData container ✓
    ├── Models/
    │   ├── Note.swift                   ← NoteEvent, Hand, Finger, MIDI helpers ✓
    │   ├── Song.swift                   ← Song, Chunk, SongLibrary (JSON loader) ✓
    │   └── ProgressRecord.swift        ← SwiftData: ChunkAttempt, SongProgress, DailyStreak ✓
    ├── Audio/
    │   ├── ChunkPlayer.swift           ← Plays NoteEvent sequences via AVAudioEngine ✓
    │   └── InputGrader.swift           ← Grades user pitch + timing against expected notes ✓
    ├── ViewModels/
    │   └── LessonViewModel.swift       ← PracticePhase state machine, coordinates audio+UI ✓
    ├── Views/
    │   ├── SongLibraryView.swift       ← Entry screen, songs grouped by difficulty ✓
    │   ├── KeyboardView/
    │   │   ├── KeyboardView.swift      ← 2-octave piano, white+black key ZStack layout ✓
    │   │   └── PianoKeyView.swift      ← Single key, finger color dots, touch gesture ✓
    │   ├── HandView/
    │   │   ├── HandView.swift          ← 2D animated hand, spring-animated finger press ✓
    │   │   └── FingerPath.swift        ← FingerJoint geometry, FingerShape (custom Shape) ✓
    │   └── LessonView/
    │       ├── LessonPlayerView.swift  ← Main screen: hands + keyboard + controls ✓
    │       ├── PhaseControlBar.swift   ← Listen/Shadow/Play buttons + tempo slider ✓
    │       ├── ScoreView.swift         ← Stars + accuracy + timing overlay ✓
    │       └── ChunkProgressBar.swift  ← Dot map of all chunks, mastered = green ✓
    └── Resources/
        └── SampleSongs.json           ← Für Elise + Twinkle (2 songs, 2 chunks each) ✓
```

### What works end-to-end
- Song library screen listing songs by difficulty
- Full Listen → Shadow → Practice → Score → Mastered loop
- Keyboard highlights correct keys with finger color dots in sync with audio
- Hand animation: both hands shown, correct fingers spring-animate down when notes play
- Tempo control (40%–100% speed)
- Scoring: stars (1–3), accuracy %, notes hit count, average timing error in ms
- Chunk progress dot map
- SwiftData schema for tracking attempts and streaks
- XcodeGen project file — open `PianoTrainer.xcodeproj` in Xcode and build

### What needs one manual step before first build
- **Xcode** must be installed (download from Mac App Store)
- **SoundFont**: Add any `.sf2` file named `Piano.sf2` to the Xcode target bundle.
  The app already falls back to the iOS built-in General MIDI piano if no `.sf2` is present,
  so this step is optional for testing — but sound quality will be better with a real SF2.
  Recommended free option: [GeneralUser GS](https://schristiancollins.com/generaluser.php) (~30 MB)

---

## What Will Be Built Next

### Phase 2 — Core Polish
| Feature | Description | Priority |
|---|---|---|
| **CoreMIDI support** | Connect a physical MIDI keyboard; all input grading works the same | High |
| **Metronome** | Click track during practice phase, with visual beat indicator | High |
| **More songs** | Expand `SampleSongs.json`: Moonlight Sonata intro, Ode to Joy, scales | High |
| **Settings screen** | Timing tolerance (easy/hard), metronome on/off, default tempo | Medium |
| **Left-hand-only / right-hand-only mode** | Practice one hand before combining | Medium |

### Phase 3 — Richer Feedback
| Feature | Description | Priority |
|---|---|---|
| **CoreHaptics rhythm** | Tap pattern on device matches the beat during listen phase | Medium |
| **Pitch detection (mic)** | Optional: detect real piano notes via microphone using AudioKit or Accelerate FFT | Medium |
| **Sheet music view** | Scrolling notation that highlights the current note (using a MIDI-to-staff renderer) | Low |
| **Slow-mo hand replay** | After a failed practice, replay the chunk at 30% speed with extra emphasis on error notes | Low |

### Phase 4 — Content & Progress
| Feature | Description | Priority |
|---|---|---|
| **Song import** | Import MIDI files, auto-chunk them, ask user to assign fingering | Medium |
| **Progress dashboard** | Streak calendar, per-song completion map, accuracy trend graph | Medium |
| **Difficulty progression** | Unlock intermediate songs only after beginner songs hit 2 stars | Low |
| **iCloud sync** | Sync `SongProgress` and `DailyStreak` across devices via SwiftData + CloudKit | Low |

---

## Data Model Summary

```
Song
 └── chunks: [Chunk]
      └── notes: [NoteEvent]
           ├── pitch: Int        (MIDI number, e.g. 60 = C4)
           ├── startTime: Double (seconds from chunk start)
           ├── duration: Double
           ├── finger: Int       (1=thumb … 5=pinky)
           ├── hand: Hand        (.left / .right)
           └── velocity: Int     (0–127)

SwiftData (persisted):
 ├── ChunkAttempt   — one row per practice attempt with accuracy score
 ├── SongProgress   — mastered chunk IDs per song
 └── DailyStreak    — array of practice dates for streak calculation
```
