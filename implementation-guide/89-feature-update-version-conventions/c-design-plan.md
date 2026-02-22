# Update version conventions - Design
**Task**: 89 (feature)

## Task Reference
- **Task ID**: internal-89
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/89-update-version-conventions
- **Template Version**: 2.1

## Goal
Design the CLAUDE.md addition and the `cwf-manage list-releases` filter algorithm.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

---

## Change 1: `CLAUDE.md` — Versioning section

### Decision
Add a `## Versioning` section at the end of the project-level `CLAUDE.md`. No new files.

### Content
```markdown
## Versioning

CWF uses `v{major}.{minor}.{task_num}` semver tags on the main branch.

- **major**: breaking changes — wf file format changes, removal of installed features,
  install script incompatibilities
- **minor**: new user-visible features (new skills, new workflow phases, new helper scripts)
- **patch = task_num**: CWF task number of the most recently completed task at time of
  tagging; never set manually

**Tagging, pushing tags, and creating GitHub releases are human-only actions.** Models
must not `git tag`, `git push --tags`, create releases, or suggest merging to main.

**This convention is internal to CWF development.** Do not reference this section from
any installed file (`.cwf/docs/`, `.cwf/templates/`, `.cwf/scripts/`, or skills).
```

### Rationale
- `CLAUDE.md` is project instructions, never installed — satisfies the isolation constraint
- Single section at end is easily skippable by models reading the file for other purposes

---

## Change 2: `cwf-manage list-releases` — filtered view

### Architecture: two new subs + `--all` flag

**`parse_semver($tag)`** — returns `(major, minor, patch)` as integers, or `undef` if the
tag is not strict 3-part semver (`v\d+\.\d+\.\d+`). Non-semver tags are silently skipped,
preserving current behaviour for arbitrary tag names.

**`filter_releases($current, @sorted_tags)`** — pure function, no I/O, fully unit-testable.
Takes the current version string and a list of all tags (sorted descending). Returns the
filtered display list (excluding current; caller appends it).

Algorithm:
1. Parse current into `(M, m, N)`. If unparseable, return all tags (safe fallback).
2. For each tag (skip current, skip non-semver):
   - Assign to exactly one bucket or discard:
     - `same-minor`  if major==M, minor==m, patch>N
     - `minor-{x}`   if major==M, minor==x where x>m
     - `major-{x}`   if major==x where x>M
     - discard       if older than or equal to current in any dimension
   - Within each bucket keep only the highest-version tag (compare via existing `version_cmp`)
3. Return bucket values sorted descending.

**`cmd_list_releases($git_root, $show_all)`** — updated signature. `$show_all` is a boolean
passed from `main` after checking `@ARGV` for `--all`.

- `--all` path: identical to current behaviour (no filter, no footer)
- Default path:
  1. Call `filter_releases` to get upgrade candidates
  2. Merge current version into display list at its natural sorted position
  3. Print descending; mark current with ` (installed)`
  4. If hidden count > 0: print footer `Run 'cwf-manage list-releases --all' to see all N releases.`

### Example outputs

**On `v0.1.88`, remote has `v0.1.89`, `v0.1.90`, `v0.2.95`, `v1.0.103`:**
```
[CWF] Available releases from <source>
  v1.0.103
  v0.2.95
  v0.1.90
  v0.1.88  (installed)

  Run 'cwf-manage list-releases --all' to see all 4 releases.
```
(v0.1.89 is hidden — not the latest on its minor)

**On `v0.1.90`, already the latest overall:**
```
[CWF] Available releases from <source>
  v0.1.90  (installed)
```
(no footer — nothing hidden)

**On `v0.1.88`, remote only has `v0.1.88`:**
```
[CWF] Available releases from <source>
  v0.1.88  (installed)
```

### Integration point in `main`

```perl
'list-releases' => sub {
    my $all = grep { $_ eq '--all' } @ARGV;
    cmd_list_releases($git_root, $all);
},
```

No `Getopt` needed — single known flag, simple grep suffices.

### `cmd_help` update

Add `--all` to the `list-releases` line:
```
  list-releases [--all]    List available tagged releases from the CWF remote
```

---

## Constraints
- No new CPAN modules
- `version_cmp` reused as-is — `parse_semver` is separate (strict 3-part only, returns undef)
- `--all` must not change the output format, only the filter

## Decomposition Check
- [ ] **Time**: No
- [ ] **People**: No
- [ ] **Complexity**: No
- [ ] **Risk**: No
- [ ] **Independence**: N/A

No decomposition needed.

## Validation
- [ ] `parse_semver` and `filter_releases` are pure functions testable without network
- [ ] All 6 edge cases from NFR1 covered in unit tests
- [ ] `grep -r "Versioning" .cwf/` returns no matches after implementation

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 89
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Design implemented as specified. Closure-based @rules pattern adopted in place of
if/elsif chain after discussion; cleaner separation of business rules from pipeline.

## Lessons Learned
Pre-sorted descending input eliminates the need for explicit max comparison in buckets —
first-seen deduplication via %seen is sufficient when input order is guaranteed.
