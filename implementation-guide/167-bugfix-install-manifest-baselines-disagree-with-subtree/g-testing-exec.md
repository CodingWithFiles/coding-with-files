# install manifest baselines disagree with subtree - Testing Execution
**Task**: 167 (bugfix)

## Task Reference
- **Task ID**: internal-167
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/167-install-manifest-baselines-disagree-with-subtree
- **Template Version**: 2.1

## Goal
Run every validation gate listed in `e-testing-plan.md` §Validation
Criteria against the post-fix tree (commit `47ba0fa`), record results,
and surface any failures.

## Execution Environment
- Branch: `bugfix/167-install-manifest-baselines-disagree-with-subtree`
- HEAD: `47ba0fa` (f-phase checkpoint)
- Perl: system Perl per `t/` convention (core modules only)
- Wall clock: ~30s for the full sweep

## Test Execution Results

### Gate 1 — TC-SANITY + TC-INV1 + TC-INV2 (focused new-test run)

```
prove -v t/installmanifest-integrity.t
```

| Subtest | Expected | Actual |
|---|---|---|
| #1 manifest has at least one artefact (sanity floor) | PASS | PASS |
| #2 INV-1: cwf-rules-bundle / cwf-workflow-files.md | PASS | PASS |
| #3 INV-1: claude-md-preamble | PASS | PASS |
| #4 INV-2: gitignore-entries dest not under .cwf/ | PASS | PASS |
| #5 INV-2: cwf-rules-bundle dest not under .cwf/ | PASS | PASS |
| #6 INV-2: claude-md-preamble container not under .cwf/ | PASS | PASS |

Files=1, Tests=6, all PASS. Wall time <1s.

**Fail-on-HEAD verification** (recorded during f-exec): pre-fix, the
INV-2 subtest then numbered #6 (covering `rules-inject`) failed
exactly as the design predicted, with the expected match against
`\A\.cwf/`. Captured to
`/tmp/-home-matt-repo-coding-with-files-task-167/test-fail-pre-fix.txt`.
This is the proof that the regression check meaningfully catches the
historical defect.

### Gate 2 — TC-RI-PRESERVED + TC-CMU-* + TC-E2E-* + TC-IBR-* (directly affected files)

```
prove t/cwf-apply-artefacts.t t/cwf-manage-update.t \
      t/cwf-manage-update-end-to-end.t t/install-bash-reinstall.t
```

| Test file | Subtests | Result |
|---|---|---|
| `t/cwf-apply-artefacts.t` | 13 (post-retirement of TC-RI-1..3, TC-FR5-KEEP, TC-FR5-NEW per Deviation A in f-exec) | PASS |
| `t/cwf-manage-update.t` | unchanged | PASS |
| `t/cwf-manage-update-end-to-end.t` | unchanged | PASS |
| `t/install-bash-reinstall.t` | unchanged (incl. TC-IBR-1 line-174 assertion `ok(-s ".cwf/rules-inject.txt")` — confirms AC5) | PASS |

Files=4, Tests=42, all PASS.

### Gate 3 — TC-FULL-SWEEP (sibling-test regression)

```
prove -r t/
```

Files=53, **Tests=619, all PASS**. Wall time 29s. No sibling-test
regressions introduced by the rules-inject removal or the test
retirements documented in f-exec Deviation A.

### Gate 4 — TC-VALIDATE (`cwf-manage validate` clean)

```
.cwf/scripts/cwf-manage validate
```

Output: `[CWF] validate: OK`. All four hash refreshes from f-exec
Step 9 verified, including the deletion of the
`data."rules-inject-template"` entry.

### Gate 5 — TC-NO-STRAY (`git grep` audit)

```
git grep -nE 'rules-inject' -- ':!t/' ':!implementation-guide/' \
                                ':!CHANGELOG.md' ':!BACKLOG.md'
```

Five legitimate references remain:
- `.claude/skills/cwf-init/SKILL.md:98` — hook description (still
  correct: hook reads the subtree-shipped file).
- `.claude/skills/cwf-init/SKILL.md:116` — hook command itself
  (still operational against the subtree-shipped file).
- `.cwf/docs/glossary.md:21,93,111` — "rules injection" glossary
  entry (the feature still exists; only the dual-distribution wiring
  was removed).

