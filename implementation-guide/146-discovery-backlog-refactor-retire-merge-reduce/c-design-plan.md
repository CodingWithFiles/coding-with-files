# Backlog refactor: retire, merge, reduce - Design
**Task**: 146 (discovery)

## Task Reference
- **Task ID**: internal-146
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/146-backlog-refactor-retire-merge-reduce
- **Template Version**: 2.1

## Goal
Specify the recommendations artefact schema, the per-action edit mechanic, the commit-ordering protocol, and the pre-flight / halt-on-failure procedures that together satisfy b-requirements without introducing new code.

## Design Priorities
Testability -> Readability -> Consistency -> Simplicity -> Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### D1 -- No new code; this is process design over existing helpers
- **Decision**: The task ships a markdown artefact and a set of commits. No new helper, no new flag, no parser change. `backlog-manager retire` / `validate` / `list --all-items` / `modify --priority` are used as-is. Merge enrichment and reduce-scope body / priority edits go via Edit/Write on BACKLOG.md.
- **Format gate**: The single gate for every BACKLOG.md / CHANGELOG.md mutation is `backlog-manager validate` (the project's BACKLOG/CHANGELOG format validator). `cwf-manage validate` is a different validator (config / workflow / templates / perl) and is not used as a gate in this task -- it remains the post-commit informational check inside `cwf-checkpoint-commit` for the phase-transition commits (a / b / c / d / e / f / j wf-file commits) only.
- **Rationale**: Discovery task type; b-requirements Constraint forbids leaving new functionality behind. The existing helper surface fits the workflow if we accept the direct-Edit carve-out for merge / reduce-scope.
- **Trade-offs**: Gives up a machine-checkable "merge enrichment preserved the union" -- relies on FR6 carry-over phrases being human-readable. Buys zero install / migration / rollback surface.

### D2 -- Recommendations artefact is per-entry sections, not a flat table
- **Decision**: `recommendations.md` under the task directory uses one `## Recommendation: <Title>` section per entry, with `- Selector:`, `- Priority:`, `- Action:`, optional `- Target:`, `- Carry-overs:`, `- Rationale:` fields. A short preamble carries `Baseline:`, `Generated:`, and an empty `Approval:` line.
- **Rationale**: 68 multi-sentence rationales plus multi-bullet merge carry-overs do not fit a markdown table without truncation. Per-section format is editor-friendly, the user's amendments are clearly diffable, and the section-count invariant (AC1) is testable with `grep -c '^## Recommendation: '`.

### D3 -- Approval recorded as the `Approval:` line in the artefact preamble
- **Decision**: The maintainer writes (or pastes) approval text into the artefact's `Approval:` line, then commits the artefact alone. This commit is the audit anchor for FR3. No special phrase is required in the commit message -- the audit is by path-touched (`git log -- recommendations.md`) and by inspecting the preamble at that revision.
- **Rationale**: Avoids "the approval lives in conversation" auditability gap. The artefact-with-approval is a single committed object; no implicit string consumer is created.

### D4 -- Baseline pinning is by SHA in the preamble; no inline snapshot
- **Decision**: `Baseline: <40-char-SHA>` in the preamble. The baseline backlog state can be regenerated on demand with `git show <SHA>:BACKLOG.md`. The artefact does not embed a full snapshot. AC1's coverage check is `git show <SHA>:BACKLOG.md | grep -c '^## Task: '` compared against `grep -c '^## Recommendation: ' recommendations.md`.
- **Rationale**: A snapshot would duplicate ~2k lines of BACKLOG.md content and rot the moment BACKLOG.md is edited. SHA-only keeps the artefact small and authoritative-by-reference.
- **Note**: There is no `--baseline=<SHA>` flag on `backlog-manager list`; do not invent one. The baseline-enumeration mechanism is the `git show` invocation above.

### D5 -- Per-action edit mechanic
- **Decision**: Action-to-mechanic mapping is fixed:
  - **retire**: `backlog-manager retire --task=146 (--id=<slug> | --exact-title="<title>")` -> `backlog-manager validate` -> if clean: `git add BACKLOG.md CHANGELOG.md && git commit`; if not: `git checkout -- BACKLOG.md CHANGELOG.md` (helper ran but produced an invalid result -- abort without committing).
  - **merge**: single commit. Edit BACKLOG.md to insert carry-over phrases into the surviving entry's body. Then `backlog-manager retire --task=146 --id=<source-slug>`. Then `backlog-manager validate`. If clean: `git add BACKLOG.md CHANGELOG.md && git commit`. If not: `git checkout -- BACKLOG.md CHANGELOG.md` and halt. (Atomic revert at single-commit granularity preserves invariants regardless of which sub-step regressed.)
  - **reduce-scope**: Edit BACKLOG.md to rewrite the entry's body (and optionally invoke `backlog-manager modify --id=<slug> --priority=<value>` for priority downgrade). **Title rewrites are forbidden** -- changing the title invalidates the slug and breaks any later row referencing this entry. Then validate; if clean, commit; if not, checkout-discard and halt.
  - **keep-as-is**: no commit.
- **Rationale**: Each action maps to the smallest helper or Edit invocation. Atomic single-commit merges remove the "what if commit 1 succeeded but commit 2 failed" partial-state class. Title-rewrite ban preserves selector stability across the batch.

### D6 -- Failure handling distinguishes pre-commit and post-commit paths
- **Decision**:
  - **Helper or validate failed before commit**: working-tree mutations are discarded with `git checkout -- BACKLOG.md CHANGELOG.md`. No commit is made; no revert is needed. The batch halts.
  - **A commit landed and a later step regressed**: `git revert <sha> --no-edit`, then `git commit --amend` with a body containing the failing tool output inside a triple-backtick fenced code block (fencing prevents accidental markdown interpretation by any downstream LLM consumer). The batch halts.
- **Halt protocol**: print to stderr the failing row's title, selector, action, index `<i>/<N>` within the approved recommendations artefact, plus the captured tool output. Surface to the user for direction before any further row is processed.
- **Rationale**: Pre-commit failure leaves nothing to revert; post-commit failure leaves something to revert; the two paths are not interchangeable. Fencing protects against tool output that contains backticks or `#` characters.

### D7 -- Task 146 CHANGELOG block seeded as the first CHANGELOG mutation on the branch
- **Decision**: Before any retire runs, a dedicated commit adds `## Task 146: Backlog refactor: retire, merge, reduce` plus the standard `### Status: In Progress`, `### Duration:`, `### Impact:` placeholders to CHANGELOG.md. All retire commits append `#### <title>` blocks under that heading's `### Retired Backlog Items` subsection (helper does the appending).
- **Rationale**: `backlog-manager retire` requires a pre-existing `## Task N:` block; the in-progress branch's CHANGELOG.md does not yet carry a Task 146 entry (verified by reading CHANGELOG.md head: latest block is Task 145). Seeding is a one-time prerequisite, not per-retire boilerplate.

### D8 -- Pre-flight checks before any apply commit runs
- **Decision**: After the approval commit and before the CHANGELOG seed, a one-shot pre-flight pass over the approved artefact verifies:
  1. **Slug uniqueness**: every `--id=<slug>` selector resolves to exactly one BACKLOG entry at the baseline SHA; collisions force the offending rows to use `--exact-title="<title>"` instead.
  2. **Target resolution**: every `merge` row's `Target:` selector resolves to another row in the artefact.
  3. **No cycles, no dangling targets**: follow each merge chain; it must terminate at a row whose terminal action is `keep-as-is` or `reduce-scope`; cycles fail the pre-flight.
  4. **Carry-over phrases are safe**: no listed carry-over phrase starts a line with `#`, `### `, `- Priority:`, `- Status:`, or any other BACKLOG metadata-key shape -- this would round-trip-corrupt the survivor entry.
- **Mechanism**: a one-shot Perl helper in the project-namespaced scratch dir (`/tmp/-home-matt-repo-coding-with-files-task-146/preflight.pl`), invoked once, output captured to the same dir. The script is throwaway; it does not get checked in (per b-Constraints / NFR3).
- **Rationale**: 68 rows is enough that hand-verification of uniqueness + cycles + carry-over shape is unreliable. The pre-flight catches malformed-but-passes-validate cases before any commit lands.

### D9 -- All helper invocations use argv form, never `bash -c`
- **Decision**: Every `backlog-manager ...` / `git ...` invocation is run with arguments as separate `argv` entries (the default form for the user's typed-or-pasted commands; the default form for `Bash` tool invocations). The batch must not be wrapped in `bash -c "<long string>"` or any other string-form spawn.
- **Rationale**: String-form spawn would re-introduce a §(a) bash-injection surface that the helpers' own list-form internal spawn carefully avoids. Stated explicitly so a future implementer scripting the batch does not "helpfully" wrap it.

## System Design

### Component Overview
- **Recommendations artefact** (`implementation-guide/146-.../recommendations.md`): single source of truth for per-entry classification, approval, and merge plans. Created in f-phase, never mutated by `backlog-manager`.
- **BACKLOG.md**: read at baseline, mutated in f-phase by `retire` and direct Edit. Validated by `backlog-manager validate` after every mutation.
- **CHANGELOG.md**: seeded with the Task 146 block, then appended to by `retire`.
- **`backlog-manager` helper** (existing): `list --all-items` (one-time enumeration), `retire` (retirement path), `validate` (format gate), `modify --priority` (priority downgrade).
- **Pre-flight script** (transient, `/tmp/-home-matt-repo-coding-with-files-task-146/preflight.pl`): one-shot, not committed; checks slug uniqueness, target resolution, cycles, carry-over safety.

### Data Flow
1. **Baseline capture (f-phase, commit 0)**: pin baseline SHA = current HEAD; run `backlog-manager list --all-items` once for the human's reference; create the artefact's section list from `git show <SHA>:BACKLOG.md` (entries identified by `^## Task: ` headings).
2. **Recommendations draft (f-phase, commit 1)**: author one `## Recommendation: ...` section per BACKLOG entry; classify; rationalise; commit artefact only.
3. **User-approval gate (f-phase, commit 2)**: maintainer fills `Approval:` line (and any amendments); commit artefact only.
4. **Pre-flight (f-phase, no commit)**: run D8 checks; failure surfaces for user direction; success proceeds.
5. **CHANGELOG seed (f-phase, commit 3)**: add `## Task 146:` block to CHANGELOG.md; commit CHANGELOG.md only.
6. **Apply loop (f-phase, commits 4..N)**: for each non-keep row in approved order, dispatch per D5; each commit touches BACKLOG.md (+ CHANGELOG.md for retire / merge) and nothing else; `backlog-manager validate` gates each.
7. **Halt-on-failure**: per D6.

### Interface Design

#### Recommendations artefact schema
```
# Task 146: Recommendations -- backlog refactor

Baseline: <40-char-SHA>
Generated: YYYY-MM-DD
Approval: <empty until maintainer fills>

---

## Recommendation: <verbatim entry title>
- Selector: --id=<slug>            (or --exact-title="...")
- Priority: <Very Low | Low | Medium | High | Very High>
- Action: <retire | merge | reduce-scope | keep-as-is>
- Target: --id=<slug>              (merge only)
- Carry-overs:                     (merge only; one bullet per phrase)
  - "<phrase from source that must appear in survivor>"
- Rationale: <one or more sentences; required for non-keep actions>
```

#### Per-action helper invocations
- Retire: `backlog-manager retire --task=146 --id=<slug>`
- Modify priority (optional, reduce-scope): `backlog-manager modify --id=<slug> --priority=<value>`
- Format gate (after every working-tree mutation, before commit): `backlog-manager validate`
- All invocations argv-form per D9.

#### Failure-mode contract
- Pre-commit failure: `git checkout -- BACKLOG.md CHANGELOG.md`, halt, surface.
- Post-commit failure: `git revert HEAD --no-edit && git commit --amend` with fenced tool output, halt, surface.

### Security boundary (carried from b-NFR4 and security-reviewer notes)
- Artefact is single-consumer (the maintainer, once, in this task). It is not machine-re-read in any later task.
- All helper invocations are argv-form (D9); no `bash -c` wrapping.
- Tool output quoted into revert commit bodies is fenced (D6) to suppress accidental markdown interpretation downstream.

## Constraints
- All constraints from b-requirements (pure ASCII; helper-mediated retirement; no new functionality; round-trip + format-validator gate) carry through.
- Per-commit scope discipline: each f-phase commit touches at most one of: {recommendations.md}, {CHANGELOG.md alone (seed)}, {BACKLOG.md and/or CHANGELOG.md (apply-loop)}. Never mixes artefact and content edits in the same commit.

## Decomposition Check
See `a-task-plan.md#decomposition-check`. No change.

## Validation
- [x] Design satisfies every b-FR and every b-AC (cross-reference: D2 -> FR1/AC1; D3 -> FR3/AC2; D4 -> FR2; D5 -> FR4/FR5/FR6 and AC3/AC5; D6 -> FR7/AC7; D7 -> FR4/AC3; D8 -> AC1 cycle/dangling clause; D9 -> security-review F1).
- [x] No new persistent components; transient pre-flight script lives in scratch dir and is not committed.
- [x] Helper interfaces match verified `--help` output (`backlog-manager retire`, `list`, `modify`, `validate`); no invented flags.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 9 decisions held end-to-end. D5 single-commit-per-merge was the load-bearing choice: every merge's pre-commit failure path collapses to a uniform `git checkout -- BACKLOG.md CHANGELOG.md` discard. D6 post-commit revert path was never exercised (no post-commit regressions observed). D8 pre-flight ran without flagging any of the 4 conditions.

## Lessons Learned
**Single-commit merge atomicity removed a whole class of "partial-state" reasoning.** The two-commit-per-merge alternative (Edit first, retire second) creates a half-finished state that must be characterised on every failure mode. Collapsing to one commit makes the discard path uniformly correct regardless of which sub-step regressed. **D9 argv-form discipline held without effort** -- the helper invocations are all short and natural to argv. No temptation to wrap in `bash -c "<long string>"` appeared at any point.
