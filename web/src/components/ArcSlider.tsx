import { useRef, useCallback } from 'react';
import type { FC } from 'react';

interface ArcSliderProps {
  value: number;
  onChange: (value: number) => void;
  min?: number;
  max?: number;
}

export const ArcSlider: FC<ArcSliderProps> = ({
  value,
  onChange,
  min = 40,
  max = 300,
}) => {
  const svgRef = useRef<SVGSVGElement>(null);

  const progress = (value - min) / (max - min);

  // Temperature color: smooth cyan gradient based on progress
  const getTemperatureColor = (t: number) => {
    const hue = 190; // Cyan
    const saturation = 100 - t * 20; // 100% -> 80%
    const lightness = 25 + t * 25; // 25% -> 50%
    return `hsl(${hue}, ${saturation}%, ${lightness}%)`;
  };

  const color = getTemperatureColor(progress);

  // Arc calculations
  const cx = 100;
  const cy = 100;
  const radius = 80;
  const startAngle = 135;
  const endAngle = 405;
  const sweepAngle = endAngle - startAngle; // 270 degrees

  const polarToCartesian = (angle: number) => {
    const rad = (angle * Math.PI) / 180;
    return {
      x: cx + radius * Math.cos(rad),
      y: cy + radius * Math.sin(rad),
    };
  };

  const createArcPath = (start: number, end: number) => {
    const startPoint = polarToCartesian(start);
    const endPoint = polarToCartesian(end);
    const largeArc = end - start > 180 ? 1 : 0;
    return `M ${startPoint.x} ${startPoint.y} A ${radius} ${radius} 0 ${largeArc} 1 ${endPoint.x} ${endPoint.y}`;
  };

  const thumbAngle = startAngle + progress * sweepAngle;
  const thumbPos = polarToCartesian(thumbAngle);

  const handleInteraction = useCallback(
    (clientX: number, clientY: number) => {
      if (!svgRef.current) return;

      const rect = svgRef.current.getBoundingClientRect();
      const x = clientX - rect.left - rect.width / 2;
      const y = clientY - rect.top - rect.height / 2;

      let angle = (Math.atan2(y, x) * 180) / Math.PI;
      if (angle < 0) angle += 360;
      if (angle < startAngle) angle += 360;

      // Clamp to arc range
      angle = Math.max(startAngle, Math.min(endAngle, angle));

      const newProgress = (angle - startAngle) / sweepAngle;
      const newValue = Math.round(min + newProgress * (max - min));
      onChange(Math.max(min, Math.min(max, newValue)));
    },
    [min, max, onChange]
  );

  const handleMouseDown = (e: React.MouseEvent) => {
    handleInteraction(e.clientX, e.clientY);

    const handleMouseMove = (e: MouseEvent) => {
      handleInteraction(e.clientX, e.clientY);
    };

    const handleMouseUp = () => {
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);
    };

    window.addEventListener('mousemove', handleMouseMove);
    window.addEventListener('mouseup', handleMouseUp);
  };

  const handleTouchStart = (e: React.TouchEvent) => {
    const touch = e.touches[0];
    handleInteraction(touch.clientX, touch.clientY);

    const handleTouchMove = (e: TouchEvent) => {
      const touch = e.touches[0];
      handleInteraction(touch.clientX, touch.clientY);
    };

    const handleTouchEnd = () => {
      window.removeEventListener('touchmove', handleTouchMove);
      window.removeEventListener('touchend', handleTouchEnd);
    };

    window.addEventListener('touchmove', handleTouchMove);
    window.addEventListener('touchend', handleTouchEnd);
  };

  // Tick marks at landmarks
  const landmarks = [60, 80, 100, 120, 140, 160, 180, 200, 240];

  return (
    <svg
      ref={svgRef}
      width="100%"
      height="100"
      viewBox="0 0 200 120"
      className="cursor-pointer select-none"
      onMouseDown={handleMouseDown}
      onTouchStart={handleTouchStart}
    >
      {/* Background track */}
      <path
        d={createArcPath(startAngle, endAngle)}
        fill="none"
        stroke="var(--charcoal)"
        strokeWidth="8"
        strokeLinecap="round"
      />

      {/* Glow layer */}
      <path
        d={createArcPath(startAngle, thumbAngle)}
        fill="none"
        stroke={color}
        strokeWidth="12"
        strokeLinecap="round"
        opacity="0.3"
        filter="blur(4px)"
      />

      {/* Value arc */}
      <path
        d={createArcPath(startAngle, thumbAngle)}
        fill="none"
        stroke={color}
        strokeWidth="8"
        strokeLinecap="round"
      />

      {/* Tick marks */}
      {landmarks.map((landmark) => {
        if (landmark < min || landmark > max) return null;
        const tickProgress = (landmark - min) / (max - min);
        const tickAngle = startAngle + tickProgress * sweepAngle;
        const innerRadius = radius - 12;
        const pos = {
          x: cx + innerRadius * Math.cos((tickAngle * Math.PI) / 180),
          y: cy + innerRadius * Math.sin((tickAngle * Math.PI) / 180),
        };
        return (
          <circle
            key={landmark}
            cx={pos.x}
            cy={pos.y}
            r="2"
            fill={value === landmark ? 'var(--electric-blue)' : 'var(--tertiary-text)'}
          />
        );
      })}

      {/* Thumb */}
      <circle
        cx={thumbPos.x}
        cy={thumbPos.y}
        r="8"
        fill={color}
        filter="drop-shadow(0 0 6px var(--electric-blue))"
      />
    </svg>
  );
};
