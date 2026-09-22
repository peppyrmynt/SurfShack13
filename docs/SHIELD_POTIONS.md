# Shield potions

Initial implementation for SurfShack13, based on master `742ea89e829ff4c7db122faebd99b680fa46aeb5`.

| Item | Grant | Cap | Drink time | Spawn path |
| --- | ---: | ---: | ---: | --- |
| Small shield potion | 25 | 50 | 2 seconds | `/obj/item/shield_potion/small` |
| Shield potion | 50 | 100 | 5 seconds | `/obj/item/shield_potion` |

Hold the potion in the active hand and activate it (Z). Movement, changing the active item, dropping it, incapacitation, a covered mouth, or damage interrupts drinking. A fully shielded hit also interrupts it. Cancellation stops the sound and preserves the item. Shield and consumption happen only on successful completion. Action speed modifiers do not shorten the drink.

The shield belongs to a carbon body, does not regenerate, and disappears on death. Small potions do nothing at or above 50 shield; big potions do nothing at 100. The remaining pool appears in a private HUD alert. Other players see **no permanent shield outline or examine indicator**. A hit produces a short blue bubble; depletion produces an expanding cyan shatter/sparkle effect. These effects reuse native SS13 effect artwork.

## Damage integration

Brute and burn damage reaching a bodypart is absorbed after armor, species, limb and configured damage multipliers, before wound and dismemberment checks. Mixed brute/burn is absorbed proportionally. Only overflow can damage or wound the body. Whole-body damage accounts for absorbed damage instead of retrying it against each successive limb.

Toxin, oxygen, stamina and direct organ damage bypass the shield. Forced damage deliberately bypasses it. Healing does not consume shield. The shield does not block independent stun, projectile embedding, or other side effects that run outside bodypart damage; these remain normal SS13 mechanics. Direct bodypart removal and gibbing are not made invulnerable.

## Obtaining potions

Base maintenance loot weights: mini 30, big 10, existing pool 10,000. Before spawner skew or holiday additions this is about 0.299% mini and 0.100% big per loot roll. Actual round counts depend on map and spawners; these weights need playtesting.

Crafting is deliberately expensive and requires cooperation with chemistry/mining:

1. Prepare Singulo (the existing vodka, liquid dark matter and wine recipe).
2. At **270–280 K**, combine 10 units Singulo, 5 blue curacao, 2 bluespace dust and 3 frost oil to produce 10 units shield concentrate.
3. With a cocktail shaker nearby, use the Chemistry crafting menu. A mini consumes 10 units concentrate, one glass sheet and one silver sheet. A big potion consumes 20 units concentrate and the same materials. Bottling takes 10 seconds and yields one sealed potion.

The precursor reagent is inert: injection, splashing, ordinary drinking or reagent storage cannot grant shields or bypass the timed item action.

## Art and audio

`icons/obj/drinks/shield_potions.dmi` contains actual 32×32 big/small frames. Separate left/right DMI files provide four-direction in-hand frames. The art preserves the approved round jar and wide-necked mini shapes and was generated with the built-in image tool, then sized and packaged for BYOND. Preview: `docs/media/shield-potions-preview.png`.

Generation prompt: polish the approved large round Fortnite shield jar with a metal lid/right handle and the small wide-necked flask; retain chunky SS13 pixels, tidy cyan highlights, blue liquid and navy outlines; no added fine detail; transparent background.

Fortnite sound sources were supplied by the requester as MP3 attachments; original game audio is by Epic Games. These are source/provenance notes, not a claim that the audio is original to this repository.

| Bundled OGG | Source | Source segment | Processing |
| --- | --- | --- | --- |
| `drink_big.ogg` | [Potion sound](https://www.youtube.com/watch?v=HgTmiUXuHDU) | 0.35–6.95 s | Pitch-preserving tempo adjustment to 5 s |
| `drink_small.ogg` | Same supplied potion MP3 | 0.35–6.95 s | Pitch-preserving tempo adjustment to 2 s |
| `break.ogg` | [Shield damage sounds](https://www.youtube.com/watch?v=vqzCpzQgCWQ) | 0.18–1.26 s | First longer burst, short edge fades |
| `hit.ogg` | Same supplied damage MP3 | 3.30–3.95 s | Third shorter burst, short edge fades |

All four files are mono 44.1 kHz OGG Vorbis. The uploaded originals remain unchanged. The in-game mix, hit/break selection and mini tempo still need listening in-game.

## Validation and testing

DreamChecker and the repository grep checks are used for static validation. DMI state/frame metadata and OGG codecs/durations are checked separately. BYOND runtime tests and multiplayer visual/audio playtesting are still required; static checks are not runtime test results.

Regression tests in `code/modules/unit_tests/shield_potion.dm` cover caps, armor, full absorption before wounds, overflow, mixed damage, whole-body damage, healing, bypass damage types, forced damage, godmode, death cleanup, actual interrupted/completed drinking, and the precursor temperature gate.

Manual test:

1. Spawn two minis and two big pots. Drink minis to 50, verify another mini is refused, then drink a big pot to 100.
2. Walk, drop/switch items, take a hit or get stunned while drinking. Confirm no shield gain, no lost potion and no continuing audio.
3. With two clients, verify only the owner sees the counter and that bystanders see the blue effect only on impact, plus the distinct break effect at zero.
4. Deal more damage than the remaining shield. Confirm overflow damages the body and fully absorbed hits do not wound it.
5. Check shotgun/spread damage, existing wounds, mixed brute/burn, death, relogging, and both held-hand directions.
6. Craft concentrate at 275 K and bottle it with a shaker; verify the recipe fails outside its temperature range.

No other feature branches, including Hyper Adrenaline, are bundled into this branch. Combined-mode damage multipliers need a separate integration playtest.
