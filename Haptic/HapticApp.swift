import SwiftUI

/// Haptic - Professional Metronome for iOS & watchOS
/// Perfect synchronization, uninterruptible haptic feedback,
/// designed for progressive metal musicians.

@main
struct HapticApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MetronomeView()
                .environmentObject(appState)
        }
    }
}

// MARK: - App State

class AppState: ObservableObject {
    @Published var isFirstLaunch: Bool = true

    init() {
        checkFirstLaunch()
    }

    private func checkFirstLaunch() {
        isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
    }
}
