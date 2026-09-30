# Restricted HoS stun mode

The fourth mode uses the existing electrode projectile without changing its effects.
A full stock HoS cell contains 12,000 charge; LASER_SHOTS(3, 12,000) costs 4,000 per shot.
The other three modes retain their original casings and costs.

Authorization requires a human with an assigned-role job datum titled Head of Security,
a name-matching crew manifest record with rank Head of Security, a mindshield, and
the ID returned by get_idcard(TRUE). That card must have ACCESS_HOS, assignment
Head of Security, and the operator's real name. Agent/chameleon cards are rejected.
A held ID takes precedence according to the existing get_idcard implementation.

Denied selection skips stun and wraps to disabler. A transferred gun may remain set
to stun, but process_fire checks credentials again before the parent firing code,
including direct calls from dual wielding. It checks both selected and chambered ammo.
There is no emag or EMP exemption. EMP can still affect the gun normally.

Acting Captain status alone grants nothing. A promoted HoS qualifies only when their
mind's assigned role, manifest rank, ID details and mindshield all satisfy the checks.
An admin-spawned HoS without a matching manifest record is denied. Renaming without
updating the manifest and ID is denied. Cyborgs and AIs are always denied stun.
The sprite uses existing nonlethal overlays for the new mode.

## Verification on 2026-09-30

- tools/ci/check_grep.sh: passed.
- Dreamchecker: zero diagnostics.
- git diff --check: passed.
- BYOND build: not run; neither the requested Windows dm.exe nor a Linux DreamMaker
  executable is available in this environment.
- In-game verification: not performed; no running BYOND test server is available.

## Required in-game checks before merging

1. Spawn a human HoS with a matching manifest, mindshield and personal HoS ID.
   Cycle disable, laser, ion, stun; fire three stun shots from a full stock cell.
   Confirm the fourth cannot fire, and recharge restores capacity.
2. Repeat selection and attempted firing with the wrong assigned job, a missing
   manifest entry, wrong manifest rank, no mindshield, no ID, missing ACCESS_HOS,
   wrong ID assignment, wrong registered name, and an agent/chameleon ID.
   Each failure must show its reason and produce no stun projectile or charge use.
3. Select stun as an authorized HoS, then hand the gun to an officer or assistant.
   Attempt ordinary and dual-wield firing. Also remove the original HoS's mindshield
   or swap their ID after selecting stun. All unauthorized shots must fail.
4. Attempt stun as a cyborg/AI, after emagging, and after EMP exposure. Neither
   electronic effect grants authorization. Verify the other three modes remain usable
   by an ordinary officer/assistant and preserve their previous effects and costs.
5. Check that the mode and charge indicators remain visible while stun is selected.
