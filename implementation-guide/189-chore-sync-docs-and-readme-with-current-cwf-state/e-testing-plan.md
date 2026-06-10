# Sync docs and README with current CWF state - Testing Plan
**Task**: 189 (chore)

## Task Reference
- **Task ID**: internal-189
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/189-sync-docs-and-readme-with-current-cwf-state
- **Template Version**: 2.1

## Goal
Verify that the documentation change set agrees with the CWF that ships today and that
it introduced no new drift, broken reference, or out-of-scope code change.

## Test Strategy
### Test Levels
This is a documentation change set — no code under test. "Tests" are deterministic
verifications run against the edited docs and the live system:
- **Static checks**: grep sweeps for stale strings; cross-reference resolution.
- **Conformance checks**: doc claims vs. ground truth (`%WORKFLOW_FILES`,
  `Validate::Config`, the skills directory, the install method).
- **Integration check**: `cwf-manage validate` clean; change set touches docs only.
- **Output-level (acceptance)**: generate a throwaway task and confirm a real,
  freshly-produced artefact carries no stale strings (the rebrand lesson — source
  grepping alone is insufficient).

### Test Coverage Targets
- **Every doc edited** is covered by at least one conformance or static check.
- **100%** of `/cwf-*` commands named in docs resolve to a real skill.
- **Zero** stale-string hits in the docs grep set.
- **Regression**: `cwf-manage validate` exits clean; no `.cwf/scripts/**` file modified.

## Test Cases
### Functional Test Cases
- **TC-1 — Command inventory is complete and real**
  - **Given**: edited README.md, COMMANDS.md, CLAUDE.md and the skills dir.
  - **When**: extract every `/cwf-*` token from the docs; list `.claude/skills/cwf-*`.
  - **Then**: every documented command resolves to a skill dir, and every user-facing
    skill is documented; no command is missing or invented.

- **TC-2 — Dead/old command surface eliminated**
  - **Given**: the rewritten COMMANDS.md and DESIGN.md.
  - **When**: grep for `/cwf-substep`, positional `<task-type> [task-id]` syntax,
    `feature/N-`/category-dir model, old `plan.md`/`requirements.md` filenames.
  - **Then**: no hits; `/cwf-new-task` shown as `<num> [<type>] "description"`.

- **TC-3 — Per-type file sets match ground truth**
  - **Given**: docs that state per-type phase sets (README Task Types, CLAUDE.md
    Architecture Overview).
  - **When**: compare against `%WORKFLOW_FILES` in `.cwf/lib/CWF/WorkflowFiles/V21.pm`.
  - **Then**: feature 10 / bugfix 7 / hotfix 7 / chore 6 / discovery 8, exact letters.

- **TC-4 — Workflow-step count consistent**
  - **Given**: all edited docs.
  - **When**: grep for "8 workflow steps" / "8 structured steps" / "a-h".
  - **Then**: no hits; step count stated as 10 phases (a–j) everywhere it appears.

- **TC-5 — Stale-string sweep clean (docs)**
  - **Given**: the doc set (README, COMMANDS, DESIGN, CWF-PROJECT-SPEC, CLAUDE,
    INSTALL, docs/**).
  - **When**: grep for `cig-`, `CIG`, "5 helper scripts"/"5 scripts", `cwf-version`
    (as a required field), camelCase `taskManagement`/`taskIdPattern`, stray `v0.1`/
    `v0.2`/standalone "v2.0 system" version leaks.
  - **Then**: no hits in docs (legitimate historical mentions in BACKLOG/CHANGELOG are
    out of scope and excluded).

- **TC-6 — SPEC matches the validator contract**
  - **Given**: rewritten CWF-PROJECT-SPEC.md and `.cwf/lib/CWF/Validate/Config.pm`.
  - **When**: cross-check required (`supported-task-types`,
    `source-management.branch-naming-convention`) and optional enforced blocks
    (`versioning`, `wf_step_config`, `sandbox`) incl. their exact rules.
  - **Then**: all present and correct; `cwf-version`/`title`/`task-management`/`team`
    are absent as enforced fields; pass-through blocks are explicitly labelled
    "not validated" so the doc never implies enforcement.

- **TC-7 — Install method prose correct**
  - **Given**: README.md install section.
  - **When**: read the install-method description.
  - **Then**: read-tree (default) + file copy; subtree described as deprecated/refused;
    no "git subtree (for upstream sync)" as a live method.

- **TC-8 — scratchpad removed cleanly**
  - **Given**: the repo after edits.
  - **When**: `git ls-files scratchpad.md`; grep docs for references to `scratchpad.md`.
  - **Then**: file is gone from the tree and nothing references it.

- **TC-9 — Conventions charter applied**
  - **Given**: CLAUDE.md `## Conventions` and the two conventions dirs.
  - **When**: read the documented split; list both dirs.
  - **Then**: the `docs/` (develop-CWF) vs `.cwf/docs/` (all-users) rule is stated;
    each existing file conforms (relocated if not); dirs are disjoint (no `perl.md`
    duplication).

- **TC-10 — Deferred items captured**
  - **Given**: BACKLOG.md after edits.
  - **When**: `cwf-backlog-manager list`.
  - **Then**: entries exist for (a) template↔validator divergence and (b) live-config
    vestigial blocks.

- **TC-11 — Output-level smoke test (acceptance)**
  - **Given**: the edited docs and a clean tree.
  - **When**: `/cwf-new-task` a throwaway chore; inspect its generated file set and any
    generated prose; grep for stale strings.
  - **Then**: file set matches the chore set (a,d,e,f,g,j) and carries no stale strings.
    **Cleanup**: delete the throwaway via `/cwf-delete-task` whether the check passes
    **or fails**, so no residue remains to break `validate`.

### Non-Functional Test Cases
- **Scope/Regression**: `git diff --name-only <baseline>..HEAD` lists only docs +
  task files + BACKLOG; **no** `.cwf/scripts/**` or hashed file modified.
- **Integrity**: `cwf-manage validate` exits clean after all edits.
- **Prose conventions**: British spelling; no superlatives without evidence; no
  personal names in committed docs (roles only).
- **Reference integrity**: cross-doc links/paths in edited docs resolve to real files.

## Test Environment
### Setup Requirements
- The working branch with edits applied; standard repo tooling (git, grep, perl).
- Ground-truth sources read-only: `.cwf/lib/CWF/WorkflowFiles/V21.pm`,
  `.cwf/lib/CWF/Validate/Config.pm`, `.claude/skills/`, `implementation-guide/cwf-project.json`.

### Automation
- Verifications are shell/grep one-liners run in g-testing-exec; no CI harness.
- `cwf-manage validate` is the integrity gate (also run by each checkpoint commit).

## Validation Criteria
- [ ] TC-1 … TC-11 pass.
- [ ] Stale-string sweep clean; all documented commands resolve; per-type sets and
      SPEC schema match ground truth.
- [ ] `cwf-manage validate` clean; change set is docs-only (no hashed-file edits).
- [ ] Prose-convention and reference-integrity checks pass.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
