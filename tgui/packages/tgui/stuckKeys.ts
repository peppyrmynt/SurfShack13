/**
 * @file
 * SURFSHACK EDIT - Fixes movement keys getting stuck with tgui windows open.
 *
 * Port of the fix from BeeStation-Hornet#12834, which tgstation took in
 * with tgui-core v4.2 (tgui-core#192). tgui-core v2's focus tracking breaks
 * on BYOND 516: its "window-blur" event never fires when you click from a
 * tgui window back to the map, so the keys it passed through to BYOND are
 * never released. We listen for the native blur ourselves instead.
 * Focusing a text input also has to release them, since key events from
 * inputs are ignored and the release would otherwise never be sent.
 *
 * On top of that:
 * - Releases of keys pressed on the map are forwarded (see common/keyRelease).
 * - tgui-core never passes arrow keys through to BYOND, so arrow-key movement
 *   stopped as soon as a window was focused. We pass them through, unless a
 *   component already handled the key.
 */

import { keyCodeToByond, setupKeyReleaseForwarding } from 'common/keyRelease';
import { canStealFocus } from 'tgui-core/events';
import { listenForKeyEvents, releaseHeldKeys } from 'tgui-core/hotkeys';

function isArrowKey(keyCode: number) {
  return keyCode >= 37 && keyCode <= 40;
}

export function setupStuckKeyRelease() {
  setupKeyReleaseForwarding();

  // Keys freshly pressed inside this window.
  let pressedHere: Record<number, boolean> = {};
  window.addEventListener('blur', () => {
    pressedHere = {};
  });
  // tgui-core passes auto-repeat keydowns through as well, so a key held on
  // the map gets "adopted" by the window once it has focus, and is then
  // released on blur/close, stopping movement although it's still held.
  // BYOND saw that key go down, so it will see it go up on the map; leave it
  // alone. tgui-core skips events that are defaultPrevented. Text inputs are
  // left untouched so typing still repeats.
  document.addEventListener(
    'keydown',
    (event) => {
      if (!event.repeat) {
        pressedHere[event.keyCode] = true;
      } else if (
        !pressedHere[event.keyCode] &&
        !(event.target instanceof HTMLElement && canStealFocus(event.target))
      ) {
        event.preventDefault();
      }
    },
    true,
  );
  document.addEventListener(
    'keyup',
    (event) => {
      pressedHere[event.keyCode] = false;
    },
    true,
  );

  // Arrow keys we passed through to BYOND and still need to release.
  const arrowsHeld: Record<string, boolean> = {};

  listenForKeyEvents((key) => {
    if (!isArrowKey(key.code)) {
      return;
    }
    const byondKey = keyCodeToByond(key.code)!;
    if (key.isDown()) {
      if (!arrowsHeld[byondKey] && !key.event.defaultPrevented) {
        arrowsHeld[byondKey] = true;
        Byond.command(`KeyDown "${byondKey}"`);
      }
      return;
    }
    if (key.isUp() && arrowsHeld[byondKey]) {
      arrowsHeld[byondKey] = false;
      Byond.command(`KeyUp "${byondKey}"`);
    }
  });

  const releaseAll = () => {
    releaseHeldKeys();
    for (const byondKey in arrowsHeld) {
      if (arrowsHeld[byondKey]) {
        arrowsHeld[byondKey] = false;
        Byond.command(`KeyUp "${byondKey}"`);
      }
    }
  };

  // Window lost focus (clicked the map, closed, ...): we won't see the
  // releases anymore, so let go now.
  window.addEventListener('blur', releaseAll);
  window.addEventListener('pagehide', releaseAll);
  // Text inputs swallow key events, same problem.
  document.addEventListener(
    'focus',
    (event) => {
      if (
        event.target instanceof HTMLElement &&
        canStealFocus(event.target)
      ) {
        releaseAll();
      }
    },
    true,
  );
  // The window is about to be destroyed by the server.
  Byond.subscribeTo('keys/release', releaseAll);
}
