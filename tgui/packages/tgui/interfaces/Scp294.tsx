import { type CSSProperties, type ReactNode, useEffect, useState } from 'react';
import { Input } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import { Beaker } from './common/BeakerDisplay';

type Data = {
  beaker: Beaker | null;
  amount: number;
  cup_color: string | null;
  status: string | null;
  status_error: boolean;
};

const MAX_LENGTH = 40;

const OUTLINE = '#141018';

// Tiny 3x5 pixel font, so button labels are drawn as pixel art instead of text
const FONT: Record<string, string[]> = {
  A: ['010', '101', '111', '101', '101'],
  C: ['011', '100', '100', '100', '011'],
  D: ['110', '101', '101', '101', '110'],
  E: ['111', '100', '110', '100', '111'],
  G: ['011', '100', '101', '101', '011'],
  H: ['101', '101', '111', '101', '101'],
  I: ['111', '010', '010', '010', '111'],
  K: ['101', '101', '110', '101', '101'],
  M: ['101', '111', '111', '101', '101'],
  N: ['111', '101', '101', '101', '101'],
  V: ['101', '101', '101', '101', '010'],
  O: ['010', '101', '101', '101', '010'],
  P: ['110', '101', '110', '100', '100'],
  R: ['110', '101', '110', '101', '101'],
  S: ['011', '100', '010', '001', '110'],
  T: ['111', '010', '010', '010', '010'],
  U: ['101', '101', '101', '101', '111'],
  '-': ['000', '000', '111', '000', '000'],
  '2': ['110', '001', '010', '100', '111'],
  '4': ['101', '101', '111', '001', '001'],
  '9': ['111', '101', '111', '001', '111'],
  ' ': ['000', '000', '000', '000', '000'],
};

const textWidth = (text: string) => text.length * 4 - 1;

/** Pixel-font text as rects, at (x, y) in pixel-grid units */
const PixelText = (props: {
  text: string;
  x: number;
  y: number;
  color: string;
  shadow?: string;
}) => {
  const { text, x, y, color, shadow } = props;
  const rects: ReactNode[] = [];
  text.split('').forEach((char, index) => {
    const glyph = FONT[char] || FONT[' '];
    glyph.forEach((row, gy) =>
      row.split('').forEach((bit, gx) => {
        if (bit !== '1') {
          return;
        }
        const px = x + index * 4 + gx;
        const py = y + gy;
        if (shadow) {
          rects.push(
            <rect
              key={`s${index}-${gx}-${gy}`}
              x={px}
              y={py + 1}
              width={1}
              height={1}
              fill={shadow}
            />,
          );
        }
        rects.push(
          <rect
            key={`t${index}-${gx}-${gy}`}
            x={px}
            y={py}
            width={1}
            height={1}
            fill={color}
          />,
        );
      }),
    );
  });
  return rects;
};

type ButtonColors = {
  light: string;
  face: string;
  dark: string;
};

const GREEN: ButtonColors = {
  light: '#7fc98a',
  face: '#3f9a4e',
  dark: '#26663a',
};
const RED: ButtonColors = {
  light: '#e07a78',
  face: '#b8393f',
  dark: '#7c222b',
};
const BLUE: ButtonColors = {
  light: '#8fb3d4',
  face: '#4a78a8',
  dark: '#2c4c72',
};
const GREY: ButtonColors = {
  light: '#6c7078',
  face: '#4a4d54',
  dark: '#303238',
};

// Steel base plate the buttons sit in
const BASE_FACE = '#a3a8b0';
const BASE_DARK = '#5f646c';

// Gunmetal casing, matching the machine's sprite
const STEEL_DARK = '#1c1e22';
const STEEL = '#34373d';
const STEEL_LIGHT = '#8d939c';
const BRUSHED =
  'repeating-linear-gradient(90deg, rgba(255,255,255,0.025) 0 1px, transparent 1px 3px)';
const GRIME =
  'radial-gradient(ellipse at 15% 90%, rgba(40,30,15,0.35), transparent 45%), radial-gradient(ellipse at 85% 20%, rgba(40,30,15,0.25), transparent 40%)';

