import SwiftUI
import SwiftData
import GymTrackerKit

@main
struct GymTrackerApp: App {
    let container: ModelContainer
    @Environment(\.scenePhase) private var scenePhase

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
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            DayNotificationManager.requestAuthorizationIfNeeded()
            DayNotificationManager.refresh()
        }
    }
}
