import SwiftUI
import GymTrackerKit

struct RootView: View {
    var body: some View {
        TabView {
            StartSessionView()
                .tabItem { Label("Today", systemImage: "bolt.fill") }

            HistoryListView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

            GymProgressView()
                .tabItem { Label("Progress", systemImage: "chart.xyaxis.line") }

            CalendarStreakView()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
        }
        .tint(Theme.accent)
    }
}
