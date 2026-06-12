# cwf-init dead UserPromptSubmit hook matcher - Implementation Execution
**Task**: 195 (bugfix)

## Task Reference
- **Task ID**: internal-195
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/195-cwf-init-dead-userpromptsubmit-hook-matcher
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [ ] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [ ] Verify all prerequisites met
- [ ] Execute implementation steps sequentially
- [ ] Update "Actual Results" for each step
- [ ] Document any deviations from plan
- [ ] Update status to "Implemented" when complete

## Implementation Steps (from d-implementation-plan.md)

All steps executed per d-implementation-plan.md (keep-and-fix + keep-D4 resolution).

## Actual Results

### Step 2: Core implementation — `cwf-claude-settings-merge`
- **Planned**: add `$CANONICAL_RULES_INJECT_CMD` (FR4(e) banner), widen the
  `read_hook_directives` event allowlist + header/usage docs (D4), add
  `prune_dead_userpromptsubmit_matcher`, wire prune-before-merge + synthetic-entry
  injection, surface the prune count in stdout.
- **Actual**: done exactly as planned.
  - Header comment (lines 8-21) now enumerates
    `{Stop,SubagentStop,PreToolUse,UserPromptSubmit}` and documents the fixed
    rules-inject hook + migration.
  - `usage()` updated to list all four events + the rules-inject/migration role.
  - Event regex widened to `/^(?:Stop|SubagentStop|PreToolUse|UserPromptSubmit)$/`.
  - `$CANONICAL_RULES_INJECT_CMD = 'cat .cwf/rules-inject.txt 2>/dev/null || true'`
    added beside `$CANONICAL_PERL5OPT` with the FR4(e) compile-time-constant banner.
  - `prune_dead_userpromptsubmit_matcher($settings)` added after `merge_hooks`,
    defensive against every malformed shape, drops empty `PreToolUse`, returns count.
  - `main`: prune runs after `read_settings()`, synthetic UserPromptSubmit entry
    pushed onto `$hook_entries` before `merge_hooks`; `$migrate_note` folds the
    prune count into both the write and `--dry-run` stdout summaries.
- **Deviations**: none.

### Step 3: Tests — `t/cwf-claude-settings-merge.t`
- **Planned**: TC-UPS1–8 + regression-green.
- **Actual**: added TC-UPS1–8 (41 subtests total, all pass). Two **pre-existing**
  subtests needed an intended update: TC-U1 and TC-U4 assert the hook-entry count
  in the stdout summary, which legitimately rises from 1→2 now that the rules-inject
  hook is always registered (the same always-on contract as `env.PERL5OPT`). Updated
  both counts and strengthened TC-U1 to assert the exact UserPromptSubmit group-wrapper
  shape. No behaviour change to any other TC-U*/TC-M*/sandbox case.
- **Deviations**: the TC-U1/TC-U4 count update was not separately called out in the
  plan; it is a direct, expected consequence of the always-on hook (design D1/D5),
  not a scope change.

### Step 4: SKILL.md
- **Planned**: collapse step 6c to a pointer to 6d; preserve the 6b-before-hook
  ordering note.
- **Actual**: step 6c is now "Rule Re-Injection Hook (registered by step 6d)" — no
  manual JSON. Step 6d retitled to include the rules-inject hook. The hard-ordering
  note was repointed from "before step 6c" to "before step 6d" (the hook now lives in
  6d). Success criterion line "Rule re-injection hook configured" still reads correctly.
- **Deviations**: ordering note repointed 6c→6d (the note's intent — rules-inject.txt
  in place before the hook is registered — is preserved; the hook simply moved phases).

### Step 5: Validation
- **Actual**: helper working perms restored to recorded **0500**; `script-hashes.json`
  sha256 refreshed in this same commit (`221bc4…`→`fab967…`); pre-refresh `git log`
  confirmed the helper was untouched since Task 181, so no unrelated drift. SKILL.md is
  under `.claude/` (outside the `.cwf/scripts/` manifest prefix) — unhashed, verified.
  `cwf-manage validate` names **no** integrity violation for the helper.
  Output-level smoke test (scratch dir seeded with the dead entry): dead group pruned,
  `Edit|Write` sibling preserved, correct top-level `UserPromptSubmit` group-wrapper,
  migration surfaced in stdout, second run byte-identical (idempotent).

## Blockers Encountered

None. One fix-on-sight item: `cwf-manage validate` surfaced a **pre-existing** perms
drift on `.cwf/scripts/command-helpers/security-review-changeset` (0700 vs recorded
0500), unrelated to this task. Per [[feedback_permission_drift_fix_on_sight]] it was
clamped immediately with `cwf-manage fix-security` (content/hash untouched) rather than
deferred.

The full `t/` suite is green except `security-review-changeset.t` TC-VALIDATE assertion
3 (`cwf-manage validate exits 0 — fully clean`), which fails only because this in-flight
task's a/c/d/e plan files carry non-terminal `**Status**` values (4 `[WORKFLOW]`
validations). That test requires a globally-clean repo and fails identically on the
pre-edit baseline; its two **integrity** assertions (no violation names the changed
helper or the agent) pass. Not a regression from this change.

## Security Review

**State**: no findings

