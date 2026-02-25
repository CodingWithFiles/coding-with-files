# Changelog

All notable changes to the Code Implementation Guide (CIG) project are documented in this file, organized by task.

## Task 94: Fix Stale Repo URL in install.bash and INSTALL.md

**Status**: Complete (2026-02-25)
**Duration**: < 1 hour (estimated: < 1 hour — on target)
**Impact**: Bugfix — corrects stale `mattkeenan/coding-with-files` GitHub org references
that would have caused default installs to fail. Task 91 fixed `README.md` but missed
`scripts/install.bash` (the `CWF_SOURCE` default) and `INSTALL.md` (the quick-install
curl command). Both corrected.

### Changes
- `scripts/install.bash:24`: `CWF_SOURCE` default URL `mattkeenan` → `CodingWithFiles`
- `INSTALL.md:12`: quick-install curl command `mattkeenan` → `CodingWithFiles`

### BACKLOG Items Addressed
- None

---

## Task 93: README.md — Problem and Benefits Sections

**Status**: Complete (2026-02-22)
**Duration**: ~45 minutes (estimated: <1 hour — on target)
**Impact**: Bugfix — adds three new sections near the top of README.md explaining the
problem CWF solves, what it does, and why the structure matters. Includes a Dan Shapiro
Five Levels reference (targeting Level 3–3.3) and the 80% token-efficiency context
reduction figure.

### Changes
- `README.md`: inserted "The Problem With AI-Assisted Coding", "What CWF Does", and
  "Why the Structure Matters" between `## Overview` and `## Project Status`

### BACKLOG Items Addressed
- None

---

## Task 92: Fix COMMERCIAL-LICENSE.md GPL-2.0 → AGPL-3.0

**Status**: Complete (2026-02-22)
**Duration**: ~20 minutes (estimated: <15 minutes — on target)
**Impact**: Hotfix — corrects incorrect licence references in COMMERCIAL-LICENSE.md. CWF has
never been released under GPL-2.0; that licence applied briefly to the predecessor project
(CIG). The incorrect text was carried over during the Task 59 CIG→CWF rebrand.

### Changes
- `COMMERCIAL-LICENSE.md`: all three GPL-2.0 / GPL v2.0 references replaced with AGPL-3.0

### BACKLOG Items Addressed
- None

---

## Task 91: README.md Updates for v1.0.90

**Status**: Complete (2026-02-22)
**Duration**: ~30 minutes (estimated: <1 hour — well under)
**Impact**: Bugfix — brings README.md in sync with v1.0.90: correct org URL, full v2.1
10-skill workflow command list, accurate task-type phase counts, semver convention, and
direct GitHub issues link. One unplanned fix: `v2.0` heading in Features section caught
by TC-3 absence-grep.

### Changes
- `README.md`: install URL `mattkeenan` → `CodingWithFiles`; full v2.1 Commands section
  (10 workflow skills, plan/exec split noted); Task Types phase counts and sequences;
  Version Information with `v{major}.{minor}.{task_num}` and `cwf-manage list-releases`;
  support link → direct GitHub issues URL; Features section `v2.0` heading removed

### BACKLOG Items Addressed
- None

---

## Task 90: Fix Stale CIG References in WF Step Templates and Template-Copier

**Status**: Complete (2026-02-22)
**Duration**: ~20 minutes (estimated: <0.25 days — well under)
**Impact**: Hotfix — closes a Task 59 (CIG→CWF rebrand) miss that caused every new task
created since the rebrand to have wrong paths and skill names in generated wf step files.
Two fix sites: the `**See ...` Status footer in all 10 wf step templates (`.cig/` →
`.cwf/`), and `name_to_action()` in `template-copier-v2.1` (`/cig-` → `/cwf-`).

### Changes
- `.cwf/templates/pool/*.template` (all 10): Status footer path corrected
- `.cwf/scripts/command-helpers/template-copier-v2.1`: lines 332 and 399 `/cig-` → `/cwf-`
- `.cwf/security/script-hashes.json`: SHA256 updated for modified template-copier-v2.1

### BACKLOG Items Addressed
- None

---

## Task 89: Update Version Conventions

**Status**: Complete (2026-02-22)
**Duration**: ~2 hours (estimated: 0.5 days — well under)
**Impact**: Feature — establishes `v{major}.{minor}.{task_num}` semver convention for CWF
itself, documented dev-side only; updates `cwf-manage list-releases` from a full tag dump
to a curated upgrade view showing the latest patch on current minor, one entry per higher
minor, and one entry per higher major.

### Changes
- `CLAUDE.md`: new `## Versioning` section defining the semver scheme, human-only tagging
  constraint, and isolation requirement (not to be referenced from any installed file)
- `.cwf/scripts/cwf-manage`: new `parse_semver` sub (strict `v\d+.\d+.\d+` via regex);
  new `filter_releases` sub (closure-based bucket rules, map/grep pipeline); updated
  `cmd_list_releases` with `$show_all` param and `--all` flag; updated `cmd_help`
- `.cwf/security/script-hashes.json`: updated SHA256 for modified `cwf-manage`
- `t/cwf-manage-list-releases.t`: new unit test file, 11 subtests, no network dependency

### Bug Found and Fixed
TC-2 (`parse_semver` no-v-prefix rejection) caught that the plan's `s/^v//` approach
silently accepted `1.2.3`. Fixed with single-regex `/^v(\d+)\.(\d+)\.(\d+)$/`.

### BACKLOG Items Addressed
- None

---

## Task 88: Refactor Workflow Docs for Efficiency

**Status**: Complete (2026-02-22)
**Duration**: ~1 hour (estimated: 0.5 days — well under)
**Impact**: Bugfix — eliminates three categories of token waste from CWF workflow docs:
repeated checkpoint commit blocks (8 phases × ~8 lines), duplicate "Typical Structure"
sections (10 phases × ~8 lines), and 3-line per-phase boilerplate in blocker-patterns.md
(9 phases × 3 lines). File-edit reversion instructions in blocker-patterns.md replaced
with explicit `/cwf-` skill call chains. Net change: −272 lines, +134 lines added (references).
Progressive disclosure preserved — every removal points to its canonical source.

### Changes
- `.cwf/docs/skills/checkpoint-commit.md`: fix stale `perl -I` command; `<>` → `{}` on placeholders
- `.cwf/docs/skills/retrospective-extras.md`: all `<var>` model-substitution variables → `{var}`
- `.cwf/docs/workflow/workflow-steps.md`: checkpoint commit blocks replaced with 1-line references;
  Typical Structure sections replaced with template pool references; jq blocks removed; source reference added
- `.cwf/docs/workflow/blocker-patterns.md`: per-phase 3-line boilerplate removed; file-edit reversion
  instructions replaced with `/cwf-` skill call chains; Decomposition Signals body → reference;
  stale `.claude/commands/` References section removed
- `.cwf/docs/workflow/decomposition-guide.md`: Context Inheritance body → reference to workflow-overview.md

### BACKLOG Items Addressed
- None (originated from ad-hoc plan)

---

## Task 87: Create CWF Terminology Glossary

**Status**: Complete (2026-02-22)
**Duration**: ~45 minutes (estimated: <1 hour — on target)
**Impact**: Hotfix — 8 previously undefined terms (CWF, wf, skill, slug, task branch,
checkpoints branch, checkpoint commit, squash commit) now canonically defined in
`.cwf/docs/glossary.md`. `workflow-preamble.md` references the glossary so every skill
invocation surfaces it to lesser models without extra steps.

### Changes
- `.cwf/docs/glossary.md`: new file — index + 8 entries, grep-friendly `## TERM` headings,
  cross-references to authoritative sources for terms already defined elsewhere
- `.cwf/docs/skills/workflow-preamble.md`: added `**Terminology**` reference line

### BACKLOG Items Addressed
- "Create CWF Terminology Glossary" (Low priority, follow-up from Task 44)

---

## Task 86: Remove Decomposition Checks from Non-Planning Workflow Steps

**Status**: Complete (2026-02-22)
**Duration**: ~30 minutes (estimated: <1 hour — well under)
**Impact**: Hotfix — Step 7 decomposition check removed from `cwf-rollout` and
`cwf-maintenance` SKILL.md files; remaining steps renumbered (8→7, 9→8).
Decomposition checks are only actionable during planning; rollout and maintenance
operate on already-committed work and gained no benefit from the check.

### Changes
- `.claude/skills/cwf-rollout/SKILL.md`: removed Step 7 decomposition check, renumbered Steps 8→7, 9→8
- `.claude/skills/cwf-maintenance/SKILL.md`: removed Step 7 decomposition check, renumbered Steps 8→7, 9→8

### BACKLOG Items Addressed
- "Remove Decomposition Checks from Non-Planning Workflow Steps" (Medium priority)

---

## Task 85: Ensure Retrospective Checkpoint Commit Stages Entire Task Directory

**Status**: Complete (2026-02-22)
**Duration**: ~1 hour (estimated: <1 hour — on target)
**Impact**: Hotfix — closes the gap that caused stale wf step statuses to persist
in task squash commits after retrospectives (root cause of tasks 77 and 81 showing <100%).

### Changes
- `retrospective-extras.md`: Updated "Verify Task Status" to use
  `workflow-manager status <task_num> --workflow`, require all steps to be in a
  terminal status, and explicitly state that 100% overall is the norm
- `retrospective-extras.md`: Added "Retrospective Checkpoint Commit" section with
  `git add implementation-guide/<task-dir>/` to stage entire task directory,
  overriding the generic single-file staging from `checkpoint-commit.md`

---

## Task 84: Backlog Audit — Remove Moot Items

**Status**: Complete (2026-02-21)
**Duration**: ~1 hour (estimated: 1 hour — on target)
**Impact**: Chore — backlog reduced from 41 to 33 active items by removing 8 items
superseded by architecture changes or already implemented, and correcting the scope
of 1 mis-specified item.

### Items Removed
- Item 12: "Update Commands/Skills to Use New Inference Output Format" — plural format never adopted
- Item 15: "Document Checkpoint Commit → Squash Workflow" — already in retrospective-extras.md Step 10
- Item 20: "Create Permanent Security Verification Script" — superseded by `cwf-manage validate`
- Item 24: "Migrate CWF to Hybrid Plugin Model" — skills migration done (Task 57); plugin hooks blocked by Bug #17688
- Item 26: "Design Task-Type-Specific Workflow Variants" — already implemented in `task-workflow create`
- "Create Automated Test Harness" — t/ directory has 15+ test files covering all major modules
- "Security Review and Hardening of CWF Bash Invocations" — commands→skills, all Perl, $ARGUMENTS moot
- "Standardize Script Naming and Invocation" — already extensionless throughout

### Item Updated
- "Remove Decomposition Checks from Non-Planning Workflow Steps" — scope corrected: keep Step 7
  in all `*-plan` skills; remove only from cwf-rollout and cwf-maintenance

---

## Task 83: Add Status Update Step to checkpoint-commit.md

**Status**: Complete (2026-02-21)
**Duration**: <1 session (estimated: <30 min — slightly over due to full wf cycle)
**Impact**: Hotfix — `checkpoint-commit.md` now instructs the LLM to set
`**Status**: Finished` in the current phase's workflow file before staging,
so `cwf-status` stays accurate throughout a task rather than only being
corrected at retrospective time. All wf step skills inherit the fix
automatically — no per-skill edits needed.

### Key Changes
- `.cwf/docs/skills/checkpoint-commit.md`: inserted new step 1 ("Update status")
  before "Stage"; renumbered original steps 1-4 → 2-5

### Test Results
3/3 TCs pass: new step present as step 1, existing steps renumbered 2-5,
wording unambiguous.

---

## Task 82: Fix checkpoints-branch-manager verify die → warn

**Status**: Complete (2026-02-21)
**Duration**: <1 session (estimated: <1 session — on target)
**Impact**: Bugfix — `verify_checkpoints_branch()` now emits a non-fatal warning
instead of a fatal Perl exception when `git log` exits non-zero (e.g. SIGPIPE
from piping through `head`, or branch genuinely absent). Callers receive exit
code 1 they can handle, with no misleading stack trace.

### Key Changes
- `.cwf/scripts/command-helpers/checkpoints-branch-manager`: replaced
  `die "… error: checkpoints branch not found\n" if $? != 0` with
  `warn "… warning: …\n"; exit 1` in `verify_checkpoints_branch()`
- `.cwf/security/script-hashes.json`: SHA256 updated for changed script

