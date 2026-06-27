# Plan-time mechanical review gates - Plan
**Task**: 213 (chore)

## Task Reference
- **Task ID**: internal-213
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/213-plan-time-mechanical-review-gates
- **Baseline Commit**: 9a8039feda7319311755703e35885de3612f672c
- **Template Version**: 2.1

## Goal
Add deterministic (non-LLM) plan-time checks to the CWF plan-review pipeline that catch
two recurring defect classes the agent reviewers structurally miss — broken
helper/script-path references and symbol deletions with live remaining references —
shipped to all CWF users and language-neutral.

## Success Criteria
- [ ] A mechanical plan-review check, shipped under `.cwf/` (installed surface, not dev-only `docs/`), scans a plan file and surfaces (a) referenced helper/script paths that do not resolve against the **main repo root**, and (b) named symbols slated for deletion together with their remaining repo-wide references.
- [ ] The check is wired into the plan-review pipeline (consumed during the `d-implementation-plan` phase at minimum) and degrades cleanly: no findings → no-op; the check's own errors are fail-open and never block the workflow.
- [ ] Both checks are language-neutral (no language-specific parsing — symbol names treated as opaque strings, path checks are filesystem-level) and the path check is **not** hardcoded to the `.cwf/scripts/` prefix.
- [ ] Tests in `t/` reproduce the Task-150 (wrong helper path) and Task-174 (deleted symbol still referenced by tests) defects on fixtures — red without the gate, surfaced with it — plus clean/no-op cases.
- [ ] New/changed hashed artefacts have `script-hashes.json` refreshed in the **same commit**; `cwf-manage validate` clean; full `prove -r t/` green.

## Original Estimate
**Effort**: ~1 day
**Complexity**: Medium
**Dependencies**: Existing plan-review pipeline (`.cwf/docs/skills/plan-review.md`, the three planning SKILLs); `CWF::Common::find_git_root` (Task 173); tmp-paths scratch convention; `script-hashes.json` machinery. The closest reuse template is `best-practice-resolve` (deterministic Perl helper, writes to per-task scratch, one stdout confirmation line, hash-tracked, 0500).

## Major Milestones
1. **Design (d-plan)**: Resolve the open decisions below — single helper vs two, integration point (pre-MAP helper writing to scratch like `best-practice-resolve` vs extending a Bash-enabled reviewer agent), finding format, and how deletion intent is detected in plan prose.
2. **Implement**: Build the helper(s), wire into the plan-review pipeline, refresh hashes.
3. **Test**: Fixtures reproducing the Task-150 and Task-174 defects (red→green) + no-op/fail-open cases.
4. **Validate & document**: `cwf-manage validate` clean, suite green, document the grep-precision tradeoff in the relevant skill/convention doc.

## Risk Assessment
### High Priority Risks
- **R1 — grep-based symbol sweep over/under-reports**: a short or common symbol name matches unrelated substrings (false findings erode trust); metaprogramming/dynamic dispatch hides real references (false negatives).
  - **Mitigation**: surface-as-finding, never block — a human/agent adjudicates hits; bound matching (word-boundary) to cut substring noise; **document the precision tradeoff openly** (the gate is a net, not a proof). The runtime backstop for the path class is the kernel's loud ENOENT (see Prior Art); the gate just moves detection earlier.

### Medium Priority Risks
- **R2 — path resolution reintroduces permission prompts or anchors to the wrong root**: inline `git rev-parse` substitutions prompt (Task 206); `--show-toplevel` returns a *worktree* root, not the main tree (Task 173).
  - **Mitigation**: resolve referenced relative paths against the main repo root via the existing `find_git_root` mechanism; no prompt-triggering inline substitutions.
- **R3 — scope creep into an LLM-style reviewer**: the value is *determinism*; building judgement into the check defeats the purpose and duplicates the existing agent reviewers.
  - **Mitigation**: keep it Perl, mechanical, no parsing; mirror the `best-practice-resolve` contract.
- **R4 — deletion intent is unstructured plan prose**: a plan rarely says "delete symbol X" in a machine-readable way, so the sweep may not reliably detect *which* symbols are slated for removal.
  - **Mitigation**: open decision for d-plan — a lightweight convention the check keys on vs a heuristic that flags candidates for reviewer confirmation. Resolve before implementing.

