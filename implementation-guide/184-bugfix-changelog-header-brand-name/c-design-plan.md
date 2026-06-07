# changelog header brand name - Design
**Task**: 184 (bugfix)

## Task Reference
- **Task ID**: internal-184
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/184-changelog-header-brand-name
- **Template Version**: 2.1

## Goal
Define how the stale brand string is corrected in two places: this repo's `CHANGELOG.md` intro line, and the changelog validation tooling (as a regression guard).

> **Scope decision (post-review)**: the originally-planned third part — an upgrade-time migration of existing user installs — was **dropped**. Investigation showed no CWF tooling ever seeds the "All notable changes…" intro into a consumer `CHANGELOG.md`: there is no CHANGELOG template, neither `install.bash` nor `/cwf-init` create the file, and `backlog-manager`'s bootstrap writes only `# Changelog` + `## Task N` nodes (`t/backlog-bootstrap-changelog.t:109`). The stale string therefore exists only in CWF's own hand-authored `CHANGELOG.md:3`; a migration would be a no-op in the wild, so it is not built ("the best part is no part").

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Canonical Strings (single source of truth for this task)
- **Stale** (exact substring): `Code Implementation Guide (CIG)`
- **Canonical** (exact substring): `Coding with Files (CWF)`

> **Brand casing (user-confirmed)**: this task uses the current repo-wide canonical **`CWF`** (all caps) — `.cwf/docs/glossary.md:51` ("CWF = Coding with Files", pronounced C-W-F), `README.md:1`, `CLAUDE.md:7`, Task 59 entry at `CHANGELOG.md:2854`. The user's intended long-term branding is mixed-case `CwF`, but that is pre-existing drift to be fixed project-wide under a separate **backlog item** (`Rebrand TLA from CWF to CwF across project`, identified in Task 184). Using `CWF` here avoids introducing the only `(CwF)` in the codebase mid-rebrand.

The fix is a **literal substring replacement**, not a whole-line rewrite. Only these bytes change; everything else in the intro line (including the existing "organized by task." wording) is preserved byte-for-byte.

## Key Decisions

### Decision 1 — This-repo header fix: direct edit
- **Decision**: Edit `CHANGELOG.md:3` in the f phase, swapping the stale substring for the canonical one. No tooling involved.
- **Rationale**: One-line correction to a consumer-content file we happen to own; completes the Task 59 rebrand. Simplest possible change.
- **Trade-offs**: None material.

### Decision 2 — Validation: surface drift as a warning, not a hard error
- **Finding**: `validate_changelog_tree` (`.cwf/lib/CWF/Backlog.pm:430`) only asserts a single `# Changelog` H1 exists; it never references the brand string. The CHANGELOG **bootstrap** path (`bootstrap_changelog_entry`, `.cwf/lib/CWF/Backlog.pm:715`) only constructs `## Task N` nodes — it does **not** emit the intro line. So no generator re-introduces the stale string; there is nothing to "fix" in a generator.
- **Decision**: Add a new `CHANGELOG-005` check in `validate_changelog_tree` that scans **the `intro` array only** (`@{$tree->{intro}}`, exactly as CHANGELOG-001 does at Backlog.pm:435 — never the whole file) for the stale substring and emits a **warning** (severity `warning`, not `error`) pointing at the canonical string and the migration.
- **Scope note**: scanning only the intro avoids false positives — the CHANGELOG **body** legitimately contains historical "(CIG)" fragments in retired Task-59 entries; those must never trip the warning.
- **Rationale**: Directly answers "validation tools updated to reflect this change", and acts as a **regression guard** so the stale brand can never silently reappear in CWF's own intro. A *warning* surfaces drift (honours "surface, don't smooth") without failing the build of a consuming repo — a hard error would punish a consumer for a cosmetic line they did not author.
- **Trade-offs**: A warning can be ignored; acceptable for a cosmetic nudge. Under `--strict` it escalates to an error via the existing generic warning→error promotion (no extra code).

## System Design

### Component Overview
- **`CHANGELOG.md` (this repo)**: data fix only (Decision 1).
- **`CWF::Backlog::validate_changelog_tree`**: gains a `CHANGELOG-005` warning that scans the intro for the stale substring (Decision 2).
- **`.cwf/security/script-hashes.json`**: refreshes the `CWF::Backlog` sha256 (the only hashed file changed), same-commit per hash-updates convention. `CHANGELOG.md` is not hashed; no new scripts are added.

### Data Flow
**A. This-repo fix (dev):** f phase → Edit `CHANGELOG.md:3` → checkpoint.

**B. Validation:** `backlog-manager validate` / `cwf-manage validate` → parse tree → `validate_changelog_tree` → if an `intro` line contains the stale substring → emit `CHANGELOG-005` warning (escalated to error only under `--strict`).

## Interface Design

### `validate_changelog_tree` — new check
```
CHANGELOG-005 (severity: warning)
  Fires when: a line in $tree->{intro} contains the literal
              "Code Implementation Guide (CIG)".
  Message:    "stale project name in CHANGELOG intro; expected
               'Coding with Files (CWF)'"
  --strict:   escalated to error by existing generic warning→error promotion.
```
(Intro-scoped, exactly like CHANGELOG-001 at `Backlog.pm:435`. The body legitimately contains historical "(CIG)" fragments in retired Task-59 entries, which must never trip the warning.)

## Constraints
- **Hashed-script discipline**: `.cwf/lib/CWF/Backlog.pm` is hashed (sha256 only, no `permissions` key — it is a lib module). Its sha256 in `.cwf/security/script-hashes.json` is refreshed in the **same commit** as the edit (hash-updates convention). No perms change; no new scripts.
- **Perl core-only + UTF-8** (`use utf8;`, `PERL5OPT=-CDSLA`).
- **No new runtime hard-failures for consumers**: validation emits a *warning* (not error), escalated only under `--strict`.
- **Reversibility**: a one-line content edit plus a read-only validation check; trivially reversible.

## Decomposition Check
After dropping the migration, only two small, cohesive concerns remain (header data fix + one validation check). No decomposition signals triggered. Single task.

## Validation
- [x] Design review completed (4 plan-review subagents; findings applied)
- [x] Integration points verified against code (Backlog.pm:430/435 validate, :715 bootstrap; no-propagation premise confirmed via templates/init/bootstrap)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Both decisions implemented as designed. Decision 1 (direct `CHANGELOG.md:3` edit)
and Decision 2 (intro-scoped `CHANGELOG-005` warning) shipped unchanged; the
dropped migration (Decision 3) stayed dropped. Intro-scoping confirmed correct
against the live file — body `(CIG)` fragments at lines 2245/2854 do not trip the
rule.

## Lessons Learned
The design-phase investigation (no propagation path for the stale intro) was the
highest-value work in the task — it removed two-thirds of the planned scope before
any code was written.
