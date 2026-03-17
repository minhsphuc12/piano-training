import SwiftUI
import UniformTypeIdentifiers

// MARK: - SongLibraryView

/// Entry screen: shows available songs grouped by difficulty.
struct SongLibraryView: View {

    @State private var songs: [Song] = SongLibrary.load()
    @State private var selectedSong: Song?
    @State private var searchText = ""
    @State private var isImportingMIDI = false
    @State private var importErrorMessage: String?

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
                        Section(difficulty.displayName) {
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Import MIDI") { isImportingMIDI = true }
                }
            }
            .navigationDestination(item: $selectedSong) { song in
                LessonPlayerView(song: song)
            }
            .fileImporter(
                isPresented: $isImportingMIDI,
                allowedContentTypes: allowedMIDIContentTypes,
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importMIDI(url: url)
                case .failure(let error):
                    importErrorMessage = error.localizedDescription
                }
            }
            .alert(
                "Import failed",
                isPresented: Binding(
                    get: { importErrorMessage != nil },
                    set: { if !$0 { importErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importErrorMessage ?? "Unknown error")
            }
        }
    }

    private var allowedMIDIContentTypes: [UTType] {
        var types: [UTType] = [UTType.midi]
        if let mid = UTType(filenameExtension: "mid") { types.append(mid) }
        if let midiExt = UTType(filenameExtension: "midi") { types.append(midiExt) }
        return types.isEmpty ? [.data] : Array(Set(types))
    }

    private func importMIDI(url: URL) {
        do {
            let imported = try MIDIFileImporter.importMIDI(from: url)
            let title = url.deletingPathExtension().lastPathComponent
            let id = makeImportedSongId(from: title)

            let secondsPerBeat = 60.0 / max(1, imported.bpm)
            let secondsPerBar = secondsPerBeat * Double(max(1, imported.timeSignatureNumerator))
            let bars = max(1, Int(ceil(imported.totalDurationSeconds / max(0.01, secondsPerBar))))

            let chunk = Chunk(
                id: 0,
                startBar: 1,
                endBar: bars,
                notes: imported.notes
            )

            let song = Song(
                id: id,
                title: title.isEmpty ? "Imported MIDI" : title,
                composer: "Imported MIDI",
                bpm: imported.bpm,
                difficulty: .beginner,
                timeSignatureNumerator: imported.timeSignatureNumerator,
                timeSignatureDenominator: imported.timeSignatureDenominator,
                chunks: [chunk]
            )

            try SongStore.save(song: song)
            songs = SongLibrary.load()
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }

    private func makeImportedSongId(from title: String) -> String {
        let base = title
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "/", with: "-")
        let suffix = UUID().uuidString.prefix(8)
        return "imported-\(base.isEmpty ? "song" : base)-\(suffix)"
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
