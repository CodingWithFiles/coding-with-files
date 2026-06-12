# Reconcile cwf-project.json with validator schema - Testing Execution
**Task**: 196 (chore)

## Task Reference
- **Task ID**: internal-196
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/196-reconcile-cwf-project-json-with-validator-schema
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Test Results

### Functional Tests (all in `t/cwf-project-template.t`)

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1 | Template parses as valid JSON | no parse error | `ok 2 - template parses as valid JSON` | PASS |
| TC-2 | Retired top-level `version` absent | absent | `ok 3 - retired top-level version field is absent` | PASS |
| TC-3 | `validate_config_hash` → 0 violations | 0 | `ok 4 - template validates clean (zero violations)` | PASS |
| TC-4 | Vestigial keys absent (`cwf-version`, `_cwf-version-note`, `title`, `team`, `task-management`, `project`) | all absent | `ok 5`–`ok 10` (one per key) | PASS |
| TC-5 | Documented names present + placeholder fixed | `project-name`, `task-tracking` present; `{description-slug}` in branch convention | `ok 11`, `ok 12`, `ok 13` | PASS |
| TC-6 | Stale TC-2 comment rewritten (process, by inspection) | no self-contradictory comment | Comment now records the Task-188 carve-out reversal and the out-of-scope live-config note; no "deliberately NOT asserted" text remains | PASS |

Focused run: `prove t/cwf-project-template.t` → 13 assertions, all `ok`, Result: PASS.

### Regression / Non-Functional Tests

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-R1 | `prove t/validate-config.t` (validator unchanged) | green | 29 tests, Result: PASS | PASS |
| TC-R2 | Full `prove t/` | green, exit 0 | 63 files, 759 tests, Result: PASS | PASS |

**Manual inspection (e-plan validation criteria)**:
- `cwf-init` SKILL.md step 2 prose matches produced keys (`project-name`, `task-tracking`, `source-management.branch-naming-convention`) — confirmed; no stale `task-management` block name remains.
- Rewritten template reads clean against `CWF-PROJECT-SPEC.md` — confirmed (required keys + sandbox block retained; documented pass-through names; no undocumented keys).

**Security**: the only security-relevant payload (`sandbox` block) is retained verbatim with fail-safe defaults; TC-3 confirms it still validates. No new automated security test required (per e-plan).

## Test Failures

None in the final run.

**Note (transient, resolved during f-exec)**: the first full-suite run reported `cwf-manage-fix-security.t` (TC-1/TC-9) and `security-review-changeset.t` (TC-35) failing. A stash-test proved these were pre-existing and independent of this changeset; root cause was working-tree permission drift on `.cwf/scripts/command-helpers/cwf-claude-settings-merge` (0700 vs recorded 0500, sha256 intact). Clamped via `cwf-manage fix-security` (fix-on-sight); `cwf-manage validate` then OK and the suite went green. Not a defect in this task's code.

## Coverage Report

Every key-shape claim in the d-plan success criteria has a corresponding mechanical assertion (validator-clean, vestigial-absent ×6, documented-names-present ×2, placeholder-fixed). No source line in the changeset is uncovered by either the focused guard or the full regression suite.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: no findings

## Security review — Task 196 testing-exec changeset

I read the full changeset at `/tmp/-home-matt-repo-coding-with-files-task-196/security-review-changeset-testing-exec.out` and the threat model in `.cwf/docs/skills/security-review.md` §"Threat categories" (a)–(e). I also read `.cwf/lib/CWF/Validate/Config.pm` to confirm the contract the new test code calls.

The changeset has one executable payload; everything else is inert. Breaking it down:

1. `t/cwf-project-template.t` — guard test extended with a `CWF::Validate::Config` import and three new test cases (TC-3/TC-4/TC-5). This is the only code path.
2. `.cwf/templates/cwf-project.json.template` — static JSON, rewritten to spec shape.
3. `.claude/skills/cwf-init/SKILL.md` — step-2 prose edit.
4. The new `implementation-guide/.../*.md` workflow docs (a, d, e, f, g, j), which carry no executable surface.

**(a) Bash injection / unsafe command construction.** No shell commands are introduced anywhere in the diff. `t/cwf-project-template.t` uses `Test::More`, `JSON::PP`, `FindBin`, and an in-process `validate_config_hash` call — no `system`, no backticks, no `qx`. The template is data; the SKILL.md edit is prose. Nothing to flag.

**(b) Perl helpers consuming git/user output without `-z`.** The only Perl touched is `t/cwf-project-template.t`. It slurps a fixed file path (`$FindBin::Bin/../.cwf/templates/cwf-project.json.template`), `decode_json`s it, and runs in-memory hash assertions. No git porcelain parsing, no newline-splitting of untrusted output, no untrusted input at all. The new `validate_config_hash($cfg, $template)` call matches the exported contract at `Config.pm:55` (`($config, $file)` → list of violation hashrefs) and is called in list context (`my @violations = …`), so the count assertion at `is(scalar @violations, 0, …)` is sound. Clean.

**(c) Prompt injection via user-supplied strings.** No `{arguments}` substitution surface is added or altered. The template literals (`OWNER/REPO`, `{{number}}`, `{description-slug}`) are inert placeholders, not interpolated into any LLM tool-selection path. The init-prose edit only names config keys. No free-text flows into LLM context. Clean.

**(d) Unsafe environment-variable handling.** No env vars are read or introduced. The template drops the old hardcoded `github.com/company/project` URLs in favour of documentation placeholders; no path flows to `chmod`/`rm`/`open`. Clean.

**(e) Pattern-based risks.** Two observations, neither actionable as a defect:

- `t/cwf-project-template.t` adds `use lib "$FindBin::Bin/../.cwf/lib"` and imports the live `CWF::Validate::Config`. Safe here because the test runs under `prove t/` against the in-repo, developer-controlled tree, and `$FindBin::Bin` resolves to the repo's `t/` directory. This is consistent with how the existing suite already locates libs. The pattern would only become risky if a test were executed from an attacker-writable CWD with a planted `.cwf/lib` — not a CWF workflow. Safe here because the test tree is trusted; audit future uses where a test might run against an untrusted checkout root.
- The retained `sandbox` block (in the static template) keeps fail-safe defaults verbatim (`enabled: false`, `fail-if-unavailable: true`, `credential-deny-list: ["~/.ssh", "~/.aws"]`, `planning-write-guard: "off"`). This is the correct fail-closed posture for a shipped template. Mildly positive, no concern.

One coverage note, not a finding: the testing-exec docs reference a transient full-suite failure resolved during f-exec via a working-tree permission clamp (`cwf-manage fix-security` on `cwf-claude-settings-merge`, sha256 intact). That is a permission/hash-integrity matter owned by `cwf-manage validate`, explicitly out of this subagent's boundary per the security-review doc §"Boundary vs `cwf-manage validate`" — raising it here would be noise. No source line in this changeset introduces that drift.

The diff ships no executable attack surface beyond the test's validator import, which is sound. The changeset is clean.

```cwf-review
state: no findings
summary: Static template/doc reconciliation + pure-Perl guard test; no shell, env, git-parse, or injection surface introduced; validator import is callsite-safe and sandbox defaults remain fail-closed.
```

## Lessons Learned
Stash-testing isolates pre-existing failures fast: re-running the suite without the changeset proved the two transient failures pre-dated this task, preventing a false regression hunt. See `j-retrospective.md`.
