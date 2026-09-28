# SurfShack13 Restoration Backlog

This document is the authoritative tracker for current-code restorations of behavior removed or changed by merged `/tg/station` pull requests.

## Cloning machinery

| Field | Value |
| --- | --- |
| Status | `in-progress` |
| Source repository | `tgstation/tgstation` |
| Source pull request | `tgstation/tgstation#48668` — **Completely removes cloning** |
| Source merge commit | `a28b24f149702527f3eb22f5c686f06c836f2f99` |
| Implementation branch | `agent/restore-cloning-upstream` |
| Pull request | `peppyrmynt/SurfShack13#372` |
| Review mirror branch | `agent/readd-cloning-final` |
| Review mirror pull request | `Ixde969-hub/SurfShack13#6` |

### Historical behavior restored

- Living crew can be scanned into persistent cloning records before death.
- A stored record becomes usable after its associated mind no longer has a living body.
- A cloning pod grows a replacement organic body and transfers the original mind into it.
- The clone matures over time, with emergency early ejection retaining unfinished growth trauma.
- Cloning machinery can be constructed through researched console and machine boards.

### Current-code implementation

- Uses the current DNA scanner, mind, DNA, species, machinery, stock-part, trait, power, and research APIs rather than reverting the historical removal commit.
- Preserves copied DNA/species, character name, underwear selections, factions, and mind-bound state.
- Rejects invalid, robotic, dead-at-scan, mindless, or unusable-DNA subjects.
- Prevents duplicate cloning and deletion or replacement of records while a pod cycle is active.
- Protects an immature clone while contained and clears temporary maturation traits on every exit or destruction path.
- Reuses the retained `icons/obj/machines/cloning.dmi` assets: `pod_0` while empty and the animated `pod_g` state while growing a clone.

### Automated coverage

The cloning round-trip unit test checks record capture, living/dead eligibility, species preservation, body creation, mind transfer, duplicate prevention, maturation protection, healing, ejection, trait cleanup, required DMI state availability, and empty/occupied sprite transitions.

### Validation

- Full fork CI passed for the implementation before the sprite correction on commit `8f594d04db6b22f631f55c9740ce6f0253ca49e8`.
- The corrected sprite implementation and regression assertions passed the complete CI Suite in fork workflow run `30793347520`, including linters, DreamChecker, OpenDream, DMI checks, all-map compilation, Windows and BYOND builds, alternate tests, all station integration-test configurations, screenshot comparison, and the completion gate.
- Upstream workflow run `30793601304` is awaiting external-contributor approval and did not start jobs. This is an upstream permission gate rather than a test failure.

### Limitations and completion criteria

- The feature is constructible through research; this change does not add round-start cloning machinery to station maps.
- Status remains `in-progress` until `peppyrmynt/SurfShack13#372` is reviewed and merged into the authoritative branch.
