# CWF install script and release management - Requirements
**Task**: 61 (feature)

## Task Reference
- **Task ID**: internal-61
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/61-cwf-install-script
- **Template Version**: 2.1

## Goal
Define functional and non-functional specifications for the CWF bootstrap install script and post-install management script.

## Functional Requirements

### Bootstrap Script (`install.bash`)

- **FR1**: Fresh install via `curl -fsSL $URL | bash` installs CWF into the current git repo with zero interaction
  - Acceptance: Running the command in a git repo with no existing `.cwf/` directory results in a working CWF installation
- **FR2**: `CWF_METHOD` env var selects installation method
  - `subtree` (default): dual `git subtree split` from cloned CWF repo — one for `.cwf/`, one for `.cwf-skills/` (staging prefix)
  - `copy`: file copy of `.cwf/` and `.cwf-skills/` with automatic permission fix
  - Both methods create symlinks from `.cwf-skills/cwf-*/` into `.claude/skills/` as a post-install step
  - Acceptance: Both methods produce identical file layouts; consumer's existing `.claude/skills/` contents are preserved; subtree method creates git subtree history
- **FR3**: `CWF_REF` env var selects the version to install
  - `latest` (default): highest semver tag (resolved via `git tag -l 'v*' --sort=-version:refname`)
  - Tag: e.g. `v2.1.0`
  - Branch: e.g. `main`
  - Commit SHA: SHA-1 (40 hex) or SHA-2/256 (64 hex), including short forms
  - Acceptance: `git rev-parse` validates the ref; invalid refs produce a clear error
- **FR4**: Script performs post-install setup automatically
  - Creates `implementation-guide/` directory structure
  - Creates symlinks from each `.cwf-skills/cwf-*/` into `.claude/skills/`
  - Adds `.cwf/task-stack` to `.gitignore`
  - Writes `.cwf/version` file recording installed ref and method
  - Acceptance: After install, `ls -la .claude/skills/cwf-*` shows symlinks pointing to `.cwf-skills/`; `/cwf-init` only needs to generate project-specific config
- **FR5**: Script detects existing CWF installation and refuses to overwrite without `CWF_FORCE=1`
  - Acceptance: Running install twice without `CWF_FORCE=1` exits with a clear error message
- **FR6**: Script output is structured for both human and agent consumption
  - Clear status lines (what it's doing, what succeeded, what to do next)
  - Exit code 0 on success, non-zero on failure
  - No colour codes or interactive formatting (agents can't parse ANSI)

### Management Script (`.cwf/scripts/cwf-manage`)

- **FR7**: `cwf-manage status` shows installed CWF version, install method, and source ref
  - Reads from `.cwf/version` file
  - Acceptance: Output includes version, method, ref, and install date
- **FR8**: `cwf-manage list-releases` shows available tagged releases from the CWF remote
  - Acceptance: Lists tags matching `v*` sorted by semver descending; indicates current installed version
- **FR9**: `cwf-manage update [ref]` updates CWF to a specified ref (default: latest)
  - For subtree installs: `git subtree pull` on both prefixes (`.cwf/` and `.cwf-skills/`)
  - For copy installs: re-fetch and re-copy with permission fix
  - Recreates symlinks from `.cwf-skills/cwf-*/` into `.claude/skills/`
  - Updates `.cwf/version` file
  - Acceptance: After update, `cwf-manage status` shows the new version; symlinks are valid
- **FR10**: `cwf-manage rollback <ref>` reverts to a previous version
  - For subtree installs: `git subtree pull` from the older ref on both prefixes
  - For copy installs: re-fetch and re-copy from the older ref
  - Recreates symlinks
  - Acceptance: After rollback, `cwf-manage status` shows the rolled-back version; symlinks are valid

### Release Convention

- **FR11**: Releases are tagged with semver format `vMAJOR.MINOR.PATCH` on main
  - Acceptance: `git tag -l 'v*'` lists releases; `latest` resolution picks the highest

## Non-Functional Requirements

### Portability (NFR1)
- Bash 4+ (no features from 5+)
- POSIX-compatible utilities only (no GNU-specific flags unless guarded)
- Works on Linux and macOS

### Agent Compatibility (NFR2)
- Zero interactive prompts — all config via env vars or args
- Plain text stdout (no ANSI colour, no spinners, no progress bars)
- Clear, parseable status messages an agent can act on
- Env var pattern: `curl -fsSL $URL | CWF_METHOD=copy bash`

### Idempotency (NFR3)
- Re-running `cwf-manage update` with same ref is a no-op (or harmless)
- Permission fixes are idempotent

### Security (NFR4)
- Bootstrap script verifiable via download-then-inspect workflow (`curl -o` then review then `bash`)
- No secrets or credentials in env vars or script output
- Script validates refs via `git rev-parse` — no shell injection from `CWF_REF`

### Reliability (NFR5)
- Failures leave the repo in a clean state (no partial installs)
- Each operation is atomic where possible (subtree add succeeds or rolls back)
- Clear error messages with actionable next steps on failure

## Constraints
- Must work in repos that already have `.claude/skills/` with non-CWF skills (no clobbering). CWF skills live in `.cwf-skills/` as the canonical location; `.claude/skills/cwf-*` entries are symlinks
- Git subtree split performance may degrade on very large CWF repo histories — document expected time
- The bootstrap script lives at repo root (`scripts/install.bash`) so it's accessible before CWF is installed
- The management script lives inside `.cwf/` so it's only available after install
- Windows is not supported; symlinks are safe to use

## Acceptance Criteria
- [ ] AC1: `curl -fsSL $URL | bash` in a fresh git repo produces a working CWF install (subtree method)
- [ ] AC2: `curl -fsSL $URL | CWF_METHOD=copy bash` produces an identical file layout via copy
- [ ] AC3: `curl -fsSL $URL | CWF_REF=v2.0.0 bash` installs a specific tagged version
- [ ] AC4: `cwf-manage update` upgrades to latest; `cwf-manage rollback v2.0.0` reverts
- [ ] AC5: `cwf-manage status` and `list-releases` produce correct output
- [ ] AC6: An agent can run the full install + first task workflow with no human intervention
- [ ] AC7: INSTALL.md documents both script and manual installation methods

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 61
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
### Pass 1 (original)
Requirements written but FR2 used `.claude/skills/` as subtree prefix, conflicting with constraint about not clobbering existing skills. Testing (TC-6) exposed the issue.

### Pass 2 (rework)
Updated FR2, FR4, FR9, FR10 to use `.cwf-skills/` as staging prefix with symlinks into `.claude/skills/`. Added explicit constraint about symlinks and no Windows support.

## Lessons Learned
- The constraint about preserving existing `.claude/skills/` was present from the start but the FR2 design contradicted it. Testing caught this — validates the workflow process.
