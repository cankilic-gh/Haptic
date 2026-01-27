import type { FC } from 'react';
import { IPhoneSimulator } from './IPhoneSimulator';
import { MetronomeApp } from './MetronomeApp';
import { AppleWatchMockup } from './AppleWatchMockup';

export const LandingPage: FC = () => {
  return (
    <div className="min-h-screen w-full" style={{ backgroundColor: 'var(--deep-black)' }}>
      {/* Scan lines overlay */}
      <div className="fixed inset-0 scan-lines pointer-events-none z-50" />

      {/* Header */}
      <header className="fixed top-0 left-0 right-0 z-40 backdrop-blur-md" style={{ backgroundColor: 'rgba(10,10,15,0.8)' }}>
        <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg flex items-center justify-center" style={{ backgroundColor: 'var(--electric-blue)' }}>
              <span className="text-lg">🎵</span>
            </div>
            <span className="text-xl font-bold tracking-wider" style={{ color: 'var(--electric-blue)' }}>
              HAPTIC
            </span>
          </div>
          <AppStoreButton />
        </div>
      </header>

      {/* Main content */}
      <main className="pt-24 pb-16 px-6">
        <div className="max-w-7xl mx-auto">
          {/* Hero Section */}
          <section className="text-center mb-16">
            <h1 className="text-5xl md:text-7xl font-bold text-white mb-4 tracking-tight">
              Feel the <span style={{ color: 'var(--electric-blue)' }} className="neon-text">Rhythm</span>
            </h1>
            <p className="text-xl md:text-2xl max-w-2xl mx-auto" style={{ color: 'var(--secondary-text)' }}>
              Pro metronome for progressive metal musicians.
              Precision timing meets haptic feedback.
            </p>
          </section>

          {/* Bento Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 auto-rows-[minmax(180px,auto)]">

            {/* iPhone Simulator - Large card spanning 2 cols and 3 rows */}
            <BentoCard className="md:col-span-2 lg:row-span-3 flex items-center justify-center p-4">
              <div className="scale-[0.7] md:scale-[0.8] origin-center">
                <IPhoneSimulator>
                  <MetronomeApp />
                </IPhoneSimulator>
              </div>
            </BentoCard>

            {/* Prog Metal Time Signatures */}
            <BentoCard className="p-6 flex flex-col justify-between">
              <div>
                <div className="text-3xl mb-2">🎸</div>
                <h3 className="text-lg font-bold text-white mb-2">Prog Metal Ready</h3>
                <p className="text-sm" style={{ color: 'var(--secondary-text)' }}>
                  7/8, 11/8, 13/16 and more. Built for complex time signatures.
                </p>
              </div>
              <div className="flex gap-2 mt-4">
                {['7/8', '11/8', '13/16'].map((ts) => (
                  <span
                    key={ts}
                    className="px-2 py-1 rounded text-xs font-mono"
                    style={{ backgroundColor: 'var(--charcoal)', color: 'var(--electric-blue)' }}
                  >
                    {ts}
                  </span>
                ))}
              </div>
            </BentoCard>

            {/* Precision */}
            <BentoCard className="p-6 flex flex-col justify-between">
              <div>
                <div className="text-3xl mb-2">⚡</div>
                <h3 className="text-lg font-bold text-white mb-2">Microsecond Precision</h3>
                <p className="text-sm" style={{ color: 'var(--secondary-text)' }}>
                  No drift. No lag. Absolute timing accuracy for long sessions.
                </p>
              </div>
              <div className="font-mono text-2xl font-bold" style={{ color: 'var(--electric-blue)' }}>
                ±0.1ms
              </div>
            </BentoCard>

            {/* Apple Watch Card */}
            <BentoCard className="lg:row-span-2 p-6 flex flex-col items-center justify-center">
              <AppleWatchMockup />
              <h3 className="text-lg font-bold text-white mt-4 text-center">Apple Watch</h3>
              <p className="text-sm text-center mt-2" style={{ color: 'var(--secondary-text)' }}>
                Feel the beat on your wrist. Silent practice anywhere.
              </p>
            </BentoCard>

            {/* Tap Tempo */}
            <BentoCard className="p-6 flex flex-col justify-between">
              <div>
                <div className="text-3xl mb-2">👆</div>
                <h3 className="text-lg font-bold text-white mb-2">Tap Tempo</h3>
                <p className="text-sm" style={{ color: 'var(--secondary-text)' }}>
                  Match any song instantly. Tap to detect BPM.
                </p>
              </div>
            </BentoCard>

            {/* Accent Patterns */}
            <BentoCard className="lg:col-span-2 p-6">
              <div className="flex items-start justify-between">
                <div>
                  <div className="text-3xl mb-2">🥁</div>
                  <h3 className="text-lg font-bold text-white mb-2">Custom Accent Patterns</h3>
                  <p className="text-sm" style={{ color: 'var(--secondary-text)' }}>
                    Create your own patterns. Standard, backbeat, djent - or design your own polyrhythmic groove.
                  </p>
                </div>
              </div>
              <div className="flex gap-2 mt-4">
                {[true, false, false, true, false, true, false].map((accent, i) => (
                  <div
                    key={i}
                    className="w-8 h-8 rounded-lg flex items-center justify-center text-xs font-bold"
                    style={{
                      backgroundColor: accent ? 'var(--electric-blue)' : 'var(--charcoal)',
                      color: accent ? 'var(--deep-black)' : 'var(--secondary-text)',
                    }}
                  >
                    {i + 1}
                  </div>
                ))}
              </div>
            </BentoCard>

            {/* Haptic Feedback */}
            <BentoCard className="p-6 relative overflow-hidden">
              <div className="relative z-10">
                <div className="text-3xl mb-2">📳</div>
                <h3 className="text-lg font-bold text-white mb-2">Haptic Feedback</h3>
                <p className="text-sm" style={{ color: 'var(--secondary-text)' }}>
                  CoreHaptics transient patterns. Feel accents through your device.
                </p>
              </div>
              {/* Pulse animation */}
              <div
                className="absolute inset-0 rounded-2xl opacity-20"
                style={{
                  background: 'radial-gradient(circle at center, var(--electric-blue) 0%, transparent 70%)',
                  animation: 'pulse 2s ease-in-out infinite',
                }}
              />
            </BentoCard>

            {/* BPM Range */}
            <BentoCard className="p-6 flex flex-col justify-between">
              <div>
                <div className="text-3xl mb-2">🎚️</div>
                <h3 className="text-lg font-bold text-white mb-2">Wide BPM Range</h3>
                <p className="text-sm" style={{ color: 'var(--secondary-text)' }}>
                  From doom metal to blast beats.
                </p>
              </div>
              <div className="flex items-center gap-2 mt-4">
                <span className="text-2xl font-bold font-mono" style={{ color: 'var(--cyan-muted)' }}>20</span>
                <div className="flex-1 h-1 rounded" style={{ backgroundColor: 'var(--charcoal)' }}>
                  <div className="h-full w-2/3 rounded" style={{ backgroundColor: 'var(--electric-blue)' }} />
                </div>
                <span className="text-2xl font-bold font-mono" style={{ color: 'var(--electric-blue)' }}>300</span>
              </div>
            </BentoCard>
          </div>

          {/* CTA Section */}
          <section className="mt-16 text-center">
            <h2 className="text-3xl font-bold text-white mb-4">Ready to level up your practice?</h2>
            <p className="mb-8" style={{ color: 'var(--secondary-text)' }}>
              Coming soon to the App Store
            </p>
            <AppStoreButton large />
          </section>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t py-8 px-6" style={{ borderColor: 'var(--charcoal)' }}>
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <span className="text-sm" style={{ color: 'var(--tertiary-text)' }}>
              Built by
            </span>
            <span className="text-sm font-bold" style={{ color: 'var(--electric-blue)' }}>
              TheGridBase
            </span>
          </div>
          <p className="text-sm" style={{ color: 'var(--tertiary-text)' }}>
            © 2025 Haptic. Designed for musicians who count in odd numbers.
          </p>
        </div>
      </footer>

      {/* Keyframes for pulse animation */}
      <style>{`
        @keyframes pulse {
          0%, 100% { transform: scale(1); opacity: 0.2; }
          50% { transform: scale(1.1); opacity: 0.3; }
        }
      `}</style>
    </div>
  );
};

// Bento Card Component
const BentoCard: FC<{ children: React.ReactNode; className?: string }> = ({ children, className = '' }) => (
  <div
    className={`rounded-2xl border transition-all duration-300 hover:border-opacity-50 ${className}`}
    style={{
      backgroundColor: 'var(--charcoal)',
      borderColor: 'var(--dark-gray)',
    }}
  >
    {children}
  </div>
);

// App Store Button
const AppStoreButton: FC<{ large?: boolean }> = ({ large = false }) => (
  <button
    className={`flex items-center gap-2 rounded-xl transition-all opacity-60 cursor-not-allowed ${
      large ? 'px-6 py-3' : 'px-4 py-2'
    }`}
    style={{
      backgroundColor: 'var(--charcoal)',
      border: '1px solid var(--dark-gray)',
    }}
    disabled
  >
    <svg className={large ? 'w-8 h-8' : 'w-6 h-6'} viewBox="0 0 24 24" fill="white">
      <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
    </svg>
    <div className="text-left">
      <div className={`text-white font-semibold ${large ? 'text-base' : 'text-sm'}`}>
        App Store
      </div>
      <div className="text-xs" style={{ color: 'var(--secondary-text)' }}>
        Coming Soon
      </div>
    </div>
  </button>
);
