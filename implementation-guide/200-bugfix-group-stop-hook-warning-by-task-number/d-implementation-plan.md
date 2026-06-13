# Group Stop-hook warning by task number - Implementation Plan
**Task**: 200 (bugfix)

## Task Reference
- **Task ID**: internal-200
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/200-group-stop-hook-warning-by-task-number
- **Template Version**: 2.1

## Goal
Implement Group Stop-hook warning by task number following the approved design and requirements.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cwf/scripts/hooks/stop-uncommitted-changes-warning` — add CWF lib loading
  (`FindBin`/`use lib`/`use CWF::TaskPath qw(parse_dirname)`); replace the
  basename-flatten + flat-cap block with derive→group→per-group-render logic.

### Supporting Changes
- `.cwf/security/script-hashes.json` — refresh the `stop-uncommitted-changes-warning`
  sha256 in the **same commit** as the edit (hash-updates convention); chmod the
  working file back to the recorded **0500**.
- `t/stop-uncommitted-changes-warning.t` — NEW test (authored in g-testing-exec
  per the e-testing-plan); no prior test exists for this hook.

## Implementation Steps
### Step 1: Edit the hook
- [ ] Add `use FindBin; use lib "$FindBin::Bin/../../lib"; use CWF::TaskPath qw(parse_dirname);`
      at the top (matching `stop-stale-status-detector:14-17`).
- [ ] Retain the unchanged git query and the `return unless @records` guard.
- [ ] Replace the flatten/flat-cap block with the derive→group→render block (below).

### Step 2: Refresh integrity
- [ ] `chmod 0500` the hook (recorded perms ceiling), then refresh its sha256 in
      `.cwf/security/script-hashes.json` (same commit).

### Step 3: Validation
- [ ] `prove -v t/stop-uncommitted-changes-warning.t` green (see e-testing-plan).
- [ ] `.cwf/scripts/cwf-manage validate` clean (hash + perms).

## Code Changes
### Before (`stop-uncommitted-changes-warning`, eval body)
```perl
my @dirty = map { m{([^/]+)$} ? $1 : $_ }
            map { substr($_, 3) } @records;

my @display = @dirty[0 .. ($#dirty > 2 ? 2 : $#dirty)];
my $msg = join(', ', @display);
$msg .= " +@{[$#dirty - 2]} more" if @dirty > 3;

print qq({"systemMessage":"⚠ Uncommitted: $msg"}\n);
```

### After
Top-of-file (after `use utf8;`):
```perl
use FindBin;
use lib "$FindBin::Bin/../../lib";
use CWF::TaskPath qw(parse_dirname);
```
eval body (replacing the `@dirty`…`print` block; query + guard unchanged):
```perl
my (@order, %files);                       # task keys (first-seen) + key => [basenames]
for my $rec (@records) {
    my @seg  = split m{/}, substr($rec, 3);
    my $file = $seg[-1];
    my $dir  = @seg >= 2 ? $seg[-2] : '';
    my ($num) = parse_dirname($dir);       # () → undef for a non-task dir
    my $key  = defined $num ? $num : $dir; # fallback: raw parent-dir basename
    push @order, $key unless exists $files{$key};
    push @{ $files{$key} }, $file;
}

my $multi = @order > 1;
my @groups;
for my $key (@order) {
    my @f    = @{ $files{$key} };
    my @show = @f[0 .. ($#f > 2 ? 2 : $#f)];
    my $g    = join(', ', @show);
    $g      .= " +@{[$#f - 2]} more" if @f > 3;
    $g       = "$key: $g" if $multi;
    push @groups, $g;
}
my $msg = join('; ', @groups);

print qq({"systemMessage":"⚠ Uncommitted: $msg"}\n);
```
Per-group cap reuses today's `3`/`+k more` arithmetic; the `$multi` toggle gives
byte-identical single-task output. JSON envelope, `eval`, and `exit 0` unchanged.

**Accepted trade-off (compile-time load):** the `use CWF::TaskPath` happens at
compile time, *outside* the runtime `eval`, so a broken install would die
non-zero rather than exit 0. This matches the sibling `stop-stale-status-detector`
exposure exactly and is a desirable broken-install signal, not a regression.
The pre-existing unescaped-basename JSON interpolation (design D3) is inherited
unchanged and remains out of scope.

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All three steps executed as planned: hook edited with the lib-loading + derive→
group→render block exactly as specified, sha256 refreshed in the same commit with
perms clamped to the recorded 0500, and validation green. One unplanned deviation,
handled per convention: `cwf-manage validate` surfaced a **pre-existing, unrelated**
permission drift (`security-review-changeset` 0700, recorded 0500); clamped on
sight via `cwf-manage fix-security` (fix-on-sight convention) rather than deferred.
No change to the planned code.

## Lessons Learned
*Captured in j-retrospective.md*
