# Fix subtask resolution to support nested directory hierarchy — Implementation Plan
**Task**: 96 (bugfix)

## Task Reference
- **Task ID**: internal-96
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/96-fix-subtask-resolution-nested-hierarchy
- **Template Version**: 2.1

## Files to Modify

### Primary Changes
- `.cwf/lib/CWF/TaskPath.pm` — Rewrite `resolve_num()` with iterative ancestor walk; update `find_children()` to search inside resolved task dir
- `.cwf/scripts/command-helpers/template-copier-v2.1` — Update `construct_destination()` to nest subtasks inside resolved parent dir

### Skill Doc Changes
- `.claude/skills/cwf-new-task/SKILL.md` — Replace ambiguous "create subdirectory" with explicit nested path example
- `.claude/skills/cwf-subtask/SKILL.md` — Add explicit nested path example in Step 3

### Verify Only (no code change expected)
- `.cwf/scripts/command-helpers/status-aggregator-v2.1` — Already recursive; confirm nesting works
- `.cwf/scripts/command-helpers/status-aggregator-v2.0` — Same
- `.cwf/scripts/command-helpers/context-inheritance-v2.1` — Delegates to `resolve()`; confirm
- `.cwf/scripts/command-helpers/context-inheritance-v2.0` — Same
- `.cwf/scripts/command-helpers/context-manager.d/hierarchy` — Same

## Implementation Steps

### Step 1: Rewrite `resolve_num()` in `TaskPath.pm`
- [ ] Replace flat glob with iterative ancestor walk
- [ ] For top-level tasks (no dots): single glob in `$base_dir` — unchanged behaviour
- [ ] For subtasks: split on dots, resolve each ancestor level inside the previous
- [ ] Return same hashref structure (full_path, num, type, slug, format, parent_path, depth)

### Step 2: Update `find_children()` in `TaskPath.pm`
- [ ] Resolve the task first to get its directory
- [ ] Glob `"$task_dir/$num.*-*-*"` instead of `"$base_dir/$num.*-*-*"`
- [ ] Filter to immediate children only (existing logic)

### Step 3: Update `construct_destination()` in `template-copier-v2.1`
- [ ] If task number contains dots: resolve parent via `resolve_num()`, nest inside parent's `full_path`
- [ ] If top-level (no dots): keep existing `"$base_path/$task_dir"` behaviour

### Step 4: Update skill docs
- [ ] `cwf-new-task/SKILL.md` Step 2: explicit nested path example
- [ ] `cwf-subtask/SKILL.md` Step 3: explicit nested path example

### Step 5: Create test fixtures and verify
- [ ] Create a nested subtask structure for testing (temporary dirs)
- [ ] Run `context-manager hierarchy` against nested subtask
- [ ] Run `context-manager inheritance` against nested subtask
- [ ] Run status aggregator against nested hierarchy
- [ ] Verify top-level resolution still works (regression check)

## Code Changes

### `resolve_num()` — Before
```perl
sub resolve_num {
    my ($num, $base_dir) = @_;
    $num = normalize($num);
    unless (validate($num)) { return undef; }
    $base_dir //= find_base_dir();
    return undef unless $base_dir;
    my $pattern = build_glob($num, $base_dir);
    my @matches = glob($pattern);
    return undef unless @matches;
    # ... parse and return
}
```

### `resolve_num()` — After
```perl
sub resolve_num {
    my ($num, $base_dir) = @_;
    $num = normalize($num);
    unless (validate($num)) { return undef; }
    $base_dir //= find_base_dir();
    return undef unless $base_dir;

    # Iterative ancestor walk
    my @parts = split(/\./, $num);
    my $current_dir = $base_dir;

    for my $i (0 .. $#parts) {
        my $ancestor_num = join(".", @parts[0 .. $i]);
        my $pattern = build_glob($ancestor_num, $current_dir);
        my @matches = glob($pattern);
        return undef unless @matches;
        $current_dir = $matches[0];
    }

    # Parse the final resolved directory
    my $dir_name = basename($current_dir);
    unless ($dir_name =~ /^([0-9.]+)-([a-z]+)-(.+)$/) { return undef; }
    # ... return hashref with $current_dir as full_path
}
```

### `find_children()` — Before
```perl
my @child_dirs = glob("$base_dir/$num.*-*-*");
```

### `find_children()` — After
```perl
my $task = resolve_num($num, $base_dir);
return () unless $task;
my @child_dirs = glob("$task->{full_path}/$num.*-*-*");
```

### `construct_destination()` — Before
```perl
return "$base_path/$task_dir";
```

### `construct_destination()` — After
```perl
if ($params->{task_num} =~ /\./) {
    my $parent_num = get_parent($params->{task_num});
    my $parent = resolve_num($parent_num);
    if ($parent) {
        return "$parent->{full_path}/$task_dir";
    }
}
return "$base_path/$task_dir";
```

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 96
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
