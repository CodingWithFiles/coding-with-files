# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Status

The Coding with Files (CWF) system is **implemented and operational** (released under
`v1.1.x` tags; workflow-file format v2.1). Core functionality includes:
- Hierarchical workflow system with 10 lettered phases (a-task-plan through j-retrospective)
- Infinite task nesting via decimal numbering (1, 1.1, 1.1.1, ...)
- Token-efficient context inheritance (~90% reduction via structural maps)
- A suite of helper scripts for deterministic operations (hierarchy resolution, format detection, status aggregation, version parsing, context inheritance, and more)
- Central template pool with task-type-specific symlinks (DRY principle)
- Progressive disclosure pattern (skills reference docs, don't duplicate)

## Development Commands

### CWF System Commands
- **Build**: Not applicable (documentation system)
- **Test**: Manual validation through command execution
- **Lint**: File integrity via `/cwf-security-check`

### Available CWF Skills

**Core Skills**:
- `/cwf-init` - Initialize CWF system
- `/cwf-new-task <num> <type> "description"` - Create hierarchical implementation guide (breaking change from v1.0)
- `/cwf-new-subtask <parent-path> <num> <type> "description"` - Create subtask with context inheritance (breaking change)
- `/cwf-delete-task <task-path> [--force]` - Delete the most-recent task (reverse of `/cwf-new-task`)
- `/cwf-status [task-path]` - Show hierarchical progress
- `/cwf-extract <task-path> <section-name>` - Extract sections (task-based, backward compatible)
- `/cwf-current-task [push|pop|list|clear] [task]` - Manage the current-task stack (LIFO context tracking)

**Workflow Skills**:
- `/cwf-task-plan <task-path>` - Planning phase
- `/cwf-requirements-plan <task-path>` - Requirements phase
- `/cwf-design-plan <task-path>` - Design phase
- `/cwf-implementation-plan <task-path>` - Implementation plan phase
- `/cwf-implementation-exec <task-path>` - Implementation execution phase
- `/cwf-testing-plan <task-path>` - Testing plan phase
- `/cwf-testing-exec <task-path>` - Testing execution phase
- `/cwf-rollout <task-path>` - Rollout phase
- `/cwf-maintenance <task-path>` - Maintenance phase
- `/cwf-retrospective <task-path>` - Retrospective phase

**Utility Skills**:
- `/cwf-security-check [verify|report]` - Verify system integrity
- `/cwf-config [init|list|reset]` - Configure CWF system
- `/cwf-backlog-manager [list|add|modify|retire|delete|normalise|validate]` - Show or manipulate the project backlog
- `.cwf/scripts/cwf-manage` - Manage CWF installation (status, update, rollback, list-releases)

## Conventions

Conventions live in two directories, split by audience:
- **`docs/conventions/`** — conventions for *developing CWF itself* (this repo only):
  commit style, design alignment, and the coding rules for CWF's own source.
- **`.cwf/docs/conventions/`** — conventions shipped to and binding on *all CWF users*
  (this repo included), referenced by the installed skills at runtime.

When adding a convention, place it by who must follow it: a rule only a CWF maintainer
needs goes in `docs/`; a rule any CWF-using project must honour goes in `.cwf/docs/`.

**Commit Messages**: Follow Linux kernel conventions with proper AI attribution. See `docs/conventions/commit-messages.md` for:
- Standard commit message structure (subject, body, trailers)
- AI attribution using `Co-developed-by:` trailer
- Proper use of `Signed-off-by:` (human only, legal certification)
- Examples of AI-assisted commits

**Design Alignment**: Keep CWF skill, helper-script, template, and rule names consistent across the codebase. See `docs/conventions/design-alignment.md` for:
- Single-source-of-truth locations for each artefact type
- Naming patterns (`cwf-` prefix, kebab-case, phase-letter, version-suffix scope, `<name>.d/` subcommand pattern)
- Rename audit checklist
- Deprecation policy (in-repo vs `cwf-manage`)
- Cross-document reference conventions

**Perl Conventions**: Universal rules for every Perl file under `.cwf/`. See `docs/conventions/perl.md` for:
- Shebang: `#!/usr/bin/env perl`
- `PERL5OPT=-CDSLA` for UTF-8 I/O and `@ARGV` decoding
- `use utf8;` source pragma (unconditional)

**Git Path Handling**: NUL-separated path output from `git`. See `docs/conventions/git-path-output.md` for:
- `-z` flag on path-emitting git subcommands
- `split /\0/` parsing of NUL-separated records

**Cross-Doc References**: Standard for how to reference other documents from CWF docs, templates, skills, and wf step files. See `docs/conventions/cross-doc-references.md` for:
- Rules table by locality (intra-file, intra-task, intra-repo, external)
- Rejected alternatives with rationale
- BACKLOG/CHANGELOG carve-out

**Tmp Paths**: Per-task scratch directories nest under one per-project parent in `/tmp/` to avoid collisions across concurrent agents and collapse per-task permission prompts. See `.cwf/docs/conventions/tmp-paths.md` for:
- Canonical form: `/tmp/cwf<dashified-absolute-repo-path>/task-<num>/` (the `cwf` prefix abuts the leading dash)
- Mandatory two-level `mkdir -m 0700` first-use guard (symlink-attack defence) + the helper's parent-symlink reject
- Derivation snippet, worked examples, the optional user-owned allowlist pattern, and the `-tool-check` carve-out

**Hash Updates**: Hash refreshes to `.cwf/security/script-hashes.json` happen in the same task — and same commit — as the underlying file modification. See `.cwf/docs/conventions/hash-updates.md` for:
- Plan-time disclosure rule for hashed-file edits
- Per-file pre-refresh `git log` verification
- Narrow carve-out (4 invariants) for dedicated hash-fix tasks
- What NOT to build: any surface that silences `cwf-manage validate` without surfacing first
- Fix permission drift on sight: clamp via `cwf-manage fix-security` rather than defer (sha256 drift is surfaced, never smoothed)

**Session Hygiene**: When to `/clear`, when to `/compact` and what to preserve, how to keep memory salient across sessions, and how to re-derive workflow state on resume. See `.cwf/docs/conventions/session-hygiene.md` for:
- Triggering conditions for `/clear` and `/compact` (vs auto-compaction)
- Preservation list explicitly including standing security rules from CLAUDE.md `## Critical Rules` and MEMORY.md
- Inline "surface, never smooth" principle covering `/clear`-as-gate-bypass and compaction-induced rule loss
- On session-resume: re-derive current wf step from on-disk task files, not from the resumed conversation

**Worktree Process**: All worktree use with CWF flows through the harness `EnterWorktree`/`ExitWorktree` tools, never raw `git worktree`. See `.cwf/docs/conventions/worktree-process.md` for:
- The guarded 5-step procedure (pre-flight allowlist scan, `ToolSearch` load, create via `EnterWorktree`, absolute-path discipline, operator-surfaced teardown)
- The three hard prohibitions (no raw `git worktree add`, no `remove --force`, no `EnterWorktree(path:)` into a raw-added tree)
- `worktree.baseRef: head` configuration and the user-global fallback
- Threat model: request-is-data, no standing teardown permission, dangerous-allowlist-entry detection, tool-load-failure-is-a-stop

**Shell Hygiene**: Portable, prompt-free shell idioms and the read-only command allowlist CWF seeds at init. See `.cwf/docs/conventions/shell-hygiene.md` for:
- Prompt-free idioms: no heredocs/inline scripts (write to scratch), `chmod +x && ./script` not `perl script`, no `perl -c`/`bash -n`, avoid prompt-tripping command substitution, NUL-separated git paths
- The read-only allowlist seed: admission criterion (read-only for the whole `:*` glob space), the excluded-near-neighbour table, and the seeded corpus
- Opting out via a user/`.local`-layer `ask`/`deny` rule (durable; deleting the committed entry is transient)
- The harness-matching caveat (operators safe; redirection/substitution undocumented, harness-wide)

## Architecture Overview

**Hierarchical Workflow System**: Ten lettered workflow phases (a–j) guide tasks from planning through retrospective. Non-linear state machine with dynamic transitions based on step outcomes. Universal decomposition signals (5 criteria) guide task breakdown into subtasks.

**Token-Efficient Context Inheritance**: Parent context via structural maps (~50-100 tokens per parent) instead of full file reads (~500-1000 tokens). LLM receives headers, line ranges, and Read tool parameters, then decides what to read in detail. Status markers indicate parent context reliability.

**Central Template Pool with Symlinks**: Single source of truth in `.cwf/templates/pool/` with task-type-specific symlinks. Feature tasks get 10 files (a–j), bugfixes get 7 (a,c,d,e,f,g,j), hotfixes get 7 (a,d,e,f,g,h,j), chores get 6 (a,d,e,f,g,j), discovery gets 8 (a,b,c,d,e,f,g,j). DRY principle eliminates duplication.

**Script-Based Helper System**: A suite of helper scripts encapsulates deterministic operations - hierarchy resolution, format detection, status aggregation, version parsing, context inheritance, and more (Perl-based). LLM focuses on intelligence, scripts handle file system traversal.

**Progressive Disclosure Pattern**: Skills reference documentation (`.cwf/docs/workflow/`) rather than duplicating content. Helper scripts provide structural information, LLM decides what matters. Reduces token consumption while preserving agency.

**Security Model**: recorded per-file `permissions` are an **upper bound** — `cwf-manage validate` flags a file only when it is *more* permissive than recorded and `fix-security` clamps it back down (`actual & recorded`), never raising a bit; recorded modes range from `0700`/`0500` (executables) to `0444` (read-only data). SHA256 content verification via `.cwf/security/script-hashes.json`; git-based version tracking.

## System Integration

- **Helper Scripts**: `.cwf/scripts/command-helpers/` with self-documenting names
- **Configuration**: Hierarchical config system with `cwf-project.json`
- **Version Tracking**: Git-based versioning (`git describe` format `<tag>-<commits-since>-g<short-sha>`, e.g. `v1.1.x-<n>-g<sha>`)
- **Task Management**: Support for GitHub/GitLab/JIRA with internal fallback
- **Task Stack**: `.cwf/task-stack` file stores current task context (managed via `/cwf-current-task`)

## File Protection (Advisory)

The following files should not be directly edited with Edit or Write tools. Use the designated skills instead:

### `.cwf/task-stack`
- **Purpose**: Tracks current task context as a LIFO stack
- **Format**: Newline-delimited task dirnames (e.g., `34-feature-add-task-stack-script`)
- **Use instead**: `/cwf-current-task` skill for all operations (push, pop, list, clear)
- **Rationale**: Stack operations require atomic file locking (flock) to prevent corruption
- **Advisory**: If you need to manipulate the stack, use the skill - direct edits may corrupt the file format

## Versioning

CWF uses `v{major}.{minor}.{task_num}` semver tags on the main branch.

- **major**: breaking changes — wf file format changes, removal of installed features,
  install script incompatibilities
- **minor**: new user-visible features (new skills, new workflow phases, new helper scripts)
- **patch = task_num**: CWF task number of the most recently completed task at time of
  tagging; never set manually

**Tagging, pushing tags, and creating GitHub releases are human-only actions.** Models
must not `git tag`, `git push --tags`, create releases, or suggest merging to main.

**This convention is internal to CWF development.** Do not reference this section from
any installed file (`.cwf/docs/`, `.cwf/templates/`, `.cwf/scripts/`, or skills).