# GymTracker

A native SwiftUI + SwiftData gym-tracking app: a fixed Push → Pull → Legs → Rest split, 2
working-sets-to-failure logging with full/partial reps, per-exercise history and progression
charts, a training calendar/streak view, and a home-screen widget — all dark-mode-first and
built around a custom numeric keypad instead of the system keyboard.

> Written and assembled on a Windows machine (no Xcode available here), so nothing in this repo
> has been compiled. The code follows standard, well-established SwiftUI/SwiftData/WidgetKit
> APIs for iOS 17, but budget a few minutes on first build in Xcode to fix anything
> environment-specific (signing, capabilities, a typo) — see **Troubleshooting** below.

## Project structure

```
Gym-App-IOS/
├── project.yml                      ← XcodeGen project definition (see "Generating the Xcode project")
├── Packages/
│   └── GymTrackerKit/                ← local Swift package: models + persistence + shared logic
│       └── Sources/GymTrackerKit/
│           ├── Models/                Exercise, Workout, ExerciseLog, SetLog, DayType, WeightUnit
│           ├── Persistence/           SharedModelContainer (App Group store), SeedData
│           ├── Utilities/             NextDayCalculator, VolumeCalculator, StreakCalculator, DashboardSnapshot
│           └── DesignSystem/          Theme (shared by app + widget)
├── GymTracker/                       ← iOS app target
│   ├── GymTrackerApp.swift
│   ├── Root/RootView.swift            5-tab shell: Today · History · Progress · Calendar · Settings
│   ├── DesignSystem/Components.swift
│   ├── Today/                         Start/continue a session, exercise list, set-logging sheet, keypad
│   ├── History/                       Per-exercise session history + edit-past-entry sheet
│   ├── Progress/                      Swift Charts progression view with personal-best highlight
│   ├── Calendar/                      Month grid + streak; tap a trained day for its full session detail
│   ├── Settings/                      Units toggle, exercise library management
│   └── Preview/                       In-memory seeded container for SwiftUI previews
└── GymTrackerWidget/                 ← WidgetKit extension: Home Screen (small/medium, interactive
                                         Start button) + Lock Screen (rectangular/circular) widgets
```

`GymTrackerKit` is a plain Swift package targeting iOS 17 **and macOS 14**, and contains every
model, the seed function, and all business logic — no SwiftUI-view code that's iOS-only. That's
what makes adding a real macOS app target later mechanical: point a new `type: application,
platform: macOS` target in `project.yml` at (mostly) the same `GymTracker/` sources — `List`,
`NavigationStack`, `TabView`, `.sheet`, and the custom keypad all run unchanged on macOS 14+; the
only things worth revisiting are tab-bar chrome and window sizing.

## Data model

- **Exercise** — name, muscle group, day type, sort order, archived flag.
- **Workout** — date + day type, has many `ExerciseLog`s.
- **ExerciseLog** — links one `Exercise` to one `Workout`; has many `SetLog`s.
- **SetLog** — set number, weight (+ the unit it was entered in), full reps, partial reps.
  Partials are always a separate stored field — never summed into `fullReps`.

Weight is stored with the unit it was entered in, so history always shows exactly what was
typed; the lb/kg toggle in Settings converts for display everywhere else on the fly
(`WeightUnit.convert`).

## Design choices worth knowing about

- **Next day type**: `NextDayCalculator` just takes the most recent `Workout.dayType.next` —
  Push → Pull → Legs → Rest → Push, forever. No workouts yet → defaults to Push.
- **Estimated volume**: full reps count fully; partial reps count at half weight-contribution
  (`VolumeCalculator`) — a documented, tweakable choice, not a hidden one.
- **Streak**: consecutive calendar days with *any* logged `Workout`, including Rest — logging a
  rest day is still an intentional check-in (`StreakCalculator`).
