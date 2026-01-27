import { useEffect, useState } from 'react';
import type { FC } from 'react';
import { IPhoneSimulator } from './IPhoneSimulator';
import { MetronomeApp } from './MetronomeApp';
import { AppleWatchMockup } from './AppleWatchMockup';

export const LandingPage: FC = () => {
  return (
    <div className="min-h-screen w-full relative overflow-hidden" style={{ backgroundColor: 'var(--deep-black)' }}>
      {/* Animated Sound Wave Background */}
      <SoundWaveBackground />

      {/* Floating Orbs */}
      <FloatingOrbs />

      {/* Scan lines overlay */}
      <div className="fixed inset-0 scan-lines pointer-events-none z-40" />

      {/* Header */}
      <header className="fixed top-0 left-0 right-0 z-50 backdrop-blur-xl" style={{ backgroundColor: 'rgba(10,10,15,0.7)' }}>
        <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3 group cursor-pointer">
            <div
              className="w-10 h-10 rounded-xl flex items-center justify-center transition-all duration-300 group-hover:scale-110 group-hover:rotate-3"
              style={{
                backgroundColor: 'var(--electric-blue)',
                boxShadow: '0 0 20px rgba(0, 212, 255, 0.3)'
              }}
            >
              <span className="text-xl">🎵</span>
            </div>
            <span className="text-xl font-bold tracking-wider transition-all duration-300 group-hover:tracking-widest" style={{ color: 'var(--electric-blue)' }}>
              HAPTIC
            </span>
          </div>
          <AppStoreButton />
        </div>
      </header>

      {/* Main content */}
      <main className="relative z-10 pt-28 pb-16 px-6">
        <div className="max-w-7xl mx-auto">
          {/* Hero Section */}
          <section className="text-center mb-20">
            <div className="inline-block mb-4 px-4 py-1.5 rounded-full text-sm animate-pulse" style={{
              backgroundColor: 'rgba(0, 212, 255, 0.1)',
              border: '1px solid rgba(0, 212, 255, 0.3)',
              color: 'var(--electric-blue)'
            }}>
              ⚡ Built for Progressive Metal
            </div>
            <h1 className="text-5xl md:text-7xl lg:text-8xl font-bold text-white mb-6 tracking-tight">
              Feel the{' '}
              <span
                className="relative inline-block"
                style={{ color: 'var(--electric-blue)' }}
              >
                <span className="relative z-10 neon-text">Rhythm</span>
                <span
                  className="absolute inset-0 blur-2xl opacity-50"
                  style={{ backgroundColor: 'var(--electric-blue)' }}
                />
              </span>
            </h1>
            <p className="text-xl md:text-2xl max-w-2xl mx-auto leading-relaxed" style={{ color: 'var(--secondary-text)' }}>
              Pro metronome for progressive metal musicians.
              <br />
              <span style={{ color: 'var(--electric-blue)' }}>Precision timing</span> meets <span style={{ color: 'var(--cyan-bright)' }}>haptic feedback</span>.
            </p>
          </section>

          {/* Bento Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5 auto-rows-[minmax(180px,auto)]">

            {/* iPhone Simulator - Large card */}
            <GlassCard className="md:col-span-2 lg:row-span-3 flex items-center justify-center p-6" delay={0}>
              <div className="scale-[0.65] md:scale-[0.75] origin-center">
                <IPhoneSimulator>
                  <MetronomeApp />
                </IPhoneSimulator>
              </div>
            </GlassCard>

            {/* Prog Metal Time Signatures */}
            <GlassCard className="p-6 flex flex-col justify-between group" delay={100}>
              <div>
                <div className="text-4xl mb-3 transition-transform duration-300 group-hover:scale-110 group-hover:rotate-6">🎸</div>
                <h3 className="text-lg font-bold text-white mb-2">Prog Metal Ready</h3>
                <p className="text-sm leading-relaxed" style={{ color: 'var(--secondary-text)' }}>
                  7/8, 11/8, 13/16 and more. Built for complex time signatures.
                </p>
              </div>
              <div className="flex gap-2 mt-4">
                {['7/8', '11/8', '13/16'].map((ts, i) => (
                  <span
                    key={ts}
                    className="px-3 py-1.5 rounded-lg text-xs font-mono font-bold transition-all duration-300 hover:scale-105"
                    style={{
                      backgroundColor: 'rgba(0, 212, 255, 0.15)',
                      color: 'var(--electric-blue)',
                      border: '1px solid rgba(0, 212, 255, 0.3)',
                      animationDelay: `${i * 100}ms`
                    }}
                  >
                    {ts}
                  </span>
                ))}
              </div>
            </GlassCard>

            {/* Precision */}
            <GlassCard className="p-6 flex flex-col justify-between group" delay={200}>
              <div>
                <div className="text-4xl mb-3 transition-transform duration-300 group-hover:scale-110 group-hover:animate-pulse">⚡</div>
                <h3 className="text-lg font-bold text-white mb-2">Microsecond Precision</h3>
                <p className="text-sm leading-relaxed" style={{ color: 'var(--secondary-text)' }}>
                  No drift. No lag. Absolute timing accuracy for long sessions.
                </p>
              </div>
              <div
                className="font-mono text-3xl font-bold mt-4 transition-all duration-300 group-hover:scale-105"
                style={{ color: 'var(--electric-blue)' }}
              >
                ±0.1<span className="text-lg">ms</span>
              </div>
            </GlassCard>

            {/* Apple Watch Card */}
            <GlassCard className="lg:row-span-2 p-6 flex flex-col items-center justify-center" delay={300}>
              <AppleWatchMockup />
              <h3 className="text-lg font-bold text-white mt-5 text-center">Apple Watch</h3>
              <p className="text-sm text-center mt-2 leading-relaxed" style={{ color: 'var(--secondary-text)' }}>
                Feel the beat on your wrist.
                <br />
                <span style={{ color: 'var(--electric-blue)' }}>Silent practice anywhere.</span>
              </p>
            </GlassCard>

            {/* Tap Tempo */}
            <GlassCard className="p-6 flex flex-col justify-between group" delay={400}>
              <div>
                <div className="text-4xl mb-3 transition-transform duration-300 group-hover:scale-125 cursor-pointer">👆</div>
                <h3 className="text-lg font-bold text-white mb-2">Tap Tempo</h3>
                <p className="text-sm leading-relaxed" style={{ color: 'var(--secondary-text)' }}>
                  Match any song instantly. Tap to detect BPM.
                </p>
              </div>
              <div className="flex gap-1 mt-4">
                {[1, 2, 3, 4].map((_, i) => (
                  <div
                    key={i}
                    className="h-8 rounded-full transition-all duration-150"
                    style={{
                      width: '4px',
                      backgroundColor: 'var(--electric-blue)',
                      opacity: 0.3 + (i * 0.2),
                      animation: `tapPulse 1s ease-in-out ${i * 0.15}s infinite`
                    }}
                  />
                ))}
              </div>
            </GlassCard>

            {/* Accent Patterns */}
            <GlassCard className="lg:col-span-2 p-6 group" delay={500}>
              <div className="flex items-start justify-between">
                <div>
                  <div className="text-4xl mb-3 transition-transform duration-300 group-hover:scale-110">🥁</div>
                  <h3 className="text-lg font-bold text-white mb-2">Custom Accent Patterns</h3>
                  <p className="text-sm leading-relaxed" style={{ color: 'var(--secondary-text)' }}>
                    Create your own patterns. Standard, backbeat, djent - or design your own polyrhythmic groove.
                  </p>
                </div>
              </div>
              <div className="flex gap-2 mt-5">
                {[true, false, false, true, false, true, false].map((accent, i) => (
                  <div
                    key={i}
                    className="w-10 h-10 rounded-xl flex items-center justify-center text-sm font-bold transition-all duration-300 hover:scale-110 cursor-pointer"
                    style={{
                      backgroundColor: accent ? 'var(--electric-blue)' : 'rgba(255,255,255,0.05)',
                      color: accent ? 'var(--deep-black)' : 'var(--secondary-text)',
                      border: accent ? 'none' : '1px solid rgba(255,255,255,0.1)',
                      boxShadow: accent ? '0 0 20px rgba(0, 212, 255, 0.4)' : 'none',
                      animation: accent ? `beatPulse 0.5s ease-out ${i * 0.1}s` : 'none'
                    }}
                  >
                    {i + 1}
                  </div>
                ))}
              </div>
            </GlassCard>

            {/* Haptic Feedback */}
            <GlassCard className="p-6 relative overflow-hidden group" delay={600}>
              <div className="relative z-10">
                <div className="text-4xl mb-3 transition-transform duration-300 group-hover:scale-110 group-hover:animate-vibrate">📳</div>
                <h3 className="text-lg font-bold text-white mb-2">Haptic Feedback</h3>
                <p className="text-sm leading-relaxed" style={{ color: 'var(--secondary-text)' }}>
                  CoreHaptics transient patterns. Feel accents through your device.
                </p>
              </div>
              {/* Pulse rings */}
              <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
                <div className="absolute w-32 h-32 rounded-full opacity-0 group-hover:opacity-100 transition-opacity duration-300" style={{
                  border: '2px solid var(--electric-blue)',
                  animation: 'ripple 1.5s ease-out infinite'
                }} />
                <div className="absolute w-32 h-32 rounded-full opacity-0 group-hover:opacity-100 transition-opacity duration-300" style={{
                  border: '2px solid var(--electric-blue)',
                  animation: 'ripple 1.5s ease-out 0.5s infinite'
                }} />
              </div>
            </GlassCard>

            {/* BPM Range */}
            <GlassCard className="p-6 flex flex-col justify-between group" delay={700}>
              <div>
                <div className="text-4xl mb-3 transition-transform duration-300 group-hover:scale-110">🎚️</div>
                <h3 className="text-lg font-bold text-white mb-2">Wide BPM Range</h3>
                <p className="text-sm leading-relaxed" style={{ color: 'var(--secondary-text)' }}>
                  From doom metal to blast beats.
                </p>
              </div>
              <div className="mt-4">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-xl font-bold font-mono" style={{ color: 'var(--cyan-muted)' }}>20</span>
                  <span className="text-xl font-bold font-mono" style={{ color: 'var(--electric-blue)' }}>300</span>
                </div>
                <div className="h-2 rounded-full overflow-hidden" style={{ backgroundColor: 'rgba(255,255,255,0.1)' }}>
                  <div
                    className="h-full rounded-full transition-all duration-1000 group-hover:w-full"
                    style={{
                      width: '60%',
                      background: 'linear-gradient(90deg, var(--cyan-dark), var(--electric-blue), var(--cyan-bright))'
                    }}
                  />
                </div>
              </div>
            </GlassCard>
          </div>

          {/* CTA Section */}
          <section className="mt-24 text-center">
            <h2 className="text-4xl md:text-5xl font-bold text-white mb-4">
              Ready to level up your <span style={{ color: 'var(--electric-blue)' }}>practice</span>?
            </h2>
            <p className="text-lg mb-10" style={{ color: 'var(--secondary-text)' }}>
              Coming soon to the App Store
            </p>
            <AppStoreButton large />
          </section>
        </div>
      </main>

      {/* Footer */}
      <footer className="relative z-10 border-t py-8 px-6" style={{ borderColor: 'rgba(255,255,255,0.1)' }}>
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <span className="text-sm" style={{ color: 'var(--tertiary-text)' }}>
              Built with 🎸 by
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

      {/* Keyframes */}
      <style>{`
        @keyframes ripple {
          0% { transform: scale(0.5); opacity: 0.8; }
          100% { transform: scale(2); opacity: 0; }
        }
        @keyframes tapPulse {
          0%, 100% { transform: scaleY(1); }
          50% { transform: scaleY(1.5); }
        }
        @keyframes beatPulse {
          0% { transform: scale(1); }
          50% { transform: scale(1.1); }
          100% { transform: scale(1); }
        }
        @keyframes vibrate {
          0%, 100% { transform: translateX(0) scale(1.1); }
          25% { transform: translateX(-2px) scale(1.1); }
          75% { transform: translateX(2px) scale(1.1); }
        }
        @keyframes float {
          0%, 100% { transform: translateY(0px); }
          50% { transform: translateY(-20px); }
        }
        @keyframes wave {
          0% { transform: translateX(0) scaleY(1); }
          50% { transform: translateX(-25%) scaleY(0.8); }
          100% { transform: translateX(-50%) scaleY(1); }
        }
        .animate-vibrate {
          animation: vibrate 0.3s ease-in-out;
        }
      `}</style>
    </div>
  );
};

