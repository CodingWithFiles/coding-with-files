# Sync docs and README with current CWF state - Implementation Plan
**Task**: 189 (chore)

## Task Reference
- **Task ID**: internal-189
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/189-sync-docs-and-readme-with-current-cwf-state
- **Template Version**: 2.1

## Goal
Correct every user- and maintainer-facing document so it agrees with the CWF that
ships today, ahead of a release. Documentation-only change set; no behavioural code.

## Workflow
Verify against ground truth → edit doc → grep-sweep for residue → checkpoint with a
"why" message. No code/test changes; "tests" here are grep/smoke verifications.

## Ground Truth (verified during planning — the basis for every edit below)
Re-confirm by recount at exec time; do not copy these numbers blindly into prose.
- **Canonical task types** (`supported_types()` in
  `.cwf/lib/CWF/WorkflowFiles/V21.pm`): `feature, bugfix, hotfix, chore, discovery`.
- **Per-type workflow-file sets** (`%WORKFLOW_FILES`,
  `.cwf/lib/CWF/WorkflowFiles/V21.pm:49-98`):
  - feature → a,b,c,d,e,f,g,h,i,j (10)
  - bugfix → a,c,d,e,f,g,j (7)
  - hotfix → a,d,e,f,g,h,j (7)
  - chore → a,d,e,f,g,j (6)
  - discovery → a,b,c,d,e,f,g,j (8)
- **Workflow steps**: 10 lettered phases a–j (a=task-plan … j=retrospective), each a
  plan/exec split where applicable. README Task Types section is already correct.
- **Skills**: 20 `cwf-*` skills under `.claude/skills/` (`ls -d .claude/skills/cwf-*`).
- **Helper scripts**: a suite under `.cwf/scripts/command-helpers/` (incl. versioned
  v2.0/v2.1 pairs) — the old "5 named scripts" description is obsolete. Exact count is
  brittle and per the counts-policy must NOT reach prose; recount only as a sanity check.
- **Config schema = what `CWF::Validate::Config` enforces**: required
  `supported-task-types` (must equal canonical set) and
  `source-management.branch-naming-convention`; optional validated blocks `versioning`
  (`major_minor` /^v\d+\.\d+$/, `last_released` /^v\d+\.\d+\.\d+$/), `wf_step_config`
  (per-step boolean flags), `sandbox` (enabled/fail-if-unavailable/violation-logging
  booleans, `credential-deny-list` string array, `planning-write-guard` off|observe|
  enforce). There is **no** `cwf-version`, `title`, `task-management`, or `team` field
  in the enforced schema (the live repo config uses `task-tracking`, `versioning`,
  `security`, `directory-structure`, `workflow` blocks instead).
- **Install method**: `read-tree` default, `copy` fallback, `subtree` deprecated/refused
  (INSTALL.md already current; README prose lags).
- **Version reality**: release tags `v1.1.x` (latest `v1.1.187`; Task 188 committed as
  `v1.1.188`); workflow-file *format* is `v2.1`. The standalone "v2.0 system" phrasing
  in CLAUDE.md predates the v1.1.x tag scheme.

## Counts policy (risk mitigation — avoid re-introducing stale numbers)
Prefer descriptive phrasing over hard counts where the number carries no real
information ("a suite of helper scripts", "one SKILL.md per `cwf-*` skill"). Where a
sanity number genuinely aids the reader (INSTALL verification), make the check
self-describing rather than magic ("# one line per installed cwf-* skill") so it cannot
silently go stale. Never assert a count without recounting it this task.

## Files to Modify

### Primary Changes
1. **README.md** (targeted edits, file is mostly current)
   - L71 "Helper Script Automation: **5 scripts** …" → describe without the stale 5.
   - L76 "(8 workflow steps)" → "(10 workflow phases, a–j)"; reconcile with the correct
     "10-Phase Workflow" already on L65.
   - L74 Core Capabilities lists only "feature, bugfix, hotfix, and chore tasks" →
     add `discovery` (the README Task Types section already lists all five).
   - L84 install prose "via **git subtree** (for upstream sync) or file copy" → match
     INSTALL.md: read-tree (default) or file copy; subtree deprecated/refused.
   - L207-220 `cwf-project.json` example uses a camelCase schema (`taskManagement`,
     `git`, `taskIdPattern`) that matches neither the validator nor the live config →
     replace with a minimal example in the **enforced** schema (`supported-task-types`,
     `source-management.branch-naming-convention`, and a short `versioning` block).

