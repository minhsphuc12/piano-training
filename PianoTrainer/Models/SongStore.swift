import Foundation

enum SongStoreError: Error {
    case cannotCreateDirectory
    case cannotWriteFile
}

/// Stores user-imported songs as JSON files in the app's Documents directory.
struct SongStore {
    static let directoryName = "Songs"

    static func songsDirectoryURL() throws -> URL {
        let fm = FileManager.default
        let docs = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = docs.appendingPathComponent(directoryName, isDirectory: true)

        var isDir: ObjCBool = false
        if fm.fileExists(atPath: dir.path, isDirectory: &isDir) {
            if isDir.boolValue { return dir }
        }

        do {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        } catch {
            throw SongStoreError.cannotCreateDirectory
        }

        return dir
    }

    static func save(song: Song) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(song)

        let dir = try songsDirectoryURL()
        let fileURL = dir.appendingPathComponent("\(song.id).json", isDirectory: false)

        do {
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            throw SongStoreError.cannotWriteFile
        }
    }

    static func loadAll() -> [Song] {
        let fm = FileManager.default
        guard let dir = try? songsDirectoryURL() else { return [] }
        guard let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return [] }

        let decoder = JSONDecoder()
        var songs: [Song] = []

        for url in files where url.pathExtension.lowercased() == "json" {
            guard
                let data = try? Data(contentsOf: url),
                let song = try? decoder.decode(Song.self, from: data)
            else { continue }
            songs.append(song)
        }

        return songs
    }
}

