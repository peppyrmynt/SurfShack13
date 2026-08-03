# /tg/station Restoration Backlog

## 7TV April Fools emotes

- **Status:** blocked
- **Source:** tgstation/tgstation#90372 (`[April Fools] :clueless:`), merged April 2025
- **Implementation branch:** `agent/restore-7tv-emotes`
- **Historical behavior:** Adds twelve 7TV-inspired human emotes with overhead image bubbles and optional sound effects: `hmm`, `clueless`, `reallymad`, `lmao`, `zorp`, `uncanny`, `xdd`, `noway`, `taa`, `tuh`, `jokerge`, and `fuckingdies`.
- **SurfShack13 requirements:**
  - Port the implementation to the current human emote architecture rather than blindly reverting historical files.
  - Bring over the source DMI and all associated OGG assets with provenance preserved.
  - Ensure every emote appears in the emote help list.
  - Render sound-producing emotes in bold in that help list.
  - Preserve the normal death-gasp path; do not globally replace `deathgasp` with `fuckingdies`.
  - Retain the historical one-minute audio cooldown unless testing identifies a compatibility problem.
- **Source assets:** `icons/mob/human/aprilfools_emotes.dmi` and files under `sound/effects/aprilfools/` from tgstation/tgstation#90372.
- **License/attribution:** Same upstream repository and license lineage as SurfShack13; retain identifiable source authorship in the pull request and changelog.
- **Validation required:** DreamMaker compile, emote invocation tests, help-list visibility check, bold sound-emote formatting check, bubble lifetime check, and sound playback/cooldown check.
- **Blocker:** The connected execution environment cannot clone GitHub or upload the required binary DMI/OGG assets, and GitHub CLI is unavailable. Do not open a code PR until the assets and implementation can be committed and compiled together.
