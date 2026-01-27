import { useState } from 'react';
import type { FC } from 'react';
import { useMetronome } from '../hooks/useMetronome';
import { TIME_SIGNATURES } from '../types';
import type { TimeSignature } from '../types';
import { BPMDisplay } from './BPMDisplay';
import { ArcSlider } from './ArcSlider';
import { BeatGrid } from './BeatGrid';
import { PlayButton } from './PlayButton';
import { ControlCard } from './ControlCard';

export const MetronomeApp: FC = () => {
  const metronome = useMetronome();
  const [showTimeSignaturePicker, setShowTimeSignaturePicker] = useState(false);

  const formatTimeSignature = (ts: TimeSignature) => `${ts.beatsPerBar}/${ts.beatUnit}`;

  return (
    <div
      className="relative w-full h-full flex flex-col overflow-hidden"
      style={{ backgroundColor: 'var(--deep-black)' }}
    >
      {/* Scan lines overlay */}
      <div className="absolute inset-0 scan-lines pointer-events-none z-10" />

      {/* Header */}
      <div className="flex items-center justify-between px-5 py-2 z-20">
        <div className="flex items-center gap-1.5">
          <div
            className="w-2 h-2 rounded-full"
            style={{
              backgroundColor: 'var(--electric-blue)',
              boxShadow: '0 0 6px var(--electric-blue)',
            }}
          />
          <span
            className="text-[10px] tracking-wider"
            style={{ color: 'var(--secondary-text)' }}
          >
            WEB VERSION
          </span>
        </div>

        <span
          className="text-xs font-bold tracking-[0.3em]"
          style={{ color: 'var(--electric-blue)' }}
        >
          HAPTIC
        </span>

        <div className="w-16" />
      </div>

      {/* Content */}
      <div className="flex-1 flex flex-col items-center justify-between py-2 z-20">
        {/* BPM Display */}
        <BPMDisplay
          bpm={metronome.bpm}
          isPlaying={metronome.isPlaying}
          onTap={metronome.tap}
          onIncrement={() => metronome.setBpm((b) => b + 1)}
          onDecrement={() => metronome.setBpm((b) => b - 1)}
        />

        {/* Arc Slider */}
        <div className="w-full px-6">
          <ArcSlider value={metronome.bpm} onChange={metronome.setBpm} />
        </div>

        {/* Beat Grid */}
        <BeatGrid
          accentPattern={metronome.accentPattern}
          currentBeat={metronome.currentBeat}
          isPlaying={metronome.isPlaying}
          onToggleAccent={metronome.toggleAccent}
          onApplyPreset={metronome.applyPreset}
        />

        {/* Controls Row */}
        <div className="w-full px-5 flex gap-3">
          <ControlCard
            title="TIME SIG"
            value={formatTimeSignature(metronome.timeSignature)}
            isActive={true}
            onClick={() => setShowTimeSignaturePicker(true)}
          />
          <ControlCard
            title="SUBDIVIDE"
            value={metronome.subdivisionEnabled ? 'ON' : 'OFF'}
            isActive={metronome.subdivisionEnabled}
            onClick={() => metronome.setSubdivisionEnabled(!metronome.subdivisionEnabled)}
          />
        </div>

        {/* Play Button */}
        <div className="pb-4">
          <PlayButton isPlaying={metronome.isPlaying} onClick={metronome.toggle} />
        </div>
      </div>

      {/* Time Signature Picker Modal */}
      {showTimeSignaturePicker && (
        <TimeSignaturePicker
          current={metronome.timeSignature}
          onSelect={(ts) => {
            metronome.setTimeSignature(ts);
            setShowTimeSignaturePicker(false);
          }}
          onClose={() => setShowTimeSignaturePicker(false)}
        />
      )}
    </div>
  );
};

interface TimeSignaturePickerProps {
  current: TimeSignature;
  onSelect: (ts: TimeSignature) => void;
  onClose: () => void;
}

const TimeSignaturePicker: FC<TimeSignaturePickerProps> = ({ current, onSelect, onClose }) => {
  const standard = ['4/4', '3/4', '2/2', '6/8'];
  const prog = ['5/4', '7/8', '11/8', '13/16', '15/16'];

  const formatCurrent = `${current.beatsPerBar}/${current.beatUnit}`;

  return (
    <div
      className="absolute inset-0 z-50 flex flex-col"
      style={{ backgroundColor: 'rgba(10, 10, 15, 0.95)' }}
    >
      <div className="flex items-center justify-between px-5 py-4 border-b border-white/10">
        <span className="text-sm font-medium text-white">Time Signature</span>
        <button
          onClick={onClose}
          className="text-sm"
          style={{ color: 'var(--electric-blue)' }}
        >
          Done
        </button>
      </div>

      <div className="flex-1 overflow-auto p-5">
        <Section title="STANDARD">
          <div className="grid grid-cols-3 gap-2">
            {standard.map((key) => {
              const ts = TIME_SIGNATURES[key];
              const isSelected = key === formatCurrent;
              return (
                <button
                  key={key}
                  onClick={() => onSelect(ts)}
                  className="py-4 rounded-xl text-lg font-bold transition-all"
                  style={{
                    backgroundColor: isSelected ? 'var(--electric-blue)' : 'var(--charcoal)',
                    color: isSelected ? 'var(--deep-black)' : 'white',
                    border: `1px solid ${isSelected ? 'transparent' : 'var(--dark-gray)'}`,
                  }}
                >
                  {key}
                </button>
              );
            })}
          </div>
        </Section>

        <Section title="PROG / COMPLEX">
          <div className="grid grid-cols-3 gap-2">
            {prog.map((key) => {
              const ts = TIME_SIGNATURES[key];
              const isSelected = key === formatCurrent;
              return (
                <button
                  key={key}
                  onClick={() => onSelect(ts)}
                  className="py-4 rounded-xl text-lg font-bold transition-all"
                  style={{
                    backgroundColor: isSelected ? 'var(--electric-blue)' : 'var(--charcoal)',
                    color: isSelected ? 'var(--deep-black)' : 'white',
                    border: `1px solid ${isSelected ? 'transparent' : 'var(--dark-gray)'}`,
                  }}
                >
                  {key}
                </button>
              );
            })}
          </div>
        </Section>
      </div>
    </div>
  );
};

const Section: FC<{ title: string; children: React.ReactNode }> = ({ title, children }) => (
  <div className="mb-6">
    <div className="flex items-center gap-3 mb-3">
      <div className="flex-1 h-px" style={{ backgroundColor: 'rgba(0, 212, 255, 0.3)' }} />
      <span className="text-[10px] tracking-[0.2em]" style={{ color: 'var(--secondary-text)' }}>
        {title}
      </span>
      <div className="flex-1 h-px" style={{ backgroundColor: 'rgba(0, 212, 255, 0.3)' }} />
    </div>
    {children}
  </div>
);
