import type { FC } from 'react';

/**
 * Apple Watch device frame showing a real screenshot of the Haptic watchOS app.
 */
export const AppleWatchMockup: FC = () => {
  return (
    <div className="relative">
      {/* Watch frame */}
      <div
        className="relative rounded-[36px] p-2"
        style={{
          background: 'linear-gradient(145deg, #3a3a3a 0%, #1a1a1a 50%, #0a0a0a 100%)',
          boxShadow: '0 10px 30px rgba(0,0,0,0.5), 0 0 40px rgba(0, 212, 255, 0.08)',
          width: '140px',
          height: '170px',
        }}
      >
        {/* Screen */}
        <div
          className="relative w-full h-full rounded-[28px] overflow-hidden"
          style={{ backgroundColor: 'var(--deep-black)' }}
        >
          <img
            src="/watch-metronome.jpg"
            alt="Haptic metronome running on Apple Watch"
            className="absolute inset-0 w-full h-full object-cover object-center z-0"
          />

          {/* Screen reflection */}
          <div
            className="absolute inset-0 pointer-events-none z-10"
            style={{
              background:
                'linear-gradient(135deg, rgba(255,255,255,0.05) 0%, transparent 45%, transparent 100%)',
            }}
          />
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
    </div>
  );
};
