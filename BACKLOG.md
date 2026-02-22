# CWF System Backlog

Future tasks and improvements for the Coding with Files system.

---

<!-- Completed: "Refactor CWF Commands for Progressive Disclosure" — Task 56 (2026-02-12) -->
<!-- Completed: "Convert CWF Commands to Skills" — Task 57 (2026-02-13) -->

<!-- Completed: "Fix Install Script / cwf-init Boundary and Post-Install UX" — Task 62 (2026-02-17) -->

<!-- Completed: "Add Missing Checkpoint Commit Instructions to cwf-requirements-plan and cwf-maintenance" — Task 71 (2026-02-19) -->

<!-- Completed: "Fix install.bash file:// Source Defaults to HEAD" — Task 80 (2026-02-21) -->

<!-- Completed: "Enforce Single Canonical Task Type List Across CWF Modules" — Task 81 (2026-02-21) -->

---

<!-- Completed: "Fix checkpoints-branch-manager verify emits die instead of warn on SIGPIPE" — Task 82 (2026-02-21) -->

---

<!-- Completed: "Harden Install Script Pre-Flight Checks and Simplify Bootstrap" — Task 75 (2026-02-19) -->

<!-- Completed: "Remove v1.0 Category Subdirectories from /cwf-init" — Task 68 (2026-02-18) -->

<!-- Completed: "Improve CWF Skill Initialisation in /cwf-init" — Task 70 (2026-02-19) -->

---

## Task: Standardise Placeholder Syntax in Remaining CLI Docs

**Task-Type**: chore
**Priority**: Low
**Status**: Follow-up from Task 88

`workflow-preamble.md` and `decomposition-guide.md` use `<var>` syntax in CLI argument
documentation (showing command syntax, not model-substitution targets). Task 88 established
the convention: `{}` = "substitute this value", `<>` = reserved for HTML/XML/email.
These files should be audited and any model-substitution `<var>` instances converted to
`{var}`. Pure CLI syntax examples (e.g. `cmd <arg>`) should be reviewed to determine
whether a deliberate style-guide entry would be clearer.

**Scope**:
- Audit `.cwf/docs/skills/workflow-preamble.md` for `<var>` instances
- Audit `.cwf/docs/workflow/decomposition-guide.md` for `<var>` instances
- Convert model-substitution uses to `{}`; decide on CLI syntax documentation style
- Add a one-liner to the style guide (or glossary) clarifying the distinction

**Identified in**: Task 88 retrospective (j-retrospective.md)

---

## Task: Add Delete Task Skill

**Task-Type**: feature
**Priority**: High

Add a `/cwf-delete-task <num>` skill that cleanly removes a task: deletes the task directory, removes the git branch (if it exists), and optionally cleans the task stack. Currently, deleting a misclassified or abandoned task requires manual `git rm -r`, branch deletion, and directory cleanup — error-prone and tedious.

**Scope**:
- Delete task directory under `implementation-guide/`
- Delete associated git branch (with confirmation)
- Remove from task stack if present
- Refuse to delete if task has subtasks (safety check)
- Support `--force` flag to skip confirmation

**Identified in**: Task 59 (misclassified as chore, needed manual delete/recreate)

---

## Task: Infer Task Type When Not Specified in new-task and subtask Skills

**Task-Type**: feature
**Priority**: Medium

When `/cwf-new-task` or `/cwf-subtask` is invoked without a task type, the agent should infer the appropriate type based on the task description and complexity rather than failing with a validation error. If the inference is ambiguous, ask the user to choose. This prevents misclassification — e.g., a task with unclear requirements being created as a chore (no design phase) when it should be a feature.

**Inference guidance**: Consider whether requirements/design phases are needed (feature), whether this fixes a defect (bugfix/hotfix), whether it's mechanical with no ambiguity (chore), or whether it's exploratory (discovery).

**Identified in**: Task 59 (agent chose chore for a task with unclear requirements, required delete/recreate as feature)

---

<!-- Completed: "Update Branding and Documentation for Skills Architecture" — Task 79 (2026-02-20) -->

<!-- Completed: "Audit /cwf-init for Obsolete Category Subdirectories" — Task 68 (2026-02-18) -->


<!-- Completed: "Fix template-copier-v2.1 Uninitialized Variable Warnings" — Task 74 (2026-02-19) -->

## Bug: /cwf-init Should Run Security Check and Fix Permissions

**Task-Type**: bugfix
**Priority**: Low

After `/cwf-init`, helper scripts may lack execute permissions — particularly when CWF was installed via file copy from a local directory (as opposed to cloning from git, which preserves permissions). `/cwf-init` should run `/cwf-security-check` (or equivalent) and fix any permission mismatches automatically.

**Scope**:
- Add a security/permissions verification step to `/cwf-init` after directory setup
- Ensure all scripts under `.cwf/scripts/` have at least `u+rx`
- Optionally verify SHA256 hashes against `.cwf/security/script-hashes.json`

**Identified in**: Task 60 (testing CWF installation in a fresh repo)

---

## Task: Add Status Update Helper Script

**Task-Type**: feature
**Priority**: Low

Agents and users naturally write invalid status values (e.g. "Done" instead of "Finished"). The workflow-manager catches this after the fact, but a dedicated status update script could validate at write time and reject invalid values immediately.

**Scope**:
- Create a helper script (e.g. `cwf-set-status`) that updates a workflow file's Status field
- Validate against the canonical status list before writing
- Reject invalid values with a clear error listing valid options
- Optionally update the Next Action and Blockers fields at the same time

**Identified in**: Task 60 (external repo installation testing — agent used "Done" instead of "Finished")

---

## Task: Lightweight Rollout/Maintenance Templates for Internal Tasks

**Task-Type**: chore
**Priority**: Low
**Status**: Follow-up from Task 57

The rollout and maintenance templates are designed for production services (phased rollout, SLA monitoring, incident response). Internal tooling tasks waste time filling in inapplicable sections. Create lightweight variants.

