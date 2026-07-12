# R3 shell-hygiene convention and allowlist seed - Testing Execution
**Task**: 227 (feature)

## Task Reference
- **Task ID**: internal-227
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/227-r3-shell-hygiene-convention-and-allowlist-seed
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready (`prove`, core Perl; tempdir fixtures)
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps
- [x] Update status to "Testing" when in progress, "Finished" when all pass

## Test Environment
- `prove t/cwf-claude-settings-merge.t` (unit + integration) and `prove -r t/` (full regression).
- Core Perl `Test::More`; tempdir fixtures via the file's existing `build_fixture`/`write_settings`/
  `read_settings`/`run_helper` helpers. No production `.claude/settings.json` touched.
- Static doc/anchor checks via `test -f`, `ls`, and `grep`.

## Test Results

### Functional Tests — safety predicate + seed integration (automated)

The e-plan's TC-1 … TC-9a are realised as subtests in `t/cwf-claude-settings-merge.t` (TC-RO1..RO5
plus the two updated count assertions TC-U1/TC-U4). `prove t/cwf-claude-settings-merge.t` → **PASS,
51 subtests, warning-clean**.

| e-plan TC | Realised as | Expected | Actual | Status |
|---|---|---|---|---|
| TC-1 (accept corpus) | TC-RO1 positive controls | all 5 corpus entries accepted | accepted | PASS |
| TC-2 (reject unsafe) | TC-RO1 negative controls | `git diff:*`/`rg:*`/`git:*`/`find:*`/`sed -i:*`/`git branch:*` rejected | rejected | PASS |
| TC-3 (exact/prefix split) | TC-RO1 + TC-RO2 | exact accepted; `git branch --show-current:*` + `git branch:*` rejected | as expected | PASS |
| TC-4 (anchor discipline) | TC-RO1 trailing-`\n` case | `Bash(ls:*)\n` rejected (`\z` not `$`) | rejected | PASS |
| TC-5 (corpus present) | TC-RO3 | all 5 corpus entries in `permissions.allow` | present | PASS |
| TC-6 (only-safe generic) | TC-RO3 | every non-`.cwf/scripts/` entry passes gate; set == corpus | equal, all safe | PASS |
| TC-7 (additive) | TC-RO4 | pre-existing `Bash(npm test:*)` survives; corpus added | preserved + added | PASS |
| TC-8 (idempotent) | TC-RO5 | second merge adds 0 duplicate corpus entries | no dups | PASS |
| TC-9 (malformed settings) | existing TC-U5b/TC-UPS5 (inherited `read_settings` fail-closed) | dies/never clobbers | unchanged behaviour | PASS |
| TC-9a (count regression) | TC-U1 `:126` + TC-U4 `:231` | `3`→`8` allowlist entries | updated to 8, re-pass | PASS |

### Functional Tests — static doc & anchors

| e-plan TC | Check | Result | Status |
|---|---|---|---|
| TC-10 | `shell-hygiene.md` exists; referenced intra-repo paths (`tmp-paths.md`, `cwf-agent-shared-rules.md#…`, `subagent-tool-selection.md`) all resolve; no maintainer `docs/`-tree link; deny/ask opt-out documented (line 68) | all confirmed | PASS |
| TC-11 | `shell-hygiene.md` referenced from shipped `cwf-agent-shared-rules.md` (line 56, the load-bearing FR3 anchor) and this repo's `CLAUDE.md` (line 112); the `#blocking-bash-anti-patterns` anchor target heading exists | all confirmed | PASS |

### Non-Functional Tests
- **Security**: TC-RO1/RO2/RO4 are the security tests — exact/prefix membership split and anchor-hole
  closure, both PASS. Operators are documented-safe (no test needed). **Redirection/substitution**
  4-vector probe: could not run authoritatively offline; documentation status verified (undocumented);
  handled via the positive branch (doc caveat + backlog item) in phase f — not silently passed.
- **Reliability**: TC-RO5 (idempotent convergence) PASS; TC-9/malformed fail-closed PASS (inherited).
- **Usability**: `--dry-run` reports the corpus count (`would add 8 …` on a clean fixture, TC-U4); doc
  is scannable in one sitting.

### Regression
`prove -r t/` → **PASS, Files=78, Tests=1078**. Full suite green with the +5 seed and both hash
refreshes in place.

## Test Failures

None. (During phase f, a full-suite run failed 4 files while the helper's hash was momentarily stale
before the Step-4 refresh — the integrity gate firing as designed. All green post-refresh and again here.)

## Coverage Report
- Critical path (the safety gate): 100% — every corpus entry validated by the independent predicate;
  every planted-unsafe class rejected, including the prefix-form-of-exact near-miss.
- Regression: full `t/` suite PASS; no change to existing settings-merge behaviour.

## Changeset Reviews

Two reviewers ran in parallel against the testing-exec changeset (anchor `8dce3a6`, under cap).
Classified by `security-review-classify`.

### Security Review

**State**: no findings

Read-only allowlist seed uses static constants (no injection surface), corpus is provably
read-only-for-all-args with exact-vs-prefix handling, fail-closed independent test gate present, and
the redirection/substitution residual is properly surfaced (doc caveat + backlog) rather than smoothed.

### Best-Practice Review

**State**: no findings

Perl test/predicate additions align with the Perl best-practice corpus (`\A`/`\z` + `/aa` anchoring,
negated char class, capture-after-match, `@_` unpacked, hash membership, positive+negative+boundary
controls); the Go and Postgres sources are not applicable to this diff.

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
- Realising the e-plan's abstract TC-1..TC-9a as concrete `t/` subtests (TC-RO1..RO5 + the updated
  count assertions) keeps the test plan and the executable suite traceable to each other without
  duplicating the plan into the code.
