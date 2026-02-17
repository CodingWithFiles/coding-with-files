# Fix install script / cwf-init boundary and post-install UX - Testing Plan
**Task**: 62 (bugfix)

## Task Reference
- **Task ID**: internal-62
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/62-fix-install-script-cwf-init-boundary
- **Template Version**: 2.1

## Goal
Validate that the install/init boundary is clean, cwf-manage uses idiomatic Perl, and UX improvements work correctly.

## Test Strategy

### Test Levels
- **Unit**: cwf-manage Perl syntax and perlcritic compliance
- **Integration**: Install script in scratch repos, cwf-init SKILL.md content verification
- **Regression**: Existing Task 61 test cases still conceptually valid

### Test Environment
Scratch repos in `/tmp/` with bare CWF clone as source (same pattern as Task 61).

```bash
git clone --bare . /tmp/cwf-test-source-62.git
```

## Test Cases

### Part 1: Install Script Boundary

- **TC-1**: Install script does NOT create `implementation-guide/`
  - **Given**: Empty git repo with initial commit; bare CWF clone
  - **When**: `CWF_SOURCE=file:///tmp/cwf-test-source-62.git bash scripts/install.bash`
  - **Then**: `.cwf/` exists, `.cwf-skills/` exists, symlinks exist, `.cwf/version` exists. `implementation-guide/` does NOT exist. `.gitignore` does NOT exist (or is unchanged if already present).

- **TC-2**: Install script does NOT modify `.gitignore`
  - **Given**: Empty git repo with existing `.gitignore` containing `node_modules/`
  - **When**: Run install script
  - **Then**: `.gitignore` contains only `node_modules/` — no `.cwf/task-stack` added

- **TC-3**: Install script still creates symlinks and version file
  - **Given**: Repo from TC-1
  - **When**: Inspect `.claude/skills/cwf-*` and `.cwf/version`
  - **Then**: Symlinks point to `../../.cwf-skills/cwf-*`; version file contains method, ref, sha, source, installed

### Part 2: cwf-manage Perl Idioms

- **TC-4**: cwf-manage passes `perl -c`
  - **When**: `perl -c .cwf/scripts/cwf-manage`
  - **Then**: "syntax OK"

- **TC-5**: cwf-manage passes `perlcritic --stern`
  - **When**: `perlcritic --stern .cwf/scripts/cwf-manage`
  - **Then**: "source OK"

- **TC-6**: No `system()` calls for file operations in cwf-manage
  - **When**: `grep -n 'system.*mkdir\|system.*find\|system.*cp\|system.*chmod' .cwf/scripts/cwf-manage`
  - **Then**: Zero matches. `system()` only used for `git` commands.

- **TC-7**: `copy_tree()` correctly copies directory trees
  - **Given**: Repo from TC-1 with CWF installed via copy method
  - **When**: `.cwf/scripts/cwf-manage update` (triggers `update_copy()` which uses `copy_tree()`)
  - **Then**: `.cwf/` and `.cwf-skills/` exist with correct contents; scripts have execute permission

- **TC-8**: `create_skill_symlinks()` uses `make_path()` not `system("mkdir")`
  - **Given**: Repo with no `.claude/skills/` directory
  - **When**: Run cwf-manage update (triggers `create_skill_symlinks()`)
  - **Then**: `.claude/skills/` created, symlinks present. No `mkdir` in process trace.

### Part 3: cwf-init SKILL.md

- **TC-9**: SKILL.md contains PERL5OPT detection step
  - **When**: `grep -c 'PERL5OPT' .cwf-skills/cwf-init/SKILL.md`
  - **Then**: References to detection/checking exist (not just the config suggestion)

- **TC-10**: SKILL.md contains post-init commit step
  - **When**: `grep -c 'git add\|git commit\|commit' .cwf-skills/cwf-init/SKILL.md`
  - **Then**: References to staging and committing init output exist

- **TC-11**: SKILL.md still contains all original setup steps
  - **When**: Grep for key steps: `implementation-guide`, `cwf-project.json`, `.gitignore`, `CLAUDE.md`
  - **Then**: All original setup responsibilities present

### Part 4: Documentation

- **TC-12**: INSTALL.md mentions restart requirement
  - **When**: `grep -i 'restart' INSTALL.md`
  - **Then**: Note about restarting Claude Code after install

### Part 5: Regression

- **TC-13**: Security hash valid for cwf-manage
  - **When**: Compare SHA256 of `.cwf/scripts/cwf-manage` against `.cwf/security/script-hashes.json`
  - **Then**: Hash matches

- **TC-14**: Existing CWF helper scripts still work
  - **When**: Run `context-manager location`, `task-context-inference`
  - **Then**: Both succeed

- **TC-15**: Subtree install still works end-to-end
  - **Given**: Fresh scratch repo
  - **When**: Full install via subtree method
  - **Then**: `.cwf/`, `.cwf-skills/`, symlinks, version file all present and correct

## Validation Criteria
- [ ] All 15 test cases passing
- [ ] Install script boundary clean (no project setup in install)
- [ ] cwf-manage uses only core Perl for file operations
- [ ] cwf-init SKILL.md has PERL5OPT detection and commit step
- [ ] INSTALL.md documents restart requirement
- [ ] No regression in existing functionality

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 62
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
