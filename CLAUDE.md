# Piano Trainer iOS App

## Overview

An iOS app that teaches piano through **three simultaneous learning channels**:
- **Visual** — watch a 2D animated hand showing which finger presses which key
- **Auditory** — hear each chunk of music before playing it
- **Kinesthetic** — build muscle memory through guided, graded repetition

## Core Learning Loop

Instead of playing a full song, the app breaks every song into **chunks** (2–4 bars):

```
Listen → Shadow → Practice → Score → (repeat until mastered) → next chunk
```

| Phase | Description |
|-------|-------------|
| Listen | App plays the chunk. Keys highlight. Hand animates. User just watches + listens |
| Shadow | App plays again. User mirrors hand movement with no grading pressure |
| Practice | User plays. App grades timing accuracy (±150ms window) |
| Mastery | 3 consecutive correct plays (≥70%) → chunk complete → advance |

## Tech Stack

| Component | Technology | Reason |
|-----------|------------|--------|
| UI | SwiftUI + `@Observable` | iOS 17+, less boilerplate |
| Audio | AVAudioEngine + AVAudioUnitSampler | Low latency, SoundFont support |
| Scheduling | Swift async/await | Clean cancellation, no race conditions |
| Storage | SwiftData | Native iOS 17, no third-party deps |
| Song format | JSON (bundled) | Easy to edit, version, and expand |
| Hand animation | 2D SwiftUI shapes | Faster than 3D, sufficient for learning |

## Directory Structure

```
PianoTrainer/
├── PianoTrainerApp.swift      # Entry point + SwiftData container
├── Models/
│   ├── Note.swift             # NoteEvent, Hand, Finger, MIDI helpers
│   ├── Song.swift             # Song, Chunk, SongLibrary (JSON loader)
│   └── ProgressRecord.swift   # SwiftData: attempts, progress, streaks
├── Audio/
│   ├── ChunkPlayer.swift      # Plays NoteEvent sequences
│   └── InputGrader.swift      # Grades pitch + timing accuracy
├── ViewModels/
│   └── LessonViewModel.swift  # State machine, coordinates audio+UI
├── Views/
│   ├── SongLibraryView.swift  # Main screen, song list
│   ├── KeyboardView/          # 2-octave piano
│   ├── HandView/              # 2D animated hand
│   └── LessonView/            # Lesson screen: hands + keyboard + controls
└── Resources/
    └── SampleSongs.json       # Sample song data
```

## Data Model

```
Song
 └── chunks: [Chunk]
      └── notes: [NoteEvent]
           ├── pitch: Int        # MIDI number (60 = C4)
           ├── startTime: Double # seconds from chunk start
           ├── duration: Double
           ├── finger: Int       # 1=thumb … 5=pinky
           ├── hand: Hand        # .left / .right
           └── velocity: Int     # 0–127

SwiftData (persisted):
 ├── ChunkAttempt   # one row per practice attempt with accuracy score
 ├── SongProgress   # mastered chunk IDs per song
 └── DailyStreak    # practice dates for streak calculation
```

## Finger Color Convention

| Finger | Color |
|--------|-------|
| Thumb (1) | Red |
| Index (2) | Orange |
| Middle (3) | Yellow |
| Ring (4) | Green |
| Pinky (5) | Blue |

## Build & Run

1. Open `PianoTrainer.xcodeproj` in Xcode
2. (Optional) Add a `Piano.sf2` file to the bundle for better sound quality
3. Build and run on simulator or iOS 17+ device

## Commands

```bash
# Generate Xcode project from project.yml
xcodegen generate

# Build project
xcodebuild -project PianoTrainer.xcodeproj -scheme PianoTrainer build
```

## Roadmap

See details in `PLAN.md`:
- **Phase 2**: CoreMIDI, Metronome, more songs, Settings
- **Phase 3**: Haptics, Pitch detection, Sheet music view
- **Phase 4**: Import MIDI, Progress dashboard, iCloud sync
