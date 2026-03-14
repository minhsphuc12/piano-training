# Piano Trainer - Test Cases

## Overview

This document catalogs all test cases for the Piano Trainer iOS app, organized by component.

---

## 1. Models

### 1.1 Note.swift

| ID | Test Case | Description | Expected Result |
|----|-----------|-------------|-----------------|
| N-01 | Finger color mapping | Finger 1-5 returns correct hex color | thumb=#FF4444, index=#FF9500, middle=#FFD60A, ring=#34C759, pinky=#0A84FF |
| N-02 | Finger name mapping | Finger 1-5 returns correct name | Thumb, Index, Middle, Ring, Pinky |
| N-03 | Invalid finger color | Finger outside 1-5 range | Returns #FFFFFF |
| N-04 | Invalid finger name | Finger outside 1-5 range | Returns "?" |
| N-05 | MIDI to note name | Pitch 60 (Middle C) | Returns "C4" |
| N-06 | MIDI to note name - sharp | Pitch 61 (C#4) | Returns "C#4" |
| N-07 | MIDI octave calculation | Various pitches | Correct octave number |
| N-08 | Black key detection | C# (pitch 61) | Returns true |
| N-09 | White key detection | C (pitch 60) | Returns false |
| N-10 | NoteEvent initialization | Default velocity | velocity = 80 |
| N-11 | NoteEvent Codable | Encode/decode round-trip | All properties preserved |
| N-12 | Hand enum Codable | Encode/decode .left, .right | Correct raw values |

### 1.2 Song.swift

| ID | Test Case | Description | Expected Result |
|----|-----------|-------------|-----------------|
| S-01 | Chunk totalDuration | Notes at 0s, 1s, 2s (0.5s each) | Returns 2.5 |
| S-02 | Chunk totalDuration empty | No notes | Returns 0 |
| S-03 | Chunk sortedNotes | Notes out of order | Sorted by startTime ascending |
| S-04 | Chunk involvedPitches | Duplicate pitches | Returns unique Set |
| S-05 | Song totalBars | Chunks with endBar 4, 8, 12 | Returns 12 |
| S-06 | Song totalBars empty | No chunks | Returns 0 |
| S-07 | Difficulty enum | All cases | beginner, intermediate, advanced |
| S-08 | Song Codable | JSON decode | All fields parsed correctly |
| S-09 | SongLibrary load | Valid JSON in bundle | Returns non-empty array |
| S-10 | SongLibrary load fail | Missing/invalid JSON | Returns empty array |

### 1.3 ProgressRecord.swift

| ID | Test Case | Description | Expected Result |
|----|-----------|-------------|-----------------|
| P-01 | ChunkAttempt stars 3 | accuracy = 0.95 | Returns 3 |
| P-02 | ChunkAttempt stars 2 | accuracy = 0.75 | Returns 2 |
| P-03 | ChunkAttempt stars 1 | accuracy = 0.55 | Returns 1 |
| P-04 | ChunkAttempt stars 0 | accuracy = 0.40 | Returns 0 |
| P-05 | ChunkAttempt boundary 90% | accuracy = 0.90 | Returns 3 |
| P-06 | ChunkAttempt boundary 70% | accuracy = 0.70 | Returns 2 |
| P-07 | ChunkAttempt boundary 50% | accuracy = 0.50 | Returns 1 |
| P-08 | SongProgress init | New progress | Empty masteredChunkIds |
| P-09 | SongProgress markMastered | Add chunk 1 | masteredChunkIds contains 1 |
| P-10 | SongProgress markMastered duplicate | Add chunk 1 twice | Only one entry |
| P-11 | SongProgress isMastered | Check mastered chunk | Returns true |
| P-12 | SongProgress isMastered false | Check unmastered chunk | Returns false |
| P-13 | DailyStreak empty | No practice dates | currentStreak = 0 |
| P-14 | DailyStreak single day | One date | currentStreak = 1 |
| P-15 | DailyStreak consecutive | 3 consecutive days | currentStreak = 3 |
| P-16 | DailyStreak gap | Days with gap | Streak breaks at gap |
| P-17 | DailyStreak recordToday | Record same day twice | Only one entry |

---

## 2. Audio

### 2.1 InputGrader.swift

| ID | Test Case | Description | Expected Result |
|----|-----------|-------------|-----------------|
| G-01 | Perfect timing | All notes within tolerance | accuracy = 1.0 |
| G-02 | All missed | No attempts | accuracy = 0.0 |
| G-03 | Partial correct | 2/4 notes correct | accuracy = 0.5 |
| G-04 | Wrong pitch | Correct timing, wrong pitch | Note not matched |
| G-05 | Timing tolerance boundary | Exactly at 150ms | Counted as correct |
| G-06 | Timing tolerance exceeded | At 151ms | Counted as incorrect |
| G-07 | Stars calculation 3 | accuracy >= 0.9 | stars = 3 |
| G-08 | Stars calculation 2 | 0.7 <= accuracy < 0.9 | stars = 2 |
| G-09 | Stars calculation 1 | 0.5 <= accuracy < 0.7 | stars = 1 |
| G-10 | Stars calculation 0 | accuracy < 0.5 | stars = 0 |
| G-11 | Tempo multiplier | 0.5x tempo | Timing scaled correctly |
| G-12 | Average timing error | Mix of early/late | Correct average in ms |
| G-13 | No chunk start | Grade without beginGrading | accuracy = 0, error = 999 |
| G-14 | Empty chunk | No expected notes | accuracy = 0 |
| G-15 | Duplicate pitch handling | Same pitch twice, both matched | Both counted separately |
| G-16 | Extra attempts | More attempts than expected | Only match expected count |

---

## 3. ViewModels

### 3.1 LessonViewModel.swift

| ID | Test Case | Description | Expected Result |
|----|-----------|-------------|-----------------|
| VM-01 | Initial state | New ViewModel | phase = .listen, chunkIndex = 0 |
| VM-02 | Initial tempo | New ViewModel | tempoMultiplier = 0.7 |
| VM-03 | startListen | Call method | phase = .listen, player started |
| VM-04 | startShadow | Call method | phase = .shadow, player started |
| VM-05 | startPractice | Call method | phase = .practice, grader began |
| VM-06 | userPressedKey practice | Press key in practice | Attempt recorded |
| VM-07 | userPressedKey non-practice | Press key in listen | No attempt recorded |
| VM-08 | setTempo | Set to 0.5 | tempoMultiplier = 0.5, player stopped |
| VM-09 | Mastery after 3 correct | 3x accuracy >= 0.7 | phase = .mastered |
| VM-10 | Result after fail | accuracy < 0.7 | phase = .result, consecutiveCorrect = 0 |
| VM-11 | Consecutive reset | Pass, fail | consecutiveCorrect = 0 |
| VM-12 | advanceToNextChunk | Not last chunk | chunkIndex + 1, phase = .listen |
| VM-13 | advanceToNextChunk last | Already last chunk | No change |
| VM-14 | replayCurrentChunk | Call method | consecutiveCorrect = 0, phase = .listen |
| VM-15 | isLastChunk true | On last chunk | Returns true |
| VM-16 | isLastChunk false | Not on last chunk | Returns false |
| VM-17 | Active pitches on noteOn | Player callback | Pitch added to activePitches |
| VM-18 | Active pitches on noteOff | Player callback | Pitch removed from activePitches |
| VM-19 | Active fingers tracking | Player noteOn | activeFingers[pitch] = finger |
| VM-20 | Active hands tracking | Player noteOn | activeHands[pitch] = hand |

---

## 4. Integration Tests

### 4.1 Learning Loop

| ID | Test Case | Description | Expected Result |
|----|-----------|-------------|-----------------|
| I-01 | Full loop success | Listen → Shadow → Practice (3x pass) → Mastered | Chunk marked complete |
| I-02 | Full loop with retry | Practice fail → Result → Replay | Loop restarts correctly |
| I-03 | Multi-chunk progression | Master chunk 1 → advance → chunk 2 | Correct chunk loaded |
| I-04 | Song completion | Master all chunks | All chunks in masteredChunkIds |

### 4.2 Audio-UI Sync

| ID | Test Case | Description | Expected Result |
|----|-----------|-------------|-----------------|
| I-05 | Keyboard highlight sync | Note plays | Correct key highlighted |
| I-06 | Hand animation sync | Note plays | Correct finger animates |
| I-07 | Tempo affects playback | Change tempo | Audio and UI sync at new tempo |

---

## 5. UI Tests

### 5.1 SongLibraryView

| ID | Test Case | Description | Expected Result |
|----|-----------|-------------|-----------------|
| UI-01 | Songs displayed | Load view | All songs from library shown |
| UI-02 | Difficulty grouping | Multiple difficulties | Songs grouped by difficulty |
| UI-03 | Song selection | Tap song row | Navigate to LessonPlayerView |
| UI-04 | Empty state | No songs | Appropriate empty message |

### 5.2 LessonPlayerView

| ID | Test Case | Description | Expected Result |
|----|-----------|-------------|-----------------|
| UI-05 | Keyboard rendering | Load view | 2 octaves, correct layout |
| UI-06 | Hand rendering | Load view | Both hands displayed |
| UI-07 | Phase controls | Tap Listen/Shadow/Practice | Correct phase activated |
| UI-08 | Tempo slider | Adjust slider | Tempo changes, label updates |
| UI-09 | Score overlay | Practice complete | Stars and accuracy shown |
| UI-10 | Chunk progress bar | Some chunks mastered | Green dots for mastered |

### 5.3 Accessibility

| ID | Test Case | Description | Expected Result |
|----|-----------|-------------|-----------------|
| A-01 | VoiceOver piano keys | Focus on key | Note name announced |
| A-02 | VoiceOver phase buttons | Focus on button | Phase name announced |
| A-03 | Dynamic Type | Large text setting | UI scales appropriately |

---

## 6. Edge Cases

| ID | Test Case | Description | Expected Result |
|----|-----------|-------------|-----------------|
| E-01 | Very fast notes | Notes < 50ms apart | All notes play and grade |
| E-02 | Very slow tempo | 40% speed | Timing tolerance scaled |
| E-03 | Chord grading | Multiple notes same startTime | All chord notes matched |
| E-04 | Memory pressure | Many attempts recorded | No memory leak |
| E-05 | App backgrounding | Background during practice | Audio stops gracefully |
| E-06 | Device rotation | Rotate during lesson | Layout adapts |

---

## Test Coverage Goals

| Component | Target Coverage |
|-----------|----------------|
| Models | 95% |
| InputGrader | 95% |
| LessonViewModel | 90% |
| Views | 70% (UI tests) |

## Running Tests

```bash
# Run all unit tests
xcodebuild test -project PianoTrainer.xcodeproj -scheme PianoTrainerTests -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test class
xcodebuild test -project PianoTrainer.xcodeproj -scheme PianoTrainerTests -only-testing:PianoTrainerTests/InputGraderTests
```
