# Always review docs regardless of line cap - Requirements
**Task**: 223 (feature)

## Task Reference
- **Task ID**: internal-223
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/223-always-review-docs-regardless-of-line-cap
- **Template Version**: 2.1

## Goal
Specify a changeset-review contract in which the task's docs are always
assessed — independent of the production-line cap — plus the base-path cap
exclusion and the folded-in cap counting/value decisions.

## Scope Note (folded-in backlog item)
This task folds in the backlog item *"Revisit the security-review line cap:
quantitative basis and edit-lines counting"* (Medium; Tasks 127/143/212). Its
**counting-basis** axis (edit-lines vs total-diff; warn/hard-stop split) is
entangled with the exit-contract change here and is in scope (FR5). Its
**quantitative-basis** axis (empirical calibration of the cap value) is
scope-flagged (FR6) — the full empirical study is heavier than this task and is
proposed as documentation-of-rationale here, with the empirical run left as a
user decision at plan review.

## Functional Requirements
Three requirements (collapsed from an earlier six on the Improvements review —
old FR3 was already-guaranteed behaviour, old FR4 was an implementation-coherence
checklist now expressed as FR2's ACs, and the two folded-in backlog axes merge
into FR3). Precision lives in the ACs.

- **FR1 — Base-path task-doc cap exclusion (markdown-only, bounded)**: the
  production-line count MUST discount **markdown under the CWF task-doc tree**,
  derived from the `directory-structure.base-path` config key, by default for any
  consumer with no per-project config. The exclude is **markdown-scoped**
  (`<base-path>/<task-dir-glob>/**/*.md`), NEVER path-scoped (`<base-path>/**`):
  code dropped under the task-doc tree MUST still count, or the cap is bypassable.
  Reuses the existing `max-lines-exclude-paths` pathspec engine (no new runtime
  engine); the derived exclude is **added to** (union with), not a replacement
  for, the seeded globs.
  - *Delta over Task 221*: Task 221 seeded `*.md` and `docs/**/*.md`, but git
    `:(glob)*.md` does not cross `/`, so a **non-default** `base-path` task tree
    is not caught — FR1 closes exactly that gap.
  - *AC1a*: with `directory-structure.base-path` set to a non-default value, that
    tree's markdown is discounted from the production count.
  - *AC1b (guardrail)*: code files under the task-doc tree, and any
    `.cwf/*` or `cwf-project.json` path, are NEVER discounted — asserted even when
    `base-path` is set adversarially (`.`, empty, containing `..`, or `.cwf`).
  - *AC1c (bounded/fail-safe)*: a `base-path` that resolves to the repo root, is
    empty/absent, or escapes the repo (`..`) is NOT honoured as an exclude — it
    degrades to counting docs as production (the stricter direction). A
    **malformed** (present-but-unparseable) `base-path` additionally emits a
    surfaced diagnostic (`carp`/STDERR); absent/empty degrades silently.
- **FR2 — Docs always reviewed regardless of cap**: when the production cap is
  exceeded, the exec-phase changeset review MUST still assess the doc portion of
  the changeset (the FR1 markdown set). A cap trip may defer/scope-down CODE
  review but MUST NOT result in "launch nothing". All `exit 2` consumers — the
  helper, both exec skills (f/g) Step 8, the exec templates, and the SubagentStop
  verdict guard — MUST be updated coherently.
  - *AC2a*: on an over-cap code changeset, the review agents run against a
    **doc-scoped changeset artefact** (a named `.out` the agents receive) and
    produce verdicts — not `error`/not-run — in the f/g exec records.
  - *AC2b (distinct State)*: a cap-deferred outcome is recorded under a distinct
    terminal State (candidate `deferred`/`partial` — final name is design's),
    never conflated with `error` and never mistaken for a pass.
  - *AC2c (no-docs case)*: an over-cap changeset with no docs records the distinct
    State cleanly (no spurious `error`, no empty agent launch).
  - *AC2d (coherence)*: source grep AND a generated exec-artefact grep find no
    stale "exit 2 → no agents"/"launch nothing" wording anywhere.
- **FR3 — Counting basis + cap-value rationale (folded-in backlog item)**: the
  threshold model is decided here — **docs always reviewed (uncapped) + code
  gated by the cap**. The residual numeric counting-basis sub-choice (edit-lines
  vs production-weighted total; warn vs hard-stop split) is design's to finalise
  and MUST be documented with rationale in `security-review.md`. The empirical
  cap-value calibration (backlog axis 1) is **scope-flagged**.
  - *AC3a*: threshold model + chosen counting basis + cap-value rationale
    documented in `security-review.md`.
  - *AC3b (scope decision, user at plan review)*: whether to run the full
    empirical calibration (subagent over 5–10 sized changesets, finding-rate
    plots) in this task, or keep it documentation-of-rationale and leave the
    empirical run deferred. If calibration is opted in, an AC for it is added.

### User Stories
- **As a** CWF consumer **I want** my own CWF process docs to never inflate my
  security-review cap **so that** genuine code changes are gated on code volume,
  not planning prose.
- **As a** CWF user running an exec phase **I want** my plan/design/test docs
  reviewed even when the code diff is large **so that** doc problems are caught
  before, not after, expensive code changes.
- **As a** security-conscious maintainer **I want** a deferred code review to be
  surfaced, never smoothed into an apparent pass **so that** the cap remains a
  signal, not a bypass.

## Non-Functional Requirements
### Performance (NFR1)
- No new runtime engine; base-path derivation is O(1) and reuses the Task 218
  pathspec machinery. No additional expensive git invocations.

### Usability (NFR2)
- Zero-config for consumers: base-path exclusion is automatic.
- Review messaging clearly distinguishes "code over cap, docs reviewed (code
  review deferred)" from a clean full review — actionable, not cryptic.

