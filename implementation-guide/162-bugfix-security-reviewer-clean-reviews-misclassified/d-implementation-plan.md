# security-reviewer clean reviews misclassified - Implementation Plan
**Task**: 162 (bugfix)

## Task Reference
- **Task ID**: internal-162
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/162-security-reviewer-clean-reviews-misclassified
- **Template Version**: 2.1

## Goal
Implement the design: a deterministic `cwf-review` verdict container (D1), a `security-review-classify` helper as the single parse authority (D2/D3), exec-skill rewiring, and the SubagentStop enforcement hook with its merge-helper plumbing (D4).

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why". Sequence: land the core fix (D1–D3) first as a coherent unit, then the D4 plumbing.

## Files to Modify
### Primary Changes
- `.cwf/scripts/command-helpers/security-review-classify` *(NEW, hashed)* — deterministic parser; reads subagent output on stdin, prints one of `no findings|findings|error`. Implements the D3 rule (exactly-one-valid-`cwf-review`-block → its state; zero or >1 → `error`).
- `.claude/agents/cwf-security-reviewer-changeset.md` *(HASHED — refresh)* — replace the line-1-sentinel contract with the trailing `cwf-review` container contract + a worked example whose `state:` is the non-token placeholder `<no findings|findings|error>`.
- `.cwf/docs/skills/security-review.md` *(not hashed)* — replace § "Exec-phase prompt template" three-tier rule (lines 143–149) with the container contract + a reference to `security-review-classify`. Skill-authored short-circuits (on-main / empty / >500-line cap) unchanged.
- `.claude/skills/cwf-implementation-exec/SKILL.md` *(not hashed)* — Step 8: write subagent output to the task tmp dir, run `security-review-classify < file`, record `**State**:` + verbatim. Replaces "Classify per the three-tier rule".
- `.claude/skills/cwf-testing-exec/SKILL.md` *(not hashed)* — same Step 8 change.
- `.cwf/scripts/hooks/subagentstop-security-verdict-guard` *(NEW, hashed)* — SubagentStop fail-open guard reusing the classifier.
- `.cwf/scripts/command-helpers/cwf-claude-settings-merge` *(HASHED — refresh)* — learn per-hook event/matcher from header directives; generalise `merge_hooks` to register by event + optional matcher group.
- `.cwf/docs/workflow/stop-hooks-framework.md` *(not hashed)* — document the SubagentStop event, the `agent_type` matcher, and the hook header-directive convention.

### Supporting Changes
- `.cwf/security/script-hashes.json` — 2 refreshes (agent def, merge helper) + 2 new entries (classifier, hook). Per `.cwf/docs/conventions/hash-updates.md`: refresh in the same commit as each source edit, verifying per-file with `git log <last-hash-commit>..HEAD -- <path>` first.
- `t/security-review-classify.t` *(NEW)* — classifier unit tests (fixtures).
- `t/cwf-claude-settings-merge.t` *(extend)* — SubagentStop+matcher registration, header-directive parsing, idempotency, backward-compat (existing Stop hooks still register matcher-less under `hooks.Stop`).

## Implementation Steps

### Step 1: Classifier helper + tests (D2/D3) — core
- [ ] Write `security-review-classify` (`#!/usr/bin/env perl`, `use strict/warnings/utf8`, core-only). Include a `--help`/usage stub for parity with sibling command-helpers. Scan stdin for fenced ```` ```cwf-review ```` blocks; collect blocks whose `state:` (trimmed, case-insensitive) is exactly one of the three tokens; apply the exactly-one rule; print the canonical token. Exit 0 always (the token, incl. `error`, is the signal). `chmod 0500`.
- [ ] Write `t/security-review-classify.t` fixtures: clean block after heavy prose; each markdown wrapping (bare/bold/backtick/blockquote); `findings`/`error`; **empty stdin → `error`**; zero blocks → `error`; invalid `state:` value → `error`; **lone block with empty/whitespace `state:` → `error`** (not ignored into a different tally); **unterminated fence (no closing ```` ``` ````) → `error`**; two valid blocks → `error`; echoed non-token example (→ `error` if alone; ignored if alongside exactly one valid block).
- [ ] Add the helper's hash entry; `cwf-manage validate`.

