# Backlog refactor: retire, merge, reduce - Implementation Execution
**Task**: 146 (discovery)

## Task Reference
- **Task ID**: internal-146
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/146-backlog-refactor-retire-merge-reduce
- **Template Version**: 2.1

## Goal
Execute d-implementation-plan.md: draft recommendations, capture maintainer approval, pre-flight, seed CHANGELOG, apply approved actions, validate.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met (scratch dir, baseline pin, baseline count)
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status to "Finished" when complete

## Actual Results

### Step 1: Setup
- **Planned**: mkdir scratch dir; pin baseline SHA to file; sanity-check baseline count.
- **Actual**: scratch dir created (0700); baseline.sha = `ca7e8e531f0cad280ffcaa58faab8945a247f2c4`; baseline count via `grep -c '^## Task: '` = 67, but cross-checked via `backlog-manager list --all-items` = 68. Investigation revealed BACKLOG.md uses both `## Task:` and `## Bug:` heading prefixes; the parser at `CWF::Backlog.pm:222` accepts both.
- **Deviations**: **D1 -- baseline-enumeration regex was incomplete.** Plan specified `grep -c '^## Task: '`; corrected to `grep -cE '^## (Task|Bug): '` to cover the `## Bug:` prefix the parser also recognises. Same correction applied at AC1 check time. Confirmed real baseline count is 68.

### Step 2: Draft recommendations.md (commit dda0c0f)
- **Planned**: enumerate every baseline entry, classify against three axes, produce one `## Recommendation:` section per entry with selector, priority, action, rationale, target+carry-overs (for merges).
- **Actual**: 68 sections generated. Classifications: 4 retire, 3 merge, 1 reduce-scope, 60 keep-as-is. Net plan: 68 → 61 (~10% shrink). Used `--exact-title="<verbatim>"` selectors throughout (no `--id=<slug>` selectors), making D8.1 slug-uniqueness check vacuous and side-stepping the need to hand-derive 68 slugs.
- **Deviations**: **D2 -- selector form.** Plan allowed `--id=<slug>` or `--exact-title=`; all 68 rows use `--exact-title=` for consistency and to skip per-row slug derivation. Both selectors are supported by `backlog-manager retire` so functional behaviour is unchanged.

### Step 3: Maintainer approval (commit d0a97ad)
- **Planned**: present drafted artefact; maintainer fills `Approval:` line; commit artefact only.
- **Actual**: maintainer reviewed the recommendations summary and approved as-is on 2026-05-17 with the instruction "approve as-is, proceed with pre-flight and apply". `Approval:` line filled accordingly; committed.
- **Deviations**: none.

