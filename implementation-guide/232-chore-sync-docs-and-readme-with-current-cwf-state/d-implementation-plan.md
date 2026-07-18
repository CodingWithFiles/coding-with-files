# Sync docs and README with current CWF state - Implementation Plan
**Task**: 232 (chore)

## Task Reference
- **Task ID**: internal-232
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/232-sync-docs-and-readme-with-current-cwf-state
- **Template Version**: 2.1

## Goal
Apply the doc corrections identified by the drift audit so README and the maintainer/spec
docs match the implementation that ships today. Documentation-only change set.

## Ground truth (audited, this phase — recount at exec, don't trust line numbers)
- `.claude/skills/`: **21 dirs = 20 `/cwf-*` command skills + 1 internal `test-cwf-skill`**
  (plus 2 loose `.md` fragments, not commands). The a-plan's "23 skills" was a miscount
  (it counted the 2 `.md` files). The 20 commands:
  cwf-backlog-manager, cwf-config, cwf-current-task, cwf-delete-task, cwf-design-plan,
  cwf-extract, cwf-implementation-exec, cwf-implementation-plan, cwf-init, cwf-maintenance,
  cwf-new-subtask, cwf-new-task, cwf-requirements-plan, cwf-retrospective, cwf-rollout,
  cwf-security-check, cwf-status, cwf-task-plan, cwf-testing-exec, cwf-testing-plan.
- Helper scripts `.cwf/scripts/command-helpers/`: **27** non-`.d` entries.
- Workflow phase docs `.cwf/docs/workflow/workflow-steps/`: **10**, named **by phase**
  (`design.md`, `implementation-execution.md`, …), not lettered — only
  `.cwf/templates/pool/` carries the a–j prefixes.
- Per-type file sets match CLAUDE.md exactly (feature 10 a–j; bugfix 7 a,c,d,e,f,g,j;
  hotfix 7 a,d,e,f,g,h,j; chore 6 a,d,e,f,g,j; discovery 8 a,b,c,d,e,f,g,j).
- Current release **v1.1.231** (`implementation-guide/cwf-project.json` `last_released`);
  latest git tag v1.1.230 (v1.1.231 not yet tagged — tagging is human-only).
- Security model: recorded permissions are an **upper bound / ceiling** (Task 170) —
  `validate` flags a file only when *more* permissive than recorded, `fix-security` clamps
  *down*; many recorded values are `0444` (read-only, no exec), not `0500`.

## Files to Modify