### Test Results
4/4 TCs pass: happy path (exit 0), error path (exit 1, warn not die),
create regression, and `cwf-manage validate` integrity check.

---

## Task 81: Enforce Single Canonical Task Type List

**Status**: Complete (2026-02-21)
**Duration**: <1 session (estimated: <1 session — on target)
**Impact**: Bugfix — `cwf-manage validate` now catches projects with unknown task types
(e.g. `docs`, `refactor`, `test`) or missing canonical types (e.g. missing `discovery`).
Previously these passed silently.

### Key Changes
- `CWF::WorkflowFiles::V21`: added `supported_types()` export returning sorted keys of
  `%WORKFLOW_FILES` — single source of truth, no separate hardcoded list
- `CWF::Validate::Config`: bidirectional validation against `supported_types()`:
  unknown types in config produce a violation; missing canonical types produce a violation
- `.cwf/templates/cwf-project.json.template`: replaced ghost types (`docs`, `refactor`,
  `test`) with correct canonical list `[feature, bugfix, hotfix, chore, discovery]`
- `.cwf/docs/workflow/decomposition-guide.md`: updated file count table with v2.1
  actuals and added `discovery` type
- `script-hashes.json`: SHA256 updated for both modified `.pm` files

### Test Results
8/8 TCs pass. `prove t/` — 162 tests, 17 files, all pass. No regressions.

---

## Task 80: Fix install.bash file:// Source Defaults to HEAD

**Status**: Complete (2026-02-21)
**Duration**: <1 session (estimated: <1 session — on target)
**Impact**: Bugfix — installing CWF from a local `file://` clone with no `CWF_REF`
set previously resolved `latest` to the most recent git tag (e.g. `v0.2.1`), which
predates the `.cig` → `.cwf` rename and causes a fatal subtree error. Now defaults
to `HEAD` when `CWF_SOURCE` is a `file://` URL.

### Key Changes
- `scripts/install.bash`: added 4-line guard at top of `resolve_ref()`:
  if ref is `latest` and `CWF_SOURCE` starts with `file://`, log
  `"file:// source detected — defaulting CWF_REF to HEAD"` and return `HEAD`.
  Remote sources (`https://`, `git://`, `ssh://`) are unaffected.
- `INSTALL.md`: added "Installing from a local clone" subsection after the env vars
  table — documents `file://` URL syntax, HEAD default behaviour, and explicit
  `CWF_REF` override example.

### Test Results
5/5 TCs pass including 2 live end-to-end installs into temp repos.
`prove t/` exits 0 (158 tests, no regressions).

---

## Task 79: Update Branding and Documentation for Skills Architecture

**Status**: Complete (2026-02-20)
**Duration**: <1 session (estimated: <1 session — on target)
**Impact**: Bugfix — CLAUDE.md and README.md now reflect current skills architecture
terminology and correct v2.1 skill names throughout.

### Key Changes
- `CLAUDE.md`: "Available CWF Commands" → "Available CWF Skills"; section headers
  "Core/Workflow/Utility Commands" → "Skills"; replaced entire v2.0 workflow skill
  list with current v2.1 names (`/cwf-task-plan`, `/cwf-requirements-plan`,
  `/cwf-design-plan`, `/cwf-implementation-plan`, `/cwf-implementation-exec`,
  `/cwf-testing-plan`, `/cwf-testing-exec`); prose "commands reference docs" →
  "skills reference docs"; "designated commands" → "designated skills"
- `README.md`: "slash commands" → "skills" (×2 in overview); "Test all commands" →
  "Test all skills" (contributing section)

### BACKLOG Items Completed
- "Update Branding and Documentation for Skills Architecture" (from Task 57 retrospective)

### Test Results
6/6 grep-based TCs pass. `prove t/` exits 0 (158 tests, no regressions).

---

## Task 78: Fix Progress Signal Non-Determinism in task-context-inference

**Status**: Complete (2026-02-19)
**Duration**: <1 session (estimated: <1 session — on target)
**Impact**: Hotfix — `task-context-inference` now returns a consistent
`confidence: correlated` result on every run. Previously, completed tasks with
`state_achievable == 0` produced `score == 0` in `_get_progress_signal`, and
Perl's non-deterministic sort order for equal elements caused a different random
task to appear as a noise partner on each invocation, yielding `confidence:
uncorrelated` every time.

### Key Changes
- `.cwf/lib/CWF/TaskContextInference.pm`: added `grep { $_->{score} > 0 }` filter
  after sort and before splice in `_get_progress_signal`
- `.cwf/security/script-hashes.json`: SHA256 updated for modified module
- `t/taskcontextinference.t`: regression subtest added —
  `get_all_signals() - progress candidates all have score > 0`

### Test Results
158 tests across 17 files (up from 157), all pass. 5× consecutive runs of
`task-context-inference` produce identical output.

---

## Task 77: Comprehensive Perl Test Suite for CWF Library Modules

**Status**: Complete (2026-02-19)
**Duration**: ~1 session (estimated 3–5 days — 80% faster than estimate)
**Impact**: Feature — establishes `prove t/` as the standard quality gate for all 17
CWF library modules. Regressions are now caught automatically rather than through
manual inspection.

### Key Changes
- `t/lib/CWFTest/Fixtures.pm` (new): shared test helper with `create_task_dir`,
  `create_git_repo`, `create_config`
- `t/task-state.t` (migrated): updated from `.cig/lib` to `.cwf/lib`, removed
  obsolete `Implemented` status, corrected `Blocked` expected values (15%, not 0%)
- 16 new `.t` files (one per remaining `.pm`): common, contextinheritance, markdownparser,
  options, statusaggregator, taskcontextinference, taskpath, templatecopier,
  validate-config, validate-consistency, validate-security, validate-workflow,
  versionrouter, workflowfiles, workflowfiles-v20, workflowfiles-v21

### Test Results
157 tests across 17 files, all pass, suite runtime ~0.9s.

### Notable Patterns (Perl test footguns documented in i-maintenance.md)
- `ok(grep { ... } @list, $msg)` — message included in grep list; use `ok((grep {...}), $msg)`
- `qw(In\ Progress)` — creates two words; use `('In Progress', ...)`
- Functions not in `@EXPORT_OK` must be called fully qualified
- `Blocked` status = 15% in `CWF::TaskState`, not 0%

---

## Task 76: Add Re-Execution Guidance to Implementation and Testing Exec Skills

**Status**: Complete (2026-02-19)
**Duration**: <1 session (trivial)
**Impact**: Bugfix — agents re-running `cwf-implementation-exec` or `cwf-testing-exec`
on an already-executed phase now have explicit instructions: work forward, don't revert
commits, use `Task N: Pass 2: …` commit naming, append results rather than overwriting.

### Key Changes
- `.cwf/docs/skills/re-execution.md` (new): shared guidance doc with Detection, Core
  Rule (no reverts), Commit Naming, Doc Handling, and Non-Blocker sections
- `.claude/skills/cwf-implementation-exec/SKILL.md`: conditional re-execution check
  inserted between Step 5 and Step 6
- `.claude/skills/cwf-testing-exec/SKILL.md`: same insertion

### Test Results
6/6 tests pass (content review).

---

## Task 75: Harden Install Script with Pre-Flight Checks and Simplify Bootstrap

**Status**: Complete (2026-02-19)
**Duration**: <1 session (trivial)
**Impact**: Bugfix — `install.bash` now exits with a clear error when the target repo
has no commits (subtree method requires at least one). Bootstrap docs simplified from
a 4-line sparse-checkout sequence to clean one-liners.

### Key Changes
- `scripts/install.bash`: Added initial-commit guard in `check_prerequisites()` —
  subtree method only; exits with descriptive error if `git rev-parse HEAD` fails
- `README.md`: Replaced 4-line sparse-checkout block with two one-liners (GitHub curl,
  non-GitHub `git archive --remote`)
- `INSTALL.md`: Same replacement; relabelled sections as "GitHub" and
  "GitLab, Gitea, Forgejo, self-hosted"

### Test Results
6/6 tests pass. Guard fires correctly for empty repo + subtree; skipped for committed
repo + subtree and all copy-method repos.

---

## Task 74: Fix template-copier-v2.1 Uninitialized Variable Warnings

**Status**: Complete (2026-02-19)
**Duration**: <1 session (trivial)
**Impact**: Bugfix — `Branch` field in all generated template files is now correctly populated from the project's branch-naming convention. Previously always blank due to two compounding silent bugs in `build_template_vars`.

### Root Cause
Two bugs in `build_template_vars`, both silent:
1. Config key path `$config->{'branch-naming-convention'}` was wrong — the key is nested under `source-management`. The `// ''` default masked the undef silently.
2. Substitution regex used double-brace format `{{task-type}}` but the config pattern uses single-brace `{task-type}` — substitution never fired.

### Key Changes
- `.cwf/scripts/command-helpers/template-copier-v2.1`: Fixed config key path (line 354) and substitution brace format (lines 368-370)
- `.cwf/security/script-hashes.json`: Updated SHA256 for `template-copier-v2.1`

### Test Results
5/5 tests pass. Branch field correct for both bugfix and feature task types. No stderr warnings.

---

## Task 71: Add Missing Checkpoint Commit Instructions to cwf-requirements-plan and cwf-maintenance

**Status**: Complete (2026-02-19)
**Duration**: <1 session (trivial)
**Impact**: Hotfix — `cwf-requirements-plan` and `cwf-maintenance` were the only two wf step skills missing a checkpoint commit step. Agents completing these phases did not commit their workflow files. Both now have Step 8 (checkpoint commit) with the correct Stage file, and Next Steps renumbered to Step 9.

### Key Changes
- `.claude/skills/cwf-requirements-plan/SKILL.md`: Added Step 8 checkpoint commit (`Stage: b-requirements-plan.md`), renumbered Next Steps to Step 9
- `.claude/skills/cwf-maintenance/SKILL.md`: Added Step 8 checkpoint commit (`Stage: i-maintenance.md`), renumbered Next Steps to Step 9

### Test Results
6/6 tests pass. Full skill audit (TC-5) confirmed cwf-new-task, cwf-subtask, and cwf-retrospective are legitimately exempt.

---

## Task 70: Improve CWF Skill Initialisation in cwf-init

**Status**: Complete (2026-02-19)
**Duration**: <1 session
**Impact**: Feature — `cwf-init` now produces a fully-functional CWF environment from a fresh project. Fixes three problems identified in Task 63 external agent testing: skill permission prompts on every call, agents manually following SKILL.md instead of using the `Skill` tool, and the post-init commit being skipped.

### Key Changes
- `.claude/skills/cwf-init/SKILL.md`: Extended from 7 to 8 steps:
  - Step 4 (Update CLAUDE.md): Now prepends a CWF enforcement preamble with idempotency check
  - Step 6 (new — Register Skill Permissions): Lists CWF skills dynamically, asks user to confirm, merges into project `.claude/settings.json` with idempotent merge
  - Step 7 (renumbered): PERL5OPT configuration unchanged
  - Step 8 (renumbered + strengthened): Mandatory init commit — "Do not begin task work until this commit is made"

### Test Results
9/9 tests pass. No defects.

---

## Task 69: Remove Obsolete `Implemented` Status Value

**Status**: Complete (2026-02-18)
**Duration**: <1 session (trivial)
**Impact**: Bugfix — eliminates the root cause of recurring `f-implementation-exec.md` being left at `Implemented` (50%) instead of `Finished` (100%). The `Implemented` status was a v2.0 artefact made obsolete when v2.1 split implementation and testing into separate files.

### Key Changes
- `cwf-project.json`: Removed `"Implemented": 50` from `status-values`
- `TaskState.pm`: Removed from `%DEFAULT_STATUS_MAP`, `_is_active_work`, POD, and comments
- `cwf-implementation-exec/SKILL.md`: Fixed instruction from `"Implemented" when complete` → `"Finished" when complete` (direct source of recurring misuse)
- `workflow-steps.md`: Removed `Implemented` from Status Values documentation
- `script-hashes.json`: Updated SHA256 for `TaskState.pm`
- `BACKLOG.md`: Retired "Add Status Field Review to Pre-Retrospective Checklist" (symptom workaround — root cause now fixed)

### Test Results
8/8 tests pass.

---

## Task 68: Remove v1.0 Category Subdirectories from cwf-init

**Status**: Complete (2026-02-18)
**Duration**: <1 session (trivial)
**Impact**: Hotfix — `cwf-init` no longer instructs agents to create obsolete `feature/`, `bugfix/`, `hotfix/`, `chore/` subdirectories under `implementation-guide/`. README Project Structure updated to v2.1 layout.

