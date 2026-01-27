# Changelog

All notable changes to the Code Implementation Guide (CIG) project are documented in this file, organized by task.

## Task 30: Fix v2.0 Format Detection Bug in TaskPath.pm

**Status**: Complete (2026-01-27)
**Duration**: 2.5 hours (vs. 1-1.5 days estimated = **6x faster**)
**Impact**: Critical bug fix - all v2.0 tasks were misdetecting as v1.0, breaking format-dependent script routing

### Problem Discovered

During user testing with Task 24, discovered all v2.0 tasks were misdetecting as v1.0 format:
- **Root Cause**: Line 213 in CIG::TaskPath::detect_format() was checking for v2.1 file names (`a-task-plan.md`, `d-implementation-plan.md`) instead of v2.0 file names (`a-plan.md`, `d-implementation.md`)
- **Impact**: hierarchy-resolver, status-aggregator, and context-inheritance trampolines all routed v2.0 tasks to wrong version-specific scripts
- **Scope**: Affected majority of repository (Tasks 1-24 are v2.0 format)

### File Naming Confusion

Task 29 renamed files for v2.1 format, creating two distinct naming conventions:
- **v2.0 format** (8 files): `a-plan.md`, `d-implementation.md`, `e-testing.md`, etc. (shorter names)
- **v2.1 format** (10 files): `a-task-plan.md`, `e-testing-plan.md`, `f-implementation-exec.md`, etc. (longer names)

Detection logic must use **v2.0 names** when checking for v2.0 tasks, not v2.1 names.

### Changes Implemented

