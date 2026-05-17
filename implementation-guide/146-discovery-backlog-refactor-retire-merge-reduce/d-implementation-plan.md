# Backlog refactor: retire, merge, reduce - Implementation Plan
**Task**: 146 (discovery)

## Task Reference
- **Task ID**: internal-146
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/146-backlog-refactor-retire-merge-reduce
- **Template Version**: 2.1

## Goal
Execute the design from c-design-plan as an ordered sequence of f-phase commits, with `backlog-manager validate` gating every BACKLOG.md / CHANGELOG.md mutation.

## Workflow
Patterns first -> validate -> mutate -> validate -> commit -> message explains "why"

## Files to Modify

### Primary changes (committed)
- `implementation-guide/146-.../recommendations.md` (NEW) -- created in Step 2, approval-amended in Step 3, never touched again.
- `BACKLOG.md` -- mutated by retire / merge-enrich / reduce-scope in Step 6.
- `CHANGELOG.md` -- seeded in Step 5; appended to in Step 6 by `backlog-manager retire`.
- `implementation-guide/146-.../f-implementation-exec.md` -- the f-phase wf-file; committed at the end of f-phase via `cwf-checkpoint-commit 146 f "<why>"` (separate from the apply-loop commits, which use plain `git commit`).

### Supporting changes (transient, not committed)
- `/tmp/-home-matt-repo-coding-with-files-task-146/baseline.sha` -- written in Step 1, read via `$(cat ...)` thereafter. Avoids relying on shell-variable persistence across Bash tool calls.
- `/tmp/-home-matt-repo-coding-with-files-task-146/preflight.pl` -- one-shot Step 4 helper that `use`s `CWF::Backlog` and `CWF::Common`. Not committed.
- `/tmp/-home-matt-repo-coding-with-files-task-146/msg-*.txt` -- per-commit message files passed to `git commit -F` to side-step shell-quoting hazards with entry titles.

### Not modified
- Any helper script (`backlog-manager`, `cwf-checkpoint-commit`, `cwf-manage`) -- per c-design D1.
- Any Perl module under `.cwf/lib/` -- per c-design D1.
- `implementation-guide/cwf-project.json` or any config.

## Implementation Steps

