import { useRef, useEffect } from 'react';
import type { FC } from 'react';
import gsap from 'gsap';

interface BPMDisplayProps {
  bpm: number;
  isPlaying: boolean;
  onTap: () => void;
  onIncrement: () => void;
  onDecrement: () => void;
}

export const BPMDisplay: FC<BPMDisplayProps> = ({
  bpm,
  isPlaying,
  onTap,
  onIncrement,
  onDecrement,
}) => {
  const bpmRef = useRef<HTMLButtonElement>(null);
  const hexRef = useRef<SVGPolygonElement>(null);
  const prevBpmRef = useRef(bpm);

  // Animate BPM number change
  useEffect(() => {
    if (!bpmRef.current || prevBpmRef.current === bpm) return;

    const direction = bpm > prevBpmRef.current ? -1 : 1;
    gsap.fromTo(bpmRef.current, {
      y: direction * 8,
      opacity: 0.5,
    }, {
      y: 0,
      opacity: 1,
      duration: 0.2,
      ease: 'power2.out',
    });

    prevBpmRef.current = bpm;
  }, [bpm]);

  // Hex frame pulse when playing
  useEffect(() => {
    if (!hexRef.current) return;

    if (isPlaying) {
      gsap.to(hexRef.current, {
        strokeWidth: 3,
        duration: 0.3,
        ease: 'power2.out',
      });
    } else {
      gsap.to(hexRef.current, {
        strokeWidth: 2,
        duration: 0.3,
        ease: 'power2.inOut',
      });
    }
  }, [isPlaying]);

  return (
    <div className="relative flex flex-col items-center">
      {/* Hexagonal frame - compact size */}
      <div className="relative">
        <svg
          width="150"
          height="150"
          viewBox="0 0 200 200"
          className={isPlaying ? 'neon-glow' : ''}
        >
          <polygon
            ref={hexRef}
            points="100,10 178,55 178,145 100,190 22,145 22,55"
            fill="none"
            stroke={isPlaying ? 'var(--electric-blue)' : 'var(--dark-gray)'}
            strokeWidth="2"
          />
          {isPlaying && (
            <polygon
              points="100,10 178,55 178,145 100,190 22,145 22,55"
              fill="none"
              stroke="var(--electric-blue)"
              strokeWidth="4"
              opacity="0.3"
              filter="blur(8px)"
            />
          )}
        </svg>

        {/* BPM value */}
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <button
            ref={bpmRef}
            onClick={onTap}
            className="text-5xl font-bold text-white tracking-tight active:scale-95"
            style={{ fontVariantNumeric: 'tabular-nums', willChange: 'transform' }}
          >
            {bpm}
          </button>
          <span
            className="text-[10px] tracking-[0.3em]"
            style={{ color: 'var(--secondary-text)' }}
          >
            BPM
          </span>

          {/* Precision buttons */}
          <div className="flex gap-4 mt-2">
            <PrecisionButton onClick={onDecrement} label="−" />
            <span
              className="text-[7px] tracking-widest self-center"
              style={{ color: 'var(--tertiary-text)' }}
            >
              TAP
            </span>
            <PrecisionButton onClick={onIncrement} label="+" />
          </div>
        </div>
      </div>
    </div>
  );
};

const PrecisionButton: FC<{ onClick: () => void; label: string }> = ({ onClick, label }) => (
  <button
    onClick={onClick}
    className="w-8 h-8 rounded-md flex items-center justify-center text-lg font-medium transition-all active:scale-90"
    style={{
      backgroundColor: 'var(--charcoal)',
      color: 'var(--electric-blue)',
      border: '1px solid rgba(0, 212, 255, 0.3)',
    }}
  >
    {label}
  </button>
);
