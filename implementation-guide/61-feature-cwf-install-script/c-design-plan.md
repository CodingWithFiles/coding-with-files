# CWF install script and release management - Design
**Task**: 61 (feature)

## Task Reference
- **Task ID**: internal-61
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/61-cwf-install-script
- **Template Version**: 2.1

## Goal
Define architecture and design decisions for the CWF bootstrap install script and post-install management script.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### D1: Two Scripts, Not One
- **Decision**: Separate bootstrap script (`scripts/install.bash`) from management script (`.cwf/scripts/cwf-manage`)
- **Rationale**: Bootstrap must work before CWF exists; management operates on an existing install. Different lifecycles — bootstrap is fetched from remote, management is installed with CWF.
- **Trade-offs**: Two scripts to maintain, but clear separation of concerns. Shared logic (ref resolution, clone management) extracted into functions within each script.

### D2: Language — Bash for Bootstrap, Perl for Management
- **Decision**: Bootstrap script (`install.bash`) in Bash; management script (`cwf-manage`) in Perl
- **Rationale**: Bootstrap is a `curl | bash` entry point — Bash is the convention. Management script runs after CWF is installed, so Perl is available and consistent with all existing CWF helper scripts. Perl is a hard prerequisite anyway (Git depends on it), and CWF uses only core Perl modules (no CPAN dependencies), so even minimal/embedded Perl distributions work.
- **Trade-offs**: Two languages across the two scripts. Acceptable because their lifecycles differ — bootstrap is fetched remotely, management is installed locally.