/** A dome-headed rivet in one corner of a panel */
const Rivet = (props: { position: CSSProperties }) => (
  <div
    style={{
      ...props.position,
      background: `radial-gradient(circle at 35% 35%, ${STEEL_LIGHT}, #2a2c30 70%)`,
      borderRadius: '50%',
      boxShadow: '0 1px 1px rgba(0,0,0,0.8)',
      height: '7px',
      position: 'absolute',
      width: '7px',
    }}
  />
);

const Rivets = () => (
  <>
    <Rivet position={{ top: 6, left: 6 }} />
    <Rivet position={{ top: 6, right: 6 }} />
    <Rivet position={{ bottom: 6, left: 6 }} />
    <Rivet position={{ bottom: 6, right: 6 }} />
  </>
);

/** Round, chunky pixel-art push button with a metal base plate */
const PixelButton = (props: {
  label: string;
  colors: ButtonColors;
  size?: number;
  scale?: number;
  disabled?: boolean;
  onClick: () => void;
}) => {
  const { label, size = 17, scale = 3, disabled, onClick } = props;
  const colors = disabled ? GREY : props.colors;
  const [pressed, setPressed] = useState(false);
  const depth = 3;
  const lift = pressed ? 1 : depth;
  const center = (size - 1) / 2;
  const radius = size / 2 - 0.3;

  const inside = (x: number, y: number) =>
    Math.hypot(x - center, y - center) <= radius;
  const edge = (x: number, y: number) =>
    inside(x, y) &&
    (!inside(x - 1, y) ||
      !inside(x + 1, y) ||
      !inside(x, y - 1) ||
      !inside(x, y + 1));

  const cells: ReactNode[] = [];
  // Base plate, drawn below the dome
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      if (!inside(x, y)) {
        continue;
      }
      cells.push(
        <rect
          key={`b${x}-${y}`}
          x={x}
          y={y + depth}
          width={1}
          height={1}
          fill={edge(x, y) ? OUTLINE : y > center ? BASE_DARK : BASE_FACE}
        />,
      );
    }
  }
  // Side of the dome between base and top, to make it look raised
  for (let step = lift - 1; step >= 0; step--) {
    for (let x = 0; x < size; x++) {
      for (let y = 0; y < size; y++) {
        if (inside(x, y) && y > center) {
          cells.push(
            <rect
              key={`d${step}-${x}-${y}`}
              x={x}
              y={y + depth - lift + step + 1}
              width={1}
              height={1}
              fill={edge(x, y) ? OUTLINE : colors.dark}
            />,
          );
        }
      }
    }
  }
  // Dome top
  const top = depth - lift;
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      if (!inside(x, y)) {
        continue;
      }
      let fill = colors.face;
      const dist = Math.hypot(x - center, y - center);
      if (edge(x, y)) {
        fill = OUTLINE;
      } else if (dist > radius - 2.2 && x + y < center * 2 - 2) {
        fill = colors.light;
      } else if (dist > radius - 2.2 && x + y > center * 2 + 2) {
        fill = colors.dark;
      }
      cells.push(
        <rect
          key={`t${x}-${y}`}
          x={x}
          y={y + top}
          width={1}
          height={1}
          fill={fill}
        />,
      );
    }
  }

  const labelX = Math.round(center - textWidth(label) / 2 + 0.5);
  const labelY = Math.round(center - 2.5) + top;

  return (
    <div
      style={{
        cursor: disabled ? 'default' : 'pointer',
        display: 'inline-block',
        userSelect: 'none',
      }}
      onMouseDown={() => !disabled && setPressed(true)}
      onMouseUp={() => setPressed(false)}
      onMouseLeave={() => setPressed(false)}
      onClick={() => !disabled && onClick()}
    >
      <svg
        width={size * scale}
        height={(size + depth) * scale}
        viewBox={`0 0 ${size} ${size + depth}`}
        shapeRendering="crispEdges"
      >
        {cells}
        <PixelText
          text={label}
          x={labelX}
          y={labelY}
          color={disabled ? '#9a9aa4' : '#ffffff'}
          shadow={colors.dark}
        />
      </svg>
    </div>
  );
};

const CUP_SCALE = 6;

