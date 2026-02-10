import { useEffect, useState, useRef } from 'react';
import type { FC } from 'react';
import { IPhoneSimulator } from './IPhoneSimulator';
import { MetronomeApp } from './MetronomeApp';
import { AppleWatchMockup } from './AppleWatchMockup';

export const LandingPage: FC = () => {
  return (
    <div className="min-h-screen w-full relative overflow-hidden" style={{ backgroundColor: 'var(--deep-black)' }}>
      {/* Particle Wave Mesh Background */}
      <ParticleWaveBackground />

      {/* Scan lines overlay */}
      <div className="fixed inset-0 scan-lines pointer-events-none z-40" />

      {/* Header */}
      <header className="fixed top-0 left-0 right-0 z-50 backdrop-blur-xl" style={{ backgroundColor: 'rgba(10,10,15,0.7)' }}>
        <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3 group cursor-pointer">
            <div
              className="w-10 h-10 rounded-xl flex items-center justify-center transition-all duration-300 group-hover:scale-110"
              style={{
                background: 'linear-gradient(135deg, var(--electric-blue), var(--cyan-bright))',
                boxShadow: '0 0 20px rgba(0, 212, 255, 0.4)'
              }}
            >
              <WaveformIcon className="w-5 h-5" />
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
            <div className="inline-block mb-8 px-4 py-1.5 rounded-full text-sm" style={{
              backgroundColor: 'rgba(0, 212, 255, 0.1)',
              border: '1px solid rgba(0, 212, 255, 0.3)',
              color: 'var(--electric-blue)'
            }}>
              Built for Progressive Metal
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
            <GlassCard className="md:col-span-2 lg:row-span-2 flex items-center justify-center p-2" delay={0}>
              <div className="scale-[0.9] origin-center">
                <IPhoneSimulator>
                  <MetronomeApp />
                </IPhoneSimulator>
              </div>
            </GlassCard>

            {/* Prog Metal Time Signatures */}
            <GlassCard className="p-6 flex flex-col justify-between group" delay={100}>
              <div>
                <div className="w-10 h-10 rounded-lg flex items-center justify-center mb-3" style={{
                  background: 'linear-gradient(135deg, rgba(0,212,255,0.2), rgba(0,212,255,0.05))',
                  border: '1px solid rgba(0,212,255,0.2)'
                }}>
                  <TimeSignatureIcon className="w-5 h-5" />
                </div>
                <h3 className="text-lg font-bold text-white mb-2">Prog Metal Ready</h3>
                <p className="text-sm leading-relaxed" style={{ color: 'var(--secondary-text)' }}>
                  7/8, 11/8, 13/16 and more. Built for complex time signatures.
                </p>
              </div>
              <div className="flex gap-2 mt-4">
                {['7/8', '11/8', '13/16'].map((ts) => (
                  <span
                    key={ts}
                    className="px-3 py-1.5 rounded-lg text-xs font-mono font-bold transition-all duration-300 hover:scale-105"
                    style={{
                      backgroundColor: 'rgba(0, 212, 255, 0.15)',
                      color: 'var(--electric-blue)',
                      border: '1px solid rgba(0, 212, 255, 0.3)',
                    }}
                  >
                    {ts}
                  </span>
                ))}
              </div>
            </GlassCard>

            {/* Apple Watch Card */}
            <GlassCard className="p-6 flex flex-col items-center justify-center group" delay={200}>
              <AppleWatchMockup />
              <h3 className="text-lg font-bold text-white mt-4 text-center">Apple Watch</h3>
              <p className="text-sm text-center mt-2 leading-relaxed" style={{ color: 'var(--secondary-text)' }}>
                Feel the beat on your wrist.
                <br />
                <span style={{ color: 'var(--electric-blue)' }}>Silent practice anywhere.</span>
              </p>
            </GlassCard>

            {/* Chromatic Tuner Card */}
            <GlassCard className="p-6 flex flex-col items-center justify-center group" delay={250}>
              <TunerVisual />
              <h3 className="text-lg font-bold text-white mt-4 text-center">Chromatic Tuner</h3>
              <p className="text-sm text-center mt-2 leading-relaxed" style={{ color: 'var(--secondary-text)' }}>
                Professional pitch detection
                <br />
                <span style={{ color: 'var(--electric-blue)' }}>with haptic feedback.</span>
              </p>
              <div className="flex flex-wrap justify-center gap-2 mt-3">
                {['Real-time', '±1 cent', 'Haptic'].map((feature) => (
                  <span
                    key={feature}
                    className="px-2 py-1 rounded-md text-[10px] font-medium"
                    style={{
                      backgroundColor: 'rgba(0, 212, 255, 0.1)',
                      color: 'var(--electric-blue)',
                      border: '1px solid rgba(0, 212, 255, 0.2)',
                    }}
                  >
                    {feature}
                  </span>
                ))}
              </div>
            </GlassCard>

            {/* Precision */}
            <GlassCard className="p-6 flex flex-col justify-between group" delay={300}>
              <div>
                <div className="w-10 h-10 rounded-lg flex items-center justify-center mb-3" style={{
                  background: 'linear-gradient(135deg, rgba(0,212,255,0.2), rgba(0,212,255,0.05))',
                  border: '1px solid rgba(0,212,255,0.2)'
                }}>
                  <PrecisionIcon className="w-5 h-5" />
                </div>
                <h3 className="text-lg font-bold text-white mb-2">Microsecond Precision</h3>
                <p className="text-sm leading-relaxed" style={{ color: 'var(--secondary-text)' }}>
                  No drift. No lag. Absolute timing accuracy.
                </p>
              </div>
              <div
                className="font-mono text-3xl font-bold mt-4 transition-all duration-300 group-hover:scale-105"
                style={{ color: 'var(--electric-blue)' }}
              >
                ±0.1<span className="text-lg">ms</span>
              </div>
            </GlassCard>

            {/* Accent Patterns */}
            <GlassCard className="p-6 group" delay={400}>
              <div>
                <div className="w-10 h-10 rounded-lg flex items-center justify-center mb-3" style={{
                  background: 'linear-gradient(135deg, rgba(0,212,255,0.2), rgba(0,212,255,0.05))',
                  border: '1px solid rgba(0,212,255,0.2)'
                }}>
                  <PatternIcon className="w-5 h-5" />
                </div>
                <h3 className="text-lg font-bold text-white mb-2">Accent Patterns</h3>
                <p className="text-sm leading-relaxed" style={{ color: 'var(--secondary-text)' }}>
                  Standard, backbeat, djent - design your own groove.
                </p>
              </div>
              <div className="flex gap-1.5 mt-4">
                {[true, false, true, false, true].map((accent, i) => (
                  <div
                    key={i}
                    className="w-8 h-8 rounded-lg flex items-center justify-center text-xs font-bold transition-all duration-300 hover:scale-110 cursor-pointer"
                    style={{
                      backgroundColor: accent ? 'var(--electric-blue)' : 'rgba(255,255,255,0.05)',
                      color: accent ? 'var(--deep-black)' : 'var(--secondary-text)',
                      border: accent ? 'none' : '1px solid rgba(255,255,255,0.1)',
                      boxShadow: accent ? '0 0 15px rgba(0, 212, 255, 0.4)' : 'none',
                    }}
                  >
                    {i + 1}
                  </div>
                ))}
              </div>
            </GlassCard>

            {/* Tap Tempo */}
            <GlassCard className="p-6 flex flex-col justify-between group" delay={500}>
              <div>
                <div className="w-10 h-10 rounded-lg flex items-center justify-center mb-3" style={{
                  background: 'linear-gradient(135deg, rgba(0,212,255,0.2), rgba(0,212,255,0.05))',
                  border: '1px solid rgba(0,212,255,0.2)'
                }}>
                  <TapIcon className="w-5 h-5" />
                </div>
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

            {/* Haptic Feedback */}
            <GlassCard className="p-6 relative overflow-hidden group" delay={600}>
              <div className="relative z-10">
                <div className="w-10 h-10 rounded-lg flex items-center justify-center mb-3" style={{
                  background: 'linear-gradient(135deg, rgba(0,212,255,0.2), rgba(0,212,255,0.05))',
                  border: '1px solid rgba(0,212,255,0.2)'
                }}>
                  <HapticIcon className="w-5 h-5" />
                </div>
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
                <div className="w-10 h-10 rounded-lg flex items-center justify-center mb-3" style={{
                  background: 'linear-gradient(135deg, rgba(0,212,255,0.2), rgba(0,212,255,0.05))',
                  border: '1px solid rgba(0,212,255,0.2)'
                }}>
                  <BPMIcon className="w-5 h-5" />
                </div>
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
      `}</style>
    </div>
  );
};

// Particle Wave Mesh Background - Full screen animated particle system
const ParticleWaveBackground: FC = () => {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let animationId: number;
    let particles: { x: number; y: number; baseY: number; speed: number; size: number; opacity: number }[] = [];

    const resize = () => {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
      initParticles();
    };

    const initParticles = () => {
      particles = [];
      const cols = Math.floor(canvas.width / 30);
      const rows = Math.floor(canvas.height / 30);

      for (let i = 0; i < cols; i++) {
        for (let j = 0; j < rows; j++) {
          particles.push({
            x: (i / cols) * canvas.width + (Math.random() - 0.5) * 20,
            y: (j / rows) * canvas.height,
            baseY: (j / rows) * canvas.height,
            speed: 0.5 + Math.random() * 1.5,
            size: 1 + Math.random() * 2,
            opacity: 0.1 + Math.random() * 0.4
          });
        }
      }
    };

    let time = 0;
    const animate = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      time += 0.01;

      // Draw particles and connections
      particles.forEach((p, i) => {
        // Wave motion
        const waveOffset = Math.sin(p.x * 0.005 + time) * 40 + Math.sin(p.x * 0.003 + time * 0.5) * 20;
        p.y = p.baseY + waveOffset;

        // Draw particle
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(0, 212, 255, ${p.opacity})`;
        ctx.fill();

        // Draw connections to nearby particles
        for (let j = i + 1; j < particles.length; j++) {
          const p2 = particles[j];
          const dx = p.x - p2.x;
          const dy = p.y - p2.y;
          const dist = Math.sqrt(dx * dx + dy * dy);

          if (dist < 60) {
            ctx.beginPath();
            ctx.moveTo(p.x, p.y);
            ctx.lineTo(p2.x, p2.y);
            ctx.strokeStyle = `rgba(0, 212, 255, ${0.1 * (1 - dist / 60)})`;
            ctx.lineWidth = 0.5;
            ctx.stroke();
          }
        }
      });

      animationId = requestAnimationFrame(animate);
    };

    resize();
    animate();

    window.addEventListener('resize', resize);
    return () => {
      window.removeEventListener('resize', resize);
      cancelAnimationFrame(animationId);
    };
  }, []);

  return (
    <canvas
      ref={canvasRef}
      className="fixed inset-0 pointer-events-none z-0"
      style={{ opacity: 0.6 }}
    />
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
        backgroundColor: 'rgba(15, 15, 20, 0.7)',
        borderColor: 'rgba(0, 212, 255, 0.15)',
        boxShadow: '0 8px 32px rgba(0, 0, 0, 0.4), inset 0 1px 0 rgba(255,255,255,0.03)',
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

// Icon Components - Clean SVG icons
const WaveformIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
    <path d="M2 12h2l2-7 3 14 3-10 2 6 2-3h6" style={{ stroke: 'var(--deep-black)' }} />
  </svg>
);

const TimeSignatureIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={className} viewBox="0 0 24 24" fill="none" stroke="var(--electric-blue)" strokeWidth="2" strokeLinecap="round">
    <path d="M12 3v18M8 7h8M8 17h8" />
  </svg>
);

const PrecisionIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={className} viewBox="0 0 24 24" fill="none" stroke="var(--electric-blue)" strokeWidth="2" strokeLinecap="round">
    <circle cx="12" cy="12" r="10" />
    <circle cx="12" cy="12" r="6" />
    <circle cx="12" cy="12" r="2" fill="var(--electric-blue)" />
  </svg>
);

const PatternIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={className} viewBox="0 0 24 24" fill="none" stroke="var(--electric-blue)" strokeWidth="2" strokeLinecap="round">
    <rect x="3" y="8" width="4" height="8" rx="1" fill="var(--electric-blue)" />
    <rect x="10" y="11" width="4" height="5" rx="1" />
    <rect x="17" y="6" width="4" height="10" rx="1" fill="var(--electric-blue)" />
  </svg>
);

const TapIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={className} viewBox="0 0 24 24" fill="none" stroke="var(--electric-blue)" strokeWidth="2" strokeLinecap="round">
    <path d="M12 2v4M12 18v4M4 12H2M22 12h-2M6.34 6.34L4.93 4.93M19.07 4.93l-1.41 1.41M6.34 17.66l-1.41 1.41M19.07 19.07l-1.41-1.41" />
    <circle cx="12" cy="12" r="4" fill="var(--electric-blue)" />
  </svg>
);

const HapticIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={className} viewBox="0 0 24 24" fill="none" stroke="var(--electric-blue)" strokeWidth="2" strokeLinecap="round">
    <path d="M5.5 8.5a7 7 0 0 1 13 0" />
    <path d="M8.5 11.5a3 3 0 0 1 7 0" />
    <circle cx="12" cy="16" r="2" fill="var(--electric-blue)" />
  </svg>
);

const BPMIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={className} viewBox="0 0 24 24" fill="none" stroke="var(--electric-blue)" strokeWidth="2" strokeLinecap="round">
    <path d="M12 2L12 22" />
    <path d="M17 7L12 2L7 7" />
    <path d="M7 17L12 22L17 17" />
    <path d="M4 12H8" />
    <path d="M16 12H20" />
  </svg>
);

// Tuner Visual Component - Animated gauge-style tuner
const TunerVisual: FC = () => {
  const [needleAngle, setNeedleAngle] = useState(0);
  const [isInTune, setIsInTune] = useState(false);
  const [currentNote, setCurrentNote] = useState('A');
  const notes = ['E', 'A', 'D', 'G', 'B', 'E'];

  useEffect(() => {
    const interval = setInterval(() => {
      // Simulate tuning - needle oscillates then settles
      const randomOffset = (Math.random() - 0.5) * 30;
      const settling = Math.random() > 0.7;

      if (settling) {
        setNeedleAngle(prev => prev * 0.5);
        setIsInTune(Math.abs(needleAngle) < 5);
      } else {
        setNeedleAngle(randomOffset);
        setIsInTune(false);
      }

      // Change note occasionally
      if (Math.random() > 0.9) {
        setCurrentNote(notes[Math.floor(Math.random() * notes.length)]);
      }
    }, 800);

    return () => clearInterval(interval);
  }, [needleAngle]);

  return (
    <div className="relative w-[140px] h-[140px]">
      {/* Gauge background */}
      <svg viewBox="0 0 100 100" className="w-full h-full">
        {/* Outer ring */}
        <circle
          cx="50"
          cy="50"
          r="45"
          fill="none"
          stroke="rgba(0, 212, 255, 0.1)"
          strokeWidth="2"
        />

        {/* Gauge arc */}
        <path
          d="M 15 50 A 35 35 0 0 1 85 50"
          fill="none"
          stroke="rgba(0, 212, 255, 0.2)"
          strokeWidth="4"
          strokeLinecap="round"
        />

        {/* Center indicator (green when in tune) */}
        <line
          x1="50"
          y1="15"
          x2="50"
          y2="25"
          stroke={isInTune ? '#00FF88' : 'var(--electric-blue)'}
          strokeWidth="3"
          strokeLinecap="round"
          style={{
            filter: isInTune ? 'drop-shadow(0 0 8px #00FF88)' : 'none',
            transition: 'all 0.2s ease'
          }}
        />

        {/* Left/Right markers */}
        <line x1="20" y1="35" x2="28" y2="40" stroke="rgba(0, 212, 255, 0.4)" strokeWidth="2" strokeLinecap="round" />
        <line x1="80" y1="35" x2="72" y2="40" stroke="rgba(0, 212, 255, 0.4)" strokeWidth="2" strokeLinecap="round" />

        {/* Needle */}
        <g style={{
          transform: `rotate(${needleAngle}deg)`,
          transformOrigin: '50px 50px',
          transition: 'transform 0.3s ease-out'
        }}>
          <line
            x1="50"
            y1="50"
            x2="50"
            y2="22"
            stroke={isInTune ? '#00FF88' : 'var(--electric-blue)'}
            strokeWidth="2"
            strokeLinecap="round"
            style={{
              filter: isInTune ? 'drop-shadow(0 0 6px #00FF88)' : 'drop-shadow(0 0 4px var(--electric-blue))',
              transition: 'stroke 0.2s ease, filter 0.2s ease'
            }}
          />
          <circle
            cx="50"
            cy="50"
            r="4"
            fill={isInTune ? '#00FF88' : 'var(--electric-blue)'}
            style={{ transition: 'fill 0.2s ease' }}
          />
        </g>

        {/* Note display */}
        <text
          x="50"
          y="70"
          textAnchor="middle"
          fill="white"
          fontSize="20"
          fontWeight="bold"
          fontFamily="monospace"
        >
          {currentNote}
        </text>

        {/* Cents display */}
        <text
          x="50"
          y="85"
          textAnchor="middle"
          fill={isInTune ? '#00FF88' : 'var(--secondary-text)'}
          fontSize="10"
          fontFamily="monospace"
          style={{ transition: 'fill 0.2s ease' }}
        >
          {isInTune ? 'IN TUNE' : `${needleAngle > 0 ? '+' : ''}${Math.round(needleAngle)} cents`}
        </text>
      </svg>

      {/* Glow effect when in tune */}
      {isInTune && (
        <div
          className="absolute inset-0 rounded-full pointer-events-none"
          style={{
            background: 'radial-gradient(circle at center, rgba(0, 255, 136, 0.15) 0%, transparent 70%)',
            animation: 'pulse 1s ease-in-out infinite'
          }}
        />
      )}
    </div>
  );
};