### Step 2: Agent container contract (D1) — core
- [ ] Rewrite the agent definition body: container contract + worked example (non-token placeholder `state: <no findings|findings|error>`); remove the "VERY FIRST output line" sentinel language; keep the threat-model reference and the pattern-risk carve-out.
- [ ] **Update the frontmatter `description`** — currently "Emits sentinel-line classification." (line 3), now false; reword to the `cwf-review` container. (Same hashed file.)
- [ ] Refresh the agent's hash entry (verify `git log <last-hash-commit>..HEAD -- <path>` first); `cwf-manage validate`.

### Step 3: Wire callers (D2 integration) — core
- [ ] Update `security-review.md` § "Exec-phase prompt template": container contract + `security-review-classify` reference; drop the three-tier rule; keep short-circuits.
- [ ] Update both exec SKILL Step 8 lines (`cwf-implementation-exec/SKILL.md:56`, `cwf-testing-exec/SKILL.md:50`): capture subagent output to a task tmp-dir file (per `tmp-paths` convention — `mkdir -m 0700` first-use guard), `security-review-classify < file` → state, record `**State**:` + verbatim. (Not hashed — no hash refresh.)
- [ ] **Core fix is now complete and coherent** — committable standalone.

### Step 4: SubagentStop hook (D4 part 1)
- [ ] Write `subagentstop-security-verdict-guard` (Perl, `JSON::PP`). **Mirror the `return`-inside-`eval` pattern of `stop-uncommitted-changes-warning`, NOT the `exit`-inside-`eval` of `stop-stale-status-detector`**: wrap the body in `eval`, use `return` for early-outs, compute a single `$decision` variable, and have **exactly one** `exit 0` after the `eval`. Emit the block-JSON (if any) in one place.
- [ ] Decision rule (affirmative-only block): decode stdin JSON → `last_assistant_message`, `stop_hook_active`. Run `security-review-classify` as a subprocess on a **pipe/stdin only** (never a message-derived path, never a shell). **Block only when** the classifier ran cleanly AND returned exactly `error` AND `stop_hook_active` is false. **Allow the stop** in every other case — valid verdict (`no findings`/`findings`), `stop_hook_active` true, classifier unreachable/non-zero/empty, malformed stdin JSON, or any exception (fail-open). Never block on the hook's own failure.
- [ ] The `reason` string is a **fixed literal** (re-emit instruction); build the output JSON via `JSON::PP->encode`, never string concatenation, so no stdin-derived data is interpolated into harness-visible output.
- [ ] Reuse the single parser: the hook **invokes `security-review-classify`** as a subprocess — it must NOT reimplement block detection inline (preserves the D2 single-authority goal).
- [ ] Header directives: `# cwf-hook-event: SubagentStop`, `# cwf-hook-matcher: cwf-security-reviewer-changeset`. `chmod 0500`.
- [ ] Add the hook's hash entry **before** the Step 5 merge-helper edit, so any environment running the new `partition_manifest` already hash-tracks the hook (tampered hook caught by `cwf-manage validate`, not silently parsed); `cwf-manage validate`.

### Step 5: Merge-helper extension (D4 part 2)
- [ ] `partition_manifest`: for `.cwf/scripts/hooks/[^/]+$` paths, **preserve the existing `push @allow, "Bash($path)"` allowlist line unchanged**, and additionally read the first ~15 lines for `# cwf-hook-event:` / `# cwf-hook-matcher:` directives. Guard the read: only `open` a path that is a regular file and not a symlink (`-f && !-l`, mirroring `read_settings` lines 100–113); it has already passed `validate_write_path_allowlist(..., ['.cwf/scripts/'])`.
- [ ] **Validate directive values** before they reach a settings key: `event` must match `^(?:Stop|SubagentStop)$`, `matcher` must match `^[A-Za-z0-9_-]+$`; reject/ignore anything else (default to `Stop` / no matcher). This is defence-in-depth behind hash integrity — never write an unvalidated parsed string into `.claude/settings.json`.
- [ ] Generalise `merge_hooks`: group entries by event; **factor the existing cross-group `%seen` dedupe loop (lines 148–156) into a per-event helper** so the matcher-less Stop path stays byte-identical. For a matched event, find/create the `{matcher => …, hooks => [...]}` group under `hooks.{event}`; a given `command` lives under exactly one group per event (re-run must not duplicate it into a second group).
- [ ] Refresh the merge-helper hash (verify `git log` first); extend `t/cwf-claude-settings-merge.t` (see e-testing-plan); `cwf-manage validate`.

