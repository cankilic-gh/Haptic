import type { FC } from 'react';

interface PlayButtonProps {
  isPlaying: boolean;
  onClick: () => void;
}

export const PlayButton: FC<PlayButtonProps> = ({ isPlaying, onClick }) => {
  return (
    <button
      onClick={onClick}
      aria-label={isPlaying ? 'Stop metronome' : 'Start metronome'}
      aria-pressed={isPlaying}
      className="relative w-[70px] h-[70px] rounded-full flex items-center justify-center transition-all active:scale-95"
      style={{
        backgroundColor: isPlaying ? 'var(--electric-blue)' : 'var(--charcoal)',
        border: `1px solid ${isPlaying ? 'transparent' : 'rgba(0, 212, 255, 0.5)'}`,
        boxShadow: isPlaying ? '0 0 20px var(--electric-blue), 0 0 40px rgba(0, 212, 255, 0.3)' : 'none',
      }}
    >
      {/* Outer ring */}
      <div
        className="absolute inset-[-10px] rounded-full transition-all"
        style={{
          border: `3px solid ${isPlaying ? 'var(--electric-blue)' : 'var(--dark-gray)'}`,
          boxShadow: isPlaying ? '0 0 15px var(--electric-blue)' : 'none',
        }}
      />

      {/* Icon */}
      {isPlaying ? (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="var(--deep-black)">
          <rect x="6" y="6" width="12" height="12" rx="1" />
        </svg>
      ) : (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="var(--electric-blue)">
          <path d="M8 5v14l11-7z" />
        </svg>
      )}
    </button>
  );
};
