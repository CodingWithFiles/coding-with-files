# Always review docs regardless of line cap - Implementation Execution
**Task**: 223 (feature)

## Task Reference
- **Task ID**: internal-223
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/223-always-review-docs-regardless-of-line-cap
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [ ] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [ ] Verify all prerequisites met
- [ ] Execute implementation steps sequentially
- [ ] Update "Actual Results" for each step
- [ ] Document any deviations from plan

## Implementation Steps (from d-implementation-plan.md)

All steps executed in TDD order. Change surface: 1 helper (hash-tracked) + 2 exec
skills + 1 doc + 1 template note + the hash manifest + 2 test files.

## Actual Results

### Step 1: Validator surface pre-flight
- **Actual**: Grepped `t/validate-security*.t` and `t/validate-workflow.t` plus the
  `security-review-classify` consumer. **No validator enumerates review-section
  `**State**:` tokens** — `deferred` on the skill-authored code-review section is
  free-form prose and trips nothing. No validator extension needed (KD3 check clean).

### Step 2: Tests first — `t/security-review-changeset.t`
- **Actual**: Added `cfg_basepath()` (isolated per-case config, no overlapping
  seeded excludes) + doc-line parse helpers (`doc_out_path`, `doc_confirm_count`,
  `doc_changeset_of`) and queued the `-docs.out` for cleanup. Added TC-223-1..6:
  base-path markdown discounted (1); code under base-path still counts (2);
  `.cwf` rejected → never discounted, HARD (3); the full adversarial base-path
  fail-safe set incl. `content\n` proving `\A..\z` (4); the deferred artefact +
  second confirmation line + 0600 (5); present-0 vs absent doc-line distinction (6).
  Cap-boundary is already covered by the existing TC-CAPBOUNDARY, not duplicated.

