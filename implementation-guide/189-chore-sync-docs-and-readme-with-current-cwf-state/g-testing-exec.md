# Sync docs and README with current CWF state - Testing Execution
**Task**: 189 (chore)

## Task Reference
- **Task ID**: internal-189
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/189-sync-docs-and-readme-with-current-cwf-state
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps
- [x] Update status to "Testing" when in progress, "Finished" when all pass

## Test Results

### Functional Tests

| Test ID | Test Case | Actual | Status |
|---------|-----------|--------|--------|
| TC-1 | Command inventory complete and real | All 20 `/cwf-*` skills documented; every documented command resolves to a skill dir. `/cwf-manage`, `/cwf-project` "misses" are false positives (paths `.cwf/scripts/cwf-manage`, `cwf-project.json`), not invocations | PASS |
| TC-2 | Dead/old command surface eliminated | No `/cwf-substep`, positional `<task-type> [task-id]`, category-dir model, or old `plan.md`/`requirements.md` filenames in COMMANDS/DESIGN | PASS |
| TC-3 | Per-type file sets match `%WORKFLOW_FILES` | CLAUDE.md states feature 10 (a–j) / bugfix 7 (a,c,d,e,f,g,j) / hotfix 7 (a,d,e,f,g,h,j) / chore 6 (a,d,e,f,g,j) / discovery 8 (a,b,c,d,e,f,g,j) — exact match to V21.pm | PASS |
| TC-4 | Workflow-step count consistent | No "8 workflow/structured steps", no `(a-h)`, no "a-plan through h-" anywhere | PASS |
| TC-5 | Stale-string sweep clean (docs) | No `cig-`/`CIG`/"5 helper scripts"/`taskManagement`/`taskIdPattern` in the six top-level docs. Residual `.cwf/docs` hits are real `cwf-version-bump/-tag/-next` script names; INSTALL `git subtree` hits are contextual "unlike" comparisons | PASS |
| TC-6 | SPEC matches validator contract | 22 validated-key mentions; required `supported-task-types` + `source-management.branch-naming-convention`; optional `versioning`/`wf_step_config`/`sandbox` with exact rules; pass-through block explicitly labelled "not validated"; no `cwf-version`/`title`/`task-management`/`team` as enforced fields | PASS |
| TC-7 | Install method prose correct | README L84 = read-tree (default) + file copy; no "git subtree (for upstream sync)" live method. INSTALL table marks `subtree` deprecated and refused | PASS |
| TC-8 | scratchpad removed cleanly | `git ls-files scratchpad.md` returns nothing (gitignored, never tracked — see deviation note) | PASS |
| TC-9 | Conventions charter applied | CLAUDE.md `## Conventions` documents the `docs/` (develop-CWF) vs `.cwf/docs/` (all-users) split; all 10 files conform; dirs disjoint (no `perl.md` duplication) | PASS |
| TC-10 | Deferred items captured | BACKLOG carries all three: template↔validator divergence, live-config vestigial blocks, residual CIG branding | PASS |
| TC-11 | Output-level smoke test (acceptance) | Generated throwaway chore via `task-workflow create`: file set = exactly a,d,e,f,g,j (6 files); grep of generated artefacts clean of stale strings; throwaway deleted, no residue, `validate` still clean | PASS |

### Non-Functional Tests

| Check | Actual | Status |
|-------|--------|--------|
| Scope/Regression | `git diff --name-only c5797a3..HEAD` lists only top-level docs + BACKLOG + task files; **no** `.cwf/**` or `.claude/{agents,hooks,rules}/**` (hash-tracked) file modified | PASS |
| Integrity | `cwf-manage validate` exits clean | PASS |
| Personal names | No `matt`/`keenan` in any edited doc (roles only) | PASS |
| Reference integrity | All cited paths (`.cwf/docs/workflow`, `.cwf/lib/CWF/{Validate/Config,WorkflowFiles/V21,PlanningGuard}.pm`, `.cwf/templates/pool`, `CWF-PROJECT-SPEC.md`, etc.) resolve | PASS |
| British spelling | Prose uses initialise/organisation/optimisation; no US spellings introduced | PASS |

## Test Failures

None. All 11 functional test cases and all non-functional checks passed.

One **plan deviation** (not a test failure), surfaced in f-implementation-exec.md Step 8:
`scratchpad.md` is gitignored (`.gitignore:14`), not a tracked file as the plan assumed.
TC-8's acceptance condition (`git ls-files` returns nothing) was already satisfied, so the
release is unaffected; the local file was left in place rather than deleted.

## Coverage Report

Every document edited in f is covered by at least one TC: README (TC-1,3,4,5,7), COMMANDS
(TC-1,2,5), DESIGN (TC-2,5), CWF-PROJECT-SPEC (TC-5,6), CLAUDE (TC-1,3,4,5,9), INSTALL
(TC-5,7). 100% of documented `/cwf-*` commands resolve to real skills. Zero stale-string
hits in the docs grep set. Generated-artefact smoke test confirms template output is clean.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Security Review

**State**: error

error: cap exceeded: 1073 production lines > 500

**Note (not a finding)**: same situation as the implementation-exec phase. The 1073
"production" lines are the six top-level documentation files (everything outside `t/**`
and `implementation-guide/**` is weighted as production); the testing phase added only
`g-testing-exec.md`, which lives under the excluded `implementation-guide/**` and so does
not change the production count. Per the exec-skill's deterministic rule for exit 2, the
changeset subagent was **not** invoked. No executable code, script, hook, or hash-tracked
file is in the change set — the security surface is nil.

## Lessons Learned
*To be captured during retrospective*