### Step 1: Setup (no commit)
- [ ] `mkdir -m 0700 -p /tmp/-home-matt-repo-coding-with-files-task-146` (tmp-paths convention; idempotent).
- [ ] `git rev-parse HEAD > /tmp/-home-matt-repo-coding-with-files-task-146/baseline.sha` (Step 1's persistent record; shell variables do not survive across Bash tool calls, but this file does).
- [ ] Sanity-check baseline count: `git show "$(cat /tmp/-home-matt-repo-coding-with-files-task-146/baseline.sha)":BACKLOG.md | grep -c '^## Task: '`; record the number; this is the target for AC1.

### Step 2: Draft recommendations.md (commit "Task 146: Draft backlog recommendations")
- [ ] Read `git show "$(cat .../baseline.sha)":BACKLOG.md` to enumerate every `## Task: <title>` entry.
- [ ] For each entry, derive `--id=<slug>` per `CWF::Common::generate_slug` (line 80 of `Common.pm`): `lc($title); s/[^a-z0-9 -]//g; s/\s+/-/g; s/-+/-/g; s/^-+|-+$//g;`. Hyphens in the source title are preserved (note: this is the corrected algorithm; the slug is informational here -- final selector resolution happens in Step 4 pre-flight and at apply time inside `backlog-manager`).
- [ ] Write `recommendations.md` with preamble (`Baseline:`, `Generated:`, empty `Approval:`) and one `## Recommendation: <title>` section per entry (verbatim title preserved; do not paraphrase). Each section populated with: `Selector`, `Priority`, draft `Action`, draft `Target` (merge only), draft `Carry-overs` (merge only), draft `Rationale` (non-keep only).
- [ ] Verify `grep -c '^## Recommendation: ' implementation-guide/146-.../recommendations.md` equals Step 1's baseline count.
- [ ] Write `/tmp/.../msg-step2.txt` with the commit message; `git add implementation-guide/146-.../recommendations.md && git commit -F /tmp/.../msg-step2.txt`.

### Step 3: User-approval gate (commit "Task 146: Maintainer approval recorded")
- [ ] Present the drafted artefact to the maintainer for review.
- [ ] Maintainer (or assistant on the maintainer's instruction) fills the `Approval:` line and amends affected rows.
- [ ] `git add recommendations.md && git commit -F /tmp/.../msg-step3.txt`.
- [ ] **Invariant**: no mutation of BACKLOG.md or CHANGELOG.md may precede this commit (FR3 / AC2).

### Step 4: Pre-flight (no commit; may force re-approval if it fails)
- [ ] Write `/tmp/.../preflight.pl`:
  ```
  #!/usr/bin/env perl
  use strict; use warnings; use utf8;
  use lib "$ENV{HOME}/repo/coding-with-files/.cwf/lib";
  use CWF::Backlog qw(parse_backlog_tree find_all_entries_by_slug);
  use CWF::Common  qw(generate_slug);
  # Args: <abs-path-to-recommendations.md> <baseline-sha>
  ```
  The script:
  1. Parses recommendations.md and `git show <SHA>:BACKLOG.md` (write the latter to a temp file in the scratch dir, then `parse_backlog_tree` it).
  2. **Slug uniqueness**: for every row whose `Selector:` is `--id=<slug>`, assert `find_all_entries_by_slug` returns exactly one.
  3. **Target resolution**: for every `merge` row, assert `Target:` selector resolves to another row in the artefact.
  4. **No cycles, no dangling targets**: follow each merge chain; assert it terminates at a row with terminal action `keep-as-is` or `reduce-scope`.
  5. **Carry-over safety**: round-trip the surviving entry with the carry-over phrases spliced in (via `parse_backlog_tree` on a synthetic tree-fragment); assert the parse re-serialises byte-identical. This delegates the "no metadata-key-shape" enumeration to the validator rather than hand-maintaining a list of forbidden prefixes.
- [ ] `chmod +x /tmp/.../preflight.pl && /tmp/.../preflight.pl /home/matt/repo/coding-with-files/implementation-guide/146-.../recommendations.md "$(cat /tmp/.../baseline.sha)"` (absolute path to recommendations.md per security review F5).
- [ ] **Failure path**: non-zero exit halts the batch. Maintainer amends `recommendations.md` (re-classifies rows, switches to `--exact-title=`, fixes targets, reshapes carry-overs). The amendment commits as a new `Task 146: Pre-flight resolution -- ...` commit on the artefact, becoming the new approval anchor (AC2 follows the latest artefact commit). Re-run pre-flight.

### Step 5: Seed Task 146 CHANGELOG block (commit "Task 146: Seed CHANGELOG block")
*Step 5 is mandatory: `backlog-manager retire` dies with "Task $task has no CHANGELOG entry; create the entry first" if the `## Task N:` block is absent (verified at `backlog-manager:464`).*
- [ ] Edit CHANGELOG.md to insert a `## Task 146: Backlog refactor: retire, merge, reduce` block immediately above the existing `## Task 145:` block, with `### Status: In Progress`, `### Duration: TBD`, `### Impact: TBD` placeholders.
- [ ] `backlog-manager validate` -> must exit 0.
- [ ] `git add CHANGELOG.md && git commit -F /tmp/.../msg-step5.txt`.

### Step 6: Apply loop (per-row commits; one commit per non-keep row)
Iterate the approved artefact in order. **Precondition for every iteration**: `git diff --quiet -- BACKLOG.md CHANGELOG.md` (working tree on these files must be clean). If not, halt and surface -- the previous iteration left state behind.

- [ ] **retire**:
  1. `backlog-manager retire --task=146 --id=<slug>` (or `--exact-title="<title>"` if Step 4 flagged a collision)
  2. `backlog-manager validate`
  3. If clean: `git add BACKLOG.md CHANGELOG.md && git commit -F /tmp/.../msg-retire-<slug>.txt` (message: "Task 146: Retire <title>")
  4. If not clean: `git checkout -- BACKLOG.md CHANGELOG.md` -> halt -> surface (no commit was made; nothing to revert).

- [ ] **merge** (single commit per c-design D5; the FR6 trace is verified in CHANGELOG.md, not in an interim BACKLOG.md state -- AC5 wording in b-requirements is acknowledged-loose):
  1. Edit BACKLOG.md to insert carry-over phrases into the surviving entry's body (paste them as plain text bullets under the entry's existing metadata; verbatim title preserved on both source and survivor).
  2. `backlog-manager validate` -- catches mal-formed Edits immediately, attributing the failure to the Edit rather than to retire (robustness F1).
  3. `backlog-manager retire --task=146 --id=<source-slug>` (or `--exact-title=...`).
  4. `backlog-manager validate`.
  5. If both validates clean: `git add BACKLOG.md CHANGELOG.md && git commit -F /tmp/.../msg-merge-<source-slug>.txt`.
  6. If either validate failed: `git checkout -- BACKLOG.md CHANGELOG.md` -> halt -> surface.

- [ ] **reduce-scope**:
  1. Edit BACKLOG.md body (title preserved per c-design D5 invariant -- slug stability).
  2. Optional: `backlog-manager modify --id=<slug> --priority=<value>` (run AFTER the body Edit, so all body changes are in place before the helper rewrites the file).
  3. `backlog-manager validate`.
  4. If clean: `git add BACKLOG.md && git commit -F /tmp/.../msg-reduce-<slug>.txt`. (Note: `git checkout -- BACKLOG.md CHANGELOG.md` on the failure path is uniform with the other actions; the no-op on an unmodified CHANGELOG.md is harmless.)
  5. If not clean: `git checkout -- BACKLOG.md CHANGELOG.md` -> halt -> surface.

- [ ] **keep-as-is**: no commit.

**Halt protocol** per c-design D6: print to stderr the failing row's title, selector, action, index `<i>/<N>` within the approved artefact, plus captured tool output. Surface to the user.

**Mid-stream abandonment**: per Scope Completion below. The recommendations artefact and its approval commit are preserved; mutation commits revert in LIFO order via `git revert <sha>` (per c-design D6's post-commit path), each revert being its own commit.

### Step 7: Post-batch validation (no commit)
- [ ] Final `backlog-manager validate` exits 0.
- [ ] **AC4 per-commit assertion** (validator on every intermediate state): walk the apply-loop commits and verify each was committed only after a clean validate. The simplest mechanical check is a worktree replay:
  ```
  for sha in $(git rev-list "$(cat /tmp/.../baseline.sha)..HEAD" -- BACKLOG.md CHANGELOG.md); do
    git -C <worktree> checkout "$sha" -- BACKLOG.md CHANGELOG.md \
      && backlog-manager validate
  done
  ```
  (Set up the temp worktree under `/tmp/.../validate-worktree/` first; tear it down after.) Any non-zero result is an AC4 violation.
- [ ] **AC6 diff-scoped ASCII purity** -- BACKLOG.md/CHANGELOG.md are already validator-gated and round-trip checks reject any breaking byte, so the bespoke grep is scoped to recommendations.md only:
  ```
  git diff "$(cat /tmp/.../baseline.sha)..HEAD" -- implementation-guide/146-.../recommendations.md \
    | LC_ALL=C grep -cP '^\+.*[^\x00-\x7F]'
  ```
  Must return 0.
- [ ] **AC1 coverage**: `grep -c '^## Recommendation: ' recommendations.md` equals `git show "$(cat .../baseline.sha)":BACKLOG.md | grep -c '^## Task: '`.
- [ ] **AC2 ordering**: `git log --oneline -- recommendations.md` shows the approval (and any pre-flight resolution) commits; `git log --oneline -- BACKLOG.md CHANGELOG.md` shows no mutation commit predating the latest artefact commit.
- [ ] **AC3 CHANGELOG seed**: first commit touching CHANGELOG.md on the branch is the Step 5 seed commit.
- [ ] **AC5 merge-enrichment trace**: for each merge row, every listed carry-over phrase is `grep`-findable in CHANGELOG.md (under the retired source-entry's `#### <title>` block; paraphrasing permitted).
- [ ] **AC7 no orphan broken commits**: `git log --oneline "$(cat .../baseline.sha)..HEAD"` shows no abandoned non-revertable state.

## Code Changes

### Recommendations artefact preamble (Step 2 commit)
```
# Task 146: Recommendations -- backlog refactor

Baseline: <40-char SHA>
Generated: <YYYY-MM-DD>
Approval:
```

### Recommendations row (one per BACKLOG entry; Step 2 commit)
```
## Recommendation: Add Delete Task Skill
- Selector: --id=add-delete-task-skill
- Priority: High
- Action: retire
- Rationale: Implemented in Task 136 (Delete most-recent task only); the broader scope of this backlog item is covered by the in-flight `/cwf-delete-task` skill plus follow-up items already in BACKLOG.
```

### CHANGELOG seed (Step 5 commit)
```
## Task 146: Backlog refactor: retire, merge, reduce

### Status: In Progress
### Duration: TBD
### Impact: TBD
```

### Pre-flight script skeleton (Step 4, transient)
```
#!/usr/bin/env perl
use strict; use warnings; use utf8;
use lib "$ENV{HOME}/repo/coding-with-files/.cwf/lib";
use CWF::Backlog qw(parse_backlog_tree find_all_entries_by_slug);
use CWF::Common  qw(generate_slug);
# Parse recommendations.md sections; for each, run the four D8 checks
# using the imported library functions. Print findings; exit non-zero on
# any failure. Core modules only (per project Perl convention).
```

## Test Coverage
**See e-testing-plan.md for complete test plan**. Verification gates are validator-clean + round-trip + the ACs in Step 7.

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**. Every commit on this branch from Step 5 onward must leave `backlog-manager validate` clean and BACKLOG.md / CHANGELOG.md round-trip byte-identical.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

This task is bounded: the apply loop terminates when every non-keep row has been applied or halted-and-reverted. The classification artefact remains preserved as a discovery output (under `implementation-guide/146-.../`). No follow-up tasks are implicitly carried into this task's commits.

**Pre-flight failure (Step 4)**: if a contested row blocks pre-flight, the maintainer amends `recommendations.md` (typically re-classifying the row to `keep-as-is` or restructuring the merge). The amendment is a new commit on the artefact and becomes the new approval anchor; pre-flight re-runs.

**Mid-stream abandonment (post-Step 5)**: if the maintainer chooses to stop part-way through, mutation commits revert in LIFO order via individual `git revert <sha>` commits (one per reversion). The recommendations artefact and its approval commits remain in the branch history. `git reset --hard` is forbidden -- it is destructive and discards the audit trail.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 7 implementation steps executed. 4 deviations recorded in f-implementation-exec.md (D1 regex coverage, D2 selector form, D3 bash pre-flight, D4 TC-AC5 wording).

## Lessons Learned
**Step 1 baseline regex (`^## Task: '`) was incomplete.** The BACKLOG parser at `CWF::Backlog.pm:222` also accepts `^## Bug: '`. Caught in f-Step-1 by cross-checking the regex count against `backlog-manager list --all-items` (67 vs 68). Lesson: when plan-baking a corpus-count check, the count must come from the same source the helper uses, not from a hand-derived regex. **The realised pre-flight was a bash one-liner, not the planned Perl helper (D3).** Justifiable for 3 merge rows, but the bash regex caught `- Priority:` shape and missed `### Status:` shape. The Perl-with-`CWF::Backlog`-round-trip approach remains correct for larger or `--id=`-heavy artefacts.
