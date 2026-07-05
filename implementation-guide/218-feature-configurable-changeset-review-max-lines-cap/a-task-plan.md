# Configurable changeset-review max-lines cap - Plan
**Task**: 218 (feature)

## Task Reference
- **Task ID**: internal-218
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/218-configurable-changeset-review-max-lines-cap
- **Baseline Commit**: d055de1cb5949f3825632fbc14d24246c7778391
- **Template Version**: 2.1

## Goal
Let a project set the changeset-review production-line cap in `cwf-project.json`
(`security.review.max-lines`) instead of relying only on the helper's hardcoded
500 default, so the value survives CWF upgrades.

## Success Criteria
- [ ] `security-review-changeset` reads `security.review.max-lines` and uses it as
      the cap when no `--max-lines` CLI flag is passed.
- [ ] Precedence is CLI flag > config key > built-in default (500); each layer
      overrides the one below it.
- [ ] Invalid config values (non-positive-integer, wrong type) are rejected/ignored
      the same way an invalid CLI value already is — never a silent wrong cap.
- [ ] This repo's `cwf-project.json` sets `security.review.max-lines: 1000`, and a
      changeset between 501 and 1000 production lines now passes.
- [ ] Script-hash entry for `security-review-changeset` is refreshed in the same
      commit as the edit (hash-updates convention).

## Original Estimate
**Effort**: <1 day
**Complexity**: Low
**Dependencies**: `CWF::Versioning::read_config` (already used by
`max_lines_exclude_paths`); `.cwf/security/script-hashes.json` refresh.

## Major Milestones
1. **Config read**: New helper sub reads/validates `security.review.max-lines`,
   mirroring `max_lines_exclude_paths` (eval-guarded, defensive, never fatal).
2. **Precedence wiring**: `%opt{max_lines}` default becomes "unset"; resolve the
   effective cap as CLI ?? config ?? 500 after arg parsing.
3. **Rollout**: Set `1000` in this repo's `cwf-project.json`; refresh script hash;
   document the key alongside `max-lines-exclude-paths`.

## Risk Assessment
### High Priority Risks
- **Silent wrong cap**: A malformed config value could weaken or break the gate.
  - **Mitigation**: Reuse the existing positive-integer validation; on any invalid/
    absent value fall through to the 500 default (fail-safe, not fail-open-large).
    Cover with tests.

### Medium Priority Risks
- **Hashed-file drift**: `security-review-changeset` is under the
  `security.review.scripts` hash glob; an un-refreshed hash breaks `cwf-manage
  validate`.
  - **Mitigation**: Refresh the hash in the same commit as the edit; verify with
    `cwf-manage validate` in testing-exec.
- **Precedence regression**: Changing the `%opt` default from 500 to unset could
  alter existing `--max-lines` behaviour.
  - **Mitigation**: Test all three precedence layers explicitly, including the
    no-config no-flag path still yielding 500.

## Dependencies
- `CWF::Versioning::read_config()` — the eval-guarded config reader already relied
  on by `max_lines_exclude_paths()`.
- Hash refresh tooling (`cwf-manage fix-security` / recorded hash update).

## Constraints
- Perl core-only, `use utf8;`, UTF-8 I/O per project conventions.
- Since CWF dogfoods itself, editing the vendored helper in this repo **is** the
  upstream change — no separate "request upstream key" step exists.
- No new config schema machinery — the key is read defensively like its sibling.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: Will this take >1 week? No.
- [x] **People**: Does this need >2 people? No.
- [x] **Complexity**: 3+ distinct concerns? No — one helper + one config key.
- [x] **Risk**: High-risk components needing isolation? No.
- [x] **Independence**: Can parts be worked on separately? No.

No decomposition signals triggered — single-unit task.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five success criteria met. Delivered in one session, matching the `<1 day` /
Low-complexity estimate. No decomposition needed — single helper + one config key,
as scoped. Both named risks (silent wrong cap, hashed-file drift) were mitigated as
planned and verified by tests + `cwf-manage validate`.

## Lessons Learned
The estimate held because the shape mirrored an existing sibling
(`max_lines_exclude_paths`) — reusing a proven config-read pattern kept the concern
count at one. See f/g for the fix-security-vs-recorded-floor lesson that surfaced
incidentally during validate.
