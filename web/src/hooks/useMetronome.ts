import { useState, useRef, useCallback, useEffect } from 'react';
import { SUBDIVISION_DIVISORS } from '../types';
import type { TimeSignature, SubdivisionType, AccentPreset } from '../types';

interface UseMetronomeOptions {
  initialBpm?: number;
  initialTimeSignature?: TimeSignature;
}

// Create click sound AudioBuffer (impulse-based for crisp attack)
const createClickBuffer = (
  ctx: AudioContext,
  frequency: number,
  duration: number,
  volume: number
): AudioBuffer => {
  const sampleRate = ctx.sampleRate;
  const length = Math.floor(sampleRate * duration);
  const buffer = ctx.createBuffer(1, length, sampleRate);
  const data = buffer.getChannelData(0);

  // Impulse with exponential decay for sharp click
  for (let i = 0; i < length; i++) {
    const t = i / sampleRate;
    // Sharp attack with fast exponential decay
    const envelope = Math.exp(-t * 80);
    // Mix of fundamental and harmonics for click character
    const fundamental = Math.sin(2 * Math.PI * frequency * t);
    const harmonic2 = Math.sin(2 * Math.PI * frequency * 2 * t) * 0.5;
    const harmonic3 = Math.sin(2 * Math.PI * frequency * 3 * t) * 0.25;
    // Add noise burst for attack transient
    const noise = (Math.random() * 2 - 1) * Math.exp(-t * 200);

    data[i] = (fundamental + harmonic2 + harmonic3 + noise * 0.3) * envelope * volume;
  }

  return buffer;
};

