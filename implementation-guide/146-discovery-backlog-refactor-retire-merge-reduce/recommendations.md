# Task 146: Recommendations -- backlog refactor

Baseline: ca7e8e531f0cad280ffcaa58faab8945a247f2c4
Generated: 2026-05-17
Approval: Approved as-is by maintainer on 2026-05-17. Proceed with pre-flight and apply.

---

## Recommendation: Tighten AC4-style grep gates to "metadata position only"
- Selector: --exact-title="Tighten AC4-style grep gates to \"metadata position only\""
- Priority: Low
- Action: keep-as-is

## Recommendation: Lift backlog-manager test scaffolding to `CWFTest::Fixtures`
- Selector: --exact-title="Lift backlog-manager test scaffolding to `CWFTest::Fixtures`"
- Priority: Low
- Action: keep-as-is

## Recommendation: Adopt CWF::Options for backlog-manager argument parsing
- Selector: --exact-title="Adopt CWF::Options for backlog-manager argument parsing"
- Priority: Low
- Action: keep-as-is

## Recommendation: Collapse parse_backlog_tree/parse_changelog_tree into single parse_tree($path, $kind)
- Selector: --exact-title="Collapse parse_backlog_tree/parse_changelog_tree into single parse_tree($path, $kind)"
- Priority: Low
- Action: keep-as-is

## Recommendation: Backfill **Baseline Commit** field in in-flight tasks' a-task-plan.md
- Selector: --exact-title="Backfill **Baseline Commit** field in in-flight tasks' a-task-plan.md"
- Priority: Low
- Action: keep-as-is

## Recommendation: Extend security-review-changeset shebang interpreter regex
- Selector: --exact-title="Extend security-review-changeset shebang interpreter regex"
- Priority: Low
- Action: keep-as-is

## Recommendation: Adopt `File::chdir` for test scaffolds that change directory
- Selector: --exact-title="Adopt `File::chdir` for test scaffolds that change directory"
- Priority: Low
- Action: keep-as-is

## Recommendation: Quantitatively justify the security-review subagent line-count cap
- Selector: --exact-title="Quantitatively justify the security-review subagent line-count cap"
- Priority: Low
- Action: keep-as-is

## Recommendation: Add fixture-server harness for end-to-end cwf-manage update tests
- Selector: --exact-title="Add fixture-server harness for end-to-end cwf-manage update tests"
- Priority: Low
- Action: keep-as-is

## Recommendation: Reconcile cwf-manage update and fix-security chmod logic
- Selector: --exact-title="Reconcile cwf-manage update and fix-security chmod logic"
- Priority: Low
- Action: keep-as-is

## Recommendation: Add --dry-run flag to cwf-manage fix-security
- Selector: --exact-title="Add --dry-run flag to cwf-manage fix-security"
- Priority: Low
- Action: keep-as-is

## Recommendation: Standardise Placeholder Syntax in Remaining CLI Docs
- Selector: --exact-title="Standardise Placeholder Syntax in Remaining CLI Docs"
- Priority: Low
- Action: keep-as-is

## Recommendation: Add Delete Task Skill
- Selector: --exact-title="Add Delete Task Skill"
- Priority: High
- Action: retire
- Rationale: Implemented in Task 136 ("Delete most-recent task only"). The /cwf-delete-task skill exists and is in use; the BACKLOG entry's bullet points (delete dir, delete branch, refuse on subtasks, --force flag) all match what shipped. The "no-arg form" follow-up is tracked as a separate, narrower entry below.

## Recommendation: Add Slug Generation Helper Script (`cwf-slug`)
- Selector: --exact-title="Add Slug Generation Helper Script (`cwf-slug`)"
- Priority: Low
- Action: keep-as-is

