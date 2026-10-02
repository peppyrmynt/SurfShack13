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
- No BYOND on Linux/cloud? `dreamchecker` (SpacemanDMM `suite-1.11`, from its GitHub releases) runs on Linux in ~20s from the repo root. Master reports 0 diagnostics; keep it that way (it catches sleeping calls inside `SIGNAL_HANDLER`s and untyped field access, which CI rejects).
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
| `mandate_powers.dm` | Wuxia emperor powers on top of the decree. Passives: Dragon Qi (rebukes weaker attackers), Heaven's Protection (10/20% less brute and burn, +2.5% per dynasty age, +2% per sworn sect; turns a crit blow aside every 10/6 min and lightning strikes the attacker), Heaven's Fortune (5/10% + 2% per age to dodge), double epiphany chance, +10/15 readiness (+5 per age), Dynasty Age tiers at 15/30/60 min. Actions: Kneel!, Imperial Treasury (graded pills, talismans, metals, a manual, legendary artifacts: guaranteed for the Son of Heaven from dynasty age 1), Imperial Pardon, Appoint Jinyiwei (guards warned with direction), Accept Fealty (sect liege), and for the Son of Heaven Ennoble (titles) and Heaven's Punishment (3 lightning strikes). Regicides are cursed and can't claim seals; seals remember their lineage |
| `legendary_artifacts.dm` (power tier) | Legendary artifacts are meant to match or beat a stage-9 body: `legendary_hit()` is true damage (`forced`, skips armour, torso hide, Vajra, Iron Shirt and realm bracing), +3 per body stage, strips Iron Shirt/Vajra/Blood Boil and adds exhaustion; +10% per refinement grade when bound. Active powers: Twin Dragon Sword Storm (paired), Heaven-Cleaving Stroke (14x3 line through reinforced walls), Dragon Slaying Strike (radius 3 cataclysm), Thirteen-Thousand-Jin Slam (Ruyi), gourd dissolves prisoners, fan hurricane/typhoon ignores push immunity, Bagua Eight Trigrams Seal (`/datum/status_effect/bagua_sealed` blocks qi techniques and body arts), Qiankun Swallow Heaven and Earth. All artifacts are INDESTRUCTIBLE |
| `mandate_of_heaven.dm` | Mandate for heads (Captain = Son of Heaven), decree, withdrawal, jade seal, omens |
| `wuxia/martial_styles.dm` | Drunken Fist, Eagle Claw, Wing Chun + manuals |
| `wuxia/jianghu.dm` | Face, honor duels, sects/plaques/transmission/rivalry, hidden weapons |
| `visuals.dm` | Wind chimes, qinggong whoosh variants, per-element cast cues, talisman flare, decree scroll, qi waves, particles, attached visuals, temple sounds, wound mending helper, guqin phrases (nylon plucks on the gong scale), distortion waves (tg `warp_effect`), acupoint sparks, breakthrough success sequence and realm banner |
| `activity_hooks.dm` | Modular hooks that feed insight (crafting, tool use, skills, harvest, books, tea, water) |
| `roundstart_loot.dm` | Round start spawns (manuals, ring, wuxia manuals, one legendary artifact, 30% chance of a Demonic Scripture) and mandate registration |
| `forbidden.dm` | The Demonic Path. Only true antagonists (any non-FLAG_FAKE_ANTAG datum) can read the Demonic Scripture (traitor uplink, 6 TC, or maint); others get a qi deviation. Masters can Transmit to willing people, who become disciples and can't teach on. Arts: Devouring Art, Plant Gu Worm + Stir the Gu, Soul Search, Corpse Puppet (basic mob jiangshi wearing the corpse, pet commands, sealed by jiangshi talismans), Heavenly Demon Blood Escape. Spiritual Sense smells demonic qi, worms and puppets |
| `heart_demon.dm` | Basic mob heart demon that copies its host and hunts only them. Killed with the host within 3 tiles = Dao heart tempered (-50 instability, +25 insight, +15 readiness for 20 min); timeout = +25 instability. From failed breakthroughs, instability >= 90 flares, and Ascension |
| `cauldron.dm` | Alchemy cauldron (craftable: 10 iron, 2 gold, welder). Heat it (welder, fire, Kindle, a Fire cultivator's palm), add herbs, a cultivator refines (20 qi, 12s). Quality roll by realm/Fire/Wood/instability: blow-ups, normal, spirit-grade pills. Cauldron-only pills: Marrow Cleansing, Beast Awakening, Pure Heart, Nine Revolutions. A bound artifact + precious sheets = tempering |
| `guqin.dm` | Guqin instrument (craftable). Playing it pulses insight and calm to the player and cultivators listening, mood to everyone |
| `body/body_cultivator.dm` | Body Molding Art, the other path (exclusive with qi). `/datum/antagonist/body_cultivator` (fake antag): stage 0-9 (Copper Skin to Primordial Chaos Body), pending tempering from training, stage benefits (max health, traits, regen, limb regrowth). Per-limb tempering is a component on each bodypart (brute/wound resistance, unarmed damage) so it travels with the limb. Mortals reach stage 1; committing (Body Molding Art book or a body master) unlocks 9 and closes qi. Body stages compare to qi realms via `realm_equivalent()` (1-2, 3-4, 5-6, 7-9) in `cultivation_realm_of` |
| `body/body_techniques.dm` | Body techniques (stamina + food, no antimagic): Forge the Body, Tribulation of Flesh (stage ordeal), Iron Shirt, Mountain Leap, Shattering Fist, Bone Setting, Remold Limb, Blood Boil, Vajra Golden Body, Primordial Roar, Accept Body Disciple, and the Body Molding panel |
| `body/body_martial.dm` | The big wuxia moves, all shouted: Earth-Shattering Stomp, Hundred Fist Barrage, Raging Bull Charge (smashes windows/tables, plain walls from stage 6), Falling Mountain Descent (leap + crater), Mountain-Toppling Throw (hurl a grabbed person), Sky-Splitting Palm (line shockwave), Heaven-Shaking Quake. Shared helpers: `body_art_hit` (higher realms brace), `body_art_smash`, `body_art_crack_ground` (breaks floor tiles, crater) |
| `body/body_martial.dm` (scaling) | Every martial art scales with stage (`body_art_stage`). `body_art_wall_tier`: plain walls from stage 6, reinforced from 8 (Shattering Fist has its own, 4 and 7). `body_art_shatter_line` carves a trench (length, half width, wall tier) used by Shattering Fist, Hundred Fists, Sky-Splitting Palm and arm-9 punches. `body_art_smash` breaks doors too (blast doors at the reinforced tier). Stage 9 is deliberately a station destroyer: it can and will breach into space |
| `body/body_items.dm` | Copper Skin Primer (anyone, mortal tier) and the Body Molding Art (commits). Body Tempering Pills give body cultivators tempering and +20 tribulation readiness |
| `wuxia/sect_missions.dm` | Sect missions (pills, duels, harvest, meditate at plaque, recruit, heart demons), and Martial Tournaments proclaimed by a Sect Master at the plaque (10 min, double duel face, Martial Champion) |

Defines: `surfshack13/code/__DEFINES/cultivation.dm`. The only core edits: `ORGAN_SLOT_DANTIAN` in `code/__DEFINES/DNA.dm` (marked Surf Shack Edit) and 25 lines appended to `strings/tips.txt` (Confucius quotes + cultivation tips).

Icons: `surfshack13/icons/cultivation/` (actions, hud, items, artifacts, effects 32/64/96, riding, terrain, particles, dharma_idol).

## Key numbers (for balance passes)

- Realm thresholds (consolidated insight): 60 / 150 / 300. Max qi 50 / 100 / 175 / 275. Pending insight cap 60.
- Qi path is the faster, easier path: thresholds 60/150/300, Ascension 400. It scales into utility and speed rather than raw damage: cooldowns 100/85/70/55% by realm, Light Body move speed +6% per realm, Qinggong 4 + 2 per realm tiles, Void Step 6 + 2 per realm past Golden Core, max qi 60/130/230/360, qi regen 0.25 + 0.1*realm per second, qi body 5/10/15% less brute and burn from Foundation, and only a modest Qi Power damage bump (1.0/1.1/1.2/1.3x via `cultivation_qi_power`). Stage-9 body cultivation is deliberately stronger in a fight. Law slots = realm (Nascent Soul: all 5).
- Sword Qi: 22 + 4/realm, range 12, speed 2.5, sever 10% + 5%/realm. Flying Sword cap 20 + 4/realm, blades sever 8% + 4%/realm.
- Buddha's Palm 45 centre / 20 shockwave; Sword Formation 12/s within 2 tiles; Sea of Flames 22/30/38 per wave over 6 tiles.
- Golden Core crit sustain 1.5 brute+burn/s (x2 Nascent Soul), Nascent Soul revival every 10 minutes.
- Artifact refinement: grade n needs 5 + 5n points (Mortal, Spirit, Earth, Heaven, Immortal, Dao). +1 per meditation cycle carrying it; cauldron tempering: silver 1, gold/plasma 2, diamond/bluespace 4 per sheet (max 5 sheets each). Each grade: +1 flight force and cap +2, +2% sever, +1 recall range.
- Ascension: 400 consolidated insight past Nascent Soul peak. 60s tribulation, 14 strikes of 14, heart demon at 20s. Success leaves the round; failure halves progress, +60 instability, cracks the core, 40 burn.
- Body path: 9 powers for each of 10 body part types (`GLOB.body_part_powers`): head (will), chest (torso hide), arms, legs, and the inner organs eyes, ears, heart, lungs, liver, stomach (`GLOB.body_tempered_organs`, tempering is a component on the organ). Arms and legs count the weaker of the pair, strike powers (arm 5-9) use the punching arm. The Tribulation of Flesh needs every limb AND organ forged past the stage, so a missing organ blocks it. Part level n costs 2 + n tempering (12 parts to level 9 is about 750). Pending cap 120. Training: gym +15/10s (starts mortals), fighting +6/15s, punching walls/bags +10/15s, taking 5+ brute/burn +5/15s, mining +8/30s, passive +1/10s, Body Tempering Pill +30. Forge cycles are 5s and pour 25. Tribulation of Flesh lasts 10 + 2*stage s. Body arts cost exhaustion (0-100, own resource, recovers 3 + 0.4*stage per second, +1 heart 3, +1 lungs 6) shown on a HUD meter (`/atom/movable/screen/body_display`, filling ring) and in the panel's technique list. Every punch adds stage + arm/2 damage and shortens the melee cooldown by stage/2 deciseconds; every stage adds 4% move speed; body art cooldowns shrink 5% per stage. Target: about 30-40 minutes of focused play from untrained to stage 9.
- Spirit beast evolutions: Beast Awakening Pill, master Foundation for Awakened (regen 0.5/s), Golden Core for Divine (regen 1/s, 25% knockdown bites). Health x1.5 per stage.

## Art pipeline

Scripts in `tools/cultivation_art/` (Python + Pillow; Chinese glyphs need a CJK font, on Linux `apt install fonts-noto-cjk`). Run from the repo root, in this order, because later scripts overwrite states earlier ones made:

1. `make_art_v2.py` (needs env `PREVIEW=<png path>`): action medallions, animated HUD orb, particles, 96px effects (storm, sigils), first pass of 64px effects
2. `make_effects32.py`: orbit sword, sword qi crescent + impact, thorn sword + splinters
3. `make_pixel_gold.py`: Golden Bell, Buddha's Palm (+ shadow), Dharma Idol (keeps water bubble / void rift)
4. `make_pixel_fx.py`: vines, mud, molten footprints, sword riding platform and qi cloud
5. `make_pixel_items.py`: all items (mat, manual, ring, dantian, golden core, needles, dagger, pellets, plaque, seal, pills) and first pass of artifacts
6. `make_artifacts_hd.py`: gourd, fan, mirror, pouch, needle (drawn at 256px, downscaled, re-sharpened, crisp alpha + outline)
7. `make_weapons_native.py`: swords and staff, hand-placed pixels in tg's weapon style (replaces only those states)
8. `make_backlog_art.py` (optional env `PREVIEW=<png path>`): demonic medallions + Ascension, per-law manual covers, demonic scripture, per-type talismans, cauldron (+ lit animation), guqin, new pills, heart demon and beast auras, decree scroll. It MERGES into the existing DMIs (only touches its own states), so it is safe to run on its own.

Lessons: long thin diagonals (weapons) must be native pixel art in tg's style (corner to corner, solid shaded rows, no black outline). On a 45 degree line, offsets `(1,0)` and `(0,1)` are the same row (row index = dx + dy). Chunky objects look great drawn large and downscaled, then re-sharpened. Keep glows as a separate soft layer, small and subtle.

## Not yet tested in game

Everything in the backlog batch (demonic path, heart demons, cauldron, refinement, guqin, beast evolution, Ascension, sect missions, tournaments, new sounds and animations) was built in a cloud session without BYOND: it passes `dreamchecker` and `check_grep.sh`, and the unit test was extended, but none of it has been compiled with DreamMaker or run. Build and run the unit tests first.

Everything since the second commit has only been compiled and unit tested, with the user spot-checking. Especially worth real testing: Mandate withdrawal/seal claim, honor duels and sects with two clients, spirit beast pet commands on non-pet mobs and monkeys, purple-gold gourd, Heaven Reliant wall carving, Nascent Soul revival, Golden Core crit sustain, Sword Riding platform visuals, formation barrier pathing.

## Backlog: what the user wants next

The user's standing direction is "keep improving: sprites, animations, sounds, gameplay loops, polish, fun". The forbidden arts were decided as: antagonist only, but a master can teach them to others (who can't teach on).

- **Sprites still borrowed or first pass**: proper inhand sprites for legendary artifacts (still tg inhands; need 4-dir left/right sheets drawn by hand in tg style), HD sect plaque and jade seal, the corpse puppet and heart demon use their victim's/host's appearance (tinted), which is intentional.
- **Balance**: everything is first-pass numbers; adjust from playtest feedback. Watch the demonic arts (Devouring Art husks corpses, Soul Search reveals antag status) and the Ascension threshold.
- **Ideas not yet built**: Heart demons you can fight during Ascension (currently endured while seated), more sect mission types, spirit beast element breaths at Divine, guqin songs with specific effects.
