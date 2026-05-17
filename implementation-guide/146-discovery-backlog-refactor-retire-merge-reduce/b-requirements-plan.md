# Backlog refactor: retire, merge, reduce - Requirements
**Task**: 146 (discovery)

## Task Reference
- **Task ID**: internal-146
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/146-backlog-refactor-retire-merge-reduce
- **Template Version**: 2.1

## Goal
Specify what a backlog-refactor pass must produce and the guarantees it must hold, including the concrete mechanics for the three classification actions given the existing `backlog-manager` helper's capabilities and limits.

## Functional Requirements
### Core Features
- **FR1 -- Recommendations artefact is complete and well-formed**: A single artefact under the task directory enumerates every BACKLOG.md entry at the pinned baseline commit, exactly once, with: title, current priority, selector (`--id=SLUG` or `--exact-title=TITLE` -- matching the helper's vocabulary), action (`retire` / `merge` / `reduce-scope` / `keep-as-is`), and rationale for non-keep rows.
  - Acceptance: row count equals `git show <SHA>:BACKLOG.md | grep -c '^## Task: '` at the pinned baseline SHA; every non-keep row has a non-empty rationale; every `merge` row names a target selector matching another row whose terminal classification is `keep-as-is` or `reduce-scope` (cycles and dangling targets forbidden).
- **FR2 -- Baseline pinning**: The artefact records the baseline commit SHA explicitly in its preamble. All count / coverage checks resolve against that SHA, not against working-tree HEAD.
  - Acceptance: artefact contains a `Baseline:` line carrying a 40-char SHA equal to the branch's initial Task 146 commit.
- **FR3 -- User-approval gate is auditable**: The artefact carries an `Approval:` line that the maintainer fills in (verbatim approval text, or amendments enumerated row-by-row). Approval lands in a commit that precedes any commit mutating BACKLOG.md or CHANGELOG.md on this branch.
  - Acceptance: `git log --oneline -- <artefact>` shows an approval-bearing commit; `git log --oneline -- BACKLOG.md CHANGELOG.md` on this branch shows no mutation commit predating it.
- **FR4 -- Retire path uses the helper with explicit task scoping**: Approved `retire` actions execute via `backlog-manager retire --task=146 --id=<slug>` (or `--exact-title=<title>`). Task 146's CHANGELOG entry must exist before any retire runs.
  - Acceptance: the first retire-bearing commit on this branch is preceded by a commit that adds a `## Task 146:` heading to CHANGELOG.md.
- **FR5 -- Merge enrichment and reduce-scope use direct Edit, gated by validator**: Because `backlog-manager modify` v1 supports only `--priority`, merge enrichment (folding source rationales into the surviving entry) and reduce-scope (title/body rewrites) are performed via Edit/Write on BACKLOG.md directly. Every such commit must still pass `backlog-manager validate` and preserve the round-trip property.
  - Acceptance: each merge / reduce-scope commit's pre-commit validate exits 0; round-trip parse->serialise remains byte-identical for both files.
- **FR6 -- Merge preserves the distinguishing material from both sources**: For each approved `merge`, the artefact lists (in the merge row) the specific constraints / rationales that must be carried over from the source into the survivor. The surviving entry's post-merge body contains a recognisable trace of each listed item.
  - Acceptance: for each merge row, every listed carry-over phrase (paraphrasing permitted) appears in the surviving entry's body after the enrichment commit and before the retire commit.
- **FR7 -- Batch halts on validator or helper failure**: Non-zero exit from `backlog-manager retire`, or a post-edit validate regression, halts the batch. The current edit is reverted with `git revert <sha>` (preserving history) and the failure is surfaced for user direction before any further edit runs. No silent skip-and-continue.
  - Acceptance: post-task `git log` shows no orphaned "broken" commits; any revert commit's body cites the helper / validator output that triggered it.

### User Stories
- **As the project maintainer I want** a single artefact listing per-entry recommendations **so that** I can approve or amend the full plan in one review pass instead of negotiating each entry inline.
- **As the project maintainer I want** retirements to flow through the existing helper **so that** CHANGELOG.md stays a faithful audit trail and the round-trip invariant is never broken.

## Non-Functional Requirements
### Performance (NFR1)
- Whole-corpus review pass must complete in a single working session -- no overnight jobs, no resumable state required.
- `backlog-manager validate` after the full edit batch must remain sub-second on this corpus.

### Usability (NFR2)
- Recommendations artefact is readable as plain markdown in any text editor; no upper-plane Unicode introduced.
- Each row is self-contained: title + priority + selector + action + (rationale | target + carry-overs). The maintainer does not need to cross-reference other files to decide approve / amend on most rows.

### Maintainability (NFR3)
- No bespoke ad-hoc scripts left behind in the repo after the task closes; the artefact stays under the task directory as a preserved discovery output.

### Reliability (NFR5)
- Any approved edit that regresses `backlog-manager validate` or the round-trip property is reverted (see FR7) before continuing.

## Constraints
- Pure-ASCII invariant: no upper-plane codepoints introduced into BACKLOG.md, CHANGELOG.md, or the recommendations artefact. Use `--`, straight quotes, `...`.
- Helper-mediated retirement only; helper limits force direct Edit for merge enrichment and reduce-scope, but the validator + round-trip + revert-on-regression chain still gates every commit.
- Discovery task type: deliverable is reviewed plan + applied edits, not new functionality, helper, template, or schema.

## Decomposition Check
See `a-task-plan.md#decomposition-check`. No change.

## Acceptance Criteria
- [ ] **AC1 -- Artefact coverage** (FR1, FR2): row count equals `git show <SHA>:BACKLOG.md | grep -c '^## Task: '` at the pinned baseline SHA; every non-keep row has a non-empty rationale; merge-target chains terminate at `keep-as-is` or `reduce-scope` rows; no cycles.
- [ ] **AC2 -- Auditable approval** (FR3): `git log` on the branch shows an approval-bearing commit on the artefact that precedes every BACKLOG.md / CHANGELOG.md mutation commit.
- [ ] **AC3 -- Task 146 CHANGELOG seeded before retires** (FR4): first commit touching CHANGELOG.md on this branch adds the `## Task 146:` heading; all subsequent retire commits scope under `--task=146`.
- [ ] **AC4 -- Validator and round-trip clean after every edit-bearing commit** (FR5, FR7, NFR5): `backlog-manager validate` exits 0; parse->serialise byte-identical for both files.
- [ ] **AC5 -- Merge enrichments traceable** (FR6): each merge row's listed carry-over phrases are findable in the surviving entry's post-enrichment body.
- [ ] **AC6 -- Diff-scoped ASCII purity** (Constraints): `git diff <baseline>..HEAD -- BACKLOG.md CHANGELOG.md <artefact> | LC_ALL=C grep -cP '^\+.*[^\x00-\x7F]'` returns 0.
- [ ] **AC7 -- Batch halts on failure cleanly** (FR7): no orphan broken commits; any revert commits cite the triggering tool output.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 7 ACs verified by TC-AC1..TC-AC7 in g-testing-exec (7/7 PASS). FR1..FR7 all satisfied. NFR1 (sub-1s validate) measured at 0.087s.

## Lessons Learned
Draft introduced a phantom `--baseline=<SHA>` flag on `backlog-manager list`; caught by plan-review subagents and fixed in commit 017169a before c-design started. Lesson: verify helper flags against `--help` (or source) before writing them into an FR. The plan-review structural check fires on inventions of this kind reliably -- worth its time cost.
