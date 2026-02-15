# Add installation instructions - Implementation Plan
**Task**: 60 (chore)

## Task Reference
- **Task ID**: internal-60
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/60-add-installation-instructions
- **Template Version**: 2.1

## Goal
Create INSTALL.md with two first-class installation methods (git subtree, file copy) and update README.md to reference it.

## Files to Modify
### Primary Changes
- `INSTALL.md` — New file. Complete installation guide.
- `README.md` — Update Installation section (lines 48-59) to reference INSTALL.md.

## Implementation Steps

### Step 1: Write INSTALL.md
Structure:
1. **Prerequisites** — Perl 5.20+, git, Claude Code, bash
2. **Method 1: Git Subtree** (upstream sync)
   - `git subtree add` with `--prefix=.cwf` from CWF repo
   - Updating: `git subtree pull`
   - Removing: `git subtree split` / manual removal
   - Note: skills dir (`.claude/skills/cwf-*`) must be copied separately since subtree only handles one prefix
3. **Method 2: File Copy** (static / manual upgrade)
   - Copy `.cwf/` directory tree (70 files, 28 dirs)
   - Copy `.claude/skills/cwf-*` (18 SKILL.md files)
   - Upgrading: repeat copy from newer CWF release
   - Both are first-class methods — copy supports static installs, air-gapped environments, and controlled manual upgrades
4. **Post-Install Setup** (common to both methods)
   - Run `/cwf-init` to create `implementation-guide/` structure and `cwf-project.json`
   - Add `.cwf/task-stack` to `.gitignore`
   - Optional: set `PERL5OPT="-CDSL"` in `~/.claude/settings.json`
5. **Verification** — checklist to confirm installation is working
6. **Troubleshooting** — common issues (permissions, Perl version, missing skills)

### Step 2: Update README.md
- Replace the current Installation section (lines 48-59) with a brief summary and link to INSTALL.md
- Keep it short: prerequisites one-liner, pointer to INSTALL.md for full instructions

### Step 3: Validation
- Verify all file paths in INSTALL.md match actual repo layout
- Verify git subtree commands are syntactically correct
- Verify copy commands produce the right file set

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
- INSTALL.md covers both methods with copy/paste-ready commands
- README Installation section references INSTALL.md
- All paths in INSTALL.md match actual repo structure
- No broken or speculative references

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 60
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
