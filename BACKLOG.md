# CWF System Backlog

Future tasks and improvements for the Coding with Files system.

## Task: Tighten AC4-style grep gates to "metadata position only"

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 132
### Identified in: Task 132 g-testing-exec.md and j-retrospective.md

Task 132 used a file-wide `grep -cE '^\*\*[A-Z][\w\- ]*\*\*:' BACKLOG.md CHANGELOG.md` as one of two AC4 gates ("legacy `**Field**:` metadata is gone"). After migration the grep returns 3 + 134 hits — *all in body content* (e.g. `**Create**:` followed by a bullet list). Validators correctly do not classify these as metadata, and the semantic gate (`backlog-manager validate` clean + round-trip byte-identical) holds. The grep is a coarse syntactic proxy. Replace with either (a) a parser-driven gate that walks the tree and asserts no metadata-position `**Field**:` survived, or (b) a tighter regex that only matches the first non-blank lines after a `## ` heading. (a) is the cleaner option since the parser already exists. Optional — there is no functional gap.

## Task: Lift backlog-manager test scaffolding to `CWFTest::Fixtures`

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 132
### Identified in: Task 132 `/simplify` deferred work

`t/backlog-tree-parse.t`, `t/backlog-tree-validate.t`, `t/backlog-tree-mutators.t`, `t/backlog-roundtrip-live.t` all duplicate the same `write_tmp` / `parse_and_validate_*` / `has_rule` / `get_rule` helpers. Lift these into `t/lib/CWFTest/Fixtures.pm` (or extend the existing test-support module if one is added later). Cost is small; payoff is single-source-of-truth for the most reused test idiom. Deferred from Task 132's `/simplify` pass because it's wider scope than the simplify pass warranted.

## Task: Adopt CWF::Options for backlog-manager argument parsing

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 132
### Identified in: Task 132 `/simplify` deferred work

`backlog-manager` rolls its own `parse_args` because no existing helper handles the "unbounded `--key=value`" argument shape it needs. Either (a) extend `CWF::Options` (or whichever the canonical options module is) to support the unbounded shape, or (b) document that `backlog-manager`'s arg parser is the canonical pattern for "unbounded options" and lift it back into the shared module for any other helper that needs the same shape. (b) is more conservative; (a) is cleaner long-term.

## Task: Collapse parse_backlog_tree/parse_changelog_tree into single parse_tree($path, $kind)

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 132
### Identified in: Task 132 `/simplify` deferred work

`CWF::Backlog` exports `parse_backlog_tree` and `parse_changelog_tree` as two-line wrappers over `_parse_path($_[0], $kind)`. Collapsing to a single `parse_tree($path, $kind)` (with `$kind` being a public enum string `'backlog'` or `'changelog'`) would shrink the surface and make the kind explicit at call sites. Touches public API — needs a deprecation pass or a major version bump. Deferred from Task 132's `/simplify` because changing exported surface was wider scope than warranted at simplify time.

## Task: Backfill **Baseline Commit** field in in-flight tasks' a-task-plan.md

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 129
### Identified in: Task 129 retrospective (j-retrospective.md)

Tasks created before Task 129 landed have no `**Baseline Commit**:` line in their `a-task-plan.md`. The `security-review-changeset` helper falls back to `git merge-base HEAD <trunk>` for these, which preserves Task 129's no-regression promise but does not give them the per-task-baseline benefit. A one-line backfill helper (or a manual edit per task) would normalise the corpus. Optional — there is no functional gap.

## Task: Extend security-review-changeset shebang interpreter regex

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 129
### Identified in: Task 129 retrospective (j-retrospective.md)

The v1 anchored interpreter regex covers `perl|bash|sh|ksh|zsh|fish|python\d?|ruby|node|deno|php|lua|pwsh|powershell` — >95% of in-the-wild interpreters. Files with `awk`, `tcl`, `make`, `gawk`, or version-pinned interpreters (e.g. `python3.11`) are missed. Focused extension; preserve the `^…$` anchoring invariant.

## Task: Adopt `File::chdir` for test scaffolds that change directory

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 129
### Identified in: Task 129 retrospective (j-retrospective.md)

`t/security-review-changeset.t` (and likely others) uses `chdir $repo` ... `chdir $orig` to scope subprocess invocations. If a test `die`s between the two, `chdir $orig` never runs, leaking cwd state into subsequent tests. Use `local $CWD` from `File::chdir` for exception-safe lexical scoping. Not currently broken (tests die fast, tempdirs auto-clean), but a worth-it refactor as the test scaffolding grows.

## Task: Tighten security-subagent prompt for sentinel-line compliance

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 123
### Problem: Subagents respond with verbose intros even when instructed otherwise. The current prompt says "Start your response with one of three sentinel lines" but the model does not reliably comply.
### Solution: One-line edit to `.cwf/docs/skills/security-review.md` § "Exec-phase prompt template" to push the sentinel ahead of any analysis. Suggested wording: "Your VERY FIRST output line MUST be the sentinel — do not preface with analysis." Optionally consider one-token sentinels (`NO_FINDINGS:`, `FINDINGS:`, `ERROR:`) which are harder to embed mid-paragraph.
### Trigger: Defer until the classifier-versus-substance gap recurs in >2 of the next 5 feature tasks. If the rate stays acceptable, no action needed — the conservative classifier is doing its job.
### Identified in: Task 123 retrospective (j-retrospective.md § "What Could Be Improved")

The security subagent introduced in Task 123 returns three sentinel-prefixed states (`findings:` / `no findings` / `error:`) classified per a three-tier rule (primary sentinel → numbered-list fallback → conservative-default error). TC-AC8 in Task 123 demonstrated that subagents tend not to lead with the sentinel — the dogfood call returned ~70 lines of analysis before the closing `no findings` line, causing the fallback classifier to fire and produce a `**State**: findings` even though the substantive verdict was clean. The conservative-default behaviour is correct (loud false positive > silent false negative), but the false-positive rate could be reduced.

## Task: Quantitatively justify the security-review subagent line-count cap

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 127
### Approach: 
### Out of scope: changing the subagent prompt itself (covered by the existing "Tighten security-subagent prompt for sentinel-line compliance" follow-up). This task is purely about the threshold value.
### Identified in: Task 127 retrospective (j-retrospective.md § "What Could Be Improved")

The current 500-line cap on security-review subagent invocations (set in Task 123, applied across `.cwf/docs/skills/security-review.md` and the exec-phase skills) is qualitatively justified — large changesets exceed the subagent's effective review window — but no empirical evidence backs the specific value of 500 vs 250 vs 1000. Task 127's changeset (2166 lines) blew through the cap and required a manual approval workflow; the user explicitly flagged the threshold's lack of quantitative basis.

1. Pick 5-10 representative changesets from CWF history at varying sizes (250, 500, 1000, 2000 lines).
2. Run the security-review subagent on each; record finding-rate, false-positive-rate, runtime, and the subagent's own self-reported coverage assessment.
3. Plot finding-rate-per-line and runtime against changeset size; identify the inflection point where review quality starts to degrade.
4. Set the cap from data, not vibes. Document the methodology in `.cwf/docs/skills/security-review.md` so future revisions have a baseline.

