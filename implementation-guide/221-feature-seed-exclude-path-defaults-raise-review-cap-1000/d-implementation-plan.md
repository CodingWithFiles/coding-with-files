# Seed exclude-path defaults, raise review cap 1000 - Implementation Plan
**Task**: 221 (feature)

## Task Reference
- **Task ID**: internal-221
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/221-seed-exclude-path-defaults-raise-review-cap-1000
- **Template Version**: 2.1

## Goal
Implement the approved design: seed a generic `security.review.max-lines-exclude-paths`
default into the config template, raise the built-in cap 500→1000, dog-food the
new default, and sync the two docs + the 500-anchored tests.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cwf/templates/cwf-project.json.template` — add `_security-review-note` +
  `security.review.max-lines-exclude-paths` generic glob array, after the
  `sandbox` block (mirrors `_sandbox-note`/`sandbox`).
- `.cwf/scripts/command-helpers/security-review-changeset` — bump the cap default
  at all four `500` sites: `:101` constant → `1000`; `:32` banner `(500)`→`(1000)`;
  `:316` comment `(default 500)`→`(default 1000)`; `:100` reword to drop the
  hardcoded literal (no re-pin).

### Supporting Changes
- `.cwf/security/script-hashes.json` — refresh the `security-review-changeset`
  entry in the same commit (hash-tracked file edited; `hash-updates.md` rule).
- `implementation-guide/cwf-project.json` — remove redundant
  `security.review.max-lines: 1000` (`:40`); keep its exclude-paths.
- `CWF-PROJECT-SPEC.md` — light touch. The bullet at `:87-89` already lists
  `review.max-lines-exclude-paths`; only the section framing at `:76` ("these keys
  appear in the dog-fooded config") is now incomplete — that exclude default also
  ships **seeded in the template** for new projects. Note the built-in cap default
  is now 1000 (a helper default, not a template key). Do **not** state `max-lines`
  is seeded in the template (per design D2 — excludes only). If the existing text
  is already accurate on inspection, keep the edit minimal or drop the file.
- `.cwf/docs/skills/security-review.md` — update the two `500` literals on `:47`
  to `1000` (not hash-tracked; no hash refresh).
- `t/cwf-project-template.t` — assert the template carries a non-empty
  `security.review.max-lines-exclude-paths` array.
- `t/security-review-changeset.t` — the 32 `500` mentions split into **change**,
  **keep**, and **string-only** classes (do NOT blanket-replace — several `500`s
  are load-bearing and must stay). The full per-subtest matrix is the
  e-testing-plan's job; the split is:
  - **CHANGE — re-baseline (assertion edits)**: `TC-DEFAULTCAP` (`:1024-1036`)
    writes 520 lines to assert the default fires; re-baseline so the fixture
    exceeds the new default (script > 1000, e.g. ~1020 production lines) and still
    exits 2. Audit `TC-CAP3` (`:757-772`, "defaults to 500").
  - **CHANGE — string/comment only (behaviourally neutral)**: the
    "degrade to 500" descriptions/comments in `TC-CONFIGCAP5/6/7/8`
    (`:1695-1755`) → "degrade to 1000". These run 30-line scripts, so no assertion
    changes — only the prose default value.
  - **KEEP — must NOT change**: `TC-CONFIGCAP4` (`:1679-1690`, explicit
    `--max-lines=500` vs a 600-line script asserting exit 2 — an explicit flag,
    not the default); `TC-DOCS` (`:1266,1283`, negative guard that skills carry no
    stale `--max-lines=500`); the `[500]` array literal in `TC-CONFIGCAP6`
    (`:1712`, arbitrary ref-type-degradation value, not a cap reference).
  - **ADD**: glob-validity (through git's real `:(glob,exclude)` engine) and
    FR3-guardrail (live-tree, re-runnable) coverage.

(No named Perl symbol is deleted — the `max-lines` removal is a JSON key and `:100`
is a comment reword. No `Deletes:` line required.)

## Implementation Steps
### Step 1: Cap bump (helper)
- [ ] Edit `security-review-changeset` `:101` `$DEFAULT_MAX_LINES` 500→1000.
- [ ] Edit `:32`, `:316` prose/comment 500→1000; reword `:100` to drop the literal.
- [ ] Verify by eyeballing the four cited sites (not `grep 500` alone — a bare
      `500` grep can hit unrelated numerics and would miss a reformatted literal).

### Step 2: Seed the template
- [ ] Add `_security-review-note` + `security.review.max-lines-exclude-paths` block
      (exact globs per c-design §Component 1) after `sandbox`.
- [ ] The `_security-review-note` must surface the markdown-discount trade-off
      explicitly (security reviewer): the seeded `*.md`/`docs/**/*.md` entries make
      doc markdown discounted from the cap **by default**, and markdown is the
      primary prompt-injection carrier — it stays fully reviewed, but the cap no
      longer bounds prose volume. (Kept per R1's "doc-only markdown" intent; the
      CHANGELOG/h-rollout note repeats it — surface, never smooth.)
- [ ] Confirm the template still parses as JSON (`t/cwf-project-template.t` green).

### Step 3: Dog-food + docs
- [ ] Remove `security.review.max-lines` from `implementation-guide/cwf-project.json`;
      keep exclude-paths. Confirm valid JSON.
- [ ] Update `CWF-PROJECT-SPEC.md` `:87-89` security bullet.
- [ ] Update `.cwf/docs/skills/security-review.md` `:47` (both 500→1000).

### Step 4: Tests (with/after impl per TDD seam — details in e-testing-plan)
- [ ] Re-baseline `TC-DEFAULTCAP`; sweep the 32 `500` mentions in
      `t/security-review-changeset.t`; add glob-validity (through git's real
      `:(glob,exclude)` engine) and FR3-guardrail (live-tree, re-runnable) tests.
- [ ] Extend `t/cwf-project-template.t` with the exclude-paths-present assertion.

### Step 5: Hash refresh + validate
- [ ] Refresh `security-review-changeset` sha256 in `.cwf/security/script-hashes.json`.
- [ ] Restore the script's recorded working perms (0500) after editing.
- [ ] `cwf-manage validate` exits 0.

### Step 6: Full-suite regression
- [ ] Run the `t/` suite; all green (no stale-500 failures remain).

## Test Coverage
**See e-testing-plan.md for complete test plan** — covers AC1–AC9: exclude match=0
production, cap boundary 1000/1001, precedence, FR3 guardrail (live-tree),
glob-validity (git engine), dog-food config shape, template diff, and doc currency.

## Validation Criteria
**See e-testing-plan.md.** Gate: `cwf-manage validate` exit 0; full `t/` suite
green; `grep 500` in helper + both docs shows no stale default.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.
All seven files land in one exec changeset (the cap bump and dog-food removal must
be same-commit so no window exists where 500-anchored tests and a 1000 default
disagree).

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
