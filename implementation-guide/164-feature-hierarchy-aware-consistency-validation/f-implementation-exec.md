# hierarchy-aware consistency validation - Implementation Execution
**Task**: 164 (feature)

## Task Reference
- **Task ID**: internal-164
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/164-hierarchy-aware-consistency-validation
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met (TaskPath exports + signatures confirmed against source)
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Status updated to Finished when complete

## Actual Results

### Step 1: Imports and predicate helpers
- **Planned**: import the four `CWF::TaskPath` string primitives; add `_is_ancestor`.
- **Actual**: `use CWF::TaskPath qw(get_parent get_depth parse_dirname version_compare);` added;
  `_is_ancestor` is the `get_parent`-chain `eq` walk verbatim from the plan. Verified all four
  are in `@EXPORT_OK` (TaskPath.pm:16-23) and that `normalize` is a pass-through for dotted
  numbers (no slash), so `get_parent`/`get_depth` behave as the plan assumed.

### Step 2: Recursive node collection
- **Planned**: `_collect_nodes` (`-l` before `-d`, `parse_dirname` gate) + `_build_node`.
- **Actual**: implemented as planned. `parse_dirname` (`^(\d+(?:\.\d+)*)-(\w+)-(.+)$`) replaces
  the inline `:41` regex; the `-l`-before-`-d` ordering is preserved.

### Step 3: Rework `validate` into the orchestrator
- **Actual**: `return () unless -d $ig_dir` kept; collect → leaf id (fail-closed on 0/≥2) →
  directional branch pass → completeness pass. `_extract_fields`, `_current_branch`,
  `_violation`, `$TERMINAL_STATUSES`, `$TASK_REF_SECTION_RE` unchanged and reused.

### Step 4: Integrity + perms
- **Actual**: `sha256sum` → `d772d571…f95dd`; `script-hashes.json:104` refreshed in this same
  change. Live `.cwf/scripts/cwf-manage validate` → `OK` (flat path only — no on-disk subtasks —
  so this is the FR5 live-repo no-regression check).
- **Perms correction**: the plan's "restore working perms to 0700" step cites
  `feedback_hashed_script_working_perms`, which is scoped to *executable scripts* that carry a
  recorded `permissions` field. `Consistency.pm` is a `use`d library module: its
  `script-hashes.json` entry records `path` + `sha256` only (no `permissions` key — unlike the
  `.claude/agents/*` and script entries), so `validate` does not check its mode, and every
  sibling `CWF::Validate::*` module is committed `100644` (working `0600`). An initial
  `chmod 0700` committed it `100755` (an anomaly + semantically wrong for a non-executable
  module); restored to `0600` so the tracked mode is `100644`, matching siblings. chmod does not
  change content, so the recorded `sha256` is unaffected.

### Step 5: Tests
- **Actual**: existing `t/validate-consistency.t` (5 tests) pass unchanged; full `prove t/` green
  after the hash refresh (585 tests). New hierarchy fixtures are the g-testing-exec deliverable.

## Deviations
- **`_build_node` takes a third arg `$dir_name` (directory basename)**, where the plan's literal
  code passed only `($path, $dir_num)`. Reason: the pre-change `**Task**` fix message ended
  "…to match directory name `$task_dir`" using the *full basename*; the plan's draft text had
  shortened it to "…to match directory `$dir_num`". Passing the basename keeps the violation
  hashref **byte-identical** to pre-change output, which FR5/AC5 require. Strictly tighter than
  the plan; no behaviour lost.
- **Branch violations are emitted after all `**Task**` violations (grouped by category), not
  interleaved per-directory as the old single loop did.** This is structural: the directional
  rule must see the whole node set to identify the leaf before it can judge any one node, so the
  branch pass cannot run inside collection. Output is byte-identical for the existing fixtures
  and any pure-flat repo whose only findings are branch mismatches; the orderings diverge only
  in a multi-directory repo that has *both* a `**Task**` mismatch and a branch mismatch — not
  exercised by any fixture, and `validate` output is an advisory unordered set (printed in full
  by `cwf-manage`, no consumer depends on inter-category order).

## Blockers Encountered
None. (The two transient `prove t/` failures — `cwf-manage-fix-security.t`,
`cwf-manage-update-end-to-end.t` — were the expected hash-drift signal from editing a
hash-tracked file; both pass once `script-hashes.json` is refreshed in-change.)

## Deferral Check
Before marking status=Finished, verify:
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met (code present; hierarchy proofs land in g)
- [x] All requirements from b-requirements-plan.md addressed (FR1-FR5 implemented; verified in g)
- [x] All design guidance in c-design-plan.md followed (recursive collect + two passes + `-l` skip)
- [x] No planned work deferred without user approval
- [x] If work deferred: n/a

**If deferral required**: Get user approval, document rationale, create follow-up task.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
See the per-step Actual Results and Deviations above. Net: module reworked, hash
refreshed in-commit, perms corrected to `0600`, `cwf-manage validate` clean.

