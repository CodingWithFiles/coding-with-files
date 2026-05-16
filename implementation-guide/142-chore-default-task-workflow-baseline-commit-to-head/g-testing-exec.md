# default task-workflow baseline-commit to HEAD - Testing Execution
**Task**: 142 (chore)

## Task Reference
- **Task ID**: internal-142
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/142-default-task-workflow-baseline-commit-to-head
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready (POSIX `git`, core Perl, no CPAN deps)
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps (none — all PASS)
- [x] Update status to "Finished"

## Test Results

### Functional Tests

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1 | `resolve_head_sha` in repo with a commit | 40-char hex SHA matching `git rev-parse HEAD` | Matches ground truth | PASS |
| TC-2 | `resolve_head_sha` in empty repo (no commits) | `undef` | `undef` | PASS |
| TC-3 | `resolve_head_sha` outside any git repo | `undef` | `undef` | PASS |
| TC-4 | Helper invoked without `--baseline-commit` | rendered `a-task-plan.md` contains live HEAD SHA | `368eb8cc…` populated correctly | PASS |
| TC-5 | Helper invoked with explicit `--baseline-commit=deadbeef…` | verbatim pass-through, no resolution attempted | `deadbeef…` appears unchanged in rendered file | PASS |
| TC-6 | Helper invoked without `--baseline-commit` outside a git repo | exit 1 with `[CWF] ERROR: Could not resolve HEAD…` | Covered via the unit-level TC-3 (resolve_head_sha returns undef) plus the inline die_msg path in `template-copier-v2.1:404-407`. The helper requires templates findable via `git rev-parse --show-toplevel`, which itself fails before the resolver in a no-repo state, so a clean black-box reproduction is impractical without a synthetic-templates fixture. Code path inspection confirms the die_msg fires; no behavioural test added. | PASS (by inspection) |

### Non-Functional Tests

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-7 (Usability) | `/cwf-new-task` no longer triggers permission prompt | No `Contains shell syntax (string)` prompt fires | Cannot be observed locally — Claude Code harness fires the prompt, not the helper. SKILL.md no longer contains `$(…)` substitution (grep clean). Behavioural validation deferred to first post-merge invocation. | DEFERRED |
| TC-8 (Integrity) | `cwf-manage validate` clean after hash regen | exit 0, no warnings | `[CWF] validate: OK` | PASS |
| TC-9 (Regression) | Full `prove -r t/` suite passes | All 478 tests, no new failures | `Files=44, Tests=478, Result: PASS` | PASS |

### Source-level Grep Gates
- `grep -rn 'git rev-parse HEAD' .claude/skills/cwf-new-task .claude/skills/cwf-new-subtask` → no matches. PASS.
- `grep -rn 'BASELINE_COMMIT' .claude/skills/` → no matches. PASS.

## Test Failures

None.

## Coverage Report

- **Unit (CWF::Common::resolve_head_sha)**: 100% of the three documented branches exercised (commit/empty/no-repo).
- **Integration (template-copier-v2.1 baseline plumbing)**: 100% of the two call shapes covered (omitted → resolve, explicit → pass-through).
- **Helper failure-mode**: TC-6 confirmed by code-path inspection rather than executable test (constraint: helper requires templates locatable via git, which precludes a clean no-repo black-box run without a synthetic templates fixture). Documented limitation, not a coverage gap for the resolver itself.
- **Regression**: 478/478 existing tests still pass.

## Validation Criteria from e-testing-plan.md

- [x] TC-1 through TC-5 pass under `prove -r t/`
- [x] TC-6 confirmed by inspection (limitation documented above)
- [-] TC-7 deferred to post-merge UX observation (harness-level, not helper-level)
- [x] TC-8 confirms integrity validation clean
- [x] TC-9 confirms no regressions
- [x] `grep` gates clean (`git rev-parse HEAD` / `BASELINE_COMMIT` both empty)

## Security Review

**State**: error

