import CoreData
import os

/// Core Data stack with in-memory option for SwiftUI previews and tests.
final class PersistenceController {
    static let shared = PersistenceController()
    static let preview = PersistenceController(inMemory: true)

    let container: NSPersistentContainer
    private let logger = Logger(subsystem: "com.repscroll.app", category: "CoreData")

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "RepScroll")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { [logger] _, error in
            if let error {
                logger.error("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save(context: NSManagedObjectContext? = nil) {
        let ctx = context ?? container.viewContext
        guard ctx.hasChanges else { return }
        do {
            try ctx.save()
        } catch {
            logger.error("Core Data save error: \(error.localizedDescription)")
        }
    }
}