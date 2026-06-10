# Sync docs and README with current CWF state - Implementation Execution
**Task**: 189 (chore)

## Task Reference
- **Task ID**: internal-189
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/189-sync-docs-and-readme-with-current-cwf-state
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status to "Implemented" when complete

## Ground Truth (recounted at exec time)
- Skills: **20** under `.claude/skills/cwf-*`.
- Helper scripts: **27** under `.cwf/scripts/command-helpers/` (count kept out of prose
  per the counts-policy — brittle).
- Per-type file sets (`%WORKFLOW_FILES`, V21.pm): feature 10 (a–j), bugfix 7
  (a,c,d,e,f,g,j), hotfix 7 (a,d,e,f,g,h,j), chore 6 (a,d,e,f,g,j), discovery 8
  (a,b,c,d,e,f,g,j). Matches plan.
- `.cwf/` tracked files: **163** (the stale INSTALL "~70" was badly out of date →
  made count-free).
- Enforced config schema confirmed against `CWF::Validate::Config`: required
  `supported-task-types` (exact canonical set) + `source-management.branch-naming-convention`;
  optional validated `versioning` / `wf_step_config` / `sandbox`. No `cwf-version`,
  `title`, `task-management`, or `team`.

## Actual Results

### Step 1: README.md targeted edits
- **Planned**: fix "5 scripts", "8 workflow steps", add discovery, install prose,
  replace camelCase config example.
- **Actual**: L71 → "A suite of helper scripts…"; L76 → "(10 workflow phases, a–j)";
  L74 added `discovery`; install prose → read-tree default + file copy (subtree
  deprecated/refused); config example replaced with a minimal **validated-schema**
  example (`supported-task-types`, `source-management.branch-naming-convention`,
  `versioning`) and the divergent template pointer swapped for a `CWF-PROJECT-SPEC.md`
  pointer (the template itself is a deferred backlog item).
- **Deviations**: pointer change beyond the literal plan, to avoid sending readers to a
  known-divergent template.

### Step 2: CLAUDE.md factual fixes
- **Planned**: version phrasing, 8→10 steps, helper-script desc, per-type sets.
- **Actual**: Project Status now "released under v1.1.x; file format v2.1", 10 lettered
  phases, "a suite of helper scripts"; Architecture Overview workflow phrasing → 10
  phases (a–j); per-type sets → 10/7/7/6 + discovery 8; "Five helper scripts" →
  "A suite…"; version-tracking example → `v1.1.187-5-gcea1c19`.
- **Deviations**: none. Conventions/Critical-Rules left untouched as planned.

### Step 3: INSTALL.md counts + version-example consistency
- **Planned**: count-free skill/file counts, standardise version examples.
- **Actual**: "~70 files" → "the complete tree"; "18 skill definitions" → "one SKILL.md
  per installed cwf-* skill"; verify comment "# Should show 18" → self-describing;
  CWF_REF/update/rollback examples standardised to current-era (`v1.1.0` / `v1.0.0`).
- **Deviations**: none.

### Step 4: CWF-PROJECT-SPEC.md rewrite against the validator
- **Planned**: document enforced schema, separate validated vs pass-through, remove
  retired fields.
- **Actual**: full rewrite. Validated keys section (exact rules from `Validate::Config`),
  an explicit **Pass-through Keys (not validated)** section listing the live config's
  unvalidated blocks, minimal + full examples, validation summary. `cwf-version`/`title`/
  `task-management`/`team` and the malformed `[::digit::]` examples removed.
- **Deviations**: none.

### Step 5: COMMANDS.md rewrite
- **Planned**: current command set/syntax, remove dead surface, a–j progression.
- **Actual**: full rewrite to the 20-skill inventory + `cwf-manage`; `/cwf-substep`,
  category-dir model, old `plan.md` filenames, `cig-` prefix, positional
  `<task-type> [task-id]` syntax all gone; phase table maps letter → file → skill.
- **Deviations**: none.

### Step 6: DESIGN.md rewrite (rationale altitude)
- **Planned**: current architecture at design-rationale altitude, pointing to
  `.cwf/docs/` and CLAUDE.md; do not create a 4th verbatim arch copy.
