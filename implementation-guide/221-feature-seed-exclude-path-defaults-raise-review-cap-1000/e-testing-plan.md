# Seed exclude-path defaults, raise review cap 1000 - Testing Plan
**Task**: 221 (feature)

## Task Reference
- **Task ID**: internal-221
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/221-seed-exclude-path-defaults-raise-review-cap-1000
- **Template Version**: 2.1

## Goal
Validate the cap bump (500→1000), the seeded generic exclude default, the FR3
security-path guardrail, and the doc/dog-food sync — with no stale `500` left and
no pre-existing test broken.

## Test Strategy
### Test Levels
- **Unit / behavioural** (`t/security-review-changeset.t`, `t/cwf-project-template.t`):
  the primary level — the helper's cap resolution and the template's seeded block
  are both directly exercised via the existing Perl `Test::More` harness.
- **Integration (git engine)**: glob-validity and the FR3 guardrail are checked
  through git's real `:(glob,exclude)` pathspec engine (the actual consumer), not a
  Perl-side approximation.
- **Regression**: the full `t/` suite must stay green; the cap change ripples into
  32 `500` mentions that need a precise change/keep split (below).

### Coverage Targets
- 100% of AC1–AC9 mapped to a named test case.
- Zero stale `500` default references in helper + both docs (eyeball the 4 helper
  sites, not `grep` alone).
- Zero regressions: every pre-existing `t/` subtest green.

## Test Cases (mapped to acceptance criteria)

### Cap default (AC4, FR4)
- **TC-DEFAULTCAP re-baseline** (`t/security-review-changeset.t:1024-1036`):
  - **Given** a changeset of > 1000 production lines (re-baseline the fixture from
    520 to ~1020) and no `--max-lines` / no config cap,
  - **When** `security-review-changeset` runs,
  - **Then** it exits 2 with `cap exceeded: … > 1000`.
- **TC-CAPBOUNDARY (new or extended)**:
  - **Given** exactly 1000 production lines, no flag/config, **Then** exit 0 (pass);
  - **Given** 1001 lines, **Then** exit 2. Pins both sides of the boundary.

### Precedence unchanged (AC5, FR5)
- **TC-PRECEDENCE (existing coverage retained)**: `--max-lines=N` overrides a
  configured `security.review.max-lines`, which overrides the built-in 1000.
  Explicitly verify `TC-CONFIGCAP4` (`:1679-1690`, `--max-lines=500` vs 600 lines →
  exit 2) still passes **unchanged** — proves the flag still wins over the default.

### Seeded exclude default (AC1, FR1)
- **TC-SEED-EXCLUDE (new)**:
  - **Given** a scratch repo using the seeded template config and a changeset whose
    churn is confined to seeded paths (e.g. `src/foo_test.js`, `vendor/x.go`,
    `dist/app.min.js`),
  - **When** the helper computes the production count,
  - **Then** the count is 0 (all discounted) and exit is 0.

### Doc-markdown scope (AC2, FR2)
- **TC-SEED-DOC (new)**:
  - **Given** the seeded config, **Then** a top-level `README.md` and
    `docs/guide.md` are discounted, but a `src/inline.md` (production location)
    still counts. Confirms `*.md` + `docs/**/*.md` anchoring, not blanket `**/*.md`.

### FR3 security-path guardrail (AC3, FR3) — live-tree, re-runnable
- **TC-SEED-GUARDRAIL (new, load-bearing)**:
  - **Given** the seeded glob set and the live repo tree,
  - **When** each guardrail path (`.cwf/scripts/`, `.cwf/hooks/`, `.cwf/security/`,
    `cwf-project.json`) is matched against the seeded globs via git's
    `:(glob,exclude)` engine,
  - **Then** none is excluded — a change to any still counts as production.
  - Encoded as a committed test that re-checks against the live tree (not a
    one-time design-time assertion), so future drift (e.g. a new
    `.cwf/scripts/foo_test.pl`) is caught.

### Glob-validity (AC4, FR4) — through the real engine, hard gate
- **TC-SEED-VALID (new, load-bearing)**:
  - **Given** each seeded glob,
  - **When** passed to git as a `:(glob,exclude)` pathspec (e.g. `git diff
    --numstat`/`ls-files`),
  - **Then** git does not fatal — proving no seeded glob would make the helper
    exit 1 across every new project. Must use the real engine, not a Perl regex.

### Template shape (AC8, FR1/FR5)
- **TC-TEMPLATE (extend `t/cwf-project-template.t`)**:
  - **Given** the shipped template, **Then** it parses as JSON (existing TC-1),
    validates clean (existing TC-3), **and** now carries
    `security.review.max-lines-exclude-paths` as a non-empty array. `max-lines` is
    **absent** from the template (guards D2).

### Dog-food config (AC6, FR6)
- **TC-DOGFOOD**:
  - **Given** `implementation-guide/cwf-project.json` after the edit, **Then**
    `security.review.max-lines` is absent, `max-lines-exclude-paths` retained, the
    file is valid JSON, and `cwf-manage validate` exits 0.

### Doc currency (AC7, FR7)
- **TC-DOCS-CURRENT**: `security-review.md:47` has no `500` (both → 1000);
  `CWF-PROJECT-SPEC.md` documents the seeded exclude default without claiming
  `max-lines` is template-seeded. The existing `TC-DOCS` negative guard
  (`:1266,1283`) still passes **unchanged**.

### Hash integrity (AC9, constraint)
- **TC-HASH**: after the helper edit + `script-hashes.json` refresh + 0500 perm
  restore, `cwf-manage validate` exits 0.

## The 32 `500` mentions — change / keep split (regression control)
Explicit classification so no mechanical sweep breaks green:
- **CHANGE, assertion re-baseline**: `TC-DEFAULTCAP` (`:1024-1036`).
- **CHANGE, string/comment only** (behaviourally neutral, 30-line scripts):
  "degrade to 500" descriptions in `TC-CONFIGCAP5/6/7/8` (`:1695-1755`) → 1000;
  audit `TC-CAP3` (`:757-772`).
- **KEEP, must NOT change**: `TC-CONFIGCAP4` explicit `--max-lines=500` (`:1679-1690`);
  `TC-DOCS` negative guards (`:1266,1283`); the `[500]` ref-type array literal in
  `TC-CONFIGCAP6` (`:1712`).

## Non-Functional Test Cases
- **Security**: TC-SEED-GUARDRAIL + TC-SEED-VALID above are the security tests
  (FR3 fail-open guardrail; malformed-glob review-wide breakage). No auth/authz
  surface exists.
- **Reliability**: TC-SEED-VALID proves the fail-safe (no default glob triggers the
  git-fatal → exit 1 path). Ecosystem-omission edge (globs match nothing → count
  normally) is covered implicitly by TC-DEFAULTCAP running with the seeded set.
- **Performance**: none — pathspec pass-through + one integer compare (NFR1).

## Test Environment
- Existing `t/` Perl `Test::More` harness; core modules only. Scratch git repos
  built in `${TMPDIR:-/tmp}` per the existing test fixtures' pattern. No external
  services, no database.

## Validation Criteria
- [ ] AC1–AC9 each have a passing named test case.
- [ ] Full `t/` suite green — no pre-existing subtest broken.
- [ ] `cwf-manage validate` exits 0.
- [ ] No stale `500` default reference in helper (`:32/:100/:101/:316`) or docs.

## Decomposition Check
- [ ] Time / People / Complexity / Risk / Independence — all No.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