## Recommendation: Migrate Remaining `print STDERR + exit` Blocks in `template-copier-v2.1` to `die_msg`
- Selector: --exact-title="Migrate Remaining `print STDERR + exit` Blocks in `template-copier-v2.1` to `die_msg`"
- Priority: Low
- Action: merge
- Target: --exact-title="Lift `die_msg` to a Shared `CWF::Common` Module"
- Carry-overs:
  - "Replace each `print STDERR \"Error: ...\" + exit N` block with `die_msg(\"...\")`, preserving exit codes via a 2-arg form if needed"
  - "Update tests if any assertion strings depend on the old format"
  - "Refresh script hash"
- Rationale: Lifting die_msg to CWF::Common (the target entry) and migrating remaining template-copier-v2.1 call-sites are halves of the same refactor. The migration consumes the lifted helper and is the natural extension once it lands. Keeping them as two separate Low-priority items duplicates the "die_msg cleanup" surface.

## Recommendation: Lift `die_msg` to a Shared `CWF::Common` Module
- Selector: --exact-title="Lift `die_msg` to a Shared `CWF::Common` Module"
- Priority: Low
- Action: keep-as-is

## Recommendation: Codify the `main() unless caller();` Testability Convention
- Selector: --exact-title="Codify the `main() unless caller();` Testability Convention"
- Priority: Low
- Action: keep-as-is

## Recommendation: Replace cwf-extract Skill with Helper Script
- Selector: --exact-title="Replace cwf-extract Skill with Helper Script"
- Priority: Low
- Action: keep-as-is

## Recommendation: Lightweight Rollout/Maintenance Templates for Internal/Developer-Tool Tasks
- Selector: --exact-title="Lightweight Rollout/Maintenance Templates for Internal/Developer-Tool Tasks"
- Priority: Medium
- Action: keep-as-is

## Recommendation: Document Dead Code Audit Methodology
- Selector: --exact-title="Document Dead Code Audit Methodology"
- Priority: Medium
- Action: keep-as-is

## Recommendation: Comprehensive Dead Code Audit for CWF Library Modules
- Selector: --exact-title="Comprehensive Dead Code Audit for CWF Library Modules"
- Priority: Low
- Action: keep-as-is

## Recommendation: Create Perl Idioms Documentation
- Selector: --exact-title="Create Perl Idioms Documentation"
- Priority: Low
- Action: keep-as-is

## Recommendation: Add "Skipped-If" Conditional Logic to Workflow System
- Selector: --exact-title="Add \"Skipped-If\" Conditional Logic to Workflow System"
- Priority: Low
- Action: keep-as-is

## Recommendation: Create Integration Test for Inconclusive Inference Scenarios
- Selector: --exact-title="Create Integration Test for Inconclusive Inference Scenarios"
- Priority: Low
- Action: keep-as-is

## Recommendation: Document Bugfix Workflow Differences
- Selector: --exact-title="Document Bugfix Workflow Differences"
- Priority: Low
- Action: merge
- Target: --exact-title="Document Workflow Phase Sequences by Task Type"
- Carry-overs:
  - "Bugfix workflow skips h-rollout.md and uses checkpoint commits for rollout instead"
  - "Comparison table showing which phases each workflow type includes"
  - "Document rollout alternatives for workflows without h-rollout"
- Rationale: The target entry "Document Workflow Phase Sequences by Task Type" is the broader form of this one. Both motivate the same comparison table; the bugfix-specific entry is a strict subset of the broader scope. Merging avoids duplicate docs work.

## Recommendation: Create Verification Test Pattern Templates
- Selector: --exact-title="Create Verification Test Pattern Templates"
- Priority: Low
- Action: keep-as-is

## Recommendation: Add Material Changes Review to Phase Commit Checklists
- Selector: --exact-title="Add Material Changes Review to Phase Commit Checklists"
- Priority: Medium
- Action: keep-as-is

## Recommendation: Add Baseline Verification Step to Implementation Planning Templates
- Selector: --exact-title="Add Baseline Verification Step to Implementation Planning Templates"
- Priority: Low
- Action: keep-as-is