/** Pixel-art paper cup, filled with the liquid's colour */
const PixelCup = (props: { beaker: Beaker | null; color: string | null }) => {
  const { beaker, color } = props;
  const width = 14;
  const height = 17;
  const fill = beaker?.maxVolume
    ? Math.min(1, beaker.currentVolume / beaker.maxVolume)
    : 0;
  const liquidRows = Math.round(fill * (height - 3));

  // Cup narrows by one pixel on each side every 4 rows
  const rowInset = (y: number) => Math.floor(y / 5);

  const cells: ReactNode[] = [];
  for (let y = 0; y < height; y++) {
    const inset = rowInset(y);
    for (let x = inset; x < width - inset; x++) {
      const isEdge = x === inset || x === width - inset - 1 || y === height - 1;
      let fillColor: string;
      if (!beaker) {
        fillColor = isEdge || y === 0 ? '#4a4a55' : 'transparent';
      } else if (isEdge) {
        fillColor = OUTLINE;
      } else if (y <= 1) {
        fillColor = y === 0 ? OUTLINE : '#fffaf0';
      } else if (height - 1 - y <= liquidRows && color) {
        fillColor = color;
      } else if (x >= width - inset - 3) {
        fillColor = '#cfc6b3';
      } else {
        fillColor = '#efe9da';
      }
      if (fillColor === 'transparent') {
        continue;
      }
      cells.push(
        <rect
          key={`${x}-${y}`}
          x={x}
          y={y}
          width={1}
          height={1}
          fill={fillColor}
        />,
      );
      // Lighter surface line on top of the liquid
      if (
        beaker &&
        color &&
        !isEdge &&
        y > 1 &&
        height - 1 - y === liquidRows
      ) {
        cells.push(
          <rect
            key={`s${x}-${y}`}
            x={x}
            y={y}
            width={1}
            height={1}
            fill="#ffffff"
            opacity={0.4}
          />,
        );
      }
    }
  }

  return (
    <svg
      width={width * CUP_SCALE}
      height={height * CUP_SCALE}
      viewBox={`0 0 ${width} ${height}`}
      shapeRendering="crispEdges"
    >
      {cells}
    </svg>
  );
};

const TITLE = 'VENDING MACHINE';

/** Stamped steel nameplate with the title punched into it */
const Nameplate = () => (
  <div
    style={{
      background: `linear-gradient(${STEEL_LIGHT}, #5d626a)`,
      border: `2px solid ${STEEL_DARK}`,
      borderRadius: '3px',
      boxShadow:
        'inset 0 1px 0 rgba(255,255,255,0.35), 0 2px 3px rgba(0,0,0,0.6)',
      margin: '0 auto',
      padding: '4px 10px 2px',
      width: 'fit-content',
    }}
  >
    <svg
      width={textWidth(TITLE) * 3}
      height={6 * 3}
      viewBox={`0 0 ${textWidth(TITLE)} 6`}
      shapeRendering="crispEdges"
    >
      <PixelText text={TITLE} x={0} y={0} color="#23262b" shadow="#b9bec6" />
    </svg>
  </div>
);

