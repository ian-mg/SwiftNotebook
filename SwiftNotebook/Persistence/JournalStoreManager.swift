import AppKit
import Observation

/// Owns where the journal's Core Data store physically lives. On first launch there is no
/// remembered folder, so `persistence` stays nil and the app shows a folder picker; once a
/// folder is chosen we keep a security-scoped bookmark so we can regain access on future launches
/// without asking again.
@Observable
final class JournalStoreManager {
    private static let bookmarkKey = "journalFolderBookmarkData"
    private static let storeFileName = "SwiftNotebook.sqlite"
    /// Marks that this folder has already been seeded, so deleting the sample entries doesn't
    /// bring them back on the next launch — seeding is a one-time-per-folder thing, not "whenever
    /// the journal happens to be empty."
    private static let seededMarkerFileName = ".swiftnotebook-seeded"

    private(set) var persistence: PersistenceController?
    private(set) var folderURL: URL?

    init() {
        if let url = Self.resolveBookmarkedFolder() {
            open(folder: url)
        }
    }

    @discardableResult
    func chooseFolder() -> Bool {
        let panel = NSOpenPanel()
        panel.title = "Choose a Folder for Your Journal"
        panel.message = "SwiftNotebook stores your entries as a local database inside this folder. Nothing leaves your Mac."
        panel.prompt = "Choose"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return false }
        _ = url.startAccessingSecurityScopedResource()
        saveBookmark(for: url)
        open(folder: url)
        return true
    }

    private func open(folder url: URL) {
        folderURL = url
        let controller = PersistenceController(storeURL: url.appendingPathComponent(Self.storeFileName))

        let seededMarker = url.appendingPathComponent(Self.seededMarkerFileName)
        if !FileManager.default.fileExists(atPath: seededMarker.path) {
            controller.seedSampleData()
            FileManager.default.createFile(atPath: seededMarker.path, contents: nil)
        }

        persistence = controller
    }

    private func saveBookmark(for url: URL) {
        guard let data = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) else { return }
        UserDefaults.standard.set(data, forKey: Self.bookmarkKey)
    }

    private static func resolveBookmarkedFolder() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else { return nil }
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) else {
            return nil
        }
        guard url.startAccessingSecurityScopedResource() else { return nil }
        return url
    }
}
