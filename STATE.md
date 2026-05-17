# Haptic - Current State

**Last Updated:** 2026-03-15
**Status:** Active Development
**Priority:** High
**Bundle ID:** com.thegridbase.Haptic
**GitHub:** thegridbase-dev/Haptic

## Active Decisions
- Multi-platform: Native Swift (iOS + watchOS) + Vite/React 19 (web demo)
- iOS app: SwiftUI with CoreHaptics + AudioClickEngine
- Web demo: Vite 7 + React 19 + TypeScript 5.9 + Tailwind CSS 4
- No shared code between platforms (separate codebases under one repo)
- Professional pro-metronome with haptic + audio feedback

## Current Focus
- Apple Watch companion app (next task)
- App Store submission preparation

## Blockers
- Apple Developer Program enrollment ($99) needed for App Store submission

## Recent Changes (2026-03-15)
- All App Store blockers fixed (deployment targets, app icon, privacy manifest, debug prints)
- AudioClickEngine added (synthesized click sounds, no audio files needed)
- HapticEngine now supports both CoreHaptics + audio simultaneously
- Build: 0 errors, 0 warnings, runs in Simulator
- .gitignore added for Xcode artifacts

## Tech Debt
- watchOS companion app not yet implemented (WatchSyncManager exists but no Watch target)
- Web demo is minimal scaffolding, needs full feature parity plan
- No test framework on either platform
- No CI/CD pipeline configured

---

## Apple Watch App Plan

### Readiness Assessment

| Component | Status | Notes |
|-----------|--------|-------|
| WatchSyncManager | 100% ready | Full WCSession bidirectional sync |
| HapticEngine watchOS fallback | 100% ready | WatchKit .notification/.click |
| Models (Codable) | 100% ready | All types serializable |
| iPhone Watch status UI | 70% ready | "WATCH LINKED/OFFLINE" indicator |
| Xcode Watch target | 0% | Must create |
| Watch UI views | 0% | Must build from scratch |
| WorkoutSession | 0% | Required for background haptics |

### Implementation Steps

#### Phase 1: Xcode Watch Target Setup
1. Add watchOS App target to Haptic.xcodeproj (watchOS 10+, SwiftUI)
2. Configure shared files between iOS and Watch targets:
   - `HapticModels.swift` (shared)
   - `MetronomeManager.swift` (shared - timing engine)
   - `HapticEngine.swift` (shared - has #if os(watchOS) fallback)
   - `AudioClickEngine.swift` (shared - audio clicks on Watch speaker)
   - `PresetManager.swift` (shared)
3. Add WatchConnectivity entitlements to both targets
4. Set deployment target: watchOS 10.0

#### Phase 2: Watch UI (SwiftUI)
5. `WatchMetronomeView.swift` - Main watch face:
   - Large BPM display (Digital Crown adjustable)
   - Play/Stop button (prominent, tappable)
   - Current beat indicator (visual pulse)
   - Time signature display
6. `WatchNowPlayingView.swift` - Active metronome screen:
   - Minimal UI: BPM + beat dots
   - Tap anywhere to stop
   - Digital Crown to adjust BPM while playing
7. `WatchSettingsView.swift` - Quick settings:
   - Time signature picker
   - Accent pattern selector
   - Subdivision toggle
   - Sound on/off toggle

#### Phase 3: Watch-Specific Features
8. Digital Crown integration for BPM control (smooth scrolling)
9. WKExtendedRuntimeSession for background haptics during practice
10. Complications for quick-launch (WidgetKit)
11. Sync with iPhone app (already implemented in WatchSyncManager)

#### Phase 4: Audio on Watch
12. AudioClickEngine on Watch speaker (Apple Watch has speaker)
13. Bluetooth audio output support (AirPods from Watch)
14. Volume control via Digital Crown during playback

### Watch UI Wireframe

```
┌─────────────────────┐
│     ◉ HAPTIC        │
│                     │
│       120           │
│       BPM           │
│   [−]  TAP  [+]     │
│                     │
│    ● ○ ○ ○          │
│    4/4  STANDARD    │
│                     │
│      ▶ PLAY         │
└─────────────────────┘

Now Playing:
┌─────────────────────┐
│       120           │
│       BPM           │
│                     │
│   ● ○ ○ ○           │
│                     │
│    ■ STOP           │
└─────────────────────┘
```

### Estimated Effort
- Phase 1 (Target setup): ~30 min
- Phase 2 (Watch UI): ~2-3 hours
- Phase 3 (Watch features): ~2 hours
- Phase 4 (Audio): ~1 hour
- **Total: ~5-6 hours**
