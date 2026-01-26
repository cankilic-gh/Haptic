import SwiftUI

/// Haptic Watch App - Focus Mode interface
/// Provides uninterruptible haptic metronome feedback
/// using HKWorkoutSession for background execution.

@main
struct HapticWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchMetronomeView()
        }
    }
}
