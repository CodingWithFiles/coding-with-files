# Bash tool-check framework - Rollout
**Task**: 201 (feature)

## Task Reference
- **Task ID**: internal-201
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/201-bash-tool-check-framework
- **Template Version**: 2.1

## Goal
Define how the Bash tool-check framework reaches CWF users and how it is backed out
if it misbehaves.

## Deployment Strategy
### Release Type
- **Strategy**: Standard CWF release. The change lands on `main` (squashed), is tagged
  `v1.1.201` by the maintainer, and reaches existing installs via `cwf-manage update`.
  New installs receive it through `INSTALL.md` / the installer. There is no server,
  no fleet, and no per-user cohorting — every install gets the same files.
- **Rationale**: CWF is a file-based system distributed by git; the unit of rollout is
  the release tag. The framework is **inert by default** (empty ruleset → strict no-op
  hook), so shipping it to 100% of installs at once carries no behavioural change until
  an operator chooses to add a rule file. The empty default is the de-facto feature flag.
- **Rollback Plan**: The hook is fail-open by construction — any internal error, missing
  config, or malformed rule yields empty stdout + exit 0, so it cannot brick `Bash`.
  A defective release is backed out by reverting the task commit (removes the hook, the
  lib, and the integrity entries) and cutting a follow-up tag; `cwf-manage rollback`
  restores the prior installed release for an individual user. No state migration is
  required — per-session repeat-state lives under `${TMPDIR:-/tmp}` and is disposable.

### Pre-Deployment Checklist
- [x] Code review completed — exec-phase security review: no findings (see f-implementation-exec.md)
- [x] All tests passing — TC-1…TC-16 + regression suite (60 tests) green (see g-testing-exec.md)
- [x] Security scan — `cwf-manage validate` → OK (hook `0500`, lib regular file, hashes match)
- [x] Performance validated — ReDoS bound verified under external `timeout` (TC-14)
- [x] Documentation updated — `.cwf/docs/tool-check-rules.md` (schema, trust table, --check)
- [x] Registration configured — hook auto-registers via `script-hashes.json` directives;
      `.cwf/tool-check/*/settings.local.json` gitignored on install **and** upgrade
- [x] Rollback verified — fail-open posture exercised by the TC-13 reliability matrix

## Rollout Plan
### Phase 1: Ship inert
- **Scope**: All installs that take the release. The hook is registered and runs on every
  `Bash` call, but with no rule files present it is a strict no-op.
- **Duration**: Until an operator opts in by authoring a rule file.
- **Success Metrics**: No change in `Bash` behaviour; `cwf-manage validate` stays OK;
  no fail-open errors observed.

### Phase 2: Operator opt-in (out of this task's scope)
- **Scope**: An operator adds rules at one of the three layers
  (`~/.cwf/tool-check/bash/settings.json`, checked-in, or `settings.local.json`).
- **Mechanism**: `--check` diagnostic lets the operator preview the effective ruleset
  (dropped checked-in perl, overrides, final set) before relying on it.
- **Success Metrics**: Denials carry the rule's verbatim guidance; the repeat-bypass
  releases an identical second attempt to the native permission prompt.

### Phase 3: Seed CWF's own rules (deliberately deferred)
- This task ships the **mechanism** only. Populating the checked-in layer with rules for
  CWF's own repo is a separate future task, because the offending-command set shifts per
  model and per Claude Code version — a fixed shipped rule set would be wrong by
  construction.

## Monitoring
### Key Metrics
- **Behaviour**: `Bash` calls continue to function (fail-open guarantee); no spurious denials.
- **Integrity**: `cwf-manage validate` reports the hook + lib hashes matching.
- **Errors**: Absence of hook-internal errors (all are swallowed to exit 0; a hanging
  match is bounded by the harness `timeout`).

### Alerting
- No automated alerting (file-based local tool). The operator's signal is the `--check`
  diagnostic and `cwf-manage validate`.

## Rollback Plan
### Triggers
- The hook denies commands it should not (operator can disable a rule via `enabled:false`
  or remove the rule file — no release needed).
- `cwf-manage validate` reports a hash mismatch on the hook or lib (integrity signal —
  surface, never smooth).
- A latent fail-open defect that lets the hook abort `Bash` rather than degrade to no-op.

### Procedure
1. **Operator-level**: Remove or disable the offending rule, or `cwf-manage rollback`
   to the prior release.
2. **Project-level**: Revert the Task 201 commit (drops hook, lib, integrity entries,
   gitignore line) and cut a follow-up release tag.
3. **Communication**: Note in the release/CHANGELOG that the framework was withdrawn.
4. **Analysis**: Root-cause via the retrospective.

## Success Criteria
- [x] Ships inert — no behavioural change until an operator opts in
- [x] Fail-open verified — cannot brick `Bash`
- [x] Integrity verified — `cwf-manage validate` OK after install/upgrade
- [x] Documentation in place for operators authoring rules
- [x] Rollback path is a plain commit revert + tag; no state migration

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Rollout plan recorded. The artefact is ready to ship in the next CWF release; it is inert
until an operator authors a rule file, and fail-open so it cannot break `Bash`. Tagging
and release are human-only actions and are not performed here.

## Lessons Learned
*To be captured during retrospective*