### Step 3-5: Helper — `doc_pathspec()`, cap union, deferred artefact
- **Actual**: Added `doc_pathspec()` reading the real kebab key
  `directory-structure.base-path` (NOT the copier's snake_case latent bug), with
  the KD5 guard (`\A[A-Za-z0-9._/-]+\z` charset — not `^..$`; reject `.`/`./`,
  leading `./`, trailing `/`, `//`, `..`, absolute, `.cwf`). Returns a context-safe
  hashref `{exclude, include}` or a bare `return;`. Called ONCE (memoised in `$doc`),
  unioned into the cap-count `@exclude`, and reused in the over-cap block to write
  `…-<step>-docs.out` (mode 0600, inside the intent-to-add window) + the
  `wrote <D> doc lines` line (raw diff-line basis matching `<N>`). `$doc` undef ⇒
  no doc line (docs-not-separable signal). Updated the header banner, Output/Exit
  prose, `print_usage` POD, and the inline "one confirmation line" comment.

### Step 6-7: Exec skills — impl-exec + testing-exec Step 8
- **Actual**: Rewrote both exit-2 branches: parse the doc line → review docs
  (D>0) / `no docs to review` (D==0) / `docs not separable — base-path unconfigured`
  (absent), and in all three emit `## Changeset Review — Code (Deferred)` /
  `**State**: deferred` + the reused `cap exceeded:` detail. Extended the
  best-practice gate so a deferred doc `.out` (D>0) counts as a usable changeset
  (MAP stays 5 / 2). Added TC-223-A/B/C/D to `t/exec-changeset-reviewers.t`.

### Step 8/8a: Doc — `security-review.md` (DRY home) + template note
- **Actual**: Added the shared § "Deferred code review (over-cap)" both skills
  reference; reconciled the two discount layers (configurable list + always-on
  base-path markdown); documented the counting basis (numstat edit-lines, already
  true) and the cap-value rationale — **calibrated observationally from real-world
  usage** (this repo + downstream), study deferred per FR3/AC3b (user decision).
  Updated line-28 wording and the template `_security-review-note`.

### Step 9: Hash refresh + validation
- **Actual**: Only the helper is hash-tracked (skills/template/doc are not).
  Refreshed its sha256 in `.cwf/security/script-hashes.json` (same commit); working
  perms already at recorded 0500. `prove t/` green (76 files, 1008 tests);
  `cwf-manage validate` clean after clamping one **unrelated** pre-existing
  permission drift on `stop-stale-status-detector` (0700→0500, fix-on-sight). AC4
  smoke: TC-223-5 greps the live-generated `-docs.out`; repo-wide grep shows no
  stale "one confirmation line" wording on any security-review-changeset surface.

### Step 10: Backlog follow-ups (noted, not implemented)
- **Actual**: (a) `template-copier-v2.1:194` reads snake_case
  `directory_structure.base_path` — never matches the kebab key, silently defaults
  (latent bug). (b) Three independent `read_config()` sites in the helper now — a
  shared cached-config read is the clean fix, out of this scope.

## Blockers Encountered

None.

## Changeset Reviews

Changeset: 19 files, 2089 lines, **211 production** (docs + tests discounted),
anchor `3f7bbed`. Exit 0 → full 5-reviewer MAP launched in parallel.

## Security Review

**State**: no findings

Verified the new code invokes git only via list-form `capture_git` (no shell), the
`base-path` guard is fail-safe toward counting, the discount is markdown-only (no
code/`.cwf` cap-bypass), and `\A…\z` closes the trailing-newline hole.

```cwf-review
state: no findings
summary: helper change is list-form git only; base-path guard fail-safe toward counting, markdown-only discount, no code/.cwf bypass
```

## Best-Practice Review

**State**: no findings

Only executable code is Perl; adheres to applicable PBP (`\A\z` anchors, brace-`m{}`,
narrower ASCII class, bare `return;`, gated `$1`, negative-path test coverage).
golang/postgres sources inapplicable (no Go/SQL in the diff).

```cwf-review
state: no findings
summary: Perl helper + tests adhere to applicable PBP guidelines; golang/postgres sources inapplicable.
```

## Improvements Review

**State**: findings

Advisory only: `doc_pathspec()` adds a third copy of the `read_config()` eval-guard
prologue — **already captured** as a Very Low BACKLOG chore ("Shared cached config
read") with out-of-scope rationale. Otherwise strong reuse (no new engine; reuses
`capture_git`/`atomic_write_text`/numstat and extends the `exit 2` contract).
**Disposition**: accept-and-record — the finding is the deferred consolidation
already backlogged; no fix-and-re-run.

```cwf-review
state: findings
summary: doc_pathspec() adds a 3rd copy of the read_config eval-guard prologue (already shared-read backlogged, Very Low); otherwise strong reuse, no avoidable new code
```

## Robustness Review

**State**: no findings

Deferred-docs path is fail-safe toward counting, captures untracked docs in the
still-open intent-to-add window, surfaces git/write errors as exit 1 (never a silent
pass), and the distinct `**State**: deferred` prevents an absent code review reading
as clean. `<D>` raw-diff-line basis makes D>0/D==0/absent gapless.

```cwf-review
state: no findings
summary: Deferred-docs helper path is fail-safe toward counting, captures untracked docs in the intent-to-add window, and surfaces git/write errors as exit 1; distinct `deferred` state prevents an absent code review reading as clean.
```

## Misalignment Review

**State**: no findings

`doc_pathspec()` reuses the sibling `read_config` idiom, git pathspec engine, and
warning style; correctly aligns to the canonical kebab `directory-structure.base-path`
key and backlogs the snake_case copier bug rather than copying it.

```cwf-review
state: no findings
summary: New doc_pathspec() reuses the sibling read_config idiom, git pathspec engine, and warning style; correctly aligns to the canonical key and backlogs the snake_case copier bug.
```

## Deferral Check
Before marking status=Finished, verify:
- [ ] All steps from d-implementation-plan.md executed
- [ ] All success criteria from a-task-plan.md met
- [ ] All requirements from b-requirements-plan.md addressed (if applicable)
- [ ] All design guidance in c-design-plan.md followed (if applicable)
- [ ] No planned work deferred without user approval
- [ ] If work deferred: Follow-up task created and linked

**If deferral required**: Get user approval, document rationale, create follow-up task.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 223
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
See the per-step Actual Results above and the Changeset Reviews section.

## Lessons Learned
`\A…\z` (not `^…$`) is a security property when validating a value bound for a git
pathspec; markdown-only discounting (not tree-scoped) is what prevents a cap-bypass.
See `j-retrospective.md` for the full set.