- **Actual**: full rewrite as "CWF Design Rationale" — the *why* (files-as-state,
  decimal hierarchy, plan/exec split, template pool, structural-map inheritance,
  scripts-vs-LLM, progressive disclosure, security model, read-tree laydown), each
  pointing to operational docs rather than restating them.
- **Deviations**: none. (Altitude was the open reviewer question; implemented at
  rationale altitude as scoped.)

### Step 7: Conventions charter
- **Planned**: document the `docs/` (develop-CWF) vs `.cwf/docs/` (all-users) split;
  classify and relocate any misfiled doc.
- **Actual**: added a charter paragraph at the top of CLAUDE.md `## Conventions`.
  Classified all 10 files: `docs/conventions/` (commit-messages, cross-doc-references,
  design-alignment, git-path-output, perl) are all develop-CWF; `.cwf/docs/conventions/`
  (hash-updates, session-hygiene, subagent-tool-selection, tmp-paths, worktree-process)
  are all all-users. **No relocation needed.** Dirs confirmed disjoint — no `perl.md`
  duplication (audit error confirmed false).
- **Deviations**: none.

### Step 8: scratchpad.md
- **Planned**: `git rm scratchpad.md` (described as a tracked vestigial v1 doc).
- **Actual**: **NOT a tracked file** — `scratchpad.md` is gitignored (`.gitignore:14`),
  a local ephemeral working file. `git ls-files scratchpad.md` already returns nothing,
  so it never ships and the release is unaffected (TC-8 already satisfied). Left the
  user's local file in place rather than deleting a 31KB file CWF did not create.
- **Deviations**: deviation from plan's `git rm`; surfaced rather than silently deleting.
  No repo change. "REVIEW REQUIRED" verified to be at line 4 (under a header), not the
  top — no stop-gate fires.

### Step 9: Docs-only stale-string sweep
- **Planned**: grep docs for stale strings, fix doc occurrences, note code occurrences
  for BACKLOG, do not touch hash-tracked `.cwf/scripts/**`.
- **Actual**: sweep clean. Remaining grep hits are legitimate — INSTALL L111/L134 are
  contextual "unlike git subtree" comparisons; `.cwf/docs/` hits are real
  `cwf-version-bump`/`-tag`/`-next` script names, not the retired config field. No
  hash-tracked file touched.
- **Deviations**: none.

### Step 10: BACKLOG entries
- **Planned**: two deferred config-schema items (added pre-exec, commit f06ce98).
- **Actual**: both present; added a third Low-priority item "Retire residual CIG
  branding from .cwf code and POD" for the out-of-scope code/POD `CIG` occurrences found
  in the sweep. `backlog-manager validate --all` clean.
- **Deviations**: third entry added (in-scope per plan's "note for BACKLOG").

## Blockers Encountered

None. One plan deviation surfaced (scratchpad.md is gitignored, not tracked — see Step 8).

## Deferral Check
Before marking status=Finished, verify:
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] All requirements from b-requirements-plan.md addressed (N/A — chore, no b-phase)
- [x] All design guidance in c-design-plan.md followed (N/A — chore, no c-phase)
- [x] No planned work deferred without user approval (scratchpad.md deviation surfaced;
      out-of-scope code items filed to BACKLOG per plan)
- [x] If work deferred: Follow-up task created and linked (3 BACKLOG items)

**If deferral required**: Get user approval, document rationale, create follow-up task.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Security Review

**State**: error

error: cap exceeded: 1073 production lines > 500

**Note (not a finding)**: this is a documentation-only change set (README, COMMANDS,
DESIGN, CWF-PROJECT-SPEC, CLAUDE, INSTALL). The changeset helper weights everything
outside `t/**` and `implementation-guide/**` as "production", so a multi-file docs
rewrite trips the 500-line production cap even though it contains no executable code.
Per the exec-skill's deterministic rule for exit 2, the changeset subagent was **not**
invoked. The actual security surface of the change is nil: no `.cwf/scripts/**`,
`.cwf/lib/**`, hook, or hash-tracked file was modified (verified by the docs-only scope
check), and no secrets, credentials, or executable logic were introduced.

## Lessons Learned
*To be captured during retrospective*