## Recommendation: Add Security Verification to Testing Workflow
- Selector: --exact-title="Add Security Verification to Testing Workflow"
- Priority: Medium
- Action: keep-as-is

## Recommendation: Test Edge Cases for Task Context Inference System
- Selector: --exact-title="Test Edge Cases for Task Context Inference System"
- Priority: Low
- Action: keep-as-is

## Recommendation: Create Template Reference Linter for Pre-Commit Hook
- Selector: --exact-title="Create Template Reference Linter for Pre-Commit Hook"
- Priority: Medium
- Action: keep-as-is

## Recommendation: Create v2.0 to v2.1 Workflow Migration Tools
- Selector: --exact-title="Create v2.0 to v2.1 Workflow Migration Tools"
- Priority: Low
- Action: retire
- Rationale: Tasks 1-24 (the v2.0 corpus that would be migrated) are completed and historical. The trampoline architecture handles mixed v2.0/v2.1 versions seamlessly, which is why the entry itself was downgraded from Critical to Low (per the entry text). The entry says "migration is 'nice to have for consistency' rather than a blocker"; the value of consistency-via-migration on a frozen historical corpus is effectively zero. Net new tasks already use v2.1. No realistic trigger to do this work.

## Recommendation: Add Status Calculation Overview to Workflow Documentation
- Selector: --exact-title="Add Status Calculation Overview to Workflow Documentation"
- Priority: Low
- Action: keep-as-is

## Recommendation: Add Active Maintenance Cost Analysis to g-maintenance Template
- Selector: --exact-title="Add Active Maintenance Cost Analysis to g-maintenance Template"
- Priority: Medium
- Action: keep-as-is

## Recommendation: Research and Consolidate Cross-Document Reference Patterns
- Selector: --exact-title="Research and Consolidate Cross-Document Reference Patterns"
- Priority: Medium
- Action: keep-as-is

## Recommendation: Extract CWF Argument Validation Pattern to Documentation
- Selector: --exact-title="Extract CWF Argument Validation Pattern to Documentation"
- Priority: Low
- Action: keep-as-is

## Recommendation: Standardize Exit Codes to errno-Style Values
- Selector: --exact-title="Standardize Exit Codes to errno-Style Values"
- Priority: Low
- Action: keep-as-is

## Recommendation: Surface Task-Level Status Label in Status Summary Line
- Selector: --exact-title="Surface Task-Level Status Label in Status Summary Line"
- Priority: Low
- Action: keep-as-is

## Recommendation: Improve status-aggregator Error Message Clarity
- Selector: --exact-title="Improve status-aggregator Error Message Clarity"
- Priority: Low
- Action: keep-as-is

## Recommendation: Implement Interface-Based Version Dispatch for status-aggregator
- Selector: --exact-title="Implement Interface-Based Version Dispatch for status-aggregator"
- Priority: Medium
- Action: reduce-scope
- Rationale: The current entry is ~200 lines including extensive embedded Perl code (full dispatch table, validate_interfaces sub, unified script skeleton). Detailed implementation belongs in the eventual task's c-design and d-implementation files, not in BACKLOG. The entry should be reduced to: problem statement (TC-F11 fails on mixed-version projects), proposed approach (per-task version detection + interface dispatch over a dispatch table), success criteria (TC-F11 passes, no regressions, code-duplication reduction), and the file-affected list. Drop the code snippets, the "Architecture" sub-section, the "Usage in Unified Script" code block, and the multi-paragraph priority-justification (Medium priority is enough; the why fits in two sentences). Net result: ~30-40 lines instead of ~200.

## Recommendation: Audit CWF Skills for Hardcoded Data
- Selector: --exact-title="Audit CWF Skills for Hardcoded Data"
- Priority: Low
- Action: keep-as-is

## Recommendation: Document Workflow Phase Sequences by Task Type
- Selector: --exact-title="Document Workflow Phase Sequences by Task Type"
- Priority: Low
- Action: keep-as-is

