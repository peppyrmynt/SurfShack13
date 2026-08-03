# SurfShack13 Custom Feature Backlog

## Localized Catastrophic Trauma

- **Status:** in-progress
- **Branch:** `agent/feature-localized-catastrophic-trauma`
- **Pull request:** #12
- **Mode:** Hyper Adrenaline only

### Intended gameplay behavior

Hyper Adrenaline attacks may cause localized catastrophic injuries without adding any new full-body gib paths. Existing established gib mechanics remain unchanged.

### Outcomes

- **Brain ejection:** 55 final post-armor damage plus a critical non-burn head wound. The installed brain is removed intact and remains recoverable. A 50/50 presentation either removes the head or leaves it attached with the existing debrained cavity presentation. Both variants produce a heavy bounded blood/tissue burst. Base chance 10%, scaling by one percentage point per damage above threshold, capped at 40%.
- **Disembowelment:** 55 final post-armor slash or pierce damage plus a critical chest wound. Reuses existing chest dismemberment to spill only currently installed chest-zone organs. No intestines organ or replacement anatomy is added. Base chance 15%, scaling to 40%.
- **Sharp limb severing:** 40 final post-armor slash damage plus a critical wound. Base chance 10%, scaling to 40%.
- **Blunt limb destruction:** 50 final post-armor blunt damage plus a critical wound. Base chance 10%, scaling to 40%.
- **Ballistic/piercing limb destruction:** 50 final post-armor pierce damage plus a critical wound. Base chance 10%, scaling to 40%.
- **Curbstomp:** An unarmed shoe-wearing humanoid attacker has a 25% chance to execute a critical or dead target that still has an attached head and installed brain. The event uses a bold combat message, heavy blood, and intact brain ejection.

### Eligible targets and damage sources

Eligibility is based on carbon bodyparts and installed organs, not sentience, `mind`, `client`, or species-name checks. NPC monkeys and other non-sentient full-anatomy carbons are eligible; basic/simple mobs are excluded.

The evaluator is attached to finalized bodypart wound damage, so qualifying melee, projectile, explosion, thrown-debris, and high-speed collision damage share the same rules where those sources produce wounds. Existing full-gib explosions and special mechanics are not intercepted.

### Invariants

- Existing full-gib mechanics remain unchanged.
- This feature introduces no new whole-body gib path.
- Only existing installed organs and bodyparts are moved or removed.
- The brain remains intact and recoverable.
- No generic single-organ ejection.
- Lungs remain one installed lungs object.
- A one-decisecond per-target guard deduplicates pellet clouds and immediate same-impact event chains; it is not player-facing immunity.
- Blood/tissue production is bounded.

### Current implementation state

The complete reviewed source diff is stored in `localized-catastrophic-trauma.patch` and covers:

- `code/__DEFINES/combat.dm`
- `code/modules/mob/living/carbon/carbon_defines.dm`
- `code/modules/surgery/bodyparts/_bodyparts.dm`
- `code/modules/surgery/bodyparts/wounds.dm`
- `code/modules/mob/living/carbon/human/_species.dm`

A direct-source application was attempted through a temporary GitHub Actions workflow, but the workflow did not execute when created through the connected GitHub app. The temporary workflow and probe file were removed. The branch still requires the patch to be applied in a writable checkout before it is merge-ready.

### Validation requirements

- Apply the patch to the branch source files and remove the patch artifact.
- Compile DreamMaker and run relevant tests/CI.
- Verify normal rounds bypass the evaluator.
- Verify thresholds, critical-wound gates, and the 40% cap.
- Verify no duplicate organs or repeated outcomes from pellet/explosion chains.
- Verify humans, monkeys, lizards, and a non-blood humanoid species.
- Verify brain reimplantation/revival.
- Verify existing full-body gib behavior is unchanged.
- Verify curbstomp on both critical and dead targets.
