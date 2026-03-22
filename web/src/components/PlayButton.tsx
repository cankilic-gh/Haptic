import { useRef, useEffect } from 'react';
import type { FC } from 'react';
import gsap from 'gsap';

interface PlayButtonProps {
  isPlaying: boolean;
  onClick: () => void;
}

export const PlayButton: FC<PlayButtonProps> = ({ isPlaying, onClick }) => {
  const buttonRef = useRef<HTMLButtonElement>(null);
  const ringRef = useRef<HTMLDivElement>(null);
  const prevPlayingRef = useRef(false);

  // Animate play/stop state transitions
  useEffect(() => {
    if (!buttonRef.current || !ringRef.current) return;

    if (isPlaying && !prevPlayingRef.current) {
      // Play pressed — punch + ring expand
      const tl = gsap.timeline();
      tl.fromTo(buttonRef.current, {
        scale: 0.9,
      }, {
        scale: 1,
        duration: 0.4,
        ease: 'back.out(1.7)',
      });
      tl.fromTo(ringRef.current, {
        scale: 0.95,
        opacity: 0.5,
      }, {
        scale: 1,
        opacity: 1,
        duration: 0.5,
        ease: 'power2.out',
      }, '<');
    } else if (!isPlaying && prevPlayingRef.current) {
      // Stop pressed — settle
      gsap.to(buttonRef.current, {
        scale: 1,
        duration: 0.3,
        ease: 'power2.out',
      });
      gsap.to(ringRef.current, {
        scale: 1,
        opacity: 0.5,
        duration: 0.3,
        ease: 'power2.inOut',
      });
    }

    prevPlayingRef.current = isPlaying;
  }, [isPlaying]);

  return (
    <button
      ref={buttonRef}
      onClick={onClick}
      aria-label={isPlaying ? 'Stop metronome' : 'Start metronome'}
      aria-pressed={isPlaying}
      className="relative w-[70px] h-[70px] rounded-full flex items-center justify-center active:scale-95"
      style={{
        backgroundColor: isPlaying ? 'var(--electric-blue)' : 'var(--charcoal)',
        border: `1px solid ${isPlaying ? 'transparent' : 'rgba(0, 212, 255, 0.5)'}`,
        boxShadow: isPlaying ? '0 0 20px var(--electric-blue), 0 0 40px rgba(0, 212, 255, 0.3)' : 'none',
        willChange: 'transform',
      }}
    >
      {/* Outer ring */}
      <div
        ref={ringRef}
        className="absolute inset-[-10px] rounded-full"
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