**Scope**:
- Create "internal" variants of h-rollout.md and i-maintenance.md templates
- Reduce to relevant sections (deployment strategy, known issues, architecture reference)
- Template selection during `/cwf-new-task` based on project type or explicit flag

**Identified in**: Task 57 retrospective (j-retrospective.md — i-maintenance.md lessons learned)

---

## Task: Document Dead Code Audit Methodology

**Task-Type**: chore
**Priority**: Medium
**Status**: Follow-up from Task 51

Create `.cwf/docs/maintenance/dead-code-audit-checklist.md` documenting comprehensive audit methodology to prevent missing active usage patterns.

**Problem**: Task 51 audit incorrectly flagged `workflow_file_mappings()` and `format_error()` as dead code, missing same-file usage and script-to-library usage patterns. Errors caught during pre-removal verification, but audit methodology needs improvement.

**Solution**: Create standardized dead code audit checklist:
- **Cross-file usage**: `grep -r "function_name" .cwf/lib/ .cwf/scripts/`
- **Same-file usage**: Check within each affected file for internal calls
- **Script-to-library usage**: `grep -r "function_name" .cwf/scripts/command-helpers/`
- **POD documentation**: Check for public API declarations (`=head2 function_name`)
- **Structured report format**: Function, file, lines, usage findings, verdict

**Scope**: Create single documentation file with checklist and examples

**Rationale**: Standardized methodology reduces audit errors, prevents breaking changes, improves cleanup confidence

**Identified in**: Task 51 retrospective (j-retrospective.md - "Recommendations")

---

## Task: Comprehensive Dead Code Audit for CWF Library Modules

**Task-Type**: chore
**Priority**: Low
**Status**: Follow-up from Task 51

Run comprehensive dead code audit across all `.cwf/lib/*.pm` files using improved methodology from dead code audit documentation.

**Problem**: Task 51 only addressed functions already identified as dead. Remaining library modules may have additional cleanup opportunities not yet discovered.

**Solution**: Systematic audit of all library modules:
- Apply documented audit methodology to each .pm file
- Generate structured audit reports for each module
- Create follow-up task(s) for confirmed dead code removal
- Consider using Perl::Critic or static analysis tools

**Scope**: Audit only, do not remove code. Create follow-up tasks for actual removal.

**Dependencies**: Requires "Document Dead Code Audit Methodology" task completed first

**Rationale**: Proactive cleanup improves maintainability, reduces confusion, keeps codebase lean

**Identified in**: Task 51 retrospective (j-retrospective.md - "Future Work")


## Task: Create Perl Idioms Documentation

**Task-Type**: chore
**Priority**: Low
**Status**: Follow-up from Task 50

Create `.cwf/docs/conventions/perl-idioms.md` documenting common idiomatic Perl patterns for CWF scripts.

**Problem**: Task 50 implementation initially used non-idiomatic patterns (`grep { defined($_) }` instead of `grep defined`, if/else blocks instead of ternary conditionals). User review during planning phase caught and corrected these, but patterns should be documented for consistency across all CWF scripts.

**Solution**: Create perl-idioms.md with sections:
- **Filtering**: `grep defined` vs `grep { defined($_) }`, `map` patterns
- **Conditionals**: Ternary operators vs if/else blocks, postfix conditionals
- **String operations**: `s///` substitution, `=~` vs `!~`
- **File operations**: Three-arg open, lexical filehandles
- **Error handling**: `die` with context, `or die` idiom
- **References**: When to use, dereferencing patterns

**Scope**: Documentation only, no code changes

**Rationale**: Consistent idiomatic code improves readability, maintainability, reduces cognitive load

**Identified in**: Task 50 retrospective (j-retrospective.md - "Recommendations")


## Task: Add "Skipped-If" Conditional Logic to Workflow System

**Task-Type**: feature
**Priority**: Low
**Status**: Follow-up from Task 50

Allow task types to conditionally skip workflow phases based on type (e.g., bugfixes always skip i-maintenance.md).

**Problem**: Task 50 added "Skipped" status for marking phases N/A, but developers must manually set status for each task. For task types with predictable phase applicability (bugfixes never need maintenance, hotfixes skip rollout), conditional logic would eliminate manual work.

**Solution**: Add `"phase-applicability"` section to cwf-project.json:
```json
"phase-applicability": {
  "feature": ["a","b","c","d","e","f","g","h","i","j"],
  "bugfix": ["a","b","c","d","e","f","g","j"],  // skip h-rollout, i-maintenance
  "hotfix": ["a","d","f","g","j"],  // skip b,c,e,h,i
  "chore": ["a","d","f","g","j"]  // skip b,c,e,h,i
}
```
Template-copier automatically marks non-applicable phases as "Skipped" during task creation.

**Scope**:
- Update cwf-project.json schema
- Modify template-copier to set "Status: Skipped" for non-applicable phases
- Update workflow-steps.md with phase applicability by task type

**Rationale**: Eliminates manual work, reduces errors, codifies workflow conventions

**Identified in**: Task 50 retrospective (j-retrospective.md - "Recommendations")

---

<!-- Removed: "Create CWF Terminology Glossary" — Task 87 (2026-02-22) -->
<!-- Reason: Completed — .cwf/docs/glossary.md created with 8 terms -->

## Task: Create Integration Test for Inconclusive Inference Scenarios

**Task-Type**: chore
**Priority**: Low
**Status**: Follow-up from Task 37

Create integration test harness that manipulates git state to produce real signal conflicts, enabling testing of inconclusive inference scenarios.

**Scope**:
- Create test script that sets up controlled signal conflicts
- Test branch signal vs recency signal conflict
- Test all three signals disagreeing
- Test no signals scenario (empty repository)
- Validate real TaskContextInference output matches expectations

**Identified in**: Task 37 retrospective (j-retrospective.md)

---

