# hierarchy-aware consistency validation - Requirements
**Task**: 164 (feature)

## Task Reference
- **Task ID**: internal-164
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/164-hierarchy-aware-consistency-validation
- **Template Version**: 2.1

## Goal
Define what hierarchy-aware consistency validation must do: validate every task at any
nesting depth, judge branch consistency by the task hierarchy rather than flat equality,
and enforce the parent/child completeness asymmetry — without changing behaviour for
repos that have no subtasks.

## Functional Requirements
### Core Features
- **FR1 (full-depth coverage)**: Consistency validation must check every task in the
  hierarchy, including subtasks nested at any depth — not only top-level tasks. Each
  task's own recorded `**Task**` number and `**Branch**` are validated against its
  directory.
  - *AC*: Given a nested subtask dir whose `**Task**`/`**Branch**` field is wrong,
    validation reports it; today it is silent.

- **FR2 (directional branch consistency)**: An active task is branch-consistent when the
  current git branch is *either* that task's own recorded branch *or* the branch of one
  of its descendants. The single task whose recorded branch equals the current branch
  ("the leaf node", a plan-local term — distinct from a tree leaf with no children) must
  match exactly. The ancestor relation is transitive and exact: a multi-level ancestor of
  the leaf is consistent, and a numeric near-miss (`1` against `11`, `1.1` against `1.10`)
  is **not** an ancestor.
  - *AC*: On a descendant's branch, an active ancestor task (including a grandparent two
    or more levels up) produces **no** branch violation; the leaf node is still asserted
    to match the current branch exactly; a near-miss prefix is not treated as ancestry.

- **FR3 (off-chain tasks still flagged — fail closed)**: An active task that is neither the
  leaf node nor an ancestor of it must still be flagged when its branch differs from the
  current branch. The directional rule narrows along the ancestry axis only; it is never a
  blanket suppression. If branch values are ambiguous — more than one task records the
  current branch and they are not in an ancestor/descendant relationship — the rule must
  **fail closed** (flag, do not suppress), so a duplicated branch record cannot be used to
  hide a real inconsistency.
  - *AC*: An active **sibling** subtask (different branch, same parent) is flagged; an
    unrelated active top-level task on a different branch is flagged; two unrelated tasks
    both recording the current branch resolve to a flag, not silence.

- **FR4 (completeness invariant)**: A task in a terminal status (`Finished`/`Skipped`/
  `Cancelled`) must not have a descendant in a recognised non-terminal status; this is
  reported as a CONSISTENCY violation. The inverse — a terminal descendant under a
  non-terminal ancestor — is permitted and must not be flagged. Only a *recognised*
  non-terminal status counts: a descendant whose status is missing or unparseable does not
  by itself trigger FR4 (consistent with the existing "undefined status is not active"
  rule), though FR1 field validation may flag the malformed file separately.
  - *AC*: A `Cancelled` (and separately a `Finished`) parent with a `Backlog` child →
    violation naming both; `Finished` child under an active parent → no violation; a child
    with missing status under a terminal parent → no FR4 violation.

- **FR5 (no regression for flat repos)**: For a repository whose tasks are all top-level
  (no subtasks), the set of violations produced is identical to the pre-change behaviour.
  - *AC*: Existing `t/` consistency assertions pass unchanged; the flat top-level
    task-number and branch checks behave as before.

### User Stories
- **As a** maintainer working a subtask on its own branch, **I want** the parent task to
  not be reported as branch-inconsistent, **so that** `validate` output stays trustworthy
  and I am not trained to ignore it.
- **As a** maintainer, **I want** a terminal parent with an unfinished child to be
  flagged, **so that** an impossible completion state is caught rather than hidden.

## Non-Functional Requirements
### Performance (NFR1)
- Validation makes a single pass over the task tree; cost is linear in the number of task
  files, with no per-node full-tree rescan. Whole-repo `validate` wall time shows no
  perceptible regression versus baseline on the live repo.

### Usability (NFR2)
- Each violation names the offending task, the conflicting field and value, and an
  actionable remedy, consistent with the existing message format.
- No violation message may instruct mutating a field that is itself correct (e.g.
  "rewrite the parent's accurate `**Branch**`"); guidance must point at the real
  inconsistency (surface, never smooth — `feedback_surface_security_dont_smooth`).

