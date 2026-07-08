# Seed exclude-path defaults, raise review cap 1000 - Testing Execution
**Task**: 221 (feature)

## Task Reference
- **Task ID**: internal-221
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/221-seed-exclude-path-defaults-raise-review-cap-1000
- **Template Version**: 2.1

## Goal
Execute e-testing-plan.md against the phase-f implementation.

## Environment
Existing `t/` Perl `Test::More` harness, core modules only. Scratch git repos in
`${TMPDIR}`. No external services, no database. Run via `prove -l t/`.

## Test Results — AC1–AC9 mapped to named test cases

| AC / FR | Test case(s) | Expected | Actual | Status |
|---------|--------------|----------|--------|--------|
| AC1 / FR1 | TC-SEED-EXCLUDE | churn in seeded test/generated/vendored paths → 0 production (passes cap 1) | exit 0, no breach | PASS |
| AC2 / FR2 | TC-SEED-DOC | top-level `*.md` + `docs/**/*.md` discounted; `src/inline.md` still counts | (a) cap 100 pass; (b) cap 100 exit 2 | PASS |
| AC3 / FR3 | TC-SEED-GUARDRAIL | no seeded glob discounts `.cwf/{scripts,hooks,security,docs}` / `cwf-project.json` (live tree) | 0 guardrail hits | PASS |
| AC4 / FR4 | TC-DEFAULTCAP, TC-CAPBOUNDARY | 1020>1000 exit 2; 1000 pass, 1001 exit 2; no stale `500` | exit 2 / pass / exit 2 | PASS |
| AC4 / FR4 | TC-SEED-VALID | every seeded glob a valid pathspec via git's real engine (helper ≠ exit 1) | exit 0, no `fatal:` | PASS |
| AC5 / FR5 | TC-CONFIGCAP4, TC-CONFIGCAP1..10 | `--max-lines` > config > default precedence preserved | explicit 500 still fires over config 1000 | PASS |
| AC6 / FR6 | TC-DOGFOOD | repo config: `max-lines` absent, excludes kept, valid JSON, validate 0 | absent / 2 excludes / valid / OK | PASS |
| AC7 / FR7 | TC-DOCS-CURRENT | `security-review.md` no `500`; spec documents seeded default; TC-DOCS guard unchanged | no stale `500`; TC-DOCS green | PASS |
| AC8 / FR1,FR5 | TC-TEMPLATE (TC-6) | template carries non-empty exclude array; `max-lines` absent | array present / absent | PASS |
| AC9 / constraint | TC-HASH | hash refreshed same-commit; `cwf-manage validate` exit 0 | validate: OK | PASS |

### Regression control — the 32 `500` mentions
Change/keep/string-only split executed exactly as planned: TC-DEFAULTCAP
re-baselined; behaviourally-neutral config-cap prose → 1000; TC-CONFIGCAP4
explicit-flag test, TC-DOCS negative guard, and the `[500]` ref-type literal kept
unchanged. `grep 500` on the helper and `security-review.md` returns nothing.

### Non-Functional Tests
- **Security**: TC-SEED-GUARDRAIL (FR3 fail-open guardrail, live-tree) + TC-SEED-VALID
  (malformed-glob review-wide breakage) — both PASS. Fail-open tradeoffs are
  deliberate and surfaced (note/spec/rollout), not smoothed.
- **Reliability**: fail-safe (malformed config → stricter default) and fail-fatal
  (invalid CLI / malformed glob → exit 1) contracts preserved; TC-CONFIGCAP5/6/7/8
  and TC-CONFIGCAP10 PASS.
- **Performance**: pathspec pass-through + one integer compare — no measurable cost.

## Full-suite result
`prove -l t/` → **All tests successful** — 75 files, 979 tests, 0 failures.
`cwf-manage validate` → **OK**.

## Test Failures
None.

## Coverage
AC1–AC9 each covered by ≥1 passing named test case. No pre-existing subtest broken.

## Changeset Reviews (Step 8 — two reviewers, parallel MAP)
Changeset: 18 files, 1721 lines, 31 production, anchor `aa0573d`, includes
uncommitted. Best-practice resolver matched 3 entries (perl applicable; golang +
postgres not applicable — no Go/SQL in the changeset).

### Security Review
**State**: no findings

Confirmed the markdown-discount fails *toward review* (exceeding the cap skips the
subagent; discounting keeps adversarial markdown under the cap and still
auto-reviewed). New test code uses list-form git spawn + `-z` parsing with a
**checked** pipe close. FR3 suffix-glob guarantee holds by layout and is guarded by
the re-runnable live-tree `TC-SEED-GUARDRAIL`. Fail-open tradeoffs deliberate and
surfaced.

### Best-Practice Review
**State**: no findings

New Perl test code conforms to the applicable Perl best practices (io /
error-handling / testing-debugging): three-arg checked `open`, `do { local $/ }`
slurp, list-form git spawn, checked `close $gp or die ... ($? >> 8)`, boundary +
negative test cases, and guarded dereferences. The phase-f guardrail close-fix is
already reflected in this diff.

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
Deriving test expectations from the shipped template (`seeded_exclude_globs()`) rather
than hardcoding guards against template/test drift — worth standardising wherever a test
asserts something the shipped artefact also states. See `j-retrospective.md`.