<!-- Removed: "Update Commands/Skills to Use New Inference Output Format" — Task 84 (2026-02-21) -->
<!-- Reason: Moot — task-context-inference still uses singular task_num field; plural format was never adopted; skills work correctly as-is -->

---

## Task: Document Bugfix Workflow Differences

**Task-Type**: chore
**Priority**: Low
**Status**: Identified from Task 36 retrospective

Clarify that bugfix workflows skip h-rollout.md and use checkpoint commits for rollout instead.

**Problem**: Task 36 attempted to use `/cwf-rollout` but bugfix template doesn't include h-rollout.md, causing confusion about rollout phase.

**Solution**: Add explicit documentation about workflow type differences.

**Scope**:
1. **Update workflow-steps.md**: Add section comparing workflow types (feature vs bugfix vs hotfix)
2. **Create comparison table**: Show which phases each workflow type includes
   ```markdown
   | Phase | Feature | Bugfix | Hotfix | Chore |
   |-------|---------|--------|--------|-------|
   | a-plan | ✓ | ✓ | ✓ | ✓ |
   | b-requirements | ✓ | - | - | - |
   | c-design | ✓ | ✓ | - | - |
   | d-implementation-plan | ✓ | ✓ | ✓ | ✓ |
   | e-testing-plan | ✓ | ✓ | ✓ | ✓ |
   | f-implementation-exec | ✓ | ✓ | ✓ | ✓ |
   | g-testing-exec | ✓ | ✓ | - | - |
   | h-rollout | ✓ | - | ✓ | - |
   | i-maintenance | ✓ | - | - | - |
   | j-retrospective | ✓ | ✓ | ✓ | ✓ |
   ```
3. **Document rollout alternatives**: For workflows without h-rollout, explain checkpoint commit serves as rollout

**Success Criteria**:
- [ ] Comparison table shows phase inclusion by workflow type
- [ ] Documentation explains rollout alternatives for bugfix/chore
- [ ] Future tasks understand which phases apply to their type

**Rationale**: Reduces confusion about missing workflow phases based on task type.

**Discovered**: Task 36 retrospective - bugfix workflow doesn't include h-rollout.md

---

## Task: Create Verification Test Pattern Templates

**Task-Type**: chore
**Priority**: Low
**Status**: Identified from Task 36 retrospective

Create reusable grep/diff verification patterns for multi-file update tasks.

**Problem**: Task 36 used grep/diff verification effectively for 17-file update. This pattern is reusable but not documented.

**Solution**: Create verification pattern templates in documentation.

**Scope**:
1. **Create `docs/patterns/verification-tests.md`**:
   - Grep count pattern: `grep -l "PATTERN" files/* | wc -l`
   - Diff statistics: `git diff --stat`
   - Insertion consistency: Check all files show same line count
2. **Add examples**: Multi-file updates, consistent snippets, completeness checks

**Success Criteria**:
- [ ] Verification patterns documented with examples
- [ ] Future multi-file tasks reference patterns
- [ ] Verification approach consistent across tasks

**Rationale**: Codifies effective verification approach from Task 36 for reuse.

**Discovered**: Task 36 retrospective - grep/diff verification proved effective

---

<!-- Removed: "Document Checkpoint Commit → Squash Workflow" — Task 84 (2026-02-21) -->
<!-- Reason: Already documented in .cwf/docs/skills/retrospective-extras.md Step 10 ("Checkpoints Branch and Squash") with exact commands -->

---

## Task: Add Material Changes Review to Phase Commit Checklists

**Task-Type**: chore
**Priority**: Medium
**Status**: Identified from Task 35 retrospective

Add explicit commit checklist step to workflow documentation and templates to prevent oversight of committing actual deliverables.

**Problem**: Task 35 experienced repeated oversight where actual command file changes (the core deliverables) were not committed at multiple checkpoints:
- Implementation-exec phase (checkpoint commit)
- Rollout phase
- Retrospective phase

Root cause: Exclusive focus on implementation-guide/ documentation files caused deliverables in other directories (.claude/, .cwf/, etc.) to be overlooked.

**Solution**: Add explicit commit review step to each workflow phase documentation.

**Scope**:
1. **Update workflow-steps.md**: Add commit checklist guidance to each phase (implementation-exec, testing-exec, rollout, retrospective)
2. **Update phase templates**: Add "Commit Checklist" section to execution templates:
   - f-implementation-exec.md.template
   - g-testing-exec.md.template
   - h-rollout.md.template
   - j-retrospective.md.template
3. **Checklist content**:
   ```markdown
   ## Pre-Commit Checklist
   - [ ] Run `git status` to see all modified files
   - [ ] Review all modified files - are they material to this task?
   - [ ] Stage all material changes: implementation-guide/, .claude/, .cwf/, source files, etc.
   - [ ] Verify staged changes match task scope (git diff --staged)
   - [ ] Don't assume only implementation-guide/ files need committing
   ```

**Success Criteria**:
- [ ] Workflow documentation includes commit review guidance
- [ ] All execution templates have commit checklist section
- [ ] Checklist explicitly mentions reviewing files outside implementation-guide/
- [ ] Future tasks less likely to miss committing core deliverables

**Rationale**: Prevents repeated oversight pattern where documentation gets committed but actual code/config changes are forgotten. Explicit checklist reduces cognitive load and provides systematic review process.

**Discovered**: Task 35 retrospective - command files not committed at any checkpoint despite being the core deliverable

---

## Task: Add Baseline Verification Step to Implementation Planning Templates

**Task-Type**: chore
**Priority**: Low
**Status**: Identified from Task 35 retrospective

Add explicit baseline verification step to implementation planning phase for tasks involving counts, metrics, or quantitative validation.

**Problem**: Task 35 estimated 35 historical references but actual count was 52. Baseline was established incorrectly, causing mid-stream test criteria adjustment during testing phase.

**Solution**: Update d-implementation-plan.md template to include baseline verification section.

