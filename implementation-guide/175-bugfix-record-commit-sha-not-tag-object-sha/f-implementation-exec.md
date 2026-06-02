# record commit sha not tag-object sha - Implementation Execution
**Task**: 175 (bugfix)

## Task Reference
- **Task ID**: internal-175
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/175-record-commit-sha-not-tag-object-sha
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status to "Implemented" when complete

## Actual Results

### Step 1: Test first (red)
- **Planned**: Add `t/version-records-commit-sha.t` with an annotated-tag install + cwf-manage-update case; confirm it fails against current code.
- **Actual**: Wrote the test (self-contained, mirrors the `t/cwf-manage-update-end-to-end.t` fixture pattern; its `build_upstream` creates **annotated** tags via `git tag -a`). Each case asserts a `rev-parse <tag>` ≠ `rev-parse <tag>^{commit}` precondition, then checks `cwf_sha`. Red as expected: TC-1 assertions 3–4 and TC-2 assertions 4–5 failed (`cwf_sha` was the tag-object SHA); the `cwf_version` regression guard passed unchanged.
- **Deviations**: None.

### Step 2: Fix install.bash
- **Planned**: Line 310 `rev-parse "$resolved_ref"` → `rev-parse "${resolved_ref}^{commit}"`.
- **Actual**: Applied verbatim.
- **Deviations**: None.

### Step 3: Fix cwf-manage
- **Planned**: `resolve_sha` `rev-parse', $ref` → `rev-parse', "$ref^{commit}"`; working perm stays 0700.
- **Actual**: Applied verbatim. `stat` confirms working perm `700` == recorded `0700` — no chmod needed. Blast radius re-confirmed: only `cwf_sha` value changes; `git_describe_version` → `cwf_version` unaffected (TC-2 regression guard green); re-passed `CWF_REF` peels idempotently.
- **Deviations**: None.

### Step 4: Refresh hash (same commit)
- **Planned**: Pre-refresh verify, then refresh the `cwf-manage` sha256 entry.
- **Actual**: `git log 7e376bc..HEAD -- .cwf/scripts/cwf-manage` empty (no committed change); working diff is the single intended one-line edit. Refreshed sha256 to `7cc0d821059bc5709096066f32ad490183efb2cc004a2fa2a26613259a54f42d` in `.cwf/security/script-hashes.json`. `permissions` left `0700`.
- **Deviations**: None.

### Step 5: Validation (green)
- **Planned**: `validate` clean for cwf-manage; new test green; named regressions pass.
- **Actual**: `cwf-manage validate` → `[CWF] validate: OK`. `prove t/version-records-commit-sha.t` → PASS (2 subtests). `prove t/install-bash-reinstall.t t/cwf-manage-update-end-to-end.t t/cwf-manage-update.t` → PASS (28 tests). No pre-existing perm drifts surfaced (fixed earlier this session).
- **Deviations**: None.

## Blockers Encountered

None.

## Deferral Check
Before marking status=Finished, verify:
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] All requirements from b-requirements-plan.md addressed (N/A — bugfix, no b)
- [x] All design guidance in c-design-plan.md followed
- [x] No planned work deferred without user approval
- [x] If work deferred: N/A — nothing deferred

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

## Security Review

**State**: no findings

I now have full context. Let me complete the security review.

## Security Review — Task 175 (implementation phase)

The changeset is a bugfix: when recording the installed CWF version SHA, `git rev-parse <ref>` is replaced with `git rev-parse <ref>^{commit}` at two sites, so that an annotated-tag ref resolves to the underlying commit SHA rather than the tag-object SHA. I reviewed the two production code edits, the hash refresh, and (by description) the five Task-175 workflow markdown files and the new Perl test.

I reasoned through each threat category:

**(a) Bash injection / unsafe command construction.** Both edits append a literal suffix `^{commit}` to an existing variable inside an argument that is already passed safely.
- `cwf-manage:225` uses list-form spawn `open my $fh, '-|', 'git', '-C', $clone_dir, 'rev-parse', "$ref^{commit}"`. No shell is invoked; `^`, `{`, `}` are not interpreted by `execvp`. The interpolation only builds one argv element. Safe.
- `install.bash:310` uses `git -C "$dir" rev-parse "${resolved_ref}^{commit}"` — the expansion is fully double-quoted, so word-splitting and glob expansion do not apply, and `^{}` are not shell metacharacters inside double quotes. Safe.

**(b) Perl git-output handling / `-z` / input validation.** `resolve_sha` reads a single SHA line from `rev-parse` and `chomp`s it; no path splitting is involved, so the `-z` convention is not relevant here. No new newline-splitting of porcelain output is introduced.

**(c) Prompt injection.** No SKILL/agent prompt surfaces are touched. The markdown files are CWF-internal workflow docs, not LLM-substituted argument sinks. Nothing new flows into LLM context.

**(d) Unsafe environment-variable handling.** The `$ref`/`$resolved_ref` values trace back to `CWF_REF` (env, default `latest`) and `CWF_SOURCE`. Both edits keep the same safe invocation pattern documented as canonical in the threat model (`cwf-manage:255` list form; quoted expansion in bash). The `^{commit}` suffix does not expand the trust surface — the same env-derived value already reached `rev-parse` before this change. No `chmod`/`rm`/`open` path is fed.

**(e) Pattern-based risk.** In `cwf-manage`, `resolve_sha` is only ever called with the output of `resolve_ref` (`cwf-manage:463-464`), which has already passed `git rev-parse --verify --quiet`. The `"$ref^{commit}"` interpolation is safe here because the spawn is list-form, so safety does not even depend on that invariant — it holds regardless of what `$ref` contains. Worth noting for future reuse: in `install.bash` the same suffix relies on the value being double-quoted; if a future edit were to drop the quotes around `${resolved_ref}^{commit}`, the `{...}` would become a brace-expansion / glob hazard. Safe here because the expansion is double-quoted; audit any future reuse where the quotes might be removed.

**Hash refresh.** Although hash integrity is `cwf-manage validate`'s deterministic domain (out of scope per the boundary note), I confirmed the diff is internally consistent and not a tampering signal: the recorded `sha256` for `.cwf/scripts/cwf-manage` (`7cc0d821059bc5709096066f32ad490183efb2cc004a2fa2a26613259a54f42d`) matches the on-disk content, and the `permissions` field (`0700`) is unchanged. The refresh accompanies the file edit in the same changeset per the hash-updates convention.

The new test `t/version-records-commit-sha.t` is described as using tempdir fixtures with no network or real-repo writes, consistent with the database/test-isolation expectation; it is reviewed but discounted from the production line cap.

No actionable security concerns.

Relevant files:
- `/home/matt/repo/coding-with-files/.cwf/scripts/cwf-manage` (resolve_sha, line 225)
- `/home/matt/repo/coding-with-files/scripts/install.bash` (line 310)
- `/home/matt/repo/coding-with-files/.cwf/security/script-hashes.json` (cwf-manage hash entry)

```cwf-review
state: no findings
summary: Literal ^{commit} suffix added to existing safe list-form/quoted rev-parse calls; no new injection, env, or prompt surface. Hash refresh internally consistent.
```