## Task: Add fixture-server harness for end-to-end cwf-manage update tests

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 127
### Approach: 
### Out of scope: SIGKILL-during-rename atomicity (covered architecturally by same-dir-temp + rename), interactive D/A prompt branches (need expect-style harness — separate task if ever needed).
### Identified in: Task 127 retrospective (j-retrospective.md § "Recommendations § Future Work")

Task 127's testing covers `cwf-apply-artefacts` at the helper level and `cwf-manage update` at the helper-sub level (lock acquisition, manifest SHA validation, path-traversal). What's missing is a true end-to-end test that exercises the full clone+subtree-pull flow — TC-INT-AC1 in Task 127's test plan was marked PARTIAL for this reason. Closing the gap requires a fixture remote (a local git repo serving as upstream) and a multi-commit fixture history so subtree pulls have something meaningful to pull.

1. Build a `t/fixtures/upstream-server/` skeleton: bare git repo, scripted commit history (3-5 commits with realistic CWF-shaped diffs).
2. Add `t/cwf-manage-update-end-to-end.t`: clones fixture upstream → runs `cwf-manage init` → modifies fixture → runs `cwf-manage update` → asserts artefacts updated, manifest-SHA pinned, lock released.
3. Cover the regression cases not currently covered: subtree-pull conflict, manifest schema bump (when v2 exists), upstream rollback (downgrade scenario).

## Task: Reconcile cwf-manage update and fix-security chmod logic

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 120
### Scope: 
### Identified in: Task 120 retrospective (j-retrospective.md, "Future Work")

`cwf-manage update` (line 350) does a blanket `chmod 0755` over `.cwf/scripts/`. `cwf-manage fix-security` (Task 120) chmods to *exact* recorded perms (e.g. `0500`/`0700`/`0755`) per `script-hashes.json`. Both pass validate, but they produce different end states. Worth reconciling so update and fix-security converge — most likely option: have `update` call `fix-security` after the copy step, removing the bespoke `chmod 0755` from the update path.

- Replace the blanket chmod in `cmd_update` with a `cmd_fix_security` call (or extract the per-entry chmod logic into a shared sub)
- Confirm the integration test for `update` (if any) still passes
- Refresh `cwf-manage` hash after the change

## Task: Add --dry-run flag to cwf-manage fix-security

### Task-Type: feature
### Priority: Low
### Status: Follow-up from Task 120
### Scope: 
### Identified in: Task 120 retrospective (j-retrospective.md, "Future Work")

`fix-security` currently has no preview mode. A `--dry-run` flag would print the chmod actions it *would* take and the unfixable entries it *would* surface, without mutating the filesystem. Useful for security-conscious users auditing the install before a repair.

- Add `--dry-run` argument parsing in `cmd_fix_security`
- Skip the `chmod` call when in dry-run mode; preface fix lines with `[dry-run]`
- Add a test case to `t/cwf-manage-fix-security.t` that asserts no fs mutation in dry-run mode
- Update help text and SKILL.md if appropriate

## Task: Standardise Placeholder Syntax in Remaining CLI Docs

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 88
### Scope: 
### Identified in: Task 88 retrospective (j-retrospective.md)

`workflow-preamble.md` and `decomposition-guide.md` use `<var>` syntax in CLI argument
documentation (showing command syntax, not model-substitution targets). Task 88 established
the convention: `{}` = "substitute this value", `<>` = reserved for HTML/XML/email.
These files should be audited and any model-substitution `<var>` instances converted to
`{var}`. Pure CLI syntax examples (e.g. `cmd <arg>`) should be reviewed to determine
whether a deliberate style-guide entry would be clearer.

- Audit `.cwf/docs/skills/workflow-preamble.md` for `<var>` instances
- Audit `.cwf/docs/workflow/decomposition-guide.md` for `<var>` instances
- Convert model-substitution uses to `{}`; decide on CLI syntax documentation style
- Add a one-liner to the style guide (or glossary) clarifying the distinction

## Task: Add Delete Task Skill

### Task-Type: feature
### Priority: High
### Scope: 
### Identified in: Task 59 (misclassified as chore, needed manual delete/recreate)

Add a `/cwf-delete-task <num>` skill that cleanly removes a task: deletes the task directory, removes the git branch (if it exists), and optionally cleans the task stack. Currently, deleting a misclassified or abandoned task requires manual `git rm -r`, branch deletion, and directory cleanup — error-prone and tedious.

- Delete task directory under `implementation-guide/`
- Delete associated git branch (with confirmation)
- Remove from task stack if present
- Refuse to delete if task has subtasks (safety check)
- Support `--force` flag to skip confirmation

## Task: Infer Task Type When Not Specified in new-task and subtask Skills

### Task-Type: feature
### Priority: Medium
### Inference guidance: Consider whether requirements/design phases are needed (feature), whether this fixes a defect (bugfix/hotfix), whether it's mechanical with no ambiguity (chore), or whether it's exploratory (discovery).
### Identified in: Task 59 (agent chose chore for a task with unclear requirements, required delete/recreate as feature)

When `/cwf-new-task` or `/cwf-new-subtask` is invoked without a task type, the agent should infer the appropriate type based on the task description and complexity rather than failing with a validation error. If the inference is ambiguous, ask the user to choose. This prevents misclassification — e.g., a task with unclear requirements being created as a chore (no design phase) when it should be a feature.

## Task: Add Slug Generation Helper Script (`cwf-slug`)

### Task-Type: feature
### Priority: Low (downgraded post-Task-119)
### Scope: 
### Identified in: Task 100 discovery (originally framed as deduplication of prose-described algorithm). Task 119 already collapsed the prose duplication and centralised the algorithm in `template-copier-v2.1`. Remaining motivation is preview-without-side-effect; lower priority than originally scoped.

Expose `generate_slug` from `template-copier-v2.1` as a standalone helper so callers can preview the slug a description will produce before invoking task creation.

- Script wraps `template-copier-v2.1`'s `generate_slug` (or extracts it to a shared module)
- Returns the slug for a given description; exits non-zero with the same `[CWF] ERROR:` message if the slug is empty or exceeds `SLUG_MAX_LEN` (consistent with task-creation behaviour)
- Useful for skills/scripts that want to compute the slug for display or branch-name construction without committing to task creation

## Task: Migrate Remaining `print STDERR + exit` Blocks in `template-copier-v2.1` to `die_msg`

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 119
### Scope: 
### Deferred from: Task 119 (c-design-plan.md Decision 3 — boy-scout would have ballooned the diff)

Task 119 added a `die_msg` helper to `template-copier-v2.1` and used it for the new slug-length validation. The script's existing error paths (unknown args, missing required params, invalid format, config load failure, template-dir-not-found, broken symlinks, copy failures) still use the older `print STDERR "Error: ..."` + `exit N` pattern. Migrating these to `die_msg` would unify the error-prefix convention (`[CWF] ERROR:`) across the whole script.

- Replace each `print STDERR "Error: ..." + exit N` block with `die_msg("...")`, preserving exit codes via a 2-arg form if needed
- Update tests if any assertion strings depend on the old format
- Refresh script hash

## Task: Lift `die_msg` to a Shared `CWF::Common` Module

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 119
### Scope: 
### Deferred from: Task 119 (out of scope per c-design-plan.md Decision 3; surfaced again in /simplify Code Reuse review)