**Scope**:
1. **Update template**: `.cwf/templates/pool/d-implementation-plan.md.template`
2. **Add section** after "Implementation Steps":
   ```markdown
   ## Baseline Verification (if applicable)

   For tasks involving counts, metrics, or quantitative validation:
   - [ ] Establish accurate baseline BEFORE implementation
   - [ ] Document baseline measurement method
   - [ ] Record baseline values with verification date
   - [ ] Note any assumptions or exclusions

   Example: Historical reference count
   - Baseline: grep -r "pattern" dir/ | wc -l
   - Value: 52 references (2026-02-06)
   - Exclusions: Task's own documentation
   ```

**Success Criteria**:
- [ ] Template includes baseline verification section
- [ ] Section is conditional ("if applicable")
- [ ] Provides clear example for count-based tasks
- [ ] Future tasks establish accurate baselines before implementation

**Rationale**: Pre-execution baseline verification prevents mid-stream test criteria adjustments and ensures test cases are accurate from the start.

**Discovered**: Task 35 retrospective - baseline of 35 references was inaccurate, actual was 52

---

<!-- Completed: "Add Status Field Review to Pre-Retrospective Checklist" — Task 69 (2026-02-18) — Root cause fixed: Implemented status removed entirely -->

## Task: Create Design-Alignment Conventions Document

**Task-Type**: chore
**Priority**: Medium
**Status**: Partial completion (Task 35 fixed command references, conventions doc remains)

**Context**: Task 35 fixed the 2 incorrect command references (`.claude/commands/cwf-new-task.md` and `.claude/commands/cwf-subtask.md`). The remaining work is to create conventions documentation to prevent future inconsistencies.

**Scope**:

Create `docs/conventions/design-alignment.md` to prevent future inconsistencies:

**Topics to cover**:

1. **Command/Skill Naming Audit Process**:
   - When to audit: Before committing command changes
   - What to check: All references in docs, templates, and code
   - Tools to use: grep, search patterns

2. **Naming Consistency Guidelines**:
   - Command naming patterns (e.g., `/cwf-{workflow-step}-{action}`)
   - When to use prefixes (cig-, task-, workflow-)
   - Avoiding ambiguous abbreviations

3. **Reference Update Checklist**:
   - Files to always check when renaming commands
   - Search patterns to use
   - Testing procedure

4. **Deprecation Process**:
   - How to deprecate old command names gracefully
   - Migration period guidelines
   - Warning messages for deprecated commands

5. **Documentation Standards**:
   - Where to document command names (single source of truth)
   - How to cross-reference between docs
   - When to use symbolic links vs duplication

**Example Convention**:
```markdown
## Command Naming Audit Checklist

Before committing changes that create/rename/remove commands:

- [ ] Search all `.md` files for old command name
- [ ] Update all references in `.claude/commands/`
- [ ] Update all references in `docs/`
- [ ] Update template files in `.cwf/templates/pool/`
- [ ] Update README.md, CLAUDE.md, COMMANDS.md
- [ ] Search implementation guides for references
- [ ] Test updated commands work correctly
- [ ] Add deprecation warnings if needed
```

**Deliverables**:
1. Audit report showing all command references and needed fixes
2. All anachronistic references updated to current names
3. `docs/conventions/design-alignment.md` document
4. Updated commit workflow to include reference audit

**Benefits**:
- Eliminates confusion from outdated command names
- Prevents future anachronistic references
- Establishes systematic approach to naming consistency
- Makes command renames safer and more reliable

---

## ~~Task: Standardize Task Context Inference Output Format~~ ✓ COMPLETED

**Task-Type**: bugfix
**Priority**: High
**Status**: ✓ Completed in Task 37 (2026-02-06)

Standardize task context inference output to always use structured, parseable format suitable for LLM consumption and script parsing, regardless of whether signals are conclusive or inconclusive.

**Problem**: Task 32 implemented inference with inconsistent output formats:

**Current Behavior (Conclusive)**:
```
task_num: 32
task_slug: task-tracking-using-inference-scoring
workflow_step: j-retrospective
```

**Current Behavior (Inconclusive - NOT PARSEABLE)**:
```
Signals disagree on current task.

Top candidates:
  - Task 14
  - Task 32

Please specify task number explicitly or clarify context.

  branch:         task 32 (score: 100, top of 1)
  worktree:       null
  state:          null
  recency:        task 32 (score: 49, top of 5)
  progress:       task 14 (score: 0, top of 5)
```

**Original Specification (from planning)**:
```
task_num: {task_num}
task_slug: {task_slug}
workflow_step: {workflow_step}
```

**What's Missing**:
1. No way to indicate conclusive vs inconclusive inference
2. Inconclusive output is human-readable prose, not parseable
3. No structured format for multiple candidate tasks
4. LLMs and scripts can't reliably parse current output

**Solution**: Implement structured output format for all scenarios.

**Proposed Output Format**:

**Conclusive (signals agree)**:
```
current: conclusive
task_num: 32
task_slug: task-tracking-using-inference-scoring
workflow_step: j-retrospective
confidence: correlated
```

**Inconclusive (signals disagree)**:
```
current: inconclusive
task_num: 14,32
task_slug: retrospective-suggest-updating-workflow-and-commit,task-tracking-using-inference-scoring
workflow_step: unknown
confidence: uncorrelated
candidates: 2
```

**No signals**:
```
current: inconclusive
task_num: unknown
task_slug: unknown
workflow_step: unknown
confidence: no_signals
candidates: 0
```

**Fields**:
- `current`: conclusive|inconclusive (can inference determine single task?)
- `task_num`: single number | comma-separated numbers | "unknown"
- `task_slug`: single slug | comma-separated slugs | "unknown"
- `workflow_step`: step name | "unknown"
- `confidence`: correlated|uncorrelated|no_signals (from TaskContextInference.pm)
- `candidates`: number of candidate tasks (0, 1, or N)

**Scope**:

