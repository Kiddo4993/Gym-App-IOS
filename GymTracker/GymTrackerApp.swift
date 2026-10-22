import SwiftUI
import SwiftData
import WidgetKit
import GymTrackerKit

@main
struct GymTrackerApp: App {
    let container: ModelContainer
    @Environment(\.scenePhase) private var scenePhase

    init() {
        #if DEBUG
        if DebugLaunch.usesDemoData {
            self.container = PreviewSupport.demoContainer
            return
        }
        #endif
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
            if newPhase == .background {
                // The widget only redraws when asked; leaving the app is the moment its data
                // (next day, streak, today's session) may have changed.
                WidgetCenter.shared.reloadAllTimelines()
            }
            guard newPhase == .active else { return }
            #if DEBUG
            if DebugLaunch.usesDemoData { return }
            #endif
            DayNotificationManager.requestAuthorizationIfNeeded()
            DayNotificationManager.refresh()
        }
    }
}
