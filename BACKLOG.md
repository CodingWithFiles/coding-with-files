# CIG System Backlog

Future tasks and improvements for the Code Implementation Guide system.

---

<!-- Completed: "Refactor CIG Commands for Progressive Disclosure" — Task 56 (2026-02-12) -->
<!-- Completed: "Convert CIG Commands to Skills" — Task 57 (2026-02-13) -->

## Task: Update Branding and Documentation for Skills Architecture

**Task-Type**: chore
**Priority**: High
**Status**: Follow-up from Task 57
**Depends on**: Skills architecture stability confirmed across several tasks

CLAUDE.md still references "commands" terminology and lists `/cig-*` as commands. Update all documentation to reflect the skills architecture: CLAUDE.md, README.md, any docs referencing `.claude/commands/`.

**Scope**:
- Update CLAUDE.md command references to skills
- Update any user-facing documentation
- Verify no stale references to `.claude/commands/` path
- Advance main once documentation is current

**Identified in**: Task 57 retrospective (j-retrospective.md)

---

## Task: Lightweight Rollout/Maintenance Templates for Internal Tasks

**Task-Type**: chore
**Priority**: Low
**Status**: Follow-up from Task 57

The rollout and maintenance templates are designed for production services (phased rollout, SLA monitoring, incident response). Internal tooling tasks waste time filling in inapplicable sections. Create lightweight variants.

**Scope**:
- Create "internal" variants of h-rollout.md and i-maintenance.md templates
- Reduce to relevant sections (deployment strategy, known issues, architecture reference)
- Template selection during `/cig-new-task` based on project type or explicit flag

**Identified in**: Task 57 retrospective (j-retrospective.md — i-maintenance.md lessons learned)

---

## Task: Document Dead Code Audit Methodology

**Task-Type**: chore
**Priority**: Medium
**Status**: Follow-up from Task 51

Create `.cig/docs/maintenance/dead-code-audit-checklist.md` documenting comprehensive audit methodology to prevent missing active usage patterns.

**Problem**: Task 51 audit incorrectly flagged `workflow_file_mappings()` and `format_error()` as dead code, missing same-file usage and script-to-library usage patterns. Errors caught during pre-removal verification, but audit methodology needs improvement.

**Solution**: Create standardized dead code audit checklist:
- **Cross-file usage**: `grep -r "function_name" .cig/lib/ .cig/scripts/`
- **Same-file usage**: Check within each affected file for internal calls
- **Script-to-library usage**: `grep -r "function_name" .cig/scripts/command-helpers/`
- **POD documentation**: Check for public API declarations (`=head2 function_name`)
- **Structured report format**: Function, file, lines, usage findings, verdict

**Scope**: Create single documentation file with checklist and examples

**Rationale**: Standardized methodology reduces audit errors, prevents breaking changes, improves cleanup confidence

**Identified in**: Task 51 retrospective (j-retrospective.md - "Recommendations")

---

## Task: Comprehensive Dead Code Audit for CIG Library Modules

**Task-Type**: chore
**Priority**: Low
**Status**: Follow-up from Task 51

Run comprehensive dead code audit across all `.cig/lib/*.pm` files using improved methodology from dead code audit documentation.

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

Create `.cig/docs/conventions/perl-idioms.md` documenting common idiomatic Perl patterns for CIG scripts.

**Problem**: Task 50 implementation initially used non-idiomatic patterns (`grep { defined($_) }` instead of `grep defined`, if/else blocks instead of ternary conditionals). User review during planning phase caught and corrected these, but patterns should be documented for consistency across all CIG scripts.

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

**Solution**: Add `"phase-applicability"` section to cig-project.json:
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
- Update cig-project.json schema
- Modify template-copier to set "Status: Skipped" for non-applicable phases
- Update workflow-steps.md with phase applicability by task type

**Rationale**: Eliminates manual work, reduces errors, codifies workflow conventions

**Identified in**: Task 50 retrospective (j-retrospective.md - "Recommendations")