1. **Update TaskContextInference.pm**:
   - Modify `infer_task_context()` to always return structured format
   - Add "current" field (conclusive/inconclusive)
   - Add "candidates" count field
   - When uncorrelated: return comma-separated task_num and task_slug lists
   - When no signals: return "unknown" for fields

2. **Update task-context-inference wrapper**:
   - Default mode outputs structured format (always parseable)
   - Keep `--verbose` flag for signal breakdown (debugging)
   - Exit codes remain: 0=conclusive, 1=uncorrelated, 3=no_signals

3. **Update skills**:
   - `/current-task-wf` outputs structured format
   - `/current-task-wf-verbose` adds signal breakdown after structured output
   - Both parseable by LLMs and scripts

4. **Update commands**:
   - Commands parse structured output (extract task_num field)
   - Commands check "current" field and handle inconclusive gracefully
   - Commands prompt user when current=inconclusive

5. **Update tests**:
   - Verify structured output for all scenarios (conclusive, uncorrelated, no_signals)
   - Parse output programmatically (validate format)
   - Update TC-I2, TC-I3, TC-I4 test expectations

**Benefits**:
- Deterministic, parseable output in all scenarios
- LLMs can reliably extract task context
- Scripts can parse output without regex hacks
- Consistent format whether signals agree or disagree
- Backward compatible (commands can check "current" field)

**Success Criteria**:
- [ ] TaskContextInference.pm always returns structured format
- [ ] Output includes current: conclusive|inconclusive
- [ ] Inconclusive output has comma-separated candidates
- [ ] Skills output parseable format
- [ ] Commands handle both conclusive and inconclusive responses
- [ ] Tests validate structured output format
- [ ] Documentation updated with output format specification

**Rationale**: Task 32 planning specified structured output (`task_num: {task_num}\ntask_slug: {task_slug}\nworkflow_step: {workflow_step}`) but implementation only provides this when signals agree. Inconclusive scenarios output human-readable prose that's not parseable by LLMs or scripts. This breaks automation and requires manual intervention. Standardizing to always output structured format enables reliable automation.

**Original Specification Reference**: Task 32 a-task-plan.md specified "3-line output (task_num, task_slug, workflow_step)" but didn't account for inconclusive scenarios.

**Real-World Impact**: Just encountered this issue - Task 32 is complete (100%) on feature branch, progress signal disagrees with branch signal, output is unparseable prose. Commands can't extract task number programmatically.

**Related**: Task 32 (implementation incomplete for original output format specification)

---

## Task: Add Security Verification to Testing Workflow

**Task-Type**: chore
**Priority**: Medium
**Status**: Identified during Task 32 security verification

Add instruction to include security integrity checks as a standard part of the testing workflow (g-testing-exec) for all tasks that modify helper scripts or libraries.

**Problem**: Task 32 modified 8 helper scripts and added 2 libraries, but security hash verification wasn't performed until after retrospective. Security verification should be part of the testing phase to catch hash mismatches early.

**Solution**: Update testing workflow documentation and templates to include security verification step.

**Scope**:

1. **Update workflow documentation** (`.cwf/docs/workflow/workflow-steps.md`):
   - Add "Security Verification" as recommended step in Testing Execution section
   - Document when security checks are required (tasks modifying scripts/libraries)
   - Document how to run verification (`/cwf-security-check verify`)

2. **Update testing templates** (`.cwf/templates/pool/g-testing-exec.md.template`):
   - Add "Security Verification" checkbox to execution checklist
   - Add conditional guidance: "If this task modifies helper scripts or libraries, run `/cwf-security-check verify` and update hashes"

3. **Update testing plan templates** (`.cwf/templates/pool/e-testing-plan.md.template`):
   - Add "Security Verification" test case (TC-S1)
   - Test case validates script-hashes.json is up to date after implementation

**Benefits**:
- Catches hash mismatches early (during testing, not post-retrospective)
- Makes security verification a standard practice, not an afterthought
- Documents when and how to perform security checks

**Success Criteria**:
- [ ] workflow-steps.md includes security verification guidance
- [ ] g-testing-exec.md.template includes security checklist item
- [ ] e-testing-plan.md.template includes security test case
- [ ] Future tasks that modify scripts will include security verification in testing phase

**Rationale**: Security verification is currently ad-hoc. Integrating it into the testing workflow ensures it's performed consistently for all tasks that modify security-sensitive files.

**Related**: Task 32 (discovered during post-retrospective security check)

---

<!-- Removed: "Create Permanent Security Verification Script" — Task 84 (2026-02-21) -->
<!-- Reason: Superseded by `cwf-manage validate` / CWF::Validate::Security.pm — version-controlled, reads script-hashes.json, verifies SHA256 and permissions -->

---

## Task: Test Edge Cases for Task Context Inference System

**Task-Type**: chore
**Priority**: Low
**Status**: Deferred from Task 32 testing execution

Execute three edge case tests for the task context inference system (Task 32) that were deferred due to requiring special test environments.

**Background**: Task 32 implemented a signal-based inference system that automatically detects the current task and workflow step from environmental signals (git branch, worktree, state file, recency, progress). During testing execution (g-testing-exec.md), 42/45 tests passed (93%) with zero failures. Three edge case tests were deferred because they require test environments that would break the current task context or create artificial conflicting state.

**Deferred Test Cases**:

1. **TC-I3: Uncorrelated Signals (Conflicting State)**
   - **Scenario**: Multiple signals disagree on which task is current
   - **Example**: Branch points to Task 32, but state file points to Task 11
   - **Expected**: User prompt asking to clarify which task is correct, exit code 1
   - **Why deferred**: Requires artificially creating conflicting state
   - **Environment**: Need to set up branch/state file/recency signals that disagree

2. **TC-I4: No Signals (Main Branch)**
   - **Scenario**: No signals detected (e.g., working on main branch with no task context)
   - **Expected**: Error message "Cannot infer context - no signals detected", exit code 3
   - **Why deferred**: Requires switching to main branch, which loses current task context
   - **Environment**: Need main branch with no feature work in progress

