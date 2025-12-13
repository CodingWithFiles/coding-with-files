# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Status

The Code Implementation Guide (CIG) system v2.0 is **implemented and operational**. Core functionality includes:
- Hierarchical workflow system with 8 structured steps (a-plan through h-retrospective)
- Infinite task nesting via decimal numbering (1, 1.1, 1.1.1, ...)
- Token-efficient context inheritance (~90% reduction via structural maps)
- 5 helper scripts for deterministic operations (hierarchy resolution, format detection, status aggregation, version parsing, context inheritance)
- Central template pool with task-type-specific symlinks (DRY principle)
- Progressive disclosure pattern (commands reference docs, don't duplicate)

## Development Commands

### CIG System Commands
- **Build**: Not applicable (documentation system)
- **Test**: Manual validation through command execution
- **Lint**: File integrity via `/cig-security-check`

### Available CIG Commands

**Core Commands (v2.0)**:
- `/cig-init` - Initialize CIG system
- `/cig-new-task <num> <type> "description"` - Create hierarchical implementation guide (breaking change from v1.0)
- `/cig-subtask <parent-path> <num> <type> "description"` - Create subtask with context inheritance (breaking change)
- `/cig-status [task-path]` - Show hierarchical progress
- `/cig-extract <task-path> <section-name>` - Extract sections (task-based, backward compatible)

**Workflow Commands (v2.0 - New)**:
- `/cig-plan <task-path>` - Planning phase
- `/cig-requirements <task-path>` - Requirements phase
- `/cig-design <task-path>` - Design phase
- `/cig-implementation <task-path>` - Implementation phase
- `/cig-testing <task-path>` - Testing phase
- `/cig-rollout <task-path>` - Rollout phase
- `/cig-maintenance <task-path>` - Maintenance phase
- `/cig-retrospective <task-path>` - Retrospective phase

**Utility Commands**:
- `/cig-security-check [verify|report]` - Verify system integrity
- `/cig-config [init|list|reset]` - Configure CIG system

## Architecture Overview

**Hierarchical Workflow System (v2.0)**: Eight lettered workflow steps (a-h) guide tasks from planning through retrospective. Non-linear state machine with dynamic transitions based on step outcomes. Universal decomposition signals (5 criteria) guide task breakdown into subtasks.

**Token-Efficient Context Inheritance**: Parent context via structural maps (~50-100 tokens per parent) instead of full file reads (~500-1000 tokens). LLM receives headers, line ranges, and Read tool parameters, then decides what to read in detail. Status markers indicate parent context reliability.

**Central Template Pool with Symlinks**: Single source of truth in `.cig/templates/pool/` with task-type-specific symlinks. Feature tasks get 8 files (a-h), bugfixes get 5 (a,c,d,e,h), hotfixes get 5 (a,d,e,f,h), chores get 4 (a,d,e,h). DRY principle eliminates duplication.

**Script-Based Helper System**: Five helper scripts encapsulate deterministic operations - hierarchy resolution, format detection, status aggregation, version parsing, context inheritance (Perl-based). LLM focuses on intelligence, scripts handle file system traversal.

**Progressive Disclosure Pattern**: Commands reference documentation (`.cig/docs/workflow/`) rather than duplicating content. Helper scripts provide structural information, LLM decides what matters. Reduces token consumption while preserving agency.

**Security Model**: u+rx (minimum 0500) permissions, SHA256 verification via `.cig/security/script-hashes.json`, git-based version tracking.

## System Integration

- **Helper Scripts**: `.cig/scripts/command-helpers/` with self-documenting names
- **Configuration**: Hierarchical config system with `cig-project.json`
- **Version Tracking**: Git-based versioning (`v0.1.1-5-gcea1c19` format)
- **Task Management**: Support for GitHub/GitLab/JIRA with internal fallback