2. **COMMANDS.md** (full rewrite — pre-v2.0 relic)
   - Replace the whole command reference with the current set, sourced from
     README "Commands" (L104-149) + CLAUDE.md skill list as the canonical inventory:
     core (`/cwf-init`, `/cwf-new-task <num> [<type>] "description"`,
     `/cwf-new-subtask`, `/cwf-delete-task`, `/cwf-status`, `/cwf-current-task`,
     `/cwf-extract`), workflow phase skills (`/cwf-task-plan` … `/cwf-retrospective`),
     utilities (`/cwf-config`, `/cwf-security-check`, `/cwf-backlog-manager`), and the
     `cwf-manage` script subcommands.
   - Remove: `/cwf-substep` (does not exist; real is `/cwf-new-subtask`), the
     `feature/N-...` category-directory model, old `plan.md`/`requirements.md`
     filenames, `cig-` prefix references, positional `<task-type> [task-id]` syntax.
   - Correct the typical-progression to the a–j phase flow with decimal nesting.

3. **DESIGN.md** (full rewrite — pre-v2.0 relic; user-confirmed "rewrite to current")
   - Replace the v1 architecture (category dirs, `cig-load-*` scripts, `plan.md`
     filenames, sed extraction, `v0.1.1` versioning) with the current design:
     decimal-nested tasks, lettered a–j phase files, central template pool + symlinks,
     helper-script + Perl-lib architecture, structural-map context inheritance, the
     sha256/permission security model, and `read-tree` laydown.
   - **Scope guard / duplication risk**: keep DESIGN.md at *design-rationale* altitude
     (the "why") and point to `.cwf/docs/workflow/` and CLAUDE.md for operational
     detail — do **not** create a fourth verbatim copy of the architecture. Flag for
     reviewer: confirm this altitude is what's wanted vs. archiving DESIGN.md.

4. **CWF-PROJECT-SPEC.md** (full rewrite against the validator)
   - Document the **enforced** schema (see Ground Truth): required
     `supported-task-types` + `source-management.branch-naming-convention`; optional
     `versioning`, `wf_step_config`, `sandbox` blocks with their exact validation
     rules.
   - **Separate "enforced by `Validate::Config`" from "conventionally present but
     unvalidated"** — `task-tracking`, `security`, `directory-structure`, `workflow`,
     `description`, `integration`, `project-name`, `templates` are pass-through blocks
     the live config carries but the validator does NOT check. The SPEC must label each
     so it never implies the latter are schema-enforced (that would re-introduce drift).
   - Remove fictional/retired fields: `cwf-version` (retired, Task 188), `title`,
     `task-management` (→ `task-tracking`), `team`; fix `supported-task-types` to the
     real five; fix the malformed `[::digit::]` POSIX-class examples.