// Sound Wave Background Component
const SoundWaveBackground: FC = () => {
  return (
    <div className="fixed inset-0 overflow-hidden pointer-events-none z-0">
      {/* Gradient overlay */}
      <div
        className="absolute inset-0"
        style={{
          background: 'radial-gradient(ellipse at 50% 0%, rgba(0, 212, 255, 0.08) 0%, transparent 50%)'
        }}
      />

      {/* Sound waves */}
      <svg
        className="absolute bottom-0 left-0 w-[200%] h-64 opacity-20"
        style={{ animation: 'wave 8s linear infinite' }}
        viewBox="0 0 1440 320"
        preserveAspectRatio="none"
      >
        <path
          fill="var(--electric-blue)"
          d="M0,192L48,197.3C96,203,192,213,288,229.3C384,245,480,267,576,250.7C672,235,768,181,864,181.3C960,181,1056,235,1152,234.7C1248,235,1344,181,1392,154.7L1440,128L1440,320L1392,320C1344,320,1248,320,1152,320C1056,320,960,320,864,320C768,320,672,320,576,320C480,320,384,320,288,320C192,320,96,320,48,320L0,320Z"
        />
      </svg>
      <svg
        className="absolute bottom-0 left-0 w-[200%] h-48 opacity-10"
        style={{ animation: 'wave 12s linear infinite reverse' }}
        viewBox="0 0 1440 320"
        preserveAspectRatio="none"
      >
        <path
          fill="var(--cyan-bright)"
          d="M0,64L48,80C96,96,192,128,288,128C384,128,480,96,576,90.7C672,85,768,107,864,144C960,181,1056,235,1152,234.7C1248,235,1344,181,1392,154.7L1440,128L1440,320L1392,320C1344,320,1248,320,1152,320C1056,320,960,320,864,320C768,320,672,320,576,320C480,320,384,320,288,320C192,320,96,320,48,320L0,320Z"
        />
      </svg>
    </div>
  );
};

