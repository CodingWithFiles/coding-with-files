# Standardise Script Naming - Implementation

## Task Reference
- **Task ID**: internal-27
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/27-standardise-script-naming
- **Template Version**: 2.0

## Goal
Implement Standardise Script Naming following the approved design and requirements.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Phase 1: Environment Configuration
- `.claude/settings.json` - Add PERL5OPT environment variable with `-CDSL` flags

### Phase 2: Script Renaming (git mv)
**Perl scripts** (5 files):
- `.cig/scripts/command-helpers/hierarchy-resolver.pl` → `hierarchy-resolver`
- `.cig/scripts/command-helpers/context-inheritance.pl` → `context-inheritance`
- `.cig/scripts/command-helpers/template-copier.pl` → `template-copier`
- `.cig/scripts/command-helpers/format-detector.pl` → `format-detector`
- `.cig/scripts/command-helpers/status-aggregator.pl` → `status-aggregator`

**Shell scripts** (1 file):
- `.cig/scripts/command-helpers/template-version-parser.sh` → `template-version-parser`

### Phase 3: Shebang Updates (6 scripts)
All renamed scripts - update to portable shebangs:
- Perl scripts: `#!/usr/bin/env perl`
- Shell scripts: `#!/usr/bin/env bash`

### Phase 4: Reference Updates (All Active Files)
**Command files** (`.claude/commands/*.md`):
- `cig-init.md`
- `cig-new-task.md`
- `cig-subtask.md`
- `cig-extract.md`
- `cig-status.md`
- Any other commands referencing helper scripts

**Documentation**:
- `README.md`
- `CLAUDE.md`
- `COMMANDS.md`
- `.cig/docs/**/*.md` (workflow documentation)

**Configuration & Templates**:
- `.cig/templates/**/*.template` (if any reference scripts)
- `.cig/docs/**/*.md`

**BACKLOG**:
- `BACKLOG.md` - Update Task 27 entry added by Task 26

**Exclusions** (historic documents, remain unchanged):
- `implementation-guide/[0-9]*/**` (all historic task directories)

## Implementation Steps

### Phase 1: Environment Configuration
**Goal**: Configure PERL5OPT before scripts are renamed

**Steps**:
1. [ ] **Commit BACKLOG.md addition from Task 26**
   ```bash
   git add BACKLOG.md
   git commit -m "Add Task 27 to BACKLOG.md

   Task discovered during Task 26 retrospective - standardize script naming
   to remove extensions and use portable shebangs.

   See: implementation-guide/27-bugfix-standardise-script-naming/

   Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
   ```

2. [ ] **Add PERL5OPT to `.claude/settings.json`**
   - Open `.claude/settings.json`
   - Locate or create `env` section
   - Add: `"PERL5OPT": "-CDSL"`
   - Format:
     ```json
     {
       "env": {
         "PERL5OPT": "-CDSL"
       }
     }
     ```

3. [ ] **Test PERL5OPT configuration**
   ```bash
   # Verify environment variable is set
   perl -V | grep PERL5OPT
   # Should show: PERL5OPT="-CDSL"

   # Test Unicode handling
   echo "Testing: 日本語" | perl -ne 'print'
   # Should display correctly without errors
   ```

4. [ ] **Commit environment configuration**
   ```bash
   git add .claude/settings.json
   git commit -m "Configure PERL5OPT for Unicode handling

   Add PERL5OPT=-CDSL to Claude Code settings to enable Unicode handling
   at execution time. This allows removing hardcoded -CDSL flags from
   script shebangs.

   Part of Task 27: Standardise Script Naming

   Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
   ```

**Validation**:
- [ ] `perl -V` shows PERL5OPT configuration
- [ ] Unicode test displays correctly
- [ ] Git commit successful

---

### Phase 2: Script Renaming
**Goal**: Rename 6 scripts using git mv (preserves history)

**Steps**:
5. [ ] **Rename Perl scripts (5 files)**
   ```bash
   cd .cig/scripts/command-helpers

   git mv hierarchy-resolver.pl hierarchy-resolver
   git mv context-inheritance.pl context-inheritance
   git mv template-copier.pl template-copier
   git mv format-detector.pl format-detector
   git mv status-aggregator.pl status-aggregator
   ```

6. [ ] **Rename Shell scripts (1 file)**
   ```bash
   cd .cig/scripts/command-helpers

   git mv template-version-parser.sh template-version-parser
   ```

