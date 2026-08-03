# SurfShack13 Custom Feature Backlog

## Localized Catastrophic Trauma

- **Status:** in-progress
- **Branch:** `agent/feature-localized-catastrophic-trauma`
- **Pull request:** #12
- **Mode:** Hyper Adrenaline only

### Implemented source patch

The current implementation is recorded in `localized-catastrophic-trauma.patch`, built against the uploaded authoritative `master` archive.

It adds a unified critical-wound evaluator for carbon mobs with full bodypart anatomy. Sentience, `mind`, and `client` are not requirements, so NPC monkeys and other non-sentient carbons are eligible. Simple/basic mobs are excluded naturally because they do not use the carbon bodypart framework.

### Outcomes

- **Brain ejection:** 55 final post-armor damage plus a critical head wound. The installed brain is removed intact and thrown behind the victim. A 50/50 presentation either destroys the head entirely or leaves the head attached with a blown-out skull cavity. Both variants create a heavy bounded blood/giblet burst. Base chance 10%, scaling +1 percentage point per damage above threshold, capped at 40%.
- **Disembowelment:** 55 final post-armor slash or pierce damage plus a critical chest wound. Reuses the existing chest dismemberment code to remove every currently installed chest-zone organ. No organs are spawned and no intestines organ is added. Base chance 15%, scaling to 40%.
- **Sharp limb severing:** 40 final post-armor slash damage plus a critical wound. Base chance 10%, scaling to 40%.
- **Blunt limb destruction:** 50 final post-armor blunt damage plus a critical wound. Base chance 10%, scaling to 40%.
- **Ballistic/piercing limb destruction:** 50 final post-armor pierce damage plus a critical wound. Base chance 15%, scaling to 40%.
- **Curbstomp:** A human attacker making an unarmed attack while wearing shoes has a 25% chance to brutally curbstomp a target already in soft critical, hard critical, or dead state. The target must still have an attached head and installed brain. The head is destroyed, the brain is ejected intact, and a bold combat message is shown.

### Source coverage

The evaluator runs from the common wound pipeline, so qualifying critical wounds caused by melee, projectiles, explosion damage, high-speed thrown debris, and collision/throw impacts use the same rules where those sources already generate wounds.

### Invariants

- Existing full-gib mechanics remain unchanged.
- This feature introduces no new whole-body gib path.
- Only existing installed organs and bodyparts are moved or removed.
- The brain remains intact and recoverable.
- No generic single-organ ejection.
- Lungs remain one installed lungs object.
- A one-second per-target guard prevents pellet clouds and same-tick multi-hits from producing multiple catastrophic outcomes.
- Blood/giblet production is bounded.

### Validation

- Source paths and relevant existing APIs were verified against the uploaded authoritative repository archive.
- Static source inspection completed.
- DreamMaker compile and runtime tests are pending because BYOND tooling is unavailable in this environment.
- The PR must remain draft until the patch is applied to the branch source files and compiled.