Both `cwf-manage` and `template-copier-v2.1` define identical `sub die_msg { print STDERR "[CWF] ERROR: @_\n"; exit 1; }` helpers. `CWF::Common` already exists (exports `parse_semver`, `version_cmp`) and is a natural home. Lifting `die_msg` deduplicates the helper and makes the `[CWF] ERROR:` prefix the single canonical convention.

- Add `die_msg` (and matching unit tests) to `.cwf/lib/CWF/Common.pm`
- Update `cwf-manage` and `template-copier-v2.1` to `use CWF::Common qw(die_msg)` and remove their inline copies
- Refresh script hashes

## Task: Codify the `main() unless caller();` Testability Convention

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 119
### Scope: 
### Identified in: Task 119 retrospective (Process Learning)

Task 119's plan-review caught that `template-copier-v2.1`'s top-level execution dies on `do`-load (empty `@ARGV` hits the required-param check before tests can override `die_msg`). Solution: wrap top-level in `sub main { ... } main() unless caller();`. This is a recurring testability requirement for any helper script with bare top-level execution; should be documented as a CwF convention so future scripts adopt it from the start.

- Document the convention in `docs/conventions/` (or similar) — explain the `do`-load failure mode, the `main() unless caller();` fix, and the `*main::die_msg` test-override pattern that depends on it
- Reference from the existing Tasks 115/116 test patterns

## Task: Replace cwf-extract Skill with Helper Script

### Task-Type: feature
### Priority: Low
### Scope: 
### Identified in: Task 100 discovery (rank 2.0, only fully-deterministic skill)

The entire cwf-extract skill is deterministic end-to-end: input type detection (regex check for "/" or ".md"), section→file lookup (fixed mapping table), and content extraction (awk pattern). Could be replaced by a single helper script, making the skill a one-line wrapper.

- Create `cwf-extract` helper script in `.cwf/scripts/command-helpers/`
- Implement input type detection, section→file mapping, awk extraction
- Reduce SKILL.md to a wrapper that calls the script

## Task: Lightweight Rollout/Maintenance Templates for Internal/Developer-Tool Tasks

### Task-Type: chore
### Priority: Medium
### Status: Follow-up from Task 57; reinforced by Task 114
### Scope: 
### Identified in: Task 57 retrospective (j-retrospective.md — i-maintenance.md lessons learned); Task 114 h-rollout.md and i-maintenance.md (both Lessons Learned sections); coalesced from a duplicate entry in Task 130 (2026-05-07)

Both `h-rollout.md` and `i-maintenance.md` ship with full enterprise templates (blue-green/canary, SLAs, monitoring, alerting, scaling). For internal tooling and developer-tool changes — which is most CwF self-development — these templates are 80% boilerplate that gets manually marked "not applicable". Task 114 wrote both phases as essentially custom freeform documents because the template didn't fit; Task 57 also flagged this in i-maintenance lessons learned.

- Create "internal" variants of h-rollout.md and i-maintenance.md templates
- Reduce to relevant sections (deployment strategy, known issues, architecture reference)
- Template selection during `/cwf-new-task` based on project type or explicit flag

## Task: Document Dead Code Audit Methodology

### Task-Type: chore
### Priority: Medium
### Status: Follow-up from Task 51
### Problem: Task 51 audit incorrectly flagged `workflow_file_mappings()` and `format_error()` as dead code, missing same-file usage and script-to-library usage patterns. Errors caught during pre-removal verification, but audit methodology needs improvement.
### Solution: Create standardized dead code audit checklist:
### Scope: Create single documentation file with checklist and examples
### Rationale: Standardized methodology reduces audit errors, prevents breaking changes, improves cleanup confidence
### Identified in: Task 51 retrospective (j-retrospective.md - "Recommendations")

Create `.cwf/docs/maintenance/dead-code-audit-checklist.md` documenting comprehensive audit methodology to prevent missing active usage patterns.


- **Cross-file usage**: `grep -r "function_name" .cwf/lib/ .cwf/scripts/`
- **Same-file usage**: Check within each affected file for internal calls
- **Script-to-library usage**: `grep -r "function_name" .cwf/scripts/command-helpers/`
- **POD documentation**: Check for public API declarations (`=head2 function_name`)
- **Structured report format**: Function, file, lines, usage findings, verdict

## Task: Comprehensive Dead Code Audit for CWF Library Modules

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 51
### Problem: Task 51 only addressed functions already identified as dead. Remaining library modules may have additional cleanup opportunities not yet discovered.
### Solution: Systematic audit of all library modules:
### Scope: Audit only, do not remove code. Create follow-up tasks for actual removal.
### Dependencies: Requires "Document Dead Code Audit Methodology" task completed first
### Rationale: Proactive cleanup improves maintainability, reduces confusion, keeps codebase lean
### Identified in: Task 51 retrospective (j-retrospective.md - "Future Work")

Run comprehensive dead code audit across all `.cwf/lib/*.pm` files using improved methodology from dead code audit documentation.


- Apply documented audit methodology to each .pm file
- Generate structured audit reports for each module
- Create follow-up task(s) for confirmed dead code removal
- Consider using Perl::Critic or static analysis tools

## Task: Create Perl Idioms Documentation

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 50
### Problem: Task 50 implementation initially used non-idiomatic patterns (`grep { defined($_) }` instead of `grep defined`, if/else blocks instead of ternary conditionals). User review during planning phase caught and corrected these, but patterns should be documented for consistency across all CWF scripts.
### Solution: Create perl-idioms.md with sections:
### Scope: Documentation only, no code changes
### Rationale: Consistent idiomatic code improves readability, maintainability, reduces cognitive load
### Identified in: Task 50 retrospective (j-retrospective.md - "Recommendations")

Create `.cwf/docs/conventions/perl-idioms.md` documenting common idiomatic Perl patterns for CWF scripts.


- **Filtering**: `grep defined` vs `grep { defined($_) }`, `map` patterns
- **Conditionals**: Ternary operators vs if/else blocks, postfix conditionals
- **String operations**: `s///` substitution, `=~` vs `!~`
- **File operations**: Three-arg open, lexical filehandles
- **Error handling**: `die` with context, `or die` idiom
- **References**: When to use, dereferencing patterns

## Task: Add "Skipped-If" Conditional Logic to Workflow System

### Task-Type: feature
### Priority: Low
### Status: Follow-up from Task 50
### Problem: Task 50 added "Skipped" status for marking phases N/A, but developers must manually set status for each task. For task types with predictable phase applicability (bugfixes never need maintenance, hotfixes skip rollout), conditional logic would eliminate manual work.
### Solution: Add `"phase-applicability"` section to cwf-project.json:
### Scope: 
### Rationale: Eliminates manual work, reduces errors, codifies workflow conventions
### Identified in: Task 50 retrospective (j-retrospective.md - "Recommendations")

Allow task types to conditionally skip workflow phases based on type (e.g., bugfixes always skip i-maintenance.md).


```json
"phase-applicability": {
  "feature": ["a","b","c","d","e","f","g","h","i","j"],
  "bugfix": ["a","b","c","d","e","f","g","j"],  // skip h-rollout, i-maintenance
  "hotfix": ["a","d","f","g","j"],  // skip b,c,e,h,i
  "chore": ["a","d","f","g","j"]  // skip b,c,e,h,i
}
```
Template-copier automatically marks non-applicable phases as "Skipped" during task creation.

