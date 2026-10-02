# Cultivation (xianxia / wuxia) for SurfShack13: handover

Branch: `port-cultivation` on the user's fork (`Ixde969-hub/SurfShack13`). Upstream is `peppyrmynt/SurfShack13` ("pepper").
This file is a working note for whoever continues the feature. Delete it (and `tools/cultivation_art/` if unwanted) before an upstream PR.

## Working with the user (important)

- **Never push or PR to upstream without asking.** Pushing to the fork branch is fine.
- **No "Generated with Claude Code" / Co-Authored-By lines** in commits or PRs.
- **PR text and the `:cl:` author must credit "Timmy the Tider".**
- **Batch changes:** during playtest iteration, don't run tests / commit / push after every fix. Build so they can test, list what changed, and only run tests + commit + push when they say so.
- The user playtests on a local DreamDaemon and sends short feedback ("X looks bad", "Y should be stronger"). Act on it directly; ask only when a choice is genuinely theirs.
- Sound: use temple sounds (`cultivation_temple_sound`, `cultivation_great_bell`), never `pray_chaplain.ogg` (Christian choir; the user objected).
- Art: the user dislikes blurry downscaled sprites. See "Art pipeline" below.

## Build, lint, test

- Build: `dm.exe tgstation.dme` (Windows) or the repo's normal build tooling. If a DreamDaemon is running from the same checkout, its `.rsc` is locked and new icon files "cannot be found": compile a copy (`cp tgstation.dme tgstation_cultcheck.dme`) and delete the copy afterwards.
- Lint: `bash tools/ci/check_grep.sh`. On Windows it always reports invalid map file references in `_maps/*.json`; those are pre-existing and unrelated.
- Unit tests: build with `-DCIBUILDING`, deploy with `tools/deploy.sh <dir>`, copy `tools/ci/ci_config.txt` to `<dir>/config/config.txt` and `_maps/runtimestation.json` to `<dir>/data/next_map.json`, then `DreamDaemon tgstation.dmb -close -trusted -verbose -params "log-directory=ci"` and read `<dir>/data/logs/ci/tests.log`. Last full run: 336 passing.
- Our test: `surfshack13/code/modules/unit_test/cultivation.dm`. Core `#undef`s `TEST_ASSERT`/`TEST_ASSERT_EQUAL` after its own tests, so modular tests redefine them locally (already done there).
- tg CI rules we hit: no new `simple_animal` subtypes; every status effect type (including abstract parents) needs an `id`; worn items need worn sprites; all spell names must be unique; new traits must be registered globally (we avoided new traits).

## Where things live

