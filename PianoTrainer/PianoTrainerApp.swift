import SwiftUI
import SwiftData

@main
struct PianoTrainerApp: App {

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([ChunkAttempt.self, SongProgress.self, DailyStreak.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup {
            SongLibraryView()
        }
        .modelContainer(sharedModelContainer)
    }
}
