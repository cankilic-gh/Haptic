export interface TimeSignature {
  beatsPerBar: number;
  beatUnit: number;
}

export const TIME_SIGNATURES: Record<string, TimeSignature> = {
  '4/4': { beatsPerBar: 4, beatUnit: 4 },
  '3/4': { beatsPerBar: 3, beatUnit: 4 },
  '2/2': { beatsPerBar: 2, beatUnit: 2 },
  '6/8': { beatsPerBar: 6, beatUnit: 8 },
  '5/4': { beatsPerBar: 5, beatUnit: 4 },
  '7/8': { beatsPerBar: 7, beatUnit: 8 },
  '11/8': { beatsPerBar: 11, beatUnit: 8 },
  '13/16': { beatsPerBar: 13, beatUnit: 16 },
  '15/16': { beatsPerBar: 15, beatUnit: 16 },
};

export type SubdivisionType = 'eighth' | 'triplet' | 'sixteenth';

export const SUBDIVISION_DIVISORS: Record<SubdivisionType, number> = {
  eighth: 2,
  triplet: 3,
  sixteenth: 4,
};

export interface MetronomeState {
  bpm: number;
  isPlaying: boolean;
  currentBeat: number;
  currentBar: number;
  timeSignature: TimeSignature;
  accentPattern: boolean[];
  subdivisionEnabled: boolean;
  subdivisionType: SubdivisionType;
}

export type AccentPreset = 'standard' | 'backbeat' | 'allAccent' | 'djent';
