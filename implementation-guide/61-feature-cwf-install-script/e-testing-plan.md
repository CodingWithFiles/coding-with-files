# CWF install script and release management - Testing Plan
**Task**: 61 (feature)

## Task Reference
- **Task ID**: internal-61
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/61-cwf-install-script
- **Template Version**: 2.1

## Goal
Validate that the bootstrap install script and management script work correctly for both install methods, ref resolution, symlink creation, and lifecycle management.

## Test Strategy

### Test Levels
- **Unit**: Individual functions (ref resolution, version file parsing, prereq checks, symlink creation)
- **Integration**: Full install flow in scratch repos (both methods)
- **Regression**: Existing CWF functionality unaffected after script addition

### Test Environment
All tests run in temporary git repos created in `/tmp/`. Each test creates a fresh repo, runs the install, and validates the result. Cleanup via `rm -rf`.

A bare clone of the CWF repo is needed as the source. Create once:
```bash
git clone --bare . /tmp/cwf-test-source.git
```

## Test Cases

### Bootstrap — Subtree Method (Default)

- **TC-1**: Fresh install via subtree (default method)
  - **Given**: Empty git repo with initial commit; bare CWF clone available
  - **When**: `CWF_SOURCE=file:///tmp/cwf-test-source.git bash scripts/install.bash`
  - **Then**: `.cwf/` exists with scripts, templates, libs; `.cwf-skills/cwf-*` exists with skill dirs; `.claude/skills/cwf-*` are symlinks pointing to `../../.cwf-skills/cwf-*`; `.cwf/version` contains `cwf_method=subtree`; `implementation-guide/` dir exists; `.gitignore` contains `.cwf/task-stack`

- **TC-2**: Subtree install creates valid git subtree history
  - **Given**: Repo from TC-1
  - **When**: `git log --oneline` inspected
  - **Then**: Squash merge commits present for both `.cwf` and `.cwf-skills` prefixes

- **TC-3**: Existing install blocked without CWF_FORCE
  - **Given**: Repo from TC-1 (CWF already installed)
  - **When**: Run install again without `CWF_FORCE`
  - **Then**: Exit code 3, error message mentioning existing install

- **TC-4**: CWF_FORCE=1 allows reinstall
  - **Given**: Repo from TC-1
  - **When**: `CWF_SOURCE=... CWF_FORCE=1 bash scripts/install.bash`
  - **Then**: Exit code 0, install succeeds; `.cwf/` and `.cwf-skills/` replaced; symlinks recreated

### Bootstrap — Copy Method

- **TC-5**: Fresh install via copy
  - **Given**: Empty git repo with initial commit; bare CWF clone available
  - **When**: `CWF_SOURCE=file:///tmp/cwf-test-source.git CWF_METHOD=copy bash scripts/install.bash`
  - **Then**: Same file layout as TC-1; `.cwf/version` contains `cwf_method=copy`; scripts have execute permission (`u+rx`); `.claude/skills/cwf-*` are symlinks

- **TC-6**: Copy method produces identical file set to subtree
  - **Given**: Repos from TC-1 and TC-5
  - **When**: Compare file lists: `find .cwf -type f | sort` and `find .cwf-skills -type f | sort`
  - **Then**: Identical file sets (excluding `.cwf/version` method field)

### Bootstrap — Symlink Verification

- **TC-6a**: Symlinks are relative and point to correct targets
  - **Given**: Repo from TC-1 or TC-5
  - **When**: `readlink .claude/skills/cwf-init` inspected
  - **Then**: Target is `../../.cwf-skills/cwf-init` (relative path, not absolute)

- **TC-6b**: Install preserves existing non-CWF skills
  - **Given**: Empty git repo with initial commit; existing `.claude/skills/my-custom-skill/SKILL.md`
  - **When**: Run install script (either method)
  - **Then**: `.claude/skills/my-custom-skill/SKILL.md` still exists and is unchanged; CWF symlinks coexist alongside it

- **TC-6c**: Symlinks resolve and skill files are readable
  - **Given**: Repo from TC-1 or TC-5
  - **When**: `cat .claude/skills/cwf-init/SKILL.md` (via symlink)
  - **Then**: File contents readable; same as `cat .cwf-skills/cwf-init/SKILL.md`

### Bootstrap — Ref Resolution

- **TC-7**: CWF_REF=latest resolves to highest semver tag
  - **Given**: CWF source has tags `v1.0.0` and `v2.0.0`
  - **When**: `CWF_REF=latest` (or omitted)
  - **Then**: `.cwf/version` contains `cwf_ref=v2.0.0` (or whatever the highest is)

- **TC-8**: CWF_REF with specific tag
  - **Given**: CWF source has tag `v1.0.0`
  - **When**: `CWF_REF=v1.0.0 CWF_SOURCE=... bash scripts/install.bash`
  - **Then**: `.cwf/version` contains `cwf_ref=v1.0.0`

