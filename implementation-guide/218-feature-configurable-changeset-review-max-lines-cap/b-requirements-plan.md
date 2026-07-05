# Configurable changeset-review max-lines cap - Requirements
**Task**: 218 (feature)

## Task Reference
- **Task ID**: internal-218
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/218-configurable-changeset-review-max-lines-cap
- **Template Version**: 2.1

## Goal
Define functional and non-functional specifications for a configurable
changeset-review production-line cap read from `cwf-project.json`.

## Functional Requirements
### Core Features
- **FR1**: `security-review-changeset` reads an integer cap from
  `security.review.max-lines` in `cwf-project.json`.
  - **AC**: With the key set to N and no `--max-lines` flag, a changeset whose
    production-weighted line count is ≤ N exits 0; > N exits 2.
- **FR2**: Cap precedence is `--max-lines` CLI flag > `security.review.max-lines`
  config key > built-in default (500).
  - **AC**: CLI flag present → its value wins regardless of config. CLI absent,
    config present → config value used. Both absent → 500 used.
  - **AC**: An *explicit* `--max-lines=500` overrides a config of 1000 (500 wins).
    This forces the `%opt{max_lines}` default to move from `500` to unset so
    "flag absent" is distinguishable from "flag explicitly 500"; the effective cap
    is then resolved as `CLI // config // 500` after arg parsing.
- **FR3**: An invalid or absent `security.review.max-lines` value never produces a
  silent wrong cap; the resolver falls back to the built-in default (500). A
  *malformed* config value is non-fatal (warn + degrade to 500); by contrast an
  invalid `--max-lines` CLI value stays **fatal** (exit 1) as it does today.
  - **AC**: Values that are not a positive integer (0, negative, leading-zero,
    non-numeric, missing key, unreadable/malformed config) cause the effective cap
    to be 500, not a weakened or crashing gate. A malformed value emits a warning
    to STDERR (mirroring the `test-paths` deprecation-warn precedent — note the
    invalid-`--max-lines` path is fatal, not warn-and-continue) but is non-fatal.
  - **AC (asymmetry rationale)**: A CLI typo is direct interactive input and should
    fail loud (exit 1); a config typo should degrade safely to 500 so a single bad
    edit never silently breaks the gate for a whole project. Both directions are
    fail-safe (stricter), never fail-open.
  - **AC (JSON scalar type)**: A JSON number (`"max-lines": 1000`) and a numeric
    string (`"max-lines": "1000"`) that both match the positive-integer regex are
    accepted — reusing the existing `^[1-9]\d*$` validation on the stringified
    scalar. Any other JSON type (array, object, bool, null) → 500.
- **FR4**: This repo's config (`implementation-guide/cwf-project.json`, not a
  repo-root file) sets `security.review.max-lines: 1000`.
  - **AC**: A changeset of 501–1000 production lines reviewed on this repo passes
    the cap gate.
- **FR5**: The `security-review-changeset` script-hash entry in
  `.cwf/security/script-hashes.json` is refreshed in the same commit as the edit.
  - **AC**: `cwf-manage validate` reports no drift after the change.

### User Stories
- **As a** CWF-using project maintainer **I want** to raise the review cap in my
  project config **so that** larger legitimate changesets pass without editing a
  vendored helper that upgrades will overwrite.
- **As a** CWF maintainer **I want** the new key read defensively like its sibling
  **so that** a typo in project config degrades safely to the default rather than
  breaking the security gate.

## Non-Functional Requirements
### Performance (NFR1)
- No measurable overhead: the config is already read once for
  `max-lines-exclude-paths`; reading one more scalar adds no new I/O of note.

### Usability (NFR2)
- The new key sits beside `max-lines-exclude-paths` under `security.review` and is
  documented in the same place, so the learning curve is "one more sibling key".
- Error messages for a malformed value are actionable and name the key.

### Maintainability (NFR3)
- The config read mirrors the existing `max_lines_exclude_paths()` sub structure
  (eval-guarded `read_config`, defensive type checks) — no new config machinery.
- Validation reuses the existing positive-integer regex, not a second copy.

### Security (NFR4)
- Fail-safe, not fail-open: any *ambiguity* (malformed/absent value) resolves to the
  *stricter* built-in 500, never a larger/disabled cap. The cap is a security gate;
  a malformed config must not weaken it.
- No new prompt-injection or env-var surface: value comes from the already-trusted
  project config file, parsed as an integer only.
- **No upper bound is enforced.** A valid-but-huge value (e.g. `100000000`) is not
  "invalid" and so is not caught by the fail-safe above — it effectively neuters the
  gate. This is deliberate: raising or effectively disabling the cap is a maintainer
  policy choice, trusted because `cwf-project.json` is an in-repo, reviewed artefact.
  The fail-safe guards *ambiguity*, not intentional up-sizing.
- **Self-referential trust boundary.** The cap now lives inside the changeset the
  gate governs, so one changeset can both raise the cap and consume the higher
  allowance. Exposure is bounded — exceeding the cap *blocks* review (exit 2), it
  does not bypass it, and the config edit is visible in the reviewed diff — but a
  self-raised cap can yield a shallow review of a large diff. Assumption:
  config-in-changeset is trusted-and-reviewable; design makes this deliberate.
- The malformed-value STDERR warning names the config *key* only — it must not echo
  raw file paths or config contents (avoid information leakage in errors).

### Reliability (NFR5)
- Reading the config never makes the helper fatal on missing/unreadable/malformed
  config (same guarantee `max_lines_exclude_paths()` already provides).

## Constraints
- Perl core-only, `use utf8;`, UTF-8 I/O (project Perl conventions).
- CWF dogfoods itself: editing the vendored helper here **is** the upstream change.
- Hashed file — hash refresh must land in the same commit (hash-updates convention).
- No change to the `--max-lines` CLI contract or its exit codes (0/1/2).

## Decomposition Check
- [x] **Time**: >1 week? No.
- [x] **People**: >2 people? No.
- [x] **Complexity**: 3+ distinct concerns? No.
- [x] **Risk**: High-risk isolation needed? No.
- [x] **Independence**: Separable parts? No.

No decomposition signals triggered.

## Acceptance Criteria
- [ ] AC1 (FR1/FR2): Precedence CLI > config > 500 verified by test across all three
      layers.
- [ ] AC2 (FR3): Every invalid-value class resolves to 500; malformed value warns
      but does not crash.
- [ ] AC3 (FR4/FR5): `implementation-guide/cwf-project.json` set to 1000;
      `cwf-manage validate` clean after hash refresh.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All FRs and NFRs satisfied and verified by the TC-CONFIGCAP suite: the config read
(FR1–3), the 501–1000 pass on this repo (FR4), the fail-safe degrade and no-value-echo
warning (NFR4/NFR5), and the CLI-fatal/config-degrade asymmetry. NFR4's
self-referential-trust-boundary note carried through to the maintenance follow-up.

## Lessons Learned
Framing the invalid-config handling as a *fail-safe* requirement (degrade to stricter
500, never fail-open-large) up front made the test matrix fall out directly — every
invalid equivalence class maps to one acceptance criterion.
