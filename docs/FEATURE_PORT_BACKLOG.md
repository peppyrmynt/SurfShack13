# External Feature Port Backlog

## 7TV image emotes

- **Status:** in-progress
- **Source repository:** `tgstation/tgstation`
- **Source reference:** closed-unmerged PR #90372, stable head commit `d72fcf2177c44000b350ab4a519b3b937513ff8c`
- **Original author:** `mcbalaam`
- **Implementation branch:** `agent/port-7tv-emotes`
- **Source license:** GNU Affero General Public License v3.0, matching the codebase lineage.
- **Assets and provenance:** `icons/mob/human/aprilfools_emotes.dmi` and seven OGG files under `sound/effects/aprilfools/`, copied from the source commit above.
- **Historical behavior:** twelve human emotes (`hmm`, `clueless`, `reallymad`, `lmao`, `zorp`, `uncanny`, `xdd`, `noway`, `taa`, `tuh`, `jokerge`, and `fuckingdies`) display an overhead image and selected emotes play audio.
- **SurfShack13 differences:**
  - normal `deathgasp` behavior is preserved; `fuckingdies` is manual only;
  - the current global overlay helper is used for the three-second overhead image;
  - the current emote-help implementation automatically lists usable emotes and bolds those with playable audio.
- **Dependencies:** current human emote registration, global overlay helpers, and the emote audio cooldown system.
- **Validation:** pending CI compile, DMI/sound checks, invocation checks, help-list visibility, bold audio-emote display, three-second overlay lifetime, and cooldown behavior.
- **Pull request:** pending.
- **Limitations:** manual in-game audio and visual verification remains required after CI.
