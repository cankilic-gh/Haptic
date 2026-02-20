import type { FC } from 'react';
import type { AccentPreset } from '../types';

interface BeatGridProps {
  accentPattern: boolean[];
  currentBeat: number;
  isPlaying: boolean;
  onToggleAccent: (index: number) => void;
  onApplyPreset: (preset: AccentPreset) => void;
}

export const BeatGrid: FC<BeatGridProps> = ({
  accentPattern,
  currentBeat,
  isPlaying,
  onToggleAccent,
  onApplyPreset,
}) => {
  const presets: { key: AccentPreset; label: string }[] = [
    { key: 'standard', label: 'STANDARD' },
    { key: 'backbeat', label: 'BACKBEAT' },
    { key: 'allAccent', label: 'ALL' },
    { key: 'djent', label: 'DJENT' },
  ];

  return (
    <div className="w-full px-4">
      {/* Section label */}
      <div className="flex items-center gap-3 mb-3">
        <div className="flex-1 h-px" style={{ backgroundColor: 'rgba(0, 212, 255, 0.3)' }} />
        <span
          className="text-[10px] tracking-[0.2em]"
          style={{ color: 'var(--secondary-text)' }}
        >
          PATTERN
        </span>
        <div className="flex-1 h-px" style={{ backgroundColor: 'rgba(0, 212, 255, 0.3)' }} />
      </div>

      {/* Beat cells */}
      <div
        className="grid gap-2"
        role="group"
        aria-label="Beat pattern grid"
        style={{
          gridTemplateColumns: `repeat(${Math.min(accentPattern.length, 8)}, 1fr)`,
        }}
      >
        {accentPattern.map((isAccented, index) => (
          <BeatCell
            key={index}
            index={index}
            isAccented={isAccented}
            isCurrent={isPlaying && currentBeat === index}
            onClick={() => onToggleAccent(index)}
          />
        ))}
      </div>

      {/* Preset buttons */}
      <div className="flex gap-2 mt-3 justify-center">
        {presets.map(({ key, label }) => (
          <button
            key={key}
            onClick={() => onApplyPreset(key)}
            className="px-3 py-1.5 rounded text-[9px] tracking-wider transition-all active:scale-95"
            style={{
              backgroundColor: 'var(--charcoal)',
              color: 'var(--secondary-text)',
            }}
          >
            {label}
          </button>
        ))}
      </div>
    </div>
  );
};

interface BeatCellProps {
  index: number;
  isAccented: boolean;
  isCurrent: boolean;
  onClick: () => void;
}

const BeatCell: FC<BeatCellProps> = ({ index, isAccented, isCurrent, onClick }) => {
  const getBackgroundColor = () => {
    if (isCurrent) {
      return isAccented ? '#FFFFFF' : 'var(--cyan-bright)';
    }
    return 'var(--charcoal)';
  };

  const getBorderColor = () => {
    if (isCurrent) return 'transparent';
    return isAccented ? 'rgba(0, 212, 255, 0.5)' : 'var(--dark-gray)';
  };

  const getTextColor = () => {
    if (isCurrent) return 'var(--deep-black)';
    return isAccented ? 'var(--primary-text)' : 'var(--secondary-text)';
  };

  // Accessibility label
  const ariaLabel = `Beat ${index + 1}${isAccented ? ', accented' : ''}${isCurrent ? ', currently playing' : ''}. ${isAccented ? 'Click to remove accent' : 'Click to add accent'}`;

  return (
    <button
      onClick={onClick}
      aria-label={ariaLabel}
      aria-pressed={isAccented}
      className="relative rounded-lg flex items-center justify-center transition-all active:scale-95"
      style={{
        backgroundColor: getBackgroundColor(),
        border: `1px solid ${getBorderColor()}`,
        height: '48px',
        transform: isCurrent ? 'scale(1.08)' : 'scale(1)',
        boxShadow: isCurrent ? '0 0 12px var(--electric-blue)' : 'none',
      }}
    >
      <span
        className="text-sm font-bold"
        style={{
          color: getTextColor(),
          fontVariantNumeric: 'tabular-nums',
        }}
      >
        {index + 1}
      </span>

      {/* Accent indicator */}
      {isAccented && !isCurrent && (
        <div
          className="absolute top-1.5 w-1.5 h-1.5 rounded-full"
          style={{
            backgroundColor: 'var(--electric-blue)',
            boxShadow: '0 0 6px var(--electric-blue)',
          }}
        />
      )}
    </button>
  );
};
