# Permission-drift repair and agent guidance - Testing Execution
**Task**: 183 (feature)

## Task Reference
- **Task ID**: internal-183
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/183-permission-drift-repair-and-agent-guidance
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
| TC-SWEEP | `fix-security --dry-run` then `validate` (AC1) | exit 0, 0 files; no perm violation | `would repair 0 file(s); 0 unfixable` exit 0; `validate: OK` | PASS | Tree clean (planning-phase clamp cleared residual) |
| TC-RULE | grep `hash-updates.md` for rule (AC2) | heading + byte-identical `cwf-manage fix-security` + rejects defer + ≥1 example | heading at `:24`; bare command at `:28`; "out of scope"/"separate backlog item"/"not part of this task" at `:30`; Task 182 + Task 174 incident example at `:36` (no names) | PASS | |
| TC-BOUNDARY | grep new section (AC3) | clamp-only auto-repairable; sha256 surface-not-smooth; working-tree-only; no recompute instruction | `:32` states clamp is the only on-sight repair + sha256 NOT + "Never recompute a hash to clear a validate warning"; `:34` working-tree-only/no committable diff, cross-refs ceiling + "What NOT to build" | PASS | |
| TC-POINTERS | grep `checkpoint-commit.md` + `CLAUDE.md` (AC2) | both paths carry note + xref; CLAUDE.md pointer bullet | `grep -c` anchor = 2 (Script + Manual paths); `CLAUDE.md:88` pointer bullet | PASS | |
| TC-XREF | derive heading slug (AC2 link integrity) | slug == `fix-permission-drift-on-sight` | `## Fix permission drift on sight` → lowercase, spaces→hyphens, no punctuation = `fix-permission-drift-on-sight` | PASS | Anchor resolves |
| TC-NOSURFACE | diff vs baseline 32b3c4c (AC4) | only 3 docs + wf files; no `script-hashes.json`; no `cwf-manage` change | committed paths = 3 docs + a–f wf files only; `script-hashes.json` and `cwf-manage` diffs empty | PASS | No hash refresh (none hash-tracked) |

### Non-Functional Tests

| Test ID | Test Case | Expected | Actual | Status | Notes |
|---------|-----------|----------|--------|--------|-------|
| TC-REPRO | induce-drift → fix (AC6, centrepiece) | validate flags drift; fix-security clamps; validate OK; clean git status; idempotent | `chmod 0700` → `700`; validate flagged "more permissive than recorded (excess 0200)... run: cwf-manage fix-security" exit 1; fix-security `chmod 0500 (was 0700)` exit 0; post-fix `500`, `validate: OK`; `git status` clean; dry-run re-run `0 file(s)` | PASS | Target `.cwf/scripts/command-helpers/security-review-changeset` (recorded 0500); fully reverted |
| TC-VALIDATE | `validate` after edits (AC4 regression) | `validate: OK` | `validate: OK` exit 0 | PASS | docs-only; no hash/perm desync |

### Deferred

| Test ID | Test Case | Status | Notes |
|---------|-----------|--------|-------|
| TC-RETIRE | retire Task-173 backlog item (AC5) | DEFERRED to j | Runs at retrospective after the `## Task 183:` CHANGELOG section exists (design D7; retire self-bootstraps + is re-run-safe) |

## Test Failures

None. All executed cases passed.

## Coverage Report

- AC1 → TC-SWEEP: PASS. AC2 → TC-RULE + TC-POINTERS + TC-XREF: PASS. AC3 → TC-BOUNDARY: PASS.
  AC4 → TC-NOSURFACE + TC-VALIDATE: PASS. AC6 → TC-REPRO: PASS. AC5 → TC-RETIRE: deferred to j.
- No code ⇒ no line-coverage metric; every AC verifiable now has a deterministic check that passed.
- Notable cross-check: the validate `Fix:` line emitted in TC-REPRO ("run: cwf-manage fix-security")
  is byte-identical to the command quoted in all three edited docs — confirms AC2's byte-identical
  requirement against live tool output, not just source inspection.

## Security Review

**State**: no findings

