# Hippie Stand port

Base: Pepper SurfShack13 `7361563c91d8db1ef055f561e283a9b7a0504c67`.
Source: HippieStation/HippieStationdeprecated2020, `hippiestation/code/modules/guardian/`.

## Architecture

The arrow extends the current guardian creator and calls its `spawn_guardian`, which
uses `set_summoner`, `PossessByPlayer`, mind enslavement and the native life-link,
leash, HUD and summoner actions. An arrow-only component owns randomized stats.
Existing guardian creators and stock guardian balance are unchanged.

All nine normal majors were audited: Assassin (4 points, weight .9), Explosive (4),
Frenzy (3), Gravity (3), The Hand (5), Healing (4, weight 1.1), Predator (2),
Scout (1), Time Erasure (6, weight .2). Other weights are 1.
The two minors are Surveillance Snares and Teleportation Pad. The three later
specials are Time Stop, Dimensional Manifestation and Absolution.

The five stats start at 1, cap at 5, and receive 15 minus major-cost extra points.
Melee damage is 5–25, object damage 16–80, attack interval 2.25–0.45 seconds,
range 2–10 tiles, damage transfer coefficient 1–.25. Potential scales powers.
Guardian infinite health is retained: damage still transfers through life_link.

Native Assassin, Explosive, Gravitokinetic and Support provide the corresponding
powers. Additional powers use modern cooldown actions, components and statuses.
No old guardian mob, verb framework or spell-holder framework is restored.

## Historical decisions

- `b25d0579da93872e0605f5ba72d183fca56932bd` introduced rare-arrow meteors.
  Final Hippie master drops the standard arrow instead; use that later behavior
  so meteor acquisition does not skip Requiem progression.
- Meteor starting weights: normal .05, threatening .05, catastrophic .075.
- PR #11955 added the arrow to Summon Magic. Both the modern distribution pool
  and the objective type list must include it.
- PR #12623 (`ceea5cbf8b`) disabled the Mysterious Attic; its parent defines
  `guardian-arrow`, cost 20 and a Powerful Signal display case. Restore that
  map with modern paths, without the historical 1% duplicate-ruin exception.
- Failed ghost polls release the arrow without spending a use, rather than
  retrying forever. Every asynchronous boundary revalidates its participants.
- Requiem replaces the normal major and consumes the arrow. The final old code
  called `TakeMinorAbility` (removal), despite the progression's minor-ability
  concept. This port follows the requested design and grants both minors.

## Assets and attribution

Arrow item and left/right in-hand states are extracted from HippieStation's
`hippiestation/icons/obj/items_and_weapons.dmi` and
`hippiestation/icons/mob/inhands/{lefthand,righthand}.dmi`. Other unrelated states
are not imported. Existing SurfShack Guardian and HUD resources are reused.
Source repository licensing/attribution applies; see its LICENSE and git history.

## Validation / progress

Incremental implementation in progress. Stage 1: arrow, native ghost creation,
random stats and four native ability adapters. DreamChecker: 0 diagnostics.
BYOND compile and the remaining milestones are pending. This is not yet ready
for gameplay acceptance or merge.
