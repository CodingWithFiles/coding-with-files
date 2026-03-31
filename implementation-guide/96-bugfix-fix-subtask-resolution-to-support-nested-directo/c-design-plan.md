# Fix subtask resolution to support nested directory hierarchy — Design
**Task**: 96 (bugfix)

## Task Reference
- **Task ID**: internal-96
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/96-fix-subtask-resolution-nested-hierarchy
- **Template Version**: 2.1

## Directory Structure Convention

Subtask directories are nested inside their parent's directory:

```
implementation-guide/
├── 48-feature-parent/
│   ├── a-task-plan.md
│   ├── ...
│   ├── 48.1-bugfix-child/
│   │   ├── a-task-plan.md
│   │   └── ...
│   └── 48.2-chore-other/
│       └── ...
└── 49-feature-standalone/
    └── ...
```

Top-level tasks (no dots) resolve flat from `implementation-guide/`. Subtasks resolve by walking the ancestor chain.

## Key Design Decision: Iterative Ancestor Walk

### Resolution algorithm for `resolve_num("48.1.3")`

1. Split into ancestor chain: `["48", "48.1", "48.1.3"]`
2. Resolve "48" in `implementation-guide/` → `implementation-guide/48-feature-parent/`
3. Resolve "48.1" inside step 2 result → `implementation-guide/48-feature-parent/48.1-bugfix-child/`
4. Resolve "48.1.3" inside step 3 result → `implementation-guide/48-feature-parent/48.1-bugfix-child/48.1.3-chore-whatever/`

Each level uses a simple `glob("$parent_dir/$num-*-*")` — no recursive filesystem walk needed.

### Rationale
- Deterministic: path is derived directly from the task number, not discovered by scanning
- O(depth) globs — max realistic depth is 3–4
- Top-level tasks (no dots) are unchanged: single glob in `implementation-guide/`

## Changes by Component

### 1. `CWF::TaskPath::resolve_num()` (core fix)

Current: `glob("$base_dir/$num-*-*")` — flat only.

New: iterative ancestor walk.

```
resolve_num("48.1.3", $base_dir):
  parts = split(".", "48.1.3")  → ["48", "1", "3"]
  current_dir = $base_dir       → "implementation-guide/"
  
  for i in 0..len(parts)-1:
    ancestor_num = join(".", parts[0..i])  → "48", "48.1", "48.1.3"
    matches = glob("$current_dir/$ancestor_num-*-*")
    if no matches → return undef
    current_dir = matches[0]
  
  return parse(current_dir)
```

For top-level tasks (no dots), this is exactly one glob — same as before.

### 2. `CWF::TaskPath::build_glob()` 

Currently used by `resolve_num()` and `find_children()`. Since `resolve_num()` will now do its own iterative walk, `build_glob()` becomes a helper for single-level lookup within a known parent directory:

```
build_glob("48.1", "/path/to/48-feature-parent/")
  → "/path/to/48-feature-parent/48.1-*-*"
```

No signature change needed — it already takes `$base_dir`. Callers just need to pass the resolved parent dir instead of the top-level base.

### 3. `CWF::TaskPath::find_children()`

Current: `glob("$base_dir/$num.*-*-*")` — searches flat.

New: resolve the task first to get its directory, then glob inside it.

```
find_children("48", $base_dir):
  task = resolve_num("48", $base_dir)
  glob("$task->{full_path}/48.*-*-*")  → nested children
```

### 4. `CWF::TaskPath::find_siblings()`

Sibling search: resolve parent, then find children of parent. Already delegates to `find_children` — no change needed if `find_children` is fixed.

### 5. `template-copier-v2.1::construct_destination()`

Current: `"$base_path/$task_dir"` — always flat.

New: if task number contains dots, resolve the parent and nest inside it.

```
construct_destination("48.1", "bugfix", "fix-something"):
  parent_num = get_parent("48.1")  → "48"
  parent = resolve_num("48", $base_dir)
  return "$parent->{full_path}/48.1-bugfix-fix-something"
```

For top-level tasks (no dots), same as before: `"$base_path/$task_dir"`.

### 6. Status aggregators (v2.0, v2.1)

The v2.1 aggregator already has recursive `build_tree` that searches inside task dirs for subtasks (line 285). The initial glob at line 224 searches `implementation-guide/*-*-*` for top-level tasks, then recurses. **This should already work with nesting** — verify during testing, no code change expected.

Check v2.0 aggregator similarly.

### 7. Context inheritance scripts (v2.0, v2.1)

Line 62: `resolve($task_path, $base_dir)` — this calls `resolve_num()` which will be fixed.
Line 81: `resolve($parent_num, $base_dir)` — same fix applies.

**No changes needed** — they delegate to `resolve()` which delegates to `resolve_num()`.

### 8. Skill docs

**`cwf-new-task/SKILL.md`** — Step 2: replace ambiguous "create subdirectory" with explicit example:
```
- Subtask: Resolve parent via `context-manager hierarchy`, then create inside parent dir
  e.g. task 48.1 → `implementation-guide/48-feature-parent/48.1-bugfix-slug/`
```

**`cwf-subtask/SKILL.md`** — Step 3: add explicit path example showing nesting.

## Files to Modify

| File | Change |
|------|--------|
| `.cwf/lib/CWF/TaskPath.pm` | `resolve_num()`: iterative ancestor walk; `find_children()`: look inside resolved dir |
| `.cwf/scripts/command-helpers/template-copier-v2.1` | `construct_destination()`: resolve parent, nest inside |
| `.claude/skills/cwf-new-task/SKILL.md` | Explicit nested path example |
| `.claude/skills/cwf-subtask/SKILL.md` | Explicit nested path example |

## Files to Verify (no code change expected)

| File | Why |
|------|-----|
| `.cwf/scripts/command-helpers/status-aggregator-v2.1` | Already recursive — verify it works |
| `.cwf/scripts/command-helpers/status-aggregator-v2.0` | Same |
| `.cwf/scripts/command-helpers/context-inheritance-v2.1` | Delegates to `resolve()` — verify |
| `.cwf/scripts/command-helpers/context-inheritance-v2.0` | Same |
| `.cwf/scripts/command-helpers/context-manager.d/hierarchy` | Delegates to `resolve()` — verify |

## Backward Compatibility

- Top-level tasks (no dots in number): resolution path is identical — single glob in `implementation-guide/`
- Existing flat subtasks (if any): will NOT be found by the new nested resolution. This is intentional — flat subtasks were never correctly supported and should be moved into their parent directory. Document migration in release notes.

## Constraints
- `glob()` treats dots literally — no escaping needed
- Git branch names remain flat (`bugfix/48.1-slug`, not `bugfix/48/48.1-slug`) — git limitation
- `find_base_dir()` is unchanged — always returns `implementation-guide/`

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 96
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
