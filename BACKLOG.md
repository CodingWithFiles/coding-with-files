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

<!-- Completed: "Audit Perl-vs-Bash helper scripts and migrate where feasible" — Task 128 (2026-05-06): all 5 shell helpers were dead/trivial; deleted, with the one live caller (cwf-config skill) inlined -->

---

## Bug: Security-review changeset construction is broken in three ways

**Task-Type**: bugfix
**Priority**: Very High
**Status**: Follow-up from Task 128 (discovered while running g-testing-exec)

The pathspec and diff anchor used by the exec-phase security-review subagent (defined in `.cwf/docs/skills/security-review.md` § "Pathspec coverage" and inlined into Step 8 of `cwf-implementation-exec/SKILL.md` and `cwf-testing-exec/SKILL.md`) is `git diff $(git merge-base HEAD main)..HEAD -- '*.pl' '*.pm' '*.bash' '*.sh' '.cwf/scripts/**' '.claude/scripts/**' '.claude/skills/**' '.claude/hooks/**' '.cwf/lib/**' '.cwf/docs/skills/**' '.claude/rules/**' '.claude/settings.json' 'implementation-guide/cwf-project.json'`. This is wrong-shaped on three independent axes; any one of them can cause silent under-coverage.

### 1. Extension-based filtering misses script-content files
The pathspec mixes extension globs (`*.pl`, `*.pm`, `*.bash`, `*.sh`) with directory globs. Most CWF helpers and hooks have **no extension** (`cwf-manage`, `context-manager`, `task-stack`, `stop-stale-status-detector`, etc.) — they are caught only because the directory globs (`.cwf/scripts/**`, `.cwf/lib/**`, `.cwf/scripts/hooks/**` via the parent glob) happen to also list them. Extension is a label, not a content classification. A new Perl or shell file dropped *outside* the listed directories (e.g. a top-level repo script with no extension) would be silently skipped. Classification by shebang / content is the only correct mechanism.

### 2. Pathspec hardcodes this repo's language stack
The extension list bakes in `*.pl` `*.pm` `*.bash` `*.sh` — fine here, useless in any consumer of CWF that uses Python, Go, Ruby, JavaScript, etc. A repo using CWF for an Elixir project would get a security-review subagent that ignores all the project's executable code. The subagent is shipped as part of CWF (it's referenced from installed skills via `.cwf/docs/skills/security-review.md`), so the breakage propagates everywhere CWF is installed.

### 3. `merge-base HEAD main` anchor mechanically over-includes earlier work
`git merge-base HEAD main` gives a stable lineage point only under particular merge policies (FF-only, no rebase, no main rewinds). When an earlier task's branch has not yet been merged to main (the normal case mid-batch — Task 127 was unmerged when Task 128 ran), the merge-base sits *before* that earlier task's tip, so the diff includes the earlier task's already-reviewed changes. This inflated Task 127's review to ~2166 lines (blew the 500-line cap; required manual workflow per the existing backlog entry "Quantitatively justify the security-review subagent line-count cap") and inflated Task 128's review to 1422/1545 lines for the same reason. It also breaks for any consumer who rebases, squashes on landing, or uses a non-`main` trunk name.

### Why Very High

- Silent failure mode: the cap-exceeded path records `error: changeset exceeds 500-line review cap` and proceeds to checkpoint anyway, so the gap is logged but doesn't block. A reader of the wf step file sees "security review ran" without realising no review actually occurred.
- The same bug affects every CWF-installed project's security gate.
- The three issues compound: extension-filtering would matter less if the directory list were exhaustive, but the directory list also presumes the consumer's layout.

### Acceptance criteria

- [ ] Replace extension globs with content-based detection (shebang / `file --mime-type`) for files in the security-relevant directory set. Files without a shebang in those dirs still go through; files outside those dirs that **are** scripts also go through.
- [ ] Make the security-relevant directory set discoverable (e.g. read from `.cwf/security/` config or compute from CWF install layout) rather than hardcoded language-stack assumptions.
- [ ] Replace the `merge-base HEAD main` anchor with something that doesn't depend on merge policy and doesn't over-include earlier-task commits. Candidates to evaluate: (a) the previous wf step's checkpoint commit (so f-phase reviews diff f's own delta, g reviews g's delta), (b) the task branch's own first commit, (c) a per-task baseline ref written by `cwf-new-task`. Do not assume `main` exists or is the trunk.
- [ ] Update `.cwf/docs/skills/security-review.md` and the two exec SKILLs (`cwf-implementation-exec`, `cwf-testing-exec`) consistently — pathspec is single-source-of-truth in `security-review.md`.
- [ ] Add a regression test that constructs a synthetic repo with: (a) an extensionless shell script that should be reviewed, (b) a Python file that should be reviewed in a non-CWF-stack consumer, (c) an unmerged earlier task branch that should not pollute the diff.

