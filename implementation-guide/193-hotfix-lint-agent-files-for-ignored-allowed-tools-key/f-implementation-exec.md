# Lint agent files for ignored allowed-tools key - Implementation Execution
**Task**: 193 (hotfix)

## Task Reference
- **Task ID**: internal-193
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/193-lint-agent-files-for-ignored-allowed-tools-key
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

See d-implementation-plan.md Steps 1-5. Actual results recorded below.

## Actual Results

### Step 1: Test-first (`t/validate-agents.t`)
- **Planned**: Write the test with positive/negative/edge fixtures; run red (module absent).
- **Actual**: Wrote TC-1..TC-8 mirroring `t/validate-templates.t` (tempdir fixtures,
  `validate($root)` direct calls). First run: `Can't locate CWF/Validate/Agents.pm`
  — red as expected.
- **Deviations**: None.

### Step 2: Module (`.cwf/lib/CWF/Validate/Agents.pm`)
- **Planned**: Scan-target resolution (.cwf-agents/ preferred, else .claude/agents/),
  cwf-* namespace glob, frontmatter-only detection, one violation per file, chmod 0600.
- **Actual**: Created the module (package `CWF::Validate::Agents`, `@EXPORT_OK=qw(validate)`,
  `use strict/warnings/utf8`, core-only, perms 0600). First run failed TC-7: the initial
  single-pass loop flagged `allowed-tools:` *before* confirming the block was terminated,
  so an unterminated block was wrongly flagged. Fixed to a two-pass scan — locate the
  closing `---` first, return `()` if absent, then scan only lines strictly inside the
  terminated block. Re-ran → all 8 subtests green.
- **Deviations**: Detection refined to two-pass (find-close-then-scan) to honour the
  TC-7 invariant. Behaviour matches the plan's intent ("unterminated → skip, do not scan
  the body"); only the implementation shape changed.

### Step 3: Wire-in (`.cwf/scripts/cwf-manage`)
- **Planned**: Add `use CWF::Validate::Agents ();` and the `cmd_validate` aggregation call.
- **Actual**: Added both (use line after `TemplateRefs`; call appended to `@all_violations`).
  Restored cwf-manage perms to the recorded 0700 after editing.
- **Deviations**: None.

### Step 4: Integrity (`.cwf/security/script-hashes.json`)
- **Planned**: Add the new module's `{path, sha256}` entry (no permissions key, 0600) and
  refresh cwf-manage's sha256 — same commit. Digest via `sha256sum`.
- **Actual**: Added `CWF::Validate::Agents` entry (alphabetical, before `Config`); refreshed
  `cwf-manage` sha256 (`e84de3eb…` → `aa198dd5…`). `cwf-manage validate` → `validate: OK`
  (TC-9: real tree clean, PerlConventions + hash integrity pass for both changed files).
- **Deviations**: None.

### Step 5: Full suite
- **Planned**: `prove t/` — no regressions.
- **Actual**: `prove t/` → All tests successful (Files=63, Tests=734), including
  `t/validate-agents.t` (TC-10).
- **Deviations**: None.

## Blockers Encountered

None. (TC-7 ordering bug found and fixed in-phase — see Step 2.)

## Security Review

**State**: no findings

Both hashes match the values recorded in the diff (`eda94617…` for Agents.pm, `aa198dd5…` for cwf-manage). The hash-integrity side is consistent — though per the boundary note in security-review.md §16, hash/permission integrity is `cwf-manage validate`'s job, not mine. Note in scope, integrity confirms the shipped file is what was reviewed.

Now let me work through the threat categories against the shipped code.

**Category (a) — Bash injection / unsafe command construction.** The new module `Agents.pm` constructs no shell commands. There is no `system`, no backticks, no `qx`, no `open '|-'`. Directory traversal uses `opendir`/`readdir`/`-d`/`-f`/`-l` and file reads use three-arg `open my $fh, '<', $path`. The wire-in to `cwf-manage` is a plain Perl function call `CWF::Validate::Agents::validate($git_root)` and a `use` statement — no command construction. Nothing to flag.

