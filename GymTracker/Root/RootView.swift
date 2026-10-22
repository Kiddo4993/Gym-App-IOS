import SwiftUI
import GymTrackerKit

struct RootView: View {
    enum Tab: String { case today, history, progress, calendar, settings }

    @State private var selection: Tab = {
        #if DEBUG
        if let raw = DebugLaunch.initialTab, let tab = Tab(rawValue: raw) { return tab }
        #endif
        return .today
    }()

    var body: some View {
        TabView(selection: $selection) {
            StartSessionView()
                .tabItem { Label("Today", systemImage: "bolt.fill") }
                .tag(Tab.today)

            HistoryListView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(Tab.history)

            GymProgressView()
                .tabItem { Label("Progress", systemImage: "chart.xyaxis.line") }
                .tag(Tab.progress)

            CalendarStreakView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(Tab.calendar)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
                .tag(Tab.settings)
        }
        .tint(Theme.accent)
    }
}
