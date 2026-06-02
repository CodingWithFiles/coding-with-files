# review all changed files not just cwf-internal - Implementation Plan
**Task**: 174 (bugfix)

## Task Reference
- **Task ID**: internal-174
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/174-review-all-changed-files-not-just-cwf-internal
- **Template Version**: 2.1

## Goal
Implement the c-design-plan decisions D1–D5: delete the classifier so the helper emits the full diff over all changed files, sweep CWF-internal-only framing from living docs, reconcile the test suite, refresh hashes.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary (behaviour)
- `.cwf/scripts/command-helpers/security-review-changeset` — delete classifier (D1); header/comment sweep (D3.1). **Hash-tracked.**

### Doc / prose sweep (D3)
- `.cwf/docs/skills/security-review.md` — rename § "Pathspec coverage" → § "Changeset coverage"; rewrite classification rules + Known-limitations; reword line 26; fix line 137 cross-ref. *Untracked.*
- `.claude/skills/cwf-implementation-exec/SKILL.md` — Step 8 classification prose + § reference. *Untracked.*
- `.claude/skills/cwf-testing-exec/SKILL.md` — same. *Untracked.*
- `.claude/agents/cwf-security-reviewer-changeset.md` — § reference (line 16). **Hash-tracked.**

### Tests (D5)
- `t/security-review-changeset.t` — delete / invert / re-justify per D5 (exhaustive mapping in e-testing-plan).

### Integrity
- `.cwf/security/script-hashes.json` — refresh helper + agent file (D4), same commit.

## Implementation Steps

### Step 1: Code — delete the classifier (D1)
- [ ] Re-confirm current line numbers (`grep -n` for each symbol; design line refs may have drifted).
- [ ] Delete `@CWF_INTERNAL_PREFIXES` + `%CWF_INTERNAL_FILES` (helper ~73–88).
- [ ] Delete `$SCRIPT_INTERPRETER_RE` and its comment block (~90–98).
- [ ] Replace the classification loop (~172–182) with `my @included = @changed;`.
- [ ] Delete `is_cwf_internal` (~457–467) and `looks_like_script` (~469–516).
- [ ] Confirm no remaining references to the five deleted symbols (`grep -n`).
- [ ] Leave untouched: anchor resolution, `list_changed_files`, the empty-check at ~193 (guard against bare whole-tree diff), diff emit at ~198, `count_production_lines`/`test_path_excludes` at ~206/205, stderr summary format.
- [ ] **Verify the empty-`@included` invariant post-edit** (highest-consequence): `@included` derives solely from `@changed`, which `list_changed_files` already `grep { length }`-filters (~393). So a genuinely empty diff still yields empty `@included`, and the line-193 guard fires **before** any `git diff … -- @included` — a bare whole-tree diff (no pathspec) can never run. Read the final code to confirm, don't assume.

### Step 2: Code comments + header sweep (D3.1)
- [ ] Header line 6: "Single source of truth for what counts as security-relevant in CWF" → "…for changeset construction (anchor + cap) in CWF".
- [ ] Header lines 19–23 ("File classification …"): replace with "Changeset: the full diff (anchor → working tree) over every changed file. No path/language filtering."
- [ ] Output block line 42: `stdout: filtered git diff output` → `stdout: git diff output (the full changeset for the subagent)`.
- [ ] Comment blocks at ~69–98 (the "CWF-internal coverage" / shebang-regex banner comments) and ~168–171 / ~457–458: delete (they document deleted code).

### Step 3: Doc sweep — security-review.md (D3.2)
- [ ] Rename heading § "Pathspec coverage" → § "Changeset coverage".
- [ ] Replace the three classification rules (CWF-internal / shebang / default-exclude) with: the helper emits the full `git diff` (anchor → working tree) over **all** changed files; no path or language filtering.
- [ ] **Delete/rewrite the Maintainer note (line ~36)** — it instructs future editors to "update the `@CWF_INTERNAL_PREFIXES` list" and preserve the shebang-regex anchoring, both of which D1 deletes. Left as-is it is a dangling instruction to edit removed code (flagged by 2 reviewers). Remove it, or replace with a one-liner: "the changeset is the full diff — there is no path/interpreter list to maintain."
- [ ] Remove the four CWF-internal "Known limitations" bullets (shebang-less, library-file, `source`d-script, uncommon-interpreter) — all moot once nothing is filtered. **Keep the `**Known limitations**` heading only if the mid-task-rebase paragraph (line ~45) remains under it; if that paragraph is the sole survivor, reparent it so no empty heading is left.** Keep the mid-task-rebase limitation (still applies).
- [ ] Production-cap note (line ~49): reword "over the included files" → "over all changed files" so no narrowing is implied.
- [ ] Line 26 reword (as header line 6).
- [ ] Line 137 cross-ref: "§ Pathspec coverage" → "§ Changeset coverage".
- [ ] Confirm the § "Classification (deterministic …)" verdict-classifier section (line ~167) is untouched.