No stray references in production code or scripts. The remaining hits
match exactly the §Validation Criteria expectation
("SKILL.md line 116 hook command + the file itself; possibly
Task 99/158 retrospective docs"). The retrospective-doc hits are
hidden by the `:!implementation-guide/` pathspec.

## §Mapping Coverage Audit

Every row of the e-plan §Mapping table is bound to a passing gate:

| AC / Validation bullet | Gate that covered it | Result |
|---|---|---|
| AC1 source-SHA agreement | Gate 1 (INV-1 subtests 2-3) | PASS |
| AC2 dev-time drift visibility | Gate 1 (all 6 subtests) | PASS |
| AC3 non-interactive update no longer aborts | Gate 1 (INV-2 schema rule) + Gate 2 (e2e helper-level) + Gate 5 (no stray refs in update code path) | PASS |
| AC4 validate clean + hash refresh in same commit | Gate 4 + manual review of commit 47ba0fa | PASS |
| AC5 rules-inject.txt populated post-update | Gate 2 (`t/install-bash-reinstall.t` line 174) | PASS |
| D1 applied (manifest entry removed) | Gate 1 INV-2 (trivially satisfied) + Gate 5 | PASS |
| D2 applied (14 cleanups) | Gate 5 + Gate 3 | PASS |
| D3 applied (test exists and passes) | Gate 1 itself | PASS |
| D4 honoured (apply_replace machinery preserved; TC-RI scope retired per Deviation A) | Gate 2 (apply-artefacts file overall PASS) | PASS¹ |
| D5 satisfied (single commit) | `git show 47ba0fa` — 11 files in one commit | PASS |
| `prove -r t/` green | Gate 3 | PASS |
| Reproducer | Hard-deferred per e-plan §Reproducer Scope Decision | n/a |

¹ D4 originally said "TC-RI-1..5 + TC-FR5-* fixtures preserved
unchanged". Five subtests (TC-RI-1..3, TC-FR5-KEEP, TC-FR5-NEW) were
retired in f-exec Deviation A by user choice — they were the ones
specifically exercising the rules-inject inventory row. The apply_replace
strategy machinery itself is preserved in the helper; coverage of
`CWF_UPGRADE_RESOLVE=keep/new` is tracked as a Low-priority BACKLOG
follow-up. The honour-D4 spirit ("preserve machinery, retire only the
specifically rules-inject-coupled fixtures") is upheld.

## Non-Functional Verification

- **Performance**: New test wall-clock 0.04s CPU as planned (<1s budget).
  Full suite at 29s — no degradation vs pre-fix baseline.
- **Security**: Allowlist contraction in `Validate/Security.pm` and
  `cwf-apply-artefacts` is strictly tightening; hash refresh landed
  in-commit per `[[hash-updates]]`. The f-phase security-review
  subagent verdict on the implementation changeset was
  `state: no findings`.
- **Usability**: `cwf-manage update` no longer aborts on the
  rules-inject conflict for consumers updating from any prior
  version. The bug-reporting consumer's specific failure (v1.1.155 →
  v1.1.163 abort) is fixed at the source-of-truth manifest level.
- **Reliability**: INV-2 codifies the architectural rule. Any future
  attempt to re-introduce a `dest` or `container` under `.cwf/` (for
  any artefact `kind`) trips the test at PR review.

## Coverage Metrics

- New code: `t/installmanifest-integrity.t` — 89 lines, 6 subtests,
  asserts over every artefact in the live manifest (3 artefacts have
  source SHAs to check; all 4 with dest/container fields covered by
  INV-2). 100% of artefacts in the shipped manifest are covered by
  at least one subtest.
- Test deletions: 5 subtests retired in f-exec Deviation A. Net delta:
  `+6 new − 5 retired = +1 subtest` (and the new ones exercise an
  invariant the retired ones did not).

## Blockers Encountered

None. All five gates passed on the first run against `47ba0fa`. No
follow-on iteration required.

## Deferral Check

- [x] All test cases from `e-testing-plan.md` executed.
- [x] All failures documented (none — all PASS).
- [x] Coverage targets met (100% of shipped artefacts covered).
- [x] No tests skipped or disabled.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 167
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
- An invariant test that fails on HEAD before a fix is applied is the
  strongest evidence that the test is meaningful. INV-2 caught the
  defect on the unmodified tree, exactly as the design predicted.
- Validation gates that lean on existing test files for transitive
  coverage (Gates 2-3 here) save substantial fixture plumbing without
  weakening the assertions — the existing suite already drives the
  same code path the bug-reporting consumer hit.
- The §Reproducer Scope Decision in e-plan was vindicated: a literal
  v1.1.155 → post-fix e2e reproducer would have added ~60 lines of
  git-historical fixture plumbing, and the same defect mode is now
  guarded by INV-2 at the schema level (where the bug actually lived).

## Security Review

**State**: no findings

Now I'll review this changeset for security concerns.

## Security Review

This is a testing-phase changeset that:
1. Removes the `rules-inject` artefact from the install-manifest inventory (in `cwf-apply-artefacts`, `CWF::Validate::Security`, `cwf-manage`, the empty template file, and `cwf-init` SKILL.md docs).
2. Retires the three `rules-inject` subtests (TC-RI-1/2/3) and the two `CWF_UPGRADE_RESOLVE=keep/new` subtests in `t/cwf-apply-artefacts.t`.
3. Adds a new test file `t/installmanifest-integrity.t` enforcing two invariants over `.cwf/install-manifest.json` (INV-1: source-sha matches; INV-2: no `dest`/`container` under `.cwf/`).

I worked through the threat categories:

(a) **Secrets/PII**: No secrets, tokens, keys, or PII introduced. The test file does read `.cwf/install-manifest.json` raw and slurp source files, but only project-tracked files under `$REPO/`. No `.env` or credential handling here. The redact pattern `qr/\.env(?:\..*)?$/` in `cwf-apply-artefacts` remains untouched.

(b) **Injection / unsafe interpolation / path traversal**: The new test composes paths as `"$REPO/$a->{source}"` and `"$REPO/$a->{source}$rel"` from manifest values. The test file's header comment explicitly addresses this trust boundary: the manifest is hash-tracked in `.cwf/security/script-hashes.json` and integrity-checked by `cwf-manage validate`, so the inputs are trusted. The `-f $abs` guard plus `SKIP` keeps the test from blowing up on a missing file but does not perform allowlist validation. This is acceptable for a developer-machine `prove` test over a trusted manifest, and the header documents the constraint clearly — including the "do NOT copy this pattern" warning. No `system`/`exec`/backticks/`open '|-'` are introduced. Removed code paths shrink the attack surface (one fewer allowed dest prefix in `validate_write_path_allowlist`).

(c) **Authn/authz, privilege, sandbox bypass**: No changes to permissions, hooks, sudo, suid, or settings.json merging. The `validate_write_path_allowlist` allowlist becomes strictly tighter (removed `.cwf/rules-inject.txt`) — a defense-in-depth improvement. INV-2 in the new test is itself a defensive guard against future manifests that would let `apply-artefacts` write into `.cwf/`, which is the subtree that ships hashed scripts; routing arbitrary writes there would conflict with the `cwf-manage validate` trust boundary. This is a genuine security-relevant invariant, well placed.

(d) **Crypto / data integrity**: `Digest::SHA::sha256_hex` is core Perl, used correctly with `<:raw>` slurp — no encoding-induced mismatch. INV-1 strengthens the integrity story by detecting manifest/source drift (the exact Task-167-class defect). The audit log line `rules-inject.txt updated (was $old_sha, now $new_sha)` is removed, but it was specific to a now-deleted artefact — no other audit logging is weakened. Hash refresh discipline (`docs/conventions/hash-updates.md`) appears respected: this changeset only edits the test files, SKILL.md, and Perl code; `script-hashes.json` updates should be folded in the same commit per the standing rule but that's an implementation concern outside this testing-phase diff.

(e) **Patterns risky if reused**:
- Pattern: trusting a manifest's path field as input to filesystem reads. Safe here because the manifest is hash-tracked and the test is developer-side. Audit future uses where the manifest could be supplied by an untrusted source (e.g. a future "import third-party manifest" feature) — there the `validate_write_path_allowlist` machinery in `CWF::ArtefactHelpers` (as the header notes) must be used.
- Pattern: `SKIP` blocks that silently skip when a referenced file is missing. Acceptable for forward-compat in a manifest-integrity test, but in a stricter security context it would mask a tampering signal (missing file == "all good"). Per the standing "surface, never smooth" rule ([[feedback-surface-security-dont-smooth]]), audit future copies — if this test were repurposed to gate something security-relevant (e.g. release CI), the SKIP should become a hard `fail()` so an attacker-removed file can't pass silently. In its current scope (developer `prove`, with `cwf-manage validate` as the actual integrity gate), it's fine.

Net effect: the change is a documentation/feature removal with a corresponding test-surface contraction, plus the addition of a defense-in-depth invariant test. No new attack surface; the allowlist becomes tighter; the new test is a positive security signal. The retired `keep`/`new` resolve-branch coverage is honestly disclosed in the in-file comment and recorded as a BACKLOG follow-up.

Relevant files:
- `/home/matt/repo/coding-with-files/t/installmanifest-integrity.t`
- `/home/matt/repo/coding-with-files/t/cwf-apply-artefacts.t`
- `/home/matt/repo/coding-with-files/.cwf/scripts/command-helpers/cwf-apply-artefacts`
- `/home/matt/repo/coding-with-files/.cwf/lib/CWF/Validate/Security.pm`
- `/home/matt/repo/coding-with-files/.cwf/scripts/cwf-manage`
- `/home/matt/repo/coding-with-files/.claude/skills/cwf-init/SKILL.md`

```cwf-review
state: no findings
summary: rules-inject artefact removal tightens write allowlist; new manifest-integrity test adds INV-1/INV-2 defense-in-depth with appropriate trust-boundary documentation. No new attack surface.
```

