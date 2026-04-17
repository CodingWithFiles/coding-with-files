# Add path-scoped rules for wf file protection - Implementation Plan
**Task**: 98 (feature)

## Task Reference
- **Task ID**: internal-98
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/98-add-path-scoped-rules-for-wf-file-protection
- **Template Version**: 2.1

## Goal
Create the rule file, integrate it into the install pipeline and `/cwf-init`, and verify it loads correctly.

## Files to Modify
### New Files
- `.claude/rules/workflow-files.md` — Path-scoped rule file with glob frontmatter and skill mapping

### Modified Files
- `scripts/install.bash` — Add `.claude/rules` subtree split (subtree method) and copy (copy method), symlink creation, force-reinstall cleanup
- `.claude/skills/cwf-init/SKILL.md` — Add step to create `.claude/rules/` directory and symlinks during init
- `CLAUDE.md` — Add rules directory to architecture overview if appropriate

## Implementation Steps

### Step 1: Create the Rule File
- [ ] Create `.claude/rules/workflow-files.md` with YAML frontmatter:
  ```yaml
  ---
  description: Workflow step files must be edited via CWF skills, not directly
  globs:
    - "implementation-guide/**/{a,b,c,d,e,f,g,h,i,j}-*.md"
  ---
  ```
- [ ] Add terse skill mapping content (under 20 lines)
- [ ] Verify file is valid markdown with valid YAML frontmatter

### Step 2: Update install.bash — Subtree Method
- [ ] Add subtree split for `.claude/rules`: `git -C "$clone_dir" subtree split --prefix=.claude/rules -b cwf-rules >/dev/null`
- [ ] Add subtree add: `git subtree add --prefix=.cwf-rules "$clone_dir" cwf-rules --squash -m "Add CWF rules ($ref)"`
- [ ] Add force-reinstall cleanup for `.cwf-rules` and `.claude/rules/` symlinks
- [ ] Add `create_rule_symlinks()` function (parallel to `create_skill_symlinks()`)

### Step 3: Update install.bash — Copy Method
- [ ] Copy rules to staging prefix: `cp -r "$clone_dir/.claude/rules" .cwf-rules`
- [ ] Call `create_rule_symlinks()` after copy

### Step 4: Create Symlink Function
- [ ] Add `create_rule_symlinks()` function:
  ```bash
  create_rule_symlinks() {
      mkdir -p .claude/rules
      for link in .claude/rules/cwf-* .claude/rules/workflow-*; do
          [[ -L "$link" ]] && rm "$link"
      done
      local count=0
      for rule_file in .cwf-rules/*.md; do
          if [[ -f "$rule_file" ]]; then
              local name
              name="$(basename "$rule_file")"
              ln -s "../../.cwf-rules/$name" ".claude/rules/$name"
              count=$((count + 1))
          fi
      done
      log "Created $count rule symlinks in .claude/rules/"
  }
  ```

### Step 5: Update /cwf-init Skill
- [ ] Add step between "Register Skill Permissions" (step 6) and "Configure Claude Code Settings" (step 7):
  ```
  ### 6b. Create Rules Directory
  - Create `.claude/rules/` if not present
  - Create symlinks from `.claude/rules/` to `.cwf-rules/`
  - Verify symlinks resolve correctly
  ```
- [ ] Update git staging in step 8 to include `.claude/rules/`

### Step 6: Update CLAUDE.md
- [ ] Add `.claude/rules/` to the system integration section if appropriate

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 98
**Blockers**: None

## Actual Results
Implementation plan followed. Four files modified: rule file created, install script updated with `create_rule_symlinks()`, cwf-init updated with step 6b, glossary updated with two new terms.

## Lessons Learned
Originally named `workflow-files.md` — renamed to `cwf-workflow-files.md` after user feedback on namespace collisions. Always use `cwf-` prefix for installed files.
