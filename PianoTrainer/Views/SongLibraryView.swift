import SwiftUI

// MARK: - SongLibraryView

/// Entry screen: shows available songs grouped by difficulty.
struct SongLibraryView: View {

    @State private var songs: [Song] = SongLibrary.load()
    @State private var selectedSong: Song?
    @State private var searchText = ""

    private var filtered: [Song] {
        guard !searchText.isEmpty else { return songs }
        return songs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.composer.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var grouped: [Difficulty: [Song]] {
        Dictionary(grouping: filtered, by: \.difficulty)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    if let songs = grouped[difficulty], !songs.isEmpty {
                        Section(difficulty.rawValue) {
                            ForEach(songs) { song in
                                SongRowView(song: song)
                                    .contentShape(Rectangle())
                                    .onTapGesture { selectedSong = song }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Piano Trainer")
            .searchable(text: $searchText, prompt: "Search songs…")
            .navigationDestination(item: $selectedSong) { song in
                LessonPlayerView(song: song)
            }
        }
    }
}

// MARK: - SongRowView

struct SongRowView: View {
    let song: Song

    var body: some View {
        HStack(spacing: 14) {
            // Difficulty badge
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(difficultyColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "music.note")
                    .foregroundColor(difficultyColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(song.title)
                    .font(.body.weight(.medium))
                Text(song.composer)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(song.bpm, specifier: "%.0f") BPM")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
                Text("\(song.chunks.count) chunks")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var difficultyColor: Color {
        switch song.difficulty {
        case .beginner:     return .green
        case .intermediate: return .orange
        case .advanced:     return .red
        }
    }
}

// MARK: - Preview

#Preview {
    SongLibraryView()
}
