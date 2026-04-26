# Build uncommitted changes warning Stop hook - Design
**Task**: 113 (feature)

## Task Reference
- **Task ID**: internal-113
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/113-build-uncommitted-changes-warning-stop-hook
- **Template Version**: 2.1

## Goal
Define the script structure, detection logic, and hook integration for the uncommitted-changes warning hook, mirroring Task 104's conventions.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### Script Location and Language
- **Decision**: Perl script at `.cwf/scripts/hooks/stop-uncommitted-changes-warning`
- **Rationale**: Match Task 104's actual implementation (`stop-stale-status-detector` is Perl with `use strict; use warnings; eval`). Perl gives reliable exit-0 discipline via `eval { ... }; exit 0` and clean string handling for porcelain parsing. Same conventions = easier maintenance.
- **Trade-off**: Could be Bash, but Perl's `eval` is a cleaner exit-0 guarantee than ad-hoc `set -u` + careful return-code handling. Consistency with Task 104 wins.

### Detection Strategy
- **Decision**: `git status --porcelain -z --untracked-files=all -- 'implementation-guide/*/[a-j]-*.md' 2>/dev/null`
- **Rationale**:
  - `--porcelain` (v1) gives stable machine-readable output: 2-char status code + space + path
  - `-z` is git's documented mechanism for verbatim path output: records are NUL-terminated and paths are emitted *exactly* as stored, with no double-quote wrapping or backslash/octal escaping for any character (newlines, quotes, backslashes, control chars, non-ASCII bytes — all verbatim). Strictly more robust than `-c core.quotepath=false` (which only suppresses escaping for bytes >0x80; quotes/backslashes/control chars stay escaped even with `core.quotepath=false`).
  - `--untracked-files=all` expands untracked directories to individual files — without this, a brand-new task directory would appear as a single dir entry and the pathspec glob wouldn't match its `*-plan.md` contents
  - Pathspec filtering inside git is faster and avoids a separate grep stage
  - Single command captures all four porcelain classes at once: staged, unstaged, untracked, conflict
- **Why not `git diff HEAD --name-only`** (Task 104's approach): `git diff HEAD` only catches staged + unstaged, not untracked. We explicitly need untracked (FR1).

### Path Parsing
- **Decision**: Split the git output on NUL (`split /\0/, $output`). For each non-empty record, take `substr($record, 3)` (skip 2-char status code + 1 space) as the path. Then take basename via the Task 104 idiom `m{([^/]+)$} ? $1 : $_`.
- **Rationale**: With `-z`, records are NUL-separated and paths are bare bytes, so the parser is `split /\0/` then `substr` — no quoting, no escapes, no edge cases with spaces or non-ASCII. Renames (`R`/`C`) emit two NUL-separated path fields per record; with our pathspec filter the only file we'd care about is the new one, but in practice `git status --porcelain` reports renames as separate `D`/`A` entries unless `--find-renames` is enabled (it isn't here), so we won't see `R` records. Defensive note: if such a record ever appears, `substr($record, 3)` yields the new path — correct enough.

