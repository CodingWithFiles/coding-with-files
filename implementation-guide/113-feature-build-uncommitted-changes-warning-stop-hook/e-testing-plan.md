# Build uncommitted changes warning Stop hook - Testing Plan
**Task**: 113 (feature)

## Task Reference
- **Task ID**: internal-113
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/113-build-uncommitted-changes-warning-stop-hook
- **Template Version**: 2.1

## Goal
Define test cases for the uncommitted-changes warning hook covering each acceptance criterion (AC1–AC6) and each porcelain class (staged, unstaged, untracked, conflict).

## Test Strategy
Manual pipe-testing of the script with controlled git state. The hook reads stdin (ignored) and writes JSON to stdout — easily simulated by `echo '{}' | <script>`. No automated test framework; script is ~30 lines of Perl. Each test case sets up the required git state, invokes the hook, asserts on stdout/exit, then reverts state.

## Test Environment
- Repo: this CWF repo on `feature/113-build-uncommitted-changes-warning-stop-hook` branch
- Git binary on PATH
- `jq` for JSON validation
- A test wf file we can manipulate without disturbing real workflow files. Use a scratch path under an existing task directory (e.g. modify `i-maintenance.md` in this task's directory — it is template content yet to be filled).

## Test Cases

| ID    | Maps to AC | Description                                                       | Setup                                                                                           | Assertion                                                                                |
|-------|-----------|-------------------------------------------------------------------|--------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------|
| TC-1  | AC3       | Clean tree → no output                                            | Commit/stash all wf changes; verify `git status --porcelain -- 'implementation-guide/*/[a-j]-*.md'` is empty | Exit 0, stdout empty                                                                     |
| TC-2  | AC1, AC2  | Untracked wf file (`??`)                                          | Create new untracked wf file inside an existing task directory                                  | Exit 0, JSON parseable by `jq -e .`, `systemMessage` begins with "⚠ Uncommitted:" and contains the basename |
| TC-3  | AC1       | Unstaged modification (` M`)                                      | `echo " " >> <committed-wf-file>` (don't `git add`)                                              | Exit 0, JSON contains the basename                                                       |
| TC-4  | AC1       | Staged modification (`M `)                                        | Modify a committed wf file then `git add` it                                                     | Exit 0, JSON contains the basename                                                       |
| TC-5  | AC1       | Staged addition (`A `)                                            | `git add` a previously untracked wf file                                                         | Exit 0, JSON contains the basename                                                       |
| TC-6  | AC1, NFR1 | 4+ dirty wf files → cap at 3 + "+N more"                          | Make 4 wf files dirty (any mix of states)                                                        | Exit 0, JSON `systemMessage` lists exactly 3 basenames + " +1 more"                      |
| TC-7  | AC4       | Non-git cwd                                                       | `(cd /tmp && echo '{}' \| <absolute-path-to-hook>)`                                              | Exit 0, stdout empty                                                                     |
| TC-8  | AC4       | Conflict state (`UU`) — stretch                                   | Force a merge conflict on a wf file (cherry-pick a divergent commit), do not resolve             | Exit 0, JSON contains the basename of the conflicted file                                |
| TC-9  | AC5       | Hook registered in settings                                       | `jq '.hooks.Stop[0].hooks \| map(.command) \| index(".cwf/scripts/hooks/stop-uncommitted-changes-warning")' .claude/settings.local.json` | Returns a non-null integer                                                               |
| TC-10 | AC5       | Hook entry has `timeout: 5`                                       | `jq '.hooks.Stop[0].hooks[] \| select(.command \| test("stop-uncommitted")) \| .timeout' .claude/settings.local.json` | Returns 5                                                                                |
| TC-11 | AC6       | Both Stop hooks fire on the same Stop event                       | Make at least one wf file uncommitted *and* with `Status: Backlog`; trigger a real Stop in this Claude Code session and observe both warnings in the next-turn system reminder | Both "⚠ Uncommitted:" and "⚠ Stale status:" appear in the system reminder                |
| TC-12 | NFR2      | Always exits 0                                                    | Run TC-1 through TC-8; capture `$?` after each                                                   | `$?` is 0 every time                                                                     |
| TC-13 | NFR3      | No side effects                                                   | Capture `git status` snapshot before and after running TC-2                                      | git state unchanged; no new files created by the hook itself                             |
| TC-14 | NFR5      | Script permissions                                                | `stat -c '%a' .cwf/scripts/hooks/stop-uncommitted-changes-warning`                               | Mode is 0500 (or stricter)                                                               |
| TC-S1 | —         | `cwf-manage validate` clean after install                         | Run `.cwf/scripts/cwf-manage validate`                                                           | Exit 0                                                                                   |

## Validation Criteria
- [ ] TC-1 through TC-7 and TC-9, TC-10, TC-12, TC-13, TC-14, TC-S1 pass
- [ ] TC-8 (conflict state) attempted; mark stretch if too brittle to reproduce reliably
- [ ] TC-11 (live Stop event) verified during g-testing-exec by observing actual session output
- [ ] All ACs (AC1–AC6) covered by at least one passing test
- [ ] `cwf-manage validate` returns OK after install
- [ ] No regression observed in Task 104 hook output (still fires on stale-Backlog state)

## Decomposition Check
- [x] **Time**: No — testing is in-line with the implementation phase
- [x] **People**: No
- [x] **Complexity**: No — pipe-test pattern is uniform across cases
- [x] **Risk**: No
- [x] **Independence**: No

**Result**: 0/5 signals. No decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 113
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