## Recommendation: Progress Signal Scores Completed Tasks Highest in Task Context Inference
- Selector: --exact-title="Progress Signal Scores Completed Tasks Highest in Task Context Inference"
- Priority: Medium
- Action: keep-as-is

## Recommendation: Research Compaction Failure Frequency via LMM Memory Analysis
- Selector: --exact-title="Research Compaction Failure Frequency via LMM Memory Analysis"
- Priority: Medium
- Action: keep-as-is

## Recommendation: Add Session Hygiene Guidance to CWF Documentation
- Selector: --exact-title="Add Session Hygiene Guidance to CWF Documentation"
- Priority: Medium
- Action: keep-as-is

## Recommendation: Replace Backtick Operators with IPC::Open3 in cwf-manage
- Selector: --exact-title="Replace Backtick Operators with IPC::Open3 in cwf-manage"
- Priority: Very Low
- Action: keep-as-is

## Recommendation: Add Conflict-State Regression Test for stop-uncommitted-changes-warning
- Selector: --exact-title="Add Conflict-State Regression Test for stop-uncommitted-changes-warning"
- Priority: Low
- Action: keep-as-is

## Recommendation: Skill Cross-Reference Linter for SKILL.md / *-extras.md Step Numbers
- Selector: --exact-title="Skill Cross-Reference Linter for SKILL.md / *-extras.md Step Numbers"
- Priority: Low
- Action: keep-as-is

## Recommendation: Resolve cwf-project.json version drift vs .cwf/version
- Selector: --exact-title="Resolve cwf-project.json version drift vs .cwf/version"
- Priority: Medium
- Action: keep-as-is

## Recommendation: Consider parent-agent inline tool-selection rubric
- Selector: --exact-title="Consider parent-agent inline tool-selection rubric"
- Priority: Low
- Action: keep-as-is

## Recommendation: Resolve symlinks in validate_path_allowlist
- Selector: --exact-title="Resolve symlinks in validate_path_allowlist"
- Priority: Low
- Action: keep-as-is

## Recommendation: Close TOCTOU window in atomic_write_text via O_NOFOLLOW
- Selector: --exact-title="Close TOCTOU window in atomic_write_text via O_NOFOLLOW"
- Priority: Low
- Action: keep-as-is

## Recommendation: Roll intent-CTA description convention to remaining skills
- Selector: --exact-title="Roll intent-CTA description convention to remaining skills"
- Priority: Low
- Action: keep-as-is

## Recommendation: Enforce sentinel-first output in security-review subagent prompt
- Selector: --exact-title="Enforce sentinel-first output in security-review subagent prompt"
- Priority: Medium
- Action: retire
- Rationale: Substantively addressed by Task 144 ("Tighten security-subagent sentinel-line output"), which strengthened the prompt with explicit "Your VERY FIRST output line MUST be..." framing. Task 141's retrospective confirmed empirical compliance ("First clean sentinel-first security-review subagent response in 6 consecutive exec-phase reviews"). The entry's secondary suggestion (extend the classifier with a last-line `no findings.` rule) is now a follow-up that has been overtaken by prompt-level success; if it becomes relevant again it can be re-added with sharper scope.

