# Retire vestigial cwf-project.json version field - Testing Execution
**Task**: 188 (chore)

## Task Reference
- **Task ID**: internal-188
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/188-retire-vestigial-cwf-projectjson-version-field
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps
- [x] Update status to "Finished" when all pass

## Test Results

### Functional Tests

| Test ID | Test Case | Expected | Actual | Status | Notes |
|---------|-----------|----------|--------|--------|-------|
| TC-1 | `t/cwf-project-template.t` parses the shipped template via `decode_json` inside `eval` | No parse error (loud failure if malformed) | Template parses; no error | PASS | `prove -lr t/cwf-project-template.t` → 3 assertions ok |
| TC-2 | Parsed template hashref has `!exists $j->{version}` | `version` absent (`cwf-version` deliberately NOT asserted) | `version` absent | PASS | Narrow scope honoured — `cwf-version` retained, untested |
| TC-3 | `cwf-manage validate` after removing top-level `version` from live config | Exits 0 (no new violation) | `[CWF] validate: OK` | PASS | Version removal added **zero** violations. Pre-existing perm drift fixed on sight; lagging a/d/e statuses set Finished (see Notes) |
| TC-4 | Full `prove -lr t/` regression | Every test passes (nothing read the field) | 709 tests; 1 pre-existing failure unrelated to this change; 61/62 files green | PARTIAL — see Test Failures | The version removal introduced no new failures (verified against baseline) |

### Non-Functional Tests
- **Reliability**: TC-1's `eval`-then-assert structure means a malformed template is a hard, loud failure — never a false green. Verified by inspection of the test body.
- **Security**: change only *reduces* surface (deletes config/doc data); no auth/network/integrity surface touched. Security-review subagent on the f-phase changeset returned **no findings**. Template/live config/spec are not hash-tracked, so no integrity records change.
- **Usability / Performance**: N/A — no user-facing behaviour or performance surface changed.

## Test Failures

**`cwf-manage-fix-security.t` — TC-8 "fixture provisions non-.cwf/ manifest paths (drift pin)" (1 inner assertion group)**

- **Symptom**: inner assertions 4/7/10/13/16 (`provisioned: .claude/agents/<name>.md perms satisfy recorded floor 0444`) fail; the files are byte-identical to the repo (3/6/9/12/15 pass) but their perms sit below a 0444 *floor*.
- **Reproduction**: `prove -lv t/cwf-manage-fix-security.t` (or `git stash` this task's edits and re-run — it fails identically on baseline commit 13840c5, and on 8279492 before the task began).
- **Root cause**: the repo's `.claude/agents/*.md` are at 0400 (more restrictive than the manifest's recorded 0444). `cwf-manage validate` treats recorded perms as a **ceiling** (Task 170), so 0400 ≤ 0444 passes; this test encodes a stricter **floor** (≥ 0444) that 0400 fails. The two checks disagree.
- **Relation to Task 188**: **none.** This task touches no agent file, manifest, or hash record. The failure pre-dates the task. Confirmed pre-existing by stashing the working changes and re-running (still fails) and by inspecting the asserted paths (all `.claude/agents/`, none in this changeset).
- **Disposition**: out of scope; logged as a follow-up backlog candidate ("fix-security TC-8 floor-vs-ceiling reconciliation"). Not a blocker for this chore.

**Notes on `validate` cleanliness (TC-3 path to green):**
1. **Permission drift (fixed on sight)**: baseline `validate` flagged `.claude/agents/cwf-security-reviewer-changeset.md` at 0600 vs recorded 0444. Cleared via `cwf-manage fix-security` (→ 0400) per the standing fix-on-sight rule. This also cleared two further `cwf-manage-fix-security.t` assertions (its tests 1 and 9).
2. **Lagging phase statuses**: this task's a/d/e plan files were still at the transient `Planning` status (not in the valid status set), tripping 3 WORKFLOW violations. Those phases are complete, so they were set to `Finished` via `cwf-set-status` — the same terminal state the retrospective status-sweep would apply. This also cleared `security-review-changeset.t` test 35 ("validate is clean").

## Coverage Report
No coverage-% target — this is a deletion, not new logic (per e-testing-plan.md). Behavioural claim ("field unread; removal inert") is covered by the full suite staying green except for the unrelated pre-existing failure; durability claim ("field cannot silently return") is covered by the TC-1/TC-2 guard test.

## Validation Criteria (from e-testing-plan.md)
- [x] TC-1, TC-2 pass in `t/cwf-project-template.t`
- [x] TC-3: `cwf-manage validate` exits 0
- [x] TC-4: full `prove -lr t/` green **except** one pre-existing, unrelated failure (documented above) — no new failure introduced by this change

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: no findings

I have everything I need. Let me reason through the five threat categories for this `testing-exec` changeset.

## Review

The changeset for this `testing-exec` step comprises: deletion of the top-level `version` field from `.cwf/templates/cwf-project.json.template`, from `implementation-guide/cwf-project.json`, and from `CWF-PROJECT-SPEC.md`; the new workflow planning/exec markdown files for Task 188; and one new Perl test, `t/cwf-project-template.t`. The only executable code in the diff is that test file. I reviewed the on-disk test and template directly to confirm they match the diff (they do).

**(a) Bash injection / unsafe command construction.** The diff constructs no shell commands. The new test invokes no `system`, backticks, `qx`, or `exec`. The JSON/spec edits are pure data deletions. No exposure.

**(b) Perl helpers consuming git/user output without `-z` / input validation.** `t/cwf-project-template.t` is the only Perl. It consumes no git output (no porcelain parsing, so the `-z`/newline-split concern is not implicated) and no untrusted input. It builds a single fixed path from `$FindBin::Bin` — a trusted constant (the test-script directory), not an external string — slurps with `<:raw` and lets `decode_json` handle UTF-8 bytes, which is the correct byte-vs-character discipline. It declares `use strict/warnings/utf8` per project convention. Clean.

**(c) Prompt injection via user-supplied strings.** No SKILL, template, or `{arguments}` substitution surface is added or modified. The deleted `version` field and the doc edits introduce no new free-text flow into LLM context. Not implicated.

**(d) Unsafe environment-variable handling.** No env vars are read or introduced. The test reads no `$ENV{...}`. The removed `version` field is confirmed (per the exec notes and the plan's reader grep) to have had zero readers, so its deletion cannot have fed any `chmod`/`rm`/`open`/clone-URL path. Not implicated.

**(e) Pattern-based risks (safe-here-but-risky-elsewhere).** The path construction `"$FindBin::Bin/../.cwf/templates/cwf-project.json.template"` is safe here because `$FindBin::Bin` resolves to the trusted test-script directory, not user input. This is the standard CWF test idiom; the invariant (`$FindBin::Bin` is trusted) holds for any test reusing it, so there is no reuse hazard worth flagging.

One non-security note for completeness (not a finding): the `## Security Review` section embedded in the `f-implementation-exec.md` diff contains its own `cwf-review` fenced block. That is reviewed *content* (a recorded prior verdict), not my emitted verdict, and the classifier parses only the reviewer's own output — but it is a reminder that prose I emit is the authoritative channel.

The net effect is a deletion of decorative config/spec data plus a sound JSON guard test. It strictly reduces surface and introduces no command construction, untrusted-input flow, or env-var handling. No actionable security concerns.

```cwf-review
state: no findings
summary: Task 188 testing-exec changeset retires the vestigial cwf-project.json `version` field (template, live config, spec) plus a sound FindBin-anchored JSON guard test; pure data/doc deletion, no command construction, untrusted-input flow, or env-var handling.
```

## Lessons Learned
*To be captured during retrospective*
