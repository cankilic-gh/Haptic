import { useState, useRef, useCallback, useEffect } from 'react';
import { SUBDIVISION_DIVISORS } from '../types';
import type { TimeSignature, SubdivisionType, AccentPreset } from '../types';

interface UseMetronomeOptions {
  initialBpm?: number;
  initialTimeSignature?: TimeSignature;
}

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
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();

    osc.connect(gain);
    gain.connect(ctx.destination);

    if (isSubdivision) {
      osc.frequency.value = 800;
      gain.gain.value = 0.05;
    } else if (isAccent) {
      osc.frequency.value = 1200;
      gain.gain.value = 0.15;
    } else {
      osc.frequency.value = 900;
      gain.gain.value = 0.1;
    }

    osc.start(time);
    gain.gain.exponentialRampToValueAtTime(0.001, time + 0.05);
    osc.stop(time + 0.05);

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

    audioContextRef.current = new AudioContext();
    nextNoteTimeRef.current = audioContextRef.current.currentTime;
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
