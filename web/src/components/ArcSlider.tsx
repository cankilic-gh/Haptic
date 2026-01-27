import { useRef, useCallback, useState, useEffect } from 'react';
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
  const isDraggingRef = useRef(false);

  const targetProgress = (value - min) / (max - min);
  const [displayProgress, setDisplayProgress] = useState(targetProgress);

  // Animate displayProgress toward targetProgress along the arc
  useEffect(() => {
    if (isDraggingRef.current) {
      // During drag, update immediately
      setDisplayProgress(targetProgress);
      return;
    }

    // Smooth animation when clicking (not dragging)
    const animationDuration = 300; // ms
    const startProgress = displayProgress;
    const startTime = performance.now();

    const animate = (currentTime: number) => {
      const elapsed = currentTime - startTime;
      const t = Math.min(elapsed / animationDuration, 1);

      // Ease out cubic
      const eased = 1 - Math.pow(1 - t, 3);

      const newProgress = startProgress + (targetProgress - startProgress) * eased;
      setDisplayProgress(newProgress);

      if (t < 1) {
        requestAnimationFrame(animate);
      }
    };

    requestAnimationFrame(animate);
  }, [targetProgress]);

  // Temperature color: vibrant cyan that gets brighter/whiter with tempo
  const getTemperatureColor = (t: number) => {
    const hue = 190; // Cyan
    const saturation = 100 - t * 15; // 100% -> 85% (stays saturated)
    const lightness = 40 + t * 40; // 40% -> 80% (much brighter at high tempo)
    return `hsl(${hue}, ${saturation}%, ${lightness}%)`;
  };

  const color = getTemperatureColor(displayProgress);

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
    if (end <= start) return '';
    const startPoint = polarToCartesian(start);
    const endPoint = polarToCartesian(end);
    const largeArc = end - start > 180 ? 1 : 0;
    return `M ${startPoint.x} ${startPoint.y} A ${radius} ${radius} 0 ${largeArc} 1 ${endPoint.x} ${endPoint.y}`;
  };

  const thumbAngle = startAngle + displayProgress * sweepAngle;
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
    isDraggingRef.current = true;
    handleInteraction(e.clientX, e.clientY);

    const handleMouseMove = (e: MouseEvent) => {
      handleInteraction(e.clientX, e.clientY);
    };

    const handleMouseUp = () => {
      isDraggingRef.current = false;
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);
    };

    window.addEventListener('mousemove', handleMouseMove);
    window.addEventListener('mouseup', handleMouseUp);
  };

  const handleTouchStart = (e: React.TouchEvent) => {
    isDraggingRef.current = true;
    const touch = e.touches[0];
    handleInteraction(touch.clientX, touch.clientY);

    const handleTouchMove = (e: TouchEvent) => {
      const touch = e.touches[0];
      handleInteraction(touch.clientX, touch.clientY);
    };

    const handleTouchEnd = () => {
      isDraggingRef.current = false;
      window.removeEventListener('touchmove', handleTouchMove);
      window.removeEventListener('touchend', handleTouchEnd);
    };

    window.addEventListener('touchmove', handleTouchMove);
    window.addEventListener('touchend', handleTouchEnd);
  };

  // Evenly spaced tick marks (9 ticks along the arc)
  const tickCount = 9;
  const tickPositions = Array.from({ length: tickCount }, (_, i) => i / (tickCount - 1));

  return (
    <svg
      ref={svgRef}
      width="100%"
      height="130"
      viewBox="0 0 200 160"
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
      {displayProgress > 0.001 && (
        <path
          d={createArcPath(startAngle, thumbAngle)}
          fill="none"
          stroke={color}
          strokeWidth="12"
          strokeLinecap="round"
          opacity="0.3"
          filter="blur(4px)"
        />
      )}

      {/* Value arc */}
      {displayProgress > 0.001 && (
        <path
          d={createArcPath(startAngle, thumbAngle)}
          fill="none"
          stroke={color}
          strokeWidth="8"
          strokeLinecap="round"
        />
      )}

      {/* Tick marks - evenly spaced, light up when slider passes them */}
      {tickPositions.map((tickProgress, index) => {
        const tickAngle = startAngle + tickProgress * sweepAngle;
        const innerRadius = radius - 12;
        const pos = {
          x: cx + innerRadius * Math.cos((tickAngle * Math.PI) / 180),
          y: cy + innerRadius * Math.sin((tickAngle * Math.PI) / 180),
        };
        const isPassed = displayProgress >= tickProgress;
        const isNear = Math.abs(displayProgress - tickProgress) < 0.02;
        return (
          <circle
            key={index}
            cx={pos.x}
            cy={pos.y}
            r={isNear ? 3 : 2}
            fill={isPassed ? 'var(--electric-blue)' : 'var(--tertiary-text)'}
            filter={isPassed ? 'drop-shadow(0 0 4px var(--electric-blue))' : undefined}
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
