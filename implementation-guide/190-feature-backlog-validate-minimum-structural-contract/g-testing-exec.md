# backlog validate minimum structural contract - Testing Execution
**Task**: 190 (feature)

## Task Reference
- **Task ID**: internal-190
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/190-backlog-validate-minimum-structural-contract
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

Runner: `prove -lr t/`. All 15 planned cases pass; the 71-test aggregate of the
two touched files is green.

### Functional Tests — predicate (`BACKLOG-000`, unit; `t/backlog-tree-validate.t`)

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1  | foreign `## ` heading (zero entries) | ≥1 BACKLOG-000 | fires | PASS |
| TC-2  | foreign list, leading H1 | fires on list item line 3, H1 silent | line 3 flagged | PASS |
| TC-3  | empty `""` and whitespace `"\n\n"` | no BACKLOG-000 | silent | PASS |
| TC-4  | intro-only `# Backlog`+prose | no BACKLOG-000 | silent | PASS |
| TC-5  | live-file shape (body `## ` headings) | no BACKLOG-000 (intro-only scan) | silent | PASS |
| TC-6  | heading-bearing legacy `**Field**:` | no BACKLOG-000 (parses to entries) | silent | PASS |
| TC-7  | message content | names kind+line, doc ref, no verbatim echo | confirmed | PASS |
| TC-8  | heading inside closed fence (zero entries) | no BACKLOG-000 (fence skip) | silent | PASS |
| TC-9  | unterminated leading fence | no BACKLOG-000 (accepted boundary, pinned) | silent | PASS |
| TC-10 | tab-delimited H1 `#\tBacklog` | no BACKLOG-000 (H1 exemption) | silent | PASS |

### Functional Tests — mutation gate (integration; `t/backlog-manager.t`)

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-11 | `add` on foreign | exit 1, refusal msg, byte-unchanged | exit 1, unchanged | PASS |
| TC-12 | `modify`/`delete` on foreign | exit 1, byte-unchanged | exit 1, unchanged | PASS |
| TC-13 | `retire` on foreign | exit 1, BOTH files byte-unchanged | exit 1, both unchanged | PASS |
| TC-14 | `add` on conformant | exit 0, entry appended | exit 0, appended | PASS |
| TC-15 | `normalise` on legacy (5th touchpoint) | exit 0; post-normalise validate clean | clean | PASS |

### Non-Functional Tests
- **Security (AC7/NFR4)**: TC-7 is the prompt-injection check — the error message
  interpolates only the fixed `$kind` enum + integer line number, never the
  offending line text. Exec-phase security review (f and g) returned `no findings`.
- **Performance (NFR1)**: predicate reuses the parser-cached `_source_lines`/
  `_source_fence` via `_file_lines_and_fence` — no second read or fence rebuild
  (satisfied by construction; no benchmark required).
- **Reliability (NFR5)**: TC-11–13 assert byte-unchanged refusal — no partial writes.
- **Regression / AC4**: live `backlog-manager validate --all` → rc 0 (live
  `BACKLOG.md`/`CHANGELOG.md` clean). Full `prove -lr t/` → 724 tests; +15 over the
  709-test baseline, all new cases green.

## Test Failures

No Task-190 failures. Two pre-existing, environment-specific suites fail
order-dependently and are **confirmed identical on clean HEAD** (stash-and-run):
- `t/cwf-manage-fix-security.t` (subtest 10, "TC-8 fixture provisions non-.cwf/
  manifest paths"): asserts `.claude/agents/cwf-plan-reviewer-*.md` working-tree
  perms satisfy a recorded `0444` floor — a checkout/umask artifact of the agent
  `.md` files, not exercised by Task 190. Clean HEAD fails 1, 9–10 here; with this
  task's hash refresh applied only 10 remains, i.e. the change strictly reduces it.
- `t/security-review-changeset.t` (subtest 35): flaky across runs (passed in the
  targeted re-run, failed in one full-suite run) — order/state dependent, also
  present on clean HEAD. Untouched by this task.

Neither is a regression introduced here. `cwf-manage validate` on the live repo
reports `OK`.

## Coverage Report

Critical path (predicate + gate) — all KD2 construct classes exercised: heading,
list item, leading-H1 exemption (space + tab), blank, fenced-skip; both intro-range
branches (entries present via TC-5/TC-6, zero entries via TC-1/TC-3). All four
mutation subcommands gated and asserted (TC-11–13), plus the conformant non-over-
refusal (TC-14) and the `_normalise_one` 5th touchpoint (TC-15). Every AC1–AC8 maps
to ≥1 case per e-testing-plan.

## Security Review

**State**: no findings

## Security review — testing-exec phase (Task 190)

**Changeset scope.** This testing-exec diff contains the Task-190 implementation already reviewed at implementation-exec, plus the testing-exec-specific additions: TC-1…TC-10 in `t/backlog-tree-validate.t` and TC-11…TC-15 in `t/backlog-manager.t`.

**(a) Arbitrary code/command execution.** New test cases add only static string fixtures (`$FOREIGN_BACKLOG` heredoc; inline byte strings) and invoke pre-existing helpers `run_bm`/`make_isolated`/`parse_and_validate_backlog`. `run_bm` shell-quotes via `quotemeta`/`_shell_quote`; no Task-190 arg is attacker-derived. No new `system`/`exec`/backtick/`eval`. Predicate remains pure Perl with static regex literals. No findings.

**(b) Path traversal / unsafe file writes.** New tests write exclusively into `File::Temp` dirs (`tempdir(CLEANUP => 1)`, fixed basenames); no repo file touched (test-DB-isolation honoured). Predicate performs no I/O; gate only prevents writes. No findings.

**(c) Prompt-injection / untrusted-content interpolation.** Message interpolates only `$kind` (fixed enum) + integer line number, never the offending line. TC-7's `unlike(... qr/Sprint Planning/ ...)` is a genuine regression guard pinning the no-verbatim-echo property. No findings.

**(d) Secrets/credential exposure.** None; manifest change is two expected same-commit sha256 refreshes. No findings.

**(e) Unsafe handling of env / external input.** No `$ENV`, no new arg parsing. Pattern note (non-actionable, carried from f): `backlog_structure_errors` is `@EXPORT_OK` for future CHANGELOG reuse (KD5) — safe here as no file content is interpolated; any future verbatim-echo edit must apply NFR2 stripping/bounding. TC-7 backstops the BACKLOG path.

**Other observations (non-security).** Accepted-boundary cases (TC-8/TC-9) are fail-open edges of a defensive check, pinned by tests so a future fence-map change cannot silently shift the contract.

The diff is clean across all five threat categories.

```cwf-review
state: no findings
summary: Testing-exec adds static fixtures + File::Temp-isolated harness calls; TC-7 pins the no-verbatim-echo property. Carried-over implementation is a pure read-only predicate + write-preventing gate, no exec/IO/secrets/env. One non-actionable pattern note on future CHANGELOG reuse of the exported predicate.
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
