# Group Stop-hook warning by task number - Implementation Execution
**Task**: 200 (bugfix)

## Task Reference
- **Task ID**: internal-200
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/200-group-stop-hook-warning-by-task-number
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

See d-implementation-plan.md for the planned steps and before/after code.

## Actual Results

### Step 1: Edit the hook
- **Planned**: Add `FindBin`/`use lib`/`use CWF::TaskPath qw(parse_dirname)`;
  replace the basename-flatten + flat-cap block with derive→group→render logic.
- **Actual**: Added the three `use` lines after `use utf8;` (matching
  `stop-stale-status-detector:14-17`); replaced the `@dirty`…`print` block with
  the derive→group→per-group-render block verbatim from the plan. Git query and
  `return unless @records` guard unchanged.
- **Deviations**: None.

### Step 2: Refresh integrity
- **Planned**: chmod 0500; refresh sha256 in script-hashes.json (same commit).
- **Actual**: `chmod 0500` applied; sha256 updated
  `510d1bf9…` → `e5d1fc72…` in `.cwf/security/script-hashes.json`.
  `cwf-manage validate` initially surfaced a **pre-existing** permission drift on
  an unrelated file (`security-review-changeset`, 0700 vs recorded 0500); clamped
  on sight via `cwf-manage fix-security` per the permission-drift convention.
  Re-validate: `validate: OK`.
- **Deviations**: The unrelated permission-drift fix was not in the plan; handled
  per the fix-on-sight convention. (chmod-only, no tracked-content change.)

### Step 3: Validation
- **Planned**: prove the new test green; `cwf-manage validate` clean.
- **Actual**: `cwf-manage validate` clean. Hook smoke-tested live in the repo —
  single dirty task ⇒ `⚠ Uncommitted: f-implementation-exec.md, g-testing-exec.md,
  j-retrospective.md` (no number prefix, baseline-identical). The new
  `t/stop-uncommitted-changes-warning.t` is authored and run in g-testing-exec
  per the e-testing-plan.
- **Deviations**: None.

## Blockers Encountered

None.

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
Reusing `CWF::TaskPath::parse_dirname` rather than inlining a fourth copy of the
task-number regex kept the change single-source and let the design lean on the
sibling hook's established lib-loading pattern. The fix-on-sight convention paid
off: the unrelated permission drift would otherwise have lingered as "not my
change" — clamping it immediately kept `validate` green for the checkpoint.

## Security Review

**State**: no findings

I have everything I need. Let me reason through the five threat categories.

## Security review — implementation-exec changeset, Task 200

The changeset modifies one executable hook (`.cwf/scripts/hooks/stop-uncommitted-changes-warning`), refreshes its sha256 in `script-hashes.json`, and adds the task's wf step files (process docs, no executable content). My review focuses on the hook; the wf-step markdown is informational and carries no code paths.

**(a) Bash injection / unsafe command construction.** The hook runs exactly one external command — the `git status --porcelain -z` backtick on line 20. That command is byte-identical to the baseline: a fixed string with no interpolation of any variable. The new code (lines 25-46) is pure in-process string manipulation — `split`, array slicing, `join` — and spawns no further subprocess. No shell metacharacter exposure is introduced. Clean.

**(b) Perl git-output handling without `-z` / input validation.** The hook continues to use `--porcelain -z` and `split /\0/` (line 21), the correct NUL-separated pattern per `git-path-output.md`. The new parsing on line 27 splits the *already NUL-delimited* record on `/` to get path segments — this operates within a single record, so embedded newlines in a filename cannot corrupt record boundaries (those were already handled by the `-z` split). `substr($_, 3)` to strip the porcelain status prefix is unchanged from baseline. `use utf8;` is present; the shebang is `#!/usr/bin/env perl`. The new dependency `CWF::TaskPath::parse_dirname` is a pure-regex parser returning `()` on non-match, and the call site correctly defends against that with `my ($num) = parse_dirname($dir); my $key = defined $num ? $num : $dir;` — no `undef` interpolation, no crash on a malformed parent dir. Clean.

**(c) Prompt injection via user-supplied strings.** No `{arguments}` substitution and no LLM-context flow here. The hook emits a `systemMessage` consumed by the harness. The basenames and task keys interpolated into the JSON on line 48 derive from repo-resident file paths matching the `[a-j]-*.md` pathspec, not from free-text user input. No new prompt-injection surface.

**(e) Pattern-based risk — unescaped interpolation into the JSON envelope (line 48).** This is the one item worth flagging, and the design doc (D3, lines 226-234) already pre-discloses it: `$msg` is built from filename basenames and task keys and interpolated raw into `qq({"systemMessage":"⚠ Uncommitted: $msg"}\n)` with no JSON string-escaping. A filename containing a `"`, `\`, or control character would produce malformed JSON. I confirm this is **pre-existing and not regressed** by this change — the baseline interpolated the same unescaped basenames at the same point. Task 200 actually *narrows* the new interpolated tokens to digits-and-dots (the `parse_dirname` task number) plus the fallback raw parent-dir basename and the literal separators `: `, `, `, `; `, none of which add JSON-special characters. So:

  - Safe here because the interpolated values are repo-authored wf filenames bounded by the `[a-j]-*.md` pathspec, and the hook is advisory with `exit 0` preserved (a malformed line degrades a warning, it does not execute anything).
  - Audit future uses where that invariant might not hold: if this hook's pathspec is ever widened to user-named files, or if the `systemMessage` JSON-building pattern is copied to a context fed by less-constrained strings, the missing escaping becomes a real malformed-output (or, in a worse consumer, injection) bug. Fixing generic JSON escaping is reasonably out of scope for this byte-identical-single-task bugfix, as the design states.

**(d) Unsafe environment-variable handling.** The hook reads no environment variables (the `FindBin`/`use lib` path is derived from `$FindBin::Bin`, a script-location constant, not env). No `chmod`/`rm`/`open` on env-derived paths. Not applicable.

**Integrity note (not a finding):** the sha256 refresh for the hook lands in the same changeset as the edit, per the hash-updates convention, and recorded perms stay `0500`. Hash/permission correctness is the deterministic domain of `cwf-manage validate`, so I do not adjudicate it here — noted only to confirm it was not omitted.

**Compile-time-load exposure (not a finding):** `use CWF::TaskPath` is outside the runtime `eval`, so a broken install dies non-zero rather than exiting 0. This matches the sibling `stop-stale-status-detector` exactly and is a desirable broken-install signal, not a security regression.

Conclusion: no actionable security findings. The single pattern-risk item (unescaped JSON interpolation) is pre-existing, correctly disclosed in the design, and not regressed — narrowed, if anything — by this change.

Relevant files:
- `/home/matt/repo/coding-with-files/.cwf/scripts/hooks/stop-uncommitted-changes-warning`
- `/home/matt/repo/coding-with-files/.cwf/lib/CWF/TaskPath.pm` (the reused `parse_dirname`, lines 305-314)

```cwf-review
state: no findings
summary: Hook change is in-process string handling only; the unescaped-JSON interpolation is pre-existing, design-disclosed, and narrowed (not regressed) by this diff.
```
