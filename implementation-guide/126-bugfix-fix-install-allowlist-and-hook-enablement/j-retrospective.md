# fix install allowlist and hook enablement - Retrospective
**Task**: 126 (bugfix)

## Task Reference
- **Task ID**: internal-126
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/126-fix-install-allowlist-and-hook-enablement
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-05

## Executive Summary
- **Duration**: 1 session of active work (estimated: 1 session; variance ~0%).
- **Scope**: Original scope held — the install-time `/cwf-init` flow now produces a `.claude/settings.json` with the right `Bash(...)` allowlist + Stop hooks. Out-of-scope-by-design: the upgrade path (`cwf-manage update`) still does not refresh settings; deferred to a follow-up BACKLOG item per the original a-task-plan risk note.
- **Outcome**: Bugfix shipped; both gaps closed for fresh installs. Coverage guard (Task 125) automatically flows future helpers and hooks into the allowlist via the manifest. Regression suite 29/271 → 30/280, all green.

## Variance Analysis

### Time and Effort
- **Estimated**: 1 session (single bugfix, low complexity).
- **Actual**: 1 session, no rework.
- **Variance**: ~0%. Plan-review subagents caught nothing requiring re-design; e-plan tests passed first run after a one-line regex-delimiter fix.

### Scope Changes
- **Additions**: None during implementation. One scope question raised post-g-phase (refresh on `cwf-manage update`); recorded as a BACKLOG follow-up rather than expanding 126.
- **Removals**: None.
- **Impact**: None on this task. The deferred upgrade-path refresh becomes Task 127.

### Quality Metrics
- **Test Coverage**: 9 unit subtests + 3 integration + 4 non-functional + 1 regression — all PASS. Helper paths exercised: empty/populated input, all four KD7 file-type checks, KD3 partition (cwf-manage / top-level helper / `.d/` / hook), KD5 multi-matcher hook scan, `--dry-run`, missing-on-disk warn-and-skip.
- **Defect Rate**: Zero defects post-implementation. One self-caught issue during testing (regex `/` delimiter inside `\Q...\E` terminated regex prematurely — fixed in-phase by switching to `qr{...}`).
- **Performance**: N/A (one-shot init helper).

## What Went Well
- **Manifest-driven design**: the helper walks `.cwf/security/script-hashes.json` rather than hard-coding helper paths. Task 125's coverage guard now automatically guarantees future helpers flow into the allowlist; no separate maintenance burden.
- **Reusing the canonical atomic-write pattern**: borrowed the `File::Temp` + `rename` shape directly from `CWF::Versioning::bump_to`. No invented patterns.
- **Idempotency by construction**: the merge step uses a `%seen` hashset against the existing array, and hook scanning iterates *all* matcher objects — so dedup works whether the target lives in `Stop[0]` or any later matcher.
- **Plan-review subagents (c and d phases)**: caught the shebang convention point (use `#!/usr/bin/env perl`, reserve `-CDSL` for git-reading scripts) and the parent-`.claude/`-symlink defence before code was written.
- **Smoke test against this repo (TC-I3)**: `--dry-run` against the live manifest confirmed the helper produces the expected entries before the test suite was even consulted.

## What Could Be Improved
- **Habit-leak: `perl -c` before execution**: a `chmod && perl -c` was issued before invoking the new helper. POSIX-only project; this is a Windows-style "compile then run" pattern. Saved as a feedback memory; should not recur.
- **Dangling-work framing on the BACKLOG addition**: the upgrade-path follow-up was initially staged with "left uncommitted for now" framing — wrong. Per the memory rule and the retrospective skill's Step 8, BACKLOG additions belong in an active phase commit (this j-phase). Corrected before any commits drifted.
- **Security-review subagent emitted analysis prose before the sentinel line**: both f- and g-phase reviews failed the primary sentinel check despite reaching `no findings` / null-actionable conclusions. Both reviews had to be classified `findings` per the strict three-tier rule and disposed as accept-and-record. The subagent prompt may benefit from "first non-blank line MUST be a sentinel" framing — relevant to the existing BACKLOG item "Tighten security-subagent prompt for sentinel-line compliance".

## Key Learnings

