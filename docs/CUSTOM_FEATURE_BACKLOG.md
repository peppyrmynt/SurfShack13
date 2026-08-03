# SurfShack13 Custom Feature Backlog

## Localized Catastrophic Trauma

- **Status:** blocked
- **Branch:** `agent/feature-localized-catastrophic-trauma`
- **Pull request:** pending
- **Mode:** Hyper Adrenaline only

### Intended gameplay behavior

Hyper Adrenaline attacks may cause localized catastrophic injuries without ever full-gibbing a humanoid/playable character.

Supported initial outcomes:

1. **Brain ejection**
   - A qualifying critical head wound may eject the victim's existing brain organ intact.
   - The brain must remain recoverable and suitable for revival under normal organ/revival rules.
   - The body remains present and receives a bounded blood/tissue spray.

2. **Disembowelment**
   - A qualifying critical slash or pierce wound to the torso may eject the victim's existing intestines organ/species-equivalent while the victim may remain alive.
   - No other internal organ is randomly ejected.

3. **Localized limb destruction**
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
| Disembowelment | 55 | critical slash or pierce, torso | 15% | 40% |
| Brain ejection | 55 | critical qualifying head wound | 10% | 40% |

Chance scales by one percentage point per final post-armor damage above the threshold, capped at 40%.

### Required invariants

- Never spawn replacement organs as trauma debris.
- Only detach the victim's currently installed organ/bodypart object.
- If the relevant organ slot is empty, the outcome cannot trigger.
- No generic or random single-organ ejection.
- Lungs are one installed lungs organ/slot in this codebase; do not model left/right lungs.
- At most one catastrophic trauma outcome per completed attack context.
- Pellet clouds and multi-hit projectiles must aggregate or share a processed flag so one attack cannot trigger repeatedly.
- The brain must not be damaged or deleted by the ejection effect.
- No full-body gibbing.

### Performance requirements

- One early Hyper Adrenaline/global feature-flag guard before anatomy work.
- Evaluate only after finalized damage/wound generation.
- Reuse calculated damage, hit zone, wound type, and wound severity.
- Hard-cap spawned blood/tissue effects.
- Do not scan every organ when a known slot can be queried.

### Administrator controls

- Enable/disable the whole feature.
- Per-outcome enable switches.
- Threshold, base chance, scaling, and 40% cap configuration.
- Combat logging for brain ejection and living disembowelment.

### Testing requirements

- Verify normal/non-Hyper-Adrenaline combat bypasses all trauma work.
- Verify threshold and wound gates independently.
- Verify chance never exceeds 40%.
- Verify an empty brain/intestines slot cannot produce an item.
- Verify repeated attacks cannot produce duplicate organs.
- Verify pellet clouds process once per attack context.
- Verify humans, monkeys, lizards, and at least one non-blood humanoid species.
- Verify brain remains intact and reimplantable/revivable.
- Verify no supported attack full-gibs the humanoid.
- Compile DreamMaker and run relevant unit tests.

### Compatibility investigation

The current wound pipeline applies/promotes a wound in `code/modules/surgery/bodyparts/wounds.dm`, which is the intended finalized-event hook. The implementation must preserve current dismemberment and wound competition behavior.

### Blocker

Implementation is blocked until the exact current installed-intestines organ slot/type and safe organ-removal/ejection helper are verified in SurfShack13, and a DreamMaker compile environment is available. The connected repository interface confirmed the wound pipeline but did not expose a verified intestines source path. Committing guessed organ APIs would risk compilation failure or duplicate anatomy.
