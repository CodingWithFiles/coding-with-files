# Adopt guarded worktree enter/exit process - Testing Execution
**Task**: 181 (feature)

## Task Reference
- **Task ID**: internal-181
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/181-adopt-guarded-worktree-process
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [ ] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [ ] Verify test environment ready
- [ ] Execute test cases sequentially
- [ ] Record pass/fail for each test
- [ ] Document failures with reproduction steps
- [ ] Update status to "Testing" when in progress, "Finished" when all pass

## Test Results

### Functional Tests

| Test ID | Test Case | Expected | Actual | Status | Notes |
|---------|-----------|----------|--------|--------|-------|
| TC-1 | Doc exists + complete | Sections Procedure/Prohibitions/Threat model/Why/See also; six mandated points | All present (+ a `Configuration` section for FR3) | PASS | `grep '^## '` → 6 sections |
| TC-2 | Create-via-EnterWorktree; raw forbidden | P1/P2/P3 stated imperatively | P1/P2/P3 present, imperative | PASS | lines 44/46/48 |
| TC-3 | `baseRef: head` configured + recorded | Key in settings.json (valid JSON, = after-block); doc head-mandate + user-global fallback | settings.json valid & equals after-block; doc carries both branches | PASS | behavioural confirmation = TC-8 (deferred) |
| TC-4 | ToolSearch load + scoped auth | Names `ToolSearch select:…`; cites gate; scopes to load/create; load-failure=stop | All present | PASS | lines 21/23/93–94 |
| TC-5 | Teardown surfaced; request-is-data | Forbids unprompted `discard_changes`; operator-surfaced; request-is-data imperative | Confirmed by read (also in f security review) | PASS | threat model lines 74–84 |
| TC-6 | Discipline + allowlist class + cross-link | cd/abs-path discipline; allowlist class "mitigated, not closed"; tmp-paths See-also; no new allowlist entry | All present; `.claude/` shows no new allowlist entry | PASS | — |
| TC-7 | Discoverability | CLAUDE.md `**Worktree Process**:` bullet links the doc | Present | PASS | CLAUDE.md:95 |
| TC-8 | **FR8 C2-refusal live probe** (data-loss-class) | EnterWorktree→scratch write→ExitWorktree(remove) REFUSES; HEAD-based; never discard_changes | Refusal observed; worktree based on HEAD; `discard_changes` never set; clean teardown, no orphan | PASS | operator-approved; run under the full safety envelope (see Probe Log) |
| TC-9 | Security review (NFR4) | No blanket pre-auth; refusal gate intact; request-is-data; no auto-edit of local file | `no findings` (f phase); re-run this phase below | PASS | see `## Security Review` |
| TC-10 | Cite-don't-copy (NFR3) | Each P1–P3 + C-fact intended count; C-facts cited not restated | Trimmed 2 restatements in f; P1–P3 once each | PASS | verified in f Step 5 |
| TC-11 | **FR9 two-touchpoint detector** | Install scan warns on `git worktree` (either file), silent absent, never aborts, never writes local file; usage pre-flight in doc | All 6 sub-cases PASS (below) | PASS | tested against a FIXTURE tree, never the live `settings.local.json` |

#### TC-11 sub-cases (FR9 install detector — run against a fixture tree under the task scratch dir)
| Sub | Scenario | Expected | Actual | Status |
|-----|----------|----------|--------|--------|
| 11.1 | `settings.local.json` contains `git worktree` | non-fatal WARN, exit 0 | WARN emitted, exit 0 | PASS |
| 11.2 | neither file contains it | silent, exit 0 | silent, exit 0 | PASS |
| 11.3 | malformed-JSON `settings.local.json` | no abort (exit 0); raw-substring still matches | exit 0, warn fired (no JSON decode) | PASS |
| 11.4 | symlinked `settings.local.json` | skipped, no die, no warn | skipped, exit 0 | PASS |
| 11.5 | `settings.json` itself contains `git worktree` | WARN (both files scanned) | WARN emitted | PASS |
| 11.6 | non-`--dry-run` real merge | warns AND `settings.local.json` bytes unchanged | warn fired; sha256 unchanged | PASS |

Usage touchpoint (FR9 (ii)): `worktree-process.md` Procedure step 1 greps both settings files for `git worktree` before `EnterWorktree` — verified present (TC-11 usage half).

