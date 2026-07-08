# Seed exclude-path defaults, raise review cap 1000 - Rollout
**Task**: 221 (feature)

## Task Reference
- **Task ID**: internal-221
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/221-seed-exclude-path-defaults-raise-review-cap-1000
- **Template Version**: 2.1

## Goal
Ship the seeded `security.review.max-lines-exclude-paths` template default and the
built-in cap bump (500→1000) to CWF users. CWF is a file-based system distributed by
git tag + `cwf-manage update`; "rollout" is a tagged release, not a server deployment.

## Deployment Strategy
### Release Type
- **Strategy**: Single tagged release on `main` (`v1.1.221`), pulled by installs via
  `cwf-manage update`. No phased/canary/blue-green — every consumer takes the whole
  file set atomically at update time. There is no runtime service to canary.
- **Rationale**: The change is two static edits — a raised numeric default in one
  helper and a new seed block in the config template. Neither has a partial-rollout
  surface; a consumer either has the new files or the old ones.
- **Rollback Plan**: `cwf-manage rollback` to the prior release, or pin
  `security.review.max-lines: 500` in `cwf-project.json` to restore the old cap
  without touching the install. Both are per-install and reversible.

### Reach — who actually sees each half
- **Cap bump (built-in default → 1000)**: reaches **every** updating install
  immediately, including those with no `security.review` config, since it is a
  code-level constant fallback. This is the security-relevant half (see disclosure).
- **Template seed (exclude-paths defaults)**: reaches **new inits only**.
  `cwf-init` does not overwrite an existing `cwf-project.json`, so existing installs
  keep their current excludes until they opt in by hand. No silent config rewrite.

### Pre-Deployment Checklist
- [x] Code review completed — 7 reviewer runs across f/g (5 impl + 2 test); one
      best-practice finding raised and resolved (guardrail pipe-close false-PASS)
- [x] All tests passing — `prove -l t/`: 75 files, 979 tests, 0 failures
- [x] Security review completed — no findings; fail-open tradeoffs deliberate and
      surfaced (note / spec / this rollout), not smoothed
- [x] Performance validated — pathspec pass-through + one integer compare; no cost
- [x] Documentation updated — `security-review.md`, `CWF-PROJECT-SPEC.md`, template
      `_security-review-note`
- [x] Integrity refreshed — `security-review-changeset` sha256 refreshed same-commit;
      `cwf-manage validate` → OK
- [x] Rollback path confirmed — `cwf-manage rollback` + per-install `max-lines` pin

## Rollout Plan
Single release; no user cohorts.
- **Phase 1 — tag & release** *(human-only)*: maintainer squashes the task branch,
  fast-forwards `main`, tags `v1.1.221`, cuts the GitHub release. Models must not
  tag, push tags, or merge to main.
- **Phase 2 — propagation**: installs pick up the change on their next
  `cwf-manage update`; `validate` confirms hash integrity post-update.
- **Phase 3 — steady state**: new `cwf-init` runs inherit the seeded excludes; the
  raised cap is live for all updated installs.

## Security Disclosure — cap loosening (surface, never smooth)
Raising the built-in default from 500 to 1000 **relaxes** the review-invocation cap
for any install that relies on the built-in default (no explicit
`security.review.max-lines`). A changeset of 501–1000 production lines that previously
**exceeded** the cap — skipping the auto-review subagent (exit 2) — will now fall
**under** it and be auto-reviewed. That is the intended direction (more gets reviewed,
not less), and it is the safe direction: the cap gates *invocation*, and a larger cap
means more changesets are small enough to review rather than being skipped.

The residual risk is only that a very large changeset (≤1000 lines) now goes to a
single review pass where an operator previously got an explicit "too big, split it"
signal at 500. **Mitigation**: an install wanting the old ceiling pins
`security.review.max-lines: 500` in `cwf-project.json` — the explicit key always wins
over the built-in default. This is called out in the release notes and the spec.

The seeded markdown discount (`*.md`, `docs/**/*.md`) is likewise surfaced in the
template `_security-review-note`: excluded paths are still **fully reviewed** — the
cap gates invocation, not content — so discounting markdown keeps a large
adversarial-markdown changeset *under* the cap and therefore still auto-reviewed.

## Monitoring
File-based system; no telemetry. Post-release signals:
- **Integrity**: `cwf-manage validate` on updated installs → OK (hash matches).
- **Regression**: `prove -l t/` green on `main` at the release tag.
- **Field signal**: reviewer-skip (exit 2) should become rarer for long-baseline
  tasks; a rise in single-pass reviews of near-1000-line changesets is the expected,
  accepted effect of the cap bump.

## Rollback Plan
### Triggers
- `cwf-manage validate` reports a hash mismatch after update (integrity failure)
- A seeded exclude glob is found to discount a security-sensitive path (FR3 breach)
- An install needs the stricter 500 ceiling restored

### Procedure
1. **Per-install cap restore** (no rollback): set `security.review.max-lines: 500` in
   `cwf-project.json`. Immediate, reversible, install-local.
2. **Full rollback**: `cwf-manage rollback` to the prior release; `validate` to
   confirm. Existing `cwf-project.json` excludes are untouched by rollback.
3. **Communication**: note in CHANGELOG / release notes if a re-release is needed.
4. **Analysis**: fold any FR3 breach into a follow-up task with a new guardrail case.

## Success Criteria
- [x] Deployment strategy defined with rationale (tagged release, no phasing)
- [x] Pre-deployment checklist completed (tests, review, integrity, docs)
- [x] Rollout plan specified (tag → propagate → steady state)
- [x] Rollback plan documented (per-install pin + `cwf-manage rollback`)
- [x] Cap-loosening security disclosure surfaced with mitigation

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Rollout documented. Release itself (squash, ff `main`, tag `v1.1.221`, GitHub
release) is a human-only action and is **not** performed here. All pre-deployment
gates green: 979 tests pass, `cwf-manage validate` OK, 7 reviewer runs recorded.

## Lessons Learned
*To be captured during retrospective*