### Out of scope

- The 500-line cap value itself (covered by the existing backlog entry "Quantitatively justify the security-review subagent line-count cap").
- The subagent prompt content / threat model — already covered separately ("Tighten security-subagent prompt for sentinel-line compliance").

**Identified in**: Task 128 g-testing-exec phase, when the cap-overflow message in the wf step file led the user to inspect the underlying `git diff` invocation.

---

<!-- Completed: "Expand script-hashes.json integrity surface to command-helpers and hooks" — Task 125 (2026-05-03) -->

---

## Task: Tighten security-subagent prompt for sentinel-line compliance

**Task-Type**: chore
**Priority**: Low
**Status**: Follow-up from Task 123

The security subagent introduced in Task 123 returns three sentinel-prefixed states (`findings:` / `no findings` / `error:`) classified per a three-tier rule (primary sentinel → numbered-list fallback → conservative-default error). TC-AC8 in Task 123 demonstrated that subagents tend not to lead with the sentinel — the dogfood call returned ~70 lines of analysis before the closing `no findings` line, causing the fallback classifier to fire and produce a `**State**: findings` even though the substantive verdict was clean. The conservative-default behaviour is correct (loud false positive > silent false negative), but the false-positive rate could be reduced.

**Problem**: Subagents respond with verbose intros even when instructed otherwise. The current prompt says "Start your response with one of three sentinel lines" but the model does not reliably comply.

**Solution**: One-line edit to `.cwf/docs/skills/security-review.md` § "Exec-phase prompt template" to push the sentinel ahead of any analysis. Suggested wording: "Your VERY FIRST output line MUST be the sentinel — do not preface with analysis." Optionally consider one-token sentinels (`NO_FINDINGS:`, `FINDINGS:`, `ERROR:`) which are harder to embed mid-paragraph.

**Trigger**: Defer until the classifier-versus-substance gap recurs in >2 of the next 5 feature tasks. If the rate stays acceptable, no action needed — the conservative classifier is doing its job.

**Identified in**: Task 123 retrospective (j-retrospective.md § "What Could Be Improved")

---

<!-- Completed: "Refresh .claude/settings.json on `cwf-manage update`" — superseded by Task 127 (broader: re-applies every cwf-init artefact, not just settings.json). -->

<!-- Completed: "Sync cwf-init artefacts during upgrade with Debian-style config conflict resolution" — Task 127 (2026-05-05) -->

---

## Task: Quantitatively justify the security-review subagent line-count cap

**Task-Type**: chore
**Priority**: Low
**Status**: Follow-up from Task 127

The current 500-line cap on security-review subagent invocations (set in Task 123, applied across `.cwf/docs/skills/security-review.md` and the exec-phase skills) is qualitatively justified — large changesets exceed the subagent's effective review window — but no empirical evidence backs the specific value of 500 vs 250 vs 1000. Task 127's changeset (2166 lines) blew through the cap and required a manual approval workflow; the user explicitly flagged the threshold's lack of quantitative basis.

**Approach**:
1. Pick 5-10 representative changesets from CWF history at varying sizes (250, 500, 1000, 2000 lines).
2. Run the security-review subagent on each; record finding-rate, false-positive-rate, runtime, and the subagent's own self-reported coverage assessment.
3. Plot finding-rate-per-line and runtime against changeset size; identify the inflection point where review quality starts to degrade.
4. Set the cap from data, not vibes. Document the methodology in `.cwf/docs/skills/security-review.md` so future revisions have a baseline.

**Out of scope**: changing the subagent prompt itself (covered by the existing "Tighten security-subagent prompt for sentinel-line compliance" follow-up). This task is purely about the threshold value.

**Identified in**: Task 127 retrospective (j-retrospective.md § "What Could Be Improved")

---

## Task: Add fixture-server harness for end-to-end cwf-manage update tests

**Task-Type**: chore
**Priority**: Low
**Status**: Follow-up from Task 127