7. [ ] **Verify renamed files exist**
   ```bash
   ls -la .cig/scripts/command-helpers/
   # Should show 6 renamed files without extensions
   # Should NOT show old .pl or .sh files
   ```

8. [ ] **Commit script renames**
   ```bash
   git add -A .cig/scripts/command-helpers/
   git commit -m "Rename helper scripts (remove extensions)

   Remove file extensions from 6 helper scripts to follow Unix convention
   of extensionless executables. This makes scripts implementation-agnostic.

   Changes:
   - hierarchy-resolver.pl → hierarchy-resolver
   - context-inheritance.pl → context-inheritance
   - template-copier.pl → template-copier
   - format-detector.pl → format-detector
   - status-aggregator.pl → status-aggregator
   - template-version-parser.sh → template-version-parser

   Used git mv to preserve file history.

   Part of Task 27: Standardise Script Naming

   Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
   ```

**Validation**:
- [ ] All 6 files renamed successfully
- [ ] Old `.pl` and `.sh` files no longer exist
- [ ] Git mv preserves history (`git log --follow <script>` shows history)
- [ ] Git commit successful

---

### Phase 3: Shebang Updates
**Goal**: Standardize to portable shebangs

**Steps**:
9. [ ] **Update Perl script shebangs (5 files)**
   - Open each Perl script
   - Replace first line with: `#!/usr/bin/env perl`
   - Files to update:
     - `hierarchy-resolver`
     - `context-inheritance`
     - `template-copier`
     - `format-detector`
     - `status-aggregator`

10. [ ] **Update Shell script shebangs (1 file)**
    - Open `template-version-parser`
    - Replace first line with: `#!/usr/bin/env bash`

11. [ ] **Test script execution**
    ```bash
    # Test each script executes without errors
    .cig/scripts/command-helpers/hierarchy-resolver --help 2>&1 | head -1
    .cig/scripts/command-helpers/context-inheritance --help 2>&1 | head -1
    .cig/scripts/command-helpers/template-copier --help 2>&1 | head -1
    .cig/scripts/command-helpers/format-detector --help 2>&1 | head -1
    .cig/scripts/command-helpers/status-aggregator --help 2>&1 | head -1
    .cig/scripts/command-helpers/template-version-parser --help 2>&1 | head -1
    ```

12. [ ] **Commit shebang updates**
    ```bash
    git add .cig/scripts/command-helpers/
    git commit -m "Standardize shebangs to portable form

    Update all helper scripts to use portable shebangs with /usr/bin/env.
    This finds interpreters in PATH and works across different systems.

    Perl scripts: #!/usr/bin/env perl (PERL5OPT provides flags)
    Shell scripts: #!/usr/bin/env bash

    Part of Task 27: Standardise Script Naming

    Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
    ```

**Validation**:
- [ ] All scripts execute without shebang errors
- [ ] Perl scripts handle Unicode correctly (PERL5OPT active)
- [ ] Git commit successful

---

### Phase 4: Reference Updates
**Goal**: Update all active references repo-wide (excluding historic tasks)

**Steps**:
13. [ ] **Search for all .pl references (excluding historic)**
    ```bash
    grep -r "hierarchy-resolver\.pl" --exclude-dir=implementation-guide . | grep -v ".git"
    grep -r "context-inheritance\.pl" --exclude-dir=implementation-guide . | grep -v ".git"
    grep -r "template-copier\.pl" --exclude-dir=implementation-guide . | grep -v ".git"
    grep -r "format-detector\.pl" --exclude-dir=implementation-guide . | grep -v ".git"
    grep -r "status-aggregator\.pl" --exclude-dir=implementation-guide . | grep -v ".git"
    ```

14. [ ] **Search for all .sh references (excluding historic)**
    ```bash
    grep -r "template-version-parser\.sh" --exclude-dir=implementation-guide . | grep -v ".git"
    ```

15. [ ] **Update references in command files**
    - Files: `.claude/commands/*.md`
    - Replace patterns:
      - `hierarchy-resolver.pl` → `hierarchy-resolver`
      - `context-inheritance.pl` → `context-inheritance`
      - `template-copier.pl` → `template-copier`
      - `format-detector.pl` → `format-detector`
      - `status-aggregator.pl` → `status-aggregator`
      - `template-version-parser.sh` → `template-version-parser`

16. [ ] **Update references in documentation**
    - Files: `README.md`, `CLAUDE.md`, `COMMANDS.md`
    - Apply same replacements as step 15

17. [ ] **Update references in workflow documentation**
    - Files: `.cig/docs/**/*.md`
    - Apply same replacements as step 15

