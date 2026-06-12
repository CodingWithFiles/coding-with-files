# Reconcile cwf-project.json with validator schema - Implementation Execution
**Task**: 196 (chore)

## Task Reference
- **Task ID**: internal-196
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/196-reconcile-cwf-project-json-with-validator-schema
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Actual Results

### Step 1: Rewrite the template
- **Planned**: Replace `.cwf/templates/cwf-project.json.template` with the Target Template (required + sandbox blocks retained; vestigial keys removed; pass-through names aligned).
- **Actual**: Rewritten to the Target Template verbatim. Removed `title`, `cwf-version`, `_cwf-version-note`, the `project` block (→ `project-name`/`description`), the `task-management` block (→ `task-tracking`), `team`, the options-style `templates` block, and the undocumented `source-management.type`/`url`. Fixed the branch placeholder `{task-description}` → `{description-slug}`. Retained `_sandbox-note` + the `sandbox` block (fail-safe defaults unchanged).
- **Deviations**: None.

### Step 2: Sync the init prose
- **Planned**: Edit `cwf-init` SKILL.md step 2 to reference `task-tracking` + `branch-naming-convention` and feed `project-name`.
- **Actual**: Step-2 bullets now read "Set `project-name` from the git remote or directory name" and "Fill the `task-tracking` block (GitHub issues by default) and the `source-management.branch-naming-convention`". No mention of the retired `task-management` block name remains.
- **Deviations**: None. (`cwf-init/SKILL.md` is not hash-tracked — confirmed in d-plan — so no sha256 refresh.)

### Step 3: Extend the guard test
- **Planned**: Add `CWF::Validate::Config` import; assert validator-clean + vestigial-absent + documented-names-present; rewrite the stale TC-2 comment.
- **Actual**: Added `use lib "$FindBin::Bin/../.cwf/lib"; use CWF::Validate::Config qw(validate_config_hash);`. Added TC-3 (validate_config_hash → 0 violations), TC-4 (loops over `cwf-version`/`_cwf-version-note`/`title`/`team`/`task-management`/`project` asserting absence), TC-5 (`project-name`/`task-tracking` present + `{description-slug}` in branch convention). Rewrote the Task-188 TC-2 comment to record the `cwf-version` carve-out reversal and note the live-config retirement is a separate out-of-scope Low item.
- **Deviations**: None. `validate_config_hash` returns a list (Config.pm:134) — `my @violations = …` is the correct call form.

### Step 4: Validate
- **Planned**: `prove t/cwf-project-template.t`, `prove t/validate-config.t`, full `prove t/` all green.
- **Actual**: Focused + validator tests green (42 tests). Full `prove t/` green: **63 files, 759 tests, exit 0**.
- **Deviations**: First full-suite run showed 2 failures (`cwf-manage-fix-security.t` TC-1/TC-9, `security-review-changeset.t` TC-35). Stash-test confirmed they were **pre-existing and unrelated** to this changeset — root cause was working-tree permission drift on `.cwf/scripts/command-helpers/cwf-claude-settings-merge` (0700 vs recorded 0500, sha256 intact). Per the fix-on-sight rule, clamped via `cwf-manage fix-security`; `cwf-manage validate` then OK and the full suite went green. The drift fix is a working-tree mode change only (no tracked-file content edit).

## Verification Sweep (removed-key reference scan)
Grepped the removed/renamed template keys across `.cwf`, `.claude`, `docs`, and `CWF-PROJECT-SPEC.md`. The only hits outside the (out-of-scope) live config are in `.cwf/utils/{config-loader,template-engine,task-validator}.md`, which still describe the **pre-Task-189** config shape (`project.name`, `source-management.type/url`, `task-management.type/url`, `branch-name-max-length`). These markdown files are **inert** — no helper, lib, or skill references `.cwf/utils` (confirmed by grep). They predate this task and are out of its Scope Fence.

**Follow-up candidate (not actioned here)**: reconcile or retire the stale `.cwf/utils/*.md` spec docs against `CWF-PROJECT-SPEC.md`. Sibling to the existing "Prune vestigial blocks from the live config" item.

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] All requirements from b-requirements-plan.md addressed (N/A — chore, no b-phase)
- [x] All design guidance in c-design-plan.md followed (N/A — chore, no c-phase)
- [x] No planned work deferred without user approval (stale `.cwf/utils` docs were never in scope; logged as a follow-up candidate)
- [x] If work deferred: follow-up candidate recorded above

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: no findings