Task 127's testing covers `cwf-apply-artefacts` at the helper level and `cwf-manage update` at the helper-sub level (lock acquisition, manifest SHA validation, path-traversal). What's missing is a true end-to-end test that exercises the full clone+subtree-pull flow — TC-INT-AC1 in Task 127's test plan was marked PARTIAL for this reason. Closing the gap requires a fixture remote (a local git repo serving as upstream) and a multi-commit fixture history so subtree pulls have something meaningful to pull.

**Approach**:
1. Build a `t/fixtures/upstream-server/` skeleton: bare git repo, scripted commit history (3-5 commits with realistic CWF-shaped diffs).
2. Add `t/cwf-manage-update-end-to-end.t`: clones fixture upstream → runs `cwf-manage init` → modifies fixture → runs `cwf-manage update` → asserts artefacts updated, manifest-SHA pinned, lock released.
3. Cover the regression cases not currently covered: subtree-pull conflict, manifest schema bump (when v2 exists), upstream rollback (downgrade scenario).

**Out of scope**: SIGKILL-during-rename atomicity (covered architecturally by same-dir-temp + rename), interactive D/A prompt branches (need expect-style harness — separate task if ever needed).

**Identified in**: Task 127 retrospective (j-retrospective.md § "Recommendations § Future Work")

---

---

## Task: Reconcile cwf-manage update and fix-security chmod logic

**Task-Type**: chore
**Priority**: Low
**Status**: Follow-up from Task 120

`cwf-manage update` (line 350) does a blanket `chmod 0755` over `.cwf/scripts/`. `cwf-manage fix-security` (Task 120) chmods to *exact* recorded perms (e.g. `0500`/`0700`/`0755`) per `script-hashes.json`. Both pass validate, but they produce different end states. Worth reconciling so update and fix-security converge — most likely option: have `update` call `fix-security` after the copy step, removing the bespoke `chmod 0755` from the update path.

**Scope**:
- Replace the blanket chmod in `cmd_update` with a `cmd_fix_security` call (or extract the per-entry chmod logic into a shared sub)
- Confirm the integration test for `update` (if any) still passes
- Refresh `cwf-manage` hash after the change

**Identified in**: Task 120 retrospective (j-retrospective.md, "Future Work")

---

## Task: Add --dry-run flag to cwf-manage fix-security

**Task-Type**: feature
**Priority**: Low
**Status**: Follow-up from Task 120

`fix-security` currently has no preview mode. A `--dry-run` flag would print the chmod actions it *would* take and the unfixable entries it *would* surface, without mutating the filesystem. Useful for security-conscious users auditing the install before a repair.

**Scope**:
- Add `--dry-run` argument parsing in `cmd_fix_security`
- Skip the `chmod` call when in dry-run mode; preface fix lines with `[dry-run]`
- Add a test case to `t/cwf-manage-fix-security.t` that asserts no fs mutation in dry-run mode
- Update help text and SKILL.md if appropriate

**Identified in**: Task 120 retrospective (j-retrospective.md, "Future Work")

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

When `/cwf-new-task` or `/cwf-new-subtask` is invoked without a task type, the agent should infer the appropriate type based on the task description and complexity rather than failing with a validation error. If the inference is ambiguous, ask the user to choose. This prevents misclassification — e.g., a task with unclear requirements being created as a chore (no design phase) when it should be a feature.

**Inference guidance**: Consider whether requirements/design phases are needed (feature), whether this fixes a defect (bugfix/hotfix), whether it's mechanical with no ambiguity (chore), or whether it's exploratory (discovery).

**Identified in**: Task 59 (agent chose chore for a task with unclear requirements, required delete/recreate as feature)

---

<!-- Completed: "Update Branding and Documentation for Skills Architecture" — Task 79 (2026-02-20) -->

<!-- Completed: "Audit /cwf-init for Obsolete Category Subdirectories" — Task 68 (2026-02-18) -->


<!-- Completed: "Fix template-copier-v2.1 Uninitialized Variable Warnings" — Task 74 (2026-02-19) -->

<!-- Completed: "Bug: /cwf-init Should Run Security Check and Fix Permissions" — Task 120 (2026-05-02) -->

---

<!-- Completed: "Add Status Update Helper Script (cwf-set-status)" — Task 101 (2026-04-18) -->

---

<!-- Completed: "Add Checkpoint Commit Helper Script (cwf-checkpoint-commit)" — Task 102 (2026-04-18) -->

---

