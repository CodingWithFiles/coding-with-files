# Adapt CWF to new Claude Code harness - Plan
**Task**: 172 (discovery)

## Task Reference
- **Task ID**: internal-172
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/172-adapt-cwf-to-new-claude-code-harness
- **Baseline Commit**: 7c2b09b0b46dd3d07e45005419435e1430b37e0d
- **Template Version**: 2.1

## Goal
Assess how recent Claude Code harness changes — a new client plus the Opus 4.8
model, bringing altered git-worktree handling, changed model self-checking /
dependency behaviour, and a newly-reserved meaning for the word "workflow" —
affect CWF's processes, and produce prioritised, tradeoff-weighted process / doc
/ convention / tooling changes that drastically reduce (1) loss of uncommitted
work and files and (2) momentum loss from permission prompts.

## Anchor Incident (primary evidence)
A real data-loss-then-recovery on another repo (`dircachefilehash`, Task 6),
captured verbatim, is the load-bearing case study. Summary of the failure chain:
1. The session ran in CWF's scratch convention but inside a **git worktree**;
   a `cd "$wt"` into the disposable worktree left the shell's **persistent CWD**
   there.
2. Subsequent `cd "$(git rev-parse --show-toplevel)"` then resolved to the
   **worktree** root (git toplevel from inside a worktree returns the worktree,
   not the main tree), so every `sed`/edit/lint/test ran in the worktree.
3. `git worktree remove --force` deleted the worktree — and with it all
   **uncommitted** edits.
4. The work survived only as a **dangling stash commit** (a `git stash push -u`
   / `pop` during verification left an unreachable commit object), recovered via
   `git fsck --unreachable` — **not** the HEAD reflog (the work was never
   committed, so HEAD reflog correctly showed nothing).
This single incident exercises worktree CWD invalidation, `--force` deletion of
uncommitted state, the toplevel-resolves-to-worktree trap, and the
reflog-is-the-wrong-tool recovery subtlety — all at once.

## Success Criteria
A discovery task's outputs are findings + recommendations, not shipped code.
- [ ] **Harness-change catalogue**: each observed behaviour change affecting CWF
      recorded with the CC client + model version under test and a concrete
      example (the anchor incident is the data-loss exemplar).
- [ ] **Data-loss root-cause map**: the failure class enumerated as distinct
      mechanisms (worktree CWD invalidation; `git rev-parse --show-toplevel`
      resolving to a worktree; `git worktree remove --force` discarding
      uncommitted work; recovery only via stash-reflog / `fsck`, not HEAD
      reflog), each tied to the CWF process step that exposes it.
