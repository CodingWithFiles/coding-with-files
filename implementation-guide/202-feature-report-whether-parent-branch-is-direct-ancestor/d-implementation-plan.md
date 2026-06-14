# report whether parent branch is direct ancestor - Implementation Plan
**Task**: 202 (feature)

## Task Reference
- **Task ID**: internal-202
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/202-report-whether-parent-branch-is-direct-ancestor
- **Template Version**: 2.1

## Goal
Implement the parent-branch ancestry signal per the approved design: hoist a
shared list-form git runner into `CWF::Common`, add
`parent_branch_ancestry` to `CWF::TaskPath`, and surface it additively in
`context-manager.d/hierarchy`.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cwf/lib/CWF/Common.pm` — add exported `run_quiet(@cmd)` (list-form
  fork/exec; child `POSIX::_exit(127)` after failed exec; `$? >> 8`; `-1` on
  fork failure). Add `use POSIX ()`; add `run_quiet` to `@EXPORT_OK` (line 14).
- `.cwf/lib/CWF/TaskPath.pm` — add `parent_branch_ancestry($task_path)` returning
  `1`/`0`/`undef`; add it to `@EXPORT_OK` (lines 17-24); add `run_quiet` to the
  existing `use CWF::Common qw(find_git_root)` import (line 15).
- `.cwf/scripts/command-helpers/context-manager.d/hierarchy` — add
  `parent_branch_ancestry` to the `use CWF::TaskPath qw(...)` import (line 28);
  call it after `resolve`; emit JSON field + conditional markdown line.

### Supporting Changes
- `.cwf/scripts/command-helpers/task-workflow.d/delete` — remove local
  `run_quiet` (lines 44-56); add `run_quiet` to `use CWF::Common qw(check_perl5opt)`
  import (line 24). Exit-path hardened: the failed-`exec` child goes `exit 127` →
  `POSIX::_exit(127)`, so inherited END blocks (delete imports `File::Path
  remove_tree`) no longer run in that child — observable exit codes unchanged.
- `.cwf/security/script-hashes.json` — refresh hashes for all four files above in
  the **same exec commit** (per `hash-updates.md`; `cwf-manage fix-security` after
  edits, with per-file `git log` verification).
- `t/tool-check.t`-style sibling — new/extended test files (see Test Coverage).

## Implementation Steps
### Step 1: Shared runner (Common)
- [ ] Add `use POSIX ();` to `Common.pm`.
- [ ] Add `run_quiet` sub: `fork`; child redirects STDIN/OUT/ERR to `/dev/null`,
      `exec(@cmd) or POSIX::_exit(127);` (the `or` form — keeps it warning-clean
      under `use warnings`, vs a bare follow-on statement); parent `waitpid`,
      return `$? >> 8`; `return -1` if `fork` undef.
- [ ] Append `run_quiet` to `@EXPORT_OK`.

### Step 2: Ancestry function (TaskPath)
- [ ] Add `run_quiet` to the `use CWF::Common` import.
- [ ] Implement `parent_branch_ancestry($task_path)`:
      - `my $parent = get_parent($task_path); return undef unless defined $parent;`
      - `my $p = resolve($parent); return undef unless $p;`
      - `my $branch = format_branch($p->{num}, $p->{type}, $p->{slug});`
      - existence: `return undef if run_quiet('git','rev-parse','--verify',
        '--quiet',"refs/heads/$branch") != 0;` — deliberately list-form rather
        than the existing `branch_exists` (which is backtick/shell form,
        `TaskPath.pm:510`), per NFR3. Also exact-match (`refs/heads/...`) vs
        `branch_exists`'s `git branch --list` glob — see the prefix-collision test.
      - ancestry: `my $rc = run_quiet('git','merge-base','--is-ancestor',$branch,
        'HEAD'); return 1 if $rc == 0; return 0 if $rc == 1; return undef;`
- [ ] Append `parent_branch_ancestry` to `@EXPORT_OK`.

### Step 3: hierarchy output
- [ ] Add `parent_branch_ancestry` to the `use CWF::TaskPath qw(...)` import.
- [ ] After `resolve`, compute `my $anc = parent_branch_ancestry($task_path);`.
- [ ] JSON: add a comma to the `depth` line, then append
      `  "parent_branch_is_ancestor": <literal>` where
      `<literal> = defined($anc) ? ($anc ? 'true':'false') : 'null'`.
- [ ] Markdown: inside the existing `if ($result->{parent_path})` block (or a
      sibling guarded the same way), print
      `Parent branch ancestor of HEAD: <yes|no|unknown>` where
      `defined($anc) ? ($anc ? 'yes':'no') : 'unknown'`.

### Step 4: delete refactor
- [ ] Add `run_quiet` to `delete`'s `use CWF::Common` import; delete the local
      sub (lines 44-56). Confirm all in-file `run_quiet(...)` call sites resolve
      to the imported one (7 call sites: lines 143, 179, 209, 280, 290, 299, 308).

### Step 5: Tests (see e-testing-plan)
- [ ] Unit-test `parent_branch_ancestry` against a synthetic git repo for
      ancestor / diverged / no-parent / missing-branch (and same-tip ⇒ true).
- [ ] Prefix-collision case: with `feature/1-foo` present, querying a task whose
      parent branch is `feature/1-foobar` (absent) MUST be `null` — proves
      `rev-parse --verify refs/heads/...` exact-matches where a `--list` glob
      would false-positive.
- [ ] hierarchy output assertions: pipe `--format=json` through a real JSON
      parser (not a regex) for one parented and one top-level task — hard
      requirement, since the serialiser is hand-rolled and a missed comma yields
      malformed JSON silently. Plus markdown line / no-line assertions.
- [ ] Run full `t/` suite — no regressions (esp. delete's tests, incl. its
      failed-exec / cleanup path).

### Step 6: Integrity + validation
- [ ] `cwf-manage fix-security` to refresh the four hashes; verify each file's
      `git log` shows this task's edit before refreshing (hash-updates).
- [ ] `cwf-manage validate` clean.

## Code Changes
Pseudocode is in the Implementation Steps above; the change is small and the
exact insertions are unambiguous, so no before/after block is duplicated here
(per "code is the documentation").

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.
This includes the `delete` refactor and the hash refresh — they are in-scope, not
deferrable. The only explicitly-deferred item is any broader `run_quiet` adoption
by *other* existing call sites, which is out of scope for this task.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Steps 1–6 executed verbatim (see f-implementation-exec.md). All seven `delete`
call sites resolved to the imported runner with the only behavioural delta being
`exit 127`→`POSIX::_exit(127)`. Step 5 new-test authoring was carried out under
g-testing-exec per the CWF phase split (not a deferral). Step 6 hash refresh: the
four sha256 entries were updated manually from `sha256sum` because
`cwf-manage fix-security` refuses content-hash rewrites by design — and two
pre-existing perms-only drifts on untouched files were clamped fix-on-sight.
The in-scope `delete` refactor and hash refresh were completed; only broader
`run_quiet` adoption by *other* call sites was left out of scope as planned.

## Lessons Learned
*Consolidated in j-retrospective.md.*