- **Minimum taps**: the Today tab lands directly on the auto-selected day; one tap starts the
  session, one tap opens an exercise, and both sets are pre-filled from your last session for
  that exercise — the keypad is the only input surface, no system keyboard ever appears.
- **Widget data sharing**: the app and widget share one SwiftData store via an App Group
  (`SharedModelContainer`), the same pattern Apple uses in its own SwiftData sample apps — not a
  duplicated/synced copy.
- **Workout-day detail**: tapping any trained day in the Calendar tab opens
  `WorkoutDayDetailView` — every exercise logged that session with its sets, in library order (or
  a plain "Rest day" state).
- **Interactive widget**: the Home Screen widgets carry a *Start* button
  (`StartSessionIntent`, an `AppIntent`) that creates today's `Workout` directly in the shared
  App Group store — no need to open the app first. `openAppWhenRun` is `false`, so it runs
  in-place; once a session exists for today, the button becomes a quiet "Session started"
  confirmation instead. Because the `Workout` already exists by the time you do open the app, the
  Today tab skips its picker screen entirely. Lock Screen widgets (`.accessoryRectangular` /
  `.accessoryCircular`) show the next day type and streak using `.widgetAccentable()` so they
  render correctly under the system's Lock Screen tinting.

## Generating the Xcode project

This repo ships source files and an [XcodeGen](https://github.com/yonaskolb/XcodeGen)
`project.yml` instead of a committed `.xcodeproj` (generated projects are noisy to diff and easy
to regenerate). On a Mac, with Xcode installed:

```bash
brew install xcodegen
cd Gym-App-IOS
xcodegen generate
open GymTracker.xcodeproj
```

Then in Xcode:

1. Select the **GymTracker** project → each target (**GymTracker** and
   **GymTrackerWidgetExtension**) → **Signing & Capabilities** → set your **Team**.
2. Still in Signing & Capabilities for both targets, add the **App Groups** capability and check
   (or create) `group.com.gymtracker.shared` — this is what lets the widget read the app's data.
   If you'd rather use your own identifier, change it in **one place**,
   `Packages/GymTrackerKit/Sources/GymTrackerKit/Persistence/SharedModelContainer.swift`
   (`appGroupID`), and in `project.yml`'s two `com.apple.security.application-groups` entries,
   then re-run `xcodegen generate`.
3. Pick the **GymTracker** scheme, choose an iOS 17+ simulator (or device), and hit **Run**.
4. To try the widget: long-press the simulator/device home screen → **+** → search
   "GymTracker" → add the small or medium widget.

### If you'd rather not install XcodeGen

Create a new Xcode project manually (App template, SwiftUI, SwiftData, iOS 17+), drag the
`GymTracker/` folder's files into the app target, add `Packages/GymTrackerKit` via **File → Add
Package Dependencies… → Add Local…**, then add a new **Widget Extension** target, drag
`GymTrackerWidget/`'s files into it, and link `GymTrackerKit` to that target too. Add the App
Group capability to both targets as in step 2 above.

## Troubleshooting a first build

- **"Cannot find type 'X' in scope"** across the widget/app targets usually means
  `GymTrackerKit` isn't linked to that target yet — check **Frameworks, Libraries, and Embedded
  Content**.
- **Widget shows no data**: the App Group isn't configured identically on both targets yet (see
  step 2 above) — until it is, `SharedModelContainer` silently falls back to a private,
  non-shared store per process.
- **`xcodegen generate` fails**: check the YAML indentation in `project.yml` wasn't mangled by
  copy/paste; XcodeGen's error message names the offending key.

## Seeding

`SeedData.seedIfNeeded(context:)` runs once on first launch (from `GymTrackerApp.init`) and
inserts the full Push/Pull/Legs library from the spec — 16 exercises, correctly grouped and
ordered. It's a no-op on every subsequent launch once any `Exercise` exists, so user edits
(renames, reorders, added/archived exercises) are never overwritten.