### Technical Insights
- **`-CDSL` is for git-path-handling scripts only** (per `docs/conventions/perl-git-paths.md`). Every other `command-helpers/` helper uses `#!/usr/bin/env perl`. Future security-review findings recommending `-CDSL` for non-git scripts should be treated as false positives.
- **Allowlist entry shape**: Claude Code matches `Bash(<path>:*)` for invocations of the form `<path> [args]` (the established CWF pattern); for hooks invoked bare by the harness, use `Bash(<path>)` exact-match. Mixing the two shapes for the same script silently fails to match.
- **Hooks live in `hooks.Stop[i].hooks[j]`**, not in a flat array. New entries must scan all matcher objects when checking for duplicates; new entries land in `Stop[0]` (creating it if absent).
- **Trampoline invariant**: `.d/` subcommands are reachable only via the parent's `:*` glob, so `.d/` paths skip the allowlist entirely. The partition rule encodes this directly.
- **Atomic write with `File::Temp::TEMPLATE`**: `XXXXXX` randomisation avoids the PID-collision footgun of naïve `$$.tmp` patterns and inherits the existing CWF pattern.

### Process Learnings
- **Plan review subagents are net-positive on a 1-session bugfix**: the c- and d-phase reviews caught two real issues (shebang choice, parent-`.claude/` symlink) before any code was written. Cost <2 min; saved at least one fix-and-re-run cycle.
- **The retrospective phase is where follow-ups belong**: when a process question surfaces post-testing-exec (here: "does this also fix the upgrade path?"), the right move is to record it in BACKLOG and fold the BACKLOG update into the j-phase commit — not to leave it dangling on the working tree.
- **Risk mitigations from a-task-plan paid off**: the Manifest-drift risk explicitly noted "out of scope: automatic refresh on `cwf-manage update`. Worth a BACKLOG item." That deferral was honoured cleanly when the question was raised.

### Risk Mitigation Strategies
- **Explicit out-of-scope notes in a-task-plan are valuable**: the upgrade-path question came up exactly where the original plan said it would. Without that note, the discussion would have looked like missed scope; with it, the answer was prepared.
- **Defence-in-depth on file paths**: even though the integrity manifest is curated, the helper validates manifest paths against `^.cwf/scripts/` and rejects `..` traversal, and refuses symlinked `.claude/` or `.claude/settings.json`. Cheap, and the right shape if the manifest ever becomes user-editable.

## Recommendations

### Process Improvements
- **None new from this task.** The existing BACKLOG item "Tighten security-subagent prompt for sentinel-line compliance" already covers the security-review prose-before-sentinel issue observed here.

### Tool and Technique Recommendations
- **Codify the "three shapes for permissions allow entries"**: `Bash(<path>:*)` for argument-taking helpers, `Bash(<path>)` exact for hooks, no entry for `.d/` subcommands. Worth adding to the cwf-init/SKILL.md commentary alongside Step 6d so the convention is documented in the place it's enforced.

### Future Work
- **Refresh `.claude/settings.json` on `cwf-manage update`** — added to BACKLOG ("Refresh .claude/settings.json on `cwf-manage update`"). Calls the same `cwf-claude-settings-merge` helper at the end of `cmd_update`, with WARN-not-fatal semantics. Identified during testing-exec phase.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-05

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- a-task-plan: `implementation-guide/126-bugfix-fix-install-allowlist-and-hook-enablement/a-task-plan.md`
- c-design-plan: `implementation-guide/126-bugfix-fix-install-allowlist-and-hook-enablement/c-design-plan.md`
- d-implementation-plan: `implementation-guide/126-bugfix-fix-install-allowlist-and-hook-enablement/d-implementation-plan.md`
- e-testing-plan: `implementation-guide/126-bugfix-fix-install-allowlist-and-hook-enablement/e-testing-plan.md`
- f-implementation-exec: `implementation-guide/126-bugfix-fix-install-allowlist-and-hook-enablement/f-implementation-exec.md`
- g-testing-exec: `implementation-guide/126-bugfix-fix-install-allowlist-and-hook-enablement/g-testing-exec.md`
- Checkpoint commits: `9e78919` (a), `0805812` (c), `3afe689` (d), `5ac961f` (e), `0d35864` (f), `7dc9f87` (g)