**Phase 1: Core Detection Logic**
- Added `detect_format()` function to CIG::TaskPath with header-based detection + file fallback
- Fixed line 213 to check for correct v2.0 file names (`a-plan.md`, `d-implementation.md`)
- Added version mismatch warning system (detects when headers don't match file structure)
- Consolidated trampoline detection logic - status-aggregator and context-inheritance now use CIG::TaskPath::resolve()
- **Code quality**: 88 lines duplicate logic → 42 lines consolidated (50% reduction)

**Phase 2: Template Headers**
- Updated 10 v2.1 templates to emit "Template Version: 2.1" (was incorrectly "2.0")
- Templates: a-task-plan, b-requirements-plan, c-design-plan, d-implementation-plan, e-testing-plan, f-implementation-exec, g-testing-exec, h-rollout, i-maintenance, j-retrospective

**Phase 3: Task Migrations**
- Migrated Task 26 headers (10 files - feature task with all a-j files)
- Migrated Task 30 headers (7 files - bugfix task: a, c, d, e, f, g, j)

**Phase 4: Security and Testing**
- Updated script-hashes.json with new SHA256 hashes for 3 modified files
- Executed 17 tests (13 functional + 4 non-functional) - **100% pass rate**
- Critical regression test TC-11 validates Task 24 now correctly detects as v2.0

### Test Results

- **Pass Rate**: 17/17 executed tests (100%)
- **Performance**: 12-13ms vs. 100ms target (**8.3x faster**)
- **Coverage**: 100% of implemented functionality
- **Bug Fix Validated**: Task 24 and all v2.0 tasks now correctly detect as v2.0

### Files Modified

- 1 library: `.cig/lib/CIG/TaskPath.pm` (added detect_format, fixed line 213)
- 2 trampolines: status-aggregator, context-inheritance (consolidated detection)
- 8 templates: v2.1 templates updated to version 2.1
- 17 task files: Task 26 (10 files) + Task 30 (7 files) migrated to v2.1 headers
- 1 security: script-hashes.json updated

**Total**: 25 files changed, 1577 insertions(+), 96 deletions(-)

### Key Learnings

- **File naming is critical**: v2.0 vs v2.1 naming differences must be explicitly documented
- **Test all version scenarios**: Regression tests should cover v1.0, v2.0 (migrated + native), and v2.1
- **User testing is invaluable**: Real-world usage (Task 24) caught bug that systematic testing missed
- **Status field standardization**: Custom status values ("In Progress (Updated...)") break status-aggregator parsing
- **AI development velocity**: 2.5 hours actual vs. 8-12 hours estimated (6x speedup from AI-assisted development)

---

## Task 29: Fix v2.1 Workflow File Order and Next Step References

**Status**: Complete (2026-01-26)
**Impact**: Corrects v2.1 workflow to follow test-first principles, enabling test planning before implementation execution

### Philosophy: Test Planning as Thinking Tool

Fixed critical workflow design flaw where implementation execution occurred before test planning. The corrected order (plan tests → execute implementation → execute tests) enables test planning to serve as a thinking tool that deepens understanding before code is written.

**Key insight**: Test planning isn't about having tests ready to run - it's about understanding what "working" means before implementing. By forcing yourself to think through measurability, edge cases, and success criteria, you write better implementation code.

**This is planning-driven development with TDD principles**, not traditional TDD. You're planning your test approach (not writing test code) to gain clarity about requirements and outcomes.

### File Order Correction

**Old order** (incorrect):
- d-implementation-plan.md → **e-implementation-exec.md** → **f-testing-plan.md** → g-testing-exec.md

**New order** (correct):
- d-implementation-plan.md → **e-testing-plan.md** → **f-implementation-exec.md** → g-testing-exec.md

### Changes Implemented

**Phase 1: Template Renaming**
- Renamed 2 pool template files using git mv (preserves history)
- Updated 10 symlinks across 5 task types (feature, bugfix, hotfix, chore, discovery)
- All renames tracked by git at 100% similarity

**Phase 2: Reference Updates (60+ references across 11 components)**
- Updated 4 template "Next Action" fields (d, e, f, g)
- Updated CIG::WorkflowFiles::V21 module (5 task type arrays)
- Updated blocker-patterns.md (5 references)
- Updated 6 workflow command files
- Updated workflow documentation (workflow-steps.md, workflow-overview.md) with philosophy
- Fixed format detection bug in 3 trampoline scripts (critical for template-copier)

**Phase 3: Migration Script**
- Created `.cig/scripts/migrations/migrate-v2.1-file-order`
- Validates task is v2.1 before migrating (safe for v2.0/v1.0)
- Three-way file swap preserves git history
- Idempotent design (safe to re-run)
- Added to script-hashes.json with SHA256 verification

**Phase 4: Task Migrations**
- Migrated Tasks 26, 27, 28, 29 to corrected file order
- All migrations successful with 100% git similarity
- Zero breaking changes for existing workflows

### Testing Results

Comprehensive testing validated all aspects of the fix:
- **16/16 test cases passed** (13 functional + 3 non-functional)
- **100% coverage** (all 11 components verified)
- **Zero defects** found during testing
- **Zero regressions** for v2.0 or v1.0 tasks

**Performance**: Both helper scripts exceeded targets significantly
- template-copier: 31ms (target <5s, 160x faster)
- status-aggregator: 27ms (target <100ms, 3.7x faster)

### Documentation Updates

**Philosophy Documentation**:
- Added "Test Planning as Thinking Tool" section to workflow-overview.md
- Explains why e before f (test planning deepens understanding before implementation)
- Distinguishes from traditional TDD (planning not coding tests first)
- Clarifies this is planning-driven development with TDD principles

**Workflow Documentation**:
- Updated workflow-steps.md with v2.1 format description
- Updated all file references throughout documentation
- Added version-aware guidance (e-testing-plan for v2.1, f-testing-plan for v2.0)

### Key Learnings

**Systematic planning ROI**: 40 min planning investment saved 6+ hours (no rework, no debugging). 10-step implementation plan eliminated decision paralysis and enabled confident progress.

**Checkpoint commits reduce risk**: 3 checkpoint commits during Phase 2 provided clean rollback points every 1.5-2 hours. Cost minimal (5 min per commit), benefit high (eliminated fear of breaking changes).

**LLM acceleration significant**: Actual duration 0.3 days vs estimate 2-3 days (5-9x faster). File operations, reference hunting, and script writing all dramatically faster with LLM assistance.

**git mv preserves history automatically**: Using git mv instead of manual rename preserved full file history at 100% similarity, with no manual tracking needed.

### System Status

- v2.1 workflow file order corrected systemwide
- All templates create tasks with correct file names
- All existing v2.1 tasks migrated successfully
- Philosophy documented for future reference
- Migration script available for any future file order changes
- Zero regressions, 100% test coverage, all systems operational

---

## BACKLOG Task: hierarchy-resolver Trampoline Entry Point [Already Complete]

**Status**: Complete (Task 27, 2026-01-23) - Task was based on false premise
**Impact**: Clarification of existing architecture

### Background

A BACKLOG task "Create hierarchy-resolver Trampoline Entry Point" was identified, claiming hierarchy-resolver was missing its entry point. Investigation revealed this was incorrect:

**Actual state**:
- hierarchy-resolver exists as `.cig/scripts/command-helpers/hierarchy-resolver` (created in Task 8, renamed in Task 27)
- It IS the entry point - no separate trampoline needed
- Version-agnostic because hierarchy resolution behaviour is identical across all versions (uses CIG::TaskPath internally)
- Registered in script-hashes.json, referenced correctly by all commands
- Tested working with v2.0 and v2.1 tasks

**Why no trampoline needed**: Unlike status-aggregator (which needs version-specific output formatting), hierarchy-resolver just resolves task paths - same logic for all versions.

**Task 27** (Standardise Script Naming) renamed hierarchy-resolver.pl → hierarchy-resolver, completing the "Alternative (simpler)" approach mentioned in the BACKLOG task description.

---

## BACKLOG Task: Clarify That Requirements and Design Are Planning Steps [Already Complete]

**Status**: Complete (Task 29, 2026-01-26) - Problem addressed via "Scope & Boundaries" sections
**Impact**: Eliminated LLM confusion about planning vs execution phases

### Background

A BACKLOG task "Clarify That Requirements and Design Are Planning Steps" was identified, describing LLM confusion where:
- LLM would ask "should I exit plan mode?" when user ran `/cig-requirements` or `/cig-design`
- LLM treated only `/cig-plan` as planning, misidentified requirements and design as execution
- This created "very frustrating" user experience

### Already Fixed in Task 29

**Task 29** (Fix v2.1 Workflow File Order) updated all workflow command files with **"Scope & Boundaries"** sections:

**Example from cig-requirements-plan.md**:
```markdown
## Scope & Boundaries

**This step**: Complete the requirements planning document (b-requirements-plan.md)...

**Not this step**: Design decisions, implementation planning, code writing, or testing.
```

**Example from cig-design-plan.md**:
```markdown
## Scope & Boundaries

**This step**: Complete the design planning document (c-design-plan.md)...

**Not this step**: Implementation (that's d-implementation-plan + f-implementation-exec), testing, or deployment.
```

These sections clearly delineate what IS and IS NOT in scope for each phase, eliminating confusion about whether requirements/design are planning or execution.

### Verification

**No issues observed since Task 29 changes** (2026-01-26 through 2026-01-27):
- ✓ No "should I exit plan mode?" questions during requirements or design phases
- ✓ LLM correctly treats requirements and design as planning activities
- ✓ Scope boundaries clearly communicate phase responsibilities

The BACKLOG task requested explicit "⚠️ PLANNING PHASE" warnings, but the "Scope & Boundaries" approach proved equally effective and more idiomatic (follows "This step / Not this step" pattern used throughout CIG commands).

**Conclusion**: Problem solved differently than BACKLOG task specified, but user confirms no issues observed since fix.

---

## BACKLOG Task: Fix Status Aggregator to Only Check Main Status Sections [Already Complete]

**Status**: Complete (Task 25, 2026-01-23) - Problem eliminated by file separation architecture
**Impact**: No multiple Status sections exist in v2.1 format

### Background

A BACKLOG task "Fix Status Aggregator to Only Check Main Status Sections" was identified, claiming:
- c-design.md has 3 Status sections (main + embedded implementation plan + embedded testing plan)
- status-aggregator showed 25% when task was actually complete due to not all Status sections being updated
- Confusing which Status sections "count" toward task completion

### Already Solved by Task 25 Architecture

**Task 25** (Implement v2.1 workflow with planning/execution separation) eliminated this problem entirely through **file separation**:

**Old structure (hypothetical v2.0 concern)**:
- c-design.md could theoretically contain multiple Status sections if implementation/testing plans were embedded

**New structure (v2.1 format)**:
- c-design-plan.md (design planning) - 1 Status section
- d-implementation-plan.md (implementation planning) - 1 Status section
- e-testing-plan.md (testing planning) - 1 Status section

Each planning file has exactly ONE `## Status` section, so there's no ambiguity about which section "counts" for status aggregation.

### Verification

**Checked current codebase**:
- ✓ All templates have exactly 1 `## Status` section per file
- ✓ All actual task files checked have exactly 1 `## Status` section per file
- ✓ No multiple Status sections found in any workflow file

**Note on Task 30's 25% issue**: That was a **different problem** - custom status values ("In Progress (Updated...)") broke the parser. This was fixed by using canonical status values ("Finished"). Not related to multiple Status sections.

**Conclusion**: File separation architecture inherently prevents the problem this task was trying to solve. No code changes needed.

---

## Task 4: Migration Tools to Migrate v1.0 to v2.0

**Status**: Complete
**Impact**: Enables safe migration of existing v1.0 tasks to v2.0 hierarchical structure with rollback capability

### Migration Scripts

Automated migration tooling discovered issues with hardcoded status values and disconnected configuration. Extended implementation to include configuration-driven status validation system.

**Three Migration Scripts**:
1. `migrate-v1-to-v2.sh` - Migrate v1.0 tasks to v2.0 with git-first backup strategy
2. `validate-migration.sh` - Validate migration integrity (Template Version, structure, content)
3. `rollback-migration.sh` - Rollback migration using git tags or manual backup

**Migration Features**:
- Git-first backup strategy using tags (instant rollback with `git reset --hard`)
- Directory structure migration: `{type}/{num}-{desc}` → `{num}-{type}-{desc}`
- Workflow file renaming: `plan.md` → `a-plan.md`, `requirements.md` → `b-requirements.md`, etc.
- Template Version tagging (adds `Template Version: 2.0` field)
- Content integrity validation with SHA256 hash comparison
- Idempotent operation (safe to run multiple times)
- Dry-run mode for preview

### Configuration-Driven Status System

During rollout discovered that status values were hardcoded and disconnected from configuration, with no LLM guidance on valid values. Enhanced to make status system self-documenting and configuration-driven.

**Status System Features**:
- Status values defined in `cig-project.json` as object (status name → percentage)
- `status-aggregator.sh` loads from config with fallback to defaults
- Unknown status warnings to stderr (non-breaking, shows: actual, mapped, effective values)
- LLM guidance in workflow commands referencing central documentation
- Self-documenting via configuration file

**Status Values**:
- Backlog (0%) - Task not started
- To-Do (0%) - Task ready to begin
- In Progress (25%) - Work actively underway
- Implemented (50%) - Code complete, not tested
- Testing (75%) - Testing in progress
- Finished (100%) - Fully complete

**Design Principles**:
- Progressive disclosure: Commands reference `.cig/docs/workflow/workflow-steps.md#status-values`
- Non-breaking warnings: Unknown statuses default to 0% with stderr warning
- Backward compatible: Fallback to hardcoded defaults if config missing/invalid
- Configuration format enables project customization of workflow stages

### Documentation Updates

**Migration Documentation**:
- Created comprehensive migration guide (`.cig/docs/migration.md`) covering why/how/safety
- Migration guide explains v1.0 limitations vs v2.0 benefits
- Six-step migration process with rollback procedures
- Prerequisites, safety features, and troubleshooting documented

**Workflow Documentation**:
- Status values section added to workflow-steps.md
- jq command examples for querying valid statuses
- All 8 workflow commands include status field guidance

### Testing Results

Comprehensive testing validated all aspects of migration and status systems:
- 24/24 migration test cases passed (3 skipped: rollback, manual backup, edge cases)
- Status loading from config: PASSED
- Unknown status warnings: PASSED
- Fallback with missing config: PASSED (bug fixed during testing)
- Template validation: PASSED
- Workflow command instructions: PASSED (8/8 verified)

### System Status

- Migration tools fully operational and tested
- Status system self-documenting via configuration
- Safe migration path from v1.0 to v2.0 with rollback capability
- Git-first backup strategy provides instant rollback
- Configuration-driven validation reduces LLM confusion

---

## Task 3: Hierarchical Workflow System with Dynamic Step Transitions

**Status**: Complete
**Impact**: Foundational change enabling infinite task nesting with 90% reduction in LLM context consumption

### Token-Efficient Context Inheritance

Reduces LLM context consumption by 90% through structural maps that enable progressive disclosure. Instead of reading full parent files (500-1000 tokens each), LLM receives navigable document structure with headers and line ranges (50-100 tokens), preserving agency to decide what details matter.

**Key Features**:
- Status markers prevent implementation confusion by indicating reliability of parent context
- Dual output formats (markdown/JSON) serve both human/LLM reasoning and programmatic automation
- Version checking ensures workflow files remain compatible with CIG software as system evolves
- Enables hierarchical task decomposition with infinite nesting while maintaining context efficiency
- LLM can understand parent task decisions without drowning in irrelevant details

### Core Infrastructure

Establishes foundation for infinite task nesting while maintaining LLM context efficiency through progressive disclosure.

**Central Template Pool**:
- Symlinks eliminate duplication across task types
- Single source of truth in `.cig/templates/pool/`
- Task-type-specific symlinks (feature: 8 files, bugfix: 5 files, hotfix: 5 files, chore: 4 files)

**Five Helper Scripts** (Automation Layer):
1. `hierarchy-resolver.sh` - Task path to directory resolution with metadata
2. `format-detector.sh` - Template version detection with upgrade suggestions
3. `status-aggregator.sh` - Progress calculation from status markers using defined formula
4. `template-version-parser.sh` - Standalone version field extraction
5. `context-inheritance.pl` - Parent context structural maps with headers and line ranges

**Eight Workflow Commands** (Complete Task Lifecycle):
- `/cig-plan` - Planning phase with decomposition signals
- `/cig-requirements` - Requirements gathering with acceptance criteria
- `/cig-design` - Architecture and design decisions
- `/cig-implementation` - Code changes and validation
- `/cig-testing` - Test strategy and execution
- `/cig-rollout` - Deployment strategy and monitoring
- `/cig-maintenance` - Ongoing support and optimization
- `/cig-retrospective` - Lessons learned and recommendations

**Design Principles**:
- Consistent 8-step pattern across all commands
- Each command references shared context documentation (DRY principle)
- Commands use helper scripts for deterministic operations
- Progressive disclosure pattern: Commands reference workflow step docs instead of duplicating content
- LLM receives structural information to make intelligent decisions

**Security Model**:
- SHA256 hashes stored for all helper scripts in `.cig/security/script-hashes.json`
- Permissions enforced (u+rx minimum, typically 0500)
- Git-based version tracking

### Documentation and User-Facing Guides

Finalizes v2.0 implementation with comprehensive workflow documentation and updated project guides. Users now have complete reference for 8-step workflow system, task decomposition principles, and migration from v1.0.

**Workflow Documentation** (3200 words total):
- Overview: 8-step hierarchical workflow and decomposition principles (400 words)
- Step-by-Step Guidance: Detailed focus/avoid patterns for each of 8 steps (2400 words)
- Decomposition Guide: 5 universal signals and hierarchical numbering explanation (400 words)

**README.md Updates** (v2.0 Features):
- Infinite task nesting with decimal numbering (1, 1.1, 1.1.1, ...)
- Token-efficient context inheritance (90% reduction in LLM context consumption)
- Progressive disclosure and central template pool
- All 8 workflow commands with examples
- Migration notes for breaking changes from v1.0

**CLAUDE.md Updates** (LLM Consumption):
- Concise architecture overview emphasizing token efficiency
- All 16 commands organized by category
- Progressive disclosure pattern explanation
- Security model and helper script descriptions

### Breaking Changes from v1.0

- **`/cig-new-task`**: New signature `<num> <type> "description"` for hierarchical numbering (was `<type> <num> <description>`)
- **`/cig-extract`**: Task-based paths instead of file paths (backward compatible during migration period)
- **`/cig-subtask`**: Context inheritance via helper scripts, not manual reading

### System Status

- Fully operational with complete documentation
- Users can leverage hierarchical workflows, context inheritance, and structured task progression
- 90% token reduction enables handling complex multi-level project structures
- Breaking changes clearly documented with migration path

---

## Previous Tasks

### Task 2: Script-Based CIG Command Helpers

Complete script-based CIG command helpers implementation with security fixes.

### Task 1: CIG Commands Implementation

Complete CIG commands implementation with official Anthropic patterns.

### Task 0: Initial System Design

- CIG project configuration system and unified task commands
- Comprehensive CIG command reference
- Initial implementation guide system design
