# Haptic - Pro Metronome for iOS & watchOS

**A professional-grade metronome with CoreHaptics and uninterruptible Apple Watch background execution.** Designed for progressive metal guitarists who need sharp, tactile cues.

[![Swift](https://img.shields.io/badge/Swift-5.9-F05138?style=for-the-badge&logo=swift)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-006AFF?style=for-the-badge&logo=swift)](https://developer.apple.com/xcode/swiftui/)
[![iOS](https://img.shields.io/badge/iOS-17+-000000?style=for-the-badge&logo=apple)](https://www.apple.com/ios/)
[![watchOS](https://img.shields.io/badge/watchOS-10+-000000?style=for-the-badge&logo=apple)](https://www.apple.com/watchos/)

🌐 **Web Demo:** [haptic.thegridbase.com](https://haptic.thegridbase.com)

---

## Features

- **Uninterrupted Watch Haptics** - Uses HKWorkoutSession to keep vibrating even when wrist is lowered
- **High-Precision Timing** - DispatchSourceTimer prevents drift during long sessions
- **CoreHaptics Transient Patterns** - Sharp, percussive taps (not generic vibrations)
- **Prog-Metal Ready** - 7/8, 11/8, 13/16 and custom accent patterns
- **iPhone ↔ Watch Sync** - Real-time BPM synchronization
- **Digital Crown** - Adjust BPM by rotating the crown

## Setup Instructions

### 1. Create Xcode Project

1. Open Xcode 15+
2. File → New → Project
3. Select **"iOS App"** with **Watch App** companion
4. Configure:
   - Product Name: `Haptic`
   - Team: Your Apple Developer Team
   - Organization Identifier: `com.yourname`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - ✅ Include Watch App (with Watch App for watchOS 10)

### 2. Copy Source Files

Replace the generated files with the files from this repository:

```
Haptic/                    → Your Xcode project's main target
HapticWatch Extension/     → Your Xcode project's watch extension
```

### 3. Configure Capabilities

#### iOS Target:
1. Select iOS target → Signing & Capabilities
2. Add: **HealthKit** (for workout session sync awareness)
3. Add: **Background Modes** → ✅ Audio, AirPlay, and Picture in Picture

#### watchOS Target:
1. Select Watch target → Signing & Capabilities
2. Add: **HealthKit**
3. Add: **Background Modes** → ✅ Workout processing

### 4. Info.plist Entries

#### iOS Info.plist:
```xml
<key>NSHealthShareUsageDescription</key>
<string>Haptic uses HealthKit to maintain metronome sync with Apple Watch during workouts.</string>
```

#### watchOS Info.plist:
```xml
<key>NSHealthShareUsageDescription</key>
<string>Haptic needs workout access to keep the metronome running in background.</string>
<key>WKBackgroundModes</key>
<array>
    <string>workout-processing</string>
</array>
```

### 5. Build & Run

⚠️ **IMPORTANT: You MUST test on physical devices!**

- CoreHaptics doesn't work on Simulator
- Watch background mode requires real hardware
- Use your iPhone + Apple Watch pair

## Testing Checklist

### iPhone App
- [ ] BPM display shows correctly
- [ ] Tap BPM number for tap tempo
- [ ] +1/-1/+10/-10 buttons work
- [ ] Beat sequencer shows correct number of beats
- [ ] Tap beats to toggle accent (blue dot appears)
- [ ] Time signature picker opens
- [ ] Play button starts metronome
- [ ] Current beat highlights green/blue
- [ ] Haptic feedback on each beat

### Apple Watch App
- [ ] BPM syncs from iPhone
- [ ] Digital Crown adjusts BPM
- [ ] Play/Stop works
- [ ] Beat indicators pulse
- [ ] **CRITICAL:** Lower wrist - haptics should CONTINUE
- [ ] **CRITICAL:** Turn screen off - haptics should CONTINUE
- [ ] Workout icon appears when playing (HKWorkoutSession active)

### Sync Test
- [ ] Change BPM on iPhone → Watch updates
- [ ] Change BPM on Watch → iPhone updates
- [ ] Start on iPhone → Watch shows playing state
- [ ] Stop on Watch → iPhone shows stopped state

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         iPhone                               │
├─────────────────────────────────────────────────────────────┤
│  MetronomeView (SwiftUI)                                    │
│       ↓                                                      │
│  MetronomeManager (Timing Engine)                           │
│       ↓                                                      │
│  HapticEngine (CoreHaptics)                                 │
│       ↓                                                      │
│  WatchSyncManager ←──── WCSession ────→ Watch               │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                       Apple Watch                            │
├─────────────────────────────────────────────────────────────┤
│  WatchMetronomeView (SwiftUI)                               │
│       ↓                                                      │
│  WorkoutSessionManager (HKWorkoutSession)                   │
│       ↓ Keeps app alive in background                       │
│  MetronomeManager (Timing Engine)                           │
│       ↓                                                      │
│  HapticEngine (CoreHaptics / WKInterfaceDevice fallback)   │
└─────────────────────────────────────────────────────────────┘
```

## Troubleshooting

### Haptics stop when wrist is lowered
- Ensure WorkoutSession is starting (check for workout icon)
- Verify HealthKit authorization was granted
- Check Background Modes capability includes "workout-processing"

### Watch not connecting
- Both devices must be on same iCloud account
- Watch must be paired with iPhone
- Try: Settings → General → Reset → Reset Sync Data

### Timing drift
- This shouldn't happen (we use mach_absolute_time)
- If it does, check CPU throttling on device

## License

MIT License - Use freely for your projects.

---

## Author

**Can Kilic**

- Portfolio: [cankilic.com](https://cankilic.com)
- GitHub: [@cankilic-gh](https://github.com/cankilic-gh)
