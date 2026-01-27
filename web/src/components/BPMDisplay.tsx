import type { FC } from 'react';

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
  return (
    <div className="relative flex flex-col items-center">
      {/* Hexagonal frame */}
      <div className="relative">
        <svg
          width="180"
          height="180"
          viewBox="0 0 200 200"
          className={`transition-all duration-150 ${isPlaying ? 'neon-glow' : ''}`}
        >
          <polygon
            points="100,10 178,55 178,145 100,190 22,145 22,55"
            fill="none"
            stroke={isPlaying ? 'var(--electric-blue)' : 'var(--dark-gray)'}
            strokeWidth="2"
            className="transition-colors duration-200"
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
            onClick={onTap}
            className="text-6xl font-bold text-white tracking-tight transition-transform active:scale-95"
            style={{ fontVariantNumeric: 'tabular-nums' }}
          >
            {bpm}
          </button>
          <span
            className="text-xs tracking-[0.3em] mt-1"
            style={{ color: 'var(--secondary-text)' }}
          >
            BPM
          </span>

          {/* Precision buttons */}
          <div className="flex gap-6 mt-3">
            <PrecisionButton onClick={onDecrement} label="−" />
            <span
              className="text-[8px] tracking-widest self-center"
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