## Task: Add Slug Generation Helper Script (`cwf-slug`)

**Task-Type**: feature
**Priority**: Low (downgraded post-Task-119)

Expose `generate_slug` from `template-copier-v2.1` as a standalone helper so callers can preview the slug a description will produce before invoking task creation.

**Scope**:
- Script wraps `template-copier-v2.1`'s `generate_slug` (or extracts it to a shared module)
- Returns the slug for a given description; exits non-zero with the same `[CWF] ERROR:` message if the slug is empty or exceeds `SLUG_MAX_LEN` (consistent with task-creation behaviour)
- Useful for skills/scripts that want to compute the slug for display or branch-name construction without committing to task creation

**Identified in**: Task 100 discovery (originally framed as deduplication of prose-described algorithm). Task 119 already collapsed the prose duplication and centralised the algorithm in `template-copier-v2.1`. Remaining motivation is preview-without-side-effect; lower priority than originally scoped.

---

## Task: Migrate Remaining `print STDERR + exit` Blocks in `template-copier-v2.1` to `die_msg`

**Task-Type**: chore
**Priority**: Low
**Status**: Follow-up from Task 119

Task 119 added a `die_msg` helper to `template-copier-v2.1` and used it for the new slug-length validation. The script's existing error paths (unknown args, missing required params, invalid format, config load failure, template-dir-not-found, broken symlinks, copy failures) still use the older `print STDERR "Error: ..."` + `exit N` pattern. Migrating these to `die_msg` would unify the error-prefix convention (`[CWF] ERROR:`) across the whole script.

**Scope**:
- Replace each `print STDERR "Error: ..." + exit N` block with `die_msg("...")`, preserving exit codes via a 2-arg form if needed
- Update tests if any assertion strings depend on the old format
- Refresh script hash

**Deferred from**: Task 119 (c-design-plan.md Decision 3 — boy-scout would have ballooned the diff)

---

## Task: Lift `die_msg` to a Shared `CWF::Common` Module

**Task-Type**: chore
**Priority**: Low
**Status**: Follow-up from Task 119

Both `cwf-manage` and `template-copier-v2.1` define identical `sub die_msg { print STDERR "[CWF] ERROR: @_\n"; exit 1; }` helpers. `CWF::Common` already exists (exports `parse_semver`, `version_cmp`) and is a natural home. Lifting `die_msg` deduplicates the helper and makes the `[CWF] ERROR:` prefix the single canonical convention.

**Scope**:
- Add `die_msg` (and matching unit tests) to `.cwf/lib/CWF/Common.pm`
- Update `cwf-manage` and `template-copier-v2.1` to `use CWF::Common qw(die_msg)` and remove their inline copies
- Refresh script hashes

**Deferred from**: Task 119 (out of scope per c-design-plan.md Decision 3; surfaced again in /simplify Code Reuse review)

---

## Task: Codify the `main() unless caller();` Testability Convention

**Task-Type**: chore
**Priority**: Low
**Status**: Follow-up from Task 119

Task 119's plan-review caught that `template-copier-v2.1`'s top-level execution dies on `do`-load (empty `@ARGV` hits the required-param check before tests can override `die_msg`). Solution: wrap top-level in `sub main { ... } main() unless caller();`. This is a recurring testability requirement for any helper script with bare top-level execution; should be documented as a CwF convention so future scripts adopt it from the start.

**Scope**:
- Document the convention in `docs/conventions/` (or similar) — explain the `do`-load failure mode, the `main() unless caller();` fix, and the `*main::die_msg` test-override pattern that depends on it
- Reference from the existing Tasks 115/116 test patterns

**Identified in**: Task 119 retrospective (Process Learning)

---

## Task: Add Settings.json Merge Helper Script (`cwf-settings-merge`)

**Task-Type**: feature
**Priority**: Medium

Extract the JSON settings merge logic from cwf-init into a helper script. Currently the agent reads `.claude/settings.json`, manually manipulates the JSON structure (adding permissions entries, hook configurations), and writes back. This is the most error-prone deterministic operation in the system — JSON escaping, key ordering, and idempotency logic done by hand.

**Scope**:
- Script takes `(key-path, value)` and performs idempotent merge into `.claude/settings.json`
- Handles nested keys (e.g. `hooks.PreToolUse`)
- Checks for existing entries to avoid duplicates
- Writes back valid JSON

**Identified in**: Task 100 discovery (rank 1.5, highest error-proneness score)

