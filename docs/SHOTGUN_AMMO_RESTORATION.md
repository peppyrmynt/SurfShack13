# Cheap printable shotgun ammunition

| Field | Value |
| --- | --- |
| Status | `in-progress` |
| Source repository | `tgstation/tgstation` |
| Source pull request | `tgstation/tgstation#55663` |
| Implementation branch | `agent/restore-shotgun-ammo-pricing` |
| Review mirror pull request | pending |

### Historical behavior restored

- Printable shotgun shells are restored to low material costs instead of the much higher modern prices.
- Single beanbag, rubbershot, slug, and buckshot shells are priced so cargo autolathes display a two-sheet cost.
- Seven-shell slug and buckshot boxes are priced so cargo autolathes display a fourteen-sheet cost.

### Current-code implementation

- Applies the material cost directly to the current autolathe/protolathe design definitions.
- Keeps shotgun ammunition printable from security protolathes and cargo autolathes.
- Avoids late type overrides in the circuit imprinter file.

### Validation

- Runtime spot-check reported the shotgun pricing is fixed.
- `git diff --check` passed for the follow-up branch.

### Limitations and completion criteria

- Security protolathe displayed cost can differ from cargo autolathe cost because the two machine families apply different material efficiency coefficients.
- Status remains `in-progress` until the follow-up pull request is reviewed and merged into the authoritative branch.
