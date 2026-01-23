# CIG System Backlog

Future tasks and improvements for the Code Implementation Guide system.

---

## Task: Add Process Adherence Guards to All Workflow Commands

**Task-Type**: chore
**Priority**: Critical
**Status**: Discovered in Task 26 (jumped from design planning to implementation execution)

Add explicit process adherence instructions at the top of every CIG workflow command and skill to prevent LLMs from being "over eager" and skipping established process steps.

**Problem**: LLMs are trained to be helpful, which creates a tendency to jump ahead and execute tasks without following the proper workflow sequence:
- Example: Task 26 jumped from "design planning" phase directly to "implementation execution"
- User said "Implement the following plan" (referring to completing the design planning phase)
- LLM interpreted this as "write the code now" and skipped implementation planning entirely
- This bypasses critical planning steps and violates the established CIG workflow

**Root Cause**:
- LLM helpfulness bias → over-eager to "get things done"
- Commands don't explicitly warn "STAY IN THIS PHASE, DON'T SKIP AHEAD"
- No clear instruction about what to do if there's a reason to deviate from process

**Solution**: Add prominent process adherence section to EVERY workflow command file (and future skills)

### Required Section Format

Add immediately after the `---` frontmatter block, before "## Context":

```markdown
---
description: [existing description]
argument-hint: [existing hint]
allowed-tools: [existing tools]
---

## ⚠️ CRITICAL: Follow the Process

**YOU ARE IN THE [PHASE NAME] PHASE**

Your job is to complete THIS phase according to the steps below. Do NOT jump ahead to later phases.

**If you think there's an overriding reason to skip this process or move to a different phase:**
1. STOP
2. Ask the user explicitly: "I'm in the [phase] phase, but [reason]. Should I proceed with [alternative action] or stick to the process?"
3. Wait for user confirmation

**Common mistake**: Seeing "implement the plan" and jumping to code writing. In planning phases, "implement" means "complete the planning work", not "write code".

## Context
[rest of existing content]
```

### Commands to Update

All workflow commands need this section:
- `.claude/commands/cig-plan.md` → "TASK PLANNING PHASE"
- `.claude/commands/cig-requirements.md` → "REQUIREMENTS PLANNING PHASE"
- `.claude/commands/cig-design.md` → "DESIGN PLANNING PHASE"
- `.claude/commands/cig-implementation.md` → "IMPLEMENTATION PLANNING PHASE"
- `.claude/commands/cig-testing.md` → "TESTING PLANNING PHASE"
- `.claude/commands/cig-rollout.md` → "ROLLOUT PHASE"
- `.claude/commands/cig-maintenance.md` → "MAINTENANCE PLANNING PHASE"
- `.claude/commands/cig-retrospective.md` → "RETROSPECTIVE PHASE"

Execution commands (when created for v2.1):
- `.claude/commands/cig-implementation-exec.md` → "IMPLEMENTATION EXECUTION PHASE - Now you write code"
- `.claude/commands/cig-testing-exec.md` → "TESTING EXECUTION PHASE - Now you run tests"

### Customization Per Phase

**Planning phases** (plan, requirements, design, implementation planning, testing planning, maintenance planning):
- Emphasize: "You are PLANNING, not executing"
- Warning: "Do NOT write code, do NOT run tests, do NOT make changes"
- Clarify: "'Implement the plan' means complete the planning document, not write code"

**Execution phases** (implementation exec, testing exec):
- Emphasize: "NOW you can write code / run tests"
- Prerequisite check: "Verify planning is complete first"

**Deployment phases** (rollout):
- Emphasize: "You are deploying completed work"
- Prerequisite check: "Implementation and testing must be finished"

**Reflection phases** (retrospective):
- Emphasize: "You are reflecting on completed work"
- Warning: "Do NOT start new work, this task is done"

### Scope

1. **Update all 8+ command files** with process adherence section
2. **Customize wording** for each phase (planning vs execution vs deployment)
3. **Test with LLM**: Verify that warnings reduce over-eager behavior
4. **Update skills during migration**: When converting commands → skills, preserve these warnings
5. **Document pattern**: Add to `.cig/docs/` as standard for future commands/skills

### Success Criteria

- [ ] All workflow commands have "⚠️ CRITICAL: Follow the Process" section
- [ ] Section appears immediately after frontmatter, before Context
- [ ] Wording customized appropriately per phase type
- [ ] LLM demonstrates reduced over-eager behavior (anecdotal testing)
- [ ] Pattern documented for future command/skill development

### Testing

**Test Case: Design Planning Phase**
1. User runs `/cig-design 26`
2. User says "Implement the following plan: [design plan content]"
3. **Expected**: LLM completes design planning document, does NOT write code
4. **Actual (before fix)**: LLM jumps to implementation execution, writes code
5. **Actual (after fix)**: LLM follows process, completes design planning

**Test Case: Ambiguous Instruction**
1. User runs `/cig-requirements 27`
2. User says "Go ahead and build this"
3. **Expected**: LLM asks "Should I exit requirements planning and move to implementation, or continue with requirements planning?"
4. **Actual (before fix)**: LLM jumps to implementation
5. **Actual (after fix)**: LLM asks for clarification

### Priority Justification

**Critical Priority** because:
- **Workflow integrity**: Skipping phases undermines the entire CIG system
- **User frustration**: Having to constantly correct LLM about which phase we're in
- **Quality impact**: Skipping planning leads to poor implementation decisions
- **Systemic issue**: Affects ALL workflow commands, not just one
- **Simple fix**: Documentation change, high impact, low implementation cost

**Rationale**: LLM helpfulness bias is a fundamental behavior that won't change. We must explicitly guard against over-eager execution by making process adherence a prominent, unavoidable instruction in every workflow command. The cost of skipping planning steps (poor designs, missed requirements, inadequate testing) far exceeds the cost of adding explicit warnings.

---

## Task: Fix v2.1 Workflow File Order and Next Step References

**Task-Type**: bugfix
**Priority**: Critical
**Status**: Discovered in Task 26 (testing planning phase revealed incorrect workflow order)

Fix the v2.1 workflow file naming/ordering to follow correct test-first approach: plan implementation, plan testing, execute implementation, execute testing.

**Problem**: Current v2.1 workflow has incorrect file order that violates test-first principles:
- **Current order**: d-implementation-plan → e-implementation-exec → f-testing-plan → g-testing-exec
- **Problem**: Tests are planned AFTER implementation is executed, defeating purpose of planning-as-thinking
- **Impact**:
  - Encourages implementing without knowing what success looks like
  - Tests become afterthoughts rather than driving implementation
  - Violates "Patterns first → Test → Minimal impl" workflow
  - All "Next Step" sections in workflow files point to wrong next file
  - **Misses cognitive benefit**: Implementation happens before thinking through what's measurable/feasible

**Philosophy: Test Planning as a Thinking Tool**

The v2.1 workflow is NOT traditional TDD (write failing test → implement → make test pass). It's a **hybrid of TDD and planning-driven development** where test planning serves as a thinking tool.

**Key insight**: The primary purpose of test planning isn't to have a perfect test suite ready to execute. The primary purpose is to **understand the problem better** by forcing yourself to think deeply about what "working" means BEFORE you implement.

By planning tests, you're forced to ask:
- What's actually **measurable**? (All tests are measurements)
- What does success look like **concretely**?
- What **edge cases** exist?
- What's **feasible** vs. theoretical?

This understanding **informs** the implementation. You write better code because you've already thought through:
- How you'll validate it works
- What could go wrong
- What the acceptance criteria mean in practice
- What's actually measurable vs. what's aspirational

**Why correct order matters**:
- **Wrong order** (plan impl → exec impl → plan tests): You implement before you've thought through what "working" means. You miss the cognitive benefit.
- **Correct order** (plan impl → plan tests → exec impl): Test planning deepens your understanding of feasibility and success criteria, leading to better implementation decisions.

**Correct Order**: Tests should be planned BEFORE implementation execution:
1. a-task-plan.md → Plan the task
2. b-requirements-plan.md → Define requirements
3. c-design-plan.md → Design architecture
4. d-implementation-plan.md → Plan implementation steps
5. **e-testing-plan.md** → Plan tests (know what success looks like!)
6. **f-implementation-exec.md** → Execute implementation
7. **g-testing-exec.md** → Execute tests
8. h-rollout.md → Deploy
9. i-maintenance.md → Maintain
10. j-retrospective.md → Reflect

**Root Cause**: Task 25 implementation of v2.1 workflow used incorrect sequencing. The file naming (e-implementation-exec, f-testing-plan) bakes the wrong order into the file names.

**Solution**: Two-phase fix required:

### Phase 1: Fix File Naming Convention
**Rename workflow files** to correct order:
- e-implementation-exec.md → **f-implementation-exec.md**
- f-testing-plan.md → **e-testing-plan.md**
- g-testing-exec.md → **g-testing-exec.md** (stays same)
- h-rollout.md → **h-rollout.md** (stays same)
- etc.

**Affected components**:
1. `.cig/templates/pool/` - Rename template files
2. All existing v2.1 tasks (Task 25, Task 26) - Rename actual workflow files
3. Template symlinks for each task type (feature, bugfix, etc.)
4. `template-copier` - Update file name mappings
5. `status-aggregator-v2.1` - Update file name recognition
6. All workflow commands - Update file references

### Phase 2: Fix "Next Step" References
**Update all workflow template files** to reference correct next step:
- a-task-plan.md: "Next: `/cig-requirements-plan <task>`"
- b-requirements-plan.md: "Next: `/cig-design-plan <task>`"
- c-design-plan.md: "Next: `/cig-implementation-plan <task>`"
- d-implementation-plan.md: "Next: `/cig-testing-plan <task>`" ← **CRITICAL CHANGE**
- **e-testing-plan.md**: "Next: `/cig-implementation-exec <task>`" ← **NEW**
- **f-implementation-exec.md**: "Next: `/cig-testing-exec <task>`" ← **CRITICAL CHANGE**
- g-testing-exec.md: "Next: `/cig-rollout <task>`"
- h-rollout.md: "Next: `/cig-maintenance <task>`"
- i-maintenance.md: "Next: `/cig-retrospective <task>`"
- j-retrospective.md: "Task complete"

**Update workflow command files** to reference correct next step:
- `.claude/commands/cig-implementation-plan.md`: Suggest `/cig-testing-plan` next (not `/cig-implementation-exec`)
- `.claude/commands/cig-testing-plan.md`: Suggest `/cig-implementation-exec` next (not `/cig-rollout`)
- `.claude/commands/cig-implementation-exec.md`: Suggest `/cig-testing-exec` next
- `.claude/commands/cig-testing-exec.md`: Suggest `/cig-rollout` next

### Scope
**Phase 1: File Renaming**
1. Rename template files in `.cig/templates/pool/`:
   - e-implementation-exec.md.template → f-implementation-exec.md.template
   - f-testing-plan.md.template → e-testing-plan.md.template
