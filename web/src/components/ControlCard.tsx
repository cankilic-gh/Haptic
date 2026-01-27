import type { FC, ReactNode } from 'react';

interface ControlCardProps {
  title: string;
  value: string;
  isActive?: boolean;
  onClick?: () => void;
  children?: ReactNode;
}

export const ControlCard: FC<ControlCardProps> = ({
  title,
  value,
  isActive = false,
  onClick,
}) => {
  return (
    <button
      onClick={onClick}
      className="flex-1 flex flex-col items-center py-3 rounded-xl transition-all active:scale-95"
      style={{
        backgroundColor: 'var(--charcoal)',
        border: `1px solid ${isActive ? 'rgba(0, 212, 255, 0.3)' : 'var(--dark-gray)'}`,
      }}
    >
      <span
        className="text-xl font-bold"
        style={{
          color: isActive ? 'var(--electric-blue)' : 'var(--tertiary-text)',
        }}
      >
        {value}
      </span>
      <span
        className="text-[9px] tracking-[0.15em] mt-1"
        style={{ color: 'var(--secondary-text)' }}
      >
        {title}
      </span>
    </button>
  );
};
