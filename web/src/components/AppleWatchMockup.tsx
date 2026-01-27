import { useState, useEffect } from 'react';
import type { FC } from 'react';

export const AppleWatchMockup: FC = () => {
  const [currentBeat, setCurrentBeat] = useState(0);
  const [isVibrating, setIsVibrating] = useState(false);

  // Simulate beat animation
  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentBeat((prev) => (prev + 1) % 4);
      setIsVibrating(true);
      setTimeout(() => setIsVibrating(false), 100);
    }, 500); // 120 BPM

    return () => clearInterval(interval);
  }, []);

  return (
    <div className="relative">
      {/* Watch frame */}
      <div
        className="relative rounded-[36px] p-2"
        style={{
          background: 'linear-gradient(145deg, #3a3a3a 0%, #1a1a1a 50%, #0a0a0a 100%)',
          boxShadow: '0 10px 30px rgba(0,0,0,0.5)',
          width: '140px',
          height: '170px',
        }}
      >
        {/* Screen */}
        <div
          className="relative w-full h-full rounded-[28px] overflow-hidden"
          style={{ backgroundColor: 'var(--deep-black)' }}
        >
          {/* Watch content */}
          <div className="absolute inset-0 flex flex-col items-center justify-center p-3">
            {/* BPM */}
            <div
              className="text-2xl font-bold mb-1"
              style={{ color: 'var(--electric-blue)' }}
            >
              120
            </div>
            <div
              className="text-[8px] tracking-widest mb-3"
              style={{ color: 'var(--secondary-text)' }}
            >
              BPM
            </div>

            {/* Beat indicators */}
            <div className="flex gap-1.5 mb-3">
              {[0, 1, 2, 3].map((beat) => (
                <div
                  key={beat}
                  className="w-4 h-4 rounded-full transition-all duration-100"
                  style={{
                    backgroundColor:
                      currentBeat === beat
                        ? beat === 0
                          ? '#FFFFFF'
                          : 'var(--cyan-bright)'
                        : 'var(--charcoal)',
                    boxShadow:
                      currentBeat === beat
                        ? '0 0 10px var(--electric-blue)'
                        : 'none',
                    transform: currentBeat === beat ? 'scale(1.2)' : 'scale(1)',
                  }}
                />
              ))}
            </div>

            {/* Haptic indicator */}
            <div
              className="flex items-center gap-1 transition-all duration-100"
              style={{
                transform: isVibrating ? 'translateX(-2px)' : 'translateX(0)',
              }}
            >
              <svg
                width="12"
                height="12"
                viewBox="0 0 24 24"
                fill={isVibrating ? 'var(--electric-blue)' : 'var(--tertiary-text)'}
                className="transition-colors duration-100"
              >
                <path d="M0 15a1 1 0 001 1h2a1 1 0 001-1V9a1 1 0 00-1-1H1a1 1 0 00-1 1v6zm20-6v6a1 1 0 001 1h2a1 1 0 001-1V9a1 1 0 00-1-1h-2a1 1 0 00-1 1zM7 18a1 1 0 001 1h2a1 1 0 001-1V6a1 1 0 00-1-1H8a1 1 0 00-1 1v12zm6 3a1 1 0 001 1h2a1 1 0 001-1V3a1 1 0 00-1-1h-2a1 1 0 00-1 1v18z" />
              </svg>
              <span
                className="text-[8px] tracking-wider transition-colors duration-100"
                style={{ color: isVibrating ? 'var(--electric-blue)' : 'var(--tertiary-text)' }}
              >
                HAPTIC
              </span>
            </div>
          </div>

          {/* Pulse effect on vibration */}
          {isVibrating && (
            <div
              className="absolute inset-0 rounded-[28px]"
              style={{
                background: 'radial-gradient(circle at center, var(--electric-blue) 0%, transparent 70%)',
                opacity: 0.15,
              }}
            />
          )}
        </div>

        {/* Digital Crown */}
        <div
          className="absolute right-[-4px] top-[40px] rounded-sm"
          style={{
            width: '4px',
            height: '24px',
            background: 'linear-gradient(180deg, #4a4a4a 0%, #2a2a2a 100%)',
          }}
        />

        {/* Side button */}
        <div
          className="absolute right-[-4px] top-[75px] rounded-sm"
          style={{
            width: '4px',
            height: '16px',
            background: 'linear-gradient(180deg, #3a3a3a 0%, #1a1a1a 100%)',
          }}
        />
      </div>

      {/* Vibration waves */}
      {isVibrating && (
        <>
          <div
            className="absolute left-[-20px] top-1/2 -translate-y-1/2"
            style={{
              width: '16px',
              height: '40px',
              opacity: 0.5,
            }}
          >
            {[0, 1, 2].map((i) => (
              <div
                key={i}
                className="absolute rounded-full"
                style={{
                  left: `${i * 6}px`,
                  top: '50%',
                  transform: 'translateY(-50%)',
                  width: '2px',
                  height: `${20 - i * 5}px`,
                  backgroundColor: 'var(--electric-blue)',
                  opacity: 1 - i * 0.3,
                }}
              />
            ))}
          </div>
          <div
            className="absolute right-[-20px] top-1/2 -translate-y-1/2"
            style={{
              width: '16px',
              height: '40px',
              opacity: 0.5,
            }}
          >
            {[0, 1, 2].map((i) => (
              <div
                key={i}
                className="absolute rounded-full"
                style={{
                  right: `${i * 6}px`,
                  top: '50%',
                  transform: 'translateY(-50%)',
                  width: '2px',
                  height: `${20 - i * 5}px`,
                  backgroundColor: 'var(--electric-blue)',
                  opacity: 1 - i * 0.3,
                }}
              />
            ))}
          </div>
        </>
      )}
    </div>
  );
};
