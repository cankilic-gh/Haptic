# Haptic - Upgrade Plan

**Analiz Tarihi:** 2026-02-16
**Tip:** iOS (Swift/SwiftUI) + Web (Vite React)
**Platformlar:** iOS, watchOS (planned), Web

---

## Kritik Upgrades

### 1. Apple Watch App Target
**Oncelik:** KRITIK
**Dosyalar:** `Managers/WatchSyncManager.swift`, `Managers/HapticEngine.swift`

WatchSyncManager altyapisi hazir, WatchKit fallback yazilmis, ama Xcode'da watchOS target YOK.

**Gorev:**
- [ ] Xcode'da watchOS companion app target olustur
- [ ] Watch UI'ini SwiftUI ile yaz
- [ ] WKWorkoutSession entegrasyonu yap
- [ ] HealthKit ile kalp atisi sync ekle

---

## Yuksek Oncelikli Upgrades

### 2. Web Audio Ses Kalitesi
**Oncelik:** YUKSEK
**Dosya:** `web/src/hooks/useMetronome.ts` (satir 98-117)

Basit oscillator "beep" sesi yerine profesyonel click sesi gerekli.

```bash
npm install tone
# veya AudioBuffer ile impulse
```

**Gorev:**
- [ ] AudioBuffer ile click sesi olustur
- [ ] Accent/normal/subdivision icin farkli sesler
- [ ] Oscillator kodunu kaldir

---

### 3. Web Haptic Feedback iOS Destegi
**Oncelik:** YUKSEK
**Dosya:** `web/src/hooks/useMetronome.ts` (satir 120-122)

`navigator.vibrate()` iOS'ta calismaz.

**Gorev:**
- [ ] iOS 17+ haptic API kontrol et
- [ ] Fallback: sub-20Hz audio pulse
- [ ] PWA + native wrapper arastir

---

### 4. Preset Kaydetme / iCloud Sync
**Oncelik:** YUKSEK
**Dosya:** `Models/HapticModels.swift`

MetronomePreset ve PracticeSession Codable ama persist edilmiyor.

**Gorev:**
- [ ] UserDefaults ile basit persist
- [ ] CloudKit entegrasyonu
- [ ] NSPersistentCloudKitContainer setup

---

## Orta Oncelikli Upgrades

### 5. Web AudioContext Lifecycle
**Oncelik:** ORTA
**Dosya:** `web/src/hooks/useMetronome.ts`

Sayfa arkaplana gecince AudioContext suspend edilmiyor.

**Gorev:**
- [ ] visibilitychange event listener ekle
- [ ] document.hidden -> ctx.suspend()
- [ ] visible -> ctx.resume()

---

### 6. TunerEngine YIN Optimizasyonu
**Oncelik:** ORTA
**Dosya:** `Managers/TunerEngine.swift` (satir 200-207)

O(N^2) hesaplama performans sorunu.

**Gorev:**
- [ ] vDSP_conv veya FFT-based autocorrelation kullan
- [ ] O(N log N) complexity'e dusur

---

### 7. Subdivision Genisletme
**Oncelik:** ORTA
**Dosya:** `Managers/MetronomeManager.swift`

Sadece 8th, triplet, 16th var.

**Gorev:**
- [ ] Quintuplet (5'li) ekle
- [ ] Sextuplet (6'li) ekle
- [ ] 32nd note destegi

---

## Dusuk Oncelikli Upgrades

### 8. Web Watch Mockup Entegrasyonu
**Dosya:** `web/src/components/AppleWatchMockup.tsx`

Hardcode 120 BPM, gercek useMetronome'a bagli degil.

**Gorev:**
- [ ] useMetronome hook'una bagla
- [ ] Canli BPM goster

---

### 9. Tuner Warmup Suresi
**Dosya:** `Views/TunerView.swift`

Ilk 200-300ms buffer kararsiz olabilir.

**Gorev:**
- [ ] warmupFrames sayaci ekle
- [ ] Ilk birkac buffer'i atla

---

### 10. Accessibility
**Dosyalar:** iOS Views, Web components

accessibilityLabel, aria-label eksik.

**Gorev:**
- [ ] iOS CyberpunkBeatCell a11y ekle
- [ ] Web BeatGrid, PlayButton aria-label ekle

---

## Onerilen Teknolojiler

| Alan | Oneri | Gerekcesi |
|------|-------|-----------|
| Watch UI | SwiftUI + HealthKit | Workout session + haptic sync |
| iOS Persist | CloudKit | Cross-device preset sync |
| Web Audio | `@tonejs/tone` veya AudioWorklet | Profesyonel ses kalitesi |
| YIN | Accelerate vDSP | O(N log N) pitch detection |
| Web Animation | Framer Motion | Tutarli spring animasyonlar |
| PWA | Web App Manifest + SW | Offline + install |

---

## Tahmini Is Yukleri

| Upgrade | Zorluk |
|---------|--------|
| Watch App Target | Zor |
| Web Audio Quality | Orta |
| iCloud Sync | Orta |
| YIN Optimizasyonu | Orta |
| Subdivision Ekleme | Kolay |