// Floating Orbs Component
const FloatingOrbs: FC = () => {
  return (
    <div className="fixed inset-0 overflow-hidden pointer-events-none z-0">
      <div
        className="absolute w-96 h-96 rounded-full blur-3xl opacity-20"
        style={{
          background: 'var(--electric-blue)',
          top: '10%',
          right: '10%',
          animation: 'float 6s ease-in-out infinite'
        }}
      />
      <div
        className="absolute w-64 h-64 rounded-full blur-3xl opacity-10"
        style={{
          background: 'var(--cyan-bright)',
          bottom: '20%',
          left: '5%',
          animation: 'float 8s ease-in-out infinite reverse'
        }}
      />
      <div
        className="absolute w-48 h-48 rounded-full blur-3xl opacity-15"
        style={{
          background: 'var(--cyan-muted)',
          top: '50%',
          left: '30%',
          animation: 'float 10s ease-in-out infinite'
        }}
      />
    </div>
  );
};

// Glass Card Component with animations
const GlassCard: FC<{ children: React.ReactNode; className?: string; delay?: number }> = ({
  children,
  className = '',
  delay = 0
}) => {
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => setIsVisible(true), delay);
    return () => clearTimeout(timer);
  }, [delay]);

  return (
    <div
      className={`
        rounded-2xl border backdrop-blur-xl
        transition-all duration-500 ease-out
        hover:border-opacity-50 hover:scale-[1.02] hover:shadow-lg
        ${isVisible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-8'}
        ${className}
      `}
      style={{
        backgroundColor: 'rgba(20, 20, 26, 0.6)',
        borderColor: 'rgba(255, 255, 255, 0.08)',
        boxShadow: '0 8px 32px rgba(0, 0, 0, 0.3), inset 0 1px 0 rgba(255,255,255,0.05)',
      }}
    >
      {children}
    </div>
  );
};

// App Store Button
const AppStoreButton: FC<{ large?: boolean }> = ({ large = false }) => (
  <button
    className={`
      flex items-center gap-3 rounded-xl transition-all duration-300
      hover:scale-105 opacity-70 hover:opacity-90 cursor-not-allowed
      backdrop-blur-xl
      ${large ? 'px-8 py-4' : 'px-5 py-2.5'}
    `}
    style={{
      backgroundColor: 'rgba(20, 20, 26, 0.8)',
      border: '1px solid rgba(255, 255, 255, 0.1)',
      boxShadow: '0 4px 20px rgba(0, 0, 0, 0.3)'
    }}
    disabled
  >
    <svg className={large ? 'w-8 h-8' : 'w-6 h-6'} viewBox="0 0 24 24" fill="white">
      <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
    </svg>
    <div className="text-left">
      <div className={`text-white font-semibold ${large ? 'text-lg' : 'text-sm'}`}>
        App Store
      </div>
      <div className="text-xs" style={{ color: 'var(--secondary-text)' }}>
        Coming Soon
      </div>
    </div>
  </button>
);
