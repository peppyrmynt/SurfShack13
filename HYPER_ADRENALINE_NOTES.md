# Hyper Adrenaline

This branch contains an apply-ready unified patch for the requested gameplay overhaul.

## Included changes

- Global damage and healing: 2x through `DAMAGE_MULTIPLIER`
- Shared `do_after` action-bar duration: 0.5x
- Chemical processing and effect speed: 2x
- Explosion devastation, heavy, light, flame, and flash ranges: 2x
- Thrown-object `throwforce`: 2x
- Thrown/projectile embedding chance: 2x, capped at 100% before armor adjustment
- Shared wound-generation potential: 2x

## Intentionally unchanged

- Maximum health
- Default walking and running speed
- Individual melee and projectile damage values, because global damage scaling already doubles their resulting damage

## Applying the patch

From the repository root:

```bash
git apply hyper-adrenaline.patch
```

## Validation status

The patch was built against the current fork `master` source. A DreamMaker compile was not available in the connected runtime. The pull request is therefore left as a draft and should be compiled and play-tested before merge.