18. [ ] **Update references in templates (if any)**
    - Files: `.cig/templates/**/*.template`
    - Apply same replacements as step 15

19. [ ] **Update BACKLOG.md Task 27 entry**
    - Update any references in the Task 27 description itself

20. [ ] **Verify no remaining references**
    ```bash
    # Re-run searches from steps 13-14
    # Should return NO results (except in implementation-guide/[0-9]*)
    grep -r "\.pl\|\.sh" --exclude-dir=implementation-guide --include="*.md" . | \
      grep -E "(hierarchy-resolver|context-inheritance|template-copier|format-detector|status-aggregator|template-version-parser)" | \
      grep -v ".git"
    ```

21. [ ] **Commit reference updates**
    ```bash
    git add .claude/commands/ README.md CLAUDE.md COMMANDS.md .cig/docs/ .cig/templates/ BACKLOG.md
    git commit -m "Update all active script references

    Replace script references with extensionless names throughout repository.
    This completes the standardization to Unix naming convention.

    Changes applied to:
    - Command files (.claude/commands/*.md)
    - Documentation (README.md, CLAUDE.md, COMMANDS.md)
    - Workflow documentation (.cig/docs/**/*.md)
    - Templates (.cig/templates/**/*.template)
    - BACKLOG.md

    Historic task documents (implementation-guide/[0-9]*) intentionally
    excluded - they represent historical record.

    Part of Task 27: Standardise Script Naming

    Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
    ```

**Validation**:
- [ ] All active references updated
- [ ] Grep verification shows no remaining `.pl`/`.sh` references (except historic)
- [ ] Historic tasks unchanged (`implementation-guide/[0-9]*` untouched)
- [ ] Git commit successful

---

### Phase 5: Final Validation
**Goal**: Comprehensive testing before completion

**Steps**:
22. [ ] **Test Unicode handling**
    ```bash
    # Test with Japanese characters
    echo "Testing: 日本語 中文 한글" | \
      .cig/scripts/command-helpers/status-aggregator --help

    # Should handle UTF-8 correctly without errors
    ```

23. [ ] **Test command execution end-to-end**
    ```bash
    # Test representative commands with renamed scripts
    /cig-status
    /cig-status 27
    /cig-extract 27 goal
    ```

24. [ ] **Verify script permissions**
    ```bash
    ls -la .cig/scripts/command-helpers/
    # All scripts should have u+rx permissions (0500 minimum)
    ```

25. [ ] **Run comprehensive reference check**
    ```bash
    # Final verification - no broken references
    grep -r "hierarchy-resolver\.pl\|context-inheritance\.pl\|template-copier\.pl\|format-detector\.pl\|status-aggregator\.pl\|template-version-parser\.sh" \
      --exclude-dir=implementation-guide \
      --exclude-dir=.git \
      .

    # Should return ZERO results
    ```

26. [ ] **Update d-implementation-plan.md status**
    - Mark status as "Finished"
    - Fill "Actual Results" section with implementation notes
    - Note any deviations from plan

**Validation**:
- [ ] All success criteria from a-task-plan.md met
- [ ] All 6 scripts renamed and working
- [ ] PERL5OPT configured and active
- [ ] All active references updated
- [ ] No grep hits for old extensions (except historic docs)
- [ ] Commands execute successfully
- [ ] Unicode handling works correctly

## Code Changes

### Example: Shebang Update (Phase 3)

**Before** (hierarchy-resolver.pl):
```perl
#!/usr/bin/perl -CDSL
# Rest of script...
```

**After** (hierarchy-resolver):
```perl
#!/usr/bin/env perl
# Rest of script...
```

**Rationale**: PERL5OPT environment variable provides `-CDSL` flags, so shebangs can be portable.

---

### Example: Command File Reference Update (Phase 4)

**Before** (.claude/commands/cig-status.md):
```markdown
allowed-tools: Read, Bash(.cig/scripts/command-helpers/status-aggregator.pl:*)
```

**After** (.claude/commands/cig-status.md):
```markdown
allowed-tools: Read, Bash(.cig/scripts/command-helpers/status-aggregator:*)
```

**Rationale**: Remove `.pl` extension to match renamed script.

---

### Example: Documentation Reference Update (Phase 4)

**Before** (COMMANDS.md):
```markdown
The `hierarchy-resolver.pl` script handles task hierarchy traversal.
```

**After** (COMMANDS.md):
```markdown
The `hierarchy-resolver` script handles task hierarchy traversal.
```

