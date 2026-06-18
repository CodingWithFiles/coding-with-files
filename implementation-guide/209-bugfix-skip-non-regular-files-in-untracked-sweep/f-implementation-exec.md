# Skip non-regular files in untracked sweep - Implementation Execution
**Task**: 209 (bugfix)

## Task Reference
- **Task ID**: internal-209
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/209-skip-non-regular-files-in-untracked-sweep
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

## Actual Results

### Step 1: Core change
- **Planned**: filter `list_untracked_files()` return to `grep { -f $_ || -l $_ }`.
- **Actual**: applied at `security-review-changeset:504-514` with the rationale
  comment (git-indexable types, char-device bind-mount trigger, `-l`/lstat
  retention, sibling `stop-stale-status-detector` divergence). No deviation.

### Step 2: Tests (red-then-green)
- **Planned**: TC-209-1 (portable symlink retention) + TC-209-2 (Linux-gated
  char-device via `unshare -rm`); confirm red on unpatched, green after.
- **Actual**: both added to `t/security-review-changeset.t` before
  `done_testing()`.
  - **Red** (unpatched helper): TC-209-2 failed — `helper exits 0` was `not ok`
    (helper exited 1, the reported abort) and the sibling file was not reviewed
    (sweep aborted before writing a changeset). The setup marker was present, so
    this was a genuine reproduction, not a SKIP. TC-209-1 passed pre-fix (the
    forward guard — symlinks were never filtered).
  - **Green** (patched helper): full `t/security-review-changeset.t` → 49/49
    pass, including TC-209-1, TC-209-2, and TC-VALIDATE.
- **Deviation**: TC-209-2 runs the helper inside the namespace via an
  env-parameterised `unshare -rm sh -c '…'` with a post-mount marker file; a
  missing marker SKIPs (env without unprivileged userns/bind-mount) so it is
  never confused with the pre-fix exit-1 abort. This is the concrete shape of
  the e-plan's "probe + SKIP" requirement.

### Step 3: Hash refresh (same commit)
- **Planned**: pre-refresh `git log` verify → sha256 update → chmod recorded →
  validate.
- **Actual**:
  - `git log e06185f..HEAD -- …/security-review-changeset` → empty (Task 206 is
    the clean last hash-set; this task's edit is the only change — no drift).
  - sha256 `489ac0…` → `76415b…`; updated `script-hashes.json:353`.
  - chmod 0500 (recorded ceiling, not bumped); `cwf-manage validate` → OK.
- **Deviation**: none.

### Wider validation
- `prove t/validate-perl-conventions.t t/validate-security.t
  t/validate-security-coverage.t` → all pass.

## Blockers Encountered

None.

## Security Review

**State**: no findings

Security review — Task 209 changeset (implementation-exec). The functional
change is a single Perl filetest filter (`grep { -f $_ || -l $_ } @paths`) in
`list_untracked_files()`. FR4 scan: (a) no command construction added — all git
calls list-form, the test's `system($unshare,'-rm','sh','-c',$script)` is
list-form with paths passed via `local $ENV{...}` (no interpolation); (b) `-z`
parsing intact, filter runs on the already-split list; (c) no `{arguments}`
surface, no new untrusted-string flow; (d) no production env-var handling; (e)
the lstat/TOCTOU window is benign (gates composition, not a trust boundary) and
already documented inline with the correct "audit future uses" framing. The
filter cannot silently shrink the review surface — only char/block devices,
fifos and sockets are dropped (no diffable content); regular files and symlinks
are retained. `script-hashes.json` change is `cwf-manage validate`'s domain.

```cwf-review
state: no findings
summary: Pure Perl filetest filter on untracked paths; list-form git/system preserved, -z parsing intact, no new untrusted-string or env flow; benign TOCTOU already documented with correct audit-future-uses framing.
```

## Best-Practice Review

**State**: no findings

The resolved best-practice corpora are `golang` and `postgres` (off-domain for a
Perl/JSON/Markdown changeset). Both source directories were readable (not an
error condition); no supplied practice applies to this diff. (Recurring note:
`best-practice-resolve` keeps tag-matching off-domain corpora for this task —
worth a separate look at the resolver, out of scope here.)

```cwf-review
state: no findings
summary: Sources are Go and PostgreSQL best-practice corpora; changeset is Perl/JSON/Markdown with no Go or SQL content, so no supplied practice applies.
```

## Deferral Check
Before marking status=Finished, verify:
- [ ] All steps from d-implementation-plan.md executed
- [ ] All success criteria from a-task-plan.md met
- [ ] All requirements from b-requirements-plan.md addressed (if applicable)
- [ ] All design guidance in c-design-plan.md followed (if applicable)
- [ ] No planned work deferred without user approval
- [ ] If work deferred: Follow-up task created and linked

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