---

## Task: Create CIG Terminology Glossary

**Task-Type**: chore
**Priority**: Low
**Status**: Follow-up from Task 44

Create glossary of CIG terms to ensure consistent usage across documentation and commands.

**Scope**:
- Create `.cig/docs/glossary.md` with standardized terminology
- Include terms like "checkpoints branch" vs "checkpoint branch", "workflow steps" vs "workflow phases"
- Consider adding automated validation in `/cig-security-check` to catch inconsistencies

**Rationale**: Terminology inconsistencies discovered during Task 44 ("checkpoints branch" needed for searchability). Glossary would prevent future confusion.

**Identified in**: Task 44 retrospective (j-retrospective.md)

---

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

## Task: Update Commands/Skills to Use New Inference Output Format

**Task-Type**: chore
**Priority**: Low
**Status**: Follow-up from Task 37

Update commands and skills that parse task context inference output to use the new structured format with plural fields.

**Scope**:
- Audit commands that call task-context-inference
- Update parsing logic to handle plural fields (task_nums, task_slugs)
- Handle inconclusive scenarios gracefully (prompt user when current=inconclusive)
- Use `current` field for version detection (backward compatibility)

**Identified in**: Task 37 retrospective (j-retrospective.md)

---

## Task: Document Bugfix Workflow Differences

**Task-Type**: chore
**Priority**: Low
**Status**: Identified from Task 36 retrospective

Clarify that bugfix workflows skip h-rollout.md and use checkpoint commits for rollout instead.

**Problem**: Task 36 attempted to use `/cig-rollout` but bugfix template doesn't include h-rollout.md, causing confusion about rollout phase.

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

## Task: Document Checkpoint Commit → Squash Workflow

**Task-Type**: chore
**Priority**: Low
**Status**: Identified from Task 36 retrospective

Document the standard pattern: checkpoint commits → backup branch → squash → rebase.

**Problem**: Task 35 and 36 both used checkpoint commits with final squashing, but pattern isn't documented.

**Solution**: Create workflow documentation for checkpoint/squash pattern.

**Scope**:
1. **Create `docs/workflow/checkpoint-squash.md`**:
   - When to use checkpoint commits (during development)
   - How to create backup branch (`git branch $(git rev-parse --abbrev-ref HEAD)-checkpoints`)
   - How to squash (`git reset --soft <base-commit>`)
   - How to rebase dependent branches
2. **Add to workflow-steps.md**: Reference checkpoint/squash pattern

**Success Criteria**:
- [ ] Pattern documented with step-by-step instructions
- [ ] Examples showing backup branch creation and squashing
- [ ] Future tasks can reference standard pattern

**Rationale**: Standardizes effective git workflow used in recent tasks.

**Discovered**: Task 36 retrospective - checkpoint/squash pattern worked well

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

Root cause: Exclusive focus on implementation-guide/ documentation files caused deliverables in other directories (.claude/, .cig/, etc.) to be overlooked.

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
   - [ ] Stage all material changes: implementation-guide/, .claude/, .cig/, source files, etc.
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
1. **Update template**: `.cig/templates/pool/d-implementation-plan.md.template`
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

## Task: Add Status Field Review to Pre-Retrospective Checklist

**Task-Type**: chore
**Priority**: Low
**Status**: Identified from Task 35 retrospective

Add status field verification to workflow documentation as a pre-retrospective checkpoint.

**Problem**: Task 35 had f-implementation-exec.md showing "Implemented" (50%) instead of "Finished" (100%), blocking task from showing 100% completion. This was only caught when running /cig-status before retrospective.

**Solution**: Add explicit status verification step to retrospective workflow documentation.

**Scope**:
1. **Update workflow-steps.md**: Add to retrospective section (before Step 8: Execute Retrospective):
   ```markdown
   ### 7. Verify Task Status

   Before documenting retrospective learnings, verify task is actually finished:

   7.1. **Run /cig-status <task-path>** to check completion percentage
   7.2. **If <100%**: Review workflow file status fields
       - Look for "Implemented" (should be "Finished")
       - Look for "Testing" (should be "Finished")
       - Look for "Blocked" (resolve or document)
   7.3. **Update status fields** before proceeding with retrospective
   7.4. **If still <100%**: Task not finished - identify and finish missing work
   ```

