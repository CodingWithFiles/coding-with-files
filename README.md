# Coding with Files (CWF)

A structured system for managing software development tasks through Claude Code skills.

CWF is pronounced "swiff".

## Overview

Coding with Files (CWF) provides a standardised approach to planning, implementing, and tracking software development tasks. Currently targeted for Claude Code integration through skills, it offers automated task creation, progress tracking, and documentation generation.

While this system is designed specifically for Claude Code, the methodology isn't strictly tied to any particular tool. Pull requests to support other development environments are welcome.

## The Problem With AI-Assisted Coding

AI coding agents are powerful in short bursts but lose the thread fast. Across multiple
sessions on a real project, you spend more time re-explaining context than actually
building — what decisions were made, why, and where things stand. Context windows fill,
sessions reset, and the agent starts contradicting earlier work. For solo developers
shipping serious software, this is a constant tax.

## What CWF Does

Coding with Files externalizes that context into structured markdown files that live in
your repo. Each task gets an implementation guide — phase-by-phase documents the agent
reads, picks up, and continues without being re-briefed. A feature like "add OAuth login"
becomes a directory with separate files for planning, design, implementation, and testing.
The agent always knows where it is, even after a restart.

## Why the Structure Matters

CWF enforces typed workflow phases — plan, design, implement, test, ship — and matches
them to the task type. A hotfix skips the design phase; a new feature doesn't. This
prevents the classic AI failure mode of jumping straight to code before the problem is
understood. It also uses token-efficient context inheritance, so subtasks get just enough
parent context to stay aligned without being overwhelmed — reducing context overhead by up
to 80% in some steps of task execution.

CWF gives the solo developer + AI agent pairing the discipline that software teams enforce
through standups, code review, and project management. It turns your AI coding agent from
a smart but forgetful assistant into a structured, accountable engineering partner.

