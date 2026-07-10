# Stop Hooks Framework for CWF

A framework for evaluating whether a Stop event hook improves CWF quality enough to justify its context cost. CWF also ships one **SubagentStop** hook (event-scoped, matcher-based); its mechanics and registration differ from Stop and are documented in § "SubagentStop hooks" below.

## Stop Hook Mechanics

**Trigger**: Stop hooks fire every time the agent stops — task completion, `/clear`, resume, compact, and natural conversation pauses. They are not scoped to "task finished."

**Input**: JSON on stdin with `session_id`. No tool name or tool input (Stop has no matcher).

**Output**: JSON with optional `systemMessage` (shown to user), `decision: "block"` (prevent stop), or `hookSpecificOutput.additionalContext` (injected into model context on next turn).

**Context cost**: Hook stdout becomes a system reminder on the next turn. Every token in the output is paid on every subsequent turn until compaction. A 50-token reminder costs ~50 tokens/turn * N turns. A verbose hook that emits 500 tokens on every stop is expensive.

**Existing checks**: `cwf-manage validate` (structural integrity — hashes, permissions, config schema), `cwf-status` (progress tracking), UserPromptSubmit rules injection hook (re-injects critical rules per turn). A Stop hook must not duplicate these.

## Taxonomy

### 1. Consistency — Status fields match actual state

**Definition**: The agent updated content but left status fields stale (e.g., wrote implementation but status still says "Backlog").

**Signal**: Compare wf file content (non-empty sections beyond template) against its `**Status**:` field.

**CWF example**: Tasks 47, 48, 46, 49 all had stale "In Progress" or "Backlog" statuses on completed phases. Task 65 fixed two, Task 67 fixed two more. Task 102 had d- and e-phases left at "Backlog" after modification. This is the most frequently recurring error in CWF history — at least 6 occurrences across 4 separate cleanup tasks.

### 2. Completeness — Agent finished what it started

**Definition**: The agent stopped mid-workflow without completing the current phase or without committing staged work.

**Signal**: Check for uncommitted changes to wf files, or wf files with "In Progress" status at stop time.

**CWF example**: Task 98 jumped from testing-exec (g) to creating Task 99 without completing rollout (h), maintenance (i), or retrospective (j). Task 84 skipped workflow skills entirely, backfilling retrospectively. Both required correction.

### 3. Structural correctness — Output conforms to schema

**Definition**: The agent wrote content that violates CWF conventions (invalid status values, missing required sections, malformed commit messages).

**Signal**: Run `cwf-manage validate` and check exit code.

**CWF example**: Task 84 used "Implemented" as a status value — not in the allowed set. Caught by `cwf-manage validate` but only during retrospective, not at write time. However, this category is **already covered** by the existing validate tool. A Stop hook here would duplicate `cwf-manage validate`.

### 4. Waste detection — Unnecessary or circular work

**Definition**: The agent modified files then reverted them, made circular edits, or performed work outside the task scope.

**Signal**: Compare `git diff` at stop time against expected task scope; flag empty diffs after edits.

**CWF example**: No clear observed occurrences in CWF history. Planning over-engineering (Tasks 101, 102 needed `/simplify` to cut scope) is a planning issue, not a stop-time issue. **Insufficient evidence to justify a hook.**

## Evaluation Checklist

For any candidate Stop hook, answer these questions:

1. **What error does this catch?** (cite at least one observed occurrence)
2. **How often has this error occurred?** (count from retrospectives/memory)
3. **What does the hook cost?** (estimate tokens per stop event)
4. **What's the alternative?** (manual review, existing tool, process change)
5. **Does this duplicate an existing check?** (validate, cwf-status, rules injection)
6. **Verdict**: build / defer / skip

A hook earns "build" when: frequency >= 3 occurrences, no existing tool covers it, and estimated cost < 100 tokens per stop.

## Candidate Evaluation

### Candidate A: Stale Status Detector

1. **Error**: Wf files modified but status field still at "Backlog" or "In Progress"
2. **Frequency**: 6+ occurrences (Tasks 46-49 via Tasks 65/67, Task 102 d/e phases, Task 84). Most recurring error in CWF.
3. **Cost**: ~40-60 tokens. Hook runs `git diff --name-only` filtered to `implementation-guide/`, reads status field of changed wf files, emits one-line warning per stale file.
4. **Alternative**: Pre-retrospective status sweep (MEMORY.md instruction). Works but relies on agent remembering — and the whole point is that agents skip optional work.
5. **Duplicates**: No. `cwf-manage validate` checks structural schema, not semantic consistency between content and status.
6. **Verdict**: **Build**. High frequency, low cost, no existing coverage.

### Candidate B: Uncommitted Changes Warning

