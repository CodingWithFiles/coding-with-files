# Add PreToolUse hook for rule re-injection - Design
**Task**: 99 (feature)

## Task Reference
- **Task ID**: internal-99
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/99-add-pretooluse-hook-for-rule-re-injection
- **Template Version**: 2.1

## Goal
Design the hook configuration, rules file format, and settings.json merge strategy.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### Rules File Location and Format
- **Decision**: `.cwf/rules-inject.txt` — plain text, one rule per line, no markup
- **Rationale**: Lives inside `.cwf/` so it's included in the existing subtree split automatically (FR5 — no additional install.bash changes). Plain text because `cat` outputs it verbatim as a system reminder. No markdown/YAML overhead.
- **Trade-offs**: Plain text has no structure for categorisation or metadata. Acceptable because the file is tiny (under 10 lines) and serves a single purpose.

### Rules Content Design
- **Decision**: 4 imperative rules, each one line, no explanation
- **Rationale**: Token cost is per-line per-turn. Explanations waste tokens. The agent either follows the rule or doesn't — prose won't change that.
- **Draft content**:
  ```
  CWF RULES (re-injected every turn):
  1. Use /cwf-{step} skills for wf step files — do not edit directly.
  2. Checkpoint commit after each wf phase — write → stage → commit → proceed.
  3. Never execute merge to main — suggest the command, do not run it.
  4. Run git status before every commit — check for untracked files.
  ```
- **Line count**: 5 lines (header + 4 rules) — well under the 10-line NFR1 limit

### Hook Configuration Design
- **Decision**: PreToolUse hook on `UserPromptSubmit` matcher with `cat .cwf/rules-inject.txt`
- **JSON structure**:
  ```json
  {
    "hooks": {
      "PreToolUse": [
        {
          "matcher": "UserPromptSubmit",
          "hooks": [
            {
              "type": "command",
              "command": "cat .cwf/rules-inject.txt 2>/dev/null || true"
            }
          ]
        }
      ]
    }
  }
  ```
- **Rationale**: `UserPromptSubmit` fires once per user message (not per tool call — avoids multiplied token cost). `2>/dev/null || true` ensures missing file doesn't produce errors or block anything.
- **Trade-offs**: Fires on every user message including simple ones ("yes", "ok"). Acceptable — the cost is 5 lines of tokens, negligible compared to model output.

### Settings.json Merge Strategy
- **Decision**: `/cwf-init` reads existing `.claude/settings.json`, adds `hooks` key alongside existing `permissions` key, writes back
- **Rationale**: Same pattern already used for skill permissions in cwf-init step 6. The `hooks` key is a sibling of `permissions`, not nested inside it — clean merge.
- **Edge case**: If `hooks.PreToolUse` already exists (user has their own hooks), append to the array rather than overwrite. Check for existing `UserPromptSubmit` matcher to avoid duplicates.

## Data Flow
1. User sends a message → Claude Code fires `PreToolUse` on `UserPromptSubmit`
2. Hook runs `cat .cwf/rules-inject.txt` → outputs rules text to stdout
3. Claude Code injects stdout as a system reminder into the agent's context
4. Agent sees the rules at the top of its context on every turn — even after compaction

## Constraints
- Hook output is injected as a system reminder — consumes tokens but is not visible to the user
- `cat` must be available (universal on Linux/macOS — safe assumption)
- `.cwf/rules-inject.txt` path is relative to git root (Claude Code CWD)
- Must not break existing settings.json content (permissions, env vars)

## Decomposition Check
0/5 signals triggered — no decomposition needed.

## Validation
- [x] Hook mechanism verified against Claude Code best practices documentation
- [x] JSON structure follows documented hooks format
- [x] Merge strategy avoids conflicts with existing settings

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 99
**Blockers**: None

## Actual Results
Design implemented as specified. UserPromptSubmit matcher confirmed correct. Silent failure pattern works as designed.

## Lessons Learned
- Plain text rules file with `cat` is the simplest possible design — no parsing, no escaping, no dependencies
