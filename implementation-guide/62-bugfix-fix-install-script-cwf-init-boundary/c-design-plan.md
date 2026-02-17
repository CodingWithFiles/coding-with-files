# Fix install script / cwf-init boundary and post-install UX - Design
**Task**: 62 (bugfix)

## Task Reference
- **Task ID**: internal-62
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/62-fix-install-script-cwf-init-boundary
- **Template Version**: 2.1

## Goal
Define the clean boundary between install script (plumbing) and `/cwf-init` (project setup), UX fixes in the init skill, and replace shell-in-Perl patterns with idiomatic core Perl in cwf-manage.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### D1: Responsibility Boundary
- **Decision**: Install script handles only CWF plumbing. `/cwf-init` handles all project setup.
- **Install script owns**: `.cwf/`, `.cwf-skills/`, symlinks in `.claude/skills/`, `.cwf/version`
- **`/cwf-init` owns**: `implementation-guide/`, `.gitignore`, `cwf-project.json`, CLAUDE.md hints, PERL5OPT guidance
- **Rationale**: The install script is a delivery mechanism — it puts CWF files in place. `/cwf-init` is the project configuration step — it sets up the project to use CWF. Separating these means the install script is idempotent plumbing, and `/cwf-init` is the user-facing setup.
- **Trade-offs**: Users must run both steps. Acceptable — INSTALL.md already documents this as the workflow.

### D2: PERL5OPT Detection
- **Decision**: `/cwf-init` reads `~/.claude/settings.json` and checks for `env.PERL5OPT` before suggesting configuration.
- **Rationale**: Avoids telling users to do something they've already done. Simple JSON check via `jq` or `cat` + grep.
- **Trade-offs**: Depends on `~/.claude/settings.json` location being stable. This is the documented Claude Code config path.

### D3: Post-Init Commit
- **Decision**: `/cwf-init` offers to stage and commit all files it created/modified at the end.
- **Commit scope**: `implementation-guide/`, `.gitignore`, `cwf-project.json`, any CLAUDE.md changes
- **Rationale**: Leaving init output uncommitted is confusing — the install script's subtree adds are committed but init's output isn't. Consistency requires either both commit or both don't. Since install commits (subtree add requires it), init should too.
- **Trade-offs**: Skill instructions can suggest a commit but can't force it. The LLM executing the skill will offer the commit to the user.

### D4: Replace Shell-in-Perl with Core Perl Idioms in cwf-manage
- **Decision**: Replace `system()` calls that have core Perl equivalents:
  - `system("mkdir", "-p", ...)` → `File::Path::make_path()` (already imported)
  - `system("find", ..., "chmod", ...)` → `File::Find::find()` + `chmod()` builtin
  - `system("cp", "-r", ...)` → `File::Find::find()` + `File::Copy::copy()` + `File::Path::make_path()`
- **Rationale**: These are C/shell idioms dressed up as Perl. Core Perl has had these facilities since Perl 5. Using them is more robust (proper error handling, no shell escaping concerns) and idiomatic.
- **Scope**: Only `cwf-manage`. The install script is Bash — shell idioms are correct there.
- **Trade-offs**: Recursive copy via `File::Find` + `File::Copy` is more verbose than `cp -r`, but gives proper error handling per-file.

### D5: Restart Documentation
- **Decision**: Add a note to INSTALL.md that Claude Code must be restarted after install for skills to register.
- **Rationale**: This is a Claude Code limitation, not a CWF bug. Users need to know to expect it.

## Data Flow

```
install.bash                          /cwf-init
    │                                     │
    ├── .cwf/ (subtree/copy)              ├── implementation-guide/
    ├── .cwf-skills/ (subtree/copy)       ├── cwf-project.json
    ├── .claude/skills/cwf-* (symlinks)   ├── .gitignore update
    ├── .cwf/version                      ├── CLAUDE.md hints
    └── (done — restart Claude Code)      ├── PERL5OPT check + guidance
                                          └── offer commit
```

## Constraints
- SKILL.md is markdown instructions, not executable — changes are to workflow text
- `jq` may not be installed; fall back to `grep` or `cat` for settings.json parsing
- Install script changes are to Bash; no new dependencies
- cwf-manage changes use only core Perl modules (`File::Find`, `File::Copy`, `File::Path`)

## Decomposition Check
- [x] **Time**: No
- [x] **People**: No
- [x] **Complexity**: No — four targeted edits
- [x] **Risk**: No
- [x] **Independence**: No

Zero signals. No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 62
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
