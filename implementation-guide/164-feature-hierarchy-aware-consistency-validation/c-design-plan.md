# hierarchy-aware consistency validation - Design
**Task**: 164 (feature)

## Task Reference
- **Task ID**: internal-164
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/164-hierarchy-aware-consistency-validation
- **Template Version**: 2.1

## Goal
Rework `CWF::Validate::Consistency::validate` from a flat, single-level scan into a
hierarchy-aware one: collect every task node at any depth in one pass, then apply the
task-number, directional-branch, and parent/child-completeness checks over that node set
using pure-string ancestry derived from the dotted task number.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Current Behaviour (what changes)
`validate($git_root)` today (`.cwf/lib/CWF/Validate/Consistency.pm`):
- `opendir`s `implementation-guide/` once and greps top-level `^\d…` dirs (`:35-36`) —
  **never recurses**, so nested subtask dirs are invisible.
- Per task dir: per-file `**Task**` vs dir-num check (`:57-65`); collects the first
  `**Branch**` field and an `is_active` flag (any file non-terminal, `:67-72`).
- Branch check is **flat equality**: active task whose recorded branch ≠ current branch →
  violation (`:74-84`).
- No parent/child relationship is modelled anywhere.

## Key Decisions

### Decision 1 — Recursive single-pass node collection, then in-memory checks
- **Decision**: Replace the single `opendir` with a recursive walk that collects a flat
  list of **node records** (one per task dir at any depth). All three checks then run over
  that in-memory list. This mirrors the *recursive-descent shape* of `build_tree`
  (`status-aggregator-v2.1:210-288`) only — **not** its mechanism: `build_tree` uses
  `glob`+`grep { -d }` (which stat-follows symlinks) and a num-prefix regex filter; this
  design uses `readdir`+`-l`-skip (Decision 5) and `get_parent`-chain ancestry, and carries
  none of `build_tree`'s depth-limit / progress-indicator / glob-filter concerns.
- **Node-gate predicate (single source of truth)**: a directory entry is a **task node**
  iff `CWF::TaskPath::parse_dirname` succeeds on its name (i.e. matches
  `^\d+(?:\.\d+)*-\w+-.+$`). The walk recurses **only into task-node dirs** (subtasks are
  nested inside their parent task dir); non-task subdirs (e.g. an `assets/` folder) are
  neither recorded nor descended. `num` is taken from `parse_dirname` — replacing the
  existing inline `/^(\d[\d.]*)-/` (`:41`) so the dirname grammar has one source. A
  `^\d`-prefixed dir that fails `parse_dirname` (e.g. `1.-foo`, `1..2-foo`) is skipped
  entirely. Well-formed task dirs match both the old and new regex identically, so a valid
  flat repo is unaffected (FR5); only degenerate malformed names that the old looser regex
  would have field-checked are now skipped — an intentional, documented tightening.