### Maintainability (NFR3)
- Ancestry and tree relationships must reuse the existing `CWF::TaskPath` primitives
  (`get_parent`, `find_ancestors`, `find_descendants`, `find_children`, `parse_dirname`,
  `version_compare`, …) rather than re-deriving dotted-number ancestry inline in
  `Consistency.pm`; no new runtime dependency (core-Perl only, `feedback_perl_core_only`).
- The hierarchy rules are unit-testable in isolation against constructed task trees,
  independent of the live repo.

### Security (NFR4)
- Task directory names and recorded branch/field values are treated as data: they must
  not be interpolated into a shell or executed. The only git invocation remains reading
  the current branch (`Consistency.pm:108`).
- Directory traversal stays within `implementation-guide/`. Because full-depth coverage
  (FR1) introduces recursive descent, the traversal must not follow a symlinked subtask
  directory out of the subtree (decide `-l`/`lstat` handling in design); a crafted dir
  name or symlink must not cause reads outside `implementation-guide/`.
- A malformed dotted task-number shape (`1..2`, `1.`, leading zero, pathologically deep
  chain) feeding ancestry derivation must be handled deterministically, not crash or be
  silently mis-classified as an ancestor.

### Reliability (NFR5)
- Malformed trees degrade gracefully and deterministically without crashing: missing
  `**Task**`/`**Branch**`/status fields, a subtask dir whose recorded branch matches no
  expected pattern, or more than one dir recording the current branch each have defined
  behaviour (validation still completes and reports what it can). Where ambiguity affects
  the branch rule, the defined behaviour is to fail closed (FR3).

## Constraints
- `.cwf/lib/CWF/Validate/Consistency.pm` is hash-tracked: any edit requires the matching
  `script-hashes.json` refresh in the same commit (`docs/conventions/hash-updates.md`).
- The change must not alter `validate`'s exit-code contract for the existing top-level
  cases (advisory behaviour preserved).
- The canonical on-disk layout is **nested** subtask directories (a child dir lives inside
  its parent dir), as resolved by `CWF::TaskPath` and traversed by the status-aggregator's
  recursive `build_tree`. The validator must align to this layout, not invent a flat-dotted
  one.
- Scope is the consistency validator and its tests; no change to template files, the
  status vocabulary, or branch-naming conventions.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No.
- [ ] **People**: Does this need >2 people working on different parts? No.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — all five FRs are served
      by one hierarchy-aware traversal of the task tree.
- [ ] **Risk**: Are there high-risk components that need isolation? No.
- [ ] **Independence**: Can parts be worked on separately? No — they share the traversal.

No decomposition signals triggered.

## Acceptance Criteria
- [ ] AC1 (FR1): A wrong `**Task**`/`**Branch**` field in a nested subtask is reported.
- [ ] AC2 (FR2): Active ancestor on a descendant branch → no violation; leaf node asserted
      exactly; a multi-level (grandparent+) ancestor on a deep descendant branch → no
      violation; a numeric near-miss (`1`/`11`, `1.1`/`1.10`) → not treated as ancestry.
- [ ] AC3 (FR3): Active sibling / unrelated active task on a different branch → flagged;
      two unrelated tasks both recording the current branch → fail closed (flagged).
- [ ] AC4 (FR4): Terminal (`Finished` and `Cancelled`) parent + recognised non-terminal
      child → violation; `Finished` child under active parent → no violation;
      missing-status child under terminal parent → no FR4 violation.
- [ ] AC5 (FR5): The violation set is identical to pre-change for the existing
      `t/validate-consistency.t` fixtures **and** for at least one added multi-task flat
      fixture (not merely "tests pass"); full `prove t/` green.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
FR1–FR5 implemented and asserted; AC1–AC5 met (g-testing-exec.md). NFR3 (reuse
`CWF::TaskPath`, core-Perl) and NFR4/NFR5 (symlink-skip, graceful degradation) verified
by TC-S1/TC-W.

## Lessons Learned
FR5's "identical violation set" was honoured byte-for-byte by passing the directory
basename into the node builder so the `**Task**` fix message stayed unchanged — stricter
than the requirement's wording strictly demanded.