### D3: Staging Prefix + Symlinks for Skills
- **Decision**: Skills are installed to `.cwf-skills/` (staging prefix), then symlinked into `.claude/skills/`. The subtree method uses two `git subtree split`s: `.cwf/` and `.cwf-skills/` (mapped from source repo's `.claude/skills/`). The copy method copies to the same two directories.
- **Rationale**: Consumer repos may already have `.claude/skills/` with their own skills. Using `.claude/skills/` as a subtree prefix would clobber those. A staging prefix preserves the consumer's directory while CWF skills appear correctly via symlinks.
- **Trade-offs**: Symlinks add a post-install step and need recreation on update/rollback. Acceptable since Windows is not supported. The `.cwf-skills/` directory is an implementation detail — consumers interact with skills via `.claude/skills/cwf-*/` as before.

### D3a: Temporary Clone
- **Decision**: Bootstrap clones CWF repo to a temp dir, runs both `git subtree split`s there, then adds subtrees to the target repo. Temp dir is cleaned up on exit.
- **Rationale**: `git subtree split` requires a local clone with full history. The consumer shouldn't need to maintain a persistent CWF clone.
- **Trade-offs**: Clone adds time (~5-15s depending on repo size).

### D4: `.cwf/version` File Format
- **Decision**: Plain text key=value file:
  ```
  cwf_version=v2.1.0
  cwf_method=subtree
  cwf_ref=v2.1.0
  cwf_installed=2026-02-15T14:30:00Z
  cwf_source=https://github.com/mattkeenan/coding-with-files.git
  ```
- **Rationale**: Sourceable by Bash (`source .cwf/version`), readable by humans, parseable by any tool. No JSON/YAML dependency.
- **Trade-offs**: No nested structure, but the data is flat anyway.

### D5: Ref Resolution Strategy
- **Decision**: Use `git rev-parse` and `git tag` for all ref validation. Never regex-validate SHA length.
- **Rationale**: Git handles SHA-1 (40 hex), SHA-2/256 (64 hex), short forms, tags, branches — all through `rev-parse`. Regex validation would need to track Git's evolving object-format support.
- **Trade-offs**: Requires the clone to exist before validation. Acceptable since we clone early in the flow.

### D6: CWF_SOURCE Env Var
- **Decision**: Add `CWF_SOURCE` env var for the CWF repo URL (default: GitHub URL). This supports forks, mirrors, and local paths (`file:///path/to/repo`).
- **Rationale**: Task 60 testing used `file:///` paths for local repos. Enterprise users may mirror to internal git servers.
- **Trade-offs**: One more env var, but essential for non-GitHub installs.

### D7: Bootstrap Script Location
- **Decision**: `scripts/install.bash` at repo root (not inside `.cwf/`)
- **Rationale**: Must be accessible via raw GitHub URL before CWF is installed. `scripts/` is a conventional location. Not inside `.cwf/` because that's the distributable payload — the bootstrap is the delivery mechanism.
- **Trade-offs**: Adds a top-level `scripts/` directory to the CWF repo.

## Component Overview

### Bootstrap Script (`scripts/install.bash`)

**Responsibilities**: Clone CWF source, resolve ref, install via chosen method, post-install setup, write version file.

**Flow**:
1. Parse env vars (`CWF_METHOD`, `CWF_REF`, `CWF_SOURCE`, `CWF_FORCE`)
2. Validate prerequisites (git, bash version, inside a git repo)
3. Check for existing install (abort if `.cwf/` exists and no `CWF_FORCE=1`)
4. Clone CWF source to temp dir
5. Resolve ref (default: latest semver tag)
6. Checkout resolved ref in temp clone
7. Install via chosen method:
   - **subtree**: `git subtree split --prefix=.cwf` + `git subtree split --prefix=.claude/skills` (in clone), then `git subtree add --prefix=.cwf` + `git subtree add --prefix=.cwf-skills` (in target) with `--squash`
   - **copy**: `cp -r .cwf/` + `cp -r` skills to `.cwf-skills/` + `chmod u+rx` permission fix
8. Create symlinks: for each `.cwf-skills/cwf-*/`, create symlink at `.claude/skills/cwf-*` → `../../.cwf-skills/cwf-*`
9. Post-install: create `implementation-guide/`, update `.gitignore`, write `.cwf/version`
10. Print summary and next steps
11. Clean up temp dir (via `trap`)

### Management Script (`.cwf/scripts/cwf-manage`)

**Responsibilities**: Query installed state, list remote releases, update, rollback.

**Flow** (subcommand-based):
- `status`: Read `.cwf/version`, print formatted output
- `list-releases`: Fetch tags from CWF remote, sort by semver, mark current
- `update [ref]`: Clone/fetch CWF source, resolve ref, apply update via installed method, recreate symlinks, update `.cwf/version`
- `rollback <ref>`: Same as update but to an older ref (semantically identical, separate command for clarity)

### Shared Patterns

Both scripts use the same patterns:
- **`log()`**: Structured output function — `[CWF] message` format, no ANSI
- **`die()`**: Error + exit 1
- **`resolve_ref()`**: Given a clone dir and ref string, return the resolved commit SHA
- **`resolve_latest()`**: Given a clone dir, return the highest semver tag
- **`cleanup()`**: `trap`-based temp dir removal

## Data Flow

```
User/Agent
    │
    ├── curl | bash ──→ install.bash
    │                      │
    │                      ├── git clone (temp)
    │                      ├── resolve ref
    │                      ├── subtree split × 2  OR  cp -r × 2
    │                      │   (.cwf/ and .cwf-skills/)
    │                      ├── create symlinks: .cwf-skills/cwf-* → .claude/skills/cwf-*
    │                      ├── post-install setup
    │                      └── write .cwf/version
    │
    └── .cwf/scripts/cwf-manage <cmd>
                           │
                           ├── status  → read .cwf/version
                           ├── list    → git ls-remote --tags
                           ├── update  → clone + subtree pull OR cp -r + recreate symlinks
                           └── rollback → same as update (older ref)
```

## Interface Design

### Env Vars (bootstrap)
| Var | Default | Values |
|-----|---------|--------|
| `CWF_METHOD` | `subtree` | `subtree`, `copy` |
| `CWF_REF` | `latest` | tag, branch, SHA-1, SHA-2/256, `latest` |
| `CWF_SOURCE` | `https://github.com/mattkeenan/coding-with-files.git` | Any git URL or `file://` path |
| `CWF_FORCE` | (unset) | `1` to overwrite existing install |

### Subcommands (management)
| Command | Args | Description |
|---------|------|-------------|
| `status` | (none) | Show installed version, method, source |
| `list-releases` | (none) | List available tags from remote |
| `update` | `[ref]` | Update to ref (default: latest) |
| `rollback` | `<ref>` | Revert to a previous ref |

### Exit Codes
| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error (with message) |
| 2 | Prerequisites not met |
| 3 | Existing install detected (no CWF_FORCE) |

### Output Format
```
[CWF] Cloning CWF source from https://github.com/...
[CWF] Resolved ref: v2.1.0 (abc1234)
[CWF] Installing via subtree method...
[CWF] Added .cwf/ (subtree split 1/2)
[CWF] Added .cwf-skills/ (subtree split 2/2)
[CWF] Created symlinks: .claude/skills/cwf-* -> .cwf-skills/cwf-*
[CWF] Post-install: created implementation-guide/
[CWF] Post-install: updated .gitignore
[CWF] Post-install: wrote .cwf/version
[CWF] CWF v2.1.0 installed successfully
[CWF] Next: run /cwf-init in Claude Code to generate project config
```

## Constraints
- `list-releases` uses `git ls-remote --tags` (no full clone needed — fast)
- `update` and `rollback` need a clone for subtree operations (same as bootstrap)
- The `.cwf/version` file should be added to `.gitignore` considerations — it's install-specific state, but useful to commit so team members know which CWF version the project uses. Decision: committed by default.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 61
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
### Pass 1 (original)
Design used `.claude/skills/` as second subtree prefix. Testing (TC-6) revealed this clobbers existing consumer skills.

### Pass 2 (rework)
Added D3 (staging prefix + symlinks), renumbered old D3 to D3a. Updated flow steps 7-8, data flow diagram, and output format to reflect `.cwf-skills/` staging with symlinks into `.claude/skills/`.

## Lessons Learned
- The staging prefix approach cleanly separates CWF's subtree concerns from the consumer's skill directory ownership.
