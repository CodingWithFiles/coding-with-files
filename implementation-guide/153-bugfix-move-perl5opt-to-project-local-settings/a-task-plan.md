# move PERL5OPT to project-local settings - Plan
**Task**: 153 (bugfix)

## Task Reference
- **Task ID**: internal-153
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/153-move-perl5opt-to-project-local-settings
- **Baseline Commit**: b5b8739e3ea5ae7605417c893b9eb32f23cc5c3d
- **Template Version**: 2.1

## Goal
Make `PERL5OPT=-CDSLA` a project-scoped setting (in the repo's `.claude/settings.json`) installed automatically by CWF, instead of a per-user instruction to hand-edit the global `~/.claude/settings.json`.

## Problem Statement
CWF currently tells the user to add `env.PERL5OPT` to their **user-global** `~/.claude/settings.json` (INSTALL.md step 3; `/cwf-init` step 7; `check_perl5opt` warning in `CWF::Common`). A single global value is shared by every project on the machine, so two checkouts of CWF that want different `PERL5OPT` values (e.g. a future version changes the flag set) clash — whichever was set last wins, silently breaking the other project. The correct scope is the project-level `.claude/settings.json`, which Claude Code applies and which overrides the user-global `env` for tool calls inside that repo (verified against Claude Code's settings-precedence docs this task).

## Success Criteria
- [ ] A fresh `/cwf-init` results in `env.PERL5OPT=-CDSLA` present in the project's `.claude/settings.json` (committed by the existing init commit step), with no instruction to edit `~/.claude/settings.json`.
- [ ] `cwf-manage update` on an existing install adds `env.PERL5OPT` to the project `.claude/settings.json` if absent (idempotent; re-running adds nothing).
- [ ] An existing user-set `env.PERL5OPT` in project settings is preserved, not overwritten; a value differing from the canonical `-CDSLA` is surfaced (warned), not silently changed.
- [ ] All user-facing references (INSTALL.md, `/cwf-init` SKILL.md, `check_perl5opt` warning, `docs/conventions/perl.md`) point at project `.claude/settings.json`, not `~/.claude/settings.json`.
- [ ] Hash-tracked files edited in this task (`cwf-claude-settings-merge`, `CWF::Common`) have their `script-hashes.json` entries refreshed in the same commit; `cwf-manage validate` reports no new violations.

## Original Estimate
**Effort**: ~½ day
**Complexity**: Low
**Dependencies**: None. Rides on the existing `cwf-claude-settings-merge` → project `.claude/settings.json` write path that both `/cwf-init` (step 6d) and `cwf-manage update` (`run_settings_merge`) already invoke.

## Major Milestones
1. **Mechanism**: `cwf-claude-settings-merge` also merges `env.PERL5OPT` into project `.claude/settings.json` (add-if-absent, warn-on-mismatch).
2. **Docs & instructions**: INSTALL.md, `/cwf-init` SKILL.md (step 7 + the step-6 note + success criteria), `check_perl5opt` warning, and `docs/conventions/perl.md` all retargeted to project settings.
3. **Integrity**: hash refresh for the two hash-tracked files; `cwf-manage validate` clean.

## Risk Assessment
### High Priority Risks
- **Risk 1**: Project-level `env` not actually applied by Claude Code → fix is inert.
  - **Mitigation**: Verified against Claude Code settings-precedence + env-vars docs this task — project `.claude/settings.json` `env` is applied and overrides user-level, with no trust-gate. Premise holds.

### Medium Priority Risks
- **Risk 2**: Broadening `cwf-claude-settings-merge` (today: "Bash allowlist + Stop hooks") to also write `env` blurs its single responsibility.
  - **Mitigation**: Its real responsibility is "merge CWF-required settings into project `.claude/settings.json`" — it is already the sole writer of that file. `env.PERL5OPT` is one more CWF-required key. Update the header/usage text to say so.
- **Risk 3**: Overwriting a user's deliberately-different `PERL5OPT` value during `update`.
  - **Mitigation**: Add-only semantics — write the canonical value only when the key is absent; if present and differing, leave it and emit `[CWF] WARN:` (surface, never smooth).
- **Risk 4**: Stale `~/.claude/settings.json` still carrying `PERL5OPT` confuses users post-migration.
  - **Mitigation**: Project value overrides user value, so a leftover global is harmless. Add a one-line migration note in INSTALL.md; do not require removal.

## Dependencies
- None external. All touched surfaces are in-repo.

## Constraints
- `cwf-claude-settings-merge` and `CWF::Common` are hash-tracked → in-task hash refresh, same commit (`.cwf/docs/conventions/hash-updates.md`).
- Perl: core modules only; `#!/usr/bin/env perl` + `use utf8;`; no new non-core deps.
- `cwf-manage` itself must remain unedited (it already delegates to the merge helper) — keeping a hash-tracked entry-point out of the changeset.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No (~½ day).
- [ ] **People**: Does this need >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — one concern (setting location), with doc fan-out.
- [ ] **Risk**: High-risk components needing isolation? No.
- [ ] **Independence**: Can parts be worked on separately? No benefit; tightly coupled.

**Verdict**: No decomposition. Single-concern bugfix.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Planning complete. Scope confirmed: one mechanism change (`cwf-claude-settings-merge`) plus doc/instruction retargeting across four surfaces; `cwf-manage` untouched.

## Lessons Learned
Scope held at one concern (config location); the "reuse the existing settings writer, don't add a helper" instinct was validated by both design reviewers. Full learnings in `j-retrospective.md`.