## Lessons Learned
Check a hash-tracked file's `permissions` entry and its siblings' modes before applying
the 0700 script convention — library modules are `100644`.

## Security Review

**State**: no findings

This confirms the diff's `old mode 100644 / new mode 100755` reflects a real working-tree perm change. `Consistency.pm` is now `0700` (executable) while every sibling `.pm` module is `0600` (non-executable). The recorded permissions/hash integrity is `cwf-manage validate`'s deterministic domain (per the boundary in security-review.md §Scope) — and MEMORY notes hashed-script working perms should be `0700` — so I will not raise it as a finding, but I note it as outside my scope and for the maintainer's hash-update step.

Now reasoning through the five threat categories.

**(a) Bash injection / unsafe command construction.** The diff adds no new shell invocations. The only command construction in the module is the pre-existing `_current_branch` (`git -C "$git_root" rev-parse ...`), which is unchanged by this diff and whose `$git_root` is `find_git_root()`-derived (trusted, not user-controlled). The new code uses `opendir`/`readdir`/file-test operators and pure-Perl string comparison only. No `system`, no backticks, no shell. Clean.

**(b) Perl helpers consuming git/user output without `-z` / input validation.** The new `_collect_nodes` and `_build_node` read directory entries via `readdir` (which yields raw bytes, no newline-splitting hazard) and gate every entry through `parse_dirname` (anchored regex `^(\d+(?:\.\d+)*)-(\w+)-(.+)$`), so only well-formed task-number dirs become nodes. No git porcelain is newline-split here. Branch/status/task fields flow through the existing `extract_field`/`status_get` helpers, unchanged. The only branch comparison is `eq` (exact string), never interpolated into a command. Clean.

**(c) Prompt injection.** This is a deterministic Perl validator invoked by `cwf-manage validate`; its output is violation hashrefs printed to a terminal, not fed verbatim into an LLM SKILL context. Field values (branch names, task numbers) are interpolated into human-readable `fix:` strings, but those are diagnostic console output, not model-steering context. No new prompt-injection surface.

**(d) Unsafe environment-variable handling.** No `%ENV` access added or touched. Not applicable.

**(e) Pattern-based risks (safe-here-but-risky-elsewhere).** Two patterns worth surfacing, both safe at this callsite:

1. **Symlink-skip-before-`-d` traversal.** `_collect_nodes` does `next if -l $full;` before `next unless -d $full;`, with the comment explaining `-d` stat-follows. This correctly prevents symlink-directed traversal escaping `implementation-guide/` (a TOCTOU/path-traversal class defence). It is *safe here because* the order is correct and there is no `open`/write between the test and any use — the only subsequent operation is `opendir` in `_build_node`, which fails closed (`return undef`) on a vanished/replaced entry. Audit future reuse: if this traversal pattern is copy-pasted into code that opens entries for *writing* or passes the path to `chmod`/`rm`, the `-l`-then-`-d` check is a TOCTOU window, not a guarantee — a entry can be swapped to a symlink between the lstat and the operation. The safety here rests on the operations being read-only and idempotent-on-failure.

2. **`get_parent`-chain ancestry walk on unbounded directory depth.** `_collect_nodes` recurses per nesting level and `_is_ancestor` walks the dotted-number chain. Both terminate on real task hierarchies (bounded depth). *Safe here because* `parse_dirname`'s node-gate plus the finite on-disk directory tree bound recursion, and `get_parent` strictly shortens its argument each step so `_is_ancestor` always terminates. Audit future reuse: there is no explicit depth cap, so if `_collect_nodes` were ever pointed at an attacker-shaped directory tree of pathological depth it would recurse without a guard — acceptable for the local-trusted-repo invariant, worth a depth cap only if this is ever exposed to untrusted trees.

Neither rises to an actionable defect in this changeset; both are correctly-reasoned defences with the invariant holding at the callsite.

One correctness-adjacent observation I checked and cleared: the comment claims `_is_ancestor` "structurally rejects numeric near-misses: 1 vs 11, 1.1 vs 1.10." Verified against `get_parent` — it uses regex `^(.+)\.[0-9]+$` and exact `eq` comparison, so `11` never yields `1` as a parent and the `eq` is exact. The claim holds. This is a correctness property, not a security one, and is sound.

**Summary:** No actionable security findings in the implementation-phase changeset. The new recursive traversal is read-only, gates entries through an anchored regex, and orders its symlink check correctly. The file-mode change (0644→0755 on the `.pm`) is real but falls under `cwf-manage validate`'s deterministic permission/hash domain (out of scope here) and matches the documented 0700-working-perms convention; the maintainer must refresh `.cwf/security/script-hashes.json` in the same commit per the hash-update convention.

```cwf-review
state: no findings
summary: Recursive read-only traversal; entries gated by anchored regex, symlink-before-stat order correct, no shell/env/prompt surface. Mode change 0644->0755 is cwf-manage validate's deterministic domain (out of scope).
```