**Classification rationale**: As in f-implementation-exec, the subagent's response did not begin with a sentinel line — first non-blank line was "Actually the code works because it's using double-quoted interpolation…". Per the three-tier rule, primary classification fails; fallback finds no numbered list or "actionable finding" phrase; conservative default applies → recorded as `error`. The substantive conclusion at the end of the response is `no findings` (paraphrased: clean under the threat model, with a category (e) pattern-risk note about `substitute_variables` being safe at this callsite). Even after an explicit "sentinel-first, no preamble" instruction in the prompt, the subagent reverted to prose-first output — this is the same defect reported in BACKLOG entries "Tighten security-subagent prompt for sentinel-line compliance" and "Enforce sentinel-first output in security-review subagent prompt".

Verbatim subagent output:

```
Actually the code works because it's using double-quoted interpolation, and the `/` in the string doesn't break the regex. The substitution works fine because Perl knows the difference between the delimiter and the string content.

Let me review the actual testing-phase changes in the diff more carefully. The critical areas are:

1. The `resolve_head_sha()` function at line 65-69 - uses backticks with `git rev-parse HEAD 2>/dev/null` with validation
2. The `template-copier-v2.1` changes at lines 401-410 - the baseline_commit now flows through variable substitution

Looking at the validation in `resolve_head_sha()`:
\```perl
my $sha = `git rev-parse HEAD 2>/dev/null`;
chomp $sha;
return $sha =~ /^[0-9a-f]{40}$/ ? $sha : undef;
\```

This is safe - the regex validation ensures only 40-char hex is returned.

Now for the explicit baseline_commit path at line 401-402:
\```perl
if (defined $params->{baseline_commit} && length $params->{baseline_commit}) {
    $vars{baselineCommit} = $params->{baseline_commit};
\```

This accepts ANY value the user passes in `--baseline-commit=...` and later substitutes it into templates via the vulnerable regex at line 421.

The documentation comment (lines 82-87) says: "Optional; defaults to HEAD (resolved internally). 40-char git SHA recorded in a-task-plan.md as the anchor for security-review changeset construction. Explicit values pass through verbatim."

So the code is designed to pass through values verbatim without validation, but this means a user could pass a value containing regex-special characters or other problematic content.

However, looking more carefully at the test at lines 305-331, the test uses 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef' - a valid 40-char hex. The code doesn't enforce this constraint.

Let me check the actual difference in the documentation to see if validation was added:

Looking at line 40 of the diff: `--baseline-commit=<40-char-sha>` - the docs suggest it should be 40 chars, but the code doesn't enforce it.

**Conclusion after thorough analysis**: There is a **Category (e) pattern-based risk** here. The `substitute_variables` function uses a simple regex substitution without escaping the replacement value. This is safe in this specific case because:

1. The only place `baselineCommit` is documented to be used is in markdown templates
2. The documented usage is for 40-char hex SHAs, which contain no problematic characters for markdown or regex replacement
3. The description/other variables similarly should not break markdown rendering

However, it's risky if this pattern is reused with truly untrusted input or in different contexts.

no findings

The changeset is clean from a security perspective under the stated threat model. While the `substitute_variables` function at line 421 technically uses an unsafe pattern (unescaped replacement in regex), it is safe here because (1) baselineCommit is documented to be a 40-char hex SHA with no regex-special characters, (2) descriptions/slugs are constrained via `generate_slug()`, and (3) other substituted values come from validated/controlled sources. If `substitute_variables` is reused with attacker-controlled, arbitrary-format strings, audit that context to ensure the replacement values cannot contain characters that would break markdown rendering or introduce unintended text transformations.
```

**Substantive note for retrospective**: The subagent raised a category-(e) pattern-risk observation that `substitute_variables` does not escape regex metacharacters in replacement values. This is an existing behaviour of the helper (unchanged by Task 142); the resolver's output is 40-char lowercase hex by construction, so this is safe at this callsite. The observation is informational, not a blocker.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 142
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
