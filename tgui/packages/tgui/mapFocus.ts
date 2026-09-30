/**
 * @file
 * SURFSHACK EDIT - Gives keyboard focus back to the map after a window takes
 * it, the way the chat panel does.
 *
 * A key pressed while a window has focus is passed through to BYOND by the
 * window, so the map never sees it go down and won't report it going up.
 * Once the window closes or loses focus it has to be released, which stops
 * movement although the key is still held. Keeping focus on the map means
 * BYOND always sees both the press and the release itself.
 *
 * Windows that need the keyboard keep focus, and so does anything you're
 * typing into.
 */

import { canStealFocus } from 'tgui-core/events';

import { globalStore, selectBackend } from './backend';
import { focusMap } from './focus';

/** Interfaces driven by the keyboard (Enter, Escape, arrows, key capture). */
const KEYBOARD_INTERFACES = [
  'AlertModal',
  'KeyComboModal',
  'ListInputWindow',
  'LootPanel',
  'NumberInputModal',
  'PreferencesMenu',
  'SurgeryInitiator',
  'TextInputModal',
];

function shouldKeepFocus() {
  const state = globalStore?.getState();
  if (!state) {
    return true;
  }
  const { config, suspended } = selectBackend(state);
  if (suspended) {
    return true;
  }
  const name = config?.interface?.name;
  if (!name || KEYBOARD_INTERFACES.includes(name)) {
    return true;
  }
  const active = document.activeElement;
  return active instanceof HTMLElement && canStealFocus(active);
}

export function setupMapFocus() {
  let mouseDown = false;
  let timer: ReturnType<typeof setTimeout> | undefined;

  const giveFocusToMap = () => {
    clearTimeout(timer);
    // Deferred so clicks, and focusing a text input, finish first.
    timer = setTimeout(() => {
      if (!shouldKeepFocus()) {
        focusMap();
      }
    });
  };

  window.addEventListener('mousedown', () => {
    mouseDown = true;
  });
  window.addEventListener('mouseup', () => {
    mouseDown = false;
    giveFocusToMap();
  });
  // Focus gained without a click in the page, e.g. when the window opens.
  window.addEventListener('focus', () => {
    if (!mouseDown) {
      giveFocusToMap();
    }
  });
  window.addEventListener('blur', () => {
    mouseDown = false;
  });
}
