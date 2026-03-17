import SwiftUI

// MARK: - LessonPlayerView

/// The main learning screen. Shows hand animation, keyboard, and phase controls.
struct LessonPlayerView: View {

    @State private var vm: LessonViewModel
    @State private var masteredChunks: Set<Int> = []
    @State private var showMasteredBanner = false

    init(song: Song) {
        _vm = State(initialValue: LessonViewModel(song: song))
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: Header
                headerBar

                ScrollView {
                    VStack(spacing: 20) {

                        // Chunk progress dots
                        ChunkProgressBar(
                            totalChunks: vm.song.chunks.count,
                            currentChunk: vm.currentChunkIndex,
                            masteredChunks: masteredChunks
                        )
                        .padding(.horizontal)
                        
                        // Chunk navigation
                        chunkNavigationBar
                            .padding(.horizontal)

                        // Hand animation zone
                        handZone
                            .frame(height: 260)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(.secondarySystemGroupedBackground))
                                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                            )
                            .padding(.horizontal)

                        // Phase label
                        phaseLabel

                        // Keyboard
                        KeyboardView(
                            activePitches: vm.activePitches,
                            activeFingers: vm.activeFingers,
                            onKeyPress: { pitch in
                                vm.userPressedKey(pitch: pitch)
                            }
                        )
                        .padding(.horizontal)

                        // Control bar
                        PhaseControlBar(
                            tempoMultiplier: Binding(
                                get: { vm.tempoMultiplier },
                                set: { vm.setTempo($0) }
                            ),
                            phase: vm.phase,
                            isPlaying: vm.player.isPlaying,
                            onListen:   { vm.startListen()   },
                            onShadow:   { vm.startShadow()   },
                            onPractice: { vm.startPractice() },
                            onStop:     { vm.player.stop()   }
                        )
                        .padding(.horizontal)

                        Spacer(minLength: 24)
                    }
                    .padding(.top, 16)
                }
            }

            // Score overlay
            if vm.phase == .result || vm.phase == .mastered,
               let result = vm.lastGradeResult {
                Color.black.opacity(0.4).ignoresSafeArea()
                    .transition(.opacity)

                ScoreView(
                    result: result,
                    onRetry: {
                        withAnimation { vm.replayCurrentChunk() }
                    },
                    onContinue: {
                        withAnimation {
                            if vm.phase == .mastered {
                                masteredChunks.insert(vm.currentChunkIndex)
                                showMasteredBanner = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    showMasteredBanner = false
                                    vm.advanceToNextChunk()
                                }
                            } else {
                                vm.startPractice()
                            }
                        }
                    }
                )
                .padding(24)
                .transition(.scale.combined(with: .opacity))
            }

            // Mastered banner
            if showMasteredBanner {
                masteredBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: vm.phase)
        .onAppear { vm.startListen() }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.song.title)
                    .font(.headline)
                Text(vm.song.composer)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
    }
    
    // MARK: - Chunk Navigation Bar
    
    private var chunkNavigationBar: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation {
                    vm.goToPreviousChunk()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Previous")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundColor(vm.currentChunkIndex > 0 ? .white : .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(vm.currentChunkIndex > 0 ? Color.blue : Color(.systemGray5))
                )
            }
            .disabled(vm.currentChunkIndex == 0)
            
            VStack(spacing: 4) {
                Text("Chunk \(vm.currentChunkIndex + 1)")
                    .font(.headline)
                Text("of \(vm.song.chunks.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Button {
                withAnimation {
                    vm.goToNextChunk()
                }
            } label: {
                HStack(spacing: 6) {
                    Text("Next")
                        .font(.subheadline.weight(.medium))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(vm.isLastChunk ? .gray : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(vm.isLastChunk ? Color(.systemGray5) : Color.blue)
                )
            }
            .disabled(vm.isLastChunk)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }

    // MARK: - Hand Zone

    private var handZone: some View {
        let leftActiveFingers = Set(
            vm.currentChunk.notes
                .filter { vm.activePitches.contains($0.pitch) && $0.hand == .left }
                .map(\.finger)
        )
        let rightActiveFingers = Set(
            vm.currentChunk.notes
                .filter { vm.activePitches.contains($0.pitch) && $0.hand == .right }
                .map(\.finger)
        )

        return HStack(spacing: 24) {
            HandView(hand: .left,  activeFingers: leftActiveFingers)
            HandView(hand: .right, activeFingers: rightActiveFingers)
        }
        .scaleEffect(0.85)
        .padding(.top, 8)
    }

    // MARK: - Phase Label

    private var phaseLabel: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(phaseColor)
                .frame(width: 8, height: 8)
                .opacity(vm.player.isPlaying ? 1 : 0.4)
            Text(vm.phase.rawValue.uppercased())
                .font(.caption.bold())
                .foregroundColor(phaseColor)
            if vm.player.isPlaying {
                Text("Playing...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .animation(.easeInOut, value: vm.phase)
    }

    private var phaseColor: Color {
        switch vm.phase {
        case .listen:   return .blue
        case .shadow:   return .purple
        case .practice: return .green
        case .result:   return .orange
        case .mastered: return .green
        }
    }

    // MARK: - Mastered Banner

    private var masteredBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.green)
                .font(.title2)
            Text("Chunk Mastered!")
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(radius: 10)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 60)
    }
}