### Maintainability (NFR3)
- Single source of truth for the base-path derivation; Perl core-only; reuse
  over new code (extends existing helper, adds no parallel mechanism).

### Security (NFR4)
- The single load-bearing security invariant (the rest is stated once in FR1/FR2
  ACs, not re-asserted here): the derived pathspec is untrusted input — it MUST
  route through the existing defensive exclude reader (list-form git
  `:(glob,exclude)`, skip NUL/refs, no shell), inheriting the helper's safe
  posture rather than re-deriving path handling.

### Reliability (NFR5)
- Fail-safe direction (detail in FR1 AC1c): over-exclusion is the dangerous
  failure, so every ambiguity degrades to counting docs as production.
- Hash-tracked helper: sha256 refreshed in the same commit as the edit; recorded
  perms (0500) treated as a ceiling.

## Constraints
- **Canonical config key**: `directory-structure.base-path` (kebab-case, as in
  `cwf-project.json`). Do NOT copy `template-copier-v2.1:194`, which reads
  snake_case `directory_structure.base_path` — that never matches the kebab key
  and silently falls back to the `implementation-guide` default (latent copier
  bug; note for a follow-up, do not depend on it).
- Perl core-only; POSIX portability (macOS system Perl).
- Hash-tracked script — same-commit sha256 refresh (hash-updates.md), 0500 ceiling.
- Dog-food: tests MUST validate a non-default `base-path`, not only this repo's
  `implementation-guide`.
- wf files edited only via CWF skills; helper/templates/docs edited directly.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: >1 week? No — 1–2 days.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? Layers of one change (cap count,
      exit-contract, counting basis, docs/tests), not parallel concerns.
- [ ] **Risk**: High-risk components needing isolation? The contract-change risk
      is isolated in design, not by decomposition.
- [x] **Independence**: FR1 (cap exclusion) and FR2 (docs always reviewed) could
      ship separately but share the helper + f/g skills; splitting adds
      coordination overhead. FR6's empirical study is the one genuinely separable
      piece — hence the scope flag rather than a subtask.

**Conclusion**: keep as one task; FR6 empirical calibration is the deferrable
seam if scope needs trimming.

## Acceptance Criteria
Boundary/negative cases are named per the Best-practice review (write the
guardrail test to fail first).
- [ ] AC1: Non-default `base-path` markdown discounted from the cap; code under
      the task tree still counted (markdown-only, not tree) (FR1/AC1a).
- [ ] AC2 (guardrail, fail-first): `.cwf/*` and `cwf-project.json` never
      discounted even under adversarial `base-path` (`.`, empty, `..`, `.cwf`);
      such values degrade to counting-as-production; malformed warns, absent/empty
      silent (FR1/AC1b,AC1c).
- [ ] AC3: Over-cap code changeset yields doc-review verdicts (not error/not-run)
      against a named doc-scoped artefact; over-cap-with-no-docs records the
      distinct State cleanly (FR2/AC2a,AC2c).
- [ ] AC4: Cap-deferred outcome recorded under a distinct terminal State (not
      `error`, not a pass); no stale "exit 2 → no agents" wording in source OR a
      generated exec artefact (FR2/AC2b,AC2d).
- [ ] AC5: Threshold model + counting basis + cap-value rationale documented in
      `security-review.md`; changeset exactly at the cap boundary behaves per the
      documented basis (FR3/AC3a).
- [ ] AC6: sha256 refreshed same commit; `cwf-manage validate` clean.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 223
**Blockers**: None identified

## Plan Review (5 reviewers + 2 resolvers)
Applied: markdown-only (not tree) exclusion to close the cap-bypass vector
(Security); bounded/adversarial `base-path` handling + malformed-warns vs
absent-silent (Robustness, Best-practice); distinct terminal State for
cap-deferred review, defined doc-set + named doc-scoped artefact, no-docs case
(Robustness); FR collapse 6→3 (Improvements); Task 221 delta + canonical
`directory-structure.base-path` key with the copier snake_case latent-bug note
(Misalignment); boundary/negative ACs written fail-first (Best-practice).
Adjudicated noise: mechanical check's `.cwf/{scripts,hooks,security,docs}`
"missing path" is brace-expansion shorthand in prose, not a real path.
Deferred to user: FR3/AC3b empirical cap-value calibration scope decision.

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
FR1, FR2, and FR3 all delivered. FR3/AC3b's empirical cap study was deferred to
observational real-world calibration (user decision), not backlogged — usage supersedes it.

## Lessons Learned
Folding the backlog cap item into requirements kept the counting-basis rationale
beside the mechanism it describes, rather than stranding it in a separate item.
