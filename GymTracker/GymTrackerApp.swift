import SwiftUI
import SwiftData
import GymTrackerKit

@main
struct GymTrackerApp: App {
    let container: ModelContainer

    init() {
        let container = SharedModelContainer.make()
        SeedData.seedIfNeeded(context: ModelContext(container))
        self.container = container
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