### Step 4: Pre-flight (no commit)
- **Planned**: write a one-shot Perl script using `CWF::Backlog` / `CWF::Common` to verify slug uniqueness, target resolution, cycle/dangling-target, and carry-over round-trip safety.
- **Actual**: implemented as a one-shot Bash check rather than the planned Perl script -- the four conditions reduced to: PF-1 vacuous (no `--id=` selectors); PF-2 dangling targets (grep over `Target:` lines, all 3 resolve to artefact rows); PF-3 cycle/terminal (every merge target's action is `keep-as-is`, no cycles, terminal); PF-4 carry-over heading-shape (grep for forbidden prefixes, none found). All four pass.
- **Deviations**: **D3 -- pre-flight realised as Bash rather than Perl.** Plan called for a Perl script using library imports. With all selectors as `--exact-title=` and only 3 merge rows, the realised checks are simple grep / awk patterns; writing a `use CWF::Backlog` script for three rows of input is heavier than the work justifies. Effective coverage is the same. The Perl-script approach remains correct for larger or `--id=`-heavy artefacts.

### Step 5: Seed Task 146 CHANGELOG block (commit ac45c8c)
- **Planned**: insert `## Task 146:` block above `## Task 145:` with In Progress placeholders.
- **Actual**: inserted exactly that. `backlog-manager validate` exit 0. Committed.
- **Deviations**: none.

### Step 6: Apply loop (commits 7c77215 → 5b37b28; 8 mutation commits total)
- **Planned**: per-row dispatch by action (retire / merge / reduce-scope / keep-as-is); `git diff --quiet` precondition before each iteration; per-commit `backlog-manager validate` gate.
- **Actual**: 4 retires + 3 merges + 1 reduce-scope = 8 commits, all single-commit (merges use the single-commit pattern per c-design D5). Validator clean after every iteration. Working-tree clean precondition held throughout. Specifically:
  - **Retire 7c77215**: "Add Delete Task Skill" -> rationale: implemented in Task 136.
  - **Retire 24f2512**: "Create v2.0 to v2.1 Workflow Migration Tools" -> rationale: moot, frozen v2.0 corpus.
  - **Retire c44acd0**: "Enforce sentinel-first output in security-review subagent prompt" -> rationale: substantively addressed by Task 144.
  - **Retire 6a845ed**: "Improve security-review-changeset feedback on empty-from-uncommitted changesets" -> rationale: obviated by Task 141.
  - **Merge 287a97e**: "Migrate print STDERR + exit Blocks" -> "Lift die_msg to a Shared CWF::Common Module"; 3 carry-overs preserved in survivor.
  - **Merge 910eb6f**: "Document Bugfix Workflow Differences" -> "Document Workflow Phase Sequences by Task Type"; 3 carry-overs preserved in survivor.
  - **Merge d38ab83**: "Consider internal-feature template variant" -> "Lightweight Rollout/Maintenance Templates for Internal/Developer-Tool Tasks"; 3 carry-overs preserved in survivor.
  - **Reduce-scope 5b37b28**: "Implement Interface-Based Version Dispatch for status-aggregator" -- entry shrank from ~210 lines to ~17 (~94% reduction). Embedded Perl code, Architecture sub-section, Implementation Steps numbered list, Benefits enumeration, and multi-paragraph Priority Justification all dropped. Problem, Approach, Success Criteria, Files Affected, Scope Note retained.
- **Deviations**: none.

### Step 7: Post-batch validation (no commit)
- **AC1 coverage**: 68 recommendations = 68 baseline entries. PASS.
- **AC2 approval ordering**: latest recommendations.md commit (d0a97ad) is ancestor of first BACKLOG/CHANGELOG mutation commit (ac45c8c). PASS.
- **AC3 CHANGELOG seed first**: first `--reverse` commit touching CHANGELOG.md in `baseline..HEAD` is the Step 5 seed commit (ac45c8c). PASS.
- **AC4 per-commit validator clean**: validate ran clean after every mutation. PASS.
- **AC5 merge-enrichment trace**: spot-check confirms all 3 merge carry-overs are findable in surviving BACKLOG entries. **TC-AC5 wording deviation noted below.** PASS.
- **AC6 ASCII purity (recommendations.md diff)**: `LC_ALL=C grep -cP '^\+.*[^\x00-\x7F]'` over the recommendations.md diff returns 0. PASS.
- **AC7 no orphan broken commits**: `git log` shows 11 coherent commits, no reverts. PASS.

**Net effect**: BACKLOG.md baseline 68 entries → post-batch 61 entries (7 entries removed, ~10% shrink), plus one entry slimmed from ~210 lines to ~17.

## Blockers Encountered

None.

## Deviations Summary

- **D1 (recommendations vs baseline regex)**: plan said `^## Task: '`; corrected mid-Step-1 to `^## (Task|Bug): '` to match the parser. Same correction propagated to AC1 verification.
- **D2 (selector form)**: plan offered `--id=` or `--exact-title=`; all rows used `--exact-title=` for consistency. No functional impact.
- **D3 (pre-flight implementation)**: plan called for a Perl script using CWF::Backlog imports; actual implementation is a single-shot Bash check that covers the same four conditions. Equivalent coverage; less ceremony for the realised input shape.
- **D4 (TC-AC5 wording)**: e-testing-plan TC-AC5 reads "grep against CHANGELOG.md" -- but merge enrichment goes into the surviving BACKLOG entry (per FR6), not into the retired CHANGELOG block. The TC wording is wrong; the corrected check (grep against BACKLOG.md, survivor side) passes. To fix in g-testing-exec.

## Deferral Check
Before marking status=Finished, verify:
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] All requirements from b-requirements-plan.md addressed
- [x] All design guidance in c-design-plan.md followed
- [x] No planned work deferred without user approval

**No deferrals.**

## Security Review

**State**: no findings

no findings: empty changeset

(The security-review-changeset helper returned `reviewed 0 files, 0 lines, anchor=ed94f60`. Task 146 mutated only `BACKLOG.md`, `CHANGELOG.md`, and `implementation-guide/146-.../*.md`; none fall inside the helper's CWF-internal-directory coverage. No new helper code, no new env-var consumers, no new shell invocations introduced by this task -- the only subprocess calls are to the existing `backlog-manager` helper, all argv-form per c-design D9.)

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
**Single-commit merge mechanic (c-design D5) collapsed all merge-failure modes to a single discard path.** Validator-clean after every commit; no revert needed; no orphan state to characterise. **`--exact-title=` over `--id=<slug>` (D2) was the simplification multiplier of the task** -- vacuous slug-uniqueness pre-flight, no per-row slug derivation, no impact on helper behaviour. Worth carrying forward as the default selector form for future batch-retire tasks. **File-based commit messages via `git commit -F /tmp/.../msg-*.txt` neutralised shell-quoting hazards** with titles containing backticks and dashes.
