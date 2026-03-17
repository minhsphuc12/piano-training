# Piano Trainer

An iOS app that teaches piano through **three simultaneous learning channels**: watch a 2D hand, hear each music segment, and practice with the Listen → Shadow → Practice loop until each chunk is mastered.

## Overview

Piano Trainer breaks every song into **chunks** (2–4 bars) and cycles:

```
Listen → Shadow → Practice → Score → (repeat until mastered) → next chunk
```

| Phase | Description |
|-------|-------------|
| **Listen** | App plays the chunk. Keys highlight. Hand animates. You just watch and listen. |
| **Shadow** | App plays again. You mirror the hand movement with no grading pressure. |
| **Practice** | You play. App grades timing (±150ms window). |
| **Mastery** | 3 consecutive correct plays (≥70%) → chunk complete → advance to next chunk. |

## Current Features

- **Song library**: List of songs by difficulty (Beginner / Intermediate / Advanced), search by title or composer.
- **Lesson player**: Song title, current/total chunk, chunk progress bar (dots turn green when mastered).
- **Listen / Shadow / Practice**: Play chunk, highlight keys by finger color, 2D hand animation in sync.
- **Tempo control**: Slider 40%–100% speed.
- **Scoring**: Stars (1–3), accuracy %, notes hit count, average timing error (ms).
- **Progress persistence**: SwiftData — attempts, mastered chunks, daily streak.

## Requirements

- **Xcode** (Mac App Store)
- **iOS 17+** (simulator or device)
- (Optional) **Piano.sf2** in the bundle for better sound — app falls back to built-in General MIDI if not present.

## Installation & Run

1. Clone the repo and open `PianoTrainer.xcodeproj` in Xcode.
2. (Optional) Add a `Piano.sf2` file to the target (e.g. [GeneralUser GS](https://schristiancollins.com/generaluser.php)).
3. Select the **PianoTrainer** scheme, build and run on simulator or device.

```bash
# Regenerate Xcode project from project.yml (if using XcodeGen)
xcodegen generate

# Build from command line
xcodebuild -project PianoTrainer.xcodeproj -scheme PianoTrainer build
```

## Project Structure

```
PianoTrainer/
├── PianoTrainerApp.swift       # Entry point + SwiftData container
├── Models/
│   ├── Note.swift             # NoteEvent, Hand, Finger, MIDI helpers
│   ├── Song.swift             # Song, Chunk, SongLibrary (JSON)
│   └── ProgressRecord.swift   # SwiftData: attempts, progress, streaks
├── Audio/
│   ├── ChunkPlayer.swift      # Plays NoteEvent sequences
│   └── InputGrader.swift      # Grades pitch + timing
├── ViewModels/
│   └── LessonViewModel.swift # Listen/Shadow/Practice state machine
├── Views/
│   ├── SongLibraryView.swift  # Song list screen
│   ├── KeyboardView/          # 2-octave piano
│   ├── HandView/              # 2D animated hand
│   └── LessonView/            # Lesson screen: hands + keyboard + controls
└── Resources/
    └── SampleSongs.json       # Sample data (e.g. Für Elise, Twinkle)
```

## Finger Colors

| Finger | Color |
|--------|-------|
| 1 (thumb) | Red |
| 2 (index) | Orange |
| 3 (middle) | Yellow |
| 4 (ring) | Green |
| 5 (pinky) | Blue |

## Roadmap

- **Phase 2**: CoreMIDI, Metronome, more songs, Settings, one-hand mode.
- **Phase 3**: Haptics, pitch detection (mic), sheet music view, slow-mo replay.
- **Phase 4**: Import MIDI, progress dashboard, iCloud sync.

Details: [PLAN.md](PLAN.md).

## Further Documentation

- [USER_REQUIREMENTS.md](USER_REQUIREMENTS.md) — User stories and implementation status.
- [TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md) — Technical design.
- [CLAUDE.md](CLAUDE.md) — Summary for AI/contributors.

## License

Internal project — see repo for terms of use.
