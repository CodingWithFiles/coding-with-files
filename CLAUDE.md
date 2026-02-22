# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Status

The Coding with Files (CWF) system v2.0 is **implemented and operational**. Core functionality includes:
- Hierarchical workflow system with 8 structured steps (a-plan through h-retrospective)
- Infinite task nesting via decimal numbering (1, 1.1, 1.1.1, ...)
- Token-efficient context inheritance (~90% reduction via structural maps)
- 5 helper scripts for deterministic operations (hierarchy resolution, format detection, status aggregation, version parsing, context inheritance)
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
- `/cwf-subtask <parent-path> <num> <type> "description"` - Create subtask with context inheritance (breaking change)
- `/cwf-status [task-path]` - Show hierarchical progress
- `/cwf-extract <task-path> <section-name>` - Extract sections (task-based, backward compatible)

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
- `.cwf/scripts/cwf-manage` - Manage CWF installation (status, update, rollback, list-releases)

## Conventions

**Commit Messages**: Follow Linux kernel conventions with proper AI attribution. See `docs/conventions/commit-messages.md` for:
- Standard commit message structure (subject, body, trailers)
- AI attribution using `Co-developed-by:` trailer
- Proper use of `Signed-off-by:` (human only, legal certification)
- Examples of AI-assisted commits

## Architecture Overview

**Hierarchical Workflow System (v2.0)**: Eight lettered workflow steps (a-h) guide tasks from planning through retrospective. Non-linear state machine with dynamic transitions based on step outcomes. Universal decomposition signals (5 criteria) guide task breakdown into subtasks.

**Token-Efficient Context Inheritance**: Parent context via structural maps (~50-100 tokens per parent) instead of full file reads (~500-1000 tokens). LLM receives headers, line ranges, and Read tool parameters, then decides what to read in detail. Status markers indicate parent context reliability.

**Central Template Pool with Symlinks**: Single source of truth in `.cwf/templates/pool/` with task-type-specific symlinks. Feature tasks get 8 files (a-h), bugfixes get 5 (a,c,d,e,h), hotfixes get 5 (a,d,e,f,h), chores get 4 (a,d,e,h). DRY principle eliminates duplication.

**Script-Based Helper System**: Five helper scripts encapsulate deterministic operations - hierarchy resolution, format detection, status aggregation, version parsing, context inheritance (Perl-based). LLM focuses on intelligence, scripts handle file system traversal.

**Progressive Disclosure Pattern**: Skills reference documentation (`.cwf/docs/workflow/`) rather than duplicating content. Helper scripts provide structural information, LLM decides what matters. Reduces token consumption while preserving agency.

**Security Model**: u+rx (minimum 0500) permissions, SHA256 verification via `.cwf/security/script-hashes.json`, git-based version tracking.

## System Integration

- **Helper Scripts**: `.cwf/scripts/command-helpers/` with self-documenting names
- **Configuration**: Hierarchical config system with `cwf-project.json`
- **Version Tracking**: Git-based versioning (`v0.1.1-5-gcea1c19` format)
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