2. Update template symlinks for all task types (feature, bugfix, hotfix, chore, discovery)
3. Update `template-copier` file mapping logic
4. Update `status-aggregator-v2.1` file recognition patterns
5. Rename existing v2.1 task files:
   - Task 25: Rename e→f, f→e
   - Task 26: Rename e→f, f→e (if e exists - currently doesn't)
6. Update git history / document breaking change

**Phase 2: Next Step References**
1. Update all 10 template files (a-j) with correct "Next Action" in Status sections
2. Update all workflow command files (8 commands) with correct next step suggestions
3. Update `.cig/docs/workflow/workflow-steps.md`:
   - Reflect correct file order (e-testing-plan, f-implementation-exec)
   - Update section on Testing Planning to explain it comes BEFORE implementation execution
   - Add philosophy explanation: test planning as thinking tool for understanding feasibility
4. Update `.cig/docs/workflow/workflow-overview.md`:
   - Update workflow sequence diagram/list to show correct order
   - Add philosophy section explaining test planning as cognitive tool
   - Clarify this is planning-driven development, not traditional TDD
   - Explain why order matters: test planning deepens understanding before implementation
5. Update any other documentation referencing workflow order

### Testing
1. Create new v2.1 task with `template-copier` - verify files created with correct names (e-testing-plan, f-implementation-exec)
2. Verify symlinks point to correct renamed templates
3. Verify `status-aggregator-v2.1 --workflow` recognizes all 10 files
4. Walk through workflow: plan → requirements → design → implementation → **testing** → **exec impl** → **exec test** → rollout
5. Verify "Next Action" references in each file point to correct next file

### Migration Strategy
**For existing v2.1 tasks** (Task 25, Task 26):
- Option A: Rename files in place (breaks existing references)
- Option B: Leave existing tasks as-is, only fix templates for future tasks
- Option C: Create migration script to rename files and update internal cross-references

**Recommended**: Option C - Create migration script
- Safer than manual renaming
- Can be run on Tasks 25, 26 to bring them into compliance
- Documents the transformation for future reference

### Success Criteria
- [ ] Template files renamed: e-testing-plan, f-implementation-exec
- [ ] Template symlinks updated for all task types
- [ ] template-copier creates files with correct names
- [ ] status-aggregator-v2.1 recognizes all 10 files in correct order
- [ ] All "Next Action" references point to correct next step
- [ ] All workflow commands suggest correct next step
- [ ] Documentation reflects correct order
- [ ] Existing v2.1 tasks (25, 26) migrated to new naming
- [ ] New v2.1 tasks created with correct file order
- [ ] Workflow follows test-first approach: plan tests BEFORE executing implementation

### Risks and Mitigations
**Risk 1: Breaking existing v2.1 tasks**
- **Likelihood**: High (Tasks 25, 26 have files with old names)
- **Impact**: High (status-aggregator won't find files, workflow broken)
- **Mitigation**: Create migration script, test on Task 25 first, document rollback procedure

**Risk 2: Confusion during transition**
- **Likelihood**: Medium (users/LLM may reference old file names)
- **Impact**: Medium (frustration, need to re-explain)
- **Mitigation**: Clear communication in commit message, update CHANGELOG, add note to workflow docs

**Risk 3: Internal cross-references break**
- **Likelihood**: Medium (workflow files may reference each other by name)
- **Impact**: Medium (broken links, confusing documentation)
- **Mitigation**: Migration script updates internal references, manual review of all templates

### Priority Justification
**Critical Priority** because:
- **Fundamental workflow flaw**: Current order violates test-first principles
- **Affects all future v2.1 tasks**: Every new task will be created with wrong order
- **Affects existing tasks**: Tasks 25 and 26 already have wrong file names
- **Workflow integrity**: Wrong order encourages bad practices (implement first, test later)
- **User confusion**: "Next Step" sections point to wrong files, causing workflow interruptions
- **Breaks TDD**: Cannot follow "Patterns first → Test → Minimal impl" with current order

**Rationale**: The v2.1 workflow is fundamentally broken. Test planning must come before implementation execution to enable test-first development. The current file naming (e-implementation-exec, f-testing-plan) bakes the wrong workflow into the file structure. This must be fixed before creating more v2.1 tasks.

**Discovered**: During Task 26 testing planning phase when cig-testing-plan command suggested "/cig-rollout 26" next, skipping implementation and test execution entirely.

---

## Task: Create hierarchy-resolver Trampoline Entry Point

**Task-Type**: bugfix
**Priority**: High
**Status**: Bug discovered in Task 26 planning phase

Create trampoline entry point for hierarchy-resolver to match Task 25 architecture pattern.

**Problem**: hierarchy-resolver is missing its trampoline entry point:
- Other Task 25 scripts have entry points: `status-aggregator`, `template-copier`, `context-inheritance`
- hierarchy-resolver only exists as `hierarchy-resolver` (no entry point)
- Command files and documentation reference `hierarchy-resolver` (no .pl extension)
- This breaks when commands try to call `.cig/scripts/command-helpers/hierarchy-resolver`

**Solution**: Create trampoline infrastructure for hierarchy-resolver matching Task 25 pattern:

**Files to create**:
1. `.cig/scripts/command-helpers/hierarchy-resolver` (entry point)
   - Detects task format version (v1.0/v2.0/v2.1)
   - Routes to appropriate orchestration script
2. `.cig/scripts/command-helpers/hierarchy-resolver-v2.0` (orchestration)
   - Handles v2.0 and v2.1 tasks (same logic)
   - Loads Core::HierarchyResolver module
3. Optionally: Extract `.cig/lib/CIG/HierarchyResolver/Core.pm` module

**Alternative (simpler)**: If hierarchy-resolver doesn't need version-specific logic:
- Create entry point that directly calls existing hierarchy-resolver
- Maintains API consistency with other scripts

**Scope**:
1. Create hierarchy-resolver entry point (no .pl extension)
2. Update script-hashes.json with new entry point
3. Test with existing commands that reference hierarchy-resolver
4. Verify permissions (0500 for entry point)

**Success Criteria**:
- [ ] Entry point created: `.cig/scripts/command-helpers/hierarchy-resolver`
- [ ] Commands can call `hierarchy-resolver <task-path>` successfully
- [ ] Follows same trampoline pattern as status-aggregator, template-copier, context-inheritance
- [ ] script-hashes.json updated

**Rationale**: Inconsistent architecture creates confusion and breaks command references. All helper scripts should follow same trampoline pattern established in Task 25.

---

## Task: Fix Format Detector to Correctly Identify v2.1 Tasks

**Task-Type**: bugfix
**Priority**: High
**Status**: Bug discovered in Task 26 planning phase

Fix format detection logic to correctly identify v2.1 (10-phase) tasks instead of misreporting them as v1.0.

**Problem**: hierarchy-resolver reports Task 26 as "Format: v1.0" when it should be v2.1:
- Task 26 created with template-copier (v2.1 workflow)
- Has 10 workflow files (a-j) including execution phases (e-implementation-exec.md, g-testing-exec.md)
- Template Version header says "2.0" (which covers v2.1)
- But hierarchy-resolver reports "Format: v1.0"

**Root Cause**: Format detection logic may not check for v2.1 indicators:
- Should detect v2.1 by presence of `e-implementation-exec.md` file
- Currently may only distinguish v1.0 vs v2.0 (not v2.1)

**Solution**: Update format detection in hierarchy-resolver (and potentially format-detector):

**Detection logic should be**:
1. Check for `e-implementation-exec.md` → v2.1 (10-phase)
2. Else check for `a-task-plan.md` or Template Version: 2.0 → v2.0 (8-phase)
3. Else check for `plan.md` → v1.0

**Files to check/update**:
- `.cig/scripts/command-helpers/hierarchy-resolver` (primary)
- `.cig/scripts/command-helpers/format-detector` (if used by hierarchy-resolver)
- Any other scripts that detect format

**Scope**:
1. Review format detection logic in hierarchy-resolver
2. Add v2.1 detection (check for e-implementation-exec.md)
3. Update return value to distinguish v2.0 vs v2.1
4. Test with v1.0, v2.0, and v2.1 tasks
5. Update documentation if format detection API changes

**Success Criteria**:
- [ ] Task 26 (v2.1) correctly reported as "Format: v2.1" (not v1.0)
- [ ] Existing v2.0 tasks still reported as "Format: v2.0"
- [ ] Existing v1.0 tasks still reported as "Format: v1.0"
- [ ] Detection based on file presence (not just Template Version header)

**Rationale**: Incorrect format detection can cause scripts to use wrong workflow file mappings, breaking task operations. Critical for correct v2.1 functionality.

---

## Task: Create v2.0 to v2.1 Workflow Migration Tools

**Task-Type**: feature
**Priority**: Critical (Highest - Blocking adoption of v2.1 workflow)

Create automated migration tools to upgrade existing v2.0 tasks (a-plan.md through h-retrospective.md) to v2.1 format (a-task-plan.md through j-retrospective.md with sequential a-j lettering).

**Context**: Task 25 implements v2.1 workflow with 10-phase sequential naming (a-j) and deprecates v1.0. Existing Tasks 1-24 use v2.0 format and will need migration to v2.1 to use new execution commands (cig-implementation-exec, cig-testing-exec).

**Problem**:
- v2.0 uses 8 files: a-plan.md, b-requirements.md, c-design.md, d-implementation.md, e-testing.md, f-rollout.md, g-maintenance.md, h-retrospective.md
- v2.1 uses 10 files with renames and re-lettering:
  - a-plan.md → a-task-plan.md
  - b-requirements.md → b-requirements-plan.md
  - c-design.md → c-design-plan.md
  - d-implementation.md → d-implementation-plan.md
  - e-testing.md → f-testing-plan.md (re-lettered!)
  - NEW: e-implementation-exec.md
  - NEW: g-testing-exec.md
  - f-rollout.md → h-rollout.md (re-lettered!)
  - g-maintenance.md → i-maintenance.md (re-lettered!)
  - h-retrospective.md → j-retrospective.md (re-lettered!)
- Manual migration is error-prone and tedious for 24 existing tasks

**Solution**: Create migration script(s) that:
1. Detect v2.0 tasks (presence of a-plan.md, absence of e-implementation-exec.md)
2. Rename existing files with -plan suffix where appropriate
3. Re-letter files (e→f, f→h, g→i, h→j)
4. Create new execution files (e-implementation-exec.md, g-testing-exec.md) with appropriate content
5. Update internal cross-references (d-implementation.md → d-implementation-plan.md references)
6. Validate migration (all 10 files exist, content valid, no broken references)
7. Provide rollback capability if migration fails

**Scope**:
- Migration script: `.cig/scripts/migrate-v20-to-v21.pl` or similar
- Dry-run mode to preview changes before applying
- Batch migration for all v2.0 tasks or selective migration
- Validation checks before and after migration
- Clear error messages and rollback on failure
- Update documentation with migration instructions

**Dependencies**:
- Task 25 must be complete (v2.1 format defined, trampoline architecture implemented)
- v2.1 template files must exist in `.cig/templates/pool/`

**Success Criteria**:
- [ ] Migration script created and tested
- [ ] Dry-run mode shows accurate preview
- [ ] Script handles all edge cases (partial migrations, already-migrated tasks)
- [ ] Validation checks prevent broken migrations
- [ ] Rollback works if migration fails mid-way
- [ ] Documentation explains migration process
- [ ] Tasks 1-24 can be migrated without manual intervention
- [ ] Migrated tasks work correctly with v2.1 workflow commands

**Rationale**: Without migration tools, users cannot easily adopt v2.1 workflow features (execution commands, blocker handling). This blocks the value delivery of Task 25 and creates friction for existing task management.

**Note**: v1.0→v2.0 migration tools already exist and are preserved by Task 25. This task creates equivalent v2.0→v2.1 migration capability.

---

## Task: Migrate CIG to Hybrid Plugin Model (Commands → Skills + Plugin)

**Task-Type**: feature
**Priority**: High

Migrate CIG from commands-based architecture to hybrid plugin model (plugin with skills), as recommended by Task 16's decision matrix scoring but not implemented due to post-hoc rationalization.

**Context - Task 16 Decision Matrix**:

Task 16 (Discovery: Investigate skills configuration and integration) evaluated 4 architecture options with weighted criteria scoring:
- **Hybrid Plugin: 55/75** ← HIGHEST SCORE
- Keep Commands: 47/75
- Plugin (skills-only): 39/75
- Skills-Only: 37/75

**The Issue**: Despite Hybrid Plugin scoring highest, Task 16's recommendation was "Keep Commands" based on "risk-adjusted thinking" (reversibility, migration risk, uncertain hooks value). During retrospective discussion, it was acknowledged that this was **post-hoc rationalization** - the lower-scoring option was selected due to implementation focus bias, not objective analysis. The retrospective even documents: "Highest score (Hybrid Plugin 55/75) ≠ Recommended option (Keep Commands 47/75)".

**Why This Decision Needs Revisiting**:

The landscape has changed significantly since Task 16 (2026-01-14):
1. **Commands are deprecated**: Anthropic is focusing on skills, commands looking increasingly legacy
2. **Task 11 blocked by unfixable bug**: Claude Code's `$ARGUMENTS` expansion bug (unbalanced sigils with special characters) prevents secure argument passing to commands. Reported to Anthropic but sitting unanswered because commands are deprecated.
3. **Hybrid Plugin avoids the bug**: Skills don't use `!{path} $ARGUMENTS` pattern, bypassing the security issue entirely
4. **"Safety" of Keep Commands was illusory**: The rationale for choosing Keep Commands (safety, reversibility) no longer holds when the platform is deprecating commands

**The Decision Matrix Was Right**: Hybrid Plugin scored highest for good reasons:
- Hooks provide automation value (SessionStart, PreToolUse, PostToolUse)
- Gradual migration path (convert commands incrementally to skills)
- Modern architecture aligned with Claude Code's future
- No `$ARGUMENTS` security bug

**Solution**: Implement the Hybrid Plugin model that scored 55/75 in Task 16's decision matrix.

### Two-Phase Migration

**Phase 1: Convert CIG Project to Plugin**
- **Goal**: Create `.claude/plugins/cig/PLUGIN.md` with proper structure
- **Scope**:
  - Create plugin directory structure (`.claude/plugins/cig/`)
  - Create PLUGIN.md manifest with metadata, hooks configuration
  - Set up plugin-specific references and documentation structure
  - Implement hooks (SessionStart, PreToolUse, PostToolUse, Stop)
  - Test plugin loading and hooks execution
  - Validate plugin works alongside existing commands (parallel operation)
- **Deliverable**: Working CIG plugin with hooks, running in parallel with existing commands
- **Rationale**: Establishes plugin infrastructure without breaking existing workflows

**Phase 2: Convert Commands to Skills (Gradual)**
- **Goal**: Migrate CIG commands to skills incrementally
- **Scope**:
  - Start with high-value commands: `cig-new-task`, `cig-status`, `cig-subtask`
  - Convert each command to skill in `.claude/plugins/cig/skills/`
  - Test each skill individually
  - Gradually convert remaining 12 workflow commands
  - Deprecate command files as skills prove stable
  - Update documentation to reference skills instead of commands
- **Deliverable**: All CIG functionality available as skills within plugin
- **Rationale**: Gradual migration reduces risk, allows validation at each step

### Benefits of Hybrid Plugin Model

**Immediate Benefits**:
- **Unblocks Task 11**: No `$ARGUMENTS` bug in skills architecture
- **Future-proof**: Aligned with Claude Code's skills-focused direction
- **Hooks automation**: SessionStart can auto-detect current task, PreToolUse can validate operations
- **Better UX**: Skills can provide richer context and validation than commands

**Long-term Benefits**:
- **Sustainable architecture**: Not dependent on deprecated commands system
- **Extensibility**: Plugin model supports growth (new skills, new hooks)
- **Security**: No shell argument expansion vulnerabilities
- **Maintainability**: Skills have clearer tool allowlists and validation patterns

### Migration Strategy

**Parallel Operation Period**:
- Keep existing `.claude/commands/cig-*.md` files during migration
- Skills take precedence when both exist (tested in Task 16)
- Users can fall back to commands if skills have issues
- Once skills proven stable (2-4 weeks usage), deprecate commands

**Rollback Plan**:
- Delete `.claude/plugins/cig/` directory to revert to commands
- Commands still present, immediately available
- Low-risk migration (can abort at any time)

**Testing Approach**:
- Create plugin with 2-3 pilot skills first (cig-new-task, cig-status)
- Validate hooks work as expected
- Test skills/commands precedence (skills should win)
- Gradually add remaining skills after pilot validation

### Dependencies

**Prerequisites**:
- Task 16 research (COMPLETE - provides architecture blueprint)
- Understanding of plugin structure (documented in Task 16)
- Understanding of skills structure (documented in Task 16)

**Blockers**:
- None - plugin/skills architecture is stable in Claude Code
- Task 16 testing confirmed hooks work in plugin mode
- Skills precedence over commands is deterministic

### Success Criteria

**Phase 1 Complete**:
- [ ] `.claude/plugins/cig/PLUGIN.md` created with valid manifest
- [ ] Hooks implemented and tested (SessionStart, PreToolUse, PostToolUse, Stop)
- [ ] Plugin loads successfully on Claude Code startup
- [ ] Plugin operates in parallel with existing commands (no interference)

**Phase 2 Complete**:
- [ ] All 15+ CIG commands converted to skills
- [ ] All skills tested and validated
- [ ] Skills take precedence over commands (verified)
- [ ] Documentation updated to reference skills
- [ ] Command files deprecated (optional: delete or archive)
- [ ] Task 11 unblocked (no `$ARGUMENTS` bug in skills)

**Overall Success**:
- [ ] CIG fully operational as hybrid plugin
- [ ] Hooks providing automation value (measurable time savings)
- [ ] Zero regression in functionality
- [ ] Improved UX from skills architecture

### Task Breakdown

Recommended to create two separate implementation tasks:

**Task A: "Convert CIG Project to Plugin Structure"**
- **Task-Type**: feature
- **Estimate**: 1-2 days
- **Deliverable**: `.claude/plugins/cig/` with working hooks
- **Risk**: Low (can run in parallel with commands)

**Task B: "Convert CIG Commands to Skills (Gradual Migration)"**
- **Task-Type**: feature
- **Estimate**: 3-5 days (15+ commands to convert)
- **Deliverable**: All CIG functionality as skills
- **Risk**: Low (gradual migration with fallback to commands)
- **Dependency**: Task A must complete first

### References

- **Task 16 Implementation**: `implementation-guide/16-discovery-investigate-skills-configuration-and-integration/d-implementation.md` lines 1274-1378 (decision matrix with scores)
- **Task 16 Retrospective**: `implementation-guide/16-discovery-investigate-skills-configuration-and-integration/h-retrospective.md` (acknowledges post-hoc rationalization)
- **Task 11 Blocker**: `implementation-guide/11-bugfix-only-pass-needed-args-to-scripts/` (blocked by `$ARGUMENTS` bug)
- **Plugin Structure Reference**: Task 16 documented plugin manifest format, hooks configuration, and directory structure
- **Skills Structure Reference**: Task 16 documented SKILL.md format, tool allowlists, and user-invocable patterns

**Rationale**: The original decision matrix was correct. Hybrid Plugin scored 55/75 for good reasons. Post-hoc rationalization led to selecting the lower-scoring "Keep Commands" option, but changed circumstances (commands deprecated, Task 11 blocked) now make the migration both necessary and urgent. This task corrects the decision and implements the architecture that Task 16's scoring recommended.

---

## Task: Create Automated Test Harness for CIG System

**Task-Type**: feature
**Priority**: Medium
**Status**: Proposed (identified in Task 25 retrospective)

Create executable test harness to automate the 95 manual validation test cases currently performed via `/cig-status`, `/cig-security-check`, and manual command testing.

**Problem**: Currently all CIG system validation is manual:
- Running `/cig-status` on Tasks 1-24 to verify regression
- Running `/cig-security-check verify` to check script integrity
- Creating test tasks to validate template copying
- Manually testing each workflow command
- Manual validation is time-consuming and error-prone

**Solution**: Create automated test script that validates all 95 test cases from Task 25 testing plan:
- Checkpoint 1-9 validation (Core modules, trampoline, templates, commands)
- Non-functional tests (performance, security, usability)
- Regression tests (Tasks 1-24 continue working)
- Acceptance tests (all functional requirements)

**Scope**:
1. Create `.cig/scripts/test-cig-system.sh` or similar
2. Automate functional test cases (TC-1.1 through TC-9.3)
3. Automate non-functional tests (TC-P1, TC-S1-S4, TC-U1)
4. Automate regression tests (TC-REG1-REG3)
5. Automate acceptance tests (FR1-FR13 validation)
6. Generate test report with pass/fail summary
7. Exit code 0 if all pass, non-zero if any fail

**Benefits**:
- One-command validation: `test-cig-system.sh` replaces 95 manual checks
- Prevents regressions when making changes
- Faster validation during development
- CI/CD integration capability

**Success Criteria**:
- [ ] Test harness created and executable
- [ ] All 95 test cases automated
- [ ] Clear pass/fail reporting
- [ ] Runs in <2 minutes
- [ ] Can run on any Perl 5.14+ system

**Rationale**: Manual validation is sustainable for small changes but becomes bottleneck as system grows. Automated testing provides confidence and speed.

---

## Task: Fix Status Aggregator to Only Check Main Status Sections

**Task-Type**: bugfix
**Priority**: Medium
**Status**: Proposed (identified in Task 25 retrospective)

Update status-aggregator to only aggregate the main `## Status` section in each workflow file, ignoring embedded Status sections within design/implementation planning sections.

**Problem**: Currently status-aggregator may read multiple `## Status` sections in a single file:
- c-design.md has 3 Status sections (main + embedded implementation plan + embedded testing plan)
- d-implementation.md may have embedded sections
- If not all Status sections updated to "Finished", task shows incorrect completion percentage
- Confusing which Status sections "count" toward task completion

**Root Cause** (from Task 25 retrospective):
- status-aggregator showed 25% when task was actually complete
- Multiple Status sections in c-design.md not all updated to "Finished"
- Unclear which Status sections matter for completion calculation

**Solution Options**:
- **Option A** (Recommended): Only aggregate main Status section (last one in file, or first one)
- **Option B**: Document that all Status sections must be updated
- **Option C**: Add comment marker to indicate which Status sections count

**Recommended**: Option A - simplest, least error-prone

**Scope**:
1. Update status-aggregator parsing logic to identify "main" Status section
2. Ignore embedded/secondary Status sections
3. Test with Tasks 1-25 to verify correct percentage calculation
4. Document behavior in status-aggregator script header

**Success Criteria**:
- [ ] status-aggregator calculates completion correctly even with embedded Status sections
- [ ] Tasks 1-25 show expected completion percentages
- [ ] Clear documentation of which Status sections count

**Rationale**: User shouldn't need to update embedded Status sections that are part of planning artifacts. Main Status section should be single source of truth for task completion.

---

## Task: Design Task-Type-Specific Workflow Variants

**Task-Type**: discovery
**Priority**: Low
**Status**: Proposed (identified in Task 25 retrospective)

Research and design task-type-specific workflow variants to match workflow overhead to task complexity.

**Problem**: Currently all task types potentially use 10-phase workflow (v2.1):
- Feature tasks: Full 10-phase makes sense
- Chore tasks: Rollout and maintenance may be unnecessary overhead
- Hotfix tasks: May need express workflow (skip planning, document retrospectively)
- Discovery tasks: Research outputs don't need rollout/maintenance

**Observation** (from Task 25 retrospective):
"Template File Count Verbose: 10 files per feature task (a-j) is comprehensive but verbose"
"Future Consideration: Consider optional 'lite' workflow for smaller tasks"

**Solution**: Research whether task-type-specific workflows provide value:

**Proposed Variants**:
- **Feature**: Full 10-phase (a-j) - comprehensive for major features
- **Bugfix**: Abbreviated 7-phase (a, c, d, e, f, g, j) - skip rollout, maintenance
- **Hotfix**: Express 5-phase (a, d, e, f, g, j) - skip design, planning, rollout, maintenance
- **Chore**: Minimal 4-phase (a, d, e, g, j) - skip rollout, maintenance, testing
- **Discovery**: Research 8-phase (a-g except h,i) - skip rollout, maintenance

**Scope**:
1. Research: Analyze existing Tasks 1-25 by type - which phases were actually used?
2. Survey: Are there phases that add overhead without value for certain task types?
3. Design: Define phase sets per task type with rationale
4. Validate: Would proposed variants have worked for historical tasks?
5. Document: Recommendations for implementing variants (if beneficial)

**Out of Scope** (this is discovery, not implementation):
- Actually implementing variants
- Changing existing templates
- Migration of existing tasks

**Success Criteria**:
- [ ] Historical task analysis complete (which phases used per task type)
- [ ] Variants defined with clear rationale
- [ ] Trade-offs documented (flexibility vs simplicity)
- [ ] Recommendation: implement variants, keep current, or other approach

**Rationale**: If task-type workflows can be optimized without losing value, it reduces overhead and improves UX. Discovery phase determines if optimization is worthwhile.

---

## Task: Add Status Calculation Overview to Workflow Documentation

**Task-Type**: chore
**Priority**: Low
**Status**: Proposed (identified during Task 25 retrospective discussion)

Add brief explanation of how task status/progress calculation works to workflow documentation, following DRY and progressive disclosure principles.

**Problem**: Current documentation explains status VALUES (Backlog=0%, Finished=100%) but not how task completion percentage is CALCULATED:
- No explanation that status is aggregated from workflow file Status fields
- No mention of status-aggregator script
- No reference to /cig-status (user-invocable currently, agent-invocable after skills migration)
- Users/LLM don't understand how "25% complete" is derived

**Solution**: Add brief "How Status Works" section to `.cig/docs/workflow/workflow-steps.md`:

```markdown
## How Task Status Works

Task completion percentage is calculated by aggregating the `## Status` field from each workflow file (a-plan.md through h-retrospective.md). Each status value has a percentage weight (Backlog=0%, In Progress=25%, Finished=100%, etc.).

**To check task status**:
- User runs: `/cig-status <task-path>` (command - user-only currently)
- Script: `status-aggregator <task-path>` (called by cig-status command)
- Future: Agent can invoke via Skill("cig-status") after skills migration

**How it's calculated**: See `status-aggregator` script for implementation details.

**Status values**: See [Status Values](#status-values) section above for complete list.
```

**Scope**:
1. Add brief "How Task Status Works" section to workflow-steps.md
2. Position after "Status Values" section (lines 16-48)
3. Include references to status-aggregator script
4. Note that /cig-status is user-only currently, agent-invocable after skills migration
5. Keep brief (4-6 sentences), follow progressive disclosure

**Out of Scope**:
- Detailed status-aggregator implementation (that's in the script itself)
- Fixing status aggregator issues (separate BACKLOG item exists)
- Skills migration (separate BACKLOG item exists)

**Success Criteria**:
- [ ] Brief explanation added to workflow-steps.md
- [ ] References status-aggregator script
- [ ] Notes future agent invocability
- [ ] Follows progressive disclosure (brief with pointers to details)

**Rationale**: Users and LLM need to understand how task percentage is calculated, but full details belong in script documentation (DRY). Brief overview with references provides sufficient context.

---

## Task: Update Documentation References from status-aggregator to status-aggregator

**Task-Type**: chore
**Priority**: Low
**Status**: Proposed (identified during Task 25 retrospective discussion)

Update all documentation and command references to use `status-aggregator` entry point script instead of outdated `status-aggregator` direct module reference.

**Problem**: Task 25 implemented trampoline architecture where helper scripts are invoked via entry points (no .pl extension), not by calling .pl files directly:
- Entry point: `.cig/scripts/command-helpers/status-aggregator`
- Routes to: `status-aggregator-v2.0` or `status-aggregator-v2.1` orchestration
- Uses: Core::StatusAggregator module

Documentation and commands may still reference `status-aggregator` which:
- Is technically incorrect (should call entry point, not .pl directly)
- Bypasses trampoline version routing
- Confusing for users who see `status-aggregator` in directory listings

**Solution**: Find and update all references:

**Files to check**:
- `.cig/docs/workflow/workflow-steps.md`
- `.cig/docs/context/tools.md`
- `.claude/commands/cig-status.md`
- Any other documentation or command files
- BACKLOG.md (this file)

**Change pattern**:
- `status-aggregator <task-path>` → `status-aggregator <task-path>`
- References to "status-aggregator script" → "status-aggregator script"

**Scope**:
1. Grep for all `status-aggregator` references
2. Update to `status-aggregator` (entry point)
3. Verify no functional changes (entry point routes to same logic)
4. Update this BACKLOG item itself (contains status-aggregator references)

**Success Criteria**:
- [ ] All references updated to use entry point (no .pl)
- [ ] No references to status-aggregator remain
- [ ] Documentation reflects trampoline architecture

**Rationale**: Documentation should reflect actual implementation (trampoline architecture). Entry point scripts are the public interface, .pl modules are internal implementation details.

---

## Task: Add Active Maintenance Cost Analysis to g-maintenance Template

**Task-Type**: chore
**Priority**: Medium

Update the g-maintenance.md template to require explicit analysis of active maintenance costs versus passive benefits, preventing open-ended future commitments.

**Problem**: Current g-maintenance.md template doesn't distinguish between:
- **Active scheduled tasks**: Work that MUST be done on a regular schedule (maintenance, noun form)
- **Reactive support**: Work that MIGHT be needed IF issues arise
- **Passive benefits**: Value delivered without ongoing work

This leads to proposals for "quarterly reviews" or "monthly checks" without justifying the time commitment. Maintenance is an ongoing cost that needs explicit justification.

**Solution**: Add required section to g-maintenance.md template:

```markdown
## Active Maintenance Requirements

### Scheduled Maintenance Tasks
List tasks that MUST be done on a regular schedule:
- [Task description] - [Frequency] - [Estimated time]

**Total scheduled cost**: [Hours per year]

If NONE: Explicitly state "NONE - no scheduled maintenance required"

### Reactive Maintenance Only
List scenarios where action MIGHT be required (IF/THEN format):
- **IF** [trigger condition] → **THEN** [action] ([estimated time])

**Estimated reactive burden**: [Hours per year, may be zero]

### Cost/Benefit Analysis
**Active costs**: [Scheduled + reactive estimates]
**Benefits**: [Concrete value delivered, if feature used]
**Justification**: [Why ongoing cost is worth it, or why zero cost makes it low-risk]
**Deprecation trigger**: [When would we remove this feature?]
```

**Scope**:
1. Update `.cig/templates/pool/g-maintenance.md.template` with new section
2. Position after "Monitoring Requirements" section, before "Status"
3. Include examples for both scenarios:
   - Example A: Feature with scheduled maintenance (database cleanup, log rotation)
   - Example B: Feature with zero scheduled maintenance (configuration/documentation changes)
4. Update documentation to explain distinction between active/reactive/passive

**Rationale**: Prevents open-ended future commitments by requiring explicit justification of ongoing work. Makes maintenance costs visible upfront, enabling better decisions about feature complexity.

---

## Task: Research and Consolidate Cross-Document Reference Patterns

**Task-Type**: discovery
**Priority**: Medium

Analyse and standardise cross-document reference patterns used throughout CIG system documentation, templates, and command files.

**Problem**: Currently inconsistent patterns for referencing other documents:
- Templates use bold text: `**See e-testing.md for complete test plan**`
- Some locations may use markdown links: `[text](path)`
- Some locations may use HTML comments
- No clear guidelines on when to use which pattern

**Scope**:
1. **Audit existing patterns**: Survey all templates, command files, and documentation for cross-reference patterns
2. **Categorise use cases**: Different contexts may need different patterns (intra-task vs external, LLM-facing vs human-facing)
3. **Define standard patterns**: Establish clear guidelines for each use case
4. **Document rationale**: Explain why each pattern is used (progressive disclosure, readability, tooling support)
5. **Update style guide**: Document patterns in `.cig/docs/` for future reference
6. **Migration plan**: Optionally create plan to standardise existing references

**Examples to analyse**:
- Intra-task references: `d-implementation.md` → `e-testing.md`
- External doc references: Templates → `workflow-steps.md`
- Config references: Command files → `cig-project.json`

**Outcome**: Clear, documented standard for cross-document references that follows DRY and progressive disclosure principles.

---

## Task: Remove Decomposition Checks from Non-Planning Workflow Steps

**Task-Type**: chore
**Priority**: Medium

Remove decomposition check steps from all workflow command files except cig-plan.md, as decomposition decisions should only be made during the planning phase.

**Problem**: Currently, all workflow command files (cig-requirements, cig-design, cig-implementation, cig-testing, cig-rollout, cig-maintenance, cig-retrospective) include "Step 7: Check Decomposition Signals" which:
- Creates confusion about when to decompose tasks
- Adds unnecessary cognitive load during execution phases
- Violates single-responsibility principle (planning decisions during execution)
- Decomposition decisions should be made once during planning, not reconsidered at every workflow step

**Solution**: Remove "Check Decomposition Signals" step from all workflow commands except cig-plan.md

**Scope**:
1. **Audit**: Verify which command files currently include decomposition checks
2. **Update commands**: Remove Step 7 (decomposition checks) from:
   - `.claude/commands/cig-requirements.md`
   - `.claude/commands/cig-design.md`
   - `.claude/commands/cig-implementation.md`
   - `.claude/commands/cig-testing.md`
   - `.claude/commands/cig-rollout.md`
   - `.claude/commands/cig-maintenance.md`
   - `.claude/commands/cig-retrospective.md`
3. **Keep in planning**: Retain decomposition checks in `.claude/commands/cig-plan.md` (where they belong)
4. **Update step numbers**: Renumber subsequent steps after removing Step 7
5. **Update documentation**: Clarify in workflow-steps.md that decomposition is a planning-phase decision

**Rationale**: Decomposition is a planning decision that should be made once upfront, not reconsidered during each workflow phase. This simplifies workflow steps and makes the planning phase the clear decision point for task breakdown.

---

## Task: Rollout Task 11 - Secure Argument Parsing

**Task-Type**: chore
**Priority**: High

Deploy the updated CIG command files with secure argument parsing pattern. All 8 workflow commands (cig-plan, cig-requirements, cig-design, cig-implementation, cig-testing, cig-rollout, cig-maintenance, cig-retrospective) have been updated with LLM-level format validation to prevent command injection. Changes are currently on local branch `bugfix/11-only-pass-needed-args-to-scripts`. Rollout involves creating PR, merging to main, and monitoring for any issues in production usage.

---

## Task: Security Review and Hardening of CIG Bash Invocations

**Task-Type**: discovery
**Priority**: Medium

Comprehensive security review and hardening of all bash invocations in the CIG system to prevent command injection vulnerabilities. Task 11 revealed that LLM-level validation is critical for security.

**Scope**:
1. **Systematic review**: Audit all command files (`.claude/commands/cig-*.md`), helper scripts, and workflow documentation for places where user input reaches bash
2. **Fix vulnerabilities**: Apply secure argument parsing pattern to any vulnerable commands (known candidates: cig-subtask.md, cig-status.md)
3. **Complete testing**: Run TC-8 testing coverage for all commands (8 workflow commands + cig-subtask + cig-status) with special character patterns (quotes, backticks, shell metacharacters)
4. **Document threat model**: Create comprehensive threat model with attack scenarios, existing defenses, and mitigation strategies

**Related to**: Task 11 (secure argument parsing pattern implementation)

---

## Task: Extract CIG Argument Validation Pattern to Documentation

**Task-Type**: feature
**Priority**: Needs-Triage

Create reusable documentation for the secure argument parsing pattern developed in Task 11. This pattern (LLM validates format → extracts arguments → invokes bash with literals) prevents command injection and handles arbitrary user input safely. Should be documented in `.cig/docs/` for use in future CIG commands or similar systems. Include: (1) Security model explanation, (2) Format validation regex patterns, (3) Example implementation, (4) Test scenarios.

---

## Task: Standardize Exit Codes to errno-Style Values

**Task-Type**: chore
**Priority**: Low

Consolidate exit codes across all CIG helper scripts to use errno-compatible values for better semantic meaning and consistency. Currently, exit codes are inconsistent across scripts (e.g., exit 3 means "Missing required argument" in hierarchy-resolver but "No parent tasks" in context-inheritance). Proposed standard:
- 0 = Success
- 2 = ENOENT (No such file or directory) - for "not found" errors
- 13 = EACCES (Permission denied) - for permission errors
- 22 = EINVAL (Invalid argument) - for validation errors

Scripts to update: hierarchy-resolver, context-inheritance, status-aggregator, format-detector, template-version-parser, and any future helper scripts. Update documentation in script headers and `.cig/docs/` to reflect standard.

---

## Task: Improve status-aggregator Error Message Clarity

**Task-Type**: chore
**Priority**: Low

Improve error message in `status-aggregator` to clarify that it expects a task number (e.g., "17", "1.2.3"), not a full file path. Current error "Invalid task path format: 17-feature-new-helper-script-to-setup-templates-for-new-task" is confusing because users might provide the directory name or full path. Updated error should say something like "Error: Invalid task number format. Expected decimal notation (e.g., '17', '1.2', '1.2.3'), not a file path or directory name." This improves usability by helping users understand the correct input format immediately.

---

## Task: Fix d-implementation.md Template to Reference e-testing.md

**Task-Type**: chore
**Priority**: Low

Remove duplicate "Test Coverage" and "Validation Criteria" sections from d-implementation.md template and replace with static reference to e-testing.md. Currently the d-implementation.md template (`.cig/templates/pool/d-implementation.md.template`) contains:
1. **Line 67-70**: "Test Coverage" section with placeholder test cases
2. **Line 72-76**: "Validation Criteria" section with test-related checkboxes

**Problem**: This creates confusion about where tests belong and duplicates content between d-implementation.md and e-testing.md. The testing phase (e-testing.md) should be the single source of truth for test strategy, test cases, and validation criteria.

**Solution**:
1. Verify all 5 task types (feature, bugfix, hotfix, chore, discovery) use e-testing.md.template (VERIFIED: all include it)
2. Replace "Test Coverage" section with: "**See e-testing.md for complete test plan**"
3. Replace "Validation Criteria" with: "**See e-testing.md for validation criteria and test results**"
4. Keep "Implementation Steps" as-is (includes Step 3: Testing and Step 5: Validation which reference executing the tests defined in e-testing.md)
5. Update any existing tasks using the old template pattern (consider migration script or manual update)

**Rationale**: Maintains single source of truth for testing, eliminates confusion about workflow phase responsibilities, and follows DRY principle.

---

## Task: Update cig-status to Use --workflow Flag

**Task-Type**: feature
**Priority**: Medium

Update `.claude/commands/cig-status.md` to use `status-aggregator --workflow <task-path>` for detailed workflow phase visibility when showing a specific task.

**Problem**: Currently, cig-status shows overall progress percentage but doesn't break down which workflow phases (a-plan, b-requirements, c-design, etc.) are completed vs pending. The status-aggregator script already supports a `--workflow` flag that provides this detailed view, but cig-status doesn't use it.

**Solution**: Update cig-status command to:
1. Use `status-aggregator <task-path>` for hierarchical tree view (current behavior)
2. Use `status-aggregator --workflow <task-path>` for detailed workflow phase breakdown when showing a single task
3. Display both views for single-task queries to provide comprehensive status

**Example output**:
```
Task Progress:
+ 21 (feature): retrospective-structure-and-flow-improvments - 25%

Workflow Status:
  ✓ a-plan.md: Finished
  ○ b-requirements.md: Backlog
  ○ c-design.md: Backlog
  ○ d-implementation.md: Backlog
  ...
```

**Scope**:
- Update `.claude/commands/cig-status.md` to call status-aggregator with --workflow flag
- Add workflow status display to output format
- Update documentation and examples

**Rationale**: Provides better visibility into which specific workflow phases are complete, making it easier to understand task progress and identify next steps.

---

## Task: Implement Current Task Tracking

**Task-Type**: feature
**Priority**: High

Implement a system to track the "current task" being worked on, allowing CIG commands and scripts to default to this task when no task number is explicitly provided.

**Problem**: Currently, all cig-* workflow commands require explicit task numbers (e.g., `/cig-implementation 21`). This becomes repetitive when working on the same task through multiple workflow phases. Users must remember and re-type the task number for each command.

**Solution**: Track the current task in a deterministic location that both LLM prompts and helper scripts can read.

**Design Considerations**:

1. **Storage Location**:
   - Option A: `.cig/current-task` (simple text file with task number)
   - Option B: Add to `cig-project.json` config
   - Recommendation: `.cig/current-task` for simplicity and determinism

2. **File Format**:
   ```
   21
   ```
   (Just the task number, one line, no formatting)

3. **Git Handling**:
   - Add `.cig/current-task` to `.gitignore` (user-specific workspace state)
   - Each developer can work on different tasks

4. **Commands Needed**:
   - Automatic: Set current task when running `/cig-new-task` or `/cig-subtask`
   - Manual: `/cig-current [task-path]` - set/view/clear current task
   - All workflow commands default to current task if no argument provided

5. **Workflow Command Updates**:
   All 8 workflow commands should:
   - Check if argument provided → use it (and set as current task)
   - If no argument → read `.cig/current-task`
   - If neither → error with helpful message
   - **Automatic current task setting**: When any workflow command is invoked with an explicit task number, set that as the current task
   - **Special case**: `/cig-retrospective` should clear current task after successful completion (task is finished)

6. **Script Integration**:
   Helper scripts can read `.cig/current-task` for deterministic current task value

**Scope**:
- Create `.cig/current-task` tracking mechanism
- Add `.cig/current-task` to `.gitignore`
- Create `/cig-current` command for manual set/view/clear
- Update `/cig-new-task` to set current task automatically
- Update `/cig-subtask` to set current task automatically
- Update all 8 workflow commands (cig-plan, cig-requirements, cig-design, cig-implementation, cig-testing, cig-rollout, cig-maintenance, cig-retrospective) to use current task as default
- Update `/cig-status` to highlight current task in output
- Document current task tracking in `.cig/docs/`

**Example Usage**:
```bash
# Create new task and it becomes current
/cig-new-task 22 feature "Add export functionality"

# Work through workflow without repeating task number
/cig-plan           # Uses task 22
/cig-requirements   # Uses task 22
/cig-design         # Uses task 22
/cig-implementation # Uses task 22
/cig-testing        # Uses task 22

# Check current task
/cig-current        # Shows: Current task: 22

# Switch to different task
/cig-current 21     # Now working on task 21

# Clear current task
/cig-current --clear
```

**Benefits**:
- Reduces repetition when working through workflow phases
- Improves UX by making commands more ergonomic
- Deterministic storage ensures scripts can reliably use current task
- Automatic tracking on task creation reduces manual steps

**Rationale**: Current task tracking significantly improves developer experience by eliminating repetitive task number arguments while maintaining deterministic behavior for scripts.

---

## Task: Fix CIG Commands to Work from Any Directory

**Task-Type**: bugfix
**Priority**: High

Fix CIG workflow commands to work regardless of current working directory. Currently, commands fail when executed from subdirectories because they use relative paths (`.cig/scripts/...`) that only work from repository root.

**Problem**: When working in a task subdirectory (e.g., `implementation-guide/21-feature-...`), running `/cig-new-task` or other commands fails with:
```
Error: .cig/scripts/command-helpers/cig-load-project-config: No such file or directory
```

This breaks the workflow when Claude is in a task directory after completing previous phases.

**Solution Options**:

**Option A: Dynamic Git Root Detection**
- Commands find git root dynamically using `git rev-parse --show-toplevel`
- Convert all relative paths to absolute paths based on git root
- Pros: Works from any directory, no directory changes needed
- Cons: Requires git, adds complexity to every command

**Option B: Explicit CD to Git Root**
- Commands explicitly `cd` to git root at start
- Echo new working directory so LLM maintains context
- Pros: Simple, matches existing relative path assumptions
- Cons: Changes working directory (must communicate to LLM)

**Recommended Approach**: Option B with clear communication
```bash
# At start of each CIG command
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
    echo "Error: Not in a git repository"
    exit 1
fi

cd "$GIT_ROOT"
echo "Working directory: $GIT_ROOT"
```

**Scope**:
- Update all CIG workflow commands (cig-plan, cig-requirements, cig-design, cig-implementation, cig-testing, cig-rollout, cig-maintenance, cig-retrospective)
- Update utility commands (cig-new-task, cig-subtask, cig-status, cig-extract, cig-config, cig-init)
- Add git root detection to command templates
- Document working directory behavior in `.cig/docs/`

**Testing**:
- Run commands from repository root (should work as before)
- Run commands from task subdirectories (should work after fix)
- Run commands from outside repository (should fail with clear error)

**Rationale**: CIG commands should work reliably regardless of where Claude's current working directory is, preventing workflow interruptions and improving user experience.

---

## Task: Create Slug Generator Helper Script

**Task-Type**: chore
**Priority**: Medium

Extract slug generation logic from cig-new-task and cig-subtask commands into a dedicated helper script for consistency and reusability.

**Problem**: Currently, slug generation is implemented inline in command files using bash pipeline:
```bash
echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 -]//g' | tr ' ' '-' | sed 's/--*/-/g' | cut -c1-50
```

This creates several issues:
- Logic duplicated across cig-new-task and cig-subtask commands
- No single source of truth for slug generation algorithm
- Difficult to test slug generation independently
- Changes require updating multiple command files
- Inconsistent with other CIG helpers (template-copier, hierarchy-resolver, etc.)

**Solution**: Create `.cig/scripts/command-helpers/slug-generator.pl` (or similar) following the pattern of existing helper scripts.

**Interface**:
```bash
slug-generator.pl "Description Text Here"
# Output: description-text-here
```

**Slug Generation Algorithm**:
1. Convert to lowercase
2. Remove special characters (keep only alphanumeric, spaces, hyphens)
3. Replace spaces with hyphens
4. Collapse multiple consecutive hyphens to single hyphen
5. Trim leading/trailing hyphens
6. Truncate to 50 characters maximum
7. Ensure result doesn't end mid-word (optional: break at last hyphen if truncated)

**Scope**:
1. Create `.cig/scripts/command-helpers/slug-generator.pl`
2. Implement slug generation algorithm matching current behavior
3. Add proper error handling (empty input, invalid characters, etc.)
4. Set executable permissions (u+rx, minimum 0500)
5. Update `.cig/commands/cig-new-task.md` to use helper script
6. Update `.cig/commands/cig-subtask.md` to use helper script
7. Add to `.cig/security/script-hashes.json` for integrity verification
8. Document in `.cig/docs/` if needed

**Testing**:
- Empty string → error
- Simple text: "Add User Auth" → "add-user-auth"
- Special characters: "Fix bug #123 (urgent!)" → "fix-bug-123-urgent"
- Long text (>50 chars): "This is a very long description that exceeds fifty characters" → "this-is-a-very-long-description-that-exceeds-f"
- Unicode/accented characters: "Café résumé" → "caf-rsum" (strip non-ASCII)
- Multiple spaces/hyphens: "Add   User---Auth" → "add-user-auth"

**Benefits**:
- Single source of truth for slug generation
- Consistent slugs across all commands
- Easier to test and modify algorithm
- Follows CIG helper script pattern (deterministic, scriptable)
- Can be used by other tools or scripts in future

**References**:
- Current implementation: `.claude/commands/cig-new-task.md` (inline bash pipeline)
- Similar pattern: `template-copier`, `hierarchy-resolver` (deterministic helpers)

**Rationale**: Extracting slug generation to a dedicated helper script improves maintainability, testability, and consistency across CIG commands. Follows the established pattern of using Perl helper scripts for deterministic operations.

---

## Task: Clarify That Requirements and Design Are Planning Steps

**Task-Type**: chore
**Priority**: High

Make it explicit that cig-plan, cig-requirements, and cig-design are ALL planning steps (not execution) in documentation and command files.

**Problem**: LLM confusion about what constitutes "planning" vs "execution":
- cig-plan, cig-requirements, cig-design are all planning activities
- LLM incorrectly assumes only cig-plan is planning, treats cig-requirements and cig-design as execution
- When plan mode is active and user runs `/cig-requirements`, LLM sees conflict: "plan mode says don't edit, but requirements wants me to edit b-requirements.md"
- This causes frustrating user experience where LLM asks "should I exit plan mode?" when the answer is obviously "no, requirements IS planning"

**Root Cause**: Documentation doesn't make it sufficiently explicit that requirements and design are planning phases.

**Solution**: Improve documentation explicitness

**Note**: Skills CAN trigger plan mode programmatically, so planning phase skills can auto-enter plan mode. This should be implemented during skills migration (separate task).

### Documentation Updates

**1. Update workflow-steps.md**:
- Add prominent section at top: "Planning Phases vs Execution Phases"
- Explicitly list: "Planning phases: cig-plan, cig-requirements, cig-design"
- Explicitly list: "Execution phases: cig-implementation, cig-testing, cig-rollout, cig-maintenance, cig-retrospective"
- Explain: Planning = deciding WHAT and WHY, Execution = doing HOW
- Add to each planning phase documentation: "**This is a PLANNING phase** - you are deciding what to build, not building it"

**2. Update command files (cig-requirements.md, cig-design.md)**:
- Add prominent note at top: "⚠️ PLANNING PHASE: You are defining requirements/design, not implementing them"
- Add to "Focus on" section: Reminder that this is planning, not execution
- Add to "Avoid" section: Reminder not to implement, only to plan

**3. Update workflow phase descriptions**:
Current language may be ambiguous:
- cig-requirements: "Define what the system must do" ← could be interpreted as execution
- Better: "PLAN what the system must do (define requirements, not implement them)"

### Scope
1. Update `.cig/docs/workflow/workflow-steps.md`:
   - Add "Planning vs Execution Phases" section at top
   - Update Planning, Requirements, Design sections with explicit "PLANNING PHASE" labels
2. Update `.claude/commands/cig-requirements.md`:
   - Add ⚠️ PLANNING PHASE notice
   - Update Focus/Avoid sections with planning reminders
3. Update `.claude/commands/cig-design.md`:
   - Add ⚠️ PLANNING PHASE notice
   - Update Focus/Avoid sections with planning reminders
4. Update `.claude/commands/cig-plan.md`:
   - Already mostly clear, but reinforce with consistent labeling

### Testing
- Run `/cig-requirements` while in plan mode → LLM should recognize it's planning, not ask to exit plan mode
- Run `/cig-design` while in plan mode → same behavior
- Verify documentation clearly states which phases are planning vs execution

### Success Criteria
- [ ] workflow-steps.md has "Planning vs Execution" section at top
- [ ] All 3 planning phases (plan, requirements, design) labeled as "PLANNING PHASE"
- [ ] All 3 planning command files have ⚠️ PLANNING PHASE notices
- [ ] LLM correctly recognizes requirements and design as planning (no more "should I exit plan mode?" questions)

### Priority Justification

**High Priority** because:
- **User frustration**: "very frustrating for users" per user feedback
- **Workflow blocker**: Confusion interrupts workflow, requires user clarification
- **Core functionality**: Planning is fundamental to CIG, must be unambiguous
- **Quick fix available**: Documentation changes can be done quickly to address immediate pain

**Rationale**: LLM misunderstanding of what constitutes "planning" creates friction in CIG workflow. Clear documentation provides immediate relief. Plan mode auto-triggering can be implemented later during skills migration.

---

## Task: Add Re-Execution Detection to Implementation and Testing Exec Commands

**Task-Type**: feature
**Priority**: High
**Status**: Discovered in Task 26 (re-running implementation-exec after plan was revised)

Add logic to cig-implementation-exec and cig-testing-exec commands to detect when they're being re-executed and assess what changed in the plan so that only necessary steps are re-executed.

**Problem**: When execution steps (e-implementation-exec.md, g-testing-exec.md) are re-visited after plan changes:
- LLM doesn't know if this is first execution or re-execution
- No clear guidance on what changed in the plan since last execution
- Risk of false blockers ("plan is outdated") when execution file just needs updating
- Risk of blindly re-executing everything when only some steps changed

**Scenario (from Task 26)**:
1. User ran `/cig-implementation-exec 26`
2. LLM saw execution file had OLD results from reverted implementation
3. LLM incorrectly called this a BLOCKER ("plan is outdated")
4. User had to manually re-run `/cig-implementation-plan 26` to "update" an already-correct plan
5. Wasted time in circular navigation

**What LLM Should Have Done**:
1. Detect: "Execution file has old results, but let me check if the plan changed"
2. Read implementation plan (d-implementation-plan.md)
3. Compare: Plan version/timestamp vs execution file results
4. Decision:
   - If plan unchanged → Clear old results, start executing from Step 1
   - If plan changed → Identify what changed, determine which steps need re-execution
   - If plan is missing/invalid → THEN it's a real blocker

**Solution**: Add re-execution detection logic to exec commands

### Implementation Approach

**For cig-implementation-exec.md**:

Add step before "Execute Implementation Workflow":

```markdown
## Re-Execution Detection

**Check if this is a re-visit**:
1. Read e-implementation-exec.md (this file)
2. Check if "Actual Results" section has content
3. If YES → This is re-execution, assess what changed

**Assess Changes**:
1. Read d-implementation-plan.md
2. Compare plan version/last-modified with execution file timestamp
3. Identify what changed:
   - New files to modify?
   - New steps added?
   - Steps re-ordered?
   - Code changes updated?

**Determine Re-Execution Strategy**:
- **If plan unchanged**: Clear old results, execute all steps fresh
- **If plan has minor changes**: Document changes, execute only affected steps
- **If plan has major changes**: Clear all results, start from Step 1
- **If plan is missing/invalid**: BLOCKER - revert to implementation planning

**NOT a Blocker**:
- Execution file having old results is NOT a blocker by itself
- Only a blocker if plan is invalid/missing or fundamentally incompatible with current architecture
```

**For cig-testing-exec.md**:

Similar logic but check f-testing-plan.md for changes:
- Test cases added/removed?
- Test environment changed?
- Validation criteria updated?

### Commands to Update

**Primary**:
- `.claude/commands/cig-implementation-exec.md` (v2.1 only)
- `.claude/commands/cig-testing-exec.md` (v2.1 only)

**Note**: cig-implementation.md and cig-testing.md don't need this (they're planning, not execution)

### Detection Criteria

**Indicators of Re-Execution**:
1. Execution file has content in "Actual Results" section
2. Execution file has "Status: Implemented" or "Status: Testing" (not "Backlog")
3. Execution file timestamp < plan file timestamp (plan changed after last execution)

**Indicators this is First Execution**:
1. Execution file says "Status: Backlog"
2. "Actual Results" section is empty or has placeholder text
3. No step completion markers (all checkboxes unchecked)

### Change Assessment

**What to Check in Implementation Plan**:
- Goal changed?
- Files to modify changed?
- Implementation steps changed (added, removed, reordered)?
- Code changes updated (different approach)?

**What to Check in Testing Plan**:
- Test strategy changed?
- Test cases added/removed?
- Validation criteria changed?
- Test environment requirements changed?

### Scope

1. **Update cig-implementation-exec command**:
   - Add re-execution detection step
   - Add change assessment logic
   - Document strategy decision tree
   - Clarify what IS and IS NOT a blocker

2. **Update cig-testing-exec command**:
   - Add re-execution detection step
   - Add change assessment logic
   - Document strategy decision tree
   - Clarify what IS and IS NOT a blocker

3. **Update execution templates** (e-implementation-exec.md, g-testing-exec.md):
   - Add "Previous Execution" section to track what was done before
   - Add "Plan Changes" section to document what changed since last execution
   - Make it clear when results are from OLD execution vs NEW execution

4. **Update documentation**:
   - Document re-execution handling in workflow-steps.md
   - Explain difference between "old results exist" (NOT a blocker) vs "plan is invalid" (IS a blocker)

### Success Criteria

- [ ] cig-implementation-exec detects re-execution correctly
- [ ] cig-implementation-exec assesses plan changes correctly
- [ ] cig-implementation-exec only re-executes changed steps (not everything)
- [ ] cig-testing-exec has same capabilities
- [ ] False blockers eliminated ("old results exist" doesn't trigger blocker)
- [ ] Real blockers still caught (invalid/missing plan)
- [ ] Execution files track previous vs current execution

### Benefits

**User Experience**:
- No more circular navigation (implement → block → replan → implement)
- Clear understanding of what changed and what needs re-execution
- Faster re-execution (only changed steps, not everything)

**LLM Behavior**:
- Smarter detection of re-execution vs first execution
- Better assessment of what constitutes a real blocker
- More efficient execution (skip unchanged steps)

**Workflow Integrity**:
- Preserves previous execution results for reference
- Documents what changed between executions
- Maintains audit trail of execution history

### Priority Justification

**High Priority** because:
- **User frustration**: Circular navigation wastes time and is frustrating
- **Workflow efficiency**: Re-executing unchanged steps is inefficient
- **False blockers**: Current behavior creates false blockers that interrupt workflow
- **Common scenario**: Plan revisions are normal during implementation, should be handled gracefully

**Rationale**: Execution commands should be smart about re-execution. Having old results is NOT a blocker - it's normal when plans are revised. Only missing/invalid plans are real blockers. This task adds the intelligence to distinguish between these cases and handle re-execution efficiently.

**Discovered**: During Task 26 when re-running `/cig-implementation-exec 26` after updating implementation plan to new architecture. LLM incorrectly flagged as blocker when execution file just needed clearing/updating.

---

## Task: Implement Interface-Based Version Dispatch for status-aggregator

**Task-Type**: refactor
**Priority**: Medium
**Status**: Discovered in Task 26 (TC-F11 test failure)

Refactor status-aggregator to use interface-based version dispatch pattern instead of separate version-specific scripts, enabling proper workflow display for mixed-version projects.

**Problem**: `status-aggregator --workflow` doesn't show workflow breakdown for all tasks in mixed-version projects.

**Current Behavior**:
```bash
# Project has Tasks 1-25 (v2.0) and Task 26 (v2.1)
status-aggregator --workflow

# Result: Only Task 26 shows workflow breakdown
# Tasks 1-25 show no workflow files
```

**Expected Behavior**: All tasks should show workflow breakdown with their respective version-specific files:
- v2.0 tasks: 8 workflow files (a,b,c,d,f,h,i,j - skips e,g)
- v2.1 tasks: 10 workflow files (a-j)

**Root Cause**: Version detection happens ONCE at trampoline level, not per-task
1. Trampoline detects version globally (finds ANY v2.1 file → routes to v2.1 script)
2. Routes to single version-specific script (status-aggregator-v2.0 or v2.1)
3. That script processes ALL tasks using its hardcoded version logic
4. v2.1 script can't find workflow files for v2.0 tasks (tries to find 10 files that don't exist)

**Affected Test Case**: TC-F11 from Task 26 testing plan - currently marked as "KNOWN LIMITATION"

### Solution: Interface-Based Dispatch Pattern

Implement Go-style interface pattern using Perl dispatch tables:

**Key Insight**: "The modules know about versions, the scripts shouldn't have to."

#### Architecture

```perl
# CIG::WorkflowFiles::Dispatch
package CIG::WorkflowFiles::Dispatch;

use strict;
use warnings;
use CIG::WorkflowFiles::V20;
use CIG::WorkflowFiles::V21;

# Dispatch table - each version implements the same interface
our %DISPATCH = (
    '2.0' => {
        list_wf_steps => sub {
            my ($opts) = @_;
            # v2.0 specific workflow file listing
            return CIG::WorkflowFiles::V20::get_workflow_files(
                $opts->{task_dir},
                $opts->{task_type}
            );
        },

        get_task_progress => sub {
            my ($opts) = @_;
            # v2.0 specific progress calculation
        },

        format_output => sub {
            my ($opts) = @_;
            # v2.0 specific formatting
        },
    },

    '2.1' => {
        list_wf_steps => sub { ... },
        get_task_progress => sub { ... },
        format_output => sub { ... },
    },
);

# Get dispatch table for a version
sub get_dispatch {
    my ($version) = @_;
    return $DISPATCH{$version} or die "Unsupported version: $version";
}

# Validate all versions implement required interface
my @REQUIRED_OPERATIONS = qw(list_wf_steps get_task_progress format_output);

sub validate_interfaces {
    for my $version (keys %DISPATCH) {
        for my $op (@REQUIRED_OPERATIONS) {
            die "Version $version missing operation: $op"
                unless exists $DISPATCH{$version}{$op};
        }
    }
}

validate_interfaces();  # Compile-time-ish checking
1;
```

#### Usage in Unified Script

```perl
# Single status-aggregator script (replaces v2.0 and v2.1 scripts)
use CIG::WorkflowFiles::Dispatch;

for my $task (@all_tasks) {
    # Detect version PER TASK
    my $version = detect_task_version($task->{dir});

    # Get version-specific operations (interface dispatch)
    my $ops = CIG::WorkflowFiles::Dispatch::get_dispatch($version);

    # Call through interface - version-agnostic!
    my @wf_files = $ops->{list_wf_steps}({
        task_dir  => $task->{dir},
        task_type => $task->{type},
        limit     => $opts->{limit},
        workflow  => $opts->{workflow},
        sort      => $opts->{sort},
        order     => $opts->{order},
    });

    if ($opts->{workflow}) {
        my $progress = $ops->{get_task_progress}({
            workflow_files => \@wf_files,
            task_dir       => $task->{dir},
        });

        $ops->{format_output}({
            task          => $task,
            workflow_files => \@wf_files,
            progress      => $progress,
        });
    }
}
```

### Implementation Steps

1. **Create `CIG::WorkflowFiles::Dispatch` module**
   - Define interface (required operations: list_wf_steps, get_task_progress, format_output)
   - Build dispatch table for v2.0 and v2.1
   - Add interface validation

2. **Refactor version-specific modules**
   - Extract logic from status-aggregator-v2.0 into V20 module operations
   - Extract logic from status-aggregator-v2.1 into V21 module operations
   - Ensure both implement complete interface

3. **Create unified status-aggregator script**
   - Replace separate v2.0/v2.1 scripts with single version-agnostic script
   - Use per-task version detection + dispatch
   - Preserve all existing flags and behavior

4. **Update trampoline**
   - Simplify or remove version detection (now handled per-task)
   - Route to unified script instead of version-specific scripts

5. **Testing**
   - Verify TC-F11 passes (mixed-version workflow display)
   - Regression test all existing functionality
   - Test with v2.0-only, v2.1-only, and mixed projects

### Benefits

1. **Fixes TC-F11**: `--workflow` works correctly for mixed-version projects
2. **Go-like interfaces**: Each version MUST implement required operations
3. **Version-agnostic scripts**: No version conditionals in orchestration code
4. **Easy version addition**: Add v2.2 by adding dispatch table entry only
5. **Better modularity**: Version logic in version modules, dispatch in dispatch module
6. **Testability**: Can inject mock dispatch for testing, validate interface compliance

### Success Criteria

- [ ] TC-F11 passes: `status-aggregator --workflow` shows workflow for all tasks
- [ ] All existing tests continue passing (no regressions)
- [ ] Single unified status-aggregator script (no v2.0/v2.1 split)
- [ ] Interface validation ensures version compliance at load time
- [ ] Code reduction (eliminate duplication between v2.0/v2.1 scripts)

### Files to Create/Modify

**Create**:
- `.cig/lib/CIG/WorkflowFiles/Dispatch.pm` - Interface dispatch module

**Modify**:
- `.cig/lib/CIG/WorkflowFiles/V20.pm` - Add operations to match interface
- `.cig/lib/CIG/WorkflowFiles/V21.pm` - Add operations to match interface
- `.cig/scripts/command-helpers/status-aggregator` - Simplify or unify
- `.cig/scripts/command-helpers/status-aggregator-v2.0` - Refactor or remove
- `.cig/scripts/command-helpers/status-aggregator-v2.1` - Refactor or remove

### Scope Note

This is a **significant refactor** touching the core status aggregation architecture. Estimate: 8-16 hours for experienced Perl developer.

**Not in scope for Task 26** due to:
- Size/complexity (would delay current feature)
- Requires careful testing with multiple version scenarios
- Current workaround acceptable (use task-specific queries)

### Priority Justification

**Medium Priority** because:
- **Primary use case works**: Task-specific queries (`/cig-status 26`) work correctly
- **Workaround exists**: Use explicit task paths instead of `--workflow` alone
- **Edge case impact**: Only affects `--workflow` without task argument in mixed-version projects
- **Quality improvement**: Reduces code duplication, improves architecture
- **Future-proofing**: Makes version additions easier (v2.2, v2.3, etc.)

**Not High Priority** because:
- Not blocking current work
- Has documented workaround
- Affects power-user feature, not core functionality

**Discovered**: During Task 26 testing execution (TC-F11) when validating `status-aggregator --workflow` behavior with mixed v2.0/v2.1 project.

---

## Task: Fix v2.1 Template File Ordering to Match Logical Workflow

**Task-Type**: bugfix
**Priority**: High
**Status**: Discovered in Task 26 (template ordering inconsistency with workflow logic)

Rename v2.1 template files to match the logical workflow order: all planning phases before execution phases.

**Problem**: Current v2.1 template naming interleaves planning and execution phases incorrectly.

**Current (Incorrect) Order**:
```
d-implementation-plan.md    (Planning)
e-implementation-exec.md    (Execution) ← WRONG: executes before testing is planned
f-testing-plan.md           (Planning)  ← WRONG: plans after implementation executes
g-testing-exec.md           (Execution)
```

**Correct Order Should Be**:
```
d-implementation-plan.md    (Planning)
e-testing-plan.md           (Planning)  ← Plan testing BEFORE executing anything
f-implementation-exec.md    (Execution) ← Execute implementation
g-testing-exec.md           (Execution) ← Execute testing
```

**Rationale**:
- Workflow best practice: Complete all planning phases before execution
- Current order forces implementation execution before testing is planned
- Logical sequence: Plan → Plan → Execute → Execute, not Plan → Execute → Plan → Execute
- Matches natural work progression: understand what to build AND how to test it, then build it, then test it

### Impact

**Current Template Order Creates Confusion**:
- Users complete d-implementation-plan, then are directed to e-implementation-exec
- They execute implementation without having planned testing approach
- Testing plan (f-testing-plan) comes AFTER implementation is done
- This is backwards from proper workflow

**Affects**:
- `.cig/templates/pool/` - Template file names
- `CIG::WorkflowFiles::V21` - File list definitions
- All existing v2.1 tasks (currently just Task 26)
- Future v2.1 tasks

### Solution

Rename template files to correct logical order:

**Step 1: Rename Templates in Pool**
```bash
# In .cig/templates/pool/
mv e-implementation-exec.md.template e-testing-plan.md.template.tmp
mv f-testing-plan.md.template f-implementation-exec.md.template.tmp
mv e-testing-plan.md.template.tmp f-implementation-exec.md.template
mv f-implementation-exec.md.template.tmp e-testing-plan.md.template

# Result:
# d-implementation-plan.md.template
# e-testing-plan.md.template (was f)
# f-implementation-exec.md.template (was e)
# g-testing-exec.md.template (unchanged)
```

**Step 2: Update V21 Module**
```perl
# In .cig/lib/CIG/WorkflowFiles/V21.pm
our %WORKFLOW_FILES = (
    feature => [
        'a-task-plan.md',
        'b-requirements-plan.md',
        'c-design-plan.md',
        'd-implementation-plan.md',
        'e-testing-plan.md',          # CHANGED: was f
        'f-implementation-exec.md',   # CHANGED: was e
        'g-testing-exec.md',
        'h-rollout.md',
        'i-maintenance.md',
        'j-retrospective.md',
    ],
    # ... update other task types similarly
);
```

**Step 3: Update Documentation**
- `.cig/lib/CIG/WorkflowFiles/V21.pm` POD documentation
- `.cig/docs/workflow/workflow-steps.md` if it references specific file names
- Any other docs mentioning v2.1 file order

**Step 4: Migrate Existing v2.1 Tasks**

Task 26 files need renaming:
```bash
cd implementation-guide/26-feature-update-cig-status-to-use-workflow-flag/
mv e-implementation-exec.md e-implementation-exec.md.old
mv f-testing-plan.md e-testing-plan.md
mv e-implementation-exec.md.old f-implementation-exec.md
mv g-testing-exec.md g-testing-exec.md.tmp
mv g-testing-exec.md.tmp g-testing-exec.md
```

**Step 5: Update Internal References**

Update any file that references specific v2.1 file names:
- Task 26 workflow files (cross-references between files)
- Command files that might reference specific phases
- Scripts that might hardcode file names (check status-aggregator, etc.)

### Testing

- [ ] Verify all template files renamed correctly in pool
- [ ] Verify V21 module returns correct file lists
- [ ] Verify Task 26 files renamed and still readable
- [ ] Verify status-aggregator shows correct file order for Task 26
- [ ] Create new v2.1 task to verify templates work correctly
- [ ] Verify no broken references in documentation

### Success Criteria

- [ ] Template pool has correct file order (d, e-testing, f-impl, g)
- [ ] V21 module reflects correct order
- [ ] Task 26 files renamed to match
- [ ] All cross-references updated
- [ ] New v2.1 tasks created with correct file order
- [ ] Documentation accurate

### Root Cause

**Introduced By**: Task 25 - "Implement v2.1 workflow with planning/execution separation"

Task 25 implemented the v2.1 format with interleaved planning/execution order:
- Commit: `91b0202 Task 25: Implement v2.1 workflow with planning/execution separation`
- File: `implementation-guide/25-feature-separate-planning-from-execution-phases-with-expli/c-design.md`
- Design specified: d-impl-plan, e-impl-exec, f-test-plan, g-test-exec

**Why It Was Wrong**: The design focused on "separating planning from execution" but didn't consider the logical workflow order should be "all planning, then all execution" rather than "plan-execute-plan-execute".

### Priority Justification

**High Priority** because:
- **Workflow Logic Broken**: Forces implementation execution before test planning
- **Affects All Future v2.1 Tasks**: Every new v2.1 task will have wrong order
- **Migration Needed**: Task 26 already exists with wrong naming
- **Breaking Change**: Better to fix now before more v2.1 tasks exist
- **Template Pool Core**: Affects fundamental template structure

**Not Critical** because:
- Only affects v2.1 tasks (Task 26 is the only one currently)
- Doesn't break functionality, just ordering logic
- Can be fixed with file renames (no code changes)

**Discovered**: During Task 26 when reviewing template ordering and realizing execution happens before planning is complete.

---

## Task: Standardize Script Naming and Invocation (Remove Extensions)

**Task-Type**: refactor
**Priority**: Medium
**Status**: Discovered in Task 26 retrospective (reference brittleness pattern)

Remove file extensions from all CIG helper scripts and standardize invocation using portable shebangs with PERL5OPT environment configuration.

**Problem**: Current script naming is inconsistent and brittle:

**Inconsistent naming**:
```bash
# Scripts WITH extensions:
.cig/scripts/command-helpers/hierarchy-resolver
.cig/scripts/command-helpers/context-inheritance
.cig/scripts/command-helpers/template-copier
.cig/scripts/command-helpers/format-detector

# Scripts WITHOUT extensions:
.cig/scripts/command-helpers/status-aggregator
.cig/scripts/command-helpers/status-aggregator-v2.0
.cig/scripts/command-helpers/status-aggregator-v2.1
```

**Reference brittleness**:
- Command prompts reference "hierarchy-resolver"
- If rewritten in Python → becomes "hierarchy-resolver.py"
- All references break throughout system

**Shebang issues**:
- Currently use `#!/usr/bin/perl -CDSL` (hardcoded path)
- Or `#!/usr/bin/env perl` (can't pass flags)
- Need `-CDSL` flags for Unicode handling at execution time (before `use` statements)

**Implementation leakage**:
- `.pl` extension exposes implementation detail
- Users shouldn't care if script is Perl, Python, shell, or compiled binary
- Unix philosophy: executables are executables

## Solution: Unix Best Practices

### Step 1: Configure PERL5OPT in Claude Code

Add to `.claude/settings.json`:
```json
{
  "env": {
    "PERL5OPT": "-CDSL"
  }
}
```

**What `-CDSL` does**:
- `-C`: Enable Unicode support for streams
- `-D`: UTF-8 for default file I/O layer
- `-S`: UTF-8 for STDIN
- `-L`: UTF-8 for STDOUT/STDERR

This ensures Unicode handling before script execution (not after `use utf8`).

### Step 2: Standardize Shebangs

Change all Perl script shebangs:
```perl
# OLD (hardcoded path):
#!/usr/bin/perl -CDSL

# NEW (portable):
#!/usr/bin/env perl
```

**Benefit**: Flags come from `PERL5OPT`, shebang finds perl in PATH.

### Step 3: Remove Script Extensions

Rename all helper scripts:
```bash
cd .cig/scripts/command-helpers/

mv hierarchy-resolver hierarchy-resolver
mv context-inheritance context-inheritance
mv template-copier template-copier
mv format-detector format-detector
```

### Step 4: Update All References

**Files to update**:
1. `.claude/commands/*.md` - All command prompts that reference scripts
2. `CLAUDE.md` - Documentation references
3. `README.md` - Usage examples
4. This BACKLOG.md - Task descriptions
5. Any workflow templates that mention scripts
6. Git history documentation (note: references in committed tasks will be stale but acceptable)

**Search pattern**:
```bash
grep -r "hierarchy-resolver\.pl" .claude/
grep -r "context-inheritance\.pl" .claude/
grep -r "template-copier\.pl" .claude/
grep -r "format-detector\.pl" .claude/
```

### Step 5: Test Unicode Handling

Verify PERL5OPT works correctly:
```bash
# Test that flags are applied
perl -V | grep -i cdsl

# Test script execution with Unicode
echo "Testing: ñ ü 日本語" | .cig/scripts/command-helpers/hierarchy-resolver 1
```

## Implementation Checklist

- [ ] Add `PERL5OPT="-CDSL"` to `.claude/settings.json`
- [ ] Update all Perl shebangs to `#!/usr/bin/env perl`
- [ ] Rename all `.pl` scripts (remove extension)
- [ ] Update all command prompt references (*.md in .claude/commands/)
- [ ] Update CLAUDE.md documentation
- [ ] Update README.md examples
- [ ] Update BACKLOG.md task descriptions
- [ ] Test all scripts still execute correctly
- [ ] Test Unicode handling works (PERL5OPT applied)
- [ ] Verify no broken references remain

## Success Criteria

- [ ] All helper scripts have no file extensions
- [ ] All shebangs use `#!/usr/bin/env perl` (portable)
- [ ] PERL5OPT configured in `.claude/settings.json`
- [ ] All command prompts reference extensionless names
- [ ] Documentation updated (CLAUDE.md, README.md)
- [ ] Unicode test passes (scripts handle UTF-8 correctly)
- [ ] No grep hits for "*.pl" in command references

## Benefits

1. **Refactor-safe**: Can rewrite in any language without breaking references
2. **Unix philosophy**: Implementation hidden, interface stable
3. **Consistency**: All scripts follow same naming convention
4. **Portable**: `#!/usr/bin/env perl` finds perl in PATH
5. **Unicode-correct**: `-CDSL` flags applied at execution time
6. **Future-proof**: Tomorrow you could rewrite in Python/Go/Rust
7. **Team-wide**: Settings file ensures all Claude Code sessions get PERL5OPT

## Note: Templates Are Different

Template files keep `.template` extension because:
- They're **data files**, not executables
- Extension distinguishes templates from actual workflow files
- Never executed directly, always copied/processed
- Extension indicates "this is a template, not a real file"

So: `d-implementation-plan.md.template` stays as-is.

## Affected Components

**Scripts to rename** (4 files):
- `hierarchy-resolver` → `hierarchy-resolver`
- `context-inheritance` → `context-inheritance`
- `template-copier` → `template-copier`
- `format-detector` → `format-detector`

**Scripts already correct** (3 files):
- `status-aggregator` (already no extension)
- `status-aggregator-v2.0` (already no extension)
- `status-aggregator-v2.1` (already no extension)

**Command files to update** (~19 files):
- All files in `.claude/commands/cig-*.md`

**Documentation to update**:
- `CLAUDE.md` - Helper script references
- `README.md` - Usage examples
- `.cig/docs/workflow/` - Any script references

## Related Tasks

- **Research and Consolidate Cross-Document Reference Patterns** - This implements one standard (extensionless scripts)
- **Fix v2.1 Workflow File Order** - Both involve fixing reference consistency
- **Create version-detector helper** - Would be created without `.pl` extension

## Rationale

This is a **reference architecture improvement** that prevents brittleness:
- Current state: 50+ references to "hierarchy-resolver" break if script rewritten
- Future state: References to "hierarchy-resolver" work regardless of implementation
- Cost: ~2 hours to rename and update references
- Benefit: Permanent reduction in maintenance burden + consistency

**Discovered**: During Task 26 retrospective when analyzing file naming confusion pattern and discussing how to prevent reference brittleness across the CIG system.