I have everything I need to assess the security-relevant change. Let me reason through the threat categories.

## Review

The substantive change in this changeset is to `.cwf/scripts/command-helpers/cwf-claude-settings-merge` (plus its hash refresh, its test file, the SKILL.md prose, and the task workflow docs). The helper writes `.claude/settings.json` — a high-trust file whose `command` values Claude Code executes on every matching event with no further trust gate. That makes the `command` and `env` write paths the security-critical surface here, exactly as the FR4(e) banners in the code call out.

### (a) Bash injection / unsafe command construction
No new shell invocation is introduced. The helper manipulates an in-memory Perl data structure and serialises it as JSON; it does not build or run any command string. The one new command *string* it writes (`cat .cwf/rules-inject.txt 2>/dev/null || true`) is a `command` value placed into settings, not executed by the helper. There is no `system`/`qx`/backtick added. Clean.

### (b) git/user output without `-z` / input validation
No new consumption of git porcelain or user output. `prune_dead_userpromptsubmit_matcher` iterates an already-parsed JSON structure with full defensive guards (tolerates `hooks` non-hash, `PreToolUse` non-array, non-hash groups, non-scalar `matcher`) and never dies — verified at lines 309-319 of the current helper and matched by the diff. The widened event regex `/^(?:Stop|SubagentStop|PreToolUse|UserPromptSubmit)$/` is a strict anchored allowlist; values failing it fall back to the safe default. Clean.

### (c) Prompt injection via user-supplied strings
This change introduces no new `{arguments}`/free-text flow into LLM context. The SKILL.md edit removes a hand-written JSON block and points to the deterministic helper — it reduces, rather than increases, prose-driven (model-executed) JSON surgery, which is a net reduction in the recurrence surface. Clean.

### (d) Unsafe environment-variable handling
The critical question for this file: is the value written into the executable `command` path attacker-influenceable? The answer is no. `$CANONICAL_RULES_INJECT_CMD` is a compile-time string constant (line 148), injected into `$hook_entries` *after* `partition_manifest` (lines 163-168), so it deliberately bypasses `read_hook_directives` — it is never sourced from a hook-file header, env var, task slug, or any external input. This mirrors the existing, audited `$CANONICAL_PERL5OPT` precedent, and the banner comment correctly documents the FR4(e) rationale. The tests confirm the emitted `command` is byte-identical to the constant (TC-UPS1, TC-U1). Clean.

### (e) Pattern-based risks (safe-here-but-risky-elsewhere)
One pattern worth recording, framed as a forward-looking audit note rather than a defect:

The synthetic-entry injection pattern at lines 163-168 — `push @$hook_entries, { entry => { command => $CONSTANT }, event => ..., matcher => undef }` post-`partition_manifest` — is **safe here because the `command` value is a compile-time constant and the injection deliberately bypasses `read_hook_directives` validation.** The safety depends entirely on that constant-ness. Audit any future reuse where the pushed `command` (or `event`) is interpolated from a hook-file header, env var, task argument, or other partly-controlled string: bypassing `read_hook_directives` while carrying non-constant data would route attacker-influenceable text straight onto the executed-on-every-event `command` path with no validation. The mitigation, already practised here, is to keep such post-partition injections to documented compile-time constants only (the same discipline `$CANONICAL_PERL5OPT` follows). No change required; this is a guardrail note for the next editor.

### Integrity / hash boundary (out of scope but noted clean)
The `script-hashes.json` sha256 refresh for the edited helper is included in the same changeset, consistent with the hash-updates convention. SHA256/permission *verification* is `cwf-manage validate`'s job, not this reviewer's, so I raise nothing there.

### Conclusion
No actionable security findings. The change keeps the executed-command and env write paths bound to compile-time constants, adds a strictly-anchored event allowlist, and a migration routine that is matcher-scoped and fully defensive. The single pattern note under (e) is a forward-audit guardrail, not a defect in this diff.

```cwf-review
state: no findings
summary: settings.json command/env writes stay compile-time constants (FR4(e) preserved); migration is matcher-scoped and defensive; one (e) forward-audit note on the post-partition synthetic-entry injection, no change required.
```

## Deferral Check
Before marking status=Finished, verify:
- [ ] All steps from d-implementation-plan.md executed
- [ ] All success criteria from a-task-plan.md met
- [ ] All requirements from b-requirements-plan.md addressed (if applicable)
- [ ] All design guidance in c-design-plan.md followed (if applicable)
- [ ] No planned work deferred without user approval
- [ ] If work deferred: Follow-up task created and linked

**If deferral required**: Get user approval, document rationale, create follow-up task.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Recorded inline above (Steps 2–5): helper edits done exactly as planned, sha256 refreshed in
the same commit, working perms restored to recorded 0500. One fix-on-sight item: pre-existing
perms drift on `security-review-changeset` clamped via `cwf-manage fix-security`. Security
review: no findings.

## Lessons Learned
The compile-time-constant discipline for the post-partition synthetic-entry injection is what
keeps FR4(e) intact — the security review flagged it as a forward-audit guardrail (keep such
injections constant-bound, never interpolated). Moving registration into the helper removed
the prose-driven JSON surgery that caused the original dead-matcher bug.