2. **Update cig-retrospective.md command**: Add step 7 between current steps 6 and 7

**Success Criteria**:
- [ ] Workflow documentation includes status verification step
- [ ] Step positioned before retrospective execution (catches issues early)
- [ ] Clear guidance on what to do if status <100%
- [ ] Future tasks catch status field issues before retrospective

**Rationale**: Systematic status verification prevents completing retrospective on incomplete tasks and ensures accurate progress tracking.

**Discovered**: Task 35 retrospective - f-implementation-exec.md status was "Implemented" not "Finished"

---

## Task: Create Design-Alignment Conventions Document

**Task-Type**: chore
**Priority**: Medium
**Status**: Partial completion (Task 35 fixed command references, conventions doc remains)

**Context**: Task 35 fixed the 2 incorrect command references (`.claude/commands/cig-new-task.md` and `.claude/commands/cig-subtask.md`). The remaining work is to create conventions documentation to prevent future inconsistencies.

**Scope**:

Create `docs/conventions/design-alignment.md` to prevent future inconsistencies:

**Topics to cover**:

1. **Command/Skill Naming Audit Process**:
   - When to audit: Before committing command changes
   - What to check: All references in docs, templates, and code
   - Tools to use: grep, search patterns

2. **Naming Consistency Guidelines**:
   - Command naming patterns (e.g., `/cig-{workflow-step}-{action}`)
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
- [ ] Update template files in `.cig/templates/pool/`
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

1. **Update workflow documentation** (`.cig/docs/workflow/workflow-steps.md`):
   - Add "Security Verification" as recommended step in Testing Execution section
   - Document when security checks are required (tasks modifying scripts/libraries)
   - Document how to run verification (`/cig-security-check verify`)

2. **Update testing templates** (`.cig/templates/pool/g-testing-exec.md.template`):
   - Add "Security Verification" checkbox to execution checklist
   - Add conditional guidance: "If this task modifies helper scripts or libraries, run `/cig-security-check verify` and update hashes"

3. **Update testing plan templates** (`.cig/templates/pool/e-testing-plan.md.template`):
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

## Task: Create Permanent Security Verification Script

**Task-Type**: chore
**Priority**: Medium
**Status**: Identified during Task 32 security verification

Create a permanent, reusable security verification script instead of relying on temporary `/tmp/verify-cig-security.sh` scripts created ad-hoc.

**Problem**: Security verification currently requires creating temporary bash scripts in `/tmp` that:
- Need to be recreated each time
- Are not version controlled
- May have inconsistent logic between invocations
- Don't accumulate improvements over time

**Solution**: Create permanent security verification script in CIG scripts directory.

**Scope**:

1. **Create `.cig/scripts/verify-security`**:
   - Permanent bash script for security verification
   - Reads `.cig/security/script-hashes.json`
   - Verifies SHA256 hashes for all scripts and libraries
   - Checks file permissions (executable scripts need u+rx minimum)
   - Supports both "lib" and "libraries" sections (backward compatible)
   - Returns exit code 0 (all verified) or 1 (failures/missing)

2. **Add to security hash tracking**:
   - Add verify-security script itself to script-hashes.json
   - Self-verifying: script can check its own integrity

3. **Update `/cig-security-check` command**:
   - Command should invoke `.cig/scripts/verify-security` for deterministic verification
   - Keep command as thin wrapper (progressive disclosure pattern)
   - Command adds user-friendly formatting and guidance

4. **Documentation**:
   - Document script in `.cig/docs/security/verification.md`
   - Add usage examples to `/cig-security-check` command
   - Document exit codes and output format

