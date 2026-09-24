# Spaceman Dance Rig

A standalone editor for the dances in `strings/dances.json`. Open `dance_editor.html` in any browser; it needs no install or server.

- Pick a keyframe, then drag the spaceman's limbs (or use the sliders) to pose them. Drag rotates a limb around its joint; hold Shift, or switch to Move, to shift it instead.
- Durations are in deciseconds. Each keyframe's pose is reached at the end of its duration.
- Repeat blocks replay earlier frames by number, the same as `repeat_frames` in the JSON.
- Press Play to preview. The preview follows the same rules as `code/modules/mob/living/carbon/human/dancing.dm`, though BYOND's tweening can look slightly different in game.

When the dance looks right, copy the export into `strings/dances.json` (under `random_dances` or `secret_dances`) and have an admin use Debug > Reload Dances.

The Open list is a copy of `dances.json` from when the tool was written. Paste the current file into Import to refresh it.