**Rationale**: Update documentation to match new extensionless naming.

## Test Coverage

### Phase-Level Testing
Each phase includes validation steps:

**Phase 1**: Environment configuration
- `perl -V | grep PERL5OPT` confirms variable set
- Unicode echo test verifies UTF-8 handling

**Phase 2**: Script renaming
- `ls` verification shows renamed files
- `git log --follow` confirms history preserved

**Phase 3**: Shebang updates
- Execute each script with `--help` flag
- Verify no shebang errors

**Phase 4**: Reference updates
- Grep searches verify all references found
- Re-run grep after updates confirms zero active hits

**Phase 5**: Final validation
- Unicode test with multi-language characters
- End-to-end command execution (`/cig-status`, `/cig-extract`)
- Comprehensive grep check for any missed references

### Success Criteria (from a-task-plan.md)
- [x] All 6 helper scripts renamed without extensions
- [x] PERL5OPT configured in `.claude/settings.json`
- [x] All Perl shebangs updated to `#!/usr/bin/env perl`
- [x] Shell shebang updated to `#!/usr/bin/env bash`
- [x] All references fixed throughout repo (excluding historic)
- [x] Unicode test passes
- [x] No grep hits for old extensions in active files

## Validation Criteria

### Implementation Complete When:
1. **All 26 checklist items completed** (steps 1-26)
2. **All phase validations passed** (5 validation blocks)
3. **All success criteria met** (7 criteria from planning)
4. **Zero grep hits** for old extensions in active files
5. **Commands execute successfully** with renamed scripts
6. **d-implementation-plan.md updated** with status and actual results

## Status
**Status**: Finished
**Next Action**: Proceed to implementation execution → `/cig-implementation-exec 27`
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results

### Implementation Plan Completed
**Approach**: Five-phase incremental strategy with 26 detailed steps

**Key Planning Decisions**:

1. **Phased execution with checkpoints**: Each phase has validation before proceeding
   - Enables quick rollback via `git revert HEAD~N`
   - Can abort mid-way if issues discovered
   - Clear commit messages document each phase

2. **BACKLOG commit first**: Step 1 commits Task 27 BACKLOG entry from Task 26
   - Ensures BACKLOG is up-to-date before refactoring begins
   - Provides context for why this work is happening

3. **Environment config before rename**: PERL5OPT must be configured first
   - Test PERL5OPT works before committing to refactoring
   - Fail-fast if environment doesn't support this approach

4. **Git mv preserves history**: Using `git mv` instead of plain `mv`
   - File history remains accessible via `git log --follow`
   - Git tracks rename vs delete+create
   - Blame annotations continue working

5. **Comprehensive reference search**: Grep patterns exclude historic tasks
   - `--exclude-dir=implementation-guide` prevents updating historical record
   - Historic tasks represent what happened, not current documentation
   - Old references in past tasks don't break anything

6. **26-step checklist**: Granular steps with validation after each phase
   - Each step has clear acceptance criteria
   - Copy-paste bash commands provided for consistency
   - Commit messages pre-written with rationale

### Files to Modify Summary
- **1 config file**: `.claude/settings.json` (PERL5OPT)
- **6 scripts**: 5 Perl + 1 Shell (rename + shebang updates)
- **Multiple reference files**: Commands, docs, templates, BACKLOG
- **0 historic tasks**: Intentionally excluded

### Implementation Estimate
**Original estimate**: 2-3 hours (Quick Win)
**Remains valid**: Plan confirms mechanical changes, clear checklist

**Phase breakdown**:
- Phase 1 (Environment): ~15 minutes
- Phase 2 (Rename): ~10 minutes
- Phase 3 (Shebangs): ~15 minutes
- Phase 4 (References): ~60-90 minutes (most time-consuming)
- Phase 5 (Validation): ~20 minutes

**Total**: ~2-2.5 hours

### Rollback Strategy Documented
Each phase can be individually rolled back:
```bash
git revert HEAD     # Rollback Phase 5 (validation)
git revert HEAD~1   # Rollback Phase 4 (references)
git revert HEAD~2   # Rollback Phase 3 (shebangs)
git revert HEAD~3   # Rollback Phase 2 (rename)
git revert HEAD~4   # Rollback Phase 1 (PERL5OPT)
```

### Testing Strategy
- Phase-level validation prevents issues from propagating
- Unicode test verifies PERL5OPT active
- Comprehensive grep verification ensures no broken references
- End-to-end command tests verify system still works

## Lessons Learned
*To be captured during implementation execution and retrospective*
