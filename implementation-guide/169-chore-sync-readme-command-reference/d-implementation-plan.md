# Sync README command reference - Implementation Plan
**Task**: 169 (chore)

## Task Reference
- **Task ID**: internal-169
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/169-sync-readme-command-reference
- **Template Version**: 2.1

## Goal
Close the README ↔ shipped-command gaps identified by the audit below, bounded to
the command/skill reference. No behavioural code changes.

## Audit Findings (the "properly identify" output)
Method: diff README's documented commands against `.claude/skills/cwf-*`, each
`SKILL.md` description, `cwf-manage help`, and the per-type template symlink sets.

**Gaps to fix:**
1. **3 shipped skills undocumented** in the `## Commands` section:
   - `cwf-delete-task` — "Delete the most-recent task (reverse of /cwf-new-task)…"
   - `cwf-current-task` — "Manage the current task stack for context tracking"
   - `cwf-backlog-manager` — "Show or manipulate the project backlog/changelog"
2. **`discovery` task type undocumented** in `## Task Types`. It ships (8 phases:
   a,b,c,d,e,f,g,j — plan→requirements→design→impl-plan→impl-exec→testing-plan→
   testing-exec→retrospective) but the section lists only feature/bugfix/hotfix/chore.
3. **`/cwf-new-task` AND `/cwf-new-subtask` signatures stale**: README:109/110 show
   required `<type>`; both skills now infer type when omitted, so the forms are
   `<num> [<type>] "description"` and `<parent-path> <num> [<type>] "description"`
   (confirmed in both `SKILL.md`s).
4. **`cwf-manage` under-documented**: README references only `cwf-manage list-releases`
   (line ~219). Full subcommand set is status / list-releases / update / rollback /
   validate / fix-security / help (7 subcommands, per `cwf-manage help`).

**Verified accurate (no change needed):**
- All 17 currently-documented `/cwf-*` skills exist and are named correctly.
- The 4 documented task-type phase counts (feature 10, bugfix 7, hotfix 7, chore 6)
  match the template symlink sets exactly.
- The 10-phase workflow command list (a–j) is correct.

## Files to Modify
### Primary Changes
- `README.md` — the only file. Four edits, matching the four gaps above.

### Supporting Changes
- None. No code, config, or test files touched.

## Implementation Steps
### Step 1: Commands section — add the 3 missing skills
- [ ] Add `cwf-delete-task` and `cwf-current-task` to **Core Commands** (task-lifecycle grouping)
- [ ] Add `cwf-backlog-manager` to **Utility Commands**
- [ ] One-liners derived verbatim from each `SKILL.md` `description`

### Step 2: Commands section — fix `cwf-new-task` AND `cwf-new-subtask` signatures
- [ ] README:109 — `<num> <type>` → `<num> [<type>]`; note type is inferred when omitted
- [ ] README:110 — `<num> <type>` → `<num> [<type>]` (same fix; subtask also infers)

### Step 3: Commands section — document `cwf-manage`
- [ ] Add a short `cwf-manage` subcommand sublist (status, list-releases, update, rollback, validate, fix-security, help — all 7) under Utility Commands, noting it is a script (not a `/`-skill) for install management
- [ ] Phrase `fix-security` as the narrow integrity-repair carve-out (perms-when-sha256-matches), NOT a routine "clear the warning" button — consistent with "surface, never smooth"

### Step 4: Task Types section — add `discovery`
- [ ] Add a `### Discovery Tasks (8 phases)` entry with the phase chain, placed after Chore

### Step 5: Validation
- [ ] Skill-list diff: README `/cwf-*` set == `.claude/skills/cwf-*` set. NB the `cwf-*`
      glob already excludes `test-cwf-skill` (test fixture, starts `test-`); `cwf-project`
      in a README grep is a `cwf-project.json` false positive, not a skill
- [ ] Task-type diff: documented types == `cwf-project.json:supported-task-types`
      (= feature,bugfix,hotfix,chore,discovery). **Do NOT diff against template dirs** —
      `.cwf/templates/` also contains `install/`, which is an artefact dir, not a task type
- [ ] `cwf-manage validate` clean
- [ ] grep README for any stale/removed command names

## Test Coverage
**See e-testing-plan.md for complete test plan** — verification is diff-based
(documented set vs shipped set), no automated unit tests for a docs change.

## Validation Criteria
**See e-testing-plan.md.** Pass = zero missing / zero phantom commands and task
types, signatures match `SKILL.md`/skill bodies, validate clean.

## Scope Completion
**IMPORTANT**: Complete all four edits before marking Finished. Per the a-task-plan
risk note, any *non-command* prose drift discovered (architecture/install/config
sections) is logged to BACKLOG, not fixed here.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 169
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All four planned edits applied to README.md (see f-implementation-exec.md). Plan-review
corrections (Step 5 oracle, cwf-new-subtask signature) carried through to execution.

## Lessons Learned
Plan review caught a wrong validation oracle (template dirs vs supported-task-types) before
it could mislead execution. See j-retrospective.md.