- Update cwf-project.json schema
- Modify template-copier to set "Status: Skipped" for non-applicable phases
- Update workflow-steps.md with phase applicability by task type

## Task: Create Integration Test for Inconclusive Inference Scenarios

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 37
### Scope: 
### Identified in: Task 37 retrospective (j-retrospective.md)

Create integration test harness that manipulates git state to produce real signal conflicts, enabling testing of inconclusive inference scenarios.

- Create test script that sets up controlled signal conflicts
- Test branch signal vs recency signal conflict
- Test all three signals disagreeing
- Test no signals scenario (empty repository)
- Validate real TaskContextInference output matches expectations

## Task: Document Bugfix Workflow Differences

### Task-Type: chore
### Priority: Low
### Status: Identified from Task 36 retrospective
### Problem: Task 36 attempted to use `/cwf-rollout` but bugfix template doesn't include h-rollout.md, causing confusion about rollout phase.
### Solution: Add explicit documentation about workflow type differences.
### Scope: 
### Success Criteria: 
### Rationale: Reduces confusion about missing workflow phases based on task type.
### Discovered: Task 36 retrospective - bugfix workflow doesn't include h-rollout.md

Clarify that bugfix workflows skip h-rollout.md and use checkpoint commits for rollout instead.



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

- [ ] Comparison table shows phase inclusion by workflow type
- [ ] Documentation explains rollout alternatives for bugfix/chore
- [ ] Future tasks understand which phases apply to their type

## Task: Create Verification Test Pattern Templates

### Task-Type: chore
### Priority: Low
### Status: Identified from Task 36 retrospective
### Problem: Task 36 used grep/diff verification effectively for 17-file update. This pattern is reusable but not documented.
### Solution: Create verification pattern templates in documentation.
### Scope: 
### Success Criteria: 
### Rationale: Codifies effective verification approach from Task 36 for reuse.
### Discovered: Task 36 retrospective - grep/diff verification proved effective

Create reusable grep/diff verification patterns for multi-file update tasks.



1. **Create `docs/patterns/verification-tests.md`**:
   - Grep count pattern: `grep -l "PATTERN" files/* | wc -l`
   - Diff statistics: `git diff --stat`
   - Insertion consistency: Check all files show same line count
2. **Add examples**: Multi-file updates, consistent snippets, completeness checks

- [ ] Verification patterns documented with examples
- [ ] Future multi-file tasks reference patterns
- [ ] Verification approach consistent across tasks

## Task: Add Material Changes Review to Phase Commit Checklists

### Task-Type: chore
### Priority: Medium
### Status: Identified from Task 35 retrospective
### Problem: Task 35 experienced repeated oversight where actual command file changes (the core deliverables) were not committed at multiple checkpoints:
### Solution: Add explicit commit review step to each workflow phase documentation.
### Scope: 
### Success Criteria: 
### Rationale: Prevents repeated oversight pattern where documentation gets committed but actual code/config changes are forgotten. Explicit checklist reduces cognitive load and provides systematic review process.
### Discovered: Task 35 retrospective - command files not committed at any checkpoint despite being the core deliverable

Add explicit commit checklist step to workflow documentation and templates to prevent oversight of committing actual deliverables.

- Implementation-exec phase (checkpoint commit)
- Rollout phase
- Retrospective phase

Root cause: Exclusive focus on implementation-guide/ documentation files caused deliverables in other directories (.claude/, .cwf/, etc.) to be overlooked.


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

- [ ] Workflow documentation includes commit review guidance
- [ ] All execution templates have commit checklist section
- [ ] Checklist explicitly mentions reviewing files outside implementation-guide/
- [ ] Future tasks less likely to miss committing core deliverables

## Task: Add Baseline Verification Step to Implementation Planning Templates

### Task-Type: chore
### Priority: Low
### Status: Identified from Task 35 retrospective
### Problem: Task 35 estimated 35 historical references but actual count was 52. Baseline was established incorrectly, causing mid-stream test criteria adjustment during testing phase.
### Solution: Update d-implementation-plan.md template to include baseline verification section.
### Scope: 
### Success Criteria: 
### Rationale: Pre-execution baseline verification prevents mid-stream test criteria adjustments and ensures test cases are accurate from the start.
### Discovered: Task 35 retrospective - baseline of 35 references was inaccurate, actual was 52

Add explicit baseline verification step to implementation planning phase for tasks involving counts, metrics, or quantitative validation.



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

- [ ] Template includes baseline verification section
- [ ] Section is conditional ("if applicable")
- [ ] Provides clear example for count-based tasks
- [ ] Future tasks establish accurate baselines before implementation

## Task: Add Security Verification to Testing Workflow

### Task-Type: chore
### Priority: Medium
### Status: Identified during Task 32 security verification
### Problem: Task 32 modified 8 helper scripts and added 2 libraries, but security hash verification wasn't performed until after retrospective. Security verification should be part of the testing phase to catch hash mismatches early.
### Solution: Update testing workflow documentation and templates to include security verification step.
### Scope: 
### Benefits: 
### Success Criteria: 
### Rationale: Security verification is currently ad-hoc. Integrating it into the testing workflow ensures it's performed consistently for all tasks that modify security-sensitive files.
### Related: Task 32 (discovered during post-retrospective security check)

Add instruction to include security integrity checks as a standard part of the testing workflow (g-testing-exec) for all tasks that modify helper scripts or libraries.




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

- Catches hash mismatches early (during testing, not post-retrospective)
- Makes security verification a standard practice, not an afterthought
- Documents when and how to perform security checks

- [ ] workflow-steps.md includes security verification guidance
- [ ] g-testing-exec.md.template includes security checklist item
- [ ] e-testing-plan.md.template includes security test case
- [ ] Future tasks that modify scripts will include security verification in testing phase

## Task: Test Edge Cases for Task Context Inference System

### Task-Type: chore
### Priority: Low
### Status: Deferred from Task 32 testing execution
### Background: Task 32 implemented a signal-based inference system that automatically detects the current task and workflow step from environmental signals (git branch, worktree, state file, recency, progress). During testing execution (g-testing-exec.md), 42/45 tests passed (93%) with zero failures. Three edge case tests were deferred because they require test environments that would break the current task context or create artificial conflicting state.
### Deferred Test Cases: 
### Test Requirements: 
### Scope: 
### Out of Scope: 
### Success Criteria: 
### Rationale: These edge case tests validate inference behavior in atypical scenarios. While the primary use case (developer working on feature branch with active task) is fully validated and production-ready, these edge cases ensure graceful degradation when signals are missing or conflicting. Testing was deferred from Task 32 because creating the test environments would break the current task context, but they should be validated in a controlled test environment to ensure robustness.
### Estimated Effort: 2-4 hours (environment setup, test execution, documentation)
### Priority: Low because:
### Related: Task 32 (feature-task-tracking-using-inference-scoring) - implementation and testing complete except for these three edge cases

Execute three edge case tests for the task context inference system (Task 32) that were deferred due to requiring special test environments.



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

- Fixing issues found (this is testing only, not bug fixes)
- Modifying inference algorithm based on findings
- Adding new test cases beyond these three