- [ ] **"workflow" keyword-collision assessment**: where CWF's own "workflow"
      terminology (wf step files, `workflow-manager`, the `cwf-*-plan` "workflow
      skills") collides with the harness's reserved keyword, the observed
      behaviour change, and disambiguation options scoped from behavioural-guard
      to rename.
- [ ] **Permission-prompt inventory**: the CWF-driven Bash patterns that trip
      permission prompts under the new harness, reconstructed from the terminal
      backlog (the prompt text is stripped from the visible transcript), ranked
      by friction, and cross-referenced against the existing MEMORY.md
      avoidance rules to find what is newly-prompting.
- [ ] **Prioritised recommendations with explicit tradeoffs**: for each failure
      mode, ranked actions each stating the safety↔momentum tradeoff, shaped so
      they can be spawned as follow-up implementation tasks (and a recommended
      decomposition of that remediation work).

## Original Estimate
**Effort**: 1–2 days (assessment + write-up; remediation is follow-up tasks)
**Complexity**: Medium
**Dependencies**: the captured `dircachefilehash` Task 6 transcript (provided);
read access to the terminal scrollback/backlog for the stripped permission-prompt
text; the current CC client + Opus 4.8 version strings.

## Major Milestones
1. **Evidence**: harness-change catalogue, anchor-incident reconstruction, and
   permission-prompt capture from the terminal backlog.
2. **Analysis**: data-loss root-cause map + a safety↔momentum tradeoff matrix
   per failure mode; the keyword-collision assessment.
3. **Recommendations**: prioritised, decomposable actions ready to become
   follow-up tasks (convention/doc edits, helper-script guards, MEMORY/feedback
   updates).

## Risk Assessment
### High Priority Risks
- **Reducing permission friction by weakening safety**: the cheapest way to stop
  being prompted is to broaden allowances — which is exactly how an agent
  rationalises auto-approving destructive git operations. Trading objective (2)
  against objective (1) is the central hazard.
  - **Mitigation**: treat the two objectives as an explicit tradeoff, never a
    silent trade; carry CWF's standing "surface, never smooth" principle into
    every recommendation. Friction that prevents `--force`-class data loss is a
    feature, not a bug to be optimised away.
- **Moving-target harness**: CC client + model behaviour changes between
  releases, so findings can have a short shelf-life.
  - **Mitigation**: stamp every finding with the version under test; frame
    recommendations as durable conventions (e.g. "never `cd` into a disposable
    worktree from the primary session") rather than version-pinned hacks.

### Medium Priority Risks
- **Non-deterministic reproduction**: worktree-management and permission-trigger
  behaviour are harness-internal and awkward to reproduce on demand.
  - **Mitigation**: lean on the captured transcript + terminal backlog as
    primary evidence; reproduce only where cheap and safe (never re-run a
    `--force` deletion against real work).
- **Keyword collision is not CWF's to fix**: the harness owns the "workflow"
  reservation; only CWF-side mitigations exist, and the maximal one (renaming our
  pervasive "workflow" vocabulary) is a large breaking change.
  - **Mitigation**: scope options across the cost spectrum (behavioural guard in
    skills/CLAUDE.md → targeted wording changes → full rename) and let the
    requirements/design phases weigh them rather than presupposing a fix.

## Dependencies
- The `dircachefilehash` Task 6 transcript (provided in-conversation).
- Terminal scrollback/backlog access for the stripped permission-prompt contents.
- Current CC client version and Opus 4.8 model id (to stamp findings).
- Existing CWF surfaces this will recommend changing: `.cwf/docs/conventions/`
  (esp. `tmp-paths.md`), the `cwf-*` skills, helper scripts, and MEMORY.md /
  feedback memories.

## Constraints
- **Discovery output is assessment + recommendations, not code.** Concrete edits
  land as follow-up tasks through the normal CWF workflow.
- **CC harness behaviour is out of scope to change** — only CWF-side processes,
  docs, conventions, helper scripts, and memory/feedback can be altered.
- Findings are tied to the specific CC client + Opus 4.8 under test; record the
  versions so later readers know the shelf-life.
- Dogfooding: this task itself runs under the very harness it assesses — process
  hazards encountered while running it are themselves evidence.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: >1 week? **No** for the assessment itself (1–2 days); the *full
      remediation* across all findings may exceed a week, but that is follow-up
      work, not this discovery.
- [x] **People**: >2 people? **No**.
- [x] **Complexity**: 3+ distinct concerns? **Yes** — (a) worktree / data-loss,
      (b) "workflow" keyword collision, (c) permission-prompt friction, (d)
      model self-checking / dependency-reaction changes.
- [x] **Risk**: high-risk isolation needed? **Partially** — the data-loss
      mitigations touch destructive git operations.
- [x] **Independence**: separable parts? **Yes** — the two user objectives
      (data-loss prevention vs permission-friction reduction) have different
      evidence sources and different mitigations.

**Verdict**: 2+ signals fire, but they argue for decomposing the **remediation**,
not the **assessment**. A discovery task must hold the whole picture to make the
safety↔momentum tradeoffs coherently; splitting the assessment up front would
fragment that view. So this task stays unified and its deliverable *includes* the
recommended decomposition (likely separate follow-up tasks per failure mode). The
requirements phase will confirm this boundary.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five success criteria met in the §1–§7 assessment (f-implementation-exec.md):
harness-change catalogue, fully-evidenced four-mechanism data-loss map, keyword-collision
option set, backlog-mined permission-prompt inventory, and 6 prioritised recommendations
with a remediation decomposition. Unified-assessment / decomposed-remediation verdict held.

## Lessons Learned
The anchor incident was load-bearing exactly as hoped — one transcript exercised all four
mechanisms. The persistent-CWD hazard recurred live on the assessing agent during exec
(dogfooding), confirming the root cause is the shell CWD, not any single git command.
