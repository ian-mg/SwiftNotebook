import AppKit
import CoreData

struct PersistenceController {
    let container: NSPersistentContainer

    /// Points the store at a file inside a folder the user has chosen (see `JournalStoreManager`),
    /// so the database lives somewhere the user owns rather than the app's sandbox container.
    init(storeURL: URL) {
        let container = NSPersistentContainer(name: "SwiftNotebook")
        container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: storeURL)]
        self.init(container: container)
    }

    private init(container: NSPersistentContainer) {
        self.container = container
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unresolved Core Data error: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    static let preview: PersistenceController = {
        let container = NSPersistentContainer(name: "SwiftNotebook")
        container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        let controller = PersistenceController(container: container)
        controller.seedSampleData()
        return controller
    }()

    /// Seeds showcase entries (including one with real bold text) and starter categories so a
    /// freshly created journal isn't just an empty page.
    func seedSampleData() {
        let context = container.viewContext
        let calendar = Calendar.current
        let components = DateComponents(year: 2026, month: 7)
        guard let julyFirst = calendar.date(from: components) else { return }

        func day(_ offset: Int) -> Date {
            calendar.date(byAdding: .day, value: offset, to: julyFirst)!
        }

        func plain(_ text: String) -> NSAttributedString {
            NSAttributedString(string: text, attributes: [.font: JournalEntry.defaultBodyFont])
        }

        let categoryNames = ["Work", "Health", "Ideas", "Family", "Books"]
        var categoriesByName: [String: Category] = [:]
        for (name, hex) in zip(categoryNames, Palette.defaultCategoryColorHexes) {
            let category = Category(context: context)
            category.id = UUID()
            category.name = name
            category.colorHex = hex
            categoriesByName[name] = category
        }

        let jasmineBody = NSMutableAttributedString()
        jasmineBody.append(plain(
            "Slept badly, woke before the alarm. The morning walk fixed most of it — cool air, empty streets, the light still low. #health\n\n"
            + "The jasmine by the front door finally opened overnight. Three months of nothing, and then all at once the whole step smells like summer.\n\n"
            + "Started the "
        ))
        let boldFont = NSFontManager.shared.convert(JournalEntry.defaultBodyFont, toHaveTrait: .boldFontMask)
        jasmineBody.append(NSAttributedString(string: "Halden", attributes: [.font: boldFont]))
        jasmineBody.append(plain(" proposal. Rough, but the shape is there now. Send Mara a draft tomorrow. #work"))

        let seeds: [(Date, String, NSAttributedString, [String], String?)] = [
            (day(0), "New month", plain("A fresh page. Setting a few #goals for July and leaving it at that for now."), ["goals"], nil),
            (day(1), "Rain, all afternoon", plain("Stayed in, read on the couch, watched it come down over the yard. #home"), ["home"], nil),
            (day(2), "Shipped it", plain("Out the door after three weeks of quiet grinding. #work"), ["work"], "Work"),
            (day(4), "The long table", plain("Everyone stayed past midnight. Slow food, slower conversation. #slow #friends"), ["slow", "friends"], nil),
            (day(6), "The jasmine opened", jasmineBody, ["health", "work"], "Health"),
        ]

        for (date, title, body, tags, categoryName) in seeds {
            let entry = JournalEntry(context: context)
            entry.id = UUID()
            entry.date = date
            entry.title = title
            entry.attributedBody = body
            entry.tagsRaw = tags.joined(separator: ",")
            entry.createdAt = date
            entry.modifiedAt = date
            entry.category = categoryName.flatMap { categoriesByName[$0] }
        }

        try? context.save()
    }
}