3. **TC-S2: Skill Failure Fallback**
   - **Scenario**: `/current-task-wf` skill invoked when inference cannot determine context
   - **Expected**: "Unable to infer context" message displayed
   - **Why deferred**: Requires no-signal environment (same as TC-I4)
   - **Environment**: Need environment where all inference signals return null

**Test Requirements**:

**For TC-I3 (Uncorrelated Signals)**:
- Create test fixture with conflicting signals
- Set git branch to feature/32-slug
- Set `.cwf/current-task` to different task number (e.g., 11)
- Verify wrapper script outputs user prompt
- Verify exit code 1 (uncorrelated)
- Clean up test fixtures after test

**For TC-I4 and TC-S2 (No Signals)**:
- Switch to main branch (loses feature branch signal)
- Clear `.cwf/current-task` if present
- Work in directory with no recent modifications
- Verify wrapper script outputs error
- Verify exit code 3 (no signals)
- Verify skill displays fallback message
- Return to feature branch after test

**Scope**:

1. **Create isolated test environment**:
   - Git worktree or separate clone for testing without disrupting main work
   - Test fixtures for artificial signal conflicts
   - Cleanup script to restore original state

2. **Execute TC-I3**: Test uncorrelated signals scenario
   - Set up conflicting signals
   - Run `task-context-inference` wrapper
   - Verify user prompt and exit code 1
   - Document results in Task 32 testing file

3. **Execute TC-I4**: Test no signals scenario
   - Set up environment with no signals
   - Run `task-context-inference` wrapper
   - Verify error message and exit code 3
   - Document results in Task 32 testing file

4. **Execute TC-S2**: Test skill failure fallback
   - Use same no-signal environment
   - Invoke `/current-task-wf` skill
   - Verify fallback message displayed
   - Document results in Task 32 testing file

5. **Update Task 32 documentation**:
   - Update g-testing-exec.md with edge case results
   - Change test status from "SKIP" to "PASS" or "FAIL"
   - Update coverage metrics

**Out of Scope**:
- Fixing issues found (this is testing only, not bug fixes)
- Modifying inference algorithm based on findings
- Adding new test cases beyond these three

**Success Criteria**:
- [ ] Isolated test environment created without disrupting main work
- [ ] TC-I3 executed with documented results (PASS/FAIL)
- [ ] TC-I4 executed with documented results (PASS/FAIL)
- [ ] TC-S2 executed with documented results (PASS/FAIL)
- [ ] Task 32 g-testing-exec.md updated with results
- [ ] Original environment restored after testing
- [ ] Any bugs discovered documented (separate BACKLOG items if fixes needed)

**Rationale**: These edge case tests validate inference behavior in atypical scenarios. While the primary use case (developer working on feature branch with active task) is fully validated and production-ready, these edge cases ensure graceful degradation when signals are missing or conflicting. Testing was deferred from Task 32 because creating the test environments would break the current task context, but they should be validated in a controlled test environment to ensure robustness.

**Estimated Effort**: 2-4 hours (environment setup, test execution, documentation)

**Priority**: Low because:
- Primary use case (correlated signals) is fully validated
- These are edge cases with low likelihood in normal usage
- System is production-ready without these tests
- No known bugs in these scenarios (just untested)

**Related**: Task 32 (feature-task-tracking-using-inference-scoring) - implementation and testing complete except for these three edge cases

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
1. Add to `.cwf/scripts/` as `template-reference-linter`
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
- Migration script: `.cwf/scripts/migrate-v20-to-v21.pl` or similar
- Dry-run mode to preview changes before applying
- Batch migration for all v2.0 tasks or selective migration
- Validation checks before and after migration
- Clear error messages on failure
- Update documentation with migration instructions (including git commit/rollback workflow)

**Dependencies**:
- Task 25 must be complete (v2.1 format defined, trampoline architecture implemented)
- v2.1 template files must exist in `.cwf/templates/pool/`

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

<!-- Removed: "Migrate CWF to Hybrid Plugin Model (Commands → Skills + Plugin)" — Task 84 (2026-02-21) -->
<!-- Reason: Commands→Skills migration completed in Task 57; plugin hooks blocked by Bug #17688; Task 54 disproved core premise (commands not deprecated, "Keep Commands" confirmed at 85% confidence) -->

---

<!-- Removed: "Create Automated Test Harness for CWF System" — Task 84 (2026-02-21) -->
<!-- Reason: Done — t/ directory has 15+ test files covering all major modules (statusaggregator, workflowfiles, templatecopier, contextinheritance, taskpath, validate-*, etc.) -->
- [ ] Runs in <2 minutes
- [ ] Can run on any Perl 5.14+ system

**Rationale**: Manual validation is sustainable for small changes but becomes bottleneck as system grows. Automated testing provides confidence and speed.

---


<!-- Removed: "Design Task-Type-Specific Workflow Variants" — Task 84 (2026-02-21) -->
<!-- Reason: Already implemented — task-workflow create produces type-specific file sets (feature=8, bugfix=5, hotfix=5, chore=4); workflow-overview.md documents variants -->

---

## Task: Add Status Calculation Overview to Workflow Documentation

**Task-Type**: chore
**Priority**: Low
**Status**: Proposed (identified during Task 25 retrospective discussion)

Add brief explanation of how task status/progress calculation works to workflow documentation, following DRY and progressive disclosure principles.

**Problem**: Current documentation explains status VALUES (Backlog=0%, Finished=100%) but not how task completion percentage is CALCULATED:
- No explanation that status is aggregated from workflow file Status fields
- No mention of status-aggregator script
- No reference to /cwf-status (user-invocable currently, agent-invocable after skills migration)
- Users/LLM don't understand how "25% complete" is derived

**Solution**: Add brief "How Status Works" section to `.cwf/docs/workflow/workflow-steps.md`:

