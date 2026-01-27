# CIG System Backlog

Future tasks and improvements for the Code Implementation Guide system.

---

---

## Task: Create Template Reference Linter for Pre-Commit Hook

**Task-Type**: chore
**Priority**: Medium
**Status**: Recommended from Task 29 retrospective

Create automated linter to detect hardcoded template filename references and verify they point to current template names.

**Problem**: Template filename references must be updated manually across codebase:
- No automated way to detect orphaned template filename references
- Manual grep required for verification (e.g., Task 29 found 60+ references)
- Risk of missing references during template changes
- Version-specific references (v2.0 vs v2.1) need distinction

**Solution**: Create `template-reference-linter` script:
- Detect hardcoded template filenames in `.md`, `.pl`, `.pm` files
- Verify references point to current template names (not deprecated)
- Distinguish v2.0 refs (acceptable in V20.pm) from v2.1 refs (should use new names)
- Run as pre-commit hook or CI check
- Report orphaned references with file:line information

**Benefits**:
- Prevents orphaned references during template renames
- Automates manual grep verification step
- Catches errors before commit
- Documents expected template filenames

**Implementation**:
1. Add to `.cig/scripts/` as `template-reference-linter`
2. Parse all `.md`, `.pl`, `.pm` files for template filename patterns
3. Cross-reference against current template pool contents
4. Flag deprecated names (e.g., "e-implementation-exec.md" in v2.1 context)
5. Allow v2.0-specific references (V20.pm uses "f-testing-plan.md" correctly)
6. Integrate with pre-commit hook or CI pipeline

**Estimated Effort**: 0.5-1 day

---

## Task: Create v2.0 to v2.1 Workflow Migration Tools

**Task-Type**: feature
**Priority**: Low

Create automated migration tools to upgrade existing v2.0 tasks (a-plan.md through h-retrospective.md) to v2.1 format (a-task-plan.md through j-retrospective.md with sequential a-j lettering).

**Context**: Task 25 implements v2.1 workflow with 10-phase sequential naming (a-j). Existing Tasks 1-24 use v2.0 format. The trampoline architecture handles mixed v2.0/v2.1 versions seamlessly, and we're already successfully using v2.1 (Tasks 26, 30), so migration is optional for consistency rather than a blocker.

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
4. Update internal cross-references (d-implementation.md → d-implementation-plan.md references)
5. Validate migration (renamed files exist, content valid, no broken references)

**Note on execution files**: Do NOT create e-implementation-exec.md or g-testing-exec.md for completed tasks - that would fabricate history. Only rename/re-letter existing files.

**Note on rollback**: Git is the rollback capability (`git commit` before migration, `git reset --hard` if needed).

**Scope**:
- Migration script: `.cig/scripts/migrate-v20-to-v21.pl` or similar
- Dry-run mode to preview changes before applying
- Batch migration for all v2.0 tasks or selective migration
- Validation checks before and after migration
- Clear error messages on failure
- Update documentation with migration instructions (including git commit/rollback workflow)

**Dependencies**:
- Task 25 must be complete (v2.1 format defined, trampoline architecture implemented)
- v2.1 template files must exist in `.cig/templates/pool/`

**Success Criteria**:
- [ ] Migration script created and tested
- [ ] Dry-run mode shows accurate preview
- [ ] Script handles all edge cases (partial migrations, already-migrated tasks)
- [ ] Validation checks prevent broken migrations
- [ ] Documentation explains migration process (including git commit/reset workflow)
- [ ] Tasks 1-24 can be migrated without manual intervention
- [ ] Migrated tasks work correctly with v2.1 workflow commands

**Rationale**: Migration tools would provide consistency across all tasks by converting v2.0 format to v2.1 naming. However, this is **not blocking** because:
- Trampoline architecture handles mixed v2.0/v2.1 versions seamlessly
- We're already successfully using v2.1 format (Tasks 26, 30)
- Completed tasks (1-24) work fine in v2.0 format
- New tasks use v2.1 templates automatically
- Manual migration is straightforward for the few tasks that need it

**Priority rationale**: Originally marked Critical, but downgraded to Low after Task 30 demonstrated that mixed versions work without issues. Migration is "nice to have for consistency" rather than a blocker.

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