export const useMetronome = (options: UseMetronomeOptions = {}) => {
  const {
    initialBpm = 120,
    initialTimeSignature = { beatsPerBar: 4, beatUnit: 4 },
  } = options;

  const [bpm, setBpmState] = useState(initialBpm);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentBeat, setCurrentBeat] = useState(0);
  const [currentBar, setCurrentBar] = useState(0);
  const [timeSignature, setTimeSignatureState] = useState<TimeSignature>(initialTimeSignature);
  const [accentPattern, setAccentPattern] = useState<boolean[]>(() =>
    createDefaultPattern(initialTimeSignature.beatsPerBar)
  );
  const [subdivisionEnabled, setSubdivisionEnabled] = useState(false);
  const [subdivisionType, setSubdivisionType] = useState<SubdivisionType>('eighth');

  const audioContextRef = useRef<AudioContext | null>(null);
  const schedulerRef = useRef<number | null>(null);
  const nextNoteTimeRef = useRef(0);
  const currentBeatRef = useRef(0);
  const currentSubdivisionRef = useRef(0);

  // Pre-computed click buffers for performance
  const accentBufferRef = useRef<AudioBuffer | null>(null);
  const normalBufferRef = useRef<AudioBuffer | null>(null);
  const subdivisionBufferRef = useRef<AudioBuffer | null>(null);

  // Lookahead scheduling parameters
  const scheduleAheadTime = 0.1; // seconds
  const lookahead = 25; // ms

  const setBpm = useCallback((newBpm: number | ((prev: number) => number)) => {
    setBpmState((prev) => {
      const value = typeof newBpm === 'function' ? newBpm(prev) : newBpm;
      return Math.max(20, Math.min(300, value));
    });
  }, []);

  const setTimeSignature = useCallback((ts: TimeSignature) => {
    setTimeSignatureState(ts);
    setAccentPattern(createDefaultPattern(ts.beatsPerBar));
    setCurrentBeat(0);
    setCurrentBar(0);
  }, []);

  const toggleAccent = useCallback((index: number) => {
    setAccentPattern((prev) => {
      const newPattern = [...prev];
      newPattern[index] = !newPattern[index];
      // Ensure at least one accent
      if (!newPattern.includes(true)) {
        newPattern[0] = true;
      }
      return newPattern;
    });
  }, []);

  const applyPreset = useCallback((preset: AccentPreset) => {
    const beats = timeSignature.beatsPerBar;
    let pattern: boolean[];

    switch (preset) {
      case 'standard':
        pattern = [true, ...Array(beats - 1).fill(false)];
        break;
      case 'backbeat':
        pattern = Array.from({ length: beats }, (_, i) => (i + 1) % 2 === 0);
        break;
      case 'allAccent':
        pattern = Array(beats).fill(true);
        break;
      case 'djent':
        if (beats === 4) {
          pattern = [true, false, false, true];
        } else if (beats === 7) {
          pattern = [true, false, false, true, false, true, false];
        } else {
          pattern = [true, ...Array(beats - 1).fill(false)];
          if (beats > 3) pattern[Math.floor(beats / 2)] = true;
        }
        break;
      default:
        pattern = createDefaultPattern(beats);
    }

    setAccentPattern(pattern);
  }, [timeSignature.beatsPerBar]);

  const playClick = useCallback((time: number, isAccent: boolean, isSubdivision: boolean) => {
    if (!audioContextRef.current) return;

    const ctx = audioContextRef.current;

    // Select appropriate pre-computed buffer
    let buffer: AudioBuffer | null = null;
    if (isSubdivision) {
      buffer = subdivisionBufferRef.current;
    } else if (isAccent) {
      buffer = accentBufferRef.current;
    } else {
      buffer = normalBufferRef.current;
    }

    if (!buffer) return;

    // Create buffer source for playback
    const source = ctx.createBufferSource();
    source.buffer = buffer;
    source.connect(ctx.destination);
    source.start(time);

    // Trigger haptic feedback on supported devices
    if ('vibrate' in navigator && !isSubdivision) {
      navigator.vibrate(isAccent ? 30 : 15);
    }
  }, []);

  const scheduler = useCallback(() => {
    if (!audioContextRef.current) return;

    const ctx = audioContextRef.current;
    const beatsPerBar = timeSignature.beatsPerBar;
    const ticksPerBeat = subdivisionEnabled ? SUBDIVISION_DIVISORS[subdivisionType] : 1;
    const secondsPerBeat = 60.0 / bpm;
    const secondsPerTick = secondsPerBeat / ticksPerBeat;

    while (nextNoteTimeRef.current < ctx.currentTime + scheduleAheadTime) {
      const beatIndex = currentBeatRef.current;
      const subdivisionIndex = currentSubdivisionRef.current;
      const isOnBeat = subdivisionIndex === 0;
      const isAccent = isOnBeat && accentPattern[beatIndex];

      if (isOnBeat) {
        playClick(nextNoteTimeRef.current, isAccent, false);
        setCurrentBeat(beatIndex);
      } else if (subdivisionEnabled) {
        playClick(nextNoteTimeRef.current, false, true);
      }

      // Advance
      currentSubdivisionRef.current++;
      if (currentSubdivisionRef.current >= ticksPerBeat) {
        currentSubdivisionRef.current = 0;
        currentBeatRef.current++;
        if (currentBeatRef.current >= beatsPerBar) {
          currentBeatRef.current = 0;
          setCurrentBar((prev) => prev + 1);
        }
      }

      nextNoteTimeRef.current += secondsPerTick;
    }

    schedulerRef.current = window.setTimeout(scheduler, lookahead);
  }, [bpm, timeSignature, accentPattern, subdivisionEnabled, subdivisionType, playClick]);

  const start = useCallback(() => {
    if (isPlaying) return;

    const ctx = new AudioContext();
    audioContextRef.current = ctx;

    // Pre-compute click buffers for crisp, click-like sounds
    accentBufferRef.current = createClickBuffer(ctx, 1200, 0.03, 0.4);
    normalBufferRef.current = createClickBuffer(ctx, 900, 0.025, 0.25);
    subdivisionBufferRef.current = createClickBuffer(ctx, 800, 0.015, 0.1);

    nextNoteTimeRef.current = ctx.currentTime;
    currentBeatRef.current = 0;
    currentSubdivisionRef.current = 0;
    setCurrentBeat(0);
    setCurrentBar(0);
    setIsPlaying(true);
  }, [isPlaying]);

  const stop = useCallback(() => {
    if (!isPlaying) return;

    if (schedulerRef.current) {
      clearTimeout(schedulerRef.current);
      schedulerRef.current = null;
    }

    if (audioContextRef.current) {
      audioContextRef.current.close();
      audioContextRef.current = null;
    }

    // Clear buffer refs
    accentBufferRef.current = null;
    normalBufferRef.current = null;
    subdivisionBufferRef.current = null;

    setIsPlaying(false);
    setCurrentBeat(0);
  }, [isPlaying]);

  const toggle = useCallback(() => {
    if (isPlaying) {
      stop();
    } else {
      start();
    }
  }, [isPlaying, start, stop]);

  // Start scheduler when playing
  useEffect(() => {
    if (isPlaying && audioContextRef.current) {
      scheduler();
    }
    return () => {
      if (schedulerRef.current) {
        clearTimeout(schedulerRef.current);
      }
    };
  }, [isPlaying, scheduler]);

  // Handle visibility change - suspend AudioContext when page is hidden
  useEffect(() => {
    const handleVisibilityChange = () => {
      const ctx = audioContextRef.current;
      if (!ctx) return;

      if (document.hidden) {
        // Page going to background - suspend AudioContext
        ctx.suspend();
      } else {
        // Page coming back to foreground - resume AudioContext
        ctx.resume();
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);

    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    };
  }, []);

  // Tap tempo
  const tapTimesRef = useRef<number[]>([]);
  const tap = useCallback(() => {
    const now = Date.now();
    tapTimesRef.current = tapTimesRef.current.filter((t) => now - t < 2000);
    tapTimesRef.current.push(now);

    if (tapTimesRef.current.length >= 2) {
      const intervals: number[] = [];
      for (let i = 1; i < tapTimesRef.current.length; i++) {
        intervals.push(tapTimesRef.current[i] - tapTimesRef.current[i - 1]);
      }
      const avgInterval = intervals.reduce((a, b) => a + b, 0) / intervals.length;
      const newBpm = Math.round(60000 / avgInterval);
      setBpm(newBpm);
    }
  }, [setBpm]);

  return {
    bpm,
    setBpm,
    isPlaying,
    currentBeat,
    currentBar,
    timeSignature,
    setTimeSignature,
    accentPattern,
    toggleAccent,
    applyPreset,
    subdivisionEnabled,
    setSubdivisionEnabled,
    subdivisionType,
    setSubdivisionType,
    start,
    stop,
    toggle,
    tap,
  };
};

function createDefaultPattern(beats: number): boolean[] {
  return [true, ...Array(beats - 1).fill(false)];
}