**Category (b) — git/user output without `-z` / input validation.** The module does not consume git output at all. It enumerates files via `readdir`, not `git ls-files`, so the NUL-separation convention (which concerns parsing git porcelain) does not apply here. Filenames are taken directly from `readdir` as native bytes — never split on `\n` from a pipe — so the embedded-newline hazard the convention guards against cannot arise. `$git_root` is supplied by the caller (`cwf-manage`, which derives it from `find_git_root()`), not from untrusted external output. The three-arg `open` is correct. Nothing to flag.

**Category (c) — Prompt injection via user-supplied strings.** This validator reads agent `.md` file contents but only inspects them with anchored regexes (`/^---\s*$/`, `/^allowed-tools\s*:/`); no file content flows into LLM context or into any downstream model prompt. It emits structured violation hashrefs with fixed string fields plus the repo-relative path. The frontmatter-only scanning with the unterminated-block guard (`return () unless defined $close`) is exactly the right discipline and matches the documented design — it avoids the body-prose false-positive class. No prompt-injection surface introduced.

**Category (d) — Unsafe environment-variable handling.** The module reads no environment variables. No `$ENV{...}` access, no env-derived paths fed to `chmod`/`rm`/`open`. The only path inputs are `$git_root` (caller-supplied) and `readdir`-enumerated basenames constrained to `/^cwf-.*\.md\z/`. Nothing to flag.

**Category (e) — Pattern-based risks (safe-here-but-risky-elsewhere).** Two patterns worth noting for future-reuse framing, neither a defect here:

1. **Path construction by string concatenation** (`"$git_root/$subdir"`, `"$dir/$name"`). Safe here because `$subdir` is one of two hardcoded literals (`.cwf-agents` / `.claude/agents`) and `$name` is constrained to the `/^cwf-.*\.md\z/` namespace by the `grep` before any path is built — so no `..` or absolute-path component can enter via `$name`. The `-f $path` guard further means symlinks resolving outside the tree are still just read, not written. Audit framing: if this concatenation idiom were copied into a context where the basename came from unfiltered `readdir`, a config value, or user input, a `..`-bearing or absolute name could escape the intended directory. It is safe here because the namespace `grep` is the invariant; audit future uses where the basename is not pre-filtered.

2. **`die` on `opendir`/`open` failure inside a validator** (lines 55, 72). This matches the sibling `Templates.pm` contract (die-on-opendir-failure) and is reached only after `-d`/`-f` guards, so it fires only on genuine I/O faults (races, permission loss), turning `cwf-manage validate` non-zero — an acceptable fail-loud posture, not a security issue. No DoS angle since the file corpus is the repo's own small `cwf-*` agent set, not attacker-supplied volume.

**Other observations.** The `.cwf-agents/`-takes-precedence resolution means that in an installed project only the real files are scanned and `.claude/agents/` symlinks are not double-counted — this is correct and avoids a TOCTOU-style discrepancy. The validator is read-only (no `Write`/`Edit`/`unlink`/`chmod`), so it cannot itself mutate state. The change is a net security *improvement*: it closes the silently-fail-open `allowed-tools:` privilege-escalation footgun for CWF agent definitions.

The diff also ships only the wf step planning docs (`a-`, `d-`, `e-`), the wire-in, and the hash entries — all consistent with the implemented module. No secrets, no credentials, no network calls introduced.

Conclusion: the changeset is clean. The only items raised are category-(e) future-reuse framings, which the threat model explicitly admits as informational signal rather than actionable defects in this diff.

```cwf-review
state: no findings
summary: Read-only frontmatter linter; no shell/env/git-output/prompt-injection surface introduced; shipped Agents.pm sha256 matches recorded hash. Only category-(e) future-reuse framings noted (path concat safe due to cwf-* namespace grep).
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

## Lessons Learned
For a bounded-block scan, locate the terminator before inspecting the interior — a
single-pass flag-on-first-match leaks past an unterminated block (the TC-7 defect). See
j-retrospective.md.