- [ ] Isolated test environment created without disrupting main work
- [ ] TC-I3 executed with documented results (PASS/FAIL)
- [ ] TC-I4 executed with documented results (PASS/FAIL)
- [ ] TC-S2 executed with documented results (PASS/FAIL)
- [ ] Task 32 g-testing-exec.md updated with results
- [ ] Original environment restored after testing
- [ ] Any bugs discovered documented (separate BACKLOG items if fixes needed)



- Primary use case (correlated signals) is fully validated
- These are edge cases with low likelihood in normal usage
- System is production-ready without these tests
- No known bugs in these scenarios (just untested)

## Task: Create Template Reference Linter for Pre-Commit Hook

### Task-Type: chore
### Priority: Medium
### Status: Recommended from Task 29 retrospective
### Problem: Template filename references must be updated manually across codebase:
### Solution: Create `template-reference-linter` script:
### Benefits: 
### Implementation: 
### Estimated Effort: 0.5-1 day

Create automated linter to detect hardcoded template filename references and verify they point to current template names.

- No automated way to detect orphaned template filename references
- Manual grep required for verification (e.g., Task 29 found 60+ references)
- Risk of missing references during template changes
- Version-specific references (v2.0 vs v2.1) need distinction

- Detect hardcoded template filenames in `.md`, `.pl`, `.pm` files
- Verify references point to current template names (not deprecated)
- Distinguish v2.0 refs (acceptable in V20.pm) from v2.1 refs (should use new names)
- Run as pre-commit hook or CI check
- Report orphaned references with file:line information

- Prevents orphaned references during template renames
- Automates manual grep verification step
- Catches errors before commit
- Documents expected template filenames

1. Add to `.cwf/scripts/` as `template-reference-linter`
2. Parse all `.md`, `.pl`, `.pm` files for template filename patterns
3. Cross-reference against current template pool contents
4. Flag deprecated names (e.g., "e-implementation-exec.md" in v2.1 context)
5. Allow v2.0-specific references (V20.pm uses "f-testing-plan.md" correctly)
6. Integrate with pre-commit hook or CI pipeline

## Task: Create v2.0 to v2.1 Workflow Migration Tools

### Task-Type: feature
### Priority: Low
### Context: Task 25 implements v2.1 workflow with 10-phase sequential naming (a-j). Existing Tasks 1-24 use v2.0 format. The trampoline architecture handles mixed v2.0/v2.1 versions seamlessly, and we're already successfully using v2.1 (Tasks 26, 30), so migration is optional for consistency rather than a blocker.
### Problem: 
### Solution: Create migration script(s) that:
### Note on execution files: Do NOT create e-implementation-exec.md or g-testing-exec.md for completed tasks - that would fabricate history. Only rename/re-letter existing files.
### Note on rollback: Git is the rollback capability (`git commit` before migration, `git reset --hard` if needed).
### Scope: 
### Dependencies: 
### Success Criteria: 
### Rationale: Migration tools would provide consistency across all tasks by converting v2.0 format to v2.1 naming. However, this is **not blocking** because:
### Priority rationale: Originally marked Critical, but downgraded to Low after Task 30 demonstrated that mixed versions work without issues. Migration is "nice to have for consistency" rather than a blocker.
### Note: v1.0→v2.0 migration tools already exist and are preserved by Task 25. This task creates equivalent v2.0→v2.1 migration capability.
### Rationale: Manual validation is sustainable for small changes but becomes bottleneck as system grows. Automated testing provides confidence and speed.

Create automated migration tools to upgrade existing v2.0 tasks (a-plan.md through h-retrospective.md) to v2.1 format (a-task-plan.md through j-retrospective.md with sequential a-j lettering).


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

1. Detect v2.0 tasks (presence of a-plan.md, absence of e-implementation-exec.md)
2. Rename existing files with -plan suffix where appropriate
3. Re-letter files (e→f, f→h, g→i, h→j)
4. Update internal cross-references (d-implementation.md → d-implementation-plan.md references)
5. Validate migration (renamed files exist, content valid, no broken references)



- Migration script: `.cwf/scripts/migrate-v20-to-v21.pl` or similar
- Dry-run mode to preview changes before applying
- Batch migration for all v2.0 tasks or selective migration
- Validation checks before and after migration
- Clear error messages on failure
- Update documentation with migration instructions (including git commit/rollback workflow)

- Task 25 must be complete (v2.1 format defined, trampoline architecture implemented)
- v2.1 template files must exist in `.cwf/templates/pool/`

- [ ] Migration script created and tested
- [ ] Dry-run mode shows accurate preview
- [ ] Script handles all edge cases (partial migrations, already-migrated tasks)
- [ ] Validation checks prevent broken migrations
- [ ] Documentation explains migration process (including git commit/reset workflow)
- [ ] Tasks 1-24 can be migrated without manual intervention
- [ ] Migrated tasks work correctly with v2.1 workflow commands

- Trampoline architecture handles mixed v2.0/v2.1 versions seamlessly
- We're already successfully using v2.1 format (Tasks 26, 30)
- Completed tasks (1-24) work fine in v2.0 format
- New tasks use v2.1 templates automatically
- Manual migration is straightforward for the few tasks that need it



- [ ] Runs in <2 minutes
- [ ] Can run on any Perl 5.14+ system

## Task: Add Status Calculation Overview to Workflow Documentation

### Task-Type: chore
### Priority: Low
### Status: Proposed (identified during Task 25 retrospective discussion)
### Problem: Current documentation explains status VALUES (Backlog=0%, Finished=100%) but not how task completion percentage is CALCULATED:
### Solution: Add brief "How Status Works" section to `.cwf/docs/workflow/workflow-steps.md`:
### To check task status: 
### Status values: See [Status Values](#status-values) section above for complete list.
### Scope: 
### Out of Scope: 
### Success Criteria: 
### Rationale: Users and LLM need to understand how task percentage is calculated, but full details belong in script documentation (DRY). Brief overview with references provides sufficient context.

Add brief explanation of how task status/progress calculation works to workflow documentation, following DRY and progressive disclosure principles.

- No explanation that status is aggregated from workflow file Status fields
- No mention of status-aggregator script
- No reference to /cwf-status (user-invocable currently, agent-invocable after skills migration)
- Users/LLM don't understand how "25% complete" is derived


```markdown
## How Task Status Works

Task completion percentage is calculated by aggregating the `## Status` field from each workflow file (a-plan.md through h-retrospective.md). Each status value has a percentage weight (Backlog=0%, In Progress=25%, Finished=100%, etc.).

- User runs: `/cwf-status <task-path>` (command - user-only currently)
- Script: `status-aggregator <task-path>` (called by cig-status command)
- Future: Agent can invoke via Skill("cig-status") after skills migration

**How it's calculated**: See `status-aggregator` script for implementation details.