---

## Task: Replace cwf-extract Skill with Helper Script

**Task-Type**: feature
**Priority**: Low

The entire cwf-extract skill is deterministic end-to-end: input type detection (regex check for "/" or ".md"), section→file lookup (fixed mapping table), and content extraction (awk pattern). Could be replaced by a single helper script, making the skill a one-line wrapper.

**Scope**:
- Create `cwf-extract` helper script in `.cwf/scripts/command-helpers/`
- Implement input type detection, section→file mapping, awk extraction
- Reduce SKILL.md to a wrapper that calls the script

**Identified in**: Task 100 discovery (rank 2.0, only fully-deterministic skill)

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

<!-- Completed: "Create Design-Alignment Conventions Document" — Task 122 (2026-05-02) -->

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

<!-- Completed: "Add Path-Scoped Rules for Workflow File Protection" — Task 98 (2026-04-17) -->

<!-- Completed: "Add PreToolUse Hook for Rule Re-Injection" — Task 99 (2026-04-17) -->

---

<!-- Completed: "Research Stop Event Hooks for Correctness, Quality, and Efficiency" — Task 103 (2026-04-19) -->

<!-- Completed: "Consolidate Status Extraction to Single Canonical Module" — Task 105 (2026-04-19) -->

---

<!-- Completed: "Build Stale Status Detector Stop Hook" — Task 104 (2026-04-19) -->

---

## Bug: Progress Signal Scores Completed Tasks Highest in Task Context Inference

**Task-Type**: bugfix
**Priority**: Medium
**Status**: Backlog

The `_score_progress` function in `TaskContextInference.pm` uses a linear ramp (line 452: `int(($percentage / 100) * WEIGHT_PROGRESS_MAX)`) — a task at 100% gets score 60 (maximum), while a task at 10% gets score 6. This means **finished tasks dominate the progress signal**, which is backwards: a 100% task has no remaining work and shouldn't be a candidate for "current task."

**Observed**: After completing Task 103 and creating Task 104, `task-context-inference` returned "inconclusive" with both 103 and 104 as candidates. Task 103 (100%/Finished) scored higher on the progress signal than Task 104 (~10%/Backlog). The branch signal (weight 100) overrode it in the final result, but the progress signal contributed noise.

**Root cause**: Comment on line 409 says "bell curve, peak at 50%" but implementation is linear ramp. The scoring should either: (a) filter out 100% tasks entirely, (b) use a bell curve peaking at ~50% (actively being worked on), or (c) use an inverted ramp where low-progress tasks score higher (more work remaining = more likely current).

**Scope**:
- Fix `_score_progress` in `.cwf/lib/CWF/TaskContextInference.pm`
- Either filter out 100% tasks or use bell-curve scoring
- Update comment to match implementation
- Verify with mixed completed/in-progress task states

**Identified in**: Task 104 session — inference returned inconclusive when only one task had remaining work

---

<!-- Completed: "Build Uncommitted Changes Warning Stop Hook" — Task 113 (2026-04-25) -->

<!-- Completed: "Discover Best Gotchas for Skills Based on LMM Memory Analysis" — Task 107 (2026-04-21) -->
<!-- Produced 4 follow-up backlog items below -->

<!-- Completed: "Add Gotchas to cwf-retrospective Skill" — Task 109 (2026-04-21) -->

<!-- Completed: "Add Gotchas to cwf-implementation-exec Skill" — Task 117 (2026-04-29), with "rebrand" replaced by "rename or string substitution" after user prose review -->

<!-- Completed: "Add Gotchas to cwf-implementation-plan Skill" and "Add Gotchas to cwf-design-plan Skill" — Task 111 (2026-04-22), unified into shared "measure twice, cut once" gotcha -->

---

## Task: Research Compaction Failure Frequency via LMM Memory Analysis

**Task-Type**: discovery
**Priority**: Medium
**Status**: Backlog

Analyse conversation history via LMM memory MCP to determine how often compaction causes loss of critical CWF context, and whether custom compaction instructions in CLAUDE.md would mitigate it.

**Problem**: Best practices recommend adding compaction preservation instructions to CLAUDE.md (e.g., "When compacting, always preserve: current task number, current workflow phase, list of modified files, task branch name"). Before implementing, we need to know whether compaction-related context loss is actually a frequent problem in CWF usage.

