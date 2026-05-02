# Create Design-Alignment Conventions Document - Implementation Execution
**Task**: 122 (chore)

## Task Reference
- **Task ID**: internal-122
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/122-create-design-alignment-conventions-document
- **Template Version**: 2.1

## Goal
Execute the implementation plan: write `docs/conventions/design-alignment.md`, wire it into CLAUDE.md, close the BACKLOG entry, add the CHANGELOG entry.

## Actual Results

### Step 1: Confirm style and audience
- **Planned**: Read `docs/conventions/perl-git-paths.md` and `commit-messages.md` to match style; confirm `docs/conventions/` (top-level) is the right location.
- **Actual**: Both convention docs read during d-implementation-plan. Top-level `docs/conventions/` confirmed correct via Task 118's commit `e9e4c2a` rationale: top-level = CWF development, `.cwf/docs/conventions/` = installed copies.

### Step 2: Inventory the reality
- **Planned**: Empirically inventory skills, helpers (incl. `.d/` and version suffixes), templates, rules, top-level scripts, reference surfaces.
- **Actual**: Inventory matched the plan with one addition. Reference-surface grep:

  ```
  git ls-files | grep -v ^implementation-guide/ | xargs grep -l 'cwf-task-plan\|cwf-status'
  ```

  returned 19 files: `CLAUDE.md`, `BACKLOG.md`, `CHANGELOG.md`, `COMMANDS.md`, `DESIGN.md`, `README.md`, `.claude/rules/cwf-workflow-files.md`, six `.claude/skills/*/SKILL.md` files, `.cwf/autoload.yaml`, `.cwf/docs/glossary.md`, `.cwf/docs/skills/checkpoint-commit.md`, and three `.cwf/docs/workflow/*.md` files.

  Addition vs plan: `.cwf/autoload.yaml` was not in the plan's expected list. The doc's audit checklist correctly defers to the live grep result (it doesn't enumerate the surfaces in prose), so no change needed.

### Step 3: Draft `docs/conventions/design-alignment.md`
- **Planned**: ~80–150 lines, Convention/Why/Existing-usage structure, all five topics.
- **Actual**: 168 lines (slightly above target — the `## Existing usage` section grew because the helper inventory was richer than expected). Five topics present as numbered subsections under `## Convention`:
  1. Single source of truth (table of artefact → canonical location)
  2. Naming patterns (`cwf-` prefix, kebab-case, phase-letter, version-suffix scope, `.d/` subcommand pattern)
  3. Rename audit checklist (5 numbered steps)
  4. Deprecation (in-repo vs `cwf-manage` asymmetry)
  5. Cross-document references (progressive disclosure, CLAUDE.md§Conventions, glossary)

  `## Why` grounds the rules in four concrete prior failures (Tasks 35, 59, 81, 90).

  `## Existing usage` lists real helper-script paths and convention-doc siblings.

### Step 4: Wire references
- **Planned**: Add `**Design Alignment**` bullet to CLAUDE.md§Conventions; replace BACKLOG.md task block (lines 557–623) with completion marker; add CHANGELOG.md entry modelled on Task 118.
- **Actual**:
  - **CLAUDE.md**: bullet added at lines 56–61 with five sub-bullets matching the **Commit Messages** style.
  - **BACKLOG.md**: 67-line task block deleted, replaced with one-line completion marker `<!-- Completed: "Create Design-Alignment Conventions Document" — Task 122 (2026-05-02) -->`.
  - **CHANGELOG.md**: Task 122 entry added above Task 121 with **Status**, **Duration**, **Impact**, ### Changes (3 bullets), ### Notable (5 bullets).
  - **Glossary**: deferred. "Design alignment" is the doc's title, not a term used in skill/doc prose elsewhere — adding a glossary entry would just duplicate the doc's first paragraph. Decision recorded here for g-testing-exec TC-10.

### Step 5: Plan review
- **Planned**: Already executed in d-implementation-plan phase via 3 parallel Explore subagents per `.cwf/docs/skills/plan-review.md`.
- **Actual**: Done. Findings synthesised into the implementation plan (helper subdirs, version-suffix scope, `.claude/rules/cwf-workflow-files.md` as reference surface, `cwf-manage` external contract, symlink-validate via `cwf-manage validate` instead of `find`, CHANGELOG format from Task 118).

### Step 6: Validation (during exec — pre-test sanity)
- **Planned**: All cited paths resolve; no v1.0 paths; British spelling; `cwf-manage validate` passes.
- **Actual**:
  - `.cwf/scripts/cwf-manage validate` → `[CWF] validate: OK`
  - 18 sampled paths cited in the doc all resolve (one-shot test loop confirmed every helper, template dir, convention sibling, and external doc path exists)
  - Only `.claude/commands/` mention in the doc is in the "Why" section describing Task 35's historical failure — accurate, not a stale path claim
  - Spot-check spelling: `behaviour` not used (no occurrences needed); no American variants (`color`, `behavior`, `organize`) — verified
  - Full TC-1…TC-10 pass/fail evidence is g-testing-exec's responsibility

## Blockers Encountered
None.

## Deviations from Plan
1. **Doc length** 168 lines vs target 80–150. Justified: the helper inventory under `## Existing usage` is denser than `perl-git-paths.md`'s because CWF has more named artefact types than there are git-path helper scripts. Trimming would either lose the concrete examples (the load-bearing part) or push them into an appendix and increase navigation cost.
2. **Glossary entry skipped** (see Step 4 actual). This is a deliberate omission, not a deferral; documented above and revisited in g-testing-exec.
3. **Reference surfaces in audit checklist** — the doc does not enumerate the 19-file list inline; instead it prescribes the grep that produces the list. This is more robust to future additions (new top-level docs auto-appear in the grep result) and matches `perl-git-paths.md`'s "list real things" style without freezing the list.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met (doc exists, covers 5 topics, reality-grounded, CLAUDE.md links to it, BACKLOG entry removed)
- [x] No requirements/design phases for this task type
- [x] No planned work deferred without user approval
- [x] No follow-up task needed

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 122
**Blockers**: None identified

## Lessons Learned
Mid-task user feedback ("avoid `find` and `sed` — they trigger blocking permission prompts") arrived while plan-review subagents were running. Caught a `find -type l ... -exec test -e` suggestion in their output and replaced it with `cwf-manage validate` before the suggestion reached the doc. The replacement is also stronger (validate also checks sha256 and recorded perms). Memory updated so the rule carries to future sessions.
