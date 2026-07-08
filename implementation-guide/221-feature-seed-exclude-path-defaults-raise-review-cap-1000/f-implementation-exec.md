# Seed exclude-path defaults, raise review cap 1000 - Implementation Execution
**Task**: 221 (feature)

## Task Reference
- **Task ID**: internal-221
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/221-seed-exclude-path-defaults-raise-review-cap-1000
- **Template Version**: 2.1

## Goal
Execute d-implementation-plan.md / e-testing-plan.md: seed a generic
`security.review.max-lines-exclude-paths` default into the template, raise the
built-in cap 500→1000, dog-food the new default, and sync docs + tests.

## Actual Results

### Step 1: Cap bump (helper) — done
`.cwf/scripts/command-helpers/security-review-changeset`, all four `500` sites:
- `:101` `$DEFAULT_MAX_LINES = 500 → 1000` (live constant).
- `:32` header banner `built-in default (500) → (1000)`.
- `:316` comment `(default 500) → (default 1000)`.
- `:100` reworded to drop the hardcoded literal (`hand-maintained "500" literal`
  → `hand-maintained numeric literal`) — removes the drift point rather than
  re-pinning it.
`grep 500` on the helper now returns nothing; the three surviving `1000` sites are
the intended ones.

### Step 2: Seed the template — done
`.cwf/templates/cwf-project.json.template`: added `_security-review-note` +
`security.review.max-lines-exclude-paths` (18 generic globs) after `sandbox`,
mirroring `_sandbox-note`/`sandbox`. The note surfaces the markdown-discount
prompt-injection trade-off explicitly (surface, never smooth). `max-lines` is NOT
seeded (design D2). Template still parses (`t/cwf-project-template.t` green).

### Step 3: Dog-food + docs — done
- `implementation-guide/cwf-project.json`: removed the now-redundant
  `security.review.max-lines: 1000`; kept its `t/**` / `implementation-guide/**`
  excludes. Repo now inherits the built-in 1000.
- `.cwf/docs/skills/security-review.md`: both `500` prose literals → `1000`.
- `CWF-PROJECT-SPEC.md`: clarified that the exclude default now ships **seeded**
  in the template, and that `max-lines` is a helper default (1000), not seeded.

### Step 4: Tests — done
- `t/cwf-project-template.t`: TC-6 asserts the template carries a non-empty
  `security.review.max-lines-exclude-paths` array and does NOT seed `max-lines`.
- `t/security-review-changeset.t`:
  - **Re-baseline**: TC-DEFAULTCAP (520→1020 lines, asserts `> 1000`); new
    TC-CAPBOUNDARY pins 1000 pass / 1001 exit 2.
  - **String-only** (behaviourally neutral, 30-line fixtures): TC-CAP3,
    TC-CONFIGCAP5/6/7/8, and the `CLI // config // 500` precedence comment → 1000.
  - **Kept unchanged**: TC-CONFIGCAP4 (explicit `--max-lines=500` flag test),
    TC-DOCS negative `--max-lines=500` guard, the `[500]` ref-type literal.
  - **Added**: TC-SEED-VALID (every seeded glob valid via git's real engine),
    TC-SEED-EXCLUDE (seeded churn → 0 production), TC-SEED-DOC (doc markdown
    scoped-discounted; non-doc `*.md` still counts), TC-SEED-GUARDRAIL
    (live-tree, re-runnable: no seeded glob discounts a
    `.cwf/{scripts,hooks,security,docs}` or `cwf-project.json` path).

### Step 5: Hash refresh + validate — done
Refreshed the `security-review-changeset` sha256 in
`.cwf/security/script-hashes.json` (same commit). Working perms already 0500
(recorded). `cwf-manage validate` → **OK**.

### Step 6: Full-suite regression — done
`prove -l t/` → **All tests successful** (75 files, 979 tests). No stale-500
failures; TC-VALIDATE green after the hash refresh.

## Deviations from plan
None material. The plan anticipated four helper `500` sites and a
change/keep/string-only split for the 32 test-file mentions; both held exactly.

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] All requirements from b-requirements-plan.md addressed (AC1–AC9)
- [x] All design guidance in c-design-plan.md followed (D1–D5, FR3 guardrail)
- [x] No planned work deferred

## Changeset Reviews (Step 8 — five reviewers, parallel MAP)
Changeset: 18 files, 1658 lines, 31 production (excludes discounted the rest),
anchor `aa0573d`, includes uncommitted. Best-practice resolver matched 3 entries.

### Security Review
**State**: no findings

Validated the markdown-discount direction: the cap gates review *invocation*, not
content — excluded paths are still emitted in full and reviewed, so discounting
markdown keeps a large adversarial-markdown changeset *under* the cap and therefore
still auto-reviewed. New test code uses list-form git spawn and `-z` NUL parsing.
Both fail-open tradeoffs deliberate and surfaced.

### Best-Practice Review
**State**: findings — **resolved**

One advisory (Perl `io.md` #129 / `error-handling.md` #174): `TC-SEED-GUARDRAIL`'s
git pipe `close $gp` was unchecked, so a non-zero git exit (e.g. an unparseable
pathspec) would read as zero lines → empty `@hits` → a **false-PASS** guardrail.
Because that subtest *is* the FR3 security guardrail, a silent false-pass warranted
the fix. **Resolved**: the loop now `die`s on a non-zero close status
(`close $gp or die "git ls-files failed (glob=$glob): status " . ($? >> 8)`).
Test re-run green.

### Improvements Review
**State**: no findings

No new runtime code path — reuses Task 218's `max_lines_exclude_paths()` git
engine; cap change is one constant; new tests reuse existing fixtures. `cfg_seeded`
reads the shipped template globs rather than hardcoding (guards template/test drift).

### Robustness Review
**State**: no findings

Fail-safe (malformed config → stricter default) and fail-fatal (invalid CLI /
malformed glob → exit 1) contracts preserved and now boundary-tested via git's real
engine. Sits at "robust" on the fragile→anti-fragile spectrum.

### Misalignment Review
**State**: no findings

Mirrors the `_sandbox-note`/`sandbox` template precedent; stays within Task 218's
`security.review.*` namespace; JSON::PP + `-z` git parsing match pervasive `t/`
conventions; same-commit hash refresh per `hash-updates.md`.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
Reusing Task 218's exclude engine meant zero new runtime code — the effort was in test
coverage and the 32-way `500`-literal triage, not implementation. The best-practice
reviewer's catch (unchecked git pipe close → false-PASS in the FR3 guardrail test) is the
key lesson: a security *test* deserves the same scrutiny as security production code.
See `j-retrospective.md`.
