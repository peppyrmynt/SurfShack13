# 7TV emotes

All `/datum/emote/living/seventv` subtypes inherit a side speech bubble inspired by
`laugh_k`: a click-through image attached to the speaker, a short pop-in, and a
shrink-out followed by removal from the original viewers and deletion.
The frame is extracted from the existing `laugh_king.dmi` sprite and cached. Each emote composites its artwork over that
frame once, preserving DMI animation frames and timing in a single cached icon. It fits within 32 by 32 pixels without changing
its aspect ratio. Nearby sighted viewers, including the speaker, receive it.

To add an emote, define a child of `/datum/emote/living/seventv` with `key`,
`message`, and `emote_icon_state`. Set `emote_icon` if using another DMI, and
optionally `sound` and `emote_duration` (default three seconds). No custom
`run_emote` is needed. Existing sentient-mob checks and 60-second cooldown apply.

```dm
/datum/emote/living/seventv/example
	key = "example"
	message = "reacts."
	emote_icon = 'icons/mob/human/example.dmi'
	emote_icon_state = "example"
	emote_duration = 4 SECONDS
```

## In-game verification

- Try `*hmm`, `*taa`, `*fuckingdies`, and `*sigma`: confirm the side frame,
  animation, existing text/sound, and disappearance (sigma lasts five seconds).
- Walk during the animation: the bubble should follow the speaker.
- Try a sentient non-human mob and another nearby client; check blind viewers
  and clients outside view do not receive it.
- Repeat within 60 seconds: the normal cooldown should block it.
- Disconnect a viewer or delete the speaker while visible: check for runtimes
  and ensure the image is removed after its duration.
- Compare `*laugh_k`, which keeps its original artwork and behavior.

## Emote wheel (testing phase)

Press **Alt+E** or use **IC → Emote Wheel**. The hotkey can be changed under the
Emote keybindings category. If an existing binding occupies Alt+E, assign the new
Emote Wheel binding manually in preferences.

The wheel displays a thumbnail and a visible command label (for example,
`*sigma`) for 7TV emotes and `laugh_k` that the current mob is eligible to use.
All fourteen fit on one page for humans; future 7TV children are discovered from
the emote registry and additional pages are automatic. Click a picture to perform
it, click the center to cancel, or press the hotkey again to close the wheel.
Selection goes through the normal intentional-emote handler, including cooldowns
and current-state checks. Changing controlled mob or disconnecting cancels it.

Typed commands, `*help`, and the existing Emote Panel remain available. Moving
these emotes exclusively to the wheel is deferred until in-game testing confirms
it works.

Test Alt+E opening/closing, all picture/command labels, selection and its normal
bubble/audio, immediate repeat selection respecting the 60-second cooldown,
non-human eligibility, and cancellation when changing controlled mob.

The wheel thumbnails are generated during startup and reused on each opening.
Opening scans only the cached wheel entries, with no icon scaling/cropping. The original staggered opening animation is retained. Wheel HUD objects are deleted when the menu closes.
Explicit macros are refreshed on login and keybinding changes, so the configured
wheel shortcut also works when chat input is focused, without toggling hotkeys.

Check first-open and repeated-open game stutter in-game, and test Alt+E directly
after login in both input modes, plus remapping/unbinding the shortcut.

The explicit macro owns the wheel shortcut so the generic Any-key handler cannot
immediately toggle it closed. A short debounce also ignores duplicate events.
Emote captions use the default runechat colour scheme, including the speaker's
generated colour and the existing emote styling.