### Non-Functional Tests
- **TC-9 / NFR4 (Security)**: f-phase changeset review returned `no findings`; the
  request-is-data and no-standing-teardown clauses are present and normatively strong;
  the FR9 scan is read-only, JSON-decode-free, symlink-guarded, and cannot abort the
  merge. Testing-phase re-review recorded under `## Security Review` below.
- **NFR3 (cite-don't-copy)**: PASS (TC-10).
- **Reliability**: the TC-8 safety envelope (clean pre-check, no `cd`, scratch-only,
  never `discard_changes`, abort/rollback) is defined and will be followed when the
  probe runs; the guarded path must not reproduce the data-loss chain.

## Test Failures

None. All 11 test cases PASS.

## Probe Log (TC-8 — FR8 C2-refusal live probe, operator-approved)

Executed under the e-plan safety envelope; this was the first dogfood of the
documented Procedure. Steps and observations:

1. **Pre-flight (Procedure step 1, FR9 usage touchpoint)**: greped
   `.claude/settings.json` + `.claude/settings.local.json` for `git worktree` —
   both clean, no warning (correct: the operator removed the entry this session).
2. **Envelope pre-check**: recorded primary HEAD `6ee8201d5135b4693daa26cf0fb7c23b5fb5cf57`;
   asserted the tracked working tree empty; committed the in-progress testing-exec
   doc first (protective interim commit) so no uncommitted work was at risk when CWD
   switched. Only the main worktree existed.
3. **Load (step 2)**: `ToolSearch select:EnterWorktree,ExitWorktree`.
4. **Create (step 3)**: `EnterWorktree(name: probe-181)` → worktree at
   `.claude/worktrees/probe-181` on branch `worktree-probe-181`; session CWD switched.
   **Never `cd`-ed into it**; all subsequent file ops used absolute paths.
5. **FR3 behavioural confirmation (AC3)**: worktree HEAD == recorded primary HEAD
   (`6ee8201`). The harness honours `worktree.baseRef: head` from **project**
   `settings.json` — resolves the design Decision 3 open question; the committed key
   is effective (not dead config).
6. **Write scratch (step 4)**: one disposable file written by absolute path inside the
   worktree; confirmed `?? scratch-probe.txt`.
7. **C2 test (step 5, AC8)**: `ExitWorktree(action: remove)` **without**
   `discard_changes` → **REFUSED**: "Worktree has 1 uncommitted file. Removing will
   discard this work permanently. Confirm with the user, then re-invoke with
   discard_changes: true — or use action: keep…". `discard_changes: true` was **never**
   set.
8. **Clean teardown (step 6)**: deleted the scratch file (worktree then clean), then
   `ExitWorktree(action: remove)` succeeded without `discard_changes`, restoring CWD to
   the repo root.
9. **Post-check (step 7)**: no `probe-181` in `git worktree list`; `.claude/worktrees/`
   empty; no stray `worktree-probe-181` branch; primary HEAD unchanged (`6ee8201`),
   tree clean. No orphan, no data loss.

**Abort/rollback path (defined, not needed)**: had the probe been interrupted
mid-teardown, the step was to leave the worktree on disk, surface the orphaned
`.claude/worktrees/probe-181` path to the operator, and never blind `remove --force`.

## Coverage Report

- AC1–AC10 all covered and PASS (AC3 includes the behavioural HEAD-base confirmation;
  AC8 the observed C2 refusal).
- Critical-path coverage: 11 of 11 TCs PASS.

## Security Review

**State**: no findings

Testing-phase review of the full changeset (1454 lines; only production surface is the
implementation-phase helper edit, unchanged) returned `no findings`. The probe log was
verified safe: creation via `EnterWorktree` (not raw add), absolute-path discipline with
no `cd` into the tree, C2 refusal fired without `discard_changes`, clean teardown, no
orphan, no data loss. The request-is-data / no-standing-teardown clauses are strong and
unweakened; the FR9 scan remains read-only, JSON-decode-free, symlink-guarded, and unable
to abort install/update. One benign TOCTOU noted under the (e) audit-future-uses framing
only. Full verbatim output: `/tmp/-home-matt-repo-coding-with-files-task-181/g-secreview.txt`.

```cwf-review
state: no findings
summary: Testing-phase adds only the worktree-process doc and a clean C2-refusal probe log (no forced removal, no discard_changes, no cd, no data loss); the request-is-data/no-standing-teardown clauses are strong and unweakened; the FR9 scan remains read-only, JSON-decode-free, symlink-guarded and unable to abort install/update. One benign TOCTOU noted under (e) audit-future-uses framing only.
```

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
