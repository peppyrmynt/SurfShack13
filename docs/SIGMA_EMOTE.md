# Sigma emote

Type `*sigma` to show the animated face above a sentient living mob and play
the matching five-second audio clip. It also appears in the normal emote help.
The existing 7TV eligibility rules and 60-second emote cooldown apply. Music
plays at its original pitch, with the shared audio cooldown held for five seconds.
The other 7TV emotes retain their original icons and three-second display time.

## Preview

[Enlarged preview with audio](media/sigma-emote-preview.mp4)

The preview enlarges the actual 32-by-32 animation with nearest-neighbor scaling.
The game uses the DMI and OGG files, not the preview MP4.

## Asset provenance and conversion

- Source: user-supplied `Patrick Bateman Sigma Meme Template.mp4`.
- Source SHA-256: `72c3e814bb228352ac34c0e1c8976510b369126be6842bc7777f3dfb91296c97`.
- Excerpt: 00:08.000 through 00:13.000, for both picture and sound.
- Visual: face-centered crop, following the shot change at 00:08.875;
  32-by-32 pixels, 50 frames at 10 frames per second, played once.
- Audio: mono Vorbis, 44.1 kHz, five seconds; 3 dB attenuation for headroom,
  20 ms fade-in and 100 ms fade-out to soften the edit boundaries.
  No pitch or playback-speed change.
- Asset paths: `icons/mob/human/sigma_emote.dmi` and
  `sound/effects/aprilfools/sigma.ogg`.
- This is a conversion of supplied footage and audio, not newly drawn artwork
  or an asset from the original tgstation 7TV port. The upload supplied no
  separate licensing information; original audiovisual rights remain with their
  respective holders.

## Validation

- Parse the DMI with the repository's DMI reader; verify the state, frame count,
  single-play setting, and total animation delay of 50 deciseconds.
- Verify the OGG duration is five seconds and it decodes without errors.
- Run DreamChecker and `git diff --check`.
- In game, check `*sigma` and `*help` on human and sentient non-human mobs,
  nearby audio, original music pitch, overlay removal after five seconds,
  and rejection of repeated use during the 60-second cooldown.