## Recommendation: Improve security-review-changeset feedback on empty-from-uncommitted changesets
- Selector: --exact-title="Improve security-review-changeset feedback on empty-from-uncommitted changesets"
- Priority: Low
- Action: retire
- Rationale: Obviated by Task 141 ("security-review-changeset blind to uncommitted"), which made the helper see uncommitted work by dropping `..HEAD` from the diff specs (option (a) from the helper's "Fix options" sketch on the now-retired sister entry). The original problem this entry tried to mitigate -- "skill records 'no findings: empty changeset' even though there IS a changeset, it just hasn't been committed" -- no longer occurs: the changeset is no longer empty for uncommitted work. The feedback-improvement that would have papered over the bug is moot now that the bug is fixed at the source.

## Recommendation: Consider `internal-feature` template variant for service-less CLI helpers
- Selector: --exact-title="Consider `internal-feature` template variant for service-less CLI helpers"
- Priority: Low
- Action: merge
- Target: --exact-title="Lightweight Rollout/Maintenance Templates for Internal/Developer-Tool Tasks"
- Carry-overs:
  - "For tasks whose deliverable is a local CLI helper with no service surface, no users, and no telemetry, the v2.1 template's h-rollout.md and i-maintenance.md sections collapse to mostly-N/A"
  - "Consider a slimmer template variant -- perhaps `internal-feature` or extending `chore` -- that drops these vestigial sections"
  - "Surfaced during Task 136 rollout + maintenance phases"
- Rationale: Same gap as the target entry (vestigial enterprise-rollout sections in templates that don't fit internal/developer-tool tasks). The target frames it as "lightweight variant"; this entry frames it as "service-less variant". The implementation path is identical: template-variant selection during /cwf-new-task. Merging consolidates the cross-task evidence (Tasks 57, 114, 136) into one entry.

## Recommendation: `/cwf-delete-task` no-arg form -- default to topmost stack entry
- Selector: --exact-title="`/cwf-delete-task` no-arg form -- default to topmost stack entry"
- Priority: Low
- Action: keep-as-is

## Recommendation: Make path-allowlists overridable in cwf-project.json
- Selector: --exact-title="Make path-allowlists overridable in cwf-project.json"
- Priority: Low
- Action: keep-as-is

## Recommendation: Investigate whether cwf-init GIT_ROOT capture is redundant
- Selector: --exact-title="Investigate whether cwf-init GIT_ROOT capture is redundant"
- Priority: Low
- Action: keep-as-is

## Recommendation: Add validate_temp_path_allowlist for transient-file callers
- Selector: --exact-title="Add validate_temp_path_allowlist for transient-file callers"
- Priority: Low
- Action: keep-as-is

## Recommendation: Drop --destination from cwf-new-task SKILL example (helper auto-constructs)
- Selector: --exact-title="Drop --destination from cwf-new-task SKILL example (helper auto-constructs)"
- Priority: Low
- Action: keep-as-is

## Recommendation: Retrofit create_skill_symlinks with warn-on-stray + die-on-collision
- Selector: --exact-title="Retrofit create_skill_symlinks with warn-on-stray + die-on-collision"
- Priority: Medium
- Action: keep-as-is

## Recommendation: Install-time chmod 0444 on data/agents files (avoid post-install fix-security)
- Selector: --exact-title="Install-time chmod 0444 on data/agents files (avoid post-install fix-security)"
- Priority: Low
- Action: keep-as-is

## Recommendation: Session-restart smoke-test helper for newly installed agents
- Selector: --exact-title="Session-restart smoke-test helper for newly installed agents"
- Priority: Low
- Action: keep-as-is

## Recommendation: Install-lifecycle shared helper library (install.bash + cwf-manage dedup)
- Selector: --exact-title="Install-lifecycle shared helper library (install.bash + cwf-manage dedup)"
- Priority: Low
- Action: keep-as-is

## Recommendation: Tune security-review-changeset 500-line cap to count edit-lines only
- Selector: --exact-title="Tune security-review-changeset 500-line cap to count edit-lines only"
- Priority: Low
- Action: keep-as-is

## Recommendation: Naming convention for throwaway test branches
- Selector: --exact-title="Naming convention for throwaway test branches"
- Priority: Low
- Action: keep-as-is

## Recommendation: Status value mismatch: planning-phase skill templates suggest 'Planning' but cwf-project.json doesn't include it
- Selector: --exact-title="Status value mismatch: planning-phase skill templates suggest 'Planning' but cwf-project.json doesn't include it"
- Priority: Low
- Action: keep-as-is

## Status
**Status**: Finished
**Next Action**: N/A -- artefact is preserved as a discovery output; the applied actions live in the f-phase commit log.