```

1. Add brief "How Task Status Works" section to workflow-steps.md
2. Position after "Status Values" section (lines 16-48)
3. Include references to status-aggregator script
4. Note that /cwf-status is user-only currently, agent-invocable after skills migration
5. Keep brief (4-6 sentences), follow progressive disclosure

- Detailed status-aggregator implementation (that's in the script itself)
- Fixing status aggregator issues (separate BACKLOG item exists)
- Skills migration (separate BACKLOG item exists)

- [ ] Brief explanation added to workflow-steps.md
- [ ] References status-aggregator script
- [ ] Notes future agent invocability
- [ ] Follows progressive disclosure (brief with pointers to details)

## Task: Add Active Maintenance Cost Analysis to g-maintenance Template

### Task-Type: chore
### Priority: Medium
### Problem: Current g-maintenance.md template doesn't distinguish between:
### Solution: Add required section to g-maintenance.md template:
### Total scheduled cost: [Hours per year]
### Estimated reactive burden: [Hours per year, may be zero]
### Active costs: [Scheduled + reactive estimates]
### Benefits: [Concrete value delivered, if feature used]
### Justification: [Why ongoing cost is worth it, or why zero cost makes it low-risk]
### Deprecation trigger: [When would we remove this feature?]
### Scope: 
### Rationale: Prevents open-ended future commitments by requiring explicit justification of ongoing work. Makes maintenance costs visible upfront, enabling better decisions about feature complexity.

Update the g-maintenance.md template to require explicit analysis of active maintenance costs versus passive benefits, preventing open-ended future commitments.

- **Active scheduled tasks**: Work that MUST be done on a regular schedule (maintenance, noun form)
- **Reactive support**: Work that MIGHT be needed IF issues arise
- **Passive benefits**: Value delivered without ongoing work

This leads to proposals for "quarterly reviews" or "monthly checks" without justifying the time commitment. Maintenance is an ongoing cost that needs explicit justification.


```markdown
## Active Maintenance Requirements

### Scheduled Maintenance Tasks
List tasks that MUST be done on a regular schedule:
- [Task description] - [Frequency] - [Estimated time]


If NONE: Explicitly state "NONE - no scheduled maintenance required"

### Reactive Maintenance Only
List scenarios where action MIGHT be required (IF/THEN format):
- **IF** [trigger condition] → **THEN** [action] ([estimated time])


### Cost/Benefit Analysis
```

1. Update `.cwf/templates/pool/g-maintenance.md.template` with new section
2. Position after "Monitoring Requirements" section, before "Status"
3. Include examples for both scenarios:
   - Example A: Feature with scheduled maintenance (database cleanup, log rotation)
   - Example B: Feature with zero scheduled maintenance (configuration/documentation changes)
4. Update documentation to explain distinction between active/reactive/passive

## Task: Research and Consolidate Cross-Document Reference Patterns

### Task-Type: discovery
### Priority: Medium
### Problem: Currently inconsistent patterns for referencing other documents:
### Scope: 
### Examples to analyse: 
### Outcome: Clear, documented standard for cross-document references that follows DRY and progressive disclosure principles.

Analyse and standardise cross-document reference patterns used throughout CWF system documentation, templates, and command files.

- Templates use bold text: `**See e-testing.md for complete test plan**`
- Some locations may use markdown links: `[text](path)`
- Some locations may use HTML comments
- No clear guidelines on when to use which pattern

1. **Audit existing patterns**: Survey all templates, command files, and documentation for cross-reference patterns
2. **Categorise use cases**: Different contexts may need different patterns (intra-task vs external, LLM-facing vs human-facing)
3. **Define standard patterns**: Establish clear guidelines for each use case
4. **Document rationale**: Explain why each pattern is used (progressive disclosure, readability, tooling support)
5. **Update style guide**: Document patterns in `.cwf/docs/` for future reference
6. **Migration plan**: Optionally create plan to standardise existing references

- Intra-task references: `d-implementation.md` → `e-testing.md`
- External doc references: Templates → `workflow-steps.md`
- Config references: Command files → `cwf-project.json`

## Task: Extract CWF Argument Validation Pattern to Documentation

### Task-Type: feature
### Priority: Low
### Note: Task 11 was cancelled (commands→skills migration in Task 57 bypassed the underlying $ARGUMENTS bug). The pattern itself remains useful as a security-review reference, hence kept at Low rather than removed. Reclassified from `Needs-Triage` in Task 130.

Create reusable documentation for the secure argument parsing pattern developed in Task 11. This pattern (LLM validates format → extracts arguments → invokes bash with literals) prevents command injection and handles arbitrary user input safely. Should be documented in `.cwf/docs/` for use in future CWF commands or similar systems. Include: (1) Security model explanation, (2) Format validation regex patterns, (3) Example implementation, (4) Test scenarios.

## Task: Standardize Exit Codes to errno-Style Values

### Task-Type: chore
### Priority: Low

Consolidate exit codes across all CWF helper scripts to use errno-compatible values for better semantic meaning and consistency. Currently, exit codes are inconsistent across scripts (e.g., exit 3 means "Missing required argument" in hierarchy-resolver but "No parent tasks" in context-inheritance). Proposed standard:
- 0 = Success
- 2 = ENOENT (No such file or directory) - for "not found" errors
- 13 = EACCES (Permission denied) - for permission errors
- 22 = EINVAL (Invalid argument) - for validation errors

Scripts to update: hierarchy-resolver, context-inheritance, status-aggregator, format-detector, template-version-parser, and any future helper scripts. Update documentation in script headers and `.cwf/docs/` to reflect standard.

## Task: Surface Task-Level Status Label in Status Summary Line

### Task-Type: feature
### Priority: Low
### Status: Follow-up from Task 58
### Proposed change: When all workflow files share the same status (e.g., all "Cancelled"), append it to the summary line: `- 11 (bugfix): ... - 0% [Cancelled]`. When mixed, either show the lowest-progress status or omit.
### Scope: Both `status-aggregator-v2.0` and `status-aggregator-v2.1`. Affects markdown and JSON output modes.
### Identified in: Task 58 retrospective (j-retrospective.md)

The status-aggregator summary line shows only the percentage (e.g., `- 11 (bugfix): ... - 0%`), with no status label. A Cancelled task at 0% looks identical to a Backlog task at 0%. The `--workflow` flag shows per-file status labels, but the top-level summary line does not surface the dominant or consensus status.

## Task: Improve status-aggregator Error Message Clarity

### Task-Type: chore
### Priority: Low

Improve error message in `status-aggregator` to clarify that it expects a task number (e.g., "17", "1.2.3"), not a full file path. Current error "Invalid task path format: 17-feature-new-helper-script-to-setup-templates-for-new-task" is confusing because users might provide the directory name or full path. Updated error should say something like "Error: Invalid task number format. Expected decimal notation (e.g., '17', '1.2', '1.2.3'), not a file path or directory name." This improves usability by helping users understand the correct input format immediately.

## Task: Implement Interface-Based Version Dispatch for status-aggregator

### Solution: Interface-Based Dispatch Pattern
### Task-Type: refactor
### Priority: Medium
### Status: Discovered in Task 26 (TC-F11 test failure)
### Problem: `status-aggregator --workflow` doesn't show workflow breakdown for all tasks in mixed-version projects.
### Current Behavior: 
### Expected Behavior: All tasks should show workflow breakdown with their respective version-specific files:
### Root Cause: Version detection happens ONCE at trampoline level, not per-task
### Affected Test Case: TC-F11 from Task 26 testing plan - currently marked as "KNOWN LIMITATION"
### Key Insight: "The modules know about versions, the scripts shouldn't have to."
### Architecture: 
### Usage in Unified Script: 

Refactor status-aggregator to use interface-based version dispatch pattern instead of separate version-specific scripts, enabling proper workflow display for mixed-version projects.


```bash
# Project has Tasks 1-25 (v2.0) and Task 26 (v2.1)
status-aggregator --workflow

