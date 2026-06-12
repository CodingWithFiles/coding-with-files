# cwf-init dead UserPromptSubmit hook matcher - Testing Execution
**Task**: 195 (bugfix)

## Task Reference
- **Task ID**: internal-195
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/195-cwf-init-dead-userpromptsubmit-hook-matcher
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
New subtests in `t/cwf-claude-settings-merge.t` (helper suite: **41 subtests, all
PASS** — `prove t/cwf-claude-settings-merge.t` → Result: PASS).

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-UPS1 | Fresh add — UserPromptSubmit group-wrapper shape | `[{hooks=>[{type,command}]}]`, no matcher key | exact shape, no matcher | PASS |
| TC-UPS2 | Migration removes dead entry, preserves Edit\|Write sibling | dead group gone, sibling kept, stdout count ≥1 | 1 PreToolUse group (Edit\|Write), migrate note "migrated 1…" | PASS |
| TC-UPS3 | PreToolUse key dropped when emptied | key absent (not `[]`) | key absent | PASS |
| TC-UPS4 | Idempotent re-run after convergence | byte-identical, 0 hooks added, no migrate note | byte-identical, "added 0…0 hook entries" | PASS |
| TC-UPS5 | Defensive over 4 malformed PreToolUse shapes | exit 0 each, hook still registered | exit 0 ×4, UserPromptSubmit present ×4 | PASS |
| TC-UPS6 | Index-0 matcher-bearing UserPromptSubmit group | appended into [0], re-run dedupes | appended into matcher=X group, single copy on re-run | PASS |
| TC-UPS7 | `--dry-run` writes nothing | on-disk file untouched, migration previewed | file unchanged, "migrated 1…(dry-run)" + JSON | PASS |
| TC-UPS8 | Directive-driven UserPromptSubmit honoured (D4) | registers under UserPromptSubmit, not Stop | under UserPromptSubmit, absent from Stop | PASS |
| TC-U1\* | Regression — fresh population (count 1→2) | 2 hook entries + UPS shape | 2 hooks, UPS group-wrapper | PASS |
| TC-U4\* | Regression — `--dry-run` summary (count 1→2) | "2 hook entries" | matches | PASS |

\* TC-U1/TC-U4 updated for the intended always-on rules-inject hook (the hook-entry
count legitimately rises 1→2). No other TC-U\*/TC-M\*/sandbox case changed.

### Non-Functional Tests
- **Reliability (TC-UPS5)**: best-effort over hand-edited settings — all four malformed
  `PreToolUse` shapes (non-array, non-hash group, missing matcher, non-scalar matcher)
  exit 0; never aborts the install/update. PASS.
- **Security (FR4(e))**: the emitted hook `command` is byte-identical to the
  compile-time constant `cat .cwf/rules-inject.txt 2>/dev/null || true` (asserted in
  TC-UPS1/TC-U1); exec-phase security review returned **no findings**. PASS.
- **Integrity**: `cwf-manage validate` reports **0 SECURITY violations** (helper sha256
  refreshed in the f-exec commit; perms at recorded 0500). `cwf-manage fix-security
  --dry-run` → "would repair 0 file(s); 0 unfixable" — no permission drift. PASS.
- **Output-level smoke test** (per MEMORY.md): real helper run in a scratch dir seeded
  with the dead entry produced the correct top-level `UserPromptSubmit` group-wrapper,
  pruned the dead group, preserved the `Edit|Write` sibling, surfaced "migrated 1 legacy
  dead PreToolUse/UserPromptSubmit hook entry", and was byte-identical on re-run. PASS.

## Test Failures

Full suite: `prove t/` → **749 tests, 748 PASS, 1 FAIL**.

The single failure is `t/security-review-changeset.t` subtest 35 (`TC-VALIDATE`),
assertion 3 only: `cwf-manage validate exits 0 (fully clean)`. It fails because this
in-flight task's a/c/d/e plan files carry non-terminal `**Status**` values (`Planning`,
`Design`, `Implementation Planning`, `Testing Planning`), which `cwf-manage validate`
reports as 4 `[WORKFLOW]` violations → non-zero exit. That assertion requires a
globally-clean repo and fails identically on the pre-edit baseline. Its two
**integrity** assertions — "no integrity violation names the changed helper" and "…the
migrated agent" — both PASS, confirming the same-commit hash refresh is consistent.

- **Not a regression** from this change; it is an artefact of running the suite mid-task.
- **Resolves on its own** once the workflow reaches terminal status (the retrospective
  status sweep marks every phase Finished/Skipped), restoring a clean `validate`.

## Coverage Report

- **Critical paths (100%)**: fresh registration, migration, empty-key drop, idempotency,
  defensive guards — all covered by TC-UPS1–4, TC-UPS5.
- **Edge cases**: all four malformed-`PreToolUse` shapes (TC-UPS5) + index-0
  matcher-bearing group (TC-UPS6) + D4 directive widening (TC-UPS8).
- **Regression**: full `t/` green except the documented in-flight `validate` artefact;
  zero behaviour change for non-UserPromptSubmit paths.

## Security Review

**State**: no findings

The source confirms the diff. The logic is exactly as described: `find_or_make_group(undef)` returns index-0 group, cross-group command dedup in `merge_hooks`, and the matcher-scoped defensive prune. Let me reason through the threat categories.

## Review

