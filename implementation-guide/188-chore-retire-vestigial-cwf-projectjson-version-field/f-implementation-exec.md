# Retire vestigial cwf-project.json version field - Implementation Execution
**Task**: 188 (chore)

## Task Reference
- **Task ID**: internal-188
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/188-retire-vestigial-cwf-projectjson-version-field
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status to "Finished" when complete

## Actual Results

### Step 1: Baseline (re-confirm zero readers + clean validate)
- **Planned**: Repo-wide bare-string scan for the version keys; confirm zero readers; `cwf-manage validate` clean before edits.
- **Actual**: Bare-string scan returned no code readers — every hit was a legitimate unrelated use (`versioning.*`, the `cwf-version-*` *script* names, migration-state `"version"` schema fields, `script-hashes.json` own schema version). **One material finding the plan review missed**: `CWF-PROJECT-SPEC.md` declared `version` a **required** field in five places. Surfaced to the user; decision = fold the spec into this task (still `version`-only scope).
- **Deviations**: `CWF-PROJECT-SPEC.md` added to scope (see Step 2). Baseline `validate` was **not** clean — 3 pre-existing WORKFLOW violations (this task's own a/d/e plan files still at transient `Planning` status) + 1 pre-existing SECURITY violation (perm drift on `.claude/agents/cwf-security-reviewer-changeset.md`, 0600 vs recorded 0444). Neither relates to the version field.

### Step 2: Remove the field
- **Planned**: Remove `version` + `_version-note` from the template; remove the top-level `version` from the live config. Retain `cwf-version`/`_cwf-version-note`.
- **Actual**: Done. `.cwf/templates/cwf-project.json.template` L3–L4 removed (`cwf-version` retained). `implementation-guide/cwf-project.json` top-level `version` line removed. **Plus** (exec-time addition) `CWF-PROJECT-SPEC.md`: removed `version` from the root-object schema, deleted the `#### version (required)` field-spec block, dropped it from both config examples, and removed it from the Validation Rules → Required Fields list. Post-edit grep confirms only legitimate references remain (`cwf-version`, the semver "Version Format" rule).
- **Deviations**: The `CWF-PROJECT-SPEC.md` edits, as recorded in d-implementation-plan.md Primary Changes (added at exec time).

### Step 3: Guard test
- **Planned**: New `t/cwf-project-template.t` — parse the template inside `eval` (fail loudly on malformed), assert `!exists $j->{version}`; mirror sibling harness conventions.
- **Actual**: Added. `use strict/warnings/utf8`, `Test::More`, `JSON::PP`, `FindBin`, `done_testing`. One fix during bring-up: initial read used a UTF-8 decoding layer then passed the result to `decode_json` (which expects UTF-8 *bytes*), producing "Wide character in subroutine entry"; switched to a raw-byte slurp (`<:raw`), the canonical `decode_json` usage. Test green (3 assertions).
- **Deviations**: None of substance (the byte-vs-character fix is an implementation detail, not a plan change).

### Step 4: Validation
- **Planned**: Guard test green; full `prove -lr t/` green; `cwf-manage validate` clean.
- **Actual**:
  - **TC-1/TC-2** (guard test): PASS.
  - **TC-3** (`cwf-manage validate`): the version removal introduced **zero** new violations. To reach a genuinely clean `validate` I (a) fixed the pre-existing perm drift on sight via `cwf-manage fix-security` (0600→0400 on the changeset reviewer agent; my standing fix-on-sight rule) and (b) marked this task's completed a/d/e planning phases `Finished` via `cwf-set-status` (they were lagging at `Planning`; the retrospective status-sweep does this anyway). `validate` now reports **OK**.
  - **TC-4** (full suite): 709 tests; **one pre-existing failure** remains — `cwf-manage-fix-security.t` TC-8 ("drift pin"), which asserts all `.claude/agents/*.md` satisfy a **floor** of 0444 while the repo's agent files are at 0400 (more restrictive). It failed identically on the clean baseline (commit 13840c5, verified by stashing my edits), touches no file this task changed, and `cwf-manage validate` is content with 0400 (recorded perms are a *ceiling* per Task 170, so 0400 ≤ 0444 passes). Out of scope for this task; candidate for its own backlog item.

## Blockers Encountered
None. One scope decision (fold `CWF-PROJECT-SPEC.md` in) was surfaced and resolved by the user mid-exec.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [N/A] b-requirements-plan.md — chore has no requirements phase
- [N/A] c-design-plan.md — chore has no design phase
- [x] No planned work deferred without user approval
- [x] Deferred-by-design follow-up (the remaining `cwf-version`/`_cwf-version-note` + `security.version-tracking`) to be filed at rollout/retrospective, per the plan

## Follow-ups to file (at rollout/retrospective)
1. "Retire remaining vestigial version fields (`cwf-version`/`_cwf-version-note` in template; `security.version-tracking`)" — the originally-deferred narrow-scope tail.
2. "fix-security TC-8 floor-vs-ceiling: agent `.md` perms at 0400 fail the 0444 floor pin while `validate` (ceiling) passes" — reconcile the test's floor expectation with the Task-170 ceiling model.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: no findings

Now let me reason through the five threat categories.

**(a) Bash injection / unsafe command construction.** No shell commands are constructed anywhere in this changeset. The new test uses no `system`, no backticks, no `qx`. The data changes are pure JSON-field deletions. No exposure.

**(b) Perl helpers consuming git or user output without `-z` / input validation.** The one Perl file added (`t/cwf-project-template.t`) consumes no git output and no user input. It reads a fixed `FindBin`-relative path, slurps raw bytes, and `decode_json`s. The path is constructed from `$FindBin::Bin` (the test's own location), not from any external string, so there's no untrusted-path concern. It correctly opens with `<:raw` and lets `decode_json` handle UTF-8, and declares `use utf8;` per project convention. No `-z`/newline-split issue because no git output is parsed. Clean.

**(c) Prompt injection via user-supplied strings.** No `{arguments}` substitution, no SKILL/template surface that feeds untrusted text into LLM context is added or modified. The JSON deletions and doc edits introduce no new free-text flow into model context. Not implicated.

**(d) Unsafe environment-variable handling.** No env vars are read or introduced. The test reads no `$ENV{...}`. The removed `version` field never fed `chmod`/`rm`/`open`/clone-URL paths (the plan confirms zero readers). Not implicated.

**(e) Pattern-based risks (safe-here-but-risky-elsewhere).** The test's path construction `"$FindBin::Bin/../.cwf/templates/cwf-project.json.template"` is safe here because `$FindBin::Bin` is the test-script directory, a trusted constant, not user input. This is the standard CWF test idiom and carries no reuse hazard worth flagging — the invariant (`FindBin::Bin` is trusted) holds for any test reusing it. Nothing else qualifies.

One non-security observation worth recording for completeness, but not a security finding: the changeset `.out` was generated before `t/cwf-project-template.t` was written, so the guard test that the testing exec relies on is not visible in the diff under review (it exists untracked in the working tree). This is a coverage/freshness artefact of the changeset anchor, not a vulnerability — the deletions themselves are inert (no readers), and the test, when read directly, is sound.

The change is a deletion of decorative config data plus a sound guard test. It strictly reduces attack surface and introduces no new command construction, untrusted-input flow, or env-var handling.

```cwf-review
state: no findings
summary: Task 188 retires the vestigial cwf-project.json `version` field plus a sound JSON guard test; pure data/doc deletion, no command construction, untrusted-input flow, or env-var handling introduced.
```

## Lessons Learned
*To be captured during retrospective*