**Approach**:
1. Query LMM for conversations where the agent lost track of task context mid-session
2. Look for patterns: agent asking "which task are we on?", re-reading files it already read, repeating completed work
3. Correlate with session length (longer sessions more likely to compact)
4. Assess frequency and impact
5. If frequent: recommend specific compaction instructions for CLAUDE.md
6. If rare: deprioritise

**Identified in**: Claude Code best practices analysis (2026-04-16)

---

## Task: Add Session Hygiene Guidance to CWF Documentation

**Task-Type**: chore
**Priority**: Medium
**Status**: Backlog

Add guidance on Claude Code session management to CWF documentation, helping users maintain effective context across workflow phases.

**Problem**: No guidance currently exists on when to clear context, when to continue sessions, or how to manage long-running CWF workflows. Best practices are clear: `/clear` between unrelated tasks, `/clear` after 2 failed corrections on the same issue, continue when deep in one problem or during iterative refinement.

**Scope**:
- Add session hygiene section to `.cwf/docs/workflow/` or CLAUDE.md
- Document when to `/clear` (between tasks, after repeated corrections)
- Document when to continue (mid-phase, iterative refinement)
- Document `/compact` with CWF-specific preservation instructions
- Installed documentation only — no code changes

**Identified in**: Claude Code best practices analysis (2026-04-16)

---

## Task: Replace Backtick Operators with IPC::Open3 in cwf-manage

**Task-Type**: chore
**Priority**: Very Low

Replace backtick operators in `.cwf/scripts/cwf-manage` with `IPC::Open3` calls to satisfy perlcritic severity 3 (harsh). `IPC::Open3` is core since Perl 5.000. Currently 5 backtick usages for simple `git` commands — functional and readable as-is, but not PBP-compliant at level 3.

**Scope**:
- Replace backticks in `find_git_root()`, `resolve_ref()`, `resolve_sha()`, `cmd_list_releases()`
- Consider also adding `/x` flag to simple regexes (8 hits) and converting the if-elsif dispatch to a hash table (1 hit) for full level 3 compliance

**Identified in**: Task 61 (perlcritic --harsh on cwf-manage)

---

## Task: Add Conflict-State Regression Test for stop-uncommitted-changes-warning

**Task-Type**: chore
**Priority**: Low
**Status**: Follow-up from Task 113

Add a small regression test that exercises the `stop-uncommitted-changes-warning` hook against synthetic git porcelain output containing conflict-state records (`UU`, `AA`, `DD`). Currently the parser is verified by code inspection only — the live TC-8 test was deferred during Task 113 because reproducing a real merge conflict on a wf file is brittle.

**Problem**: The hook's parsing path (`substr($_, 3)`) is identical for every porcelain status code, so conflict records *should* parse correctly. But this is unverified end-to-end. If git ever changes the porcelain format for conflicts (e.g. emits two paths separated by NUL, like renames), the hook would silently misreport.

**Scope**:
- Add a test that feeds synthetic porcelain output into a parsing helper, or stages a real `UU` record via `git update-index --cacheinfo` against a stub blob
- Cover `UU`, `AA`, `DD`, and at least one rename (`R`) to round out porcelain-class coverage
- Wire into `prove` if there's an existing test harness, otherwise document as a manual one-liner

**Identified in**: Task 113 g-testing-exec (TC-8 deferred as stretch)

## Task: Skill Cross-Reference Linter for SKILL.md / *-extras.md Step Numbers

**Task-Type**: chore
**Priority**: Low
**Status**: Follow-up from Task 114

`*/SKILL.md` files numbered step lists (Step 1, Step 2, ...). Their companion `.cwf/docs/skills/*-extras.md` files mirror those numbers in section headings (e.g. "## CHANGELOG.md and BACKLOG.md Update (Step 8)"). When a SKILL.md is renumbered, the extras file silently drifts. Task 114 introduced two new steps in `cwf-retrospective/SKILL.md` (Step 9 bump, Step 11 tag), bumping squash from 9→10 and merge-suggestion from 10→12. The drift in `retrospective-extras.md` was only caught by actually running the retrospective skill in Task 114's own j-phase — and fixed in-task.

**Problem**: There's no static check that SKILL.md step numbers match their extras-file labels. The d-implementation-plan Step 9 grep audit only looks for cross-references *to* the skill from outside; it doesn't catch internal docs that mirror the numbering.