**Output Format** (same as current temporary script):
```
=========================================
CIG Security Verification Report
=========================================

Date: 2026-01-28 18:20:12
Version: 2.1
Last Updated: 2026-01-28

HELPER SCRIPTS:
---------------
✅ .cig/scripts/command-helpers/hierarchy-resolver
   SHA256: <hash> (verified)
   Permissions: 700 (expected: 0500)

❌ .cig/scripts/command-helpers/format-detector
   SHA256: <actual> (MISMATCH)
   Expected: <expected>
   Action: Update hash or review changes

PERL LIBRARIES:
---------------
✅ .cig/lib/TaskState.pm
   SHA256: <hash> (verified)

=========================================
SUMMARY
=========================================
Total files checked: 29
✅ Verified: 29
❌ Failed verification: 0
❓ Missing files: 0

✅ ALL FILES VERIFIED
CIG system integrity confirmed
```

**Benefits**:
- Deterministic, repeatable security verification
- Version controlled (improvements accumulate)
- Single source of truth for verification logic
- Can be invoked directly or via `/cig-security-check` command
- Testable (can write tests for the verification logic)

**Success Criteria**:
- [ ] `.cig/scripts/verify-security` created and executable (0755)
- [ ] Script added to script-hashes.json (self-verifying)
- [ ] `/cig-security-check verify` uses permanent script
- [ ] Script handles both "lib" and "libraries" sections
- [ ] Exit codes documented (0=success, 1=failures)
- [ ] Documentation in `.cig/docs/security/verification.md`

**Rationale**: Temporary scripts in `/tmp` are anti-pattern for deterministic operations. Permanent script enables consistent, repeatable security verification and accumulates improvements over time.

**Related**: Task 32 (created temporary verification scripts during security check)

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
- Set `.cig/current-task` to different task number (e.g., 11)
- Verify wrapper script outputs user prompt
- Verify exit code 1 (uncorrelated)
- Clean up test fixtures after test

**For TC-I4 and TC-S2 (No Signals)**:
- Switch to main branch (loses feature branch signal)
- Clear `.cig/current-task` if present
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
**Priority**: Medium *(downgraded from High — see Task 54 update below)*

Migrate CIG from commands-based architecture to hybrid plugin model (plugin with skills), as recommended by Task 16's decision matrix scoring but not implemented due to risk-adjusted thinking.

**CRITICAL UPDATE — Task 54 Findings (2026-02-12)**:

Task 54 (Discovery: Assess current 2026 W6 skills and plugin standards) found critical blockers that invalidate migration prerequisites:

1. **Bug #17688**: Frontmatter hooks in SKILL.md don't trigger within plugins. This is the single most important finding — it invalidates the primary value proposition of plugin migration (hooks automation). Community traced root cause to different loader functions for plugin vs local components. Affects both inline and marketplace plugins.
2. **Bug #22087**: SubagentStop hook failure (34 upvotes, 16 comments). Agents complete work but fail on termination. Blocks multi-agent orchestration, which CIG uses extensively.
3. **No deprecation signal**: Task 54 found no evidence that commands are deprecated. Commands are merged into skills in v2.1.3 and continue to work. The assumption below that "commands are deprecated" is **not supported by evidence**.
4. **Task 54 recommendation**: Keep Commands, 85% confidence. Decision matrix (4 options × 8 weighted criteria) reaffirmed Task 16's adjusted recommendation.

**Prerequisite added**: Bug #17688 must be resolved before migration can proceed.
**Review trigger**: Q3 2026 or when Bug #17688 is fixed, whichever comes first.
**See**: `implementation-guide/54-discovery-assess-current-2026-w6-skills-and-plugin-stds/f-implementation-exec.md` for full research.

---

**Context - Task 16 Decision Matrix**:

Task 16 (Discovery: Investigate skills configuration and integration) evaluated 4 architecture options with weighted criteria scoring:
- **Hybrid Plugin: 55/75** ← HIGHEST SCORE
- Keep Commands: 47/75
- Plugin (skills-only): 39/75
- Skills-Only: 37/75

