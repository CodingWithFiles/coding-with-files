# Sync README command reference - Implementation Execution
**Task**: 169 (chore)

## Task Reference
- **Task ID**: internal-169
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/169-sync-readme-command-reference
- **Template Version**: 2.1

## Goal
Execute the four README edits from d-implementation-plan.md.

## Actual Results

### Step 1: Add the 3 missing skills
- **Planned**: add cwf-delete-task, cwf-current-task (Core), cwf-backlog-manager (Utility)
- **Actual**: done. `cwf-delete-task` + `cwf-current-task` added to Core Commands (README:110,113); `cwf-backlog-manager` added to Utility Commands. One-liners derived from each `SKILL.md` description.
- **Deviations**: none.

### Step 2: Fix cwf-new-task AND cwf-new-subtask signatures
- **Planned**: `<type>` → `[<type>]` on README:109/110
- **Actual**: done — both now show `[<type>]` with an "inferred when omitted" note. Also fixed a third stale instance found during verification: README:245 (Contributing) showed the invalid `/cwf-new-task feature`; corrected to `/cwf-new-task <num> feature "description"`.
- **Deviations**: +1 in-scope fix (line 245) beyond the planned two — same defect class (incorrect signature), surfaced by TC-4.

### Step 3: Document cwf-manage
- **Planned**: short subcommand list under Utility, framing fix-security as a narrow carve-out
- **Actual**: done — added an "Installation Management (`cwf-manage`)" subsection listing all 7 subcommands (status, list-releases, update, rollback, validate, fix-security, help); `fix-security` framed as perms-repair-only-when-sha256-matches, explicitly "not a way to clear a warning".
- **Deviations**: none.

### Step 4: Add discovery task type
- **Planned**: `### Discovery Tasks (8 phases)` after Chore
- **Actual**: done — added with the 8-phase chain (a,b,c,d,e,f,g,j).
- **Deviations**: none.

## Verification (pre-handoff sanity, full run in g-testing-exec)
- TC-1 skill set diff: zero shipped skills missing; only `cwf-manage` (a script) and `cwf-project` (cwf-project.json false positive) appear README-but-not-shipped — both expected.
- TC-3 task types == cwf-project.json:supported-task-types {feature,bugfix,hotfix,chore,discovery}.
- TC-4 both signatures show `[<type>]`.
- TC-5 all 7 cwf-manage subcommands present.
- `git diff` confined to Commands / cwf-manage / Task Types / Contributing-example regions.
- `cwf-manage validate`: OK.

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] Requirements/design phases N/A for a chore
- [x] No planned work deferred

## Security Review

**State**: no findings

no findings: empty changeset

(README.md is a human-facing doc, not a CWF-internal path and carries no shebang, so
`security-review-changeset --phase=implementation` resolved to `reviewed 0 files, 0 lines
(0 production), anchor=7c676c8` — nothing in scope for the changeset reviewer.)

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 169
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