- **Node record** (per task dir):
  - `num` — dotted task number (from `parse_dirname`)
  - `path` — task dir path (for violation `file` field)
  - `branch` — first `**Branch**` field across its direct `.md` files (or undef)
  - `active` — true iff any direct `.md` file has a *recognised* non-terminal status
  - `complete` — true iff it has ≥1 recognised status and is **not** active (all
    recognised statuses terminal)
  - the per-file `**Task**`-vs-dir-num check is emitted during collection (so it now runs
    at every depth — this is FR1's coverage, for free)
- **Ordering**: top-level task-node dirs are iterated in the existing `sort`ed order, and
  children in `version_compare` order, so the violation list ordering is stable and, for a
  flat repo, byte-identical to today (FR5/AC5 covers set *and* order).
- **Rationale**: One pass = linear in task files (NFR1). An in-memory node set makes the
  ancestry checks pure functions of the collected data, unit-testable without the live
  repo (NFR3, Testability-first). `active` keeps the existing semantics (undefined status
  is not active, `:69`), which is also exactly what FR4 needs for "missing status doesn't
  count".
- **Trade-offs**: Recursion descends the whole tree rather than one level; bounded by the
  task-dir count, no rescan.

### Decision 2 — Reuse `CWF::TaskPath` **string** primitives; do NOT use its filesystem `find_*` family
- **Decision**: Derive ancestry with `CWF::TaskPath::get_parent`, plus `parse_dirname`
  (num extraction, Decision 1) and `version_compare` (deterministic ordering and the
  completeness tiebreak, Decision 4). Explicitly **reject**
  `find_ancestors`/`find_descendants`/`find_children` here.
- **Ancestor-set construction (the load-bearing loop)**: the ancestor set of a node `L` is
  computed **purely from its dotted number string**, independent of which intermediate
  nodes were collected:
  `{ get_parent(L.num), get_parent(get_parent(L.num)), … }` iterated until `get_parent`
  returns `undef`. `A` is an ancestor of `L` iff `A.num` is in that set, tested by `eq`.
  A single local helper `_is_ancestor($anc_num, $node_num)` encapsulates this walk and is
  called by **both** later passes — the branch pass (is a node an ancestor *of the leaf*?,
  Decision 3) and the completeness pass (is a node a descendant of a complete node? — the
  same predicate with arguments swapped, Decision 4). Two callsites, so it clears the
  single-callsite/Rule-of-Three bar. The walk **must not** be a node-to-node parent-pointer
  traversal: a missing/unparseable intermediate dir (e.g. `1` and `1.1.1` present but `1.1`
  absent) must still recognise `1` as an ancestor of `1.1.1`.
- **Termination / deep chains (NFR4)**: `get_parent` strips exactly one `.N` segment per
  call and returns `undef` at top level, so the loop terminates in `depth` steps for any
  valid number; a pathologically deep chain is bounded, not unbounded.
- **Rationale**: Satisfies the reuse-over-duplication guardrail (misalignment review) —
  ancestry policy stays in `TaskPath`, not re-derived inline. But the `find_*` family
  calls `find_base_dir()` (its own `git rev-parse`, `TaskPath.pm:38`) and re-globs the
  filesystem per call: that would (a) duplicate the traversal just done, (b) add a second
  git invocation and a base-dir assumption that may differ from the `$git_root` `validate`
  was handed (the test harness passes a tempdir explicitly), and (c) be quadratic. The
  string primitives carry no such coupling.
- **Near-miss safety (FR2)**: because the ancestor set is built by repeated `get_parent`
  and tested by **exact string equality** (never substring/prefix matching),
  `get_parent("1.10")` → `"1"`, so the chain of `1.10` is `{1}` and never contains `1.1`;
  `"1"` never equals `"11"`. This holds transitively (the grandparent case, AC2) because
  every link is a full `get_parent` result compared by `eq`. Numeric near-misses are
  structurally impossible — no special-casing needed.

### Decision 3 — Leaf identification by recorded branch; fail closed when not unique
- **Decision**: The "leaf node" is the node whose `branch` equals the current git branch.
  - exactly one match → that node is the leaf; its ancestor set = `get_parent`-chain nums
    present in the collected node set.
  - **zero** matches (on `main`, a detached/ad-hoc branch, or a wrong on-disk branch
    field) → no leaf, no suppression; the branch check degrades to flat equality (the
    existing behaviour — FR5-safe).
  - **two or more** matches → ambiguous; **fail closed** (FR3): no suppression granted to
    anyone, branch check degrades to flat equality so a duplicated branch record cannot
    silence a real mismatch.
- **Branch check (per active node)**: no violation iff the node *is* the leaf (its branch
  equals current) **or** the node is an ancestor of the leaf; otherwise flag (existing
  message + actual/expected). Active siblings and unrelated active tasks are not on the
  ancestry chain, so they stay flagged (FR3).
- **Rationale**: Implements FR2 literally (match on the recorded branch field), staying
  independent of branch-naming convention. "Leaf matches exactly" is definitional — if the
  on-branch task's own `**Branch**` field is wrong, no node matches the current branch, so
  that task falls to flat equality and is itself flagged (FR1/FR2 catch the bad field).
- **Rejected alternative**: identify the leaf by `parse_branch(current_branch)` → task
  number. Unique by construction, but couples leaf-finding to the `type/num-slug` branch
  convention (misalignment review's heuristic-fragility caution). Matching the recorded
  field needs no naming assumption; the duplicate case is handled by fail-closed instead.
- **Trade-off**: if the leaf task's branch field is itself wrong, both it and its active
  ancestors get flagged (degraded but safe — the root-cause bad field is among the
  flags). Accepted.

### Decision 4 — Parent/child completeness invariant (FR4)
- **Decision**: After collection, for each `complete` node, flag a CONSISTENCY violation
  if any **descendant** node (a node whose `get_parent`-chain contains this node's num) is
  `active`. The inverse (active ancestor over a terminal descendant) is never flagged.
- **Violation shape**: reuse the existing `_violation` hashref (category `CONSISTENCY`);
  `file` = the complete task's dir, `field` = `**Status**`, with a fix message naming the
  offending descendant ("Task N is complete but descendant M is still active — reopen N or
  finish M"). One violation per complete node with active descendants, naming the nearest
  active descendant — **nearest = smallest `get_depth`; ties broken by `version_compare`**
  — so the message (and AC4 assertions) are deterministic when two descendants are equally
  near.
- **Rationale**: This is the asymmetry the validator currently lacks; modelling nodes in
  memory makes it a cheap second pass. `complete` excludes status-less/malformed nodes, so
  a half-written tree does not manufacture completeness violations (NFR5).

### Decision 5 — Symlink-safe recursion (NFR4)
- **Decision**: During descent, skip any directory entry that is a symlink — test with
  `-l` (the `template-copier-v2.1:254` idiom) **before** the `-d` test, since `-d`
  stat-follows. Only real directories are recorded/recursed, so traversal cannot leave
  `implementation-guide/` via a symlinked subtask dir. **Do not** copy `build_tree`'s
  `glob`+`grep { -d }` (`status-aggregator-v2.1:231`), which follows symlinks.
- **`cwf-check-tree-symlinks` considered, not reused**: that helper is an *escape-checker*
  (canonicalises the symlink target string and fails closed for the install/copy laydown
  path). The validator is a read-only advisory scan that merely needs to **not follow** any
  symlinked dir — a plain `-l` skip — so wiring in the escape-checker would over-couple an
  advisory validator to an install-path guard. The `-l` skip is the right-sized fit.
- **Rationale**: Recursion is the new exposure; the existing single `readdir` never
  followed links. Dir names and field values remain pure data — no shell interpolation;
  the only `git` call stays `_current_branch` (`:106-111`).

## System Design
### Component Overview
- **`CWF::Validate::Consistency`** (the only module changed):
  - `validate($git_root)` — unchanged signature and return contract (list of violation
    hashrefs); becomes the orchestrator: collect → task-num check (inline) → branch check
    → completeness check.
  - `_collect_nodes($ig_dir)` *(new, recursive)* — returns the node-record list; emits
    `**Task**` violations inline; skips symlinked dirs.
  - `_extract_fields` / `_current_branch` / `_violation` — reused as-is.
  - Ancestry helpers come from `CWF::TaskPath` (`get_parent`, `parse_dirname`,
    `version_compare`); a thin local `_is_ancestor($anc_num, $node_num)` wraps the
    `get_parent`-chain test for readability.
- **No change** to `cwf-manage`'s violation reporting (same hashref keys), templates,
  status vocabulary, or branch conventions.

### Data Flow
1. `validate($git_root)` → `_collect_nodes` walks `implementation-guide/` depth-first,
   producing `@nodes` (+ inline `**Task**` violations).
2. Resolve `current_branch`; identify the leaf node among `@nodes` (Decision 3).
3. **Branch pass**: for each `active` node, apply the directional rule → branch violations.
4. **Completeness pass**: for each `complete` node, scan `@nodes` for active descendants →
   completeness violations.
5. Return the accumulated violation list.

## Interface Design
- `validate($git_root)` → `@violations`. Unchanged.
- Violation hashref (unchanged keys): `{ category, file, field, actual, expected, fix }`.
  - `**Task**` violations: as today.
  - `**Branch**` violations: as today, but only for active nodes off the leaf's ancestry
    chain.
  - `**Status**` (completeness) violations: new, same key set.

## Constraints
- `Consistency.pm` is hash-tracked → same-commit `script-hashes.json` refresh
  (`docs/conventions/hash-updates.md`); working perms restored to 0700
  (`feedback_hashed_script_working_perms`). `CWF::TaskPath` is unmodified (no new hash).
- Core-Perl only; `TaskPath`/`TaskState`/`MarkdownParser` are existing deps.
- Canonical layout is nested subtask dirs (per `TaskPath::resolve_num` and the
  status-aggregator); the recursion assumes nesting.
- `validate`'s exit-code/return contract is preserved for flat top-level repos (FR5).

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — collection + two in-memory passes over one
      node set; a single coherent mechanism.
- [ ] **Risk**: high-risk isolation needed? No — advisory module, fully unit-testable.
- [ ] **Independence**: separable parts? No — all three checks share the node collection.

No decomposition signals triggered.

## Plan Review Outcomes (Step 8)
Four parallel reviewers (improvements, misalignment, robustness, security). Applied:
- **`build_tree` is the wrong precedent for symlink safety** (security/misalignment/
  improvements): it uses `glob`+`-d` (follows symlinks). Decision 1/5 now mirror only its
  descent *shape* and point at the `-l` skip idiom (`template-copier-v2.1:254`); noted
  `cwf-check-tree-symlinks` considered-not-reused.
- **Ancestor loop made explicit** (robustness): the set is built from the dotted-number
  string via repeated `get_parent` (not node-pointer walk), `eq`-tested, terminating in
  `depth` steps — covers the grandparent case and a missing intermediate dir (Decision 2).
- **One num-extraction source** (improvements/robustness): `parse_dirname` replaces the
  inline regex; the node-gate predicate and malformed-name skip behaviour are now stated
  (Decision 1).
- **`version_compare` justified** (improvements): used for child ordering and the
  nearest-descendant tiebreak (Decision 1/4), not left as an unused dependency.
- **`_is_ancestor` has two callsites** (misalignment): branch pass + completeness pass —
  clears the single-callsite bar (Decision 2).
- **FR5 ordering** (robustness): top-level `sort` order preserved so the flat-repo
  violation list is byte-identical, not merely set-equal (Decision 1).

## Validation
- [x] Design review completed (plan-review subagents, Step 8) — findings applied above
- [x] Leaf-identification fail-closed semantics confirmed against FR3
- [x] Reuse of `TaskPath` string primitives (not `find_*`) confirmed against the module API
- [x] Symlink-skip precedent verified (`-l` test; `build_tree`'s `-d` follows links)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five Key Decisions implemented as designed (recursive collect; `get_parent`-chain
ancestry from the string; leaf-by-recorded-branch fail-closed; completeness pass;
`-l`-before-`-d`). No design revision needed during exec.

## Lessons Learned
The Constraints note "working perms restored to 0700" was over-broad: it applies to
executable scripts, not `use`d library modules (no `permissions` entry in
`script-hashes.json`; siblings are `100644`). Corrected to `0600` during f.
