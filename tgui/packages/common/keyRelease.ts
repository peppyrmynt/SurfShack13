/**
 * @file
 * SURFSHACK EDIT - Fixes movement getting stuck in one direction.
 *
 * BYOND tracks held keys through the map's key macros. When a key is pressed
 * on the map and a browser window (tgui UI, chat, say box, ...) takes focus
 * before it is released, the release happens in the browser instead. BYOND
 * never sees it, keeps the key as held and keeps moving you that way. Other
 * movement keys then look "blocked" because they cancel against the stuck one.
 *
 * This forwards the release of any key that was pressed outside this window.
 * Uses native listeners so it also works while typing in a text field.
 */

/** Mirrors the keycode -> BYOND key name mapping used by tgui-core. */
export function keyCodeToByond(keyCode: number): string | undefined {
  if (keyCode === 16) return 'Shift';
  if (keyCode === 17) return 'Ctrl';
  if (keyCode === 18) return 'Alt';
  if (keyCode === 33) return 'Northeast';
  if (keyCode === 34) return 'Southeast';
  if (keyCode === 35) return 'Southwest';
  if (keyCode === 36) return 'Northwest';
  if (keyCode === 37) return 'West';
  if (keyCode === 38) return 'North';
  if (keyCode === 39) return 'East';
  if (keyCode === 40) return 'South';
  if ((keyCode >= 48 && keyCode <= 57) || (keyCode >= 65 && keyCode <= 90)) {
    return String.fromCharCode(keyCode);
  }
  if (keyCode >= 96 && keyCode <= 105) return `Numpad${keyCode - 96}`;
}

let isSetup = false;

export function setupKeyReleaseForwarding() {
  if (isSetup) {
    return;
  }
  isSetup = true;
  // Keys that were freshly pressed inside this window. Auto-repeat of a key
  // held down since before we got focus doesn't count.
  let pressedHere: Record<number, boolean> = {};

  // A key still down when we lose focus gets released somewhere else, so
  // forget it. Otherwise a later release here would be wrongly skipped.
  window.addEventListener('blur', () => {
    pressedHere = {};
  });

  document.addEventListener(
    'keydown',
    (event) => {
      if (!event.repeat) {
        pressedHere[event.keyCode] = true;
      }
    },
    true,
  );

  document.addEventListener(
    'keyup',
    (event) => {
      const wasPressedHere = pressedHere[event.keyCode];
      pressedHere[event.keyCode] = false;
      if (wasPressedHere) {
        return;
      }
      const byondKey = keyCodeToByond(event.keyCode);
      // The server ignores KeyUp for keys it doesn't consider held,
      // so a spare one is harmless.
      if (byondKey) {
        Byond.command(`KeyUp "${byondKey}"`);
      }
    },
    true,
  );
}
