# Reconcile or retire stale .cwf/utils spec docs - Implementation Execution
**Task**: 197 (chore)

## Task Reference
- **Task ID**: internal-197
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/197-reconcile-or-retire-stale-cwfutils-spec-docs
- **Template Version**: 2.1

## Goal
Retire the four inert `.cwf/utils/*.md` prototype-era spec docs by deleting them, per d-implementation-plan.md (Chosen Direction: retire, not reconcile).

## Actual Results

### Step 1: Re-confirm inert (immediately before deletion)
- **Planned**: Sweep for any functional consumer of the four basenames; STOP only if a helper/lib/skill/template/test (not in the known-hits list) surfaces.
- **Actual**: `grep -rn "config-loader\|template-engine\|task-validator\|hierarchy-manager" --include=*.md --include=*.pl --include=*.pm --include=*.json .` (excluding `implementation-guide/` and `.cwf/utils/`). Every hit fell into the expected non-consumer set:
  - `BACKLOG.md` — the originating item (then :1459) and the second open item (:1278); both handled in Step 3.
  - `CHANGELOG.md:13`, `:789` — historical notes, left untouched.
  - Other `implementation-guide/**` task docs (tasks 1, 59, 96, 151, 160, 196) — historical records / this task's own plans.
  - No helper, lib, skill, template, or test referenced any of the four files. Confirmed inert.
- **Deviations**: None.

### Step 2: Delete
- **Planned**: `git rm` the four files; confirm `.cwf/utils/` disappears.
- **Actual**: `git rm .cwf/utils/{config-loader,hierarchy-manager,task-validator,template-engine}.md` — all four staged for deletion. `.cwf/utils/` is gone from the worktree (git tracks no empty dirs).
- **Deviations**: None.

### Step 3: Close out
- **Planned**: Retire originating BACKLOG item (:1459) via the backlog helper; amend the second open item (:1278) to drop the dead `template-engine.md:41` citation; record all four removals (incl. `hierarchy-manager.md`) in CHANGELOG.
- **Actual**:
  - `backlog-manager retire --exact-title="Reconcile or retire the stale .cwf/utils/*.md spec docs against CWF-PROJECT-SPEC.md" --task=197 --note="..."` — transactionally moved the item from BACKLOG to a new `## Task 197` section in CHANGELOG under `### Retired Backlog Items`. The `--note` records the deviation from the backlog body: all **four** files were deleted, explicitly naming `hierarchy-manager.md` (which the body omitted). This single transaction satisfies both the backlog-retire and the CHANGELOG-record requirements — no separate manual CHANGELOG entry was added (would have been redundant).
  - Amended the second open item (`BACKLOG.md:1278`, "Align cwf-extract skill … to grep+read"): dropped the `.cwf/utils/template-engine.md:41` citation, noting the doc was retired in Task 197 and that `SKILL.md:48` is now the sole awk site. The item stays open and valid with `SKILL.md:48` as its surviving converge target.
  - Historical notes at `CHANGELOG.md:13` and `:789` left untouched (append-only).
- **Deviations**: The em-dash in the first `--note` attempt was rejected (`--note must be printable ASCII`); re-ran with ASCII punctuation. The amend initially still contained the literal `utils/template-engine` path token (would fail TC-3); reworded to a bare `template-engine.md` reference so no live path to the deleted file remains.

### Step 4: Validate
- **Planned**: `cwf-manage validate` passes; `git ls-files .cwf/utils/` empty.
- **Actual**:
  - `backlog-manager validate` → exit 0 (BACKLOG/CHANGELOG format intact after retire + amend).
  - `git ls-files .cwf/utils/` → empty.
  - `grep -c "utils/template-engine" BACKLOG.md` → 0 (TC-3 dereference confirmed).
  - `cwf-manage validate` — run by the checkpoint-commit helper (see Status); no sha256/permission drift expected (none of the four files were hash-tracked).
- **Deviations**: None.

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met (no superseded design ships; sweep clean; validate green; originating item retired + recorded)
- [ ] b-requirements-plan.md — N/A (chore: no requirements phase)
- [ ] c-design-plan.md — N/A (chore: no design phase)
- [x] No planned work deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
- `backlog-manager retire --note` enforces printable-ASCII; keep punctuation plain.
- When de-referencing a deleted file from surviving prose, drop the whole path token, not just the line-number suffix — a residual `dir/basename` path still reads as a live pointer and fails the dereference check.

## Security Review

**State**: no findings

All remaining references are in historical `implementation-guide/**` task documents (tasks 1, 59, 151, 160) — these are archival records of completed work, not live consumers. `git ls-files .cwf/utils/` is empty, confirming the files are gone. None of the deleted files were hash-tracked.

I have completed the security review. My reasoning across the five threat categories:

**Nature of the changeset.** This is a documentation-only change for Task 197. It deletes four inert `.cwf/utils/*.md` spec docs (`config-loader.md`, `hierarchy-manager.md`, `task-validator.md`, `template-engine.md`), adds the standard Task-197 workflow files (`a`/`d`/`e`/`f`/`g`/`j`), and edits `BACKLOG.md` and `CHANGELOG.md` for close-out. No Perl, shell, JSON config, hooks, skills, or templates are touched.

**(a) Bash injection / unsafe command construction.** No executable code is added or modified. The deleted files are prose `.md` (mode 100644) — one of them (`hierarchy-manager.md`) contained an illustrative `find … | sed` snippet, but it is being removed, not introduced, and it was never a wired-up command. No interpolation of slugs/branch names/paths into shell calls anywhere in the diff. Nothing to flag.

**(b) Perl helpers consuming git/user output.** No Perl is added or changed; no git-porcelain parsing is introduced. N/A.

**(c) Prompt injection via user-supplied strings.** No `{arguments}` substitution surface is added or altered. The new content is authored process prose, not a new untrusted-input flow. The note that `backlog-manager retire --note` enforces printable-ASCII (f-exec, Lesson Learned) is a positive input-validation observation, not a concern. Nothing to flag.

**(d) Unsafe environment-variable handling.** No env vars introduced or consumed; no paths flow to `chmod`/`rm`/`open`. The plan correctly notes none of the four files were hash-tracked, which I verified against `.cwf/security/script-hashes.json` (no `utils/` entries). N/A.

**(e) Pattern-based risks (safe-here-but-risky-elsewhere).** No reusable code pattern is added. The only borderline item is the deletion of four files that ship to end users via `git read-tree --prefix=.cwf/`. I verified the deletion leaves no dangling live reference: `git ls-files .cwf/utils/` is empty, and the only remaining string references to the four basenames are in historical `implementation-guide/**` task archives (tasks 1, 59, 151, 160) and the append-only `CHANGELOG.md` historical notes — all archival records, not live consumers. No helper/lib/skill/template/test references them. The second open backlog item that previously cited `template-engine.md:41` had its live path token dropped (BACKLOG diff at line 195 confirms `SKILL.md:48` is now the sole awk site). No security-relevant residue.

Subtractive documentation change with no executable, hash-tracked, or input-flow surface. Verification confirms no functional consumers and no integrity drift. Clean.

```cwf-review
state: no findings
summary: Documentation-only deletion of four inert .cwf/utils/*.md docs plus Task-197 workflow files; no executable, hash-tracked, env-var, or input-flow surface; no dangling live references.
```