**The Issue**: Despite Hybrid Plugin scoring highest, Task 16's recommendation was "Keep Commands" based on "risk-adjusted thinking" (reversibility, migration risk, uncertain hooks value). During retrospective discussion, it was acknowledged that this may have been **post-hoc rationalization** - the lower-scoring option was selected due to implementation focus bias. However, Task 54's independent research reaffirmed the "Keep Commands" recommendation with additional evidence (Bug #17688, no deprecation signal, community consensus).

**Why This Decision Needs Revisiting** *(original rationale, partially invalidated by Task 54)*:

~~The landscape has changed significantly since Task 16 (2026-01-14):~~
1. ~~**Commands are deprecated**: Anthropic is focusing on skills, commands looking increasingly legacy~~ **Task 54 found no deprecation signal. Commands merged into skills in v2.1.3 and continue to work.**
2. **Task 11 blocked by unfixable bug**: Claude Code's `$ARGUMENTS` expansion bug (unbalanced sigils with special characters) prevents secure argument passing to commands. Reported to Anthropic but sitting unanswered. *(Still valid — but skills migration blocked by Bug #17688)*
3. ~~**Hybrid Plugin avoids the bug**: Skills don't use `!{path} $ARGUMENTS` pattern, bypassing the security issue entirely~~ **True, but plugin hooks are broken (#17688), so the primary benefit is unavailable.**
4. ~~**"Safety" of Keep Commands was illusory**: The rationale for choosing Keep Commands (safety, reversibility) no longer holds when the platform is deprecating commands~~ **Task 54 confirmed Keep Commands remains safe — no deprecation signal found.**

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
**Priority**: Blocked (was High)
**Status**: BLOCKED - Cannot rollout until skills migration completes

**Blocker**: Task 11 is blocked at 25% completion. The secure argument parsing work discovered an unfixable `$ARGUMENTS` bug in Claude Code's command system (special characters cause security vulnerabilities). Commands are deprecated by Anthropic. Task 11 cannot be completed or rolled out until "Migrate CIG to Hybrid Plugin Model" task completes, which will convert commands to skills and bypass the `$ARGUMENTS` bug entirely.

**Original Intent**: Deploy updated CIG command files with secure argument parsing pattern. All 8 workflow commands (cig-plan, cig-requirements, cig-design, cig-implementation, cig-testing, cig-rollout, cig-maintenance, cig-retrospective) have been updated with LLM-level format validation to prevent command injection. Changes are on branch `bugfix/11-only-pass-needed-args-to-scripts`.

**Unblock Strategy**: Complete "Migrate CIG to Hybrid Plugin Model" task first (see BACKLOG entry above), then resume Task 11 with skills architecture.

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

## ✓ Task: Fix CIG Commands to Work from Any Directory

**Task-Type**: bugfix
**Priority**: High
**Status**: ✓ Complete (Task 36 - 2026-02-06)

Fixed CIG workflow commands to work regardless of current working directory by adding git root detection to all 17 command files.

**Solution Implemented**: Added bash snippet to detect git repository root and cd to it before execution:
```bash
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
    echo "Error: Not in a git repository. CIG commands must be run from within a git repository."
    exit 1
fi
cd "$GIT_ROOT"
echo "Working directory: $GIT_ROOT"
```

**Results**:
- All 17 command files updated (.claude/commands/cig-*.md)
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

---

## Task: Audit CIG Commands for Hardcoded Data

**Task-Type**: chore
**Priority**: Low
**Status**: Follow-up from Task 43

Audit all CIG command files to identify and eliminate hardcoded data that should be read from configuration files instead.

**Scope**:
- Check all `.claude/commands/cig-*.md` files for hardcoded lists, paths, or configuration values
- Identify data that duplicates information in `script-hashes.json`, `cig-project.json`, or other config files
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
- Add to `.cig/docs/workflow/` directory
- Include in command help or error messages when phase skipped

**Identified in**: Task 43 retrospective (j-retrospective.md)