**Scope**:
- Small Perl helper, e.g. `.cwf/scripts/command-helpers/cwf-validate-skill-refs`
- Given each SKILL.md, parse out its `**Step N**:` headings; given the corresponding extras file, parse `## ... (Step N)` and `### N.X` labels; warn on any mismatch
- Wire into `cwf-manage validate` as a soft check (warn, not fail) initially
- One subtest per SKILL/extras pair in a new `t/skill-refs.t`

**Rationale**: Caught by dog-fooding in Task 114. The fix is mechanical; the linter prevents recurrence and surfaces the issue before the next renumbering.

**Identified in**: Task 114 j-retrospective.md

## Task: Lighter-Weight Rollout/Maintenance Templates for Internal/Developer-Tool Tasks

**Task-Type**: chore
**Priority**: Medium
**Status**: Follow-up from Task 114 (and reinforces existing backlog item)

Both `h-rollout.md` and `i-maintenance.md` ship with full enterprise templates (blue-green/canary, SLAs, monitoring, alerting, scaling). For developer-tool changes (which is most CwF self-development), these templates are 80% boilerplate that gets manually marked "not applicable". Task 114 wrote both phases as essentially custom freeform documents because the template didn't fit.

**Note**: An existing BACKLOG item ("Lightweight Rollout/Maintenance Templates for Internal Tasks") covers this. Task 114 is corroborating evidence — bumping its priority would be reasonable.

**Identified in**: Task 114 h-rollout.md and i-maintenance.md (both Lessons Learned sections)

## Task: Resolve cwf-project.json version drift vs .cwf/version

**Task-Type**: discovery
**Priority**: Medium
**Status**: Follow-up from external user upgrade (v1.0.95 → v1.0.114)

After `cwf-manage update`, `.cwf/version` was bumped to `v1.0.114` but `cwf-project.json` still recorded `"version": "v1.0.95"`. The external user deferred reconciling this on the basis that "`.cwf/version` is authoritative" — but it's unclear whether that's the design or just current behaviour.

**Problem**: Two files claim to record the installed CWF version. Either one is authoritative and the other is vestigial, or both are intentional and should stay in sync. Either way, `cwf-manage update` shouldn't leave them inconsistent.

**Discovery questions**:
- What is `cwf-project.json`'s `version` field meant to record? (installed CWF version, project schema version, last-init version, something else?)
- Is `.cwf/version` the authoritative installed-version source? If yes, why does `cwf-project.json` also carry a version?
- What reads each field today? (grep callers; any drift may already be silently broken)

**Resolution paths** (pick one in design phase):
- **A**: `.cwf/version` is sole authority — drop `version` from `cwf-project.json`, migrate any callers
- **B**: Both fields are intentional — `cwf-manage update` writes both; add a validate check for drift
- **C**: `cwf-project.json` records something distinct (e.g. project-schema version, init version) — rename the field to remove ambiguity

**Identified in**: External user upgrade report, 2026-04-26

## Task: Consider parent-agent inline tool-selection rubric

**Task-Type**: discovery
**Priority**: Low
**Status**: Follow-up from Task 118 retrospective

Task 118 added a tool-selection rubric for CWF subagents (canonical doc + brief inline excerpt in the plan-review prompt). The same anti-patterns (`sed -n 'X,Yp'`, `cat | grep`, `find … -exec cat`) apply when the *parent* Claude Code agent reaches for them — and Task 118's empirical observation that subagents ignore soft prompt restrictions is plausibly the same for the parent agent reading CLAUDE.md.

**Discovery questions**:
- Does the parent agent already comply with the rubric? Pull a recent transcript and check.
- The harness's system prompt already says "Read files: Use Read (NOT cat/head/tail)" — is that catching the cases Task 118's anti-patterns name, or are there gaps the canonical doc covers that the system prompt doesn't?
- If a gap exists: is the right place to address it CLAUDE.md (project-scoped), `~/.claude/CLAUDE.md` (user-scoped), or a CWF skill that can install the guidance into either?

**Resolution paths** (pick in design phase):
- **A**: No gap — close the discovery; convention doc remains subagent-scoped
- **B**: Gap exists, scope is project-specific — add a one-line reference to `.cwf/docs/conventions/subagent-tool-selection.md` from the project's CLAUDE.md
- **C**: Gap exists, scope is user-wide — add a CWF install-time hook that writes a tool-selection block into `~/.claude/CLAUDE.md` (with user opt-in)

**Identified in**: Task 118 j-retrospective.md (Future Work)

