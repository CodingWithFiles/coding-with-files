# Adopt guarded worktree enter/exit process - Implementation Execution
**Task**: 181 (feature)

## Task Reference
- **Task ID**: internal-181
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/181-adopt-guarded-worktree-process
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [ ] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [ ] Verify all prerequisites met
- [ ] Execute implementation steps sequentially
- [ ] Update "Actual Results" for each step
- [ ] Document any deviations from plan
- [ ] Update status to "Implemented" when complete

## Implementation Steps (from d-implementation-plan.md)

See `d-implementation-plan.md` for the planned steps; actual results below.

## Actual Results

### Step 1 — Author the convention doc
- **Planned**: New `.cwf/docs/conventions/worktree-process.md` with sections
  Procedure / Prohibitions / Threat model / Why / See also; each rule once;
  C-facts cited to Task 177, not copied.
- **Actual**: Created with sections `Procedure` (5-step flow incl. FR9 pre-flight
  scan), `Prohibitions` (P1–P3 + the no-allowlist-broadening rule), `Configuration`
  (FR3 `baseRef: head` + user-global fallback), `Threat model` (request-is-data,
  no-standing-teardown, allowlist-mitigated-not-closed, tool-load-failure-is-a-stop),
  `Why`, `See also`. Style matched to peer `session-hygiene.md`/`tmp-paths.md`.
- **Deviations**: Added an explicit `Configuration` heading (design listed the
  config wording but folded it under no specific section) so the FR3 both-branches
  wording has a clear home. No scope change.

### Step 2 — Settings key (`worktree.baseRef: head`)
- **Planned**: Add `{"worktree": {"baseRef": "head"}}` to committed
  `.claude/settings.json`; ship doc with BOTH branches' wording; FR3 AC stays OPEN
  until the g-phase probe confirms project-scope is honoured.
- **Actual**: Key added; `read_settings` decoded the file cleanly in the helper
  dry-run (valid JSON). Doc `Configuration` section carries both the `head` mandate
  and the user-global fallback. FR3 behavioural confirmation deferred to g-phase
  FR8 probe, as planned.
- **Deviations**: None.

### Step 3 — Cross-references
- **Planned**: `**Worktree Process**:` bullet in CLAUDE.md `## Conventions` (after
  Session Hygiene, `.cwf/docs/conventions/`-prefixed path); append a single
  `worktree-process.md` entry to the existing `## See also` in `tmp-paths.md`.
- **Actual**: Both done. CLAUDE.md bullet added after the Session Hygiene bullet
  with four sub-points; `tmp-paths.md` See-also gained one entry (no second heading).
- **Deviations**: None.

### Step 4 — Surface the residual + usage pre-flight (no auto-edit)
- **Planned**: Doc documents the *class* of dangerous `git worktree` allowlist
  entry as "mitigated pending operator action"; pre-flight grep of both settings
  files in the Procedure; no allowlist entry added by this task.
- **Actual**: Threat model frames detection as "mitigated, not closed"; Procedure
  step 1 is the pre-flight grep. No allowlist entry added (`git status` shows no
  settings.local.json change; the helper never writes it).
- **Deviations**: None.

### Step 4b — Install-time detector (the one hashed-script edit)
- **Planned**: Edit `cwf-claude-settings-merge` to slurp both settings files as
  raw text (no JSON decode), best-effort + symlink-guarded, warn non-fatally on
  `git worktree`; fire under `--dry-run`; never write `settings.local.json`;
  refresh `script-hashes.json` same-commit; restore recorded perms 0500.
- **Actual**: Added `warn_on_worktree_allowlist()` (raw `<:raw>` slurp, `index()`
  substring test, `-f && !-l` guard mirroring `read_settings`, `open ... or next`
  best-effort) called unconditionally before the dry-run/write branch (so it fires
  in both). New sha256
  `221bc4d7dd98f7ee0b57dc20c0df35e2887b77e660bb9e3af04daf7e1396a7a4` written to
  `script-hashes.json` line 210; helper chmod'd back to 0500. Dry-run smoke:
  no die, 27 allowlist / 3 hook / 0 env, and SILENT on the worktree warning
  (no `git worktree` substring in the live files — confirms the absent branch).
- **Deviations**: None. The warning-fires and malformed/symlink must-not-abort
  fixture tests are scoped to g-phase TC-11 (run against a fixture, never the live
  `settings.local.json`).