- **TC-9**: CWF_REF with branch name
  - **Given**: CWF source has a branch with `.cwf/` content
  - **When**: `CWF_REF=<branch> CWF_SOURCE=... bash scripts/install.bash`
  - **Then**: Install succeeds, `.cwf/version` contains the branch ref

- **TC-10**: CWF_REF with invalid ref
  - **Given**: CWF source exists
  - **When**: `CWF_REF=nonexistent-ref-xyz CWF_SOURCE=... bash scripts/install.bash`
  - **Then**: Exit code 1, error message about invalid ref

### Bootstrap — Prerequisite Checks

- **TC-11**: Not inside a git repo
  - **Given**: Plain directory (not a git repo)
  - **When**: Run install script
  - **Then**: Exit code 2, error about not being in a git repo

- **TC-12**: Output format is agent-friendly
  - **Given**: Any successful install
  - **When**: Capture stderr (where `[CWF]` messages go)
  - **Then**: All lines prefixed with `[CWF]`; no ANSI escape codes; exit code 0

### Management Script — Status

- **TC-13**: `cwf-manage status` after subtree install
  - **Given**: Repo from TC-1
  - **When**: `.cwf/scripts/cwf-manage status`
  - **Then**: Prints version, method=subtree, ref, source, install date

- **TC-14**: `cwf-manage status` after copy install
  - **Given**: Repo from TC-5
  - **When**: `.cwf/scripts/cwf-manage status`
  - **Then**: Prints version, method=copy, ref, source, install date

### Management Script — List Releases

- **TC-15**: `cwf-manage list-releases` shows available tags
  - **Given**: Repo with CWF installed; CWF source has tagged releases
  - **When**: `.cwf/scripts/cwf-manage list-releases`
  - **Then**: Lists tags sorted by semver descending; marks current installed version

### Management Script — Update

- **TC-16**: `cwf-manage update` with subtree install
  - **Given**: Repo from TC-1; CWF source has a newer commit/tag
  - **When**: `.cwf/scripts/cwf-manage update`
  - **Then**: Files updated; `.cwf/version` reflects new ref; symlinks still valid

- **TC-17**: `cwf-manage update` with copy install
  - **Given**: Repo from TC-5; CWF source has a newer commit/tag
  - **When**: `.cwf/scripts/cwf-manage update`
  - **Then**: Files updated; permissions correct; `.cwf/version` reflects new ref; symlinks still valid

### Management Script — Rollback

- **TC-18**: `cwf-manage rollback <ref>` reverts to older version
  - **Given**: Repo updated via TC-16 or TC-17
  - **When**: `.cwf/scripts/cwf-manage rollback <previous-ref>`
  - **Then**: Files match previous version; `.cwf/version` reflects rolled-back ref; symlinks still valid

- **TC-19**: `cwf-manage rollback` without ref argument
  - **Given**: Any installed repo
  - **When**: `.cwf/scripts/cwf-manage rollback` (no arg)
  - **Then**: Error message requesting a ref argument

### Management Script — Help and Errors

- **TC-20**: `cwf-manage help` prints usage
  - **When**: `.cwf/scripts/cwf-manage help`
  - **Then**: Prints available subcommands with descriptions

- **TC-21**: Unknown subcommand
  - **When**: `.cwf/scripts/cwf-manage foobar`
  - **Then**: Error message listing valid subcommands

### Documentation

- **TC-22**: INSTALL.md documents script install method
  - **When**: Grep INSTALL.md for script install instructions
  - **Then**: `curl | bash` example present; env vars table present; `cwf-manage` commands documented

- **TC-23**: No stale references
  - **When**: Grep INSTALL.md and new scripts for `.cig/`
  - **Then**: Zero matches

### Regression

- **TC-24**: Existing CWF helper scripts still work after adding new scripts
  - **When**: Run `context-manager location`, `task-context-inference` in the CWF repo itself
  - **Then**: All succeed without errors

- **TC-25**: Security hashes valid
  - **When**: Verify `cwf-manage` SHA256 hash against `.cwf/security/script-hashes.json`
  - **Then**: Hash matches

## Validation Criteria
- [ ] All 28 test cases passing (25 original + 3 new symlink tests)
- [ ] Both install methods produce working CWF installations with valid symlinks
- [ ] Existing consumer skills preserved during install
- [ ] Management script handles all subcommands correctly and recreates symlinks
- [ ] No regression in existing CWF functionality
- [ ] Zero stale `.cig/` references

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 61
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
### Pass 1 (original)
25 test cases written. TC-6 exposed the `.claude/skills/` clobbering issue during execution.

### Pass 2 (rework)
Updated TC-1, TC-2, TC-4, TC-5, TC-6 to reference `.cwf-skills/` prefix. Added TC-6a (symlink targets are relative), TC-6b (existing skills preserved), TC-6c (symlinks resolve correctly). Updated TC-16/TC-17/TC-18 to verify symlinks after update/rollback. Total: 28 test cases.

## Lessons Learned
- TC-6b (coexistence with existing skills) is the critical new test — it validates the entire reason for the redesign.
