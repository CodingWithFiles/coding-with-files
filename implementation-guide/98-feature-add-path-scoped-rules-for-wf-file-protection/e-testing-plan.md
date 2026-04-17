# Add path-scoped rules for wf file protection - Testing Plan
**Task**: 98 (feature)

## Task Reference
- **Task ID**: internal-98
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/98-add-path-scoped-rules-for-wf-file-protection
- **Template Version**: 2.1

## Goal
Verify rule file format, content, glob matching, install integration, and cwf-init integration.

## Test Strategy
### Test Levels
- **File validation**: Rule file exists, has valid frontmatter, correct content
- **Pattern matching**: Glob pattern matches expected files, rejects non-matching files
- **Install integration**: install.bash handles rules in both subtree and copy methods
- **Init integration**: cwf-init creates rules directory and symlinks
- **Regression**: Existing install and init behaviour unchanged

## Test Cases

### Rule File Validation
- **TC-1**: Rule file exists with valid frontmatter
  - **Given**: `.claude/rules/workflow-files.md` created
  - **When**: Read file and parse YAML frontmatter
  - **Then**: File has `description` and `globs` fields in frontmatter; content is valid markdown

- **TC-2**: Rule content maps all 10 step prefixes
  - **Given**: Rule file content
  - **When**: Grep for each prefix (a- through j-)
  - **Then**: All 10 prefixes present with correct skill names: task-plan, requirements-plan, design-plan, implementation-plan, testing-plan, implementation-exec, testing-exec, rollout, maintenance, retrospective

- **TC-3**: Rule content under 20 lines (NFR1)
  - **Given**: Rule file content (excluding frontmatter)
  - **When**: Count lines
  - **Then**: Under 20 lines

### Glob Pattern Matching
- **TC-4**: Glob matches top-level task wf step files
  - **Given**: Glob pattern from frontmatter
  - **When**: Test against `implementation-guide/98-feature-*/a-task-plan.md`
  - **Then**: Match

- **TC-5**: Glob matches nested subtask wf step files
  - **Given**: Glob pattern from frontmatter
  - **When**: Test against `implementation-guide/48-feature-*/48.1-bugfix-*/f-implementation-exec.md`
  - **Then**: Match

- **TC-6**: Glob does not match non-wf-step files
  - **Given**: Glob pattern from frontmatter
  - **When**: Test against `implementation-guide/98-feature-*/cwf-project.json` or `README.md`
  - **Then**: No match

### Install Integration
- **TC-7**: install.bash contains rules subtree split
  - **Given**: Updated `scripts/install.bash`
  - **When**: Grep for `.claude/rules` subtree split
  - **Then**: Found in `install_subtree()` function

- **TC-8**: install.bash contains rules copy
  - **Given**: Updated `scripts/install.bash`
  - **When**: Grep for `.cwf-rules` copy
  - **Then**: Found in `install_copy()` function

- **TC-9**: install.bash contains `create_rule_symlinks()` function
  - **Given**: Updated `scripts/install.bash`
  - **When**: Grep for function definition
  - **Then**: Function exists and creates `.claude/rules/` directory with symlinks

### Init Integration
- **TC-10**: cwf-init skill references rules directory creation
  - **Given**: Updated `.claude/skills/cwf-init/SKILL.md`
  - **When**: Read skill file
  - **Then**: Contains step for creating `.claude/rules/` and symlinks, and stages `.claude/rules/` in init commit

### Regression
- **TC-11**: cwf-manage validate still passes
  - **Given**: All changes applied
  - **When**: Run `perl -I.cwf/lib .cwf/scripts/cwf-manage validate`
  - **Then**: Exit 0, output "OK"

## Validation Criteria
- [ ] TC-1 through TC-3: Rule file valid and concise
- [ ] TC-4 through TC-6: Glob pattern correct
- [ ] TC-7 through TC-9: Install pipeline updated
- [ ] TC-10: cwf-init updated
- [ ] TC-11: No regressions

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 98
**Blockers**: None

## Actual Results
11 test cases defined covering rule file content, glob pattern, install script integration, cwf-init integration, and glossary entries.

## Lessons Learned
Testing glob patterns requires verifying both inclusion and exclusion. The rename from `workflow-files.md` to `cwf-workflow-files.md` required updating test expectations.