# Result: Only Task 26 shows workflow breakdown
# Tasks 1-25 show no workflow files
```

- v2.0 tasks: 8 workflow files (a,b,c,d,f,h,i,j - skips e,g)
- v2.1 tasks: 10 workflow files (a-j)

1. Trampoline detects version globally (finds ANY v2.1 file → routes to v2.1 script)
2. Routes to single version-specific script (status-aggregator-v2.0 or v2.1)
3. That script processes ALL tasks using its hardcoded version logic
4. v2.1 script can't find workflow files for v2.0 tasks (tries to find 10 files that don't exist)

Implement Go-style interface pattern using Perl dispatch tables:



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

## Task: Audit CWF Skills for Hardcoded Data

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 43
### Scope: 
### Note: Originally framed against `.claude/commands/cwf-*.md`; rescoped to skills in Task 130 after the commands→skills migration (Task 57) eliminated the original audit target. The audit motivation still applies to the skill files that replaced them.
### Identified in: Task 43 retrospective (j-retrospective.md); rescoped in Task 130 (2026-05-07)

Audit all CWF skill files to identify and eliminate hardcoded data that should be read from configuration files instead.

- Check all `.claude/skills/cwf-*/SKILL.md` files (and any companion `*-extras.md` docs) for hardcoded lists, paths, or configuration values
- Identify data that duplicates information in `script-hashes.json`, `cwf-project.json`, or other config files
- Refactor to read from canonical sources instead of duplicating data

## Task: Document Workflow Phase Sequences by Task Type

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 43
### Scope: 
### Identified in: Task 43 retrospective (j-retrospective.md)

Create quick reference documentation for workflow phase sequences (which files are used) for each task type.

- Document feature workflow: a, b, c, d, e, f, g, h, i, j (all 10 phases)
- Document bugfix workflow: a, c, d, e, f, g, j (7 phases)
- Document hotfix workflow: a, d, f, g, h (5 phases)
- Document chore workflow: a, d, f, j (4 phases)
- Add to `.cwf/docs/workflow/` directory
- Include in command help or error messages when phase skipped

## Bug: Progress Signal Scores Completed Tasks Highest in Task Context Inference

### Task-Type: bugfix
### Priority: Medium
### Status: Backlog
### Observed: After completing Task 103 and creating Task 104, `task-context-inference` returned "inconclusive" with both 103 and 104 as candidates. Task 103 (100%/Finished) scored higher on the progress signal than Task 104 (~10%/Backlog). The branch signal (weight 100) overrode it in the final result, but the progress signal contributed noise.
### Root cause: Comment on line 409 says "bell curve, peak at 50%" but implementation is linear ramp. The scoring should either: (a) filter out 100% tasks entirely, (b) use a bell curve peaking at ~50% (actively being worked on), or (c) use an inverted ramp where low-progress tasks score higher (more work remaining = more likely current).
### Scope: 
### Identified in: Task 104 session — inference returned inconclusive when only one task had remaining work

The `_score_progress` function in `TaskContextInference.pm` uses a linear ramp (line 452: `int(($percentage / 100) * WEIGHT_PROGRESS_MAX)`) — a task at 100% gets score 60 (maximum), while a task at 10% gets score 6. This means **finished tasks dominate the progress signal**, which is backwards: a 100% task has no remaining work and shouldn't be a candidate for "current task."



- Fix `_score_progress` in `.cwf/lib/CWF/TaskContextInference.pm`
- Either filter out 100% tasks or use bell-curve scoring
- Update comment to match implementation
- Verify with mixed completed/in-progress task states

## Task: Research Compaction Failure Frequency via LMM Memory Analysis

### Task-Type: discovery
### Priority: Medium
### Status: Backlog
### Problem: Best practices recommend adding compaction preservation instructions to CLAUDE.md (e.g., "When compacting, always preserve: current task number, current workflow phase, list of modified files, task branch name"). Before implementing, we need to know whether compaction-related context loss is actually a frequent problem in CWF usage.
### Approach: 
### Identified in: Claude Code best practices analysis (2026-04-16)

Analyse conversation history via LMM memory MCP to determine how often compaction causes loss of critical CWF context, and whether custom compaction instructions in CLAUDE.md would mitigate it.


1. Query LMM for conversations where the agent lost track of task context mid-session
2. Look for patterns: agent asking "which task are we on?", re-reading files it already read, repeating completed work
3. Correlate with session length (longer sessions more likely to compact)
4. Assess frequency and impact
5. If frequent: recommend specific compaction instructions for CLAUDE.md
6. If rare: deprioritise

## Task: Add Session Hygiene Guidance to CWF Documentation

### Task-Type: chore
### Priority: Medium
### Status: Backlog
### Problem: No guidance currently exists on when to clear context, when to continue sessions, or how to manage long-running CWF workflows. Best practices are clear: `/clear` between unrelated tasks, `/clear` after 2 failed corrections on the same issue, continue when deep in one problem or during iterative refinement.
### Scope: 
### Identified in: Claude Code best practices analysis (2026-04-16)

Add guidance on Claude Code session management to CWF documentation, helping users maintain effective context across workflow phases.


- Add session hygiene section to `.cwf/docs/workflow/` or CLAUDE.md
- Document when to `/clear` (between tasks, after repeated corrections)
- Document when to continue (mid-phase, iterative refinement)
- Document `/compact` with CWF-specific preservation instructions
- Installed documentation only — no code changes

## Task: Replace Backtick Operators with IPC::Open3 in cwf-manage

### Task-Type: chore
### Priority: Very Low
### Scope: 
### Identified in: Task 61 (perlcritic --harsh on cwf-manage)

Replace backtick operators in `.cwf/scripts/cwf-manage` with `IPC::Open3` calls to satisfy perlcritic severity 3 (harsh). `IPC::Open3` is core since Perl 5.000. Currently 5 backtick usages for simple `git` commands — functional and readable as-is, but not PBP-compliant at level 3.

- Replace backticks in `find_git_root()`, `resolve_ref()`, `resolve_sha()`, `cmd_list_releases()`
- Consider also adding `/x` flag to simple regexes (8 hits) and converting the if-elsif dispatch to a hash table (1 hit) for full level 3 compliance

## Task: Add Conflict-State Regression Test for stop-uncommitted-changes-warning

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 113
### Problem: The hook's parsing path (`substr($_, 3)`) is identical for every porcelain status code, so conflict records *should* parse correctly. But this is unverified end-to-end. If git ever changes the porcelain format for conflicts (e.g. emits two paths separated by NUL, like renames), the hook would silently misreport.
### Scope: 
### Identified in: Task 113 g-testing-exec (TC-8 deferred as stretch)

Add a small regression test that exercises the `stop-uncommitted-changes-warning` hook against synthetic git porcelain output containing conflict-state records (`UU`, `AA`, `DD`). Currently the parser is verified by code inspection only — the live TC-8 test was deferred during Task 113 because reproducing a real merge conflict on a wf file is brittle.


- Add a test that feeds synthetic porcelain output into a parsing helper, or stages a real `UU` record via `git update-index --cacheinfo` against a stub blob
- Cover `UU`, `AA`, `DD`, and at least one rename (`R`) to round out porcelain-class coverage
- Wire into `prove` if there's an existing test harness, otherwise document as a manual one-liner

## Task: Skill Cross-Reference Linter for SKILL.md / *-extras.md Step Numbers

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 114
### Problem: There's no static check that SKILL.md step numbers match their extras-file labels. The d-implementation-plan Step 9 grep audit only looks for cross-references *to* the skill from outside; it doesn't catch internal docs that mirror the numbering.
### Scope: 
### Rationale: Caught by dog-fooding in Task 114. The fix is mechanical; the linter prevents recurrence and surfaces the issue before the next renumbering.
### Identified in: Task 114 j-retrospective.md

`*/SKILL.md` files numbered step lists (Step 1, Step 2, ...). Their companion `.cwf/docs/skills/*-extras.md` files mirror those numbers in section headings (e.g. "## CHANGELOG.md and BACKLOG.md Update (Step 8)"). When a SKILL.md is renumbered, the extras file silently drifts. Task 114 introduced two new steps in `cwf-retrospective/SKILL.md` (Step 9 bump, Step 11 tag), bumping squash from 9→10 and merge-suggestion from 10→12. The drift in `retrospective-extras.md` was only caught by actually running the retrospective skill in Task 114's own j-phase — and fixed in-task.


- Small Perl helper, e.g. `.cwf/scripts/command-helpers/cwf-validate-skill-refs`
- Given each SKILL.md, parse out its `**Step N**:` headings; given the corresponding extras file, parse `## ... (Step N)` and `### N.X` labels; warn on any mismatch
- Wire into `cwf-manage validate` as a soft check (warn, not fail) initially
- One subtest per SKILL/extras pair in a new `t/skill-refs.t`

## Task: Resolve cwf-project.json version drift vs .cwf/version

### Task-Type: discovery
### Priority: Medium
### Status: Follow-up from external user upgrade (v1.0.95 → v1.0.114)
### Problem: Two files claim to record the installed CWF version. Either one is authoritative and the other is vestigial, or both are intentional and should stay in sync. Either way, `cwf-manage update` shouldn't leave them inconsistent.
### Discovery questions: 
### Identified in: External user upgrade report, 2026-04-26

After `cwf-manage update`, `.cwf/version` was bumped to `v1.0.114` but `cwf-project.json` still recorded `"version": "v1.0.95"`. The external user deferred reconciling this on the basis that "`.cwf/version` is authoritative" — but it's unclear whether that's the design or just current behaviour.


- What is `cwf-project.json`'s `version` field meant to record? (installed CWF version, project schema version, last-init version, something else?)
- Is `.cwf/version` the authoritative installed-version source? If yes, why does `cwf-project.json` also carry a version?
- What reads each field today? (grep callers; any drift may already be silently broken)

**Resolution paths** (pick one in design phase):
- **A**: `.cwf/version` is sole authority — drop `version` from `cwf-project.json`, migrate any callers
- **B**: Both fields are intentional — `cwf-manage update` writes both; add a validate check for drift
- **C**: `cwf-project.json` records something distinct (e.g. project-schema version, init version) — rename the field to remove ambiguity

## Task: Consider parent-agent inline tool-selection rubric

### Task-Type: discovery
### Priority: Low
### Status: Follow-up from Task 118 retrospective
### Discovery questions: 
### Identified in: Task 118 j-retrospective.md (Future Work)

Task 118 added a tool-selection rubric for CWF subagents (canonical doc + brief inline excerpt in the plan-review prompt). The same anti-patterns (`sed -n 'X,Yp'`, `cat | grep`, `find … -exec cat`) apply when the *parent* Claude Code agent reaches for them — and Task 118's empirical observation that subagents ignore soft prompt restrictions is plausibly the same for the parent agent reading CLAUDE.md.

- Does the parent agent already comply with the rubric? Pull a recent transcript and check.
- The harness's system prompt already says "Read files: Use Read (NOT cat/head/tail)" — is that catching the cases Task 118's anti-patterns name, or are there gaps the canonical doc covers that the system prompt doesn't?
- If a gap exists: is the right place to address it CLAUDE.md (project-scoped), `~/.claude/CLAUDE.md` (user-scoped), or a CWF skill that can install the guidance into either?

**Resolution paths** (pick in design phase):
- **A**: No gap — close the discovery; convention doc remains subagent-scoped
- **B**: Gap exists, scope is project-specific — add a one-line reference to `.cwf/docs/conventions/subagent-tool-selection.md` from the project's CLAUDE.md
- **C**: Gap exists, scope is user-wide — add a CWF install-time hook that writes a tool-selection block into `~/.claude/CLAUDE.md` (with user opt-in)

## Task: Resolve symlinks in validate_path_allowlist

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 131
### Scope: 
### Risk: low — the only known production callers operate on hard-coded repo paths, not user-supplied ones. The exposure is via `backlog-manager add --body-file` which is not yet wired into automation.
### Identified in: Task 131 c-design-plan plan-review (security agent)

`validate_path_allowlist` in `CWF::ArtefactHelpers` rejects absolute paths and `..` traversal but does not resolve symlinks before checking the allowlist. A symlink inside the repo pointing outside the allowed prefixes (e.g. `t/fixtures/escape -> /etc/passwd`) would slip through, allowing `--body-file=t/fixtures/escape` in `backlog-manager add` (and analogous flows in any other helper using `validate_path_allowlist`) to read arbitrary files.

- Modify `validate_path_allowlist` to call `Cwd::realpath()` on the input and on each allowed prefix; reject if the resolved path doesn't begin with a resolved allowed prefix.
- Audit existing callers (`cwf-apply-artefacts`, `cwf-claude-settings-merge`, `backlog-manager`) to confirm none rely on symlink-not-resolved behaviour.
- Update `t/artefacthelpers.t` (or equivalent) with a symlink-escape regression test.

## Task: Close TOCTOU window in atomic_write_text via O_NOFOLLOW

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 131
### Scope: 
### Risk: very low — single-developer maintenance helpers; concurrent attacker access to the working tree is out of the documented threat model. Worth fixing for defense in depth, especially before any tool that takes user-supplied paths is exposed to multi-user scenarios.
### Identified in: Task 131 c-design-plan plan-review (security agent)

`atomic_write_text` in `CWF::ArtefactHelpers` uses `rename($tmp, $path)` which writes through symlinks. Helpers that defend against this (e.g. `backlog-manager retire`, the `write_backlog_file` / `write_changelog_file` wrappers in `CWF::Backlog`) check `-l $path` before invoking `atomic_write_text`. There is a TOCTOU window between the check and the rename: an attacker who can rewrite the directory between the two calls could swap the regular file for a symlink and have the rename traverse it.

- Modify `atomic_write_text` to use `sysopen` with `O_NOFOLLOW` on the destination, OR perform the `-l` check inside the helper immediately before the rename (narrows but does not eliminate the window).
- Considered alternative: `link()` + `unlink()` instead of `rename()` — gives atomic semantics on POSIX but would change the helper's semantics for callers that rely on inode preservation.
- Update `t/artefacthelpers.t` to verify symlink targets are refused.
