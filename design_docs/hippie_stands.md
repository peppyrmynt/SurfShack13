# Hippie Stand port

Base: Pepper SurfShack13 `7361563c91d8db1ef055f561e283a9b7a0504c67`.
Source: HippieStation/HippieStationdeprecated2020, `hippiestation/code/modules/guardian/`.

## Architecture

The arrow extends the current guardian creator and calls its `spawn_guardian`, which
uses `set_summoner`, `PossessByPlayer`, mind enslavement and the native life-link,
leash, HUD and summoner actions. Every arrow-created Stand uses a neutral modern
Guardian shell; an arrow-only component owns its randomized stats and Stand powers.
Existing guardian creators and stock guardian balance are unchanged.

All nine normal majors were audited: Assassin (4 points, weight 171), Explosive (4),
Frenzy (3), Gravity (3), The Hand (5), Healing (4, weight 209), Predator (2),
Scout (1), Time Erasure (6, weight 80). Other normal weights are 190. Integer weights total 1600, giving Time Erasure exactly 5% of normal power rolls while preserving the relative odds of the other powers.
The two minors are Surveillance Snares and Teleportation Pad. The three Requiem
specials are Time Stop, Dimensional Manifestation and Absolution.

The five stats start at 1, cap at 5, and receive 15 minus major-cost extra points.
Melee damage is 5–25, object damage 16–80, attack interval 2.25–0.45 seconds,
range 2–10 tiles, damage transfer coefficient 1–.25. Potential scales powers.
Guardian infinite health is retained: damage still transfers through life_link.

Normal and Requiem Stand abilities are implemented on the neutral arrow Stand with
modern cooldown actions, components and statuses. No normal SurfShack Guardian type
is randomly selected by the Stand Arrow, and no old guardian mob, verb framework or
spell-holder framework is restored.

Arrow-created Stand controllers are permanent. The normal `Reset Guardian
Consciousness` action filters them out and cannot poll a replacement ghost for them.

## Requiem

Stabbing an eligible arrow-created Stand starts a 50-second Requiem transformation.
On completion the normal major ability is removed, each of the five stats gains 1–3
points up to the normal cap of 5, and one of three Requiem specials is selected:

- Time Stop: freezes a localized area for 10 seconds while the Stand, its summoner
  and allied linked Stands remain immune. Cooldown: 50 seconds.
- Dimensional Manifestation: moves the Stand, summoner and linked allied Stands to
  or from a private pocket dimension. Cooldown: 45 seconds. The moved group receives
  death/crit/damage protection while inside the pocket dimension.
- Absolution: while the Requiem Stand is manifested, its summoner receives godmode
  and no-breath protection. The protection is removed when the Stand recalls.

Every Requiem Stand also receives Surveillance Snares and Teleportation Pad. The
Stand is renamed with the `Requiem` suffix and both Stand and summoner receive an
explicit message identifying the rolled Requiem special after transformation.

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
`hippiestation/icons/mob/inhands/{lefthand,righthand}.dmi`. Stand-specific Hippie
sounds used by The Hand, Frenzy and Time Erasure are retained at their historical
volume/positional behavior, with old `world.view` ranges translated to SurfShack's
modern sound API. Other unrelated assets are not imported. Existing SurfShack
Guardian and HUD resources are reused. Source repository licensing/attribution
applies; see its LICENSE and git history.

## Validation / progress

DreamChecker, OpenDream, Windows/BYOND compilation, map checks and all-map compile
have passed for the Stand implementation. A previous full CI run was red only because
the NebulaStation integration test produced existing lightning-thrower/overcharged
SMES signal runtimes; the Stand and changelog checks themselves passed.
