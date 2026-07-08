# Always review docs regardless of line cap - Testing Plan
**Task**: 223 (feature)

## Task Reference
- **Task ID**: internal-223
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/223-always-review-docs-regardless-of-line-cap
- **Template Version**: 2.1

## Goal
Define test strategy and validation approach for Always review docs regardless of line cap.

## Test Strategy
### Test Levels
- **Unit / helper (`prove t/security-review-changeset.t`)**: `doc_pathspec()`
  derivation + guards, cap-count exclusion, deferred artefact + confirmation-line
  contract. The bulk of coverage lives here (deterministic Perl).
- **Skill-contract (`t/exec-changeset-reviewers.t`)**: if it models Step-8
  recording, assert the deferred-State record + reviewer routing on exit 2;
  otherwise cover via the output smoke.
- **System / output smoke (manual, AC4)**: force an over-cap run in a scratch
  repo, grep the generated exec artefact for `**State**: deferred` and the
  absence of stale "one confirmation line"/"exit 2 → no agents" wording.
- **Regression**: full `prove t/` — no existing helper/skill/validate test breaks.

### Test Coverage Targets
- **Critical paths (100%)**: every KD5 guard branch; the three doc-line outcomes
  (present>0 / present-0 / absent); the cap-count exclusion; the guardrail
  (`.cwf/**/*.md` never discounted).
- **Edge/adversarial**: full adversarial `base-path` set; cap-boundary; no-docs.
- **Regression**: existing `security-review-changeset.t` / `validate-security*.t`
  green.

## Test Cases
### Functional — helper (`t/security-review-changeset.t`)
Harness isolation (misalignment F2): each case writes its OWN `cwf-project.json`
with an explicit `max-lines-exclude-paths` that does NOT already cover the test
`base-path`, so the discount under test is observable, not masked by this repo's
real excludes.

- **TC-1 — base-path markdown discounted (AC1a)**
  - **Given**: `base-path=docs-tree`; a changeset adding N markdown lines under
    `docs-tree/…/*.md` plus a small code change under cap.
  - **When**: run `security-review-changeset --wf-step=implementation-exec`.
  - **Then**: exit 0; production count excludes the `docs-tree` markdown (does not
    trip the cap on prose alone).
- **TC-2 — code under base-path still counts; markdown-scoped (AC1/security)**
  - **Given**: `base-path=docs-tree`; a `docs-tree/foo.pl` (code) change exceeding
    the cap.
  - **When**: run helper.
  - **Then**: exit 2 — code under the task-doc tree is NOT discounted (proves
    markdown-only, not tree-scoped).
- **TC-3 — guardrail: `.cwf/**/*.md` never discounted (AC2, HARD assertion)**
  - **Given**: `base-path=.cwf` (adversarial); a large `.cwf/…/x.md` change.
  - **When**: run helper.
  - **Then**: `base-path` rejected by the guard → no exclude → the `.cwf` markdown
    counts as production (guards CWF's own security docs from discount).
- **TC-4 — adversarial/malformed base-path fail-safe (AC2/AC1c)**
  - **Given**: `base-path` ∈ {absent, empty, `.`, `./`, `foo/`, `./foo`, `../x`,
    `/abs`, `**`, `a*b`, `a,b`, `x\n`} (one sub-case each).
  - **When**: run helper.
  - **Then**: no exclude (markdown counts as production); a *malformed present*
    value emits a `carp`/STDERR diagnostic naming the key + fallback; absent/empty
    is silent. (`x\n` specifically MUST be rejected — proves `\A…\z` anchoring.)
- **TC-5 — deferred artefact on over-cap (AC3a)**
  - **Given**: `base-path=docs-tree` valid; changeset with over-cap code AND
    markdown under `docs-tree`.
  - **When**: run helper.
  - **Then**: exit 2; writes `…-implementation-exec-docs.out` containing ONLY the
    doc markdown diff; stdout has the primary line AND
    `wrote <D> doc lines to <abs>` (`D>0`, raw diff-line basis); stderr still has
    `cap exceeded:`.
- **TC-6 — configured-but-no-docs vs unconfigured (AC2c, robustness F1)**
  - **Given (a)**: valid `base-path`, over-cap code, NO markdown → doc line present
    with `wrote 0 doc lines`. **Given (b)**: base-path unconfigured, over-cap →
    NO doc line at all.
  - **Then**: the two cases are distinguishable on the wire (present-0 ≠ absent).
- **TC-7 — cap boundary (AC5)**: production exactly == cap ⇒ exit 0 (pass);
  cap+1 ⇒ exit 2. Confirms the counting basis at the edge.

### Functional — skill contract / output smoke (AC3/AC4)
- **TC-8 — deferred State recorded, agents run on docs**
  - **Given**: an over-cap exec run with task docs present.
  - **When**: the exec skill Step 8 processes exit 2.
  - **Then**: the reviewer sections carry their doc-review verdicts AND a
    `## Changeset Review — Code (Deferred)` / `**State**: deferred` record is
    present; best-practice reviewer ran on the docs (MAP stayed 5/2).
- **TC-9 — no stale wording (AC4)**: grep helper + both skills + security-review.md
  → zero matches for "exactly one confirmation line"/"prints one confirmation
  line" and "exit 2 → error/no agents"/"launch nothing".

### Non-Functional Test Cases
- **Security**: TC-3, TC-4 are the security guardrail (charset/anchor,
  `.cwf` never discounted, markdown-only). No world-readable widening — `-docs.out`
  mode 0600 (assert in TC-5).
- **Reliability**: doc-diff git failure collapses exit-2→exit-1 (surface, don't
  rescue) — assert an induced failure records `error`, not a pass.
- **Maintainability**: `cwf-manage validate` clean after the hash refresh.

## Test Environment
### Setup Requirements
- Ephemeral git repo per case (helper uses `find_git_root`; cannot be pointed at
  a temp dir — write a real `cwf-project.json` + commits in a `File::Temp` repo,
  per the existing `security-review-changeset.t` pattern).
- Core-only Perl; no network.

### Automation
- `prove t/` locally; the same suite is the CI gate.

## Validation Criteria
- [ ] TC-1..TC-9 pass; existing `t/` green (no regression)
- [ ] Every KD5 guard branch + all three doc-line outcomes exercised
- [ ] `.cwf/scripts/cwf-manage validate` clean
- [ ] AC4 output smoke: `deferred` present, stale wording absent

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 223
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
TC-1..TC-9 all pass (TC-7 covered by the existing TC-CAPBOUNDARY, not duplicated).
Per-case `cfg_basepath` harness isolation worked — the discount under test was never
masked by this repo's real excludes.

## Lessons Learned
Proving `\A…\z` needs the *diagnostic-fires* assertion, not the exit code — a `^…$`
guard would silently accept a trailing-newline base-path without changing the exit.