5. **CLAUDE.md** (project root — factual Project-Status/Architecture claims only;
   leave Conventions/Critical-Rules untouched)
   - "system **v2.0** is implemented" → accurate current phrasing (releases are v1.1.x;
     file format v2.1) without the contradictory standalone "v2.0".
   - "**8** structured steps (a-plan through h-retrospective)" → 10 phases
     (a-task-plan through j-retrospective).
   - "**5 helper scripts** … hierarchy resolution, format detection, …" (Project Status
     bullet **and** Architecture Overview) → current description; drop the obsolete
     five named functions.
   - Architecture Overview per-type file sets ("feature 8 (a-h), bugfix 5 (a,c,d,e,h),
     hotfix 5 (a,d,e,f,h), chore 4 (a,d,e,h)") → correct sets from Ground Truth
     (10/7/7/6 + discovery 8).

6. **INSTALL.md** (targeted)
   - L220 "**18** skill definitions" and L343 "# Should show **18**" → make
     count-free/self-describing ("one SKILL.md per installed `cwf-*` skill"); if a
     number is kept, it is 20 and labelled current.
   - Standardise the inconsistent version examples (`v2.0.0`, `v2.1.0`, `v0.2.1`) to a
     single neutral `<tag>` placeholder or a consistent current-era example.
   - Re-verify the "~70 files" figure (L219); soften if not recounted.

### Supporting Changes
7. **scratchpad.md** (repo root) — remove. Vestigial v1 design doc; its `## Status`
   carries an old "REVIEW REQUIRED" marker (the global stop-gate keys off that string
   at the *top* of the file — it is below a title here, so no gate fires). `git rm`.
8. **Conventions directory charter** — apply the user's principle: `docs/conventions/`
   = conventions for *developing CWF itself*; `.cwf/docs/conventions/` = conventions
   for *all CWF users* (shipped). Actions:
   - Document the split once (short charter line in CLAUDE.md `## Conventions`, and/or a
     one-line header in each conventions area).
   - Classify each existing file against the rule and relocate any misfiled doc. Initial
     read: current placement already conforms (dev-authoring conventions in `docs/`;
     operational/user conventions in `.cwf/docs/`); confirm at exec, relocate only on a
     clear mismatch.
   - **Correct the audit error**: the two directories are disjoint — there is **no**
     duplicated `perl.md`; nothing to dedupe.
9. **Stale brand/string sweep (docs only)** — grep shipped/maintainer docs for `cig-`,
   "CIG", "v2.0"/"v0.1"/"v0.2" version leaks, `/cwf-substep`, old `plan.md` filenames;
   fix doc occurrences. Code/POD occurrences (e.g. V21.pm "CIG System" author tag) are
   out of scope → note for BACKLOG. **Guard**: do not let grep hits tempt an edit to any
   `.cwf/scripts/**` file — those are hash-tracked; touching one pulls a code+hash change
   into a docs commit.

### Deferred to BACKLOG (found during planning — NOT fixed in this docs task)
- **Install template ↔ validator divergence**: `.cwf/templates/cwf-project.json.template`
  still ships `cwf-version`/`title`/`task-management` and omits `versioning`/
  `wf_step_config`/`task-tracking` — so a fresh `/cwf-init` produces a config shaped
  unlike the dog-fooded one. Fixing the template/`cwf-init` output is a code/behaviour
  change, not doc sync.
- **Live `implementation-guide/cwf-project.json` vestigial blocks**: its `templates`
  block lists old `plan.md` filenames (unused — `template-copier` uses V21.pm) and
  `security.canonical-source` holds `OWNER/REPO` placeholders.
- Add both via `/cwf-backlog-manager` during exec (committing BACKLOG changes per the
  standing rule).

## Implementation Steps
### Step 1: Setup
- [ ] Re-confirm Ground Truth counts by recount (skills, helper scripts, type sets).
- [ ] Establish the stale-string grep baseline over docs (record current hits).

### Step 2: Edits (commit in logical groups, smallest-risk first)
- [ ] README.md targeted edits (counts, install prose, config example).
- [ ] CLAUDE.md factual fixes (version, step count, helper desc, per-type file sets).
- [ ] INSTALL.md counts + version-example consistency.
- [ ] CWF-PROJECT-SPEC.md rewrite against the validator schema.
- [ ] COMMANDS.md rewrite to current command set/syntax.
- [ ] DESIGN.md rewrite to current architecture (rationale altitude).
- [ ] Conventions charter documented + placement confirmed/relocated.
- [ ] `git rm scratchpad.md`.
- [ ] Docs-only stale-string sweep fixes.
- [ ] BACKLOG entries added for the two deferred items.

## Test Coverage
**See e-testing-plan.md for the complete verification matrix.** Verification is grep
sweeps + a generated-artefact smoke test + `cwf-manage validate`, not code tests.

## Validation Criteria
- [ ] Stale-string grep over docs returns clean (no `cig-`, `/cwf-substep`, "5 helper
      scripts", "8 workflow steps", `cwf-version` as required, old `plan.md` filenames).
- [ ] Every `/cwf-*` named in README/COMMANDS/CLAUDE resolves to a real skill dir; no
      command is missing or invented; syntax matches the skills.
- [ ] Per-type file sets in docs match `%WORKFLOW_FILES`.
- [ ] CWF-PROJECT-SPEC required/optional fields match `Validate::Config`.
- [ ] Output-level smoke test: generate a throwaway task, confirm its file set + docs
      carry no stale strings; then delete it (`/cwf-delete-task`). **On failure mid-test,
      still delete the throwaway task** so a failed verification leaves no residue that
      would itself break `cwf-manage validate`.
- [ ] `cwf-manage validate` clean; cross-doc references resolve; British spelling; no
      personal names; no superlatives.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