### Step 4: Doc sweep — exec SKILLs + agent (D3.3, D3.4)
- [ ] `cwf-implementation-exec/SKILL.md`: Step 8 — "applies CWF-internal-dir + shebang-sniff classification per § Pathspec coverage" → "emits the full diff over all changed files and enforces the production-weighted cap per § Changeset coverage"; update the earlier "§ Pathspec coverage" read-reference too. Leave exit-code branches verbatim.
- [ ] `cwf-testing-exec/SKILL.md`: identical edit.
- [ ] `cwf-security-reviewer-changeset.md` line 16: "§ Pathspec coverage" → "§ Changeset coverage".
- [ ] Output-level smoke test (per memory), **scoped** — grep the four swept living docs for `CWF-internal`, `Pathspec coverage`, "what counts as security-relevant": expect **zero**. For `shebang`/`#!`: a non-zero count is expected and legitimate in `security-review.md` § "Threat categories" (the `#!`/interpreter anti-pattern examples) — triage against that enumerated list, not "expect zero". Any `shebang` hit describing *changeset selection* is a residue and must go.

### Step 5: Tests (D5)
- [ ] Apply the delete/invert/re-justify mapping from e-testing-plan to `t/security-review-changeset.t`.
- [ ] Add the widening-regression TC (plain `src/app.js` reaches `@included`, appears in diff, counts as production).
- [ ] Add a TC for the cap fail-safe direction: with **no** `security.review.test-paths` configured, changed test files count as production toward `--max-lines` (documents that the cap fires earlier, never later — not a regression).
- [ ] **Guard-removal-safety TC (MANDATORY gate — sole evidence for D1's "DoS net-neutral" claim)**: a changeset containing a symlink and a FIFO. Assert the *observable*: `git diff` over a tracked symlink emits the **link-target text** (the blob), not the dereferenced file, and over a FIFO the command **completes without hanging** (does not block reading the pipe). "Neither blocks nor leaks" must be falsifiable, not self-certifying.
- [ ] `chmod +x` and run `t/security-review-changeset.t`; all green.
- [ ] Run the full `t/` suite for regressions.

### Step 6: Hash refresh + validate (D4)
- [ ] Per-file `git log` pre-refresh check for the helper and agent file (hash-updates convention).
- [ ] Refresh `.cwf/security/script-hashes.json` for the two hash-tracked files.
- [ ] Restore helper working perms to the **recorded** value (0500 ceiling — do not leave 0700; per feedback).
- [ ] `.cwf/scripts/cwf-manage validate` → zero *new* violations (the 3 pre-existing unrelated perm-drift items are out of scope; do not fold their fix into this task).

## Code Changes
### Before (helper, classification loop)
```perl
my @included;
for my $path (@changed) {
    if (is_cwf_internal($path)) { push @included, $path; next; }
    if (looks_like_script($path)) { push @included, $path; next; }
}
```
### After
```perl
# Review the full changeset: every changed file, no path/language filter.
# Test-vs-production weighting happens only in the cap (count_production_lines).
my @included = @changed;
```

## Test Coverage
**See e-testing-plan.md for the complete test plan** (D5 subtest mapping + new widening/guard-removal cases).

## Validation Criteria
**See e-testing-plan.md.** Key gates: full diff emitted over all changed files; production count = all − test-paths; empty diff → exit 0 `reviewed 0 files`; zero residual CWF-internal-only framing in living docs; `cwf-manage validate` clean of new violations.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned implementation steps executed (see f-implementation-exec.md for the
step-by-step record). Deviations: (1) a user-directed config-key rename
(`test-paths` → `max-lines-exclude-paths`) with back-compat fallback, beyond the
approved plan; (2) two extra test files (`t/cwf-check-tree-symlinks.t`,
`t/install-bash-reinstall.t`) reconciled for references to the deleted
`@CWF_INTERNAL_PREFIXES`, which the plan scoped only to the co-located test file.
Both recorded as f deviations; this plan was left frozen as approved.

## Lessons Learned
The plan scoped test reconciliation to one file and source-grepped for the deleted
symbols, but did not extend the grep to *test assertions* on those symbols — the
cross-file coupling surfaced at exec. A plan-time repo-wide symbol-deletion reference
sweep would have caught it (recommended as a backlog item). See j-retrospective.md.