### Output Format
- **Decision**: JSON `{"systemMessage":"⚠ Uncommitted: <file1>, <file2>, <file3> +N more"}` when uncommitted wf files found. Cap at 3 files; basename only (strip directory). No output (no JSON, no stdout) when clean.
- **Rationale**:
  - Leading "⚠ Uncommitted:" (Unicode `⚠` warning sign in the source, matching Task 104's `qq()` style) satisfies AC2 — distinguishable from Task 104's "⚠ Stale status:" output.
  - Cap bounds worst-case to ~25 tokens (matches NFR1 budget of 20-30).
  - Zero output when clean = zero token cost on the common case (NFR1, FR4). Matches Task 104's pattern.
  - Basenames only because the parent task directory carries the task identity already and full paths would inflate the budget without helping the user.

### Error Handling
- **Decision**: Wrap entire body in `eval { ... }; exit 0;`. No `die` propagation. Use `2>/dev/null` on the git invocation to suppress errors when not in a repo or git is missing.
- **Rationale**: NFR2 / AC4 require exit 0 on every code path including missing git, non-repo cwd, and conflict states. `eval` catches Perl-side exceptions; `2>/dev/null` swallows git stderr. If `git status` produces no output (any reason), the script naturally emits nothing.

### Hook Registration
- **Decision**: Append a new command object to the existing `hooks.Stop[0].hooks` array in `.claude/settings.local.json`. Do **not** add the script to `.cwf/security/script-hashes.json` — Task 104's `stop-stale-status-detector` is intentionally absent from the hash registry, and we follow that precedent. Hook scripts are loaded by Claude Code at user request via local settings, distinct from the CWF helper-script trust boundary.
  ```json
  {
    "type": "command",
    "command": ".cwf/scripts/hooks/stop-uncommitted-changes-warning",
    "timeout": 5
  }
  ```
- **Rationale**: AC5 is explicit. Settings.local.json is project-local and git-ignored (Task 104 convention). Keeping both hooks in a single `hooks` array means they fire on the same Stop event without separate matcher entries.

### Coordination with Task 104 Hook
- **Decision**: Independent. No shared library calls. A wf file that is both uncommitted AND has a stale Backlog status will surface in *both* warnings — by design (FR5).
- **Rationale**: The two failure modes are genuinely distinct ("you forgot to commit" vs "you forgot to update status"). Sharing state would couple the hooks unnecessarily; the duplication cost is at most ~50 tokens in the rare overlap case.

## System Design

### Component Overview
- **Hook script** (`.cwf/scripts/hooks/stop-uncommitted-changes-warning`): Reads git porcelain output, emits JSON warning if dirty.
- **Hook registration** (`.claude/settings.local.json`): Tells Claude Code to invoke the script on every Stop event.

### Data Flow
1. Stop event → Claude Code invokes both registered Stop hooks (Task 104 + Task 113) in array order
2. Task 113 hook runs `git status --porcelain -z --untracked-files=all -- 'implementation-guide/*/[a-j]-*.md' 2>/dev/null`
3. If empty output → exit 0, no stdout
4. Else → parse each line, extract path (post-`->` for renames), take basename
5. Format JSON systemMessage capped at 3 displayed names, append `+N more` if >3
6. Print JSON to stdout, exit 0

### Output Examples

Clean (most common):
```
(no output, exit 0)
```

Single dirty file:
```json
{"systemMessage":"⚠ Uncommitted: c-design-plan.md"}
```

Many dirty files:
```json
{"systemMessage":"⚠ Uncommitted: a-task-plan.md, b-requirements-plan.md, c-design-plan.md +2 more"}
```

## Interface Design

### Hook contract (Claude Code Stop event)
- **Stdin**: JSON with `session_id` (ignored)
- **Stdout**: Either empty, or one line of JSON with `systemMessage`
- **Exit code**: 0 always (NFR2)
- **Stderr**: Suppressed via `2>/dev/null` on git call

### No public API
This is a leaf script with no callers in the codebase. Not invoked from other helpers, not referenced by skills.

## Constraints
- Stop hooks fire on every stop including `/clear`, resume, compact (per stop-hooks-framework.md)
- Token cost is paid every subsequent turn until compaction — keeps NFR1 budget tight
- Must not duplicate `cwf-manage validate` (structural), `cwf-status` (progress), or Task 104 hook (different failure mode)
- Script runs from git root (Claude Code invokes hooks at project root)

## Decomposition Check
- [x] **Time**: No — 1 session
- [x] **People**: No — single developer
- [x] **Complexity**: No — 2 concerns (script + registration), well below threshold
- [x] **Risk**: No — trivially reversible (delete script, remove array entry)
- [x] **Independence**: No — script and registration are coupled

**Result**: 0/5 signals triggered. No decomposition needed.

## Validation
- [ ] Design review completed (plan-review subagents)
- [ ] Detection strategy verified against all four porcelain classes
- [ ] Output format budget verified within NFR1

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 113
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
