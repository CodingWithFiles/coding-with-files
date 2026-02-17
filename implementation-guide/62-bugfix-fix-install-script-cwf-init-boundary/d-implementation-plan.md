# Fix install script / cwf-init boundary and post-install UX - Implementation Plan
**Task**: 62 (bugfix)

## Task Reference
- **Task ID**: internal-62
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/62-fix-install-script-cwf-init-boundary
- **Template Version**: 2.1

## Goal
Implement the install/init boundary fix, cwf-init UX improvements, cwf-manage Perl idiom cleanup, and restart documentation.

## Files to Modify

### Primary Changes
- `scripts/install.bash` — Remove `implementation-guide/` and `.gitignore` from `post_install()`
- `.cwf/scripts/cwf-manage` — Replace `system()` file ops with core Perl idioms
- `.cwf-skills/cwf-init/SKILL.md` — Add PERL5OPT detection, post-init commit step

### Supporting Changes
- `INSTALL.md` — Add restart note after install
- `.cwf/security/script-hashes.json` — Update cwf-manage hash

## Implementation Steps

### Step 1: Install Script Cleanup (`scripts/install.bash`)
- [ ] Remove `implementation-guide/` creation from `post_install()` (lines 219-223)
- [ ] Remove `.gitignore` creation/update from `post_install()` (lines 225-232)
- [ ] Keep: `create_skill_symlinks`, `.cwf/version` write — these are plumbing

### Step 2: cwf-manage Perl Idiom Fixes (`.cwf/scripts/cwf-manage`)
- [ ] Add `use File::Find;` and `use File::Copy qw(copy);` to imports
- [ ] Replace `system("mkdir", "-p", $skills_dir)` with `make_path($skills_dir)` in `create_skill_symlinks()` (line 270). `make_path` is from `File::Path`, already imported.
- [ ] Replace `system("find", ..., "chmod", ...)` with `File::Find` + `chmod()` in `update_copy()` (line 257):
  ```perl
  find(sub { chmod 0755, $_ if -f }, "$git_root/.cwf/scripts");
  ```
- [ ] Replace `system("cp", "-r", ...)` calls with a `copy_tree()` helper using `File::Find` + `File::Copy` + `File::Path` in `update_copy()` (lines 248-254):
  ```perl
  sub copy_tree {
      my ($src, $dst) = @_;
      find(sub {
          my $rel = $File::Find::name;
          $rel =~ s/^\Q$src\E//;
          my $target = "$dst$rel";
          if (-d) {
              make_path($target);
          } else {
              copy($_, $target)
                  or die_msg("Failed to copy $_ to $target: $!");
          }
      }, $src);
  }
  ```
- [ ] Update `update_copy()` to use `copy_tree()` and inline `chmod`/`find`
- [ ] Run `perl -c` and `perlcritic --stern` to verify

### Step 3: cwf-init SKILL.md Updates (`.cwf-skills/cwf-init/SKILL.md`)
- [ ] Add PERL5OPT detection step before Step 6:
  - Check `~/.claude/settings.json` for `PERL5OPT` using Bash: `grep -q PERL5OPT ~/.claude/settings.json 2>/dev/null`
  - If found: "PERL5OPT is already configured — no action needed"
  - If not found: show the existing configuration guidance
- [ ] Add Step 7: Post-init commit
  - Stage all created/modified files: `git add implementation-guide/ .gitignore cwf-project.json`
  - Offer to commit: "CWF project initialisation"
  - Include any CLAUDE.md changes if modified

### Step 4: Documentation (`INSTALL.md`)
- [ ] Add a note after the install steps: "Restart Claude Code (or start a new conversation) after install for skills to register"

### Step 5: Security Hash Update
- [ ] Regenerate SHA256 hash for cwf-manage in `.cwf/security/script-hashes.json`

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
- Install script no longer creates `implementation-guide/` or `.gitignore`
- cwf-manage passes `perl -c` and `perlcritic --stern`
- cwf-manage `update_copy()` and `create_skill_symlinks()` use no `system()` for file ops
- cwf-init SKILL.md includes PERL5OPT detection and commit step
- INSTALL.md mentions restart requirement

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 62
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