### 1. `CLAUDE.md` (project, checked-in) — 3 edits — HIGHEST VALUE
Instruction file: touch only the wrong factual/architecture claims; leave conventions/rules
untouched (a-plan risk).
- [ ] **Security-model line** (audit anchor ~L130: "Security Model: u+rx (minimum 0500)
      permissions"): reword to the ceiling model — recorded permissions are an upper bound;
      `validate` flags files *more* permissive than recorded and `fix-security` clamps down;
      recorded modes include `0444` (no exec). Drop "minimum 0500" (it states the opposite
      invariant).
- [ ] **Skill list** (audit anchor ~L25–48): add the two omitted installed skills —
      **`cwf-current-task`** (task-stack; already referenced later in the file) and
      **`cwf-backlog-manager`** (BACKLOG management). Place under the appropriate
      Core/Utility grouping; keep `cwf-manage` labelled as the management **script**, not a
      skill.
- [ ] **Version example** (audit anchor ~L136: "e.g. `v1.1.187-5-gcea1c19`"): genericise
      the `git describe` example per the Version-example policy below (preserve the
      `-<n>-g<sha>` shape; do not chase a concrete number).

### 2. `DESIGN.md` — 2 edits
- [ ] **Permission framing** (audit anchor ~L79–80: "held at minimum permissions (`u+rx`,
      typically `0500`)"): align to the same ceiling model as CLAUDE.md; the nearby
      `fix-security` clamp prose (~L86–87) already reads consistently, so this is a wording
      fix, not a rewrite.
- [ ] **Version example** (audit anchor ~L96: same `v1.1.187` pin): genericise the
      `git describe` example per the Version-example policy (preserve the `-<n>-g<sha>`
      shape).

### 3. `README.md` — 1 substantive + 1 optional
- [ ] **"Always split planning/execution" overstatement** (audit anchors ~L65, ~L118–119,
      ~L154): only **implementation** and **testing** have separate `-exec` phases; the
      other phases are single-step. Reword all three to the hedged form COMMANDS.md already
      uses ("where applicable"/"where a stage benefits from it"), so the claim is accurate.
      **Do NOT touch ~L26** ("separate files for planning, design, implementation, and
      testing") — it describes *file structure*, not the plan/exec split, and is correct
      (robustness review: avoid over-correction).
- [ ] **(Optional — owner decision, see policy below)** illustrative `cwf-project.json`
      block (~L215–216: `"major_minor": "v1.0"`, `"last_released": "v1.0.0"`).

### 4. `CWF-PROJECT-SPEC.md` — 0–2 edits (OWNER DECISION, illustrative)
- [ ] The two dated `last_released` config samples (audit anchors ~L52, ~L122: `v1.1.188`)
      are config-value examples — **default: leave** per the Version-example policy (not
      drift; format is correct). Refresh to `v1.1.231` only if the owner chooses freshness.
      If left, this file drops out of the change set entirely.

### 5. NO CHANGE (verified clean by audit — record as "audited, no drift")
- `COMMANDS.md`: 0 drift — all 20 commands map to real skills, syntax matches
  `<num> [<type>] "description"`, phase-file table matches the pool, plan/exec split already
  hedged with "where applicable".
- `INSTALL.md`: 0 drift — `CWF_REF=v1.1.0` / `cwf-manage … v1.x` are acceptable illustrative
  pins; all documented `cwf-manage` subcommands exist.

## Version-example policy (OWNER DECISION — plan-review flagged)
The dated pins are all `e.g.`-labelled illustrative examples, so by the a-plan criterion
they are **not strictly drift** (three plan reviewers converged on this). "Refresh to the
current concrete number" re-stales next cycle, and `v1.1.231` is currently *untagged* —
so it is a poor illustrative `git describe` value (CLAUDE.md's own versioning rule ties the
patch to the task number *at tag time*). **Chosen policy — genericise, do not chase the
number:**
- **`git describe` format examples** (CLAUDE.md ~L136, DESIGN.md ~L96,
  `v1.1.187-5-gcea1c19`): these illustrate the **format** `<tag>-<n-commits>-g<short-sha>`,
  not a release. Genericise to make that explicit (e.g. `git describe` format such as
  `v1.1.x-<n>-g<sha>`), or if a concrete example is kept it **must preserve the
  `-<n>-g<sha>` shape** — never collapse to a bare tag (robustness review).
- **Config-value samples** (`cwf-project.json` `last_released`/`major_minor` in
  CWF-PROJECT-SPEC.md ~L52/~L122 and README ~L215–216): these show a *valid config value*
  and must match `/^v\d+\.\d+\.\d+$/`, so they cannot be genericised to `v1.1.x`. **Default:
  leave them** (labelled examples, not drift). If the owner prefers freshness over
  stability, refresh once to the current era (`v1.1.231` / `v1.1`) accepting the recurring
  churn. **Surface both to the owner at plan review; do not refresh silently.**
- Never touch historical version references in CHANGELOG.md/BACKLOG.md (point-in-time).

## Implementation Steps
1. [ ] Re-verify ground truth at exec (counts + the audit line-anchors may have drifted):
       `ls .claude/skills/`, the two missing skills, the permission-model lines, the version
       pins. **Divergence rule**: if the fresh recount differs from the numbers recorded
       above (e.g. a new skill, a release past v1.1.231), treat the *fresh* count as
       authoritative and drive the edits from it — do **not** apply this plan's literal
       numbers over a contradicting recount.
2. [ ] Apply CLAUDE.md edits: (a) security-model line → ceiling model; (b) add the two
       skills **in the existing Core/Utility grouping structure**, not appended loosely
       (misalignment review); (c) `git describe` example per the Version-example policy.
       **Verify the reworded security text against actual `cwf-manage validate` /
       `fix-security` behaviour** (flags when *more* permissive than recorded; clamps down)
       before committing — this is the one edit where wrong wording is itself a defect
       (security review).
3. [ ] Apply DESIGN.md edits (permission framing; `git describe` example per policy).
4. [ ] Apply README.md edit (plan/exec overstatement ×3; leave ~L26; the ~L215–216 JSON
       block only if the owner opts to refresh).
5. [ ] Apply CWF-PROJECT-SPEC.md sample refresh **only if** the owner opted in (else skip —
       file drops from the change set).
6. [ ] Grep sweep (sole verification — no task-generation): every `/cwf-*` command in
       CLAUDE.md maps to a real skill dir and no real command is omitted; the two new
       entries sit in the right grouping; no bare-tag `git describe` example was introduced;
       the security-model prose reads as the ceiling model.

## Test Coverage
**See e-testing-plan.md.** Verification is grep-based and deterministic: (a) skill-list
completeness (every `cwf-*` dir named, none invented); (b) no bare-tag/stale `git describe`
example in the edited docs; (c) the security-model statement matches the ceiling invariant;
(d) `cwf-manage validate` OK and `prove -r t/` green (docs-only, so both should be
unaffected). **No generated-artefact smoke test**: these prose edits do not flow into
template-generated output (not a rebrand), so a throwaway-task probe would exercise nothing
and needlessly mutate repo state (improvements + robustness review) — the Step 6 grep sweep
over the edited docs is the complete check.

## Validation Criteria (definition of done)
- [ ] All five success criteria in a-task-plan.md met.
- [ ] COMMANDS.md and INSTALL.md left unchanged (recorded as audited-clean, not skipped).
- [ ] No hashed-script edit (docs only) → no `script-hashes.json` change; `validate` OK.
      **If any edit lands on a hash-tracked file, STOP and surface it** (unexpected for a
      doc sync).
- [ ] British spelling; no superlatives; "CwF" in prose; no personal names.

## Deviations from a-plan
- **Drift smaller than Task 189**: the docs are well-maintained; no DESIGN.md re-architecture
  or docs/-consolidation work is needed. Net substantive edits: the Task-170 permission
  model (CLAUDE.md + DESIGN.md) and the two missing skills in CLAUDE.md; the rest are the
  README plan/exec wording and illustrative version-pin refreshes.
- **`scratchpad.md`**: untracked (not in HEAD) → not in the public tree → **out of scope**;
  no removal needed (closes the a-plan open decision).

## Plan-review adjustments (5-reviewer MAP)
- **Version pins → genericise, not refresh** (improvements/robustness/misalignment): the
  pins are labelled-illustrative, so chasing a concrete number is recurring churn; `git
  describe` examples genericised to format-structure, config samples left by default. The
  concrete-vs-leave choice for the two config samples is an **owner decision** at plan
  review.
- **Removed the throwaway-task smoke test** (improvements/robustness): prose edits don't
  reach template-generated output (not a rebrand), so it exercised nothing and mutated repo
  state; the grep sweep is the complete check.
- **Added**: a Step-1 divergence rule, a "leave README ~L26" caveat, a skill-grouping
  placement check, and an exec verification of the reworded security text against real
  `validate`/`fix-security` behaviour.
- Security/best-practice reviewers: no actionable findings (docs-only; no code, no
  applicable Go/Perl/Postgres best-practice corpus).

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 6 steps executed; ground truth recounted at exec matched the plan (no divergence). Owner
resolved the config-sample decision → refresh to v1.1.232 (both SPEC samples + README block).
See f-implementation-exec.md.

## Lessons Learned
The permission-model edit was the one where wrong wording is itself a defect; verifying it
against `hash-updates.md` + real `cwf-manage` clamp behaviour before commit paid off — three
reviewers independently re-confirmed it corrects an inverted invariant.
