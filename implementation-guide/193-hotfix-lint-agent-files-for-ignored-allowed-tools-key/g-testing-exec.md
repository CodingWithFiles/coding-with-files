# Lint agent files for ignored allowed-tools key - Testing Execution
**Task**: 193 (hotfix)

## Task Reference
- **Task ID**: internal-193
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/193-lint-agent-files-for-ignored-allowed-tools-key
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
All cases per e-testing-plan.md. Unit cases run via `prove -v t/validate-agents.t`;
TC-9 via `cwf-manage validate`; TC-10 via `prove t/`.

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1 | happy path (`tools:`) | 0 violations | 0 violations | PASS |
| TC-2 | bad key flagged (core) | 1 AGENTS viol, all 6 fields asserted | category/file/field/actual/expected/fix all match; `fix=~/tools:/` | PASS |
| TC-3 | body occurrence after close | 0 violations | 0 violations | PASS |
| TC-4 | `.cwf-agents/` scan target | 1 viol, `file=.cwf-agents/cwf-x.md` | 1 viol, correct file path | PASS |
| TC-5 | non-CWF filename ignored | 0 violations | 0 violations | PASS |
| TC-6 | no frontmatter (line 1 ≠ `---`) | 0 violations | 0 violations | PASS |
| TC-7 | unterminated frontmatter | 0 violations (block not scanned) | 0 violations | PASS |
| TC-8 | multiple bad files, sorted | 2 viols, `cwf-a` then `cwf-b` | 2 viols in sorted order | PASS |
| TC-9 | real tree stays green | `validate: OK`, exit 0 | `[CWF] validate: OK` | PASS |
| TC-10 | full suite | `prove t/` green incl. validate-agents.t | Files=63, Tests=734, all pass | PASS |

### Non-Functional Tests
- **Security**: covered by the f-phase plan-review security pass and the testing-exec
  changeset review below — read-only validator, no command construction, no env reads,
  no prompt-injection surface. Nothing to exercise at runtime.
- **Reliability (malformed input)**: TC-6 (no frontmatter) and TC-7 (unterminated block)
  confirm graceful handling — no crash, no false positive.

## Test Failures

None. (The TC-7 ordering defect was found and fixed during the f-phase — the validator's
detection was reworked to a two-pass find-close-then-scan; see f-implementation-exec.md
Step 2. All cases pass as committed.)

## Coverage Report

- **Critical path** (bad key detected / clean tree silent): both directions covered
  (TC-2, TC-4 positive; TC-1, TC-9 negative). 100%.
- **Edge cases**: body-only (TC-3), unterminated (TC-7), no-frontmatter (TC-6),
  non-CWF namespace (TC-5), installed-context branch (TC-4) — all covered.
- **Regression**: full `t/` suite (734 tests) green; `cwf-manage validate` green on the
  real corpus (all five agents on `tools:`), confirming zero false positives and no
  collateral breakage of the other validators.

## Security Review

**State**: no findings

The shipped files match the diff exactly. I have everything I need to complete the review.

## Security Review — Task 193 testing-exec changeset

This `testing-exec` changeset ships a new read-only validator (`CWF::Validate::Agents`), its wire-in to `cwf-manage validate`, a `t/` unit test, hash entries, and planning docs. I worked through the five threat categories against the shipped code.

**Category (a) — Bash injection / unsafe command construction.** `Agents.pm` constructs no shell commands: no `system`, no backticks/`qx`, no `open '|-'`. Directory traversal is `opendir`/`readdir` with `-d`/`-f` guards; file reads use three-arg `open my $fh, '<', $path`. The wire-in (`cwf-manage` lines 118, 126) is a plain `use` plus a function call `CWF::Validate::Agents::validate($git_root)` — no command construction. The test file likewise uses only three-arg `open` and `make_path`. Nothing to flag.

**Category (b) — git/user output without `-z` / input validation.** The module does not consume git output at all; it enumerates files via `readdir`, so the NUL-separation convention (which concerns parsing git porcelain) does not apply. Filenames come straight from `readdir` as native bytes and are constrained by `grep { /^cwf-.*\.md\z/ }` before any path is built — never split on `\n` from a pipe, so the embedded-newline hazard cannot arise. `$git_root` is caller-supplied (`cwf-manage`'s `find_git_root()`), not untrusted external output. Nothing to flag.

**Category (c) — Prompt injection via user-supplied strings.** The validator reads agent `.md` contents but inspects them only with anchored regexes (`/^---\s*$/`, `/^allowed-tools\s*:/`). No file content flows into LLM context or any downstream prompt; it emits structured violation hashrefs with fixed-string fields plus the repo-relative path. The frontmatter-only scanning with the unterminated-block guard (`return () unless defined $close`) is the correct discipline and avoids the body-prose false-positive class. No prompt-injection surface introduced.

**Category (d) — Unsafe environment-variable handling.** The module reads no environment variables — no `$ENV{...}`. The only path inputs are `$git_root` (caller-supplied) and `readdir`-enumerated basenames constrained to the `cwf-*` namespace. Nothing to flag.

**Category (e) — Pattern-based risks (safe-here-but-risky-elsewhere).** Two informational framings, neither a defect here:

1. **Path construction by string concatenation** (`"$git_root/$subdir"`, `"$dir/$name"` at lines 51, 60). Safe here because `$subdir` is one of two hardcoded literals (`.cwf-agents` / `.claude/agents`) and `$name` is pre-filtered by the `/^cwf-.*\.md\z/` grep before any path is built, so no `..` or absolute component can enter via `$name`; the `-f $path` guard means a symlink resolving outside the tree is still only *read*, never written. Audit framing: if this idiom were copied where the basename came from unfiltered `readdir`, a config value, or user input, a `..`-bearing or absolute name could escape the directory. Safe here because the namespace grep is the invariant; audit future uses where the basename is not pre-filtered.

2. **`die` on `opendir`/`open` failure inside a validator** (lines 54–55, 71–72). Mirrors the sibling `Templates.pm` contract and is reached only after `-d`/`-f` guards, so it fires only on genuine I/O faults — a fail-loud posture turning `cwf-manage validate` non-zero, not a security issue. No DoS angle: the corpus is the repo's own small `cwf-*` agent set, not attacker-supplied volume.

**Other observations.** The `.cwf-agents/`-takes-precedence resolution means an installed project scans only the real files and never double-counts `.claude/agents/` symlinks — correct, avoids a discrepancy. The validator is read-only (no `Write`/`Edit`/`unlink`/`chmod`), so it cannot mutate state. Hash/permission integrity is `cwf-manage validate`'s job per the §16 boundary, not mine; I note only that the shipped `Agents.pm` and `cwf-manage` match the files I read this turn. The change is a net security improvement: it closes the silently-fail-open `allowed-tools:` privilege-escalation footgun for CWF agent definitions. No secrets, credentials, or network calls introduced.

Conclusion: the changeset is clean. The only items raised are category-(e) future-reuse framings, which the threat model admits as informational signal rather than actionable defects.

```cwf-review
state: no findings
summary: Read-only frontmatter linter; no shell/env/git-output/prompt-injection surface introduced. Only category-(e) future-reuse framings noted (path concat safe due to cwf-* namespace grep; die-on-IO-fault matches sibling validators).
```

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
TC-7 (unterminated frontmatter) failed against the first implementation cut and forced the
correct two-pass detection — the test plan caught the defect before it left the exec phase.
See j-retrospective.md.