1. **Error**: Agent stops with staged or unstaged changes to wf files that weren't committed
2. **Frequency**: ~2-3 occurrences (Task 81 missed c-design-plan.md staging; Task 85 retrospective didn't stage all files). Moderate but not the highest frequency error.
3. **Cost**: ~20-30 tokens. Hook runs `git status --porcelain` filtered to `implementation-guide/`, emits warning if dirty wf files found.
4. **Alternative**: "Always `git status` before committing" (MEMORY.md instruction). Same problem — agents skip optional work.
5. **Duplicates**: No existing tool checks for uncommitted wf file changes at stop time.
6. **Verdict**: **Build**. Moderate frequency, very low cost, complements Candidate A.

### Candidate C: Validate-on-Stop

1. **Error**: Structural violations (bad status values, wrong permissions, hash mismatches) not caught until retrospective
2. **Frequency**: ~2 occurrences (Task 84 "Implemented" status, Task 101 permissions mismatch)
3. **Cost**: ~100-200 tokens if validate finds issues; ~20 tokens if clean. But `cwf-manage validate` already takes 1-2 seconds to run.
4. **Alternative**: `cwf-manage validate` is already baked into checkpoint commits (Task 102). Runs after every phase commit.
5. **Duplicates**: **Yes** — directly duplicates checkpoint commit's built-in validate call.
6. **Verdict**: **Skip**. Already covered by checkpoint commit workflow.

## Recommendations

**Build first**: Candidate A (Stale Status Detector). Highest frequency, clearest signal, low cost. Implementation: a shell script that reads `git diff --name-only`, filters for `*/[a-j]-*.md`, extracts `**Status**:` from each, warns if content differs from template but status is still "Backlog".

**Build second**: Candidate B (Uncommitted Changes Warning). Trivially cheap, complements A, and catches a different failure mode.

**Skip**: Candidate C. Already covered by checkpoint commits.

**Future consideration**: If `/simplify` reviews keep catching over-engineered plans, a planning-phase-specific PostToolUse hook might be worth exploring — but that's a PostToolUse pattern, not a Stop hook, and needs its own evaluation.

## SubagentStop hooks

A **SubagentStop** hook fires when a subagent (an `Agent` tool call) finishes,
distinct from the conversation-level Stop event. Unlike Stop, SubagentStop
supports a **matcher** that scopes the hook to a single subagent by its
`agent_type` — the `name` field from the agent definition's frontmatter
(`.claude/agents/<name>.md`). The hook's stdin JSON carries
`last_assistant_message` (the subagent's final message) and `stop_hook_active`
(true when the stop was itself produced by a prior block decision — the
harness's loop guard, capped at a small number of consecutive blocks).

CWF ships one such hook:
`.cwf/scripts/hooks/subagentstop-security-verdict-guard`, scoped to
`cwf-security-reviewer-changeset`. It is the backstop for the exec-phase
security review (Task 162): if the subagent's response carries no valid
`cwf-review` verdict block, the hook returns `{"decision":"block","reason":…}`
to force a re-emit. It reuses the deterministic
`security-review-classify` helper rather than reimplementing block detection,
so there is one parse authority.

### Fail-open discipline (security-critical)

A SubagentStop guard must never trap the subagent. The whole body runs in
`eval`; it **blocks only** when the classifier ran cleanly AND returned exactly
`error` AND `stop_hook_active` is false. In every other case — a valid verdict,
an already-looping stop, an unreachable or failing classifier, malformed stdin
JSON, or any exception — it **allows the stop** (empty stdout, exit 0). It never
blocks on its own failure, and the `reason` it emits is a fixed literal built
via `JSON::PP->encode`, so no `last_assistant_message`-derived data is ever
interpolated into harness-visible output. The hook always exits 0; a non-zero
exit would surface as an error to the user.

### Registration: header directives + settings shape

`cwf-claude-settings-merge` discovers hooks by walking the integrity manifest
(`.cwf/security/script-hashes.json`) for paths under `.cwf/scripts/hooks/`. A
hook defaults to the **Stop** event with **no matcher**. To register under a
different event or with a matcher, a hook declares directives in its first 15
header-comment lines:

```
# cwf-hook-event: SubagentStop
# cwf-hook-matcher: cwf-security-reviewer-changeset
```

The merge helper validates both values before they reach a settings key —
`event` must be exactly `Stop` or `SubagentStop`; `matcher` must match
`^[A-Za-z0-9_-]+$`. An invalid or absent directive falls back to the
Stop / no-matcher default, so an unvalidated parsed string is never written
into `.claude/settings.json`. The directive read refuses symlinks and
non-regular files (`-f && !-l`).

The resulting `.claude/settings.json` shape is a `{matcher, hooks}` group under
`hooks.SubagentStop`:

```json
"SubagentStop": [
  {
    "matcher": "cwf-security-reviewer-changeset",
    "hooks": [
      { "type": "command",
        "command": "${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/subagentstop-security-verdict-guard",
        "timeout": 5 }
    ]
  }
]
```

Matcher-less Stop hooks keep their existing shape — a `{hooks: […]}` group under
`hooks.Stop` with no `matcher` key — registered byte-for-byte as before.

### Silent-failure risk

The matcher is exact-matched against the subagent's `agent_type`. A wrong
matcher value means the hook **never fires** — and because the hook fails open,
a never-firing hook is indistinguishable from an allow at runtime, silently
disabling the backstop. This is why the merge helper's matcher registration is
covered by a regression test (`t/cwf-claude-settings-merge.t`): the failure
mode is invisible in normal operation, so it must be caught at the
registration boundary. If the agent is ever renamed, the matcher directive in
the hook header must be updated in the same change (see
`docs/conventions/design-alignment.md`).