## Security review — Task 196 implementation-exec changeset

I read the full changeset at `/tmp/-home-matt-repo-coding-with-files-task-196/security-review-changeset-implementation-exec.out` and the threat model in `.cwf/docs/skills/security-review.md` §"Threat categories" (a)–(e). I also read `.cwf/lib/CWF/Validate/Config.pm` to confirm the contract the new test exercises.

The changeset has four material payloads (the rest are CWF workflow-step docs, which carry no executable surface):

1. `.cwf/templates/cwf-project.json.template` — rewritten to spec shape.
2. `.claude/skills/cwf-init/SKILL.md` — step-2 prose synced.
3. `t/cwf-project-template.t` — guard test extended with three new test cases plus a `CWF::Validate::Config` import.
4. The five new `implementation-guide/.../*.md` workflow docs.

**(a) Bash injection / unsafe command construction.** No shell commands are introduced anywhere in the diff. The template is static JSON; the SKILL.md edit is prose; the test uses `Test::More`/`JSON::PP` and a pure-Perl `validate_config_hash` call with no `system`/backticks/`qx`. Nothing to flag.

**(b) Perl helpers consuming git/user output without `-z`.** The only Perl touched is `t/cwf-project-template.t`. It slurps a fixed file path (`$FindBin::Bin/../.cwf/templates/cwf-project.json.template`), `decode_json`s it, and runs in-memory hash assertions. No git porcelain parsing, no newline-splitting, no untrusted input. `validate_config_hash($cfg, $template)` returns a list and is called in list context (`my @violations = …`), matching the contract at `Config.pm:55`/`:134`. Clean.

**(c) Prompt injection via user-supplied strings.** No `{arguments}` substitution surface is added or altered. The template gains an `OWNER/REPO` placeholder URL and `{{number}}` id-format strings — these are inert template literals, not interpolated into any LLM tool-selection path. The init-prose edit names config keys (`project-name`, `task-tracking`, `branch-naming-convention`), no free-text flow. Clean.

**(d) Unsafe environment-variable handling.** No env vars are read or introduced. The template drops `task-management.url` / `source-management.url` (the old hardcoded `github.com/company/project` values) and replaces them with documentation placeholders. No path flows to `chmod`/`rm`/`open`. Clean.

**(e) Pattern-based risks.** Two observations worth recording, neither actionable as a defect:

- The new test adds `use lib "$FindBin::Bin/../.cwf/lib"` and imports the live `CWF::Validate::Config`. This is safe here because the test runs against the in-repo tree under `prove t/` (a trusted, developer-controlled path), and `$FindBin::Bin` resolves to the repo's `t/` directory. The pattern would only become risky if a future test were run from an attacker-writable CWD with a planted `.cwf/lib` — not a CWF workflow, and consistent with how the existing suite already locates libs. Safe here because the test tree is trusted; audit future uses where a test might execute against an untrusted checkout root.

- The retained `sandbox` block keeps fail-safe defaults verbatim (`enabled: false`, `fail-if-unavailable: true`, `credential-deny-list: ["~/.ssh", "~/.aws"]`, `violation-logging: false`, `planning-write-guard: "off"`). This is the correct fail-closed posture for a shipped template; a fresh `/cwf-init` lands sandboxing off-but-fail-closed-when-enabled. Mildly positive, no concern. The `_sandbox-note` annotation correctly points a fresh user at `.cwf/docs/sandboxing.md` before enabling a security-sensitive feature.

One coverage note (not a finding, already self-disclosed in `f-implementation-exec.md`): the verification sweep flagged stale `.cwf/utils/{config-loader,template-engine,task-validator}.md` describing the pre-Task-189 config shape. These are inert markdown with no readers and were correctly left out of scope. No security implication — they are documentation, not a code path.

The diff ships no executable attack surface and the one new code path (the test's validator import) is sound. The changeset is clean.

```cwf-review
state: no findings
summary: Static template/doc reconciliation + pure-Perl guard test; no shell, env, git-parse, or injection surface introduced; sandbox defaults remain fail-closed.
```

## Lessons Learned
Run `cwf-manage validate` at the start of the implementation phase, before the first full `prove t/`, so ambient permission/integrity drift is attributed correctly instead of masquerading as a regression in the current diff. See `j-retrospective.md`.