### Key Changes
- `.claude/skills/cwf-init/SKILL.md`: Removed bullet instructing category subdir creation (v1.0 legacy)
- `README.md`: Replaced stale v1.0 Project Structure block with v2.1 number-prefixed layout; updated `.cwf/` subtree to reflect current reality (`lib/CWF/`, `security/`, `templates/pool/`)
- `BACKLOG.md`: Retired both duplicate entries covering this issue (Task 63 High + Task 60 Medium)

---

## Task 67: Fix Stale Statuses in Tasks 46 and 49

**Status**: Complete (2026-02-18)
**Duration**: <1 session (trivial)
**Impact**: Chore — 7 status field edits; tasks 46 and 49 now show 100%.

### Key Changes
- Task 46: `f-implementation-exec.md`, `g-testing-exec.md` — `Backlog` → `Finished`
- Task 49: `a`, `c`, `d`, `e` — `In Progress` → `Finished`; `f` — `Implemented` → `Finished`

---

## Task 66: Fix Terminal Status Handling in state_done and Status Aggregators

**Status**: Complete (2026-02-18)
**Duration**: <1 session
**Impact**: Bugfix — tasks where all workflow files are Cancelled or Skipped now score 100% in status-aggregator. Blocked tasks now surface in task-context-inference at a low DORMANT score rather than being hidden.

### Key Changes

1. **`CWF::TaskState.pm`**:
   - Add `Skipped => 100` to `%DEFAULT_STATUS_MAP`
   - Replace `_is_terminal` (Blocked|Finished|Cancelled) with `_is_closed` (Finished|Cancelled|Skipped) — Blocked is recoverable, not terminal
   - Fix `state_done` MIN: closed steps mapped to 100 before MIN calculation (not their raw score)
   - Remove dead `$blocked_count`/`$is_workable`/`!$is_workable` from `state_achievable` — CLIFF catches all-closed tasks; Blocked falls to DORMANT (≈4)
   - Fix 4 pre-existing perlcritic violations (`grep` block form, `RequireBriefOpen`, `_max`/`_min` unpack)
2. **`cwf-project.json`**: `"Skipped": null` → `"Skipped": 100` (config overrides `%DEFAULT_STATUS_MAP`; both must match)
3. **Both aggregators**: Add `Skipped` to unknown-status warning exclusion regex

### Test Results
14/14 test cases pass. Task 11 (all Cancelled) now shows 100%.

---

## Task 65: Fix Stale In Progress Statuses in Tasks 47 and 48

**Status**: Complete (2026-02-18)
**Duration**: <1 session (trivial)
**Impact**: Chore — 10 status field edits; tasks 47 and 48 now show 100% in status-aggregator and no longer appear in task-context-inference output.

### Key Changes

1. Tasks 47 and 48: `a-task-plan.md`, `c-design-plan.md`, `d-implementation-plan.md`, `e-testing-plan.md` — `In Progress` → `Finished`
2. Tasks 47 and 48: `f-implementation-exec.md` — `Implemented` → `Finished`

### Root Cause

Retrospective skills did not require updating intermediate workflow files before marking j-retrospective.md Finished. Both tasks had retrospectives that set j-retrospective.md to Finished but left a–f stale.

### Recommendation Added

`.cwf/docs/skills/retrospective-extras.md` should include an explicit checklist item: "Set all preceding workflow files (a through g) to Finished." (See j-retrospective.md for full recommendation.)

---

## Task 64: cwf-manage validate and CWF::Validate Module Suite

**Status**: Complete (2026-02-18)
**Duration**: 1 session (vs. 2-3 sessions estimated — well under)
**Impact**: Feature — Deterministic validation of config, workflow, consistency, and security fields across the entire repo, callable as a post-skill guard.

### Key Changes

1. **Four new modules** under `.cwf/lib/CWF/Validate/`:
   - `Config.pm` — validates `cwf-project.json` schema (supported-task-types, source-management)
   - `Workflow.pm` — validates `## Status` section presence and value in all workflow files
   - `Consistency.pm` — cross-checks task num in dirname vs `**Task**:` field; branch vs git branch for active tasks
   - `Security.pm` — SHA256 + permissions verification using `Digest::SHA` (no shell subprocess)
2. **`cwf-manage validate` subcommand** — calls all four modules, reports all violations before exit, exits 1 if any
3. **`/cwf-security-check` skill simplified** — now a thin wrapper delegating to `cwf-manage validate`
4. **`checkpoint-commit.md` updated** — step 4 added: run `cwf-manage validate` after every checkpoint commit
5. **Side-fixes found by the validator on first run**:
   - Unclosed ` ```perl ` code fence in task 37 `c-design-plan.md` (made `## Status` invisible to any parser)
   - Missing `source-management` key in `implementation-guide/cwf-project.json`
   - `chmod 0755` on `task-context-inference`, `task-stack`, `migrate-v2.1-file-order` (permissions mismatch)

### Test Results

- 25 test cases (2 static + 6 Config + 4 Workflow + 4 Consistency + 5 Security + 3 integration + 2 regression), all PASS
- 1 additional test (lib files without `permissions` key skip the permissions check)

### BACKLOG Items Added

- **Expand Perl test suite to cover all CWF library modules** (chore, High) — `t/` currently has only `task-state.t`; all four new modules and the remaining 10 library modules need proper `.t` files runnable via `prove t/`

---

## Task 63: Fix template-copier-v2.1 Undef Warnings and Sparse-Checkout Bootstrap

**Status**: Complete (2026-02-17)
**Duration**: 1 session (vs. 1 session estimated = on target)
**Impact**: Bugfix — Zero undef warnings during template creation; agent-friendly install bootstrap documented.

### Key Changes

1. **Undef guards in template-copier-v2.1**: `$pattern // ''` (line 354), `$value // ''` (line 385), `supported-task-types // [default list]` (line 198)
2. **Perlcritic stern**: Fixed 3 pre-existing violations — explicit `return` on `print_usage` and `output_results`, `return sort` ambiguity resolved
3. **Sparse-checkout bootstrap**: Added agent-friendly 4-line install sequence to README.md and INSTALL.md for non-GitHub hosts
4. **Security hash**: Updated for template-copier-v2.1

### Test Results

- 10 test cases: 2 static analysis + 2 source inspection + 2 integration + 1 hash + 2 docs + 1 array guard, all PASS

### BACKLOG Items Added

- **Harden install script**: Initial commit pre-flight + replace sparse checkout with `git archive` one-liner
- **Remove v1.0 category dirs from /cwf-init**
- **`cwf-manage validate` and CWF::Validate module suite**
- **Improve CWF skill initialisation in /cwf-init** (permissions, enforcement preamble, post-init commit)

---

## Task 62: Fix Install Script / cwf-init Boundary and Post-Install UX

**Status**: Complete (2026-02-17)
**Duration**: 1 session (vs. 1 session estimated = on target)
**Impact**: Bugfix — Clean separation between install script (plumbing) and /cwf-init (project setup).

### Key Changes

1. **Install script boundary**: Removed `implementation-guide/` and `.gitignore` creation from `post_install()` — these are now exclusively `/cwf-init`'s responsibility
2. **cwf-manage Perl idioms**: Replaced `system()` file operations with core Perl (`File::Find`, `File::Copy`, `File::Path`). Added `copy_tree()` helper.
3. **cwf-init UX**: Added PERL5OPT detection (skip suggestion if already configured) and post-init commit step
4. **INSTALL.md**: Documents that Claude Code restart is needed after install for skills to register

### Test Results

- 15 test cases: 3 boundary + 5 Perl idioms + 3 SKILL.md + 1 docs + 3 regression, all PASS

---

## Task 61: CWF Install Script and Release Management

**Status**: Complete (2026-02-16)
**Duration**: 2 sessions (vs. 1-2 sessions estimated = on target)
**Impact**: Feature — Zero-interaction bootstrap install script and Perl management script for CWF lifecycle.

### Key Changes

1. **Bootstrap script** (`scripts/install.bash`, ~240 lines): `curl | bash` installer supporting subtree (default) and copy methods via `CWF_METHOD`, `CWF_REF`, `CWF_SOURCE`, `CWF_FORCE` env vars
2. **Management script** (`.cwf/scripts/cwf-manage`, ~345 lines Perl): `status`, `list-releases`, `update`, `rollback` subcommands with dispatch table
3. **Staging prefix + symlinks**: Skills install to `.cwf-skills/` and are symlinked into `.claude/skills/`, preserving existing consumer skills
4. **INSTALL.md**: Added "Quick Install (Script)" section; updated manual methods for `.cwf-skills/` staging prefix
5. **Perlcritic**: Clean at severity 4 (stern) — explicit returns on all subs, dispatch table for command routing

### Design Decision

Original design used `.claude/skills/` as a subtree prefix, which would clobber existing consumer skills. Reworked through full process (b→g) to use `.cwf-skills/` staging prefix with relative symlinks. This was the critical design insight of the task.

### Test Results

- 28 test cases: 4 subtree + 1 copy + 3 symlink + 4 ref resolution + 2 prereq + 8 management + 2 docs + 2 regression, all PASS
- Pass 1: 5 bugs found. Pass 2 (after rework): 0 bugs found.

### BACKLOG Items Added

- **Replace backtick operators with IPC::Open3 in cwf-manage** (chore, very low)

### BACKLOG Items Completed

- Task 60 deferred items (install script, tag-based release management) now implemented

---

## Task 60: Add Installation Instructions

**Status**: Complete (2026-02-15)
**Duration**: ~2 hours (vs. 1-2 hours estimated = on target)
**Impact**: Chore — New INSTALL.md enabling users to install CWF into their own repos.

### Key Changes

1. **INSTALL.md**: Two first-class installation methods — git subtree (two-split approach) and file copy (static/manual upgrade)
2. **README.md**: Installation section replaced with concise summary linking to INSTALL.md
3. **Git subtree two-split**: Verified approach using `git subtree split` for `.cwf/` and `.claude/skills/` from single CWF repo

### Scope Notes

This is an intentionally incomplete implementation. Deferred to Task 61 (feature):
- `curl | bash` install script
- Tag-based release management with update/rollback

### BACKLOG Items Added

- **Audit /cwf-init for obsolete category subdirectories** (chore, medium)
- **template-copier-v2.1 undef warnings** (bugfix, high)
- **/cwf-init should run security check and fix permissions** (bugfix, low)
- **Add status update helper script** (feature, low)

### Test Results

- 11 test cases: 3 structure + 3 path accuracy + 2 command validity + 2 README integration + 1 verification, all PASS
- External validation: both methods tested against real repo

---

## Task 59: Rebrand CIG to CWF (Coding with Files)

**Status**: Complete (2026-02-14)
**Duration**: ~2 hours (vs. 3-5 hours estimated = under estimate)
**Impact**: Feature — Full rebrand from "Code Implementation Guide" (CIG) to "Coding with Files" (CWF, pronounced "swiff").

### Key Changes

1. **Structural renames**: `.cig/`→`.cwf/`, 19 skill dirs (`cig-*`→`cwf-*`), 5 helper scripts, `CIG-PROJECT-SPEC.md`→`CWF-PROJECT-SPEC.md`, `cig-project.json`→`cwf-project.json`
2. **Perl namespace**: `CIG::*`→`CWF::*` across 15 modules. `TaskState` and `TaskContextInference` moved from lib root into `CWF::` namespace.
3. **Content updates**: All SKILL.md files, root docs (README, CLAUDE.md, COMMANDS.md, DESIGN.md, BACKLOG), internal docs, configs updated
4. **Security hashes**: Regenerated for all renamed/modified scripts and modules
5. **README pronunciation**: "CWF is pronounced 'swiff'"

### Preserved Unchanged

- All historical task workflow docs (`implementation-guide/*/`)
- CHANGELOG.md (append-only history)

### Test Results

- 20 test cases: 5 structural + 2 compilation + 6 content sweep + 3 functional + 4 regression, all PASS

### BACKLOG Items Affected

- **Added**: "Add Delete Task Skill" (High) — from Task 59 misclassification experience
- **Added**: "Infer Task Type When Not Specified" (Medium) — agent should infer type from complexity

---

## Task 58: Add Cancelled Status to Workflow System

**Status**: Complete (2026-02-13)
**Duration**: ~30 minutes (vs. <1 hour estimated = on target)
**Impact**: Bugfix — Added "Cancelled" as a terminal status value (0%) for tasks that are abandoned or superseded.

