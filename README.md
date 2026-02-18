# Coding with Files (CWF)

A structured system for managing software development tasks through Claude Code slash commands.

CWF is pronounced "swiff".

## Overview

Coding with Files (CWF) provides a standardised approach to planning, implementing, and tracking software development tasks. Currently targeted for Claude Code integration through slash commands, it offers automated task creation, progress tracking, and documentation generation.

While this system is designed specifically for Claude Code, the methodology isn't strictly tied to any particular tool. Pull requests to support other development environments are welcome.

## Project Status

**⚠️ Beta Development**: This is a new project under active development. While being used for actual development work, it should be considered a beta process. Use with appropriate caution.

**Development Status**: Core functionality is implemented and operational, but the system is still evolving based on real-world usage and feedback.

### Contributing

We welcome issues, pull requests, and suggestions! This project aims to become a community-driven tool.

**Copyright Assignment Preference**: Contributors are strongly encouraged to assign copyright to enable potential future cooperative or community benefit corporation structure where contributors could share in any revenue (though no firm plans exist yet).

**Current Priority**: Establishing robust, secure foundations before expanding features.

## Features

### v2.0 - Hierarchical Workflow System
- **Infinite Task Nesting**: Decimal numbering (1, 1.1, 1.1.1) with unlimited depth
- **8-Step Workflow**: Structured progression from planning through retrospective
- **Token-Efficient Context Inheritance**: Parent context via structural maps (~50-100 tokens vs 500-1000)
- **Progressive Disclosure**: Commands reference documentation rather than duplicating content
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

### Quick Install (Any Git Host)

```bash
git clone --depth 1 --filter=blob:none --sparse <cwf-repo-url> /tmp/cwf-bootstrap
git -C /tmp/cwf-bootstrap sparse-checkout set scripts
CWF_SOURCE=<cwf-repo-url> bash /tmp/cwf-bootstrap/scripts/install.bash
rm -rf /tmp/cwf-bootstrap
```

This fetches only the install script (~few KB) via sparse checkout, then runs it. Works with any git host (GitHub, GitLab, Gitea, etc.).

See **[INSTALL.md](INSTALL.md)** for complete instructions, post-install setup, and troubleshooting.

## Commands

### Core Commands (v2.0)

- `/cwf-init` - Initialise CWF system with project configuration
- `/cwf-new-task <num> <type> "description"` - **Breaking change**: Create hierarchical implementation guide
- `/cwf-subtask <parent-path> <num> <type> "description"` - **Breaking change**: Create subtask with context inheritance
- `/cwf-status [task-path]` - Show progress across implementation guide hierarchy
- `/cwf-extract <task-path> <section-name>` - **Breaking change**: Extract section (task-based, backward compatible)

### Workflow Commands (v2.0 - New)

Execute structured 8-step workflow for any task:

- `/cwf-task-plan <task-path>` - Guide through planning phase (goals, milestones, risks)
- `/cwf-requirements-plan <task-path>` - Guide through requirements phase (FR/NFR, acceptance criteria)
- `/cwf-design-plan <task-path>` - Guide through design phase (architecture, components, interfaces)
- `/cwf-implementation-plan <task-path>` - Guide through implementation phase (code changes, tests)
- `/cwf-testing-plan <task-path>` - Guide through testing phase (test strategy, validation)
- `/cwf-rollout <task-path>` - Guide through rollout phase (deployment, monitoring)
- `/cwf-maintenance <task-path>` - Guide through maintenance phase (support, optimization)
- `/cwf-retrospective <task-path>` - Guide through retrospective phase (learnings, variance)

### Utility Commands

- `/cwf-config [init|list|reset]` - Configure CWF system paths and settings
- `/cwf-security-check [verify|report]` - Verify file integrity and sources for CWF system

### Migration from v1.0

**Breaking Changes**: `/cwf-new-task`, `/cwf-subtask`, and `/cwf-extract` have new signatures (see [Migration Guide](.cwf/docs/migration.md#what-gets-changed)).

**Migrating v1.0 Tasks**: Existing v1.0 tasks continue to work without migration. Migration to v2.0 hierarchical structure is **optional** but enables task decomposition and context inheritance. See [Migration Guide](.cwf/docs/migration.md) for rationale, process, and safety features.

## Task Types

### Feature Tasks
Complete feature development lifecycle with 6 phases:
- Plan, Requirements, Design, Testing, Rollout, Maintenance

### Bugfix Tasks
Streamlined bug resolution with 4 phases:
- Plan, Implementation, Testing, Rollout

### Hotfix Tasks
Rapid critical issue resolution with 3 phases:
- Plan, Implementation, Rollout

### Chore Tasks
Maintenance and operational tasks with 4 phases:
- Plan, Implementation, Validation, Maintenance

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

**Git-Based Versioning**: This project uses `git describe --tags --always` format for version tracking (e.g., `v0.1.1-5-gcea1c19`):
- Base version from most recent git tag
- Number of commits since tag
- Current commit hash

**Current Version**: Run `git describe --tags --always` in repository for current version
**CWF Project Schema**: Matches git version for consistency

## Contributing

1. Create a feature branch following the CWF methodology
2. Use `/cwf-new-task feature` to structure your work
3. Ensure hierarchical numbering matches directory structure
4. Test all commands before submission

## License

This project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0). See [LICENSE.md](LICENSE.md) for the full license text.

Commercial distribution licenses are available for organisations that wish to distribute this software without being bound by the AGPL-3.0 terms. See [COMMERCIAL-LICENSE.md](COMMERCIAL-LICENSE.md) for details on enquiries.

## Trademark Notice

Claude Code is a trademark of Anthropic. This repository is not affiliated with Anthropic or Claude Code. The mention of Claude Code in this repository is not indicative of support or endorsement by Anthropic.

## Support

For issues and feature requests, please use the project's issue tracking system as configured in `cwf-project.json`.
