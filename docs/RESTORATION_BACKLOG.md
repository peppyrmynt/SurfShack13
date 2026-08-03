# /tg/station Restoration Backlog

This document is the authoritative tracker for restorations of behavior changed by merged `tgstation/tgstation` pull requests.

## Status definitions

`candidate`, `reviewing`, `approved`, `in-progress`, `blocked`, `completed`, `declined`, and `superseded`.

## Restorations

| ID | Feature | Source | Status | Branch | Pull request | Validation | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TG-55663 | Cheap printable shotgun ammunition | Merged [`tgstation/tgstation#55663`](https://github.com/tgstation/tgstation/pull/55663), merge commit `ab3c0e033274630cc682fa8dd9437efb6bd80369` | in-progress | `agent/restore-cheap-shotgun-ammo` | Draft [`#8`](https://github.com/Ixde969-hub/SurfShack13/pull/8) | Source and compile-order inspection completed. DreamMaker compile and gameplay testing not available in the connected runtime. | Restores slug and buckshot recipes to all supported lathes at the historical two-sheet unit cost. Seven-shell slug and buckshot boxes cost fourteen sheets. Existing SurfShack13 restorations of 50-damage slugs, buckshot-loaded combat shotguns, and the faster riot-shotgun delay are preserved. The historical pulse-shotgun projectile no longer exists in the current code and is not recreated. |
