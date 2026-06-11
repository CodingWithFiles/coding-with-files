# backlog validate minimum structural contract - Rollout
**Task**: 190 (feature)

## Task Reference
- **Task ID**: internal-190
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/190-backlog-validate-minimum-structural-contract
- **Template Version**: 2.1

## Goal
Roll out the `BACKLOG-000` structural-manageability contract: the validate
assertion plus the `add`/`modify`/`delete`/`retire` mutation gate.

## Deployment Strategy
### Release Type
- **Strategy**: Single-step in-repo release (no phased user rollout). CWF is a
  file-based developer tool, not a running service; the blue-green/canary
  template does not apply. (Tracked separately:
  *Lightweight Rollout/Maintenance Templates for Internal/Developer-Tool Tasks*.)
- **Rationale**: The change is two hash-tracked source files
  (`CWF::Backlog.pm`, `backlog-manager`) plus tests and docs. It lands on `main`
  via the normal squash-merge and reaches end users when they run
  `cwf-manage update`. There is no partial-population concept to canary.
- **Rollback Plan**: `git revert` the squashed commit (or `cwf-manage rollback`
  on an installed copy). The change is additive and isolated — reverting
  restores the prior vacuous-pass behaviour with no data migration. No state is
  written by the feature itself.

### Pre-Deployment Checklist
- [x] Code review completed — exec-phase security review (f and g): `no findings`
- [x] All tests passing — TC-1…TC-15 green; full suite +15 over baseline, zero
      new failures (two pre-existing env-specific failures confirmed on clean HEAD)
- [x] Security scan completed — no critical issues; error message interpolates
      only fixed-enum kind + line number, no verbatim file content (TC-7 pins it)
- [x] Performance validated — predicate reuses parser-cached `_source_lines`/
      `_source_fence`; no second read or fence rebuild (NFR1 by construction)
- [x] Documentation updated — `cwf-backlog-manager.md` gained the
      "Structural contract (`BACKLOG-000`)" section (target of the error ref)
- [x] `cwf-manage validate` → OK on the live repo
- [x] Rollback procedure identified (single `git revert`; additive change)

## Rollout Plan
This task is an in-repo tooling change; the "phased rollout" of the template is
replaced by the discrete rollout actions performed at this step:

### Action 1 — Retire the seed backlog item
The item that motivated this task —
*"Backlog validate must assert a minimum structural contract (manageability),
not pass vacuously on foreign files"* (seeded at `48b12c6`) — was retired to
`CHANGELOG.md` against Task 190 via `backlog-manager retire`. High band 2 → 1;
two-file atomic write; `validate --all` clean afterwards.

### Action 2 — File follow-up backlog items
Two follow-ups filed from the design's open questions (`backlog-manager add`):
- **KD5 CHANGELOG parity** (Medium) — extend the generic
  `backlog_structure_errors` predicate (already `@EXPORT_OK`) to the
  `CHANGELOG.md` validate/mutation path, with the NFR2 no-verbatim-echo caveat
  recorded for any future message that cites offending-line text.
- **Accepted-boundary gaps** (Low) — tighten the two documented fail-open edges
  (unterminated-leading-fence masking; prose-only / after-entry foreign content),
  pinned today by TC-8/TC-9.

### Action 3 — Land on main
On user approval at retrospective: squash the task branch to a single commit and
fast-forward `main`. Distribution to installed repos is via `cwf-manage update`,
which re-verifies the refreshed `script-hashes.json` entries on pull.

## Monitoring
### Key Metrics
- **Correctness**: `cwf-manage validate` reports OK on this repo and on any repo
  that runs `cwf-manage update`; sha256 entries for both edited files verify.
- **Behavioural**: a foreign-format `BACKLOG.md` now fails `validate` with
  `BACKLOG-000` and the four mutation subcommands refuse it (the intended,
  observable change); a conformant file is unaffected.
- **Regression signal**: the existing backlog/changelog round-trip and
  `backlog-manager.t` / `backlog-tree-validate.t` suites.

### Alerting
N/A — no runtime service. A regression surfaces as a failing test in `prove -lr t/`
or a non-OK `cwf-manage validate`, both run by maintainers and by the
installed-side update verification.

## Rollback Plan
### Triggers
- A conformant `BACKLOG.md`/`CHANGELOG.md` is wrongly rejected by `BACKLOG-000`
  (false positive blocking legitimate mutations).
- `cwf-manage validate` fails post-update for an sha256 reason traceable to the
  two refreshed entries.

### Procedure
1. **Immediate**: identify the false-positive input; confirm against TC-1…TC-15.
2. **Rollback**: `git revert` the squashed Task-190 commit on `main` (additive,
   no migration); installed copies use `cwf-manage rollback`.
3. **Communication**: note in CHANGELOG; the retired seed item can be re-opened.
4. **Analysis**: capture the misclassified input as a new test case before re-landing.

## Success Criteria
- [x] Seed backlog item retired to CHANGELOG against Task 190
- [x] Follow-up items filed (KD5 parity; accepted-boundary gaps)
- [x] `backlog-manager validate --all` clean after all backlog mutations
- [x] Rollback procedure documented (single revert; additive change)
- [ ] Landed on `main` (human-run squash-merge at retrospective)

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Rollout actions executed in-step: seed item retired (High 2→1), two follow-ups
filed (Medium 17→18, Low 63→64), backlog validates clean. Landing on `main` is
deferred to the human-run merge suggested at retrospective.

## Lessons Learned
*To be captured during retrospective*
