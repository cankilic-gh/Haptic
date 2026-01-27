import type { FC, ReactNode } from 'react';

interface IPhoneSimulatorProps {
  children: ReactNode;
}

export const IPhoneSimulator: FC<IPhoneSimulatorProps> = ({ children }) => {
  return (
    <div className="flex flex-col items-center">
      {/* Phone frame */}
      <div
        className="relative rounded-[50px] p-3"
        style={{
          background: 'linear-gradient(145deg, #2a2a2a 0%, #1a1a1a 50%, #0a0a0a 100%)',
          boxShadow: `
            0 0 0 1px rgba(255,255,255,0.1),
            0 25px 50px -12px rgba(0,0,0,0.8),
            0 0 60px rgba(0, 212, 255, 0.1)
          `,
        }}
      >
        {/* Screen bezel */}
        <div
          className="relative overflow-hidden rounded-[38px]"
          style={{
            width: '320px',
            height: '692px',
            backgroundColor: '#000',
          }}
        >
          {/* Dynamic Island / Notch */}
          <div className="absolute top-0 left-0 right-0 flex justify-center z-30">
            <div
              className="mt-3 rounded-full flex items-center justify-center"
              style={{
                width: '120px',
                height: '34px',
                backgroundColor: '#000',
                boxShadow: 'inset 0 0 4px rgba(0,0,0,0.8)',
              }}
            >
              {/* Camera */}
              <div
                className="rounded-full mr-8"
                style={{
                  width: '12px',
                  height: '12px',
                  background: 'radial-gradient(circle at 30% 30%, #3a3a4a, #1a1a2a)',
                }}
              />
            </div>
          </div>

          {/* Screen content */}
          <div className="absolute inset-0 pt-14 overflow-hidden">{children}</div>

          {/* Home indicator */}
          <div className="absolute bottom-2 left-0 right-0 flex justify-center z-30">
            <div
              className="rounded-full"
              style={{
                width: '134px',
                height: '5px',
                backgroundColor: 'rgba(255,255,255,0.3)',
              }}
            />
          </div>

          {/* Screen reflection */}
          <div
            className="absolute inset-0 pointer-events-none z-20"
            style={{
              background:
                'linear-gradient(135deg, rgba(255,255,255,0.03) 0%, transparent 50%, transparent 100%)',
            }}
          />
        </div>

        {/* Side buttons - Volume */}
        <div
          className="absolute left-[-3px] top-[120px] rounded-l-sm"
          style={{
            width: '3px',
            height: '30px',
            backgroundColor: '#2a2a2a',
          }}
        />
        <div
          className="absolute left-[-3px] top-[160px] rounded-l-sm"
          style={{
            width: '3px',
            height: '60px',
            backgroundColor: '#2a2a2a',
          }}
        />
        <div
          className="absolute left-[-3px] top-[230px] rounded-l-sm"
          style={{
            width: '3px',
            height: '60px',
            backgroundColor: '#2a2a2a',
          }}
        />

        {/* Side button - Power */}
        <div
          className="absolute right-[-3px] top-[180px] rounded-r-sm"
          style={{
            width: '3px',
            height: '80px',
            backgroundColor: '#2a2a2a',
          }}
        />
      </div>

      {/* Label */}
      <div className="mt-8 text-center">
        <h1
          className="text-2xl font-bold tracking-wider"
          style={{ color: 'var(--electric-blue)' }}
        >
          HAPTIC
        </h1>
        <p className="text-sm mt-2" style={{ color: 'var(--secondary-text)' }}>
          Pro Metronome for Progressive Metal
        </p>
        <p className="text-xs mt-1" style={{ color: 'var(--tertiary-text)' }}>
          High-precision timing with haptic feedback
        </p>
      </div>
    </div>
  );
};