The substantive code change in this changeset is to `/home/matt/repo/coding-with-files/.cwf/scripts/command-helpers/cwf-claude-settings-merge` (plus its same-commit hash refresh, its test file `t/cwf-claude-settings-merge.t`, the `cwf-init/SKILL.md` prose, and the task workflow docs). The helper writes `.claude/settings.json` — a high-trust file whose `command` and `env` values Claude Code applies/executes on every matching event with no further trust gate. That is the security-critical surface, exactly as the in-code FR4(e) banners call out. I verified the diff against the live source (lines 243-336) to confirm the load-bearing dedup/prune semantics rather than trusting the f-exec narrative.

### (a) Bash injection / unsafe command construction
No new shell invocation. The helper manipulates an in-memory Perl structure and serialises it as JSON; it never builds or runs a command string. The new constant `cat .cwf/rules-inject.txt 2>/dev/null || true` is a `command` *value written into settings*, not executed by the helper. No `system`/`qx`/backtick added. `prune_dead_userpromptsubmit_matcher` is pure data filtering. Clean.

### (b) git/user output without `-z` / input validation
No new consumption of git porcelain or user output. The prune iterates an already-parsed JSON structure with full defensive guards (verified lines 311-319: tolerates `hooks` non-hash, `PreToolUse` non-array, non-hash groups, `matcher` absent or non-scalar via `!ref $_->{matcher}`) and never dies — and TC-UPS5 exercises all four malformed shapes. The widened directive regex `/^(?:Stop|SubagentStop|PreToolUse|UserPromptSubmit)$/` is a strict anchored allowlist; non-matching values fall back to the safe `Stop`/no-matcher default. Clean.

### (c) Prompt injection via user-supplied strings
No new `{arguments}`/free-text flow into LLM context. The SKILL.md edit *removes* a hand-written JSON block and points to the deterministic helper — a net reduction in model-executed (prose-driven) JSON surgery, which was this bug's root cause. Clean.

### (d) Unsafe environment-variable handling
The decisive question for this file: is the value landing on the executed `command` path attacker-influenceable? No. `$CANONICAL_RULES_INJECT_CMD` is a compile-time constant (line 336), pushed onto `$hook_entries` *after* `partition_manifest` (diff lines 163-168), so it deliberately bypasses `read_hook_directives`. It is never sourced from a hook-file header, env var, task slug, or any external input. This mirrors the audited `$CANONICAL_PERL5OPT` precedent and the banner documents the FR4(e) rationale. TC-UPS1/TC-U1 assert the emitted `command` is byte-identical to the constant. Clean.

### (e) Pattern-based risks (safe-here-but-risky-elsewhere)
One forward-audit note, not a defect. The post-`partition_manifest` synthetic-entry injection — `push @$hook_entries, { entry => { command => $CONSTANT }, event => 'UserPromptSubmit', matcher => undef }` — is **safe here because the `command` is a compile-time constant and the injection deliberately bypasses `read_hook_directives` validation.** The safety rests entirely on that constant-ness. **Audit any future reuse where the pushed `command` (or `event`) is interpolated from a hook-file header, env var, task argument, or other partly-controlled string**: bypassing `read_hook_directives` while carrying non-constant data would route attacker-influenceable text straight onto the executed-on-every-event `command` path with no validation. The mitigation, already practised here, is to keep post-partition injections to documented compile-time constants only (same discipline as `$CANONICAL_PERL5OPT`). No change required.

A second, smaller pattern observation for the same audit bucket: `merge_hooks` dedups by `command` string across all groups for an event (lines 277-294), and `find_or_make_group(undef)` appends into index-0 (lines 245-250). Both are safe here because the injected command is a fixed constant, so dedup is exact and the worst case (TC-UPS6: appended into a pre-existing matcher-bearing index-0 group) still fires correctly and dedups on re-run. This invariant would weaken if the per-event command were ever made dynamic.

### Integrity / hash boundary (out of scope, noted clean)
The `script-hashes.json` sha256 refresh (`221bc4…`→`fab967…`) is in the same changeset, per the hash-updates convention. SHA256/permission *verification* is `cwf-manage validate`'s job, not this reviewer's. The f-exec note about the pre-existing perms drift on `security-review-changeset` (clamped via `fix-security`) and the in-flight `TC-VALIDATE` workflow-status artefact are process/integrity items outside this threat model.

### Conclusion
No actionable security findings. The change keeps the executed-command and env write paths bound to compile-time constants, adds a strictly-anchored event allowlist, and a matcher-scoped, fully-defensive migration. The (e) notes are forward-audit guardrails for the next editor, not defects in this diff.

```cwf-review
state: no findings
summary: settings.json command/env writes stay compile-time constants (FR4(e) preserved); migration is matcher-scoped and defensive; (e) forward-audit note on post-partition synthetic-entry injection and per-event command dedup staying constant-bound — no change required.
```

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Recorded inline above (Test Results / Coverage): 41 helper subtests PASS; full `t/` 748/749
with the single failure being the documented in-flight TC-VALIDATE artefact (resolved by the
retrospective status sweep). `cwf-manage validate`: 0 SECURITY violations; no permission drift.
Security review: no findings.

## Lessons Learned
The output-level smoke test is the right final gate for any change that emits structured
config — it confirmed the top-level group-wrapper, the matcher-scoped prune, sibling
preservation, the surfaced migration count, and byte-identical idempotency in one run. The
TC-VALIDATE red is a recurring mid-task suite artefact, not a regression; understanding it
once avoids re-triaging it each phase.
