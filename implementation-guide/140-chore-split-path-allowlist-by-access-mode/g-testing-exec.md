# Split path-allowlist by access mode - Testing Execution
**Task**: 140 (chore)

## Task Reference
- **Task ID**: internal-140
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/140-split-path-allowlist-by-access-mode
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Test Results

### Functional Tests

| Test ID | Test Case                                                              | Status | Notes                                  |
|---------|------------------------------------------------------------------------|--------|----------------------------------------|
| TC-W1   | `validate_write_path_allowlist` accepts allowed prefixes               | PASS   | `t/artefacthelpers.t` ok 10–12         |
| TC-W2   | rejects absolute path                                                  | PASS   | ok 13                                  |
| TC-W3   | rejects path containing `..`                                           | PASS   | ok 14                                  |
| TC-W4   | rejects leading `..`                                                   | PASS   | ok 15                                  |
| TC-W4b  | rejects path outside allowlist                                         | PASS   | ok 16                                  |
| TC-W5a  | rejects undef                                                          | PASS   | ok 17                                  |
| TC-W5b  | rejects empty                                                          | PASS   | ok 18                                  |
| TC-R1   | `validate_read_path_allowlist` accepts existing readable file in /tmp  | PASS   | ok 19                                  |
| TC-R3a  | rejects undef                                                          | PASS   | ok 20                                  |
| TC-R3b  | rejects empty                                                          | PASS   | ok 21                                  |
| TC-R4   | rejects non-existent path                                              | PASS   | ok 22                                  |
| TC-R5   | rejects unreadable file (chmod 0000)                                   | PASS   | ok 23 (running as non-root)            |
| TC-B1   | backlog-manager add accepts `/tmp/.../body.md`                          | PASS   | `t/backlog-manager.t` ok 18 (subtest)  |
| TC-B2   | rejects non-existent `--body-file`                                     | PASS   | ok 19                                  |
| TC-B3   | rejects unreadable `--body-file`                                       | PASS   | ok 20 (would skip under root)          |
| TC-B4   | rejects empty `--body-file=`                                           | PASS   | ok 21                                  |

TC-R2 ("accepts absolute path under /tmp/") collapsed into TC-R1 — the planned test already uses `tempdir(CLEANUP => 1)`, which on this system returns an absolute `/tmp/...` path. The single TC-R1 case therefore covers both the bare-accept and the regression-guard-against-prefix-list semantics.

### Regression
- **TC-RG1**: full `prove t/` → 42 files, **472 tests, all PASS** (10.0s wall).
- Focused re-run: `prove t/artefacthelpers.t t/backlog-manager.t` → 65 subtests, PASS.

### Non-Functional Tests
- **Security**: `security-review-changeset --phase=testing` and subagent review — recorded in § "Security Review" below.
- **Maintainability**: `grep -rn validate_path_allowlist .cwf/ t/ docs/ .claude/` → **0 hits**. Orphan-symbol guard clean.
- **Reliability**: `cwf-manage validate` → **OK** (script hashes match, perms match, manifest parses).
- **Performance**: not measured — change is in argument-validation hot path of CLI tools, no perceptible delta.

### System Smoke (manual)
Performed against live `BACKLOG.md`:

```
$ mkdir -p /tmp/cwf-smoke-140
$ <wrote body.md into /tmp/cwf-smoke-140/>
$ .cwf/scripts/command-helpers/backlog-manager add \
    --title='Task140 Smoke' --task-type=chore --priority=Low \
    --body-file=/tmp/cwf-smoke-140/body.md
$ backlog-manager list --all-items | grep 'Task140 Smoke'
  - Task140 Smoke                                           # PASS — accepted /tmp/ body
$ backlog-manager delete --exact-title='Task140 Smoke' --confirm
$ backlog-manager list --all-items | grep -c 'Task140 Smoke'
  0                                                          # PASS — clean restore
$ rm -rf /tmp/cwf-smoke-140
```

`git status` after the smoke confirms `BACKLOG.md` was restored byte-for-byte — no residue.

## Test Failures
None.

## Coverage Report
- **New helper functions**: every documented accept and reject path exercised at unit level.
- **Migrated call sites**: backlog-manager covered by 4 new integration subtests (pos + 3 neg). `cwf-apply-artefacts` and `cwf-claude-settings-merge` covered by their existing test files (which exercise the write-validator's reject paths via manifest-tampering fixtures — verified by full `prove t/` green).
- **Regression**: 100% of the 472 existing tests pass.

## Validation Criteria Roll-up (from e-testing-plan.md)
- [x] All TC-W1..W5 pass.
- [x] All TC-R1..R5 pass (TC-R5 run as non-root).
- [x] All TC-B1..B4 pass (TC-B3 run as non-root).
- [x] TC-RG1: `prove t/` exit 0.
- [x] Source grep for `validate_path_allowlist` returns zero hits.
- [x] `security-review-changeset` reviewed (see below).
- [x] `cwf-manage validate` is OK.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 140
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: error

error: subagent emitted substantive analysis with body-level "no findings" verdict (closing line: "no findings. All test code follows safe patterns…") but failed sentinel-first formatting even after an explicit warning in the prompt that the response would be classified `error` if the first line was anything other than a sentinel. Per the three-tier rule: tier-1 fails (no leading sentinel — first line is "Now let me analyze…"); tier-2 matches numbered enumeration of changeset files (`^\s*\d+[.)]\s` form), which would mechanically push to `findings` — but the body content is clearly a "no findings" verdict, so the mechanical tier-2 classification would be misleading. Defaulting to tier-3 conservative `error` and recording the verbatim verdict.

Same root cause as the f-phase security-review section above — BACKLOG items "Enforce sentinel-first output in security-review subagent prompt" and "Tighten security-subagent prompt for sentinel-line compliance". Two consecutive exec-phase reviews on this task hit it; this is now strong evidence the prompt template itself needs work.

Substantive verdict (verbatim, last paragraph of subagent output):

```
**No actionable security issues detected.** The test code follows safe patterns: explicit path construction via `File::Spec`, proper tempfile cleanup, permission restoration, and appropriate skip conditions for privilege-dependent tests.

no findings. All test code follows safe patterns: explicit path construction via File::Spec, tempfile cleanup with CLEANUP flag, proper permission restoration after chmod 0000 tests, and skip conditions for privilege-dependent checks.
```

Pattern-(e) observation in the body: chmod 0000 tests correctly restore mode 0600 before `tempdir` CLEANUP, and skip-if-root is consistent across both new test files. No code action required.

## Lessons Learned
*To be captured during retrospective*