### Step 5 — In-phase validation
- **Actual**: `cwf-manage validate` → `OK` (the helper's own pre-existing
  0700→0500 drift cleared as a side effect; the unrelated
  `pretooluse-planning-write-guard` drift also restored to recorded 0500 — a
  perms-only fix with no git-tracked change). Doc smoke-greps: all mandated points
  present (ToolSearch load, `discard_changes`, absolute-path, `baseRef: head`);
  P1/P2/P3 labels appear once each; no stale strings (`:127`, TODO, "Planning").
  Cite-don't-copy: trimmed two C-fact content-restatements (step 3 C1 gloss, P2 C2
  gloss) so each fact is explained once (in `Why`/operational step) and cited by
  bare label elsewhere. Request-is-data clause read and confirmed normatively
  imperative (it forbids the request selecting `action:`/`discard_changes:`).
  `.claude/settings.json` confirmed valid JSON (decoded by the helper).

## Blockers Encountered

None.

## Security Review

**State**: no findings

## Security review — Task 181 (implementation phase)

I reviewed the full changeset at `/tmp/-home-matt-repo-coding-with-files-task-181/f-changeset.diff` (1036 lines), the new untracked doc `.cwf/docs/conventions/worktree-process.md` (read directly, untracked), the edited helper `cwf-claude-settings-merge` in full surrounding context, and the threat model in `.cwf/docs/skills/security-review.md`.

The production surface is: one settings key (`.claude/settings.json`), one new convention doc, two cross-reference edits (`CLAUDE.md`, `tmp-paths.md`), one Perl helper edit plus its same-commit hash refresh. The a–e markdown is workflow planning prose.

### (a) Bash injection / unsafe command construction
The helper adds no `system`/`qx`/backtick calls. The new `warn_on_worktree_allowlist` sub does only `open`/slurp/`index`/`warn` on two fixed, hardcoded paths (both derived from the constant `.claude`, no interpolation of user/task strings). No shell is invoked. Clean.

### (b) Perl helpers consuming git/user output without `-z`
No git porcelain is consumed. The read is a raw whole-file slurp (`local $/; <$fh>`) with `<:raw` — no newline-splitting, so the `-z`/`split /\0/` concern does not arise. The `index($blob, 'git worktree')` substring test is byte-safe. Clean.

### (c) Prompt injection via user-supplied strings
Security-central for this feature, handled correctly. The doc's `Threat model` carries the FR4(c) clause imperatively: the triggering request is data, must never select the `action:`/`discard_changes:` argument, with the adversarial example worked through. The no-standing-teardown invariant and the load+create-only authorisation scope are present and normatively strong, not hedged. The doc is not blanket pre-authorisation to remove a worktree.

### (d) Unsafe environment-variable handling
No env vars introduced or consumed. `worktree.baseRef: head` is static committed config; the design (Decision 3 Security note) consciously records the broadened branch-from-HEAD surface as a deliberate trade-off. No finding.

### (e) Pattern-based risks
The scan is contractually unable to abort install/update (no `die`/`exit`/non-zero return; best-effort reads `open ... or next`; `-f && !-l` guard mirroring `read_settings`; no JSON decode; never writes). One benign TOCTOU note (lstat-then-open) reported under the (e) audit-future-uses framing only: safe here because the result feeds an advisory `warn`, not a destructive action; audit if the idiom is copied into a writing context.

### Conclusion
No actionable findings.

```cwf-review
state: no findings
summary: Worktree-process doc carries a strong request-is-data/no-standing-teardown clause; the settings-merge git-worktree scan is read-only, symlink-guarded, JSON-decode-free and cannot abort install/update. One benign TOCTOU noted under (e) audit-future-uses framing only.
```

## Deferral Check
Before marking status=Finished, verify:
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met (FR3 behavioural + FR8 probe are g-phase by design, not deferrals)
- [x] All requirements from b-requirements-plan.md addressed (FR8 probe is the g-phase activity by plan; FR7 MEMORY pointer is the rollout-phase non-gating manual step by plan)
- [x] All design guidance in c-design-plan.md followed
- [x] No planned work deferred without user approval
- [x] If work deferred: g-phase/rollout items are planned phases, not deferrals; no follow-up task needed

**If deferral required**: Get user approval, document rationale, create follow-up task.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