export const Scp294 = (props) => {
  const { act, data } = useBackend<Data>();
  const { beaker, amount, cup_color, status, status_error } = data;
  const [liquid, setLiquid] = useState('');
  const [pouring, setPouring] = useState(false);

  useEffect(() => {
    if (!pouring) {
      return;
    }
    const timer = setTimeout(() => setPouring(false), 1800);
    return () => clearTimeout(timer);
  }, [pouring]);

  // Pouring with no cup makes the machine drop one in first
  const pour = () => {
    if (!liquid.trim()) {
      return;
    }
    act('pour', { name: liquid });
    setPouring(true);
    setLiquid('');
  };

  const cupHeight = 17 * CUP_SCALE;

  return (
    <Window width={330} height={500}>
      <Window.Content>
        <div
          style={{
            background: `${GRIME}, ${BRUSHED}, linear-gradient(${STEEL}, ${STEEL_DARK})`,
            border: `3px solid #0e0f11`,
            borderRadius: '4px',
            boxShadow: `inset 0 0 0 2px ${STEEL_LIGHT}55, inset 0 0 30px rgba(0,0,0,0.6)`,
            display: 'flex',
            flexDirection: 'column',
            height: '100%',
            padding: '14px 16px 10px',
            position: 'relative',
          }}
        >
          <Rivets />
          <Nameplate />

          <div
            style={{
              background: `repeating-linear-gradient(0deg, rgba(0,0,0,0.25) 0 1px, transparent 1px 3px), linear-gradient(#11232a, #0a1519)`,
              border: `2px solid ${STEEL_DARK}`,
              borderRadius: '2px',
              boxShadow: `0 0 0 2px #50555d, inset 0 0 12px rgba(0,0,0,0.9)`,
              fontFamily: 'monospace',
              margin: '10px 0',
              padding: '5px 7px',
            }}
          >
            <div
              style={{
                color: status_error ? '#ff6a5a' : '#79d3e6',
                fontSize: '11px',
                minHeight: '15px',
                textShadow: '0 0 4px currentColor',
              }}
            >
              {'> '}
              {status || 'ENTER ANY LIQUID'}
            </div>
            <Input
              fluid
              autoFocus
              maxLength={MAX_LENGTH}
              placeholder="type a liquid, press enter..."
              value={liquid}
              onChange={(e, value) => setLiquid(value)}
              onEnter={() => pour()}
            />
          </div>

          <div
            style={{
              alignItems: 'center',
              background: `${BRUSHED}, linear-gradient(#050505, #17191c)`,
              border: `3px solid #0b0c0d`,
              borderRadius: '3px',
              boxShadow: `0 0 0 2px #50555d, inset 0 8px 18px rgba(0,0,0,0.95)`,
              display: 'flex',
              flex: 1,
              flexDirection: 'column',
              justifyContent: 'flex-end',
              position: 'relative',
            }}
          >
            <div
              style={{
                background: `linear-gradient(90deg, #3a3d42, ${STEEL_LIGHT}, #3a3d42)`,
                border: '2px solid #0b0c0d',
                borderTop: 'none',
                height: '12px',
                left: 'calc(50% - 11px)',
                position: 'absolute',
                top: 0,
                width: '22px',
              }}
            />
            {pouring && (
              <div
                style={{
                  background: cup_color || '#8fd3ff',
                  bottom: `${cupHeight + 10}px`,
                  left: 'calc(50% - 2px)',
                  opacity: 0.85,
                  position: 'absolute',
                  top: '12px',
                  width: '4px',
                }}
              />
            )}
            <PixelCup beaker={beaker} color={cup_color} />
            <div
              style={{
                background: `repeating-linear-gradient(90deg, #2a2d31 0 4px, #0e0f11 4px 6px)`,
                borderTop: `2px solid ${STEEL_LIGHT}`,
                height: '8px',
                marginTop: '2px',
                width: '100%',
              }}
            />
          </div>

          <div
            style={{
              color: '#9aa0a8',
              fontFamily: 'monospace',
              fontSize: '10px',
              minHeight: '14px',
              padding: '4px 0 6px',
              textAlign: 'center',
            }}
          >
            {beaker
              ? beaker.contents?.length
                ? beaker.contents
                    .map((reagent) => `${reagent.volume}u ${reagent.name}`)
                    .join(', ')
                : `empty cup (${beaker.maxVolume}u)`
              : `no cup - ${amount}u per pour`}
          </div>

          <div
            style={{
              alignItems: 'flex-end',
              background: `${BRUSHED}, linear-gradient(#2a2d32, #1a1c20)`,
              border: `2px solid #0e0f11`,
              borderRadius: '3px',
              boxShadow: `inset 0 1px 0 ${STEEL_LIGHT}44`,
              display: 'flex',
              justifyContent: 'space-around',
              padding: '6px 4px 4px',
            }}
          >
            <PixelButton
              label="CUP"
              colors={GREEN}
              disabled={!!beaker}
              onClick={() => act('makecup')}
            />
            <PixelButton
              label="POUR"
              colors={RED}
              size={19}
              disabled={!liquid.trim()}
              onClick={pour}
            />
            <PixelButton
              label="TAKE"
              colors={BLUE}
              disabled={!beaker}
              onClick={() => act('take_cup')}
            />
          </div>
        </div>
      </Window.Content>
    </Window>
  );
};
