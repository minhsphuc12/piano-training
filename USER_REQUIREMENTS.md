# Piano Trainer iOS App — User Requirements Document

## Table of Contents

1. [Overview](#1-overview)
2. [User Personas](#2-user-personas)
3. [User Stories & Requirements](#3-user-stories--requirements)
4. [User Flow](#4-user-flow)
5. [UX Specifications](#5-ux-specifications)
6. [Implementation Status](#6-implementation-status)

---

## 1. Overview

### Product Goal
Build an iOS app that teaches piano through **3 simultaneous learning channels**:
- **Visual** — Watch 2D hand animation showing which finger presses which key
- **Auditory** — Listen to each music segment before playing
- **Kinesthetic** — Build muscle memory through guided repetition

### Learning Method (Learning Loop)
Instead of playing a full song, the app breaks each song into **chunks** (2-4 bars) and cycles:
```
Listen → Shadow → Practice → Score → (repeat until mastered) → next chunk
```

---

## 2. User Personas

### Persona 1: Piano Beginner
- **Name**: Alex
- **Age**: 25
- **Goal**: Learn basic piano at home without a teacher
- **Pain points**: Doesn't know correct finger placement, difficulty following sheet music

### Persona 2: Returning Piano Player
- **Name**: Sarah
- **Age**: 30
- **Goal**: Practice classical pieces that have been forgotten
- **Pain points**: Needs slow tempo to practice difficult sections

---

## 3. User Stories & Requirements

### 3.1. Song Library

| ID | User Story | Status |
|----|------------|--------|
| SL-01 | As a user, I want to view a list of songs to choose what to learn | ✅ DONE |
| SL-02 | As a user, I want songs grouped by difficulty (Beginner/Intermediate/Advanced) | ✅ DONE |
| SL-03 | As a user, I want to search songs by title or composer | ✅ DONE |
| SL-04 | As a user, I want to see BPM and chunk count for each song | ✅ DONE |
| SL-05 | As a user, I want to see my learning progress for each song (mastered chunks) | ❌ NOT DONE |
| SL-06 | As a user, I want to import MIDI files to add new songs | ❌ NOT DONE |

### 3.2. Lesson Player Screen

| ID | User Story | Status |
|----|------------|--------|
| LP-01 | As a user, I want to see the song title and composer in the header | ✅ DONE |
| LP-02 | As a user, I want to see current chunk / total chunks | ✅ DONE |
| LP-03 | As a user, I want to see a chunk progress bar (dot map) with mastered colors | ✅ DONE |
| LP-04 | As a user, I want to return to the library screen at any time | ✅ DONE |

### 3.3. Practice Phases

| ID | User Story | Status |
|----|------------|--------|
| PP-01 | **Listen**: As a user, I want to hear the app play the chunk, see keys highlight, watch hand animation | ✅ DONE |
| PP-02 | **Shadow**: As a user, I want to play along without being graded to get familiar | ✅ DONE |
| PP-03 | **Practice**: As a user, I want to play and be graded on timing | ✅ DONE |
| PP-04 | **Result**: After practice, I want to see results (stars, accuracy, notes hit, timing error) | ✅ DONE |
| PP-05 | **Mastered**: After 3 consecutive passes at ≥70%, I want the chunk marked complete and auto-advance | ✅ DONE |
| PP-06 | As a user, I want a Retry button to practice the chunk again | ✅ DONE |
| PP-07 | As a user, I want a Continue button to proceed | ✅ DONE |
| PP-08 | As a user, I want to see a "Chunk Mastered!" banner animation upon completion | ✅ DONE |

### 3.4. Controls

| ID | User Story | Status |
|----|------------|--------|
| CT-01 | As a user, I want 3 buttons Listen/Shadow/Play to switch phases | ✅ DONE |
| CT-02 | As a user, I want a Stop button while playing | ✅ DONE |
| CT-03 | As a user, I want to adjust tempo from 40% to 100% | ✅ DONE |
| CT-04 | As a user, I want to see current tempo % | ✅ DONE |
| CT-05 | As a user, I want to toggle metronome while practicing | ❌ NOT DONE |
| CT-06 | As a user, I want to choose to practice only left hand or right hand | ❌ NOT DONE |

### 3.5. Keyboard View

| ID | User Story | Status |
|----|------------|--------|
| KB-01 | As a user, I want to see a 2-octave keyboard with white and black keys | ✅ DONE |
| KB-02 | As a user, I want keys to highlight with finger-color dots when notes are playing | ✅ DONE |
| KB-03 | As a user, I want to tap keys on screen to input notes | ✅ DONE |
| KB-04 | As a user, I want to hear a sound preview when tapping keys | ✅ DONE |
| KB-05 | As a user, I want to connect an external MIDI keyboard for practice | ❌ NOT DONE |

### 3.6. Hand Animation View

| ID | User Story | Status |
|----|------------|--------|
| HA-01 | As a user, I want to see animation of both hands (left & right) | ✅ DONE |
| HA-02 | As a user, I want fingers to spring-animate down when notes are played | ✅ DONE |
| HA-03 | As a user, I want each finger to have its own color (Thumb=red, Index=orange, Middle=yellow, Ring=green, Pinky=blue) | ✅ DONE |
| HA-04 | As a user, I want to see slow-mo replay at 30% speed after failing | ❌ NOT DONE |

### 3.7. Scoring System

| ID | User Story | Status |
|----|------------|--------|
| SC-01 | As a user, I want to see star count (1-3) based on accuracy | ✅ DONE |
| SC-02 | As a user, I want to see accuracy % | ✅ DONE |
| SC-03 | As a user, I want to see notes hit / total notes | ✅ DONE |
| SC-04 | As a user, I want to see average timing error (ms) | ✅ DONE |
| SC-05 | Stars animate with delay when showing results | ✅ DONE |
| SC-06 | Timing tolerance ±150ms (adjustable for easy/hard) | ⚠️ PARTIAL (fixed 150ms, no UI settings) |

### 3.8. Progress & Data

| ID | User Story | Status |
|----|------------|--------|
| PD-01 | As a user, I want my progress to be saved (SwiftData) | ✅ DONE (schema exists, but not persisted from UI) |
| PD-02 | As a user, I want to see a progress dashboard (streak calendar, accuracy trend) | ❌ NOT DONE |
| PD-03 | As a user, I want to see my daily consecutive streak | ❌ NOT DONE |
| PD-04 | As a user, I want to sync progress via iCloud | ❌ NOT DONE |

### 3.9. Settings

| ID | User Story | Status |
|----|------------|--------|
| ST-01 | As a user, I want to adjust timing tolerance (easy/hard) | ❌ NOT DONE |
| ST-02 | As a user, I want to toggle default metronome | ❌ NOT DONE |
| ST-03 | As a user, I want to set default tempo | ❌ NOT DONE |
| ST-04 | As a user, I want to choose a different sound font | ❌ NOT DONE |

### 3.10. Advanced Feedback

| ID | User Story | Status |
|----|------------|--------|
| FB-01 | As a user, I want to feel the beat through haptic feedback | ❌ NOT DONE |
| FB-02 | As a user, I want to use the mic to detect notes from a real piano | ❌ NOT DONE |
| FB-03 | As a user, I want to see scrolling sheet music highlighting the current note | ❌ NOT DONE |

### 3.11. Content

| ID | User Story | Status |
|----|------------|--------|
| CN-01 | App has at least 2 demo songs (Für Elise, Twinkle Twinkle) | ✅ DONE |
| CN-02 | More songs available (Moonlight Sonata, Ode to Joy, scales) | ❌ NOT DONE |
| CN-03 | Unlock intermediate songs only when completing beginner with 2 stars | ❌ NOT DONE |

---

## 4. User Flow

### 4.1. Main Flow: Learning a Song

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              APP LAUNCH                                  │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        SONG LIBRARY SCREEN                               │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ 🔍 Search bar                                                    │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌─ Beginner ──────────────────────────────────────────────────────┐    │
│  │ 🎵 Twinkle Twinkle | Mozart | 100 BPM | 2 chunks               │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│  ┌─ Intermediate ──────────────────────────────────────────────────┐    │
│  │ 🎵 Für Elise | Beethoven | 70 BPM | 2 chunks                   │    │
│  └─────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                            [Tap on song]
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        LESSON PLAYER SCREEN                              │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ Header: Song Title | Composer | Chunk 1/2                       │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ Chunk Progress: ○ ○ (dots represent chunks)                     │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │                      HAND ANIMATION ZONE                         │    │
│  │              [Left Hand]        [Right Hand]                     │    │
│  │                 🖐️                  🖐️                           │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ Phase Label: ● LISTEN Playing...                                │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │                         KEYBOARD                                 │    │
│  │  ┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐                    │    │
│  │  │  │▓▓│▓▓│  │▓▓│▓▓│▓▓│  │▓▓│▓▓│  │▓▓│▓▓│▓▓│ (2 octaves)       │    │
│  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │                    │    │
│  │  └──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘                    │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ Controls:                                                        │    │
│  │  [Listen 👂] [Shadow 🖐️] [Play 🎵]  [Stop ⏹️]                   │    │
│  │  🐢 ───────────○─────────── 🐇  70%                             │    │
│  └─────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2. Learning Loop Flow

```
                    ┌──────────────────┐
                    │   CHUNK START    │
                    └────────┬─────────┘
                             │
                             ▼
              ┌──────────────────────────────┐
              │        LISTEN PHASE          │
              │   • App plays chunk          │
              │   • Keys highlight           │
              │   • Hand animates            │
              │   • User watches & listens   │
              └──────────────┬───────────────┘
                             │
                    [Chunk finished]
                             │
                             ▼
              ┌──────────────────────────────┐
              │        SHADOW PHASE          │
              │   • App plays again          │
              │   • User mirrors             │
              │   • No grading               │
              └──────────────┬───────────────┘
                             │
                    [User ready]
                             │
                             ▼
              ┌──────────────────────────────┐
              │       PRACTICE PHASE         │
              │   • User plays               │
              │   • App grades timing        │
              │   • ±150ms tolerance         │
              └──────────────┬───────────────┘
                             │
                    [Chunk finished]
                             │
                             ▼
              ┌──────────────────────────────┐
              │        RESULT PHASE          │
              │   • Show stars (1-3)         │
              │   • Accuracy %               │
              │   • Notes hit count          │
              │   • Timing error (ms)        │
              │                              │
              │   [Retry]      [Continue]    │
              └──────────────┬───────────────┘
                             │
              ┌──────────────┴───────────────┐
              │                              │
        [Accuracy < 70%]              [Accuracy ≥ 70%]
              │                              │
              ▼                              ▼
    ┌─────────────────┐            ┌─────────────────┐
    │ consecutiveCorrect = 0      │ consecutiveCorrect++
    │ → Retry Practice            │                        │
    └─────────────────┘            └──────────┬────────────┘
                                              │
                              ┌───────────────┴───────────────┐
                              │                               │
                    [consecutiveCorrect < 3]      [consecutiveCorrect >= 3]
                              │                               │
                              ▼                               ▼
                    ┌─────────────────┐             ┌─────────────────────┐
                    │ Continue to     │             │    MASTERED PHASE   │
                    │ next Practice   │             │  • Banner animation │
                    └─────────────────┘             │  • Chunk marked ✓   │
                                                    └──────────┬──────────┘
                                                               │
                                                    ┌──────────┴──────────┐
                                                    │                     │
                                            [Has next chunk]     [Last chunk]
                                                    │                     │
                                                    ▼                     ▼
                                            ┌────────────────┐   ┌────────────────┐
                                            │ Advance to     │   │   SONG DONE    │
                                            │ Next Chunk     │   │   🎉           │
                                            │ → Listen Phase │   └────────────────┘
                                            └────────────────┘
```

### 4.3. Score View Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         RESULT OVERLAY                           │
│                                                                  │
│                          「 Result 」                             │
│                                                                  │
│                        ⭐ ⭐ ⭐                                   │
│                    (animated one by one)                         │
│                                                                  │
│         ┌──────────┬──────────┬──────────┐                      │
│         │ Accuracy │ Notes Hit│ Avg Error│                      │
│         │   85%    │   12/15  │   45ms   │                      │
│         │  (green) │  (blue)  │ (orange) │                      │
│         └──────────┴──────────┴──────────┘                      │
│                                                                  │
│         ┌─────────────┐  ┌─────────────────┐                    │
│         │   🔄 Retry  │  │  ➡️ Continue    │                    │
│         └─────────────┘  └─────────────────┘                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 4.4. Navigation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│    ┌────────────────┐          ┌────────────────────────┐       │
│    │                │   tap    │                        │       │
│    │  Song Library  │ ───────► │    Lesson Player       │       │
│    │    Screen      │          │       Screen           │       │
│    │                │ ◄─────── │                        │       │
│    └────────────────┘   back   └────────────────────────┘       │
│                                                                  │
│                                          │                       │
│                                          │ (future)              │
│                                          ▼                       │
│                                ┌────────────────────────┐       │
│                                │     Settings Screen    │       │
│                                │      (NOT DONE)        │       │
│                                └────────────────────────┘       │
│                                          │                       │
│                                          │ (future)              │
│                                          ▼                       │
│                                ┌────────────────────────┐       │
│                                │   Progress Dashboard   │       │
│                                │      (NOT DONE)        │       │
│                                └────────────────────────┘       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. UX Specifications

### 5.1. Finger Colors

| Finger | Color | Color Code |
|--------|-------|------------|
| Thumb (1) | Red | Red |
| Index (2) | Orange | Orange |
| Middle (3) | Yellow | Yellow |
| Ring (4) | Green | Green |
| Pinky (5) | Blue | Blue |

### 5.2. Phase Colors

| Phase | Color | Meaning |
|-------|-------|---------|
| Listen | Blue | Passive learning |
| Shadow | Purple | Semi-active mimicking |
| Practice | Green | Active playing |
| Result | Orange | Evaluation |
| Mastered | Green | Success |

### 5.3. Scoring Criteria

| Accuracy | Stars | Color |
|----------|-------|-------|
| ≥ 90% | ⭐⭐⭐ | Green |
| 70% - 89% | ⭐⭐ | Orange |
| 50% - 69% | ⭐ | Red |
| < 50% | (no star) | Red |

### 5.4. Mastery Criteria
- **Condition**: 3 consecutive passes with ≥70% accuracy
- **Action**: Auto-advance to next chunk

### 5.5. Timing Tolerance
- **Default**: ±150ms
- **Planned**: Easy (+200ms), Hard (+100ms) - NOT DONE

### 5.6. Tempo Range
- **Min**: 40%
- **Max**: 100%
- **Default**: 70%
- **Step**: 5%

---

## 6. Implementation Status

### Summary

| Category | Done | Not Done | Partial |
|----------|------|----------|---------|
| Song Library | 4 | 2 | 0 |
| Lesson Player | 4 | 0 | 0 |
| Practice Phases | 8 | 0 | 0 |
| Controls | 4 | 2 | 0 |
| Keyboard | 4 | 1 | 0 |
| Hand Animation | 3 | 1 | 0 |
| Scoring | 5 | 0 | 1 |
| Progress & Data | 1 | 3 | 0 |
| Settings | 0 | 4 | 0 |
| Advanced Feedback | 0 | 3 | 0 |
| Content | 1 | 2 | 0 |
| **TOTAL** | **34** | **18** | **1** |

### Details by Priority

#### ✅ Core Features (DONE)
- [x] Song library with search, difficulty grouping
- [x] Full learning loop: Listen → Shadow → Practice → Score → Mastered
- [x] Keyboard highlights with finger color dots
- [x] 2D hand animation for both hands
- [x] Tempo control (40%-100%)
- [x] Scoring: stars, accuracy %, notes hit, timing error
- [x] Chunk progress dot map
- [x] SwiftData schema for progress tracking

#### 🚧 High Priority (NOT DONE)
- [ ] CoreMIDI support for external MIDI keyboard
- [ ] Metronome with visual beat indicator
- [ ] More songs (Moonlight Sonata, Ode to Joy, scales)
- [ ] Settings screen (timing tolerance, metronome, default tempo)
- [ ] Left-hand / Right-hand only mode

#### 📋 Medium Priority (NOT DONE)
- [ ] CoreHaptics rhythm feedback
- [ ] Pitch detection via microphone
- [ ] Song import from MIDI files
- [ ] Progress dashboard (streak calendar, accuracy trend)

#### 📌 Low Priority (NOT DONE)
- [ ] Sheet music view
- [ ] Slow-mo hand replay
- [ ] Difficulty progression (unlock intermediate)
- [ ] iCloud sync

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-03-14 | Initial document created |
| 1.1 | 2026-03-14 | Translated to English |
