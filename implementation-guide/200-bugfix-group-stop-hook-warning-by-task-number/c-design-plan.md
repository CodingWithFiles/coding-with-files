# Group Stop-hook warning by task number - Design
**Task**: 200 (bugfix)

## Task Reference
- **Task ID**: internal-200
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/200-group-stop-hook-warning-by-task-number
- **Template Version**: 2.1

## Goal
Define the grouped output format for the Stop-hook uncommitted-files warning
and the algorithm that derives, groups, caps, and renders it.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Current Behaviour (baseline)
`.cwf/scripts/hooks/stop-uncommitted-changes-warning` runs
`git status --porcelain -z --untracked-files=all -- 'implementation-guide/*/[a-j]-*.md'`,
strips each record's status prefix and path to its **bare basename**, shows the
first 3, then `+N more`, and prints
`{"systemMessage":"⚠ Uncommitted: <list>"}`. The owning task is discarded at the
`m{([^/]+)$}` basename step (line 21), so the operator cannot tell which task a
dirty file belongs to.

## Key Decisions

### D1 — Task number is the number of the file's immediate parent dir, via `parse_dirname`
Each record path is `implementation-guide/<dir>[/<subdir>...]/[a-j]-*.md`. The
owning task is the **directory immediately containing the file**; its number is
the first element returned by `CWF::TaskPath::parse_dirname($parent_basename)`
(regex `^(\d+(?:\.\d+)*)-(\w+)-(.+)$`, `.cwf/lib/CWF/TaskPath.pm:305`).
- `implementation-guide/199-discovery-…/j-retrospective.md` → `199`
- `implementation-guide/28-feature-…/28.1-chore-…/f-implementation-exec.md` → `28.1`

**Reuse, not a fresh regex.** The hook loads the canonical helper via
`use FindBin; use lib "$FindBin::Bin/../../lib"; use CWF::TaskPath qw(parse_dirname);`
— the exact lib-loading pattern the sibling Stop hook
`stop-stale-status-detector:14-17` already uses, so this introduces no new
dependency style for the hooks directory. This avoids adding a fourth inline
copy of the task-number regex that `TaskPath.pm` exists to consolidate
(design-alignment, single-source-of-truth).

**Fallback for a non-task parent dir.** The git pathspec does not *enforce* a
`<num>-<type>-<slug>` parent (e.g. a stray `implementation-guide/scratch/a-x.md`
matches the glob). When `parse_dirname` returns `()` the file is grouped under
its **raw parent-dir basename** as the key — so a malformed path is still
surfaced, never dropped or interpolated as `undef`.

**Nested paths are reached.** Git pathspec `*` matches across `/`, so the
single-`*` glob `implementation-guide/*/[a-j]-*.md` *does* match the two-deep
nested-subtask file — verified empirically. The `28.1` case is live, not dead.

### D2 — Unified per-group render with single-task elision
One algorithm covers both cases; the single-task case is byte-identical to today.
- The baseline `return unless @records` guard is **retained**, so the renderer
  only ever sees ≥1 group (the zero-dirty case never reaches it).
- Group basenames by task number, preserving **first-seen order** (git status order)
  for both groups and files within a group.
- Render each group as `[<num>: ]<f1>, <f2>, <f3>[ +k more]`:
  - the `<num>: ` prefix is **emitted only when >1 group exists** (elided for a
    single task — criterion 2);
  - the per-group cap is **3 files** (same constant as today), with a per-group
    `+k more` for that group's overflow.
- Join groups with `; `.

**Rationale**: keeping the cap *per group* guarantees every dirty task's number
appears — a whole group is never silently dropped (criterion 3 / the top risk).
Single group ⇒ no prefix ⇒ identical to baseline. The total message length is
therefore **intentionally unbounded across groups** (N dirty tasks → up to N
`+k more`-capped segments): surfacing every owning task number is judged more
valuable than a hard line-length ceiling, and the message is advisory with
`exit 0` preserved. Concurrent dirty tasks are realistically 1–3, so this is an
accepted, not a probable, cost.

### D3 — Output envelope unchanged
Still one line of JSON `{"systemMessage":"⚠ Uncommitted: <msg>"}`, still
`exit 0` unconditionally, still wrapped in `eval { … }`. Group separators
(`;`/`,`/`: `) and task numbers (digits/dots) add **no new JSON-escaping
surface**. The basenames themselves are still interpolated unescaped — this is a
**pre-existing** property of the baseline (line 28), not regressed by this change,
and is bounded by the `[a-j]-*.md` pathspec to repo-authored wf filenames. Flagged
here so exec-phase security review does not read it as newly introduced; fixing
generic JSON escaping is out of scope for a byte-identical-single-task bugfix.

## System Design
### Data Flow
1. `git status --porcelain -z` → NUL-separated records (unchanged query).
2. For each record: strip 3-char status prefix → path; split into
   parent-dir basename + file basename; `parse_dirname(parent)` → number
   (or raw parent basename on `()`).
3. Fold into an ordered list of groups keyed by number (first-seen order).
4. Render per D2 → `$msg`.
5. `print` the JSON envelope; `exit 0`.

### Worked Examples
| Dirty files (task) | Output `systemMessage` |
|---|---|
| 8 files, all task 199 | `⚠ Uncommitted: j-retrospective.md, d-implementation-plan.md, e-testing-plan.md +5 more` |
| 2×199, 1×28.1 | `⚠ Uncommitted: 199: a-task-plan.md, c-design-plan.md; 28.1: f-implementation-exec.md` |
| 4×199, 1×30 | `⚠ Uncommitted: 199: a-…, c-…, d-… +1 more; 30: a-task-plan.md` |

## Constraints
- Perl core-only; `use utf8;`; hook must never exit non-zero.
- Single-line JSON systemMessage (consumed by the harness).
- Hashed script (`.cwf/security/script-hashes.json`, recorded perms **0500**):
  per the hash-updates convention the sha256 refresh lands in the **same commit**
  as the edit, and the working file is chmod'd back to the recorded `0500`.

## Decomposition Check
No signals triggered (see a-task-plan); single hook + test, well under a day.

## Validation
- [x] Design review completed (plan-review subagents, design type)
- [ ] Architecture approved by team
- [ ] Integration points verified

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Design implemented as specified: D1 (reuse `parse_dirname`, raw-key fallback for
non-task dirs), D2 (unified per-group render with single-task elision, per-group
cap), D3 (unchanged JSON envelope, pre-existing unescaped-basename property
disclosed and not regressed). One framing correction surfaced downstream: "git
status order" is git's **lexicographic-by-pathname** sort, not file-plant order —
the worked examples here (`199` before `28.1`, etc.) are correct under that sort;
the inaccurate framing was in e-testing-plan, now corrected in g-testing-exec.

## Lessons Learned
*Captured in j-retrospective.md*