I have read the full changeset and the threat model. This is the `testing-exec` security review for Task 183. The changeset is the cumulative diff from baseline through the testing-exec phase, comprising the three documentation edits (`hash-updates.md`, `checkpoint-commit.md`, `CLAUDE.md`) plus the standard CWF workflow planning files (a-f).

Let me reason through the five threat categories.

**Nature of the changeset.** Four substantive files plus workflow docs:
- `.cwf/docs/conventions/hash-updates.md` — new `## Fix permission drift on sight` section.
- `.cwf/docs/skills/checkpoint-commit.md` — fix-on-sight notes on both the script and manual paths.
- `CLAUDE.md` — one pointer bullet under the Hash Updates conventions entry.
- `implementation-guide/183-.../{a..f}-*.md` — the CWF workflow step files (the f-exec file itself embeds the implementation-exec security review verdict, which is prose, not code).

No Perl, shell, hooks, agents, `cwf-manage` surface changes, or `script-hashes.json` edits. Design decision D8 explicitly rejects touching the hash-tracked `claude-md-preamble.md`.

**(a) Bash injection / unsafe command construction.** No code is added or modified. The docs quote command strings (`cwf-manage fix-security`, `chmod 0700 <script>`) as literal prose for an agent to run, not as shell built from interpolated untrusted input. The FR6/TC-REPRO induce-drift procedure prescribes `chmod 0700` on a *named, recorded* tracked script — no string interpolation from task slugs, branch names, or user input. No concern.

**(b) Perl helpers consuming git/user output without `-z`.** No Perl is added or changed. FR1/FR4 reuse the existing clamp-only `fix-security` engine rather than building a new one. No concern.

**(c) Prompt injection via user-supplied strings.** No new `{arguments}` substitution surface or LLM-context flow is introduced. The new convention prose is authored static content that ships into agent context — that is the intended behaviour of a convention doc, not untrusted input relayed verbatim. The negative examples are phrased by rationalisation and incident number with no user-controlled interpolation. No concern.

**(d) Unsafe environment-variable handling.** No env vars introduced or consumed. No `chmod`/`rm`/`open` path is built from an env var. No concern.

**(e) Pattern-based risks (safe-here-but-risky-elsewhere).** The substantive content of this change is itself a *defensive* boundary statement, and it draws the line correctly: auto-repair is scoped strictly to permission **clamping** (`actual & recorded` — can only clear bits, never raise), and auto-absorbing **sha256/content** drift is explicitly forbidden, cross-referencing the existing "what NOT to build" / "surface, never smooth" prohibition. This preserves the tamper-signal guarantee. I checked specifically for the failure mode the threat model and the project's standing rules care about — a new surface that silences `cwf-manage validate` without surfacing first — and FR4/AC4/TC-NOSURFACE explicitly forbid it; no such surface is added. The testing-exec phase adds no new code beyond the f-exec embedded verdict prose, so the threat surface is identical to what the implementation-exec review covered.

One pattern worth a forward note, with the required framing: the FR6/TC-REPRO procedure (now operationalised in the testing-exec phase) instructs an agent to deliberately induce a security-relevant state (`chmod 0700` on a recorded-`0500` tracked script) then repair it. **Safe here because** the induced bit is `u+rwx` only (no group/other write/execute, no setuid/setgid/sticky), the target is a single named tracked script in the working tree, the change is within git's `100755` class so it produces no committable diff, and `validate` keeps flagging until the idempotent clamp runs (interrupt-recovery is documented). **Audit future uses where** this "induce drift then fix" recipe is copied into a context that loosens *group/other* write/execute or setuid/setgid bits, or that operates on a hashed file's *content* rather than its mode — there the same recipe would cross from a reversible mode tweak into either a recorded-ceiling-widening or a tamper-signal scenario the clamp cannot undo. This is a documentation note, not a defect in the diff as written.

No actionable security concerns in this changeset.

```cwf-review
state: no findings
summary: Testing-exec review of docs-only Task-183 change; auto-repair correctly scoped to permission clamping, sha256 surface-not-smooth boundary preserved; no code, env, or injection surface added.
```

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*See Test Results tables above.*

## Lessons Learned
*To be captured during retrospective*