## Dependencies
- Existing plan-review pipeline and the three planning SKILLs (requirements/design/implementation) that invoke it at Step 8.
- `CWF::Common::find_git_root` (main-tree resolution, Task 173); tmp-paths scratch convention; `script-hashes.json` + `cwf-manage validate`.

## Constraints
- **C1 — installed surface**: deliverables land under `.cwf/` (and `.claude/agents/` if an agent is touched), so every CWF user gets the gates; not dev-only `docs/conventions/`.
- **C2 — language-neutral**: no language-specific parsing. Symbol names are opaque strings grepped repo-wide; path existence is a filesystem test. Works for any project language.
- **C3 — generalise the path check**: verify *any* referenced helper/script path, not only the `.cwf/scripts/` prefix the originating backlog item named.
- **C4 — zero-prompt, correct-root resolution**: reuse `find_git_root` / existing helpers; no inline `git rev-parse` (Task 206), no `--show-toplevel` worktree trap (Task 173).
- **C5 — fail-open, surface-not-block**: the gate emits findings for review; its own errors and "no findings" both degrade to a clean no-op, mirroring the pipeline's fail-open posture.
- **C6 — helper conventions**: Perl core-only, `0500`, hash-tracked (same-commit refresh), tmp-paths scratch output, self-managing single-confirmation-line stdout contract.

### Prior Art (verified this session)
- **Task 150** — origin of the helper-path defect class: a d-plan referenced `.cwf/scripts/command-helpers/cwf-manage` but the helper lives at `.cwf/scripts/cwf-manage`; agent reviewers reviewed plan *logic* and missed the path-existence defect.
- **Task 174** — origin of the symbol-deletion defect class: a plan deleted `@CWF_INTERNAL_PREFIXES` and source-grepped for it but not *test* assertions, so two test files coupled to the constant surfaced only at exec.
- **Task 173** — `CWF::Common::find_git_root` derives the main repo root via `git rev-parse --path-format=absolute --git-common-dir` (worktree-safe); the canonical resolver to reuse.
- **Task 206** — eliminate path-resolution permission prompts; anchor to project root with zero prompts (no inline substitutions).
- **ENOENT self-anchoring principle** (the `cwf-backlog-manager` cd-prefix cleanup) — relative `.cwf/scripts/...` paths self-anchor: wrong path ⇒ loud `execve` ENOENT (exit 127) at runtime. This is the *runtime backstop*; our gate is the *plan-time* early-catch, not a replacement for it.

### Open Decisions (resolve in d-plan)
1. **One helper or two** — a single pass doing both scans (the backlog notes they're complementary) vs two focused helpers.
2. **Integration shape** — a pre-MAP helper writing findings to per-task scratch (like `best-practice-resolve`, consumed in REDUCE) vs extending a Bash-enabled reviewer agent (misalignment or robustness) to run the check inline.
3. **Deletion-intent detection** (R4) — convention the check keys on vs heuristic-flag-for-confirmation.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No (~1 day).
- [ ] **People**: Does this need >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — two checks that deliberately share one plan-review pass.
- [ ] **Risk**: High-risk components needing isolation? No.
- [x] **Independence**: Can parts be worked on separately? The two checks *could* be split, but the whole point of this task (per the backlog) is to combine them into one mechanical pass — splitting would defeat the consolidation. **Keep as one task.**

**Decision**: No decomposition. One signal (independence) is technically present but combining the checks is the task's purpose.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 213
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Delivered in one session, under the ~1-day estimate. All three open decisions resolved in d-plan (one helper / two checks; pre-MAP resolver; declared `**Deletes**:` convention). All success criteria met: helper shipped under `.cwf/`, language-neutral, path check not prefix-bound, fail-open, Task-150/174 fixtures red→green, hashes refreshed same commit, validate OK.

## Lessons Learned
The `best-practice-resolve` template made the estimate accurate. Plan review caught two library-contract misassumptions before exec — verifying helper contracts at plan time is cheaper than at exec. See `j-retrospective.md`.
