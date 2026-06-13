# Align scratch tmp-paths with /tmp/claude sandbox - Retrospective
**Task**: 199 (discovery)

## Task Reference
- **Task ID**: internal-199
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/199-align-scratch-tmp-paths-with-tmpclaude-sandbox
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-13

## Executive Summary
- **Duration**: single session (~half day; estimated 1-2 days — under estimate).
- **Scope**: audit CWF's `/tmp` write surface and re-root the per-task scratch
  convention so it lands inside the new `/tmp/claude` sandbox restriction. Final
  scope matched plan; the helper-internal `File::Temp` concern dissolved into a
  no-op at design time.
- **Outcome**: success. One helper edit + convention + 3 tests + in-session memory
  alignment. Full suite green (762 tests), `validate` clean, both security reviews
  `no findings`. The sandbox-denial enforcement check is BLOCKED-ENV (dev session
  is unsandboxed) with documented repro.

## Variance Analysis
### Time and Effort
- **Estimated**: 1-2 days (Medium complexity).
- **Actual**: one session. Planning chain (a–e) + exec (f/g) + retrospective.
- **Variance**: under estimate — the honour-`$TMPDIR` design collapsed two
  apparent concerns into one mechanism, and the contract proved testable without a
  sandbox, removing most of the expected complexity.

### Scope Changes
- **Additions**: none beyond plan.
- **Removals/dissolved**: the class-(c) helper-internal `File::Temp` fix
  (`cwf-apply-artefacts`, `cwf-manage`) — `File::Temp` honours `$TMPDIR` natively,
  so once the design keyed everything off `$TMPDIR` those sites need no change
  (disposition (ii), pending the D2 sandbox-sets-`TMPDIR` confirmation).
- **Deferred**: FR7 sandbox-denial verification + the contingent class-(c) fix —
  BLOCKED-ENV, carried to BACKLOG.

### Quality Metrics
- **Test Coverage**: 3 new contract subtests (set/unset/empty `$TMPDIR`); full
  suite 63 files / 762 tests green.
- **Defect Rate**: one self-inflicted defect during exec (interpolating-heredoc
  `${...}` parsed as a Perl deref → 44 transient failures), caught immediately by
  the suite and fixed by escaping `\${`. Zero shipped defects.

## What Went Well
- **The plan-review chain earned its keep.** It caught: a blocking design↔requirements
  conflict (hardcoded `/tmp/claude` vs honour-`$TMPDIR`) which was reconciled by
  amending the requirements; the empty-`TMPDIR` Perl/shell divergence
  (`// '/tmp'` vs length-check) before it shipped; and the fail-closed-layer
  imprecision in the design prose.
- **Design simplification.** Keying scratch resolution off `$TMPDIR` unified all
  three temp classes onto one signal and kept the shipped convention portable (no
  harness-specific `/tmp/claude` literal), dissolving the decomposition question.
- **Testable without the blocker.** Asserting the `.out` location under a set
  `$TMPDIR` exercised the whole contract in an unsandboxed session, shrinking the
  irreducible BLOCKED-ENV residue to just enforcement + the `TMPDIR`-set fact.

## What Could Be Improved
- **The red/green prediction was slightly wrong.** The d-plan said TC-TMPDIR-1 and
  -3 would fail against old code; only TC-1 did (old code already routes to `/tmp`,
  so the unset/empty fallbacks were already green). TC-3 guards the *new* impl's
  length-check, not the old code. Recorded honestly rather than retrofitted.
- **The heredoc escape was avoidable.** A literal `${TMPDIR:-/tmp}` placed in an
  interpolating `usage()` heredoc broke compilation. A quick `perl -c`-equivalent
  (running `--help` once) right after the comment edit would have caught it a step
  earlier; the full suite caught it regardless.

## Key Learnings
### Technical Insights
- `${VAR:-default}` written literally inside a Perl *interpolating* heredoc/string
  is parsed as a variable deref and breaks compilation — escape the `$` (`\${…}`)
  or keep such shell-syntax in non-interpolating `#` comments.
- Perl `//` (defined-or) is **not** the analogue of shell `${VAR:-default}`: `//`
  only catches undef, so an empty-string env var slips through. Match shell
  semantics with an explicit `length` test, or an empty value collapses the path
  to filesystem root.
- `File::Temp`/`tempdir` resolve their dir from `$TMPDIR`, so making an *explicit*
  convention honour `$TMPDIR` too lets one environment fact govern every temp class.

### Process Learnings
- **Design-reveals-requirements is a real transition, not a failure.** The design
  found a better form than the requirements specified; the proper move was to loop
  back and amend FR2/FR3 with a reconciliation note, not to silently diverge.
- **BLOCKED-ENV with a written repro is the honest close** for a check that needs
  an environment the dev session lacks (here, an active sandbox) — paired with a
  resolution rule so the deferred branch can't be silently dropped.

### Risk Mitigation Strategies
- Probing the actual environment early (the legacy-`/tmp` mkdir + `go-build`
  evidence) grounded the design in what the sandbox really does rather than an
  assumed model, and made the single load-bearing unknown (`TMPDIR`-set) explicit.

## Recommendations
### Process Improvements
- After editing comment/usage text in a Perl script, run the script's `--help`
  once before the full suite — a one-command compile check for the cheap class of
  break introduced this task.

### Tool and Technique Recommendations
- Keep shell-syntax examples (`${VAR:-default}`) in `#` comments, not in
  interpolating heredocs, in Perl helpers.

### Future Work
- **Confirm the sandbox sets `TMPDIR=/tmp/claude` and verify denial (FR7/D2);
  fix class-(c) only if unset.** BLOCKED-ENV this session — see BACKLOG.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: FR7/D2 sandbox checks BLOCKED-ENV (unsandboxed dev session) — carried to BACKLOG with repro.
**Completion Date**: 2026-06-13
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Plan/exec docs: `implementation-guide/199-discovery-align-scratch-tmp-paths-with-tmpclaude-sandbox/`
- Code: `.cwf/scripts/command-helpers/security-review-changeset`, `.cwf/docs/conventions/tmp-paths.md`, `t/security-review-changeset.t`, `.cwf/security/script-hashes.json`
- Security-review captures: `${TMPDIR:-/tmp}/-home-matt-repo-coding-with-files-task-199/security-review-output-*.out`
