import SwiftUI
import CoreData

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var repository: WorkoutRepository
    @Published var blockedAppsService = BlockedAppsService()

    init(context: NSManagedObjectContext) {
        repository = WorkoutRepository(context: context)
    }

    func refresh() {
        repository.refresh()
    }
}