`surfshack13/code/modules/cultivation/`
| File | What |
|---|---|
| `cultivator.dm` | The cultivator datum (FLAG_FAKE_ANTAG antag datum on the mind): realm, qi, insight, instability, laws, techniques, HUD orb, life tick (passive insight, epiphanies, Golden Core crit sustain), Nascent Soul revival, examine lines, roundend, admin buttons |
| `dantian.dm` | Dantian organ (physical half of cultivation; grade caps effective realm). Also keeps the dantian through species organ regeneration |
| `laws.dm` | Five element laws (techniques by realm, Foundation passives, insight sources) and combination techniques |
| `techniques/_technique.dm` | Technique base types (self and pointed), qi cost, counterfeit shouting, realm-scaled cooldowns, auto medallion icons |
| `techniques/universal.dm` | Meditate (continuous cycles, heals), Breakthrough, Spiritual Sense, Empty Palm, Qinggong, Write Talisman, Accept Disciple, Acupoint Sealing, Realm Pressure, Spirit Beast Contract, Summon Beast |
| `techniques/metal.dm` | Artifact binding component (recall, flight, catching, severing), Flying Sword, Sword Qi, Sword Riding, `cultivation_sever_limb` |
| `techniques/elements.dm` | Water/Fire/Earth/Wood techniques, combos, vines, mud, molten footprints |
| `techniques/advanced.dm` | Void Step, formation arrays, Nascent Soul signatures (Sword Formation, Mirror Lake, Sea of Flames, Buddha's Palm, Myriad Spring Revival) |
| `status_effects.dm` | Ward, Golden Bell, Rooted Stance, Sword Riding platform, Dharma Idol, Burning Blood, qi leak, Molten Step |
| `breakthrough.dm` | Breakthrough controller: readiness, storm cloud, unwarned lightning, grounding rods, failures, Heart Demon |
| `cultivation_site.dm` | Feng shui element scan, mat, gathering array and sect plaque bonuses |
| `cultivation_panel.dm` | The "Path of Cultivation" browser panel |
| `items.dm` | Manuals (+ counterfeits), talismans, spirit beast component (pet commands, monkeys, follow/rift), ancestral ring ghost role |
| `alchemy.dm` | Pills and pill toxicity |
| `legendary_artifacts.dm` | Ganjiang/Moye, Heaven Reliant (carves walls), Dragon Saber, Ruyi Jingu Bang, Purple-Gold Gourd, Plantain Fan, Bagua Mirror, Qiankun Pouch |
| `mandate_of_heaven.dm` | Mandate for heads (Captain = Son of Heaven), decree, withdrawal, jade seal, omens |
| `wuxia/martial_styles.dm` | Drunken Fist, Eagle Claw, Wing Chun + manuals |
| `wuxia/jianghu.dm` | Face, honor duels, sects/plaques/transmission/rivalry, hidden weapons |
| `visuals.dm` | Qi waves, particles, attached visuals, temple sounds, wound mending helper |
| `activity_hooks.dm` | Modular hooks that feed insight (crafting, tool use, skills, harvest, books, tea, water) |
| `roundstart_loot.dm` | Round start spawns (manuals, ring, wuxia manuals, one legendary artifact) and mandate registration |

Defines: `surfshack13/code/__DEFINES/cultivation.dm`. The only core edits: `ORGAN_SLOT_DANTIAN` in `code/__DEFINES/DNA.dm` (marked Surf Shack Edit) and 25 lines appended to `strings/tips.txt` (Confucius quotes + cultivation tips).

Icons: `surfshack13/icons/cultivation/` (actions, hud, items, artifacts, effects 32/64/96, riding, terrain, particles, dharma_idol).

## Key numbers (for balance passes)

- Realm thresholds (consolidated insight): 60 / 150 / 300. Max qi 50 / 100 / 175 / 275. Pending insight cap 60.
- Cooldowns scale 100/90/80/70% by realm. Law slots = realm (Nascent Soul: all 5).
- Sword Qi: 22 + 4/realm, range 12, speed 2.5, sever 10% + 5%/realm. Flying Sword cap 20 + 4/realm, blades sever 8% + 4%/realm.
- Buddha's Palm 45 centre / 20 shockwave; Sword Formation 12/s within 2 tiles; Sea of Flames 22/30/38 per wave over 6 tiles.
- Golden Core crit sustain 1.5 brute+burn/s (x2 Nascent Soul), Nascent Soul revival every 10 minutes.

## Art pipeline

Scripts in `tools/cultivation_art/` (Python + Pillow; Chinese glyphs need a CJK font, on Linux `apt install fonts-noto-cjk`). Run from the repo root, in this order, because later scripts overwrite states earlier ones made:

1. `make_art_v2.py` (needs env `PREVIEW=<png path>`): action medallions, animated HUD orb, particles, 96px effects (storm, sigils), first pass of 64px effects
2. `make_effects32.py`: orbit sword, sword qi crescent + impact, thorn sword + splinters
3. `make_pixel_gold.py`: Golden Bell, Buddha's Palm (+ shadow), Dharma Idol (keeps water bubble / void rift)
4. `make_pixel_fx.py`: vines, mud, molten footprints, sword riding platform and qi cloud
5. `make_pixel_items.py`: all items (mat, manual, ring, dantian, golden core, needles, dagger, pellets, plaque, seal, pills) and first pass of artifacts
6. `make_artifacts_hd.py`: gourd, fan, mirror, pouch, needle (drawn at 256px, downscaled, re-sharpened, crisp alpha + outline)
7. `make_weapons_native.py`: swords and staff, hand-placed pixels in tg's weapon style (replaces only those states)

Lessons: long thin diagonals (weapons) must be native pixel art in tg's style (corner to corner, solid shaded rows, no black outline). On a 45 degree line, offsets `(1,0)` and `(0,1)` are the same row (row index = dx + dy). Chunky objects look great drawn large and downscaled, then re-sharpened. Keep glows as a separate soft layer, small and subtle.

## Not yet tested in game

Everything since the second commit has only been compiled and unit tested, with the user spot-checking. Especially worth real testing: Mandate withdrawal/seal claim, honor duels and sects with two clients, spirit beast pet commands on non-pet mobs and monkeys, purple-gold gourd, Heaven Reliant wall carving, Nascent Soul revival, Golden Core crit sustain, Sword Riding platform visuals, formation barrier pathing.

## Backlog: what the user wants next

The user's standing direction is "keep improving: sprites, animations, sounds, gameplay loops, polish, fun". Concretely:

- **Sprites**: inhand sprites for artifacts (currently borrowed tg inhands), proper talisman sprites per type, sect plaque and jade seal could use the HD treatment, a real cultivation manual cover per law, Heart Demon visual, spirit beast aura sprite.
- **Animations**: talisman use effects, acupoint jab sparks, Realm Pressure distortion, breakthrough success sequence (rising, light pillar, realm name banner), formation activation flare, decree banner.
- **Sounds**: more oriental cues (guqin/pipa-like plucks via instrument samples, wind chimes); qinggong whoosh variants; per-element cast sounds.
- **Gameplay loops**: forbidden/antag techniques (corpse puppets, devouring art, soul search, gu worms; ask whether antag-only or rare manuals), guqin music cultivation, Ascension finale, sect missions/tournaments, more insight sources per law, pills that matter more (alchemy cauldron structure), artifact refinement (upgrade a bound artifact over time), Heart Demon fights, spirit beast evolutions.
- **Balance**: everything is first-pass numbers; adjust from playtest feedback.