### Step 6: Docs (D4 part 3)
- [ ] `stop-hooks-framework.md`: document the SubagentStop event and, **authoritatively (do not rely on the ephemeral `/tmp` reference)**, the exact settings shape — a `{matcher, hooks}` group under `hooks.SubagentStop` where `matcher` is exact-matched against the subagent's `agent_type` (the agent frontmatter `name`); the fail-open discipline; and the `# cwf-hook-event:` / `# cwf-hook-matcher:` header-directive convention. Note the silent-failure risk: a wrong matcher key means the hook never fires (fails open by accident, masking a broken backstop) — hence the test in Step 5.

### Step 7: Validation
- [ ] **Gate**: `cwf-manage validate` clean; full `prove t/` suite green (the classifier unit tests are the deterministic acceptance evidence).
- [ ] **Corroborating, best-effort only** (not a pass/fail gate — exercises a live LLM): re-run the subagent (new definition) against a sample of bucket-B changesets (Tasks 140/142/143/158) and confirm clean ones classify `no findings` via the helper.
- [ ] **Note**: this task's own changeset will exceed the 500-line cap, so its exec-phase security review (f/g Step 8) takes the skill-authored `error: exceeds cap` path → perform the manual threat-category walkthrough rather than the subagent.

## Code Changes

### Container format (D1) — what the subagent emits
````
<free-form threat-category analysis, any length>

```cwf-review
state: no findings
summary: <optional one line>
```
````
Agent-definition worked example uses `state: <no findings|findings|error>` (non-token) so an echoed example never validates.

### Hook header-directive convention (D4) — read by the merge helper (values validated)
```
# cwf-hook-event: SubagentStop
# cwf-hook-matcher: cwf-security-reviewer-changeset
```
Absent directives default to `Stop` / no matcher — existing hooks need no edit. Parsed values are regex-validated (`event ^(?:Stop|SubagentStop)$`, `matcher ^[A-Za-z0-9_-]+$`) before use.

### `merge_hooks` generalisation (D4) — the one non-trivial edit
Before: every hook entry is appended to `hooks.Stop[0].hooks` (matcher-less group `{hooks=>[...]}`, no `matcher` key).
After: entries carry `{event, matcher}`; merge into `hooks.{event}`, into the `{matcher,hooks}` group for matched events (created if absent), deduped by `command` per event (reusing the existing dedupe loop, factored per-event). The matcher-less Stop group shape is preserved byte-for-byte (no spurious `matcher` key). Resulting shape for the new hook:
```json
"SubagentStop": [
  { "matcher": "cwf-security-reviewer-changeset",
    "hooks": [ { "type": "command", "command": ".cwf/scripts/hooks/subagentstop-security-verdict-guard", "timeout": 5 } ] }
]
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 7 steps executed in order — core (D1–D3, Steps 1–3) before the D4 plumbing (Steps 4–6), then validation (Step 7). The hook reuses the classifier via a shell-free `exec { $prog } $prog` over a self-managed pipe (cleaner than the planned temp-file/open2 options, and POSIX::_exit-safe in the child). `merge_hooks` was generalised with a factored `find_or_make_group` helper; the matcher-less Stop path stays byte-identical (TC-U1/U3 retained). 4 hash touches (agent + merge-helper refreshed, classifier + hook added).

## Lessons Learned
Two operational gotchas surfaced: (1) restore edited hashed scripts to `0700`, not the recorded `0500` minimum, or `install-bash-reinstall.t` TC-5 breaks; (2) `git add -N` the new files before `security-review-changeset` so the review actually covers them.