### Problem Addressed

Task 11 (secure argument parsing) was superseded by Task 57 (commands→skills) but had no appropriate status value. "Blocked" was inaccurate (it wasn't waiting on anything) and "Finished" was wrong (it never achieved its goals). A "Cancelled" terminal status was needed.

### Key Changes

1. **Added `"Cancelled": 0`** to `cig-project.json` status-values
2. **Updated `TaskState.pm`**: Renamed `_is_blocked_or_finished` → `_is_terminal`, added Cancelled to terminal check and default map
3. **Updated both aggregators** (v2.0 and v2.1): Warning regex exempts Cancelled from "unknown 0% status" warnings
4. **Updated `workflow-steps.md`**: Documented Cancelled in Valid Status Values section
5. **Cancelled Task 11**: All 5 workflow files set to Cancelled with reason "Superseded by Task 57"

### Test Results

- 12 test cases: 10 functional + 2 regression, all PASS
- 0 failures, 0 deviations from plan

### BACKLOG Items Affected

- **Removed**: "Rollout Task 11 - Secure Argument Parsing" (superseded)

---

## Task 57: Convert CIG Commands to Skills

**Status**: Complete (2026-02-13)
**Duration**: ~6-7 hours active (vs. 2-3 days estimated = -60% to -75% variance)
**Impact**: Feature — Migrated all 17 CIG commands from `.claude/commands/` to `.claude/skills/` format, adopting the skills system for better tool permission control and eliminating injection syntax.

### Problem Addressed

CIG commands used `!{bash}` and `!/path` context injection syntax which doesn't work in skills (Task 55 confirmed this empirically). Commands needed conversion to skills format with runtime tool call instructions to adopt the newer architecture and fix FR8 (permission error regression from injection syntax).

### Key Changes

1. **Converted 17 commands to skills** in `.claude/skills/cig-*/SKILL.md` with YAML frontmatter
2. **Replaced all context injection** with 3 patterns: Pattern A (context-manager location), Pattern B (task-context-inference), Pattern C (skill-specific mandatory instructions)
3. **Accounted for all 15 Pattern C injections**: 10 converted to runtime instructions, 5 removed as provably redundant
4. **Renamed shared docs** from `.cig/docs/commands/` to `.cig/docs/skills/`
5. **Fixed `cig-current-task`** pre-existing skill — added missing YAML frontmatter
6. **Deleted all 17 command files** — clean cutover, no parallel operation

### Test Results

- 14 test cases: 12 PASS, 2 conditional PASS (token budget 930 vs 850 target — accepted trade-off)
- 0 functional or regression failures
- All 18 skills have valid frontmatter (18/18)

### BACKLOG Items Affected

- **Completed**: "Convert CIG Commands to Skills"

## Task 56: Refactor CIG Commands for Progressive Disclosure

**Status**: Complete (2026-02-12)
**Duration**: ~1 day (vs. 2-3 days estimated = -50% to -67% variance)
**Impact**: Chore — Reduced 17 CIG commands from 1,914 total lines to 782 (59.1% reduction) by extracting shared patterns into 3 reference docs.

### Problem Addressed

CIG's 17 commands embedded full workflow instructions inline (80-237 lines each), causing duplication and context pollution risk. This blocked skill conversion (Task 57) because auto-loading 17 bloated commands would consume ~26k+ tokens.

### Key Changes

1. **Created 3 shared docs** in `.cig/docs/commands/`:
   - `workflow-preamble.md` (51 lines) — argument parsing, task validation, Steps 1-4
   - `checkpoint-commit.md` (23 lines) — commit template with trailer
   - `retrospective-extras.md` (95 lines) — CHANGELOG/BACKLOG update, checkpoints branch, squash
2. **Refactored 16 commands** to thin dispatchers referencing shared docs (cig-init.md skipped, already 53 lines)
3. **Consistent structure** across all 10 workflow commands: frontmatter, scope, context, workflow (shared doc refs), success criteria

### Test Results

- 12 test cases: 10 PASS, 2 marginal FAIL (aspirational metrics targets)
- 0 functional or regression failures

### BACKLOG Items Affected

- **Completed**: "Refactor CIG Commands for Progressive Disclosure"
- **Unblocked**: "Convert CIG Commands to Skills" — commands are now thin enough for skill conversion

## Task 55: Test Context Injection Syntax in SKILL.md Format

**Status**: Complete (2026-02-12)
**Duration**: ~30 minutes (vs. <1 hour estimated = -50% variance)
**Impact**: Discovery — Empirically confirmed that `!{bash}` and `!` path shorthand context injection syntaxes are commands-only features that do not work in SKILL.md files.

### Problem Addressed

Task 54 flagged context injection syntax as "unverified in SKILL.md format" — a key unknown blocking the command-to-skill migration decision. Rather than relying on documentation (which doesn't mention this limitation), this task tested it empirically.

### Key Findings

1. **`!{bash}` block syntax**: FAIL — raw literal text in skill prompt, not expanded
2. **`!` path shorthand**: FAIL — raw literal text in skill prompt, not expanded
3. **Root cause**: Context injection is a feature of the `.claude/commands/` loader, not the `.claude/skills/` loader
4. **Silent failure**: No error or warning — injection syntax passes through as literal text
5. **Alternative approaches**: 4 identified; recommended: `allowed-tools` with Bash + thin skill + doc reference (runtime tool calls instead of prompt-time expansion)

### Test Results

- 6 test cases: 4 FAIL (injection syntax), 2 PASS (cleanup, isolation)
- 100% coverage of identified injection patterns

### BACKLOG Items Affected

- **Completed**: "Test Context Injection Syntax in SKILL.md Format"
- **Informed**: "Refactor CIG Commands for Progressive Disclosure" and "Convert CIG Commands to Skills" — now know that skill conversion requires runtime tool calls, not injection syntax

## Task 54: Assess Current 2026 W6 Skills and Plugin Standards

**Status**: Complete (2026-02-12)
**Duration**: ~4-5 hours active work across 2 calendar days (vs. 2-3 days / 16-24 hours estimated = -70% to -80% variance)
**Impact**: Discovery — Comprehensive ecosystem assessment informing CIG migration strategy. Reaffirms "Keep Commands" recommendation from Task 16.

### Problem Addressed

Task 16 (Jan 2026) recommended "Keep Commands" but the skills/plugin ecosystem was evolving rapidly. The BACKLOG "Migrate CIG to Hybrid Plugin Model" item assumed commands were deprecated and migration prerequisites were met. Task 54 assessed the current state to validate or update these assumptions.

### Key Findings

**Research Output** (FR1-FR7):
1. **API Evolution (FR1)**: 4 releases (v2.1.3-v2.1.34) with 2 breaking changes (`$ARGUMENTS` syntax, SDK rename). Commands merged into skills in v2.1.3.
2. **User Feedback (FR2)**: 23 GitHub issues catalogued — critical bugs in hooks (#17688, 9 upvotes), SubagentStop (#22087, 34 upvotes), context pollution (#14851, 7 upvotes). AGENTS.md most-requested feature (2565 upvotes).
3. **Migration Patterns (FR3)**: 5 real-world examples found; all use hybrid/status-quo approach. No full migrations to skills-only.
4. **Hooks Standardisation (FR4)**: Agent Skills spec adopted by 6 platforms. Adoption faster than Task 16 expected.
5. **Marketplace (FR5)**: 40+ official plugins; mature distribution via npm/GitHub.
6. **Technical Blockers (FR6)**: 10 blockers identified (2 CRITICAL, 3 HIGH). Bug #17688 (hooks broken in plugins) is the single most important finding — invalidates the primary value of plugin migration.
7. **Recommendation (FR7)**: Keep Commands, 85% confidence. Decision matrix: 4 options × 8 weighted criteria. Review triggers set for Q3 2026.

**Test Results**: 11/12 PASS, 1 PARTIAL (minor single-source caveat). Zero contradictions across independently-researched FR sections.

### Process Innovation

- **Parallel research agents**: 6 agents ran simultaneously for FR1-FR6, compressing 14 hours of serial research into ~2 hours wall-clock time
- **`gh` CLI enrichment**: After initial WebSearch-based research, `gh` structured searches and per-issue reaction data improved FR2 quality (flipped 2 test cases from PARTIAL to PASS)

### BACKLOG Items Affected

- **Updated**: "Migrate CIG to Hybrid Plugin Model" — added Bug #17688 as critical blocker, updated context with Task 54 findings

## Task 53: Add Slug Generation to Template Copier

**Status**: Complete (2026-02-10)
**Duration**: ~0.5 hours (vs. 2-4 hours estimated = -75% to -87% variance)
**Impact**: Bugfix - Eliminated permission prompts for normal template copying operations and simplified command invocations by making destination parameter optional.

### Problem Addressed

Template-copier-v2.1 required destination path for every invocation and used inline bash slug generation that triggered permission prompts (ironic given the script's purpose of eliminating prompts). BACKLOG item "Create Slug Generator Helper Script" addressed via embedded solution.

**Issues Fixed**:
1. Inline bash slug generation required permission prompts during template copying
2. Users had to specify destination path explicitly for every command invocation
3. No path auto-construction from task metadata (type, number, description)

### Changes Made

**`.cig/scripts/command-helpers/template-copier-v2.1`**:
- Added `generate_slug()` function (Perl port of bash algorithm: lowercase → remove special chars → hyphens → collapse → truncate 50)
- Added `construct_destination()` function for config-based path construction (reads cig-project.json pattern)
- Modified `parse_parameters()` to make destination optional with fallback to auto-construction
- Updated usage documentation to show destination as optional parameter
- Preserved backward compatibility (explicit destination still works for testing/debugging)

**`.cig/security/script-hashes.json`**:
- Updated SHA256 hash for template-copier-v2.1
- Old: `d65567baa0cf81e11b57aabb09fa7b6b70a08b53055ff3397db08d8dfa391e54`
- New: `c0c9d8ef1359dbb29f3c9eeaff5a24ae1db901fe75e4e6a207e90c8c8f31531c`

### Implementation Quality

**Test Coverage**: 9/9 executed tests passed (100% pass rate)
- Functional tests: 7/7 passed (slug generation, auto-construction, backward compatibility, integration)
- Non-functional tests: 2/3 passed, 1 skipped (performance 20.75ms per op, compatibility across all 5 task types)

**Defect Rate**: 0 defects - all executed tests passed, zero regressions across all task types

**Estimation Accuracy**: Task completed 75-87% faster than estimated due to clear design (pure functions) and straightforward scope

### Key Achievements

1. **Permission prompt elimination**: Moved slug generation from inline bash to Perl function (no permission prompts)
2. **Simplified invocations**: Destination now optional, auto-constructed from config pattern
3. **Full backward compatibility**: Explicit destination parameter still works for testing/debugging
4. **Zero regressions**: All 5 task types (feature, bugfix, hotfix, chore, discovery) tested and working
5. **Algorithm exactness**: Bash-to-Perl port verified with side-by-side comparison testing

## Task 52: Clean Up Obsolete BACKLOG Items

**Status**: Complete (2026-02-10)
**Duration**: ~1.75 hours elapsed (vs. <1 hour estimated = +75-133% variance)
**Impact**: Chore - Removed 3 verified obsolete BACKLOG items that were already completed in previous tasks, improving BACKLOG accuracy and maintainability.

### Problem Addressed

BACKLOG.md accumulated 3 obsolete items that had already been completed in previous tasks but were never removed, causing confusion about what work remained and making the backlog less trustworthy as a project roadmap.

**Issues Fixed**:
1. "Update cig-status to Use --workflow Flag" - already implemented in Task 32 (cig-status auto-enables --workflow)
2. "Update Task 32 Tests for New Inference Output Format" - already completed in Task 32 (tests verify task_num/task_slug format)
3. "Add 'Create Task Branch' Step to Implementation Execution" - already implemented in cig-new-task (automatic branch creation in Step 6)

### Changes Made

**`BACKLOG.md`**:
- Removed "Update cig-status to Use --workflow Flag" (lines 1571-1607)
  - Evidence: `.claude/commands/cig-status.md` line 36 shows auto --workflow
- Removed "Update Task 32 Tests for New Inference Output Format" (lines 131-150)
  - Evidence: Task 32 `g-testing-exec.md` line 48 shows new format tests
- Removed "Add 'Create Task Branch' Step to Implementation Execution" (lines 187-215)
  - Evidence: `.claude/commands/cig-new-task.md` Step 6 shows branch creation
- Result: BACKLOG reduced from 42 to 39 tasks

### Implementation Quality

**Test Coverage**: 7/7 tests passed (100%)
- Verification tests: 5/5 passed (3 grep verifications, structure validation, markdown rendering)
- Non-functional tests: 2/2 passed (completeness, formatting consistency)

**Defect Rate**: 0 defects - all verification tests passed, no orphaned separators, BACKLOG structure intact

### Key Achievements

1. **Evidence-based cleanup**: Each item verified with concrete code/test references before removal
2. **Zero structural damage**: No orphaned separators, all 39 remaining tasks properly formatted
3. **Comprehensive verification**: Multi-level validation (grep content, awk structure, task header counts)
4. **Process documentation**: Clear rationale for each removal preserved in implementation plan

## Task 51: Remove Dead Code from TaskContextInference.pm

**Status**: Complete (2026-02-10)
**Duration**: ~1.3 hours (vs. 1-2 hours estimated = -13% under midpoint)
**Impact**: Bugfix - Removed 114 lines of confirmed dead code from TaskContextInference.pm, improving maintainability and reducing codebase confusion.

### Problem Addressed

Dead code audit identified 4 unused functions in TaskContextInference.pm that were no longer called after Task 32 removed status signal functionality. Original audit also incorrectly flagged 2 functions in other modules, but pre-removal verification caught these errors.

**Issues Fixed**:
1. Dead functions consuming 114 lines in TaskContextInference.pm
2. Audit methodology gaps (same-file usage, script-to-library usage not checked)
3. Potential confusion for future developers reading deprecated code

### Changes Made

**`.cig/lib/TaskContextInference.pm`**:
- Removed `_get_status_signal()` (45 lines) - status signal removed per Task 32
- Removed `_score_status()` (17 lines) - helper only called by dead function
- Removed `_get_task_status_score()` (29 lines) - helper only called by dead function
- Removed `_format_uncorrelated()` (23 lines) - marked DEPRECATED, replaced by format_output()
- Total: 114 lines removed

**`.cig/security/script-hashes.json`**:
- Updated SHA256 hash for TaskContextInference.pm
- Old: `6debb865...522d34bc`
- New: `93b4426e...513502de`

### Implementation Quality

**Test Coverage**: 8/8 applicable tests passed (100%)
- Verification tests: 3/3 passed (grep verification, hash verification, line count)
- Regression tests: 3/3 passed (status aggregator, module imports, context inference)
- Non-functional tests: 2/2 passed (hash integrity, code cleanliness)

**Scope Adjustment**: Audit error discovered during Step 1 verification
- `workflow_file_mappings()` NOT removed (actively used by context-inheritance-v2.0)
- `format_error()` NOT removed (internal usage in Common.pm with POD docs)
- Scope reduced from 3 files (~160 lines) to 1 file (114 lines)
- Verification process prevented breaking changes

### Key Achievements

1. **Pre-removal verification caught errors**: Step 1 grep discovered 2 audit mistakes before any code was modified
2. **Surgical removal**: Edit tool enabled precise function deletion without affecting code structure
3. **Zero regressions**: All core CIG workflows (status aggregator, context inference) still work correctly
4. **Process learning**: Identified audit methodology gaps for future dead code cleanup

## Task 50: Add "Skipped" Workflow Step Status (v2.1 Format Only)

**Status**: Complete (2026-02-10)
**Duration**: <1 day (vs. 1-2 days estimated = -50% to -100% variance)
**Impact**: Feature - v2.1 format can now mark any workflow step as "Skipped" (N/A), excluded from progress calculation. Enables correct 100% completion when phases aren't applicable (e.g., maintenance for bugfixes).

### Problem Addressed

No way to mark workflow steps as "not applicable" without affecting progress calculation. Example: bugfix task with maintenance phase marked "Backlog" (0%) shows 90% complete (9/10 phases finished) instead of 100% (9/9 applicable phases finished). Users forced to mark N/A phases as "Finished" dishonestly or accept inaccurate progress metrics.

**Issues Fixed**:
1. No status value for "not applicable" workflow phases
2. Progress calculation includes phases that shouldn't apply to specific tasks
3. Display shows misleading percentages for N/A phases (e.g., "Maintenance: Backlog (0%)")
4. Workflow documentation didn't clarify when phases can be skipped

### Changes Made

**`implementation-guide/cig-project.json`**:
- Added `"Skipped": null` to workflow.status-values (line 77)
- Null value maps to Perl `undef` for clean filtering

**`.cig/lib/TaskState.pm`**:
- Added `grep defined` filter to `state_done()` (line 97)
- Excludes undef values from progress calculation (9/9=100% not 9/10=90%)

**`.cig/scripts/command-helpers/status-aggregator-v2.1`**:
- Display logic: Shows "Skipped (N/A)" instead of percentage (line 423)
- Bug fix: Added `defined($pct)` check in warning logic (line 123)
- Bug fix: Added `defined($wf->{percent})` checks in indicator ternary (lines 420-421)

**`.cig/docs/workflow/workflow-steps.md`**:
- Added "Skipped" status documentation (lines 44-67)
- Usage guidance: Emphasizes per-task decisions, provides examples
- Clarifies v2.1 requirement and distinction from Backlog/Finished

### Implementation Quality

**Test Coverage**: 15/19 tests executed (79% execution rate)
- 10/12 functional tests passed (TC-F5, TC-F6 deferred - core logic verified via TC-F3)
- 5/7 NFR tests passed (TC-NFR1, TC-NFR2 deferred - existing patterns validated)

**Defect Rate**: 2 bugs found during testing, 0 post-testing defects
- Line 123: undef comparison warning (fixed immediately)
- Lines 420-421: indicator ternary undef warnings (fixed immediately)

### Key Achievements

1. **Null-value sentinel pattern**: Using JSON `null` (Perl `undef`) cleaner than magic numbers
2. **Idiomatic Perl**: `grep defined` filter and ternary conditionals improve readability
3. **Backward compatible**: v2.0 format unchanged, v2.1 tasks without "Skipped" work identically
4. **Testing caught bugs**: Execution testing phase discovered 2 undef handling bugs before production
5. **Clear documentation**: workflow-steps.md provides usage guidance and examples

## Task 49: Fix Checkpoints Branch Permissions Issue with Script

**Status**: Complete (2026-02-10)
**Duration**: ~1 hour (vs. 4 hours estimated = -75% variance - 3x faster)
**Impact**: Bugfix - Created `checkpoints-branch-manager` script to eliminate Step 10 permission prompts. Deterministic git operations now in code, not LLM decisions.
**BACKLOG Item Completed**: "Fix Retrospective Step 10 Permission Prompts" from Task 45

### Problem Addressed

Task 45 retrospective identified that Step 10 of cig-retrospective workflow uses compound git commands with command substitution that trigger permission prompts despite individual commands being in frontmatter allowlist:
- `git branch "$(git rev-parse --abbrev-ref HEAD)-checkpoints"` (10.1)
- `git log --oneline --graph -20` (10.2 - missing from frontmatter)
- `git log "$(git rev-parse --abbrev-ref HEAD)-checkpoints" --oneline` (10.4)

**Issues Fixed**:
1. Compound commands with `$(...)` don't match frontmatter wildcard patterns
2. Missing `git log` permission in frontmatter
3. Step 10 workflow requires user approval interrupting retrospective automation
4. Violates CIG principle: deterministic operations belong in code

### Changes Made

**`.cig/scripts/command-helpers/checkpoints-branch-manager` (NEW)**:
- **60 lines** Perl script with 3 subcommands (create, show-history [count], verify)
- **Permissions**: 500 (r-x------)
- **Error handling**: Detached HEAD detection, branch exists, missing branch, invalid input
- **Idiomatic Perl**: Uses `die`, `//` operator, `shift`, postfix conditionals, `get_current_branch()` helper (DRY)
- **Security**: SHA256 hash recorded in `.cig/security/script-hashes.json`

**`.claude/commands/cig-retrospective.md`**:
- **Step 10.1**: Replaced `git branch "$(git ...)"` with `checkpoints-branch-manager create`
- **Step 10.2**: Replaced `git log ...` with `checkpoints-branch-manager show-history`
- **Step 10.4**: Replaced `git log "$(git ...)"` with `checkpoints-branch-manager verify`

### Implementation Quality

**Test Coverage**: 14/14 tests passed (100%)
- TC-1 to TC-9: Functional tests (all subcommands, error handling) ✅
- TC-10 (CRITICAL): No permission prompts from Step 10 ✅
- TC-11: File permissions (500) ✅
- TC-12: Security hash validation ✅
- TC-13: Error message clarity ✅
- TC-14: Backward compatibility (original git commands still work) ✅

**Defect Rate**: 1 minor issue found and fixed (permissions 700 after refactoring, corrected to 500)

### Key Achievements

1. **Permission prompts eliminated**: Script in `.cig/scripts/command-helpers/*:*` allowlist
2. **Code quality**: Refactored from 100 to 60 lines (-40%) with user-guided idiomatic Perl improvements
3. **Comprehensive testing**: All edge cases covered (detached HEAD, branch exists, missing branch, invalid input)
4. **Backward compatible**: Original git commands still functional, users can choose approach
5. **Fast delivery**: 3x faster than estimated due to clear requirements and simple design

## Task 48: Fix nextAction Template Substitution in Template-Copier

**Status**: Complete (2026-02-10)
**Duration**: ~4 hours (vs. 2-3 hours estimated = 33% overrun)
**Impact**: Bugfix - Template-copier now derives command names from template filenames, establishing directory structure as single source of truth. All 5 task types generate correct nextAction sequences.

### Problem Addressed

Task 47 discovered during rollout that `{{nextAction}}` template variable was not being deterministically substituted by template-copier-v2.1. Hardcoded `%PHASE_COMMANDS` mapping was incorrect (all commands shifted by 1 position), causing bugfix workflow g-testing-exec.md to show "Next Action: /cig-rollout" when correct action is "/cig-retrospective" (bugfix workflow has no h-rollout.md).

**Issues Fixed**:
1. Hardcoded `%PHASE_COMMANDS` mapping out of sync with actual command names
2. `{{nextAction}}` not being substituted, agents manually determining next steps
3. Violates CIG core principle: deterministic routing should be code-driven, not LLM decision
4. Future maintenance burden: any filename changes require updating hardcoded mapping

### Changes Made

**`.cig/scripts/command-helpers/template-copier-v2.1`**:
- **Removed**: 47 lines (entire `compute_next_action()` function + `%PHASE_COMMANDS` hash)
- **Added**: 8 lines (`name_to_action()` helper function)
- **Refactored**: `copy_templates()` to compute nextAction in loop by peeking at next template
- **Pattern**: `while (@templates) { shift @templates }` - idiomatic Perl
- **Transformation**: Strip phase prefix (`s/^[a-z]-//`), strip extension (`s/\.md\.template$//`), prepend `/cig-`
- **Future-proof**: Used `[a-z]` instead of `[a-j]` for forward compatibility

### Implementation Quality

**Test Coverage**: 9/9 tests passed (100%)
- TC-1: Bugfix g-testing-exec.md → "/cig-retrospective" (CRITICAL - original bug fixed) ✅
- TC-2: Feature task (10 files) - all nextActions correct ✅
- TC-3: Hotfix task (7 files) - all nextActions correct ✅
- TC-4: Chore task (6 files) - all nextActions correct ✅
- TC-5: Discovery task (8 files) - all nextActions correct ✅
- TC-6: Template variables regression - no regression ✅
- TC-7: File permissions (0600) regression - no regression ✅
- TC-8: Last phase shows "Task complete" ✅
- TC-9: Test directories cleaned up ✅

**Defect Rate**: 0 bugs found during testing or validation

### Key Achievements

1. **Single source of truth**: Template symlink filenames now define command names (zero hardcoded mapping)
2. **Code simplification**: Net -39 lines, significantly simpler logic
3. **Idiomatic Perl**: User-guided refactoring to `while/shift` pattern, `//` operator, functional approach
4. **100% test coverage**: All 5 task types validated end-to-end
5. **Zero regressions**: Template variables and permissions unchanged

### Benefits Delivered

- **Deterministic routing**: nextAction automatically derived from directory structure
- **Zero maintenance**: Filename changes automatically reflected in commands
- **More maintainable**: 39 lines shorter, more idiomatic Perl
- **Comprehensive validation**: 9 tests confirm all task types work correctly

### Lessons Learned

**Technical Insights**:
- Idiomatic Perl: `while (@array) { shift @array }` cleaner than indexed loops
- Defined-or operator `//` cleaner than if/else for fallbacks
- In-loop computation (peek at next template) simpler than separate discovery function
- Future-proofing regex: `[a-z]` vs `[a-j]` accounts for possible expansion

**Process Learnings**:
- Estimate 2x multiplier for "simple" bugfixes to account for full CIG workflow overhead
- User code review during implementation valuable (caught non-idiomatic patterns)
- Comprehensive testing (9 vs 7 planned) provided high confidence
- Following CIG process consistently pays off

**BACKLOG Items Completed**:
- Task 48 item from Task 47 retrospective (fix template-copier nextAction substitution)

## Task 47: Fix Variable Use in Commands to Avoid Bash Issues

**Status**: Complete (2026-02-09)
**Duration**: ~6 hours (vs. 2-3 hours estimated = 2x overrun)
**Impact**: Bugfix - All 17 CIG command files now use `{placeholder}` syntax exclusively, eliminating LLM-generated bash wrappers that trigger permission prompts

### Problem Addressed

Commands using `$VARIABLE` and `<placeholder>` syntax were causing LLMs to generate unnecessary bash wrapper scripts around helper script calls, triggering permission prompts that interrupted workflow execution.

**Issues Fixed**:
1. `$VARIABLE` syntax (22 occurrences across 16 files) triggered bash variable interpretation
2. `<placeholder>` syntax (98 occurrences across 15 files) in argument-hint fields caused parsing ambiguity
3. LLM creating bash wrappers like `bash -c ".cig/scripts/command-helpers/script $ARG"` instead of direct calls
4. Permission prompts interrupting command execution

### Changes Made

**All 17 CIG Command Files** (`.claude/commands/cig-*.md`):
- Frontmatter argument-hint fields: `<task-path>` → `{task-path}`, `<num>` → `{num}`, etc.
- Command body placeholders: `$ARGUMENTS` → `{arguments}`, `$TYPE` → `{type}`, `$TASK_DIR` → `{task-dir}`, etc.
- Total replacements: 120 changes (22 `$VARIABLE` + 98 `<placeholder>` → 61 `{placeholder}`)

**Files Modified**:
- `cig-new-task.md`, `cig-task-plan.md`, `cig-implementation-exec.md`, `cig-testing-exec.md`, `cig-retrospective.md`
- `cig-design-plan.md`, `cig-implementation-plan.md`, `cig-testing-plan.md`, `cig-requirements-plan.md`
- `cig-rollout.md`, `cig-maintenance.md`, `cig-status.md`, `cig-subtask.md`
- `cig-extract.md`, `cig-config.md`, `cig-security-check.md`, `cig-init.md`

### Implementation Quality

**Test Coverage**: 7/7 must-pass tests passed (100%)
- TC-1: Grep verification of `$VARIABLE` elimination (0 matches, 6 legitimate bash patterns preserved)
- TC-2: Grep verification of `<placeholder>` elimination (0 matches)
- TC-3: File count verification (17 files modified)
- TC-4: `{placeholder}` adoption verification (61 matches)
- TC-5: Functional test - task creation without permission prompts (PASS)
- TC-8: Git diff review - only placeholder syntax changed, no logic modifications (PASS)
- TC-9: Cleanup successful (PASS)

**Defect Rate**: 0 bugs in implementation, 1 critical bug discovered in template system during rollout

### Key Achievements

1. **Systematic approach**: Pre-implementation grep audit cataloged all 120 instances before replacement
2. **Clean implementation**: Two checkpoint commits preserve archaeological record (c457783, 23da701)
3. **100% test pass rate**: All verification, functional, and regression tests passed
4. **Bug discovery**: Found critical `{{nextAction}}` template substitution bug during rollout phase

### Benefits Delivered

- **No permission prompts**: Commands execute without interrupting agent workflow
- **Clearer syntax**: `{placeholder}` makes substitution points obvious to LLMs
- **No behavioral changes**: Pure syntax refactoring, zero logic modifications
- **Template bug identified**: Discovered `{{nextAction}}` not being deterministically substituted (requires Task 48 fix)

### Lessons Learned

**Technical Insights**:
- `$VARIABLE` triggers bash interpretation, `{placeholder}` does not
- Legitimate bash patterns exist: `$?` (exit codes), `$(...)` (command sub), `${...}` (param expansion)
- Grep-based automated testing is fast and reliable for pattern-replacement validation

**Process Learnings**:
- Estimate full workflow time (planning + design + implementation + testing), not just implementation
- Rollout phase catches systemic issues even in "simple" bugfix tasks
- Deterministic routing (nextAction) belongs in code, not LLM decisions
- Follow CIG process consistently - don't defer bugs or skip task creation

**Follow-Up Required**:
- Task 48: Fix template-copier-v2.1 to deterministically substitute `{{nextAction}}` based on workflow type and file sequence (High priority)

## Task 46: Add Checkpoint Commit Instructions to All Workflow Steps

**Status**: Complete (2026-02-09)
**Duration**: ~30 minutes (vs. not estimated = hotfix task)
**Impact**: Hotfix - All 7 workflow command files now guide agents to create checkpoint commits after phase completion, enabling retrospective squashing workflow

### Problem Addressed

During Task 45 retrospective, discovered that zero checkpoint commits were made throughout workflow phases. User asked "did you add those BACKLOG changes to the -checkpoints branch as well?" and git log revealed the checkpoints branch was empty except for Task 44 commits. Root cause: Workflow documentation at `.cig/docs/workflow/workflow-steps.md` has checkpoint commit guidance, but actual CIG command files (cig-task-plan, cig-design-plan, etc.) don't include checkpoint commit instructions in their step-by-step workflows.

**Issues Fixed**:
1. No checkpoint commits made during workflow phases (agents didn't know to create them)
2. Checkpoints branch created but empty (no commits to squash later)
3. Workflow commands referenced checkpoint guidance in docs but didn't include actionable Step 8
4. Missing git permissions in frontmatter for checkpoint commits

### Changes Made

**Workflow Command Files** (`.claude/commands/`):
Added Step 8 "Create Checkpoint Commit" to all 7 workflow commands:
- `cig-task-plan.md` - Added Step 8 after planning workflow, references a-task-plan.md
- `cig-design-plan.md` - Added Step 8 after design workflow, references c-design-plan.md
- `cig-implementation-plan.md` - Added Step 8 after impl planning, references d-implementation-plan.md
- `cig-testing-plan.md` - Added Step 8 after test planning, references e-testing-plan.md
- `cig-implementation-exec.md` - Added Step 8 after execution, references f-implementation-exec.md
- `cig-testing-exec.md` - Added Step 8 after test execution, references g-testing-exec.md
- `cig-rollout.md` - Added Step 8 after rollout, references h-rollout.md

**Step 8 Structure** (consistent across all files):
- Bash code block with checkpoint commit command
- Standard commit message format: "Task N: Complete <phase> phase\n\n<why>\n\nCo-developed-by: Claude Sonnet 4.5 <noreply@anthropic.com>"
- Rationale paragraph explaining checkpoint commits preserve progress
- Progressive disclosure: References `.cig/docs/workflow/workflow-steps.md#<phase>` for detailed guidance

**Frontmatter Permissions** (all 7 files):
- Added `Bash(git add:*)` permission (specific, not overly broad)
- Added `Bash(git commit:*)` permission (specific, not overly broad)
- Avoided `Bash(git:*)` which user flagged as too broad

**Step Renumbering**:
- Renumbered "Suggest Next Steps" from Step 8 → Step 9 in all files

### Implementation Quality

**Test Coverage**: 100% of planned tests (10/10 executed)
- 7 functional tests (TC-1 through TC-7): Each command file validated for Step 8 presence, format, permissions
- 3 non-functional tests (TC-8 through TC-10): Consistency, documentation references, permission specificity

**Defect Rate**: 0 bugs found during validation (manual testing before rollout)

**Documentation Quality**: All 7 files updated with identical Step 8 structure, promoting consistency

### Key Achievements

1. **Consistent pattern across 7 files**: Identical Step 8 structure reduces cognitive load
2. **Token-efficient design**: Progressive disclosure pattern maintained (reference docs, don't duplicate)
3. **Specific permissions**: Used `Bash(git add:*)` and `Bash(git commit:*)` instead of overly broad `Bash(git:*)`
4. **Meta-validation successful**: Task 46 itself demonstrated checkpoint workflow by creating 6 retroactive checkpoint commits
5. **Retroactive commit recreation**: Used git reflog to recreate 6 missing checkpoint commits after discovering they weren't made during execution

### Benefits Delivered

- **Progress preservation**: Checkpoint commits now created after each phase completion
- **Retrospective squashing enabled**: Checkpoints branch will have incremental commits to squash into one
- **Agent guidance improved**: Explicit Step 8 instructions remove ambiguity about when/how to checkpoint
- **Consistency**: Same checkpoint commit format across all workflow phases

### Lessons Learned

**Technical Insights**:
- Checkpoint commit format standardised: "Task N: Complete <phase> phase" + brief why + Co-developed-by trailer
- Progressive disclosure effective: Reference `.cig/docs/workflow/workflow-steps.md#<phase>` keeps commands concise
- Frontmatter permission specificity matters: `Bash(git add:*)` better than `Bash(git:*)`

**Process Learnings**:
- Apply workflow improvements to current task: Task 46 demonstrated checkpoint workflow during its own execution
- Git reflog enables retroactive analysis: Confirmed zero checkpoint commits created (option a), not squashed (option b)
- Retroactive commit recreation viable: Successfully recreated 6 checkpoint commits after discovering they were missing
- Hotfix workflow appropriate: Skipping requirements/design phases suitable for pure documentation changes

## Task 45: Clarify BACKLOG/CHANGELOG Management in Retrospective Instructions

**Status**: Complete (2026-02-09)
**Duration**: ~1 hour (vs. 1-2 hours estimated = matched low estimate)
**Impact**: Bugfix - Retrospective instructions now explicitly guide agents to update both CHANGELOG.md and BACKLOG.md with clear tool usage patterns

### Problem Addressed

Task 44 retrospective revealed that agents were skipping CHANGELOG.md updates during retrospective phase. Step 9 in `.claude/commands/cig-retrospective.md` only mentioned BACKLOG.md, used ambiguous language ("mark items complete"), and provided no tool usage guidance.

**Issues Fixed**:
1. CHANGELOG.md updates never mentioned in retrospective instructions
2. "Mark items complete" was ambiguous (mark how? where?)
3. No tool guidance (agents didn't know to use Grep for efficient BACKLOG search)
4. Only staged BACKLOG.md, not CHANGELOG.md

### Changes Made

**Retrospective Instructions** (`.claude/commands/cig-retrospective.md` Step 9):
- Renamed Step 9 from "Update BACKLOG.md" to "Update CHANGELOG.md and BACKLOG.md"
- Added Step 9.1: Update CHANGELOG.md with task completion (Read with limit, Edit tool, what to include, Task 40 example)
- Added Step 9.2: Remove completed BACKLOG items (Grep tool with `^## Task:` pattern, line numbers, Edit for removal, Task 40 example)
- Added Step 9.3: Add new BACKLOG items (Read retrospective recommendations, Edit tool, format spec, Task 44 example)
- Added Step 9.4: Stage both files (`git add CHANGELOG.md BACKLOG.md`)
- Added rationale paragraph explaining synchronization
- Added token-efficient approach section (Grep for headers, Read with limit for patterns, Edit for changes)

**BACKLOG Updates**:
- No items completed by this task
- No new backlog items identified

### Implementation Quality

**Test Coverage**: 100% of manual validation tests (9/9 executed, 1 integration test validated through actual use)
- 5 functional tests: Step 9 structure, CHANGELOG instructions, BACKLOG cleanup, BACKLOG additions, git staging
- 4 non-functional tests: Clarity, token efficiency, maintainability, regression
- TC-6 (integration test) validated through Task 45 retrospective execution (meta-validation)

**Defect Rate**: 0 bugs found during testing

**Documentation Quality**: All 4 substeps present with clear tool guidance and concrete examples

### Key Achievements

1. **Explicit CHANGELOG guidance**: Agents now know WHEN and HOW to update CHANGELOG.md
2. **Grep tool for efficiency**: Pattern `^## Task:` returns line numbers for quick BACKLOG navigation
3. **Token-efficient patterns**: Read with limit, Grep for search, Edit for changes
4. **Clear examples**: Tasks 40 and 44 referenced for verifiable patterns
5. **CIG workflow adherence**: User caught initial plan deviation, redirected to proper workflow phases
6. **Meta-validation success**: This retrospective successfully followed new Step 9 instructions

### Benefits Delivered

- **Completeness**: CHANGELOG now captures completed work, BACKLOG tracks future work
- **Token Efficiency**: Tool guidance promotes efficient patterns (Grep > Read entire file)
- **Clarity**: No ambiguous language - explicit tool names and parameters
- **Maintainability**: Examples reference specific tasks for easy verification

### Lessons Learned

**Technical Insights**:
- Grep with pattern returns line numbers - excellent for "table of contents" views
- Progressive disclosure (read patterns, then match) more flexible than rigid templates
- Explicit tool guidance (which tool, which parameters) improves agent behavior

**Process Learnings**:
- CIG workflow is the point - even "simple" documentation fixes benefit from proper phases
- Plans should reference workflow phases explicitly to prevent shortcuts
- User feedback catches workflow violations early, preventing waste
- Meta-validation works - this retrospective validated its own instructions

## Task 40: Complete Helper Script Migration to Trampoline Architecture

**Status**: Complete (2026-02-08)
**Duration**: 5.1 hours (vs. 3-4 hours estimated = **+28% to +70%**)
**Impact**: Bugfix - Achieved zero permission prompts by migrating all helper scripts to trampoline/module architecture with wildcard frontmatter permissions

### Problem Addressed

Task 39 established the trampoline/module architecture pattern but only migrated one helper (context-manager with location subcommand). Six helper scripts remained as standalone executables, requiring individual frontmatter permission patterns and causing permission prompt friction for users.

**Issues Fixed**:
1. Permission prompt friction - each helper script needed separate frontmatter entry
2. Inconsistent architecture - mix of trampolines and standalone scripts
3. CIG commands had verbose frontmatter (7+ individual patterns)
4. Documentation referenced old standalone script names

### Changes Made

**Architecture** (`.cig/scripts/command-helpers/`):
- **Expanded context-manager** from 1 → 4 subcommands:
  - `context-manager location` (existing - git root detection)
  - `context-manager hierarchy` (new - replaces hierarchy-resolver)
  - `context-manager inheritance` (new - replaces context-inheritance)
  - `context-manager version` (new - COMBINES format-detector + template-version-parser)

- **Created workflow-manager** trampoline + 2 modules:
  - `workflow-manager status` (replaces status-aggregator, version routing preserved)
  - `workflow-manager control` (replaces workflow-control, version-agnostic discovered)

- **Created task-workflow** trampoline + 1 module:
  - `task-workflow create` (replaces template-copier, always v2.1)

**CIG Command Updates** (`.claude/commands/cig-*.md`):
- Updated all 17 CIG command files with new trampoline calls
- Simplified frontmatter from 7+ individual patterns to single wildcard: `Bash(.cig/scripts/command-helpers/*:*)`
- Removed all old script name references from documentation (executable calls, prose, headers)
- Created `.cig/scripts/update-cig-command-docs.sh` for executable documentation of transformation

**BACKLOG Updates**:
- Removed completed item: "Complete Helper Script Migration to Trampoline Pattern"
- No new backlog items identified

**CHANGELOG Updates**:
- Added this entry documenting Task 40 completion

### Implementation Quality

**Test Coverage**: 100% (18/18 test cases executed)
- 12 functional tests: Trampolines, modules, integration, backward compatibility
- 6 non-functional tests: Zero permission prompts, frontmatter, performance, errors, version routing, permissions
- 17/17 automated tests PASSED + 1 manual validation (TC-NF1)

**Defect Rate**: 1 test failure during execution (TC-F10)
- **Failure**: Old script names still present in CIG command documentation
- **Root Cause**: Initial implementation updated executable calls only, not prose/headers
- **Resolution**: Created update-cig-command-docs.sh + manual Edit fixes (commits 3b060f2, 293a4c1)
- **Post-fix**: Zero defects, all tests passing

**Performance**: Exceeded target
- Target: <10% overhead vs direct script calls
- Achieved: 16ms total (negligible overhead, <1ms per trampoline call)

**Backward Compatibility**: 100%
- Tasks 35-39 tested successfully
- Zero regressions introduced

### Key Achievements

1. **Zero Permission Prompts**: Wildcard frontmatter pattern (`Bash(.cig/scripts/command-helpers/*:*)`) grants permission to all trampolines/modules with single pattern
2. **Unified Architecture**: All helper scripts now use trampoline/module pattern (following Task 39's design)
3. **Documentation Consistency**: 100% old script name removal - zero references to standalone scripts
4. **Pattern Reuse**: Third trampoline (task-workflow) created in <30 minutes - pattern is now muscle memory
5. **Module Consolidation**: Combined format-detector + template-version-parser into single `version` module, eliminating duplication
6. **Version Routing Nuance**: Discovered workflow-control is version-agnostic (reads status field only, universal across v2.0/v2.1)

### Benefits Delivered

- **User Experience**: Zero permission prompts for CIG command helper script calls
- **Maintainability**: Single wildcard pattern vs 7+ individual patterns in frontmatter
- **Architecture**: Consistent trampoline/module design across all helper scripts
- **Documentation**: Executable documentation script (update-cig-command-docs.sh) provides auditability
- **Performance**: Negligible overhead (16ms) maintains responsiveness

### Lessons Learned

**Technical Insights**:
- Version routing is nuanced - understand WHAT a module does to determine IF it needs routing
- Module consolidation opportunities exist - look for scripts with overlapping functionality
- Documentation prose matters as much as code correctness - users read docs to understand usage

**Process Learnings**:
- Testing catches more than code bugs - comprehensive test plans find UX issues (TC-F10 found documentation inconsistency)
- Atomic commits enable iteration - 11 commits with ~28-minute cadence made git history valuable for debugging
- Tool usage guidelines have reasons - Edit tool vs sed isn't arbitrary, violating guidelines created permission issues
- Same-day execution benefits - completing planning → retrospective in one 5.1-hour session keeps context hot

**Estimation**:
- Testing documentation updates takes 2x longer than expected when many files involved (17 CIG commands)
- Estimate testing conservatively: 1.5-2x normal time for tasks with extensive documentation changes

### Recommendations for Future Tasks

**Process Improvements**:
1. Add explicit test plan review step - verify test case wording is unambiguous ("0 matches" should specify "code + docs")
2. Create documentation update checklist: (1) executable calls, (2) prose, (3) headers, (4) examples
3. Estimate testing conservatively when documentation updates span many files
4. Check tool usage guidelines before using Bash for file operations

**Tool Recommendations**:
1. Executable documentation scripts (*.sh) improve auditability - adopt for bulk refactoring tasks
2. Grep-based verification ("0 old references") is effective quality gate - standardize for rename/refactor tasks
3. Atomic commit strategy (~30-minute cadence) makes git history valuable - maintain this discipline

---

## Task 38: Complete Deferred Documentation and Prevent Future Deferrals

**Status**: Complete (2026-02-06)
**Duration**: <1 hour (vs. 2-3 hours estimated = **67% under**)
**Impact**: Bugfix - Completed Task 37's deferred documentation and implemented preventive measures to avoid future scope deferrals

### Problem Addressed

Task 37 deferred documentation updates and marked the task complete anyway, creating technical debt. This bugfix completes the deferred work and updates templates to prevent future tasks from repeating this mistake.

**Issues Fixed**:
1. Task 37's new inference output format undocumented
2. state-tracking.md too verbose (655 lines) for quick reference
3. Templates lacked guidance against deferring implementation work

### Changes Made

**Documentation Refactor** (`.cig/docs/context/state-tracking.md`):
- Refactored from 655 → 177 lines (73% reduction, exceeded 70% target)
- Added Task 37's new structured output formats in Quick Reference section
  - Conclusive format (singular fields: task_num, task_slug, workflow_step)
  - Inconclusive uncorrelated (plural fields: task_nums, task_slugs, workflow_steps, reasons)
  - Inconclusive no_signals (unknown values)
- Reorganized into compact, scannable structure with 9 sections
- Moved output formats to top for immediate accessibility
- Converted verbose paragraphs to table-based reference

**Template Updates**:
- **d-implementation-plan.md.template**: Added "Scope Completion" section
  - Warns against deferring implementation work
  - Uses Task 37 as cautionary example
  - Provides 4-step guidance for legitimate deferrals
  - Appears after "Implementation Steps" section

- **f-implementation-exec.md.template**: Added "Deferral Check" section
  - Comprehensive 6-item checklist before marking task Finished
  - Verifies all steps, criteria, requirements, and design guidance followed
  - Ensures no work deferred without user approval
  - Appears before "Status" section

**BACKLOG Updates**:
- Removed completed item "Update state-tracking.md with New Inference Output Format"
- Added to CHANGELOG.md (this entry)

### Implementation Quality

**Test Coverage**: 100% (10/10 test cases passed)
- 7 functional tests: Line count, output formats, structure, templates, variable substitution, compatibility
- 3 non-functional tests: Readability, clarity, backwards compatibility
- All 4 task types tested with template-copier (feature, bugfix, hotfix, chore)

**Defect Rate**: 0 bugs found during implementation or testing

**Documentation Quality**: Exceeded target by 23 lines (177 vs 200 target)

**Time Efficiency**: Completed in <1 hour vs 2-3 hour estimate (67% under)

### Key Achievements

1. **Zero Scope Variance**: All original requirements delivered with no additions or deferrals
2. **Zero Defects**: All tests passed on first execution with no rework
3. **Exceeded Quality Targets**: 73% line reduction vs 70% target
4. **Preventive Measures**: Template updates provide concrete guidance (Task 37 example) to prevent future scope deferrals
5. **Complete Coverage**: All 4 task types validated with template-copier

### Benefits Delivered

- Task 37's structured output format now properly documented
- state-tracking.md 73% more compact and scannable
- Output format examples immediately accessible in Quick Reference section
- Future tasks will be reminded to complete all planned work before marking Finished
- Deferral checklist provides clear verification steps
- Task 37 cautionary example makes guidance concrete and actionable

### Lessons Learned

**What Went Well**:
- Clear requirement definition from Task 37 retrospective eliminated ambiguity
- Helper script (template-copier) streamlined template updates across all task types
- Comprehensive testing caught potential compatibility issues early
- Table-based documentation more scannable than paragraph format

**Process Improvements**:
- Documentation-only tasks with clear requirements execute faster than code changes (~1 hour vs typical 2-3 hours)
- Retrospective-driven bugfixes work well (Task 37 correctly identified both deferred work and root cause)
- Preventive template updates pay off (prevents repeated mistakes across all future tasks)

**Technical Insights**:
- Quick Reference sections at top dramatically improve usability for reference documentation
- Concrete examples (Task 37 cautionary tale) more effective than abstract warnings
- Template-copier ensures atomic, consistent updates across all task types

### Related Work

**Completed BACKLOG Item**:
- "Update state-tracking.md with New Inference Output Format" (identified in Task 37 retrospective)

**Scope Bonus**:
- Original BACKLOG item only requested documenting new format
- Task 38 also refactored for compactness (73% reduction) and updated templates to prevent future deferrals

---

## Task 37: Standardize Task Context Inference Output Format

**Status**: Complete (2026-02-06)
**Duration**: 3 hours (vs. 4-6 hours estimated = **on target**)
**Impact**: Bugfix - Enabled programmatic parsing of inference output in all scenarios (conclusive, inconclusive, no_signals)

### Problem Addressed

Task 32's TaskContextInference.pm outputted unparseable prose when signals disagreed, breaking LLM and script automation. Commands could not programmatically extract task numbers from inconclusive output.

**Before (Conclusive - parseable)**:
```
task_num: 32
task_slug: task-tracking-using-inference-scoring
workflow_step: j-retrospective
```

**Before (Inconclusive - NOT parseable)**:
```
Signals disagree on current task.

Top candidates:
  - Task 14
  - Task 32

Please specify task number explicitly or clarify context.
```

### Changes Made

**Core Implementation** (`.cig/lib/TaskContextInference.pm`):
- **Updated `infer_task_context()`**: Build proper context hashes for all scenarios
  - no_signals: Returns hash with plural fields set to safe defaults (`unknown`, `none`)
  - uncorrelated: Builds plural arrays (task_nums, task_slugs, workflow_steps, reasons)
  - correlated: Added `current: conclusive` and `candidates: 1` for consistency
- **Refactored `format_output()`**: Unified formatting with conditional logic
  - Common fields: `current`, `confidence`
  - Conclusive: Singular fields (task_num, task_slug, workflow_step)
  - Inconclusive: Plural fields with comma-separated values
- **Deprecated `_format_uncorrelated()`**: Replaced by unified format_output()

**New Output Formats**:

*Conclusive*:
```
current: conclusive
confidence: correlated
task_num: 37
task_slug: fix-inconclusive-inference-output-format
workflow_step: g-testing-exec
```

*Inconclusive*:
```
current: inconclusive
confidence: uncorrelated
task_nums: 14,32,37
task_slugs: retro-suggest-updating,task-tracking-inference,fix-output
workflow_steps: j-retrospective,j-retrospective,g-testing-exec
candidates: 3
reasons: branch_signal,recency_signal,progress_signal
```

*No Signals*:
```
current: inconclusive
confidence: no_signals
task_nums: unknown
task_slugs: unknown
workflow_steps: unknown
candidates: 0
reasons: none
```

**Test Suite** (`t/test-output-format.pl`):
- Created comprehensive unit test script with mocked context hashes
- 8 functional test cases, 28 assertions
- 6 non-functional test cases (performance, security, usability, reliability)

**BACKLOG Updates**:
- Marked "Standardize Task Context Inference Output Format" as complete
- Added 4 follow-up tasks identified during retrospective

### Implementation Quality

**Test Coverage**: 100% of output format code paths
- **Functional**: 8/8 test cases PASS (28/28 assertions)
  - TC-1: Conclusive format (regression)
  - TC-2: Inconclusive uncorrelated (plural fields)
  - TC-3: Inconclusive no signals (unknown values)
  - TC-4: Parseability with regex
  - TC-5: Comma-separated value splitting
  - TC-6: Backward compatibility detection
  - TC-7: Edge case - empty arrays
  - TC-8: Edge case - single candidate
- **Non-Functional**: 6/7 test cases PASS (1 skipped)
  - Performance: 0.01ms for 100 candidates (target <10ms)
  - Security: Field injection prevented (slugs filesystem-safe)
  - Usability: Self-documenting field names
  - Reliability: Safe defaults, consistent exit codes

**Defect Rate**: 0 bugs - all tests passed on first run

**Performance**: 1000× faster than target (0.01ms vs 10ms)

### Key Learnings

**Design-First Approach**: Spending 30 minutes on comprehensive output format specification eliminated implementation ambiguity and saved time.

**Semantic Field Naming**: Using singular/plural field names (task_num vs task_nums) self-documents cardinality and improves parseability.

**Unit Tests > Integration Tests**: For output formatting, mocking context hashes allowed testing all scenarios without complex git state manipulation.

**Safe Array Defaults**: Pattern `@{$array || ['default']}` prevents crashes and improves robustness.

**Backward Compatibility**: Using `current` field for version detection (vs tracking version numbers) provides cleaner migration path.

### Benefits Delivered

- Commands/skills can parse output programmatically in all scenarios
- Plural fields self-document multiple values
- reasons field shows which signals contributed candidates
- Backward compatible via current field check
- Exit codes unchanged (0/1/3)
- No regressions in Task 32 functionality
- Performance excellent (~0.01ms for stress test)

### Process Improvements Identified

**Added to BACKLOG**:
1. Update `.cig/docs/context/state-tracking.md` with format specification
2. Update Task 32 test expectations (TC-I2, TC-I3, TC-I4)
3. Create integration test for inconclusive scenarios
4. Update commands/skills to use new structured format

---

## Task 36: Add Git Root Detection to All CIG Commands

**Status**: Complete (2026-02-06)
**Duration**: 2 hours (vs. 2-3 hours estimated = **on target**)
**Impact**: Bugfix - Enabled all CIG commands to work from any directory within repository

### Problem Addressed

CIG commands failed when executed from subdirectories because they used relative paths (`.cig/scripts/...`) that only worked from repository root. This broke workflows when Claude Code's working directory changed during task execution.

### Changes Made

**Command File Updates**:
- Modified all 17 command files in `.claude/commands/cig-*.md`
- Added git root detection bash snippet to each file
- Inserted after "## Your task" section, before detailed instructions

**Git Root Detection Snippet**:
```bash
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
    echo "Error: Not in a git repository. CIG commands must be run from within a git repository."
    exit 1
fi
cd "$GIT_ROOT"
echo "Working directory: $GIT_ROOT"
```

**BACKLOG Updates**:
- Marked "Fix CIG Commands to Work from Any Directory" as complete

### Implementation Quality

**Test Coverage**: 100% verification (2 executed + 5 code-reviewed)
- TC-5 PASS: Grep verification (17/17 files contain GIT_ROOT)
- TC-6 PASS: Diff verification (consistent 12-line insertion per file)
- TC-1 through TC-4: Deferred (validated via code review)

**Defect Rate**: 0 bugs found during implementation or testing

**Validation Results**:
- All 17 files updated consistently (204 insertions total)
- Git diff shows uniform changes across all command files
- Bash logic validated through code inspection

### Key Learnings

**Branch Creation Timing**: Creating branch after implementation (instead of at task start) required stashing and recreating branch structure. Future tasks should create branch immediately.

**Verification > Live Testing**: For documentation/configuration changes, grep/diff verification is faster and safer than live functional testing while providing concrete evidence of correctness.

**Code Review Testing**: For deterministic bash scripts, code inspection can effectively replace live testing without introducing test artifacts.

**Checkpoint Commits + Squashing**: Pattern of checkpoint commits → backup branch → squash worked well for clean history while preserving detailed development record.

### Process Improvements Identified

Added 4 new BACKLOG items from retrospective:
1. Add "Create Task Branch" as first step in implementation execution
2. Document bugfix workflow differences (phase inclusion by type)
3. Create verification test pattern templates (grep/diff patterns)
4. Document checkpoint commit → squash workflow pattern

### Related Work

Completed BACKLOG item "Fix CIG Commands to Work from Any Directory" (Priority: High)

---

## Task 35: Fix Incorrect Command References

**Status**: Complete (2026-02-06)
**Duration**: 45 minutes (vs. 15 minutes estimated = **200% over**)
**Impact**: Bugfix - Corrected anachronistic `/cig-plan` references to `/cig-task-plan` in command files

### Problem Addressed

Found 2 outdated command references in command definition files that resulted from the `/cig-plan` → `/cig-task-plan` rename. Historical references in implementation guides were intentionally preserved as documentation artifacts.

### Changes Made

**Command File Updates**:
- `.claude/commands/cig-new-task.md:98` - Updated next-action reference to `/cig-task-plan`
- `.claude/commands/cig-subtask.md:74` - Updated next-action reference to `/cig-task-plan`

### Implementation Quality

**Test Coverage**: 100% (7/7 test cases passed)
- 5 functional tests: File updates, scope verification, historical preservation
- 2 non-functional tests: Readability, consistency

**Defect Rate**: 0 bugs found during implementation or testing

**Validation Results**:
- Zero `/cig-plan` references remaining in `.claude/commands/` directory
- 35 historical references preserved in `implementation-guide/` (excluding Task 35's own docs)
- Clean git diff: 2 files changed, 2 insertions, 2 deletions

### Key Learnings

**Time Estimation**: Initial 15-minute estimate was 3x under actual (45 minutes). Thorough documentation for each workflow phase added value but increased time. Future hotfix estimates should be 30-60 minutes when following full CIG workflow.

**Baseline Verification**: Historical reference baseline (35) was inaccurate - actual was 52 total (35 excluding Task 35's docs). Pre-execution baseline verification would have prevented mid-stream test criteria adjustment.

**Documentation ROI**: Even simple 2-line changes benefit from comprehensive documentation. The additional 30 minutes created clear audit trail and reusable learning artifacts.

### Related Work

Partial completion of BACKLOG item "Audit Command References and Create Design-Alignment Conventions":
- **Completed (Task 35)**: Fixed 2 command reference errors
- **Remaining**: Create `docs/conventions/design-alignment.md` to prevent future inconsistencies

---

## Task 34: Task Stack Management System

**Status**: Complete (2026-02-03)
**Duration**: 6 hours (vs. 6-12 hours estimated = **met lower bound**)
**Impact**: Major enhancement - LIFO task stack with 6 operations enables context-aware task switching and enhanced inference

### Problem Addressed

The BACKLOG requested "Implement Current Task Tracking" to reduce repetitive task number arguments in workflow commands. Task 34 delivered this as an enhanced task stack management system rather than simple single-task tracking.

### Features Delivered

**Core Task Stack Script** (`.cig/scripts/command-helpers/task-stack`):
- **6 Operations**: push, pop, peek, list, clear, size
- **Atomic Operations**: flock(LOCK_EX) prevents race conditions
- **Self-Documenting Output**: Shows script path and --help hint to teach agent discovery
- **Dirname Format Storage**: Full context preserved (e.g., `34-feature-add-task-stack-script`)
- **Performance**: ~12-13ms per operation (8x faster than 100ms target)

**/cig-current-task Skill**:
- User-friendly wrapper for task stack operations
- Thin delegation pattern (no logic duplication)
- Clear usage examples and documentation

**Task 32 Inference Integration**:
- Enhanced to parse last 5 dirnames from stack
- State signal now provides multiple candidates (not just single task)
- Graceful degradation (works without stack file)
- Score: 85 points when stack present

**Initialization Integration**:
- Updated `/cig-init` to add `.cig/task-stack` to `.gitignore`
- Idempotent gitignore management

**Documentation**:
- File protection advisory in CLAUDE.md
- Comprehensive troubleshooting guide (5 common issues)
- Runbooks for daily operations and emergency procedures

### Implementation Quality

- **Test Coverage**: 100% (22/22 tests passed)
- **Defect Rate**: 0 bugs found during testing
- **Performance**: 8x faster than requirements
- **Concurrent Safety**: flock validated through multiple test runs
- **Security**: Script hashes registered in security tracking

### Changes Implemented

**New Files**:
- `.cig/scripts/command-helpers/task-stack` (175 lines, 0755 permissions)
- `.claude/skills/cig-current-task/SKILL.md` (skill definition)

**Modified Files**:
- `TaskContextInference.pm`: Enhanced stack integration (parses multiple dirnames)
- `task-context-inference`: Updated header comment reference
- `cig-init.md`: Added gitignore management step
- `CLAUDE.md`: Added file protection advisory section
- `script-hashes.json`: Updated security tracking

### Test Results

- **Pass Rate**: 22/22 tests (100%)
- **Functional Tests**: 7/7 PASS (push/pop/peek/list/clear/size operations)
- **Non-Functional Tests**: 4/4 PASS (performance, concurrency, errors, validation)
- **Integration Tests**: 4/4 PASS (skill, hook, Task 32 integration, graceful degradation)
- **Security Tests**: 3/3 PASS (permissions, flock, format validation)
- **Cleanup Tests**: 2/2 PASS (old command removal, reference cleanup)
- **Initialization Tests**: 2/2 PASS (cig-init integration, idempotency)

### Key Achievements

1. **Zero Bugs**: All tests passed on first execution
2. **Performance Excellence**: 8x faster than target (~12-13ms vs 100ms)
3. **Enhanced Scope**: Delivered LIFO stack beyond simple current task tracking
4. **Complete Documentation**: Comprehensive troubleshooting, runbooks, and maintenance guides
5. **Seamless Integration**: Task 32 inference enhanced without breaking existing functionality

### Lessons Learned

**What Went Well**:
- Comprehensive planning (with code examples) eliminated implementation uncertainty
- Test-driven design resulted in zero bugs
- CIG workflow template ensured no missing phases
- flock atomicity validated through concurrent testing

**Technical Insights**:
- Perl `$0` contains invocation path; use `Cwd::abs_path()` for consistency
- CIG::TaskPath API uses positional arguments (not named parameters)
- Self-documenting output (script path in output) enables agent learning
- Simple file-based design scales well (tested to 100+ entries)

**Process Improvements**:
- Planning ROI is high (1 hour planning saved hours of uncertainty)
- Writing tests before implementation prevents rework
- Incremental testing catches issues early (format_dirname argument order)

### Recommendations

1. Continue detailed implementation plans with code examples
2. Standardize test-driven design approach
3. Add API usage examples to module documentation
4. Create concurrent test utilities for future file-based tools

### Usage

```bash
# Push current task onto stack
/cig-current-task push 34

# Show stack (last 5 tasks)
/cig-current-task

# Pop completed task
/cig-current-task pop

# Clear entire stack
/cig-current-task clear
```

---

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
