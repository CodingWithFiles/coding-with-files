# R3 shell-hygiene convention and allowlist seed - Maintenance
**Task**: 227 (feature)

## Task Reference
- **Task ID**: internal-227
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/227-r3-shell-hygiene-convention-and-allowlist-seed
- **Template Version**: 2.1

## Goal
Define ongoing maintenance, monitoring, and support requirements for R3 shell-hygiene convention and allowlist seed.

## Monitoring Requirements
CWF is an offline documentation/helper system — there is no uptime, latency, or on-call
surface. "Monitoring" here means the standing integrity and regression gates that a maintainer
runs, plus the one tracked open question.

### Integrity
- `cwf-manage validate` must stay OK. Two hash-tracked files carry refreshed sha256 entries
  (`cwf-claude-settings-merge`, `cwf-agent-shared-rules.md`); any future edit to either requires
  an in-same-commit hash refresh (`hash-updates.md`). A sha256 drift is surfaced, never smoothed;
  a permission drift is fixed on sight with `cwf-manage fix-security`.

### Regression
- `prove -r t/` must stay green. The load-bearing guard for this task is the fail-closed
  `is_read_only_safe` predicate in `t/cwf-claude-settings-merge.t` (TC-RO1..RO5) plus the two
  count assertions (`8` allowlist entries). If the corpus grows/shrinks, both the predicate's
  hand-authored `%SAFE_PREFIX_KEYS`/`%SAFE_EXACT_KEYS` sets **and** the count assertions must be
  updated in lockstep — the anti-tautology split is deliberate, keep the two sets independent of
  the script corpus.

### Correctness of the seed
- After a downstream `cwf-manage update`, the 5 read-only entries appear in `permissions.allow`
  and no broadened prefix leaked in (notably `git branch:*`, which the exact
  `git branch --show-current` entry deliberately avoids).

## Maintenance Tasks
### Corpus curation (the primary ongoing task)
- The read-only allowlist is a curated compile-time constant. Adding an entry is a code change,
  not config: it must be read-only for its **whole** `:*` glob space (or pinned exact), pass the
  independent test gate, and be justified against the excluded-near-neighbour table in
  `shell-hygiene.md`. Never source the corpus from a probe or manifest (FR4(e)).
- Removal/opt-out is a downstream concern: a user/`.local`-layer `deny`/`ask` rule wins by
  precedence — documented in `shell-hygiene.md`. Deleting the committed entry is transient
  (re-seeded on next merge); the `.local` override is durable.

### Preventive
- Dead-code audit (see `.cwf/docs/dead-code-audit.md`) — periodic sweep; low risk here (one
  constant + one push).
- Re-verify the harness-matching caveat if Claude Code's permission docs change (see open item).

## Incident Response
### Common Issues
- **`validate` fails after editing the helper or shared-rules doc**: expected stale-hash signal.
  Resolution: refresh the sha256 in the same commit, verify independently with `sha256sum`.
  (This exact signal fired transiently during phase f and was resolved by the Step-4 refresh.)
- **A corpus entry admits a mutating command**: e.g. a prefix that turns out to cover a
  write subcommand. Resolution: pin it exact or drop it; add a negative control to TC-RO1.
- **Downstream user wants the seed off**: not a defect — point them at the `deny`/`ask`
  opt-out in `shell-hygiene.md`.

### Troubleshooting Guide
- **Symptom**: red `t/` run touching `cwf-claude-settings-merge.t`. **Diagnosis**: count assertion
  vs. actual seed size, or a predicate-set mismatch. **Resolution**: reconcile corpus size with the
  `8`-entry assertions and the two SAFE sets; re-run `prove t/cwf-claude-settings-merge.t`.

## Open Maintenance Item
- **Redirection/command-substitution auto-approval (harness residual)**: undocumented whether a
  `Bash(<verb>:*)` allow rule auto-approves `verb > f` / `verb $(…)`. Pre-existing and
  harness-wide (affects every `allow` entry, not just this corpus). Tracked as a Medium discovery
  backlog item; `shell-hygiene.md` carries the caveat. Revisit if the permission docs gain a
  definitive statement.

## Documentation
- Runbook for this feature is the "Common Issues" + "Troubleshooting" above; the authoritative
  convention is `shell-hygiene.md` (linked from `cwf-agent-shared-rules.md` FR3 anchor and this
  repo's `CLAUDE.md`).

## Success Criteria
- [x] Monitoring surface defined (integrity `validate`, regression `t/`, seed correctness) — no
      live SLA surface applies to an offline docs/helper system
- [x] Maintenance procedures documented (corpus-curation rules, dead-code audit)
- [x] Common issues documented with resolutions
- [x] Open item tracked (redirection/substitution residual → backlog)
- [x] Next steps suggested

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
No live maintenance surface exists for an offline docs/helper system; maintenance reduces to the
standing integrity (`cwf-manage validate`) and regression (`prove -r t/`) gates plus corpus
curation discipline. All gates are green as of task completion. The single open item — the
undocumented harness redirection/substitution behaviour — is tracked as a Medium backlog
discovery item rather than left implicit.

## Lessons Learned
- The meaningful "maintenance" for a curated security allowlist is the curation contract itself:
  every future corpus change must clear the same read-only + independent-test-gate + near-neighbour
  bar, and the anti-tautology split (SAFE sets authored independently of the corpus) must be kept
  intentionally — that is the invariant a future maintainer is most likely to erode.
