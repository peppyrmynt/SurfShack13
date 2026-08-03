# SurfShack13 Custom Feature Backlog

## Localized Catastrophic Trauma

- **Status:** in-progress
- **Branch:** `agent/feature-localized-catastrophic-trauma`
- **Pull request:** #12
- **Mode:** Hyper Adrenaline only

### Intended gameplay behavior

Hyper Adrenaline attacks may cause localized catastrophic injuries without ever full-gibbing a humanoid/playable character.

The first implemented slice enables the repository's existing chest dismemberment/disembowelment path on living victims. A qualifying hit uses the existing open-torso presentation and ejects the victim's actual installed chest-zone organs while leaving the body present.

### Current implemented outcome: living disembowelment

- Requires slash or pierce wounding.
- Requires at least 55 final post-armor damage after the global Hyper Adrenaline multiplier.
- Requires an existing critical exterior-mangling chest wound.
- Starts at 15% chance at threshold.
- Gains one percentage point per damage above threshold.
- Caps at 40%.
- Uses the existing `/obj/item/bodypart/chest/dismember()` implementation.
- Removes only organs currently installed in the victim's chest bodypart.
- Does not add an intestines organ or spawn replacement organs.
- Preserves existing corpse and cursed-target behavior.

### Planned outcomes

1. **Brain ejection**
   - A qualifying critical head wound may eject the victim's existing brain organ intact.
   - The brain must remain recoverable and suitable for revival under normal organ/revival rules.
   - The body remains present and receives a bounded blood/tissue spray.

2. **Localized limb destruction**
   - Qualifying critical wounds may sever/destroy only the struck limb.
   - The whole humanoid must never gib from this feature.

### Species scope

Use carbon/humanoid anatomy and installed organ/bodypart data rather than species-name checks. This must support humans, monkeys, lizards, moths, plasmamen, and other playable humanoid races where the required anatomy exists. Species-specific fluids/effects should be reused.

### Configurable values

All damage values are final post-armor values after Hyper Adrenaline's global 2x damage multiplier.

| Outcome | Damage threshold | Wound requirement | Chance at threshold | Maximum chance |
|---|---:|---|---:|---:|
| Sharp limb severing | 40 | critical slash | 10% | 40% |
| Blunt limb destruction | 50 | critical blunt | 10% | 40% |
| Ballistic limb destruction | 50 | critical ballistic/pierce equivalent | 15% | 40% |
| Disembowelment | 55 | critical slash or pierce, chest | 15% | 40% |
| Brain ejection | 55 | critical qualifying head wound | 10% | 40% |

Chance scales by one percentage point per final post-armor damage above the threshold, capped at 40%.

### Required invariants

- Never spawn replacement organs as trauma debris.
- Only detach the victim's currently installed organ/bodypart object.
- If the relevant anatomy is already missing, the outcome cannot produce it again.
- No generic or random single-organ ejection.
- Lungs remain the existing single lungs organ object.
- At most one catastrophic trauma outcome per completed attack context.
- Pellet clouds and multi-hit projectiles must aggregate or share a processed flag so one attack cannot trigger repeatedly.
- The brain must not be damaged or deleted by the ejection effect.
- No full-body gibbing.

### Performance requirements

- One early Hyper Adrenaline guard before anatomy work.
- Evaluate only after finalized post-armor damage/wound generation.
- Reuse calculated damage, hit zone, wound type, and wound severity.
- Hard-cap spawned blood/tissue effects.
- Reuse installed bodypart/organ collections instead of creating anatomy.

### Administrator controls

The initial implementation uses compile-time threshold/chance defines and the existing damage multiplier config as the Hyper Adrenaline gate. Dedicated runtime controls can be added after playtesting.

### Testing requirements

- Verify normal damage multiplier values cannot disembowel living targets.
- Verify 54 final damage cannot qualify.
- Verify 55 final damage begins at 15%.
- Verify probability never exceeds 40%.
- Verify blunt and burn attacks cannot qualify.
- Verify a critical exterior-mangling chest wound is mandatory.
- Verify humans, monkeys, lizards, and other organ-bearing playable carbon species use their existing anatomy.
- Verify each installed chest organ is removed at most once.
- Verify already-missing organs do not respawn.
- Verify corpse and cursed-target behavior remains unchanged.
- Verify the body remains and no full-body gib occurs.
- Compile DreamMaker and run relevant unit tests.

### Validation status

- Existing chest dismemberment code inspected from the uploaded authoritative source archive.
- Confirmed that it already removes actual installed chest-zone organs and uses the existing disembowelment presentation.
- Exact current-code implementation patch committed to the feature branch as `localized-catastrophic-trauma.patch`.
- DreamMaker compile and gameplay validation remain pending because BYOND tooling is unavailable in the current runtime.
