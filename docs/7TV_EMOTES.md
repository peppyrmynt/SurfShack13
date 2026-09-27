# 7TV emotes

All `/datum/emote/living/seventv` subtypes inherit a side speech bubble inspired by
`laugh_k`: a click-through image attached to the speaker, a short pop-in, and a
shrink-out followed by removal from the original viewers and deletion.
The frame is drawn once and cached. Artwork stays a separate overlay, preserving
DMI animation frames and timing. It fits within 32 by 32 pixels without changing
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
