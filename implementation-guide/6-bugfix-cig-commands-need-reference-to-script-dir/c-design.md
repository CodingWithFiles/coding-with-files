# CIG Commands Need Reference to Script Dir - Design

## Task Reference
- **Task ID**: internal-6
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/6-cig-commands-need-reference-to-script-dir
- **Template Version**: 2.0

## Goal
Design a consistent, minimal-impact solution to add explicit helper script directory references to all CIG command files.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

**Application to this task**:
- **Simplicity**: Single-line addition per file, no logic changes
- **Consistency**: Exact same format and placement across all 14 files
- **Readability**: Clear, explicit statement of script directory location
- **Reversibility**: Easy to revert if needed (single line removal)
- **Testability**: Verifiable by checking LLM path resolution behavior

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

**Application to this task**: **Explicit over implicit** - Make script directory path explicit in instructions rather than relying on implicit context.

## Key Decisions
### Architecture Choice
- **Decision**: Documentation pattern - add explicit helper scripts location reference
- **Rationale**:
  - LLM hallucinates script paths when seeing bare script names like `hierarchy-resolver.sh`
  - Context sections contain correct paths but LLM focuses on "Your task" instructions
  - Adding explicit path in instruction section prevents hallucination
  - One-line addition is minimal, non-invasive change
- **Trade-offs**:
  - **Benefit**: Clear, explicit path guidance in main instruction flow
  - **Benefit**: Minimal change (one line per file)
  - **Benefit**: Maintains all existing functionality
  - **Drawback**: Slight redundancy with Context section (acceptable trade-off)
  - **Drawback**: Must update 14 files (one-time cost)

### Technology Stack
- **Format**: Markdown (existing CIG command format)
- **Placement Strategy**: Insert after task description, before arguments/steps
- **Content Format**: Bold markdown with inline code: `**Helper scripts location**: `.cig/scripts/command-helpers/``

## System Design
### Component Overview
This is a documentation fix, not a code architecture change. Components affected:

- **CIG Command Files** (14 files in `.claude/commands/`):
  - Provide instructions to LLM for executing CIG workflows
  - Currently reference helper scripts by name only
  - Will be updated to include explicit directory path

- **Helper Scripts** (unchanged):
  - Located in `.cig/scripts/command-helpers/`
  - No changes required

### Data Flow
No data flow changes - this is purely a documentation update:

1. User invokes CIG command (e.g., `/cig-status`)
2. LLM reads command file instructions
3. **NEW**: LLM sees explicit path: `**Helper scripts location**: `.cig/scripts/command-helpers/``
4. LLM uses correct path when executing helper script commands
5. Helper scripts execute successfully (no ENOENT errors)

## Interface Design
### File Format Pattern

**Standardized insertion point** in all command files:

```markdown
## Your task
[Task description paragraph]

**Helper scripts location**: `.cig/scripts/command-helpers/`

**Arguments**: (or **Steps**: or other section)
```

### Placement Rules by Command File

| File | Insert After Line | Insert Before Section |
|------|-------------------|----------------------|
| cig-status.md | Line 11 (task description) | **Arguments** |
| cig-new-task.md | Line 13 (task description) | ⚠️ BREAKING CHANGE |
| cig-plan.md | Line 13 (task description) | **Steps** |
| cig-design.md | Line 13 (task description) | Follow the 8-step... |
| cig-implementation.md | Line 13 (task description) | Follow the 8-step... |
| cig-testing.md | Line 13 (task description) | Follow the 8-step... |
| cig-rollout.md | Line 13 (task description) | Follow the 8-step... |
| cig-maintenance.md | Line 13 (task description) | Follow the 8-step... |
| cig-retrospective.md | Line 13 (task description) | Follow the 8-step... |
| cig-requirements.md | Line 13 (task description) | Follow the 8-step... |
| cig-subtask.md | Line 15 (task description) | ⚠️ BREAKING CHANGE |
| cig-extract.md | Line 14 (task description) | **Parse arguments** |
| cig-config.md | TBD (check structure) | TBD |
| cig-security-check.md | TBD (check structure) | TBD |

### Exact Text Format

```markdown
**Helper scripts location**: `.cig/scripts/command-helpers/`
```

**Critical formatting requirements**:
- Bold markdown: `**...**`
- Inline code for path: `` `.cig/scripts/command-helpers/` ``
- Trailing slash included
- Blank line before and after

## Constraints
- **One line only**: User requirement - exactly one line per file
- **No Context changes**: Cannot modify Context sections or allowed-tools
- **Consistent placement**: Same location pattern across all files
- **Preserve formatting**: Must not break existing markdown structure
- **No logic changes**: Pure documentation update, no behavioral changes

## Validation
- [x] Design approach validated against planning phase
- [x] Placement strategy defined for all 14 files
- [x] Format specification documented
- [ ] User approval of design approach

## Status
**Status**: Finished
**Next Action**: Move to implementation (`/cig-implementation 6`)
**Blockers**: None

## Actual Results
Design approach validated through implementation:
- One-line addition per file proved minimal and non-invasive
- Consistent placement (after task description) worked across all file types
- Bold markdown with inline code format rendered correctly in all files
- Git diff confirmed exactly expected changes (14 files, 28 insertions)

## Lessons Learned
- "Explicit over implicit" architecture preference directly applicable - placing paths in both Context AND instructions prevents hallucination
- Design phase placement table proved valuable during implementation - no ambiguity about insertion points
- Treating command files as executable code (not documentation) led to correct design decisions