On [Dan Shapiro's Five Levels of AI Software Development](https://www.danshapiro.com/blog/2026/01/the-five-levels-from-spicy-autocomplete-to-the-software-factory/),
CWF is designed to operate at **Level 3** (Developer as Manager) — you direct the agent
through structured phases and review its work rather than writing code yourself, with the
system targeting Level 3–3.3 of that scale.

## Project Status

**⚠️ Beta Development**: This is a new project under active development. While being used for actual development work, it should be considered a beta process. Use with appropriate caution.

**Development Status**: Core functionality is implemented and operational, but the system is still evolving based on real-world usage and feedback.

### Contributing

We welcome issues, pull requests, and suggestions! This project aims to become a community-driven tool.

**Copyright Assignment Preference**: Contributors are strongly encouraged to assign copyright to enable potential future cooperative or community benefit corporation structure where contributors could share in any revenue (though no firm plans exist yet).

**Current Priority**: Establishing robust, secure foundations before expanding features.

## Features

### Hierarchical Workflow System
- **Infinite Task Nesting**: Decimal numbering (1, 1.1, 1.1.1) with unlimited depth
- **10-Phase Workflow**: Planning and execution phases separated for each stage (plan → exec)
- **Token-Efficient Context Inheritance**: Parent context via structural maps (~50-100 tokens vs 500-1000)
- **Progressive Disclosure**: Skills reference documentation rather than duplicating content
- **Central Template Pool**: DRY principle with symlink-based templates per task type
- **Universal Decomposition Signals**: 5 signals guide when to break tasks into subtasks
- **Dynamic Workflow Transitions**: Non-linear state machine based on step outcomes
- **Helper Script Automation**: 5 scripts encapsulate deterministic operations

### Core Capabilities
- **Task Management**: Structured approach to feature, bugfix, hotfix, and chore tasks
- **Hierarchical Organisation**: Multi-level task breakdown with automatic numbering
- **Template System**: Consistent documentation templates for all task types (8 workflow steps)
- **Progress Tracking**: Real-time status monitoring with progress calculation
- **Section Extraction**: Task-based and file-based extraction with backward compatibility
- **Retrospective Analysis**: Post-completion variance tracking and lessons learned
- **Security Verification**: SHA256 hash verification for all helper scripts

## Installation

CWF can be installed via git subtree (for upstream sync) or file copy (for static/manual upgrades). Both methods are fully supported.

**Prerequisites**: Git 1.7+, Perl 5.20+, Bash 4+, Claude Code.

### Quick Install

**GitHub**:

```bash
curl -fsSL https://raw.githubusercontent.com/CodingWithFiles/coding-with-files/main/scripts/install.bash | bash
```

**GitLab, Gitea, Forgejo, self-hosted**:

```bash
git archive --remote=<cwf-repo-url> HEAD scripts/install.bash | tar -xO | bash
```

See **[INSTALL.md](INSTALL.md)** for complete instructions, post-install setup, and troubleshooting.

## Commands

### Core Commands

- `/cwf-init` - Initialise CWF system with project configuration
- `/cwf-new-task <num> <type> "description"` - Create hierarchical implementation guide
- `/cwf-new-subtask <parent-path> <num> <type> "description"` - Create subtask with context inheritance
- `/cwf-status [task-path]` - Show progress across implementation guide hierarchy
- `/cwf-extract <task-path> <section-name>` - Extract section from implementation guide

### Workflow Commands

Execute structured workflow phases for any task. Phases are split into planning and
execution steps — plan first, then execute separately:

- `/cwf-task-plan <task-path>` - Planning phase (goals, milestones, risks)
- `/cwf-requirements-plan <task-path>` - Requirements phase (FR/NFR, acceptance criteria)
- `/cwf-design-plan <task-path>` - Design phase (architecture, components, interfaces)
- `/cwf-implementation-plan <task-path>` - Implementation plan (files to change, steps)
- `/cwf-implementation-exec <task-path>` - Implementation execution (write the code)
- `/cwf-testing-plan <task-path>` - Testing plan (test strategy, test cases)
- `/cwf-testing-exec <task-path>` - Testing execution (run tests, record results)
- `/cwf-rollout <task-path>` - Rollout phase (deployment, monitoring, rollback plan)
- `/cwf-maintenance <task-path>` - Maintenance phase (support, optimisation)
- `/cwf-retrospective <task-path>` - Retrospective phase (variance, learnings)

### Utility Commands

- `/cwf-config [init|list|reset]` - Configure CWF system paths and settings
- `/cwf-security-check [verify|report]` - Verify file integrity and sources for CWF system

## Task Types

Each task type runs a subset of the 10 available workflow phases, matched to its scope.
Phases are always split into a planning step and a separate execution step.

### Feature Tasks (10 phases)
Full development lifecycle:
plan → requirements → design → implementation plan → implementation exec → testing plan → testing exec → rollout → maintenance → retrospective

### Bugfix Tasks (7 phases)
plan → design → implementation plan → implementation exec → testing plan → testing exec → retrospective

### Hotfix Tasks (7 phases)
plan → implementation plan → implementation exec → testing plan → testing exec → rollout → retrospective

### Chore Tasks (6 phases)
plan → implementation plan → implementation exec → testing plan → testing exec → retrospective

## Project Structure

```
implementation-guide/
├── cwf-project.json
├── 1-feature-task-name/
│   ├── a-task-plan.md
│   ├── b-requirements-plan.md
│   ├── c-design-plan.md
│   └── ...
├── 1.1-chore-subtask/
│   └── ...
└── 2-bugfix-another-task/

.cwf/
├── autoload.yaml
├── lib/
│   └── CWF/                 # Perl library modules
├── scripts/
│   └── command-helpers/     # Helper scripts for compound operations
├── security/
│   └── script-hashes.json
└── templates/
    └── pool/                # Template source files (task-type symlinks alongside)
```

## Configuration

The system uses hierarchical configuration:

1. **Global**: `~/.cwf/autoload.yaml`
2. **Project**: `.cwf/autoload.yaml`
3. **Implementation Guide**: `implementation-guide/cwf-project.json`

Example `cwf-project.json` (template available at `.cwf/templates/cwf-project.json.template`):
```json
{
  "name": "My Project",
  "taskManagement": {
    "system": "github",
    "taskIdPattern": "^[A-Z]+-\\d+$"
  },
  "git": {
    "defaultBranch": "main",
    "branchPrefix": "feature/"
  }
}
```

## Hierarchical Numbering

Tasks use hierarchical numbering that syncs with filesystem structure:

- **Level 1**: 1, 2, 3 (main tasks)
- **Level 2**: 1.1, 1.2, 1.3 (subtasks)
- **Level 3**: 1.1.1, 1.1.2, 1.1.3 (micro-tasks)

Directory structure mirrors numbering exactly.

## Version Information

CWF uses `v{major}.{minor}.{task_num}` semver tags:
- **major**: breaking changes (wf file format, removed features, install incompatibilities)
- **minor**: new user-visible features (new skills, workflow phases, helper scripts)
- **patch**: CWF task number of the most recently completed task at time of tagging

Run `cwf-manage list-releases` to see available upgrades from the configured source.
Run `git describe --tags --always` for the current working-tree version.

## Contributing

1. Create a feature branch following the CWF methodology
2. Use `/cwf-new-task feature` to structure your work
3. Ensure hierarchical numbering matches directory structure
4. Test all skills before submission

## License

This project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0). See [LICENSE.md](LICENSE.md) for the full license text.

Commercial distribution licenses are available for organisations that wish to distribute this software without being bound by the AGPL-3.0 terms. See [COMMERCIAL-LICENSE.md](COMMERCIAL-LICENSE.md) for details on enquiries.

## Trademark Notice

Claude Code is a trademark of Anthropic. This repository is not affiliated with Anthropic or Claude Code. The mention of Claude Code in this repository is not indicative of support or endorsement by Anthropic.

## Support

For issues and feature requests, please open a GitHub issue:
https://github.com/CodingWithFiles/coding-with-files/issues
