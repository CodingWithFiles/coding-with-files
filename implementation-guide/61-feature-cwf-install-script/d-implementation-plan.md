# CWF install script and release management - Implementation Plan
**Task**: 61 (feature)

## Task Reference
- **Task ID**: internal-61
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/61-cwf-install-script
- **Template Version**: 2.1

## Goal
Implement the bootstrap install script, management script, and update INSTALL.md per the approved design.

## Files to Modify

### New Files
- `scripts/install.bash` — Bootstrap script (~150-200 lines)
- `.cwf/scripts/cwf-manage` — Management script (~150-200 lines)

### Modified Files
- `INSTALL.md` — Add script-based install method alongside existing manual methods
- `.cwf/security/script-hashes.json` — Add hash for `cwf-manage`
- `CLAUDE.md` — Add `cwf-manage` to utility commands section
- `README.md` — Update installation section if needed (currently points to INSTALL.md)

## Implementation Steps

### Step 1: Bootstrap Script (`scripts/install.bash`)
- [ ] Create `scripts/` directory
- [ ] Write script skeleton: shebang, `set -euo pipefail`, env var parsing with defaults
- [ ] Implement `log()` and `die()` helper functions (`[CWF]` prefix, no ANSI)
- [ ] Implement prerequisite checks (git version, bash version, inside git repo, no existing `.cwf/` unless CWF_FORCE)
- [ ] Implement `cleanup()` with `trap` for temp dir removal
- [ ] Implement `resolve_latest()` — `git tag -l 'v*' --sort=-version:refname | head -1`
- [ ] Implement `resolve_ref()` — `git rev-parse` validation, checkout
- [ ] Implement subtree install path:
  - Clone to temp dir
  - Checkout resolved ref
  - `git subtree split --prefix=.cwf -b cwf-core` (in clone)
  - `git subtree split --prefix=.claude/skills -b cwf-skills` (in clone)
  - `git subtree add --prefix=.cwf <temp> cwf-core --squash` (in target)
  - `git subtree add --prefix=.cwf-skills <temp> cwf-skills --squash` (in target — staging prefix)
  - Force reinstall: `git rm -rf` + unconditional `rm -rf` on both `.cwf/` and `.cwf-skills/`, then commit
- [ ] Implement copy install path:
  - Clone to temp dir
  - Checkout resolved ref
  - `cp -r <temp>/.cwf .cwf`
  - `cp -r <temp>/.claude/skills .cwf-skills` (staging prefix, not directly into `.claude/skills/`)
  - `find .cwf/scripts -type f -exec chmod u+rx {} \;`
  - Force reinstall: `rm -rf .cwf .cwf-skills`
- [ ] Implement symlink creation (`create_skill_symlinks()`):
  - `mkdir -p .claude/skills`
  - For each dir in `.cwf-skills/cwf-*/`: create relative symlink at `.claude/skills/<name>` → `../../.cwf-skills/<name>`
  - Remove stale CWF symlinks before creating new ones (handle skill renames across versions)
  - Log count of symlinks created
- [ ] Implement post-install:
  - Call `create_skill_symlinks()`
  - `mkdir -p implementation-guide`
  - Append `.cwf/task-stack` to `.gitignore` (idempotent)
  - Write `.cwf/version` file (key=value format per D4)
- [ ] Print summary and next steps
- [ ] Set executable permission: `chmod u+rx scripts/install.bash`

### Step 2: Management Script (`.cwf/scripts/cwf-manage`) — Perl
- [ ] Write script skeleton: shebang (`#!/usr/bin/env perl`), `use strict; use warnings;`, subcommand dispatch via `Getopt::Long` or positional args
- [ ] Implement `log_msg()` and `die_msg()` helpers (`[CWF]` prefix, no ANSI)
- [ ] Implement version file parser: read `.cwf/version` key=value format into hash
- [ ] Implement `status` subcommand:
  - Parse `.cwf/version`
  - Print version, method, ref, source, install date
- [ ] Implement `list-releases` subcommand:
  - Read `cwf_source` from `.cwf/version`
  - `git ls-remote --tags "$cwf_source" 'v*'`
  - Sort by semver descending (use `sort` with version comparison)
  - Mark current installed version
- [ ] Implement `update [ref]` subcommand:
  - Clone source to temp dir (`File::Temp`), resolve ref
  - Branch on method from `.cwf/version`:
    - subtree: re-split + `git subtree pull` on `.cwf/` and `.cwf-skills/` prefixes
    - copy: remove `.cwf/` and `.cwf-skills/`, re-copy, permission fix
  - Recreate symlinks (remove stale, create new)
  - Update `.cwf/version`
- [ ] Implement `rollback <ref>` subcommand:
  - Validate ref argument is provided
  - Delegate to same logic as `update` with the specified ref
- [ ] Implement `help` subcommand and unknown-command error
- [ ] Set executable permission: `chmod u+rx .cwf/scripts/cwf-manage`

### Step 3: Documentation Updates
- [ ] Update `INSTALL.md`:
  - Add "Quick Install (Script)" section at the top, before manual methods
  - Document env vars table (`CWF_METHOD`, `CWF_REF`, `CWF_SOURCE`, `CWF_FORCE`)
  - Document management commands (`cwf-manage status|update|rollback|list-releases`)
  - Keep existing manual methods as "Manual Install" sections
- [ ] Update `CLAUDE.md` utility commands to mention `cwf-manage`
- [ ] Regenerate `.cwf/security/script-hashes.json` to include `cwf-manage`

### Step 4: Release Tagging
- [ ] Establish tagging convention: determine appropriate first tag (e.g. `v2.0.0`)
  - Note: this requires merging to main first — may be done as a post-implementation step
  - The bootstrap script works without tags (can use branch refs), but `latest` resolution needs at least one tag

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
- Bootstrap installs CWF via both methods in a scratch repo
- Management script reads version, lists releases, performs update
- INSTALL.md documents all three install paths (script, subtree manual, copy manual)
- No regression in existing CWF functionality

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 61
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
### Pass 1 (original)
Implementation completed but testing revealed `.claude/skills/` subtree prefix clobbers existing consumer skills.

### Pass 2 (rework)
Updated Steps 1 and 2: subtree add targets `.cwf-skills/` prefix, copy targets `.cwf-skills/` directory. Added `create_skill_symlinks()` function for relative symlinks from `.claude/skills/cwf-*` → `../../.cwf-skills/cwf-*`. Force reinstall updated to clean `.cwf-skills/`. Management script update/rollback recreates symlinks.

## Lessons Learned
- Force reinstall needs both `git rm` (tracked files) AND `rm -rf` (untracked files) — `||` fallback is insufficient.