```markdown
## How Task Status Works

Task completion percentage is calculated by aggregating the `## Status` field from each workflow file (a-plan.md through h-retrospective.md). Each status value has a percentage weight (Backlog=0%, In Progress=25%, Finished=100%, etc.).

**To check task status**:
- User runs: `/cwf-status <task-path>` (command - user-only currently)
- Script: `status-aggregator <task-path>` (called by cig-status command)
- Future: Agent can invoke via Skill("cig-status") after skills migration

**How it's calculated**: See `status-aggregator` script for implementation details.

**Status values**: See [Status Values](#status-values) section above for complete list.
```

**Scope**:
1. Add brief "How Task Status Works" section to workflow-steps.md
2. Position after "Status Values" section (lines 16-48)
3. Include references to status-aggregator script
4. Note that /cwf-status is user-only currently, agent-invocable after skills migration
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
- Entry point: `.cwf/scripts/command-helpers/status-aggregator`
- Routes to: `status-aggregator-v2.0` or `status-aggregator-v2.1` orchestration
- Uses: Core::StatusAggregator module

Documentation and commands may still reference `status-aggregator` which:
- Is technically incorrect (should call entry point, not .pl directly)
- Bypasses trampoline version routing
- Confusing for users who see `status-aggregator` in directory listings

**Solution**: Find and update all references:

**Files to check**:
- `.cwf/docs/workflow/workflow-steps.md`
- `.cwf/docs/context/tools.md`
- `.claude/commands/cwf-status.md`
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
1. Update `.cwf/templates/pool/g-maintenance.md.template` with new section
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

Analyse and standardise cross-document reference patterns used throughout CWF system documentation, templates, and command files.

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
5. **Update style guide**: Document patterns in `.cwf/docs/` for future reference
6. **Migration plan**: Optionally create plan to standardise existing references

**Examples to analyse**:
- Intra-task references: `d-implementation.md` → `e-testing.md`
- External doc references: Templates → `workflow-steps.md`
- Config references: Command files → `cwf-project.json`

**Outcome**: Clear, documented standard for cross-document references that follows DRY and progressive disclosure principles.

---

<!-- Removed: "Remove Decomposition Checks from Non-Planning Workflow Steps" — Task 86 (2026-02-22) -->
<!-- Reason: Completed — Step 7 removed from cwf-rollout and cwf-maintenance SKILL.md files -->

<!-- Removed: "Rollout Task 11 - Secure Argument Parsing" — Task 11 cancelled (superseded by Task 57, commands→skills bypasses $ARGUMENTS bug entirely). Removed in Task 58 retrospective. -->

<!-- Removed: "Security Review and Hardening of CWF Bash Invocations" — Task 84 (2026-02-21) -->
<!-- Reason: Moot — commands migrated to skills (Task 57), command-helpers are all Perl with no shell metacharacter exposure; $ARGUMENTS bug bypassed entirely -->

---

## Task: Extract CWF Argument Validation Pattern to Documentation

**Task-Type**: feature
**Priority**: Needs-Triage

Create reusable documentation for the secure argument parsing pattern developed in Task 11. This pattern (LLM validates format → extracts arguments → invokes bash with literals) prevents command injection and handles arbitrary user input safely. Should be documented in `.cwf/docs/` for use in future CWF commands or similar systems. Include: (1) Security model explanation, (2) Format validation regex patterns, (3) Example implementation, (4) Test scenarios.

---

## Task: Standardize Exit Codes to errno-Style Values

**Task-Type**: chore
**Priority**: Low

Consolidate exit codes across all CWF helper scripts to use errno-compatible values for better semantic meaning and consistency. Currently, exit codes are inconsistent across scripts (e.g., exit 3 means "Missing required argument" in hierarchy-resolver but "No parent tasks" in context-inheritance). Proposed standard:
- 0 = Success
- 2 = ENOENT (No such file or directory) - for "not found" errors
- 13 = EACCES (Permission denied) - for permission errors
- 22 = EINVAL (Invalid argument) - for validation errors

Scripts to update: hierarchy-resolver, context-inheritance, status-aggregator, format-detector, template-version-parser, and any future helper scripts. Update documentation in script headers and `.cwf/docs/` to reflect standard.

---

## Task: Surface Task-Level Status Label in Status Summary Line

**Task-Type**: feature
**Priority**: Low
**Status**: Follow-up from Task 58

The status-aggregator summary line shows only the percentage (e.g., `- 11 (bugfix): ... - 0%`), with no status label. A Cancelled task at 0% looks identical to a Backlog task at 0%. The `--workflow` flag shows per-file status labels, but the top-level summary line does not surface the dominant or consensus status.

**Proposed change**: When all workflow files share the same status (e.g., all "Cancelled"), append it to the summary line: `- 11 (bugfix): ... - 0% [Cancelled]`. When mixed, either show the lowest-progress status or omit.

**Scope**: Both `status-aggregator-v2.0` and `status-aggregator-v2.1`. Affects markdown and JSON output modes.

**Identified in**: Task 58 retrospective (j-retrospective.md)

---

## Task: Improve status-aggregator Error Message Clarity

**Task-Type**: chore
**Priority**: Low

Improve error message in `status-aggregator` to clarify that it expects a task number (e.g., "17", "1.2.3"), not a full file path. Current error "Invalid task path format: 17-feature-new-helper-script-to-setup-templates-for-new-task" is confusing because users might provide the directory name or full path. Updated error should say something like "Error: Invalid task number format. Expected decimal notation (e.g., '17', '1.2', '1.2.3'), not a file path or directory name." This improves usability by helping users understand the correct input format immediately.

---

## ✓ Task: Fix CWF Commands to Work from Any Directory

**Task-Type**: bugfix
**Priority**: High
**Status**: ✓ Complete (Task 36 - 2026-02-06)

Fixed CWF workflow commands to work regardless of current working directory by adding git root detection to all 17 command files.

**Solution Implemented**: Added bash snippet to detect git repository root and cd to it before execution:
```bash
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
    echo "Error: Not in a git repository. CWF commands must be run from within a git repository."
    exit 1
fi
cd "$GIT_ROOT"
echo "Working directory: $GIT_ROOT"
```

**Results**:
- All 17 command files updated (.claude/commands/cwf-*.md)
- Commands now work from any directory within repository
- Clear error handling for non-git directories
- Working directory changes communicated to user/LLM

**Completed by**: Task 36 (bugfix/36-fix-cig-commands-to-work-from-any-directory)

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
# At start of each CWF command
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
    echo "Error: Not in a git repository"
    exit 1
fi

cd "$GIT_ROOT"
echo "Working directory: $GIT_ROOT"
```

**Scope**:
- Update all CWF workflow commands (cig-plan, cig-requirements, cig-design, cig-implementation, cig-testing, cig-rollout, cig-maintenance, cig-retrospective)
- Update utility commands (cig-new-task, cig-subtask, cig-status, cig-extract, cig-config, cig-init)
- Add git root detection to command templates
- Document working directory behavior in `.cwf/docs/`

**Testing**:
- Run commands from repository root (should work as before)
- Run commands from task subdirectories (should work after fix)
- Run commands from outside repository (should fail with clear error)

**Rationale**: CWF commands should work reliably regardless of where Claude's current working directory is, preventing workflow interruptions and improving user experience.

---


<!-- Completed: "Add Re-Execution Guidance to Implementation and Testing Exec Skills" — Task 76 (2026-02-19) -->
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
# CWF::WorkflowFiles::Dispatch
package CWF::WorkflowFiles::Dispatch;

use strict;
use warnings;
use CWF::WorkflowFiles::V20;
use CWF::WorkflowFiles::V21;

# Dispatch table - each version implements the same interface
our %DISPATCH = (
    '2.0' => {
        list_wf_steps => sub {
            my ($opts) = @_;
            # v2.0 specific workflow file listing
            return CWF::WorkflowFiles::V20::get_workflow_files(
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
use CWF::WorkflowFiles::Dispatch;

for my $task (@all_tasks) {
    # Detect version PER TASK
    my $version = detect_task_version($task->{dir});

    # Get version-specific operations (interface dispatch)
    my $ops = CWF::WorkflowFiles::Dispatch::get_dispatch($version);

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

1. **Create `CWF::WorkflowFiles::Dispatch` module**
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
- `.cwf/lib/CIG/WorkflowFiles/Dispatch.pm` - Interface dispatch module

**Modify**:
- `.cwf/lib/CIG/WorkflowFiles/V20.pm` - Add operations to match interface
- `.cwf/lib/CIG/WorkflowFiles/V21.pm` - Add operations to match interface
- `.cwf/scripts/command-helpers/status-aggregator` - Simplify or unify
- `.cwf/scripts/command-helpers/status-aggregator-v2.0` - Refactor or remove
- `.cwf/scripts/command-helpers/status-aggregator-v2.1` - Refactor or remove

### Scope Note

This is a **significant refactor** touching the core status aggregation architecture. Estimate: 8-16 hours for experienced Perl developer.

**Not in scope for Task 26** due to:
- Size/complexity (would delay current feature)
- Requires careful testing with multiple version scenarios
- Current workaround acceptable (use task-specific queries)

### Priority Justification

**Medium Priority** because:
- **Primary use case works**: Task-specific queries (`/cwf-status 26`) work correctly
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

<!-- Removed: "Standardize Script Naming and Invocation (Remove Extensions)" — Task 84 (2026-02-21) -->
<!-- Reason: Done — all command-helpers already use extensionless names (context-manager, task-workflow, workflow-manager, status-aggregator-v2.*, etc.); no .pl/.sh extensions present -->

---

## Task: Audit CWF Commands for Hardcoded Data

**Task-Type**: chore
**Priority**: Low
**Status**: Follow-up from Task 43

Audit all CWF command files to identify and eliminate hardcoded data that should be read from configuration files instead.

**Scope**:
- Check all `.claude/commands/cwf-*.md` files for hardcoded lists, paths, or configuration values
- Identify data that duplicates information in `script-hashes.json`, `cwf-project.json`, or other config files
- Refactor to read from canonical sources instead of duplicating data
- Example: cig-security-check.md had hardcoded list of v2.0 scripts

**Identified in**: Task 43 retrospective (j-retrospective.md)

---

## Task: Document Workflow Phase Sequences by Task Type

**Task-Type**: chore
**Priority**: Low
**Status**: Follow-up from Task 43

Create quick reference documentation for workflow phase sequences (which files are used) for each task type.

**Scope**:
- Document feature workflow: a, b, c, d, e, f, g, h, i, j (all 10 phases)
- Document bugfix workflow: a, c, d, e, f, g, j (7 phases)
- Document hotfix workflow: a, d, f, g, h (5 phases)
- Document chore workflow: a, d, f, j (4 phases)
- Add to `.cwf/docs/workflow/` directory
- Include in command help or error messages when phase skipped

**Identified in**: Task 43 retrospective (j-retrospective.md)

---

## Task: Replace Backtick Operators with IPC::Open3 in cwf-manage

**Task-Type**: chore
**Priority**: Very Low

Replace backtick operators in `.cwf/scripts/cwf-manage` with `IPC::Open3` calls to satisfy perlcritic severity 3 (harsh). `IPC::Open3` is core since Perl 5.000. Currently 5 backtick usages for simple `git` commands — functional and readable as-is, but not PBP-compliant at level 3.

**Scope**:
- Replace backticks in `find_git_root()`, `resolve_ref()`, `resolve_sha()`, `cmd_list_releases()`
- Consider also adding `/x` flag to simple regexes (8 hits) and converting the if-elsif dispatch to a hash table (1 hit) for full level 3 compliance

**Identified in**: Task 61 (perlcritic --harsh on cwf-manage)
