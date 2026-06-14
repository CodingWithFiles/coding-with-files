# report whether parent branch is direct ancestor - Design
**Task**: 202 (feature)

## Task Reference
- **Task ID**: internal-202
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/202-report-whether-parent-branch-is-direct-ancestor
- **Template Version**: 2.1

## Goal
Define the architecture for the parent-branch ancestry signal: one new library
function in `CWF::TaskPath`, consumed additively by `context-manager.d/hierarchy`.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### Architecture Choice
- **Decision**: Add a single library function
  `parent_branch_ancestry($task_path)` to `CWF::TaskPath` (the module that
  already owns `resolve`, `get_parent`, `format_branch`, `branch_exists`). The
  `hierarchy` command calls it and maps the tri-state result into both output
  formats. All git calls are list-form, via a shared runner hoisted into
  `CWF::Common` (see next decision).
- **Rationale**: Keeps derivation/ancestry logic out of the command (FR6), so it
  is unit-testable independently of output formatting. Co-locating with the
  other task↔branch helpers matches existing module boundaries.

### Shared list-form git runner (de-duplication)
- **Decision**: A list-form fork/exec runner that returns the child exit code
  already exists as `run_quiet` inside `task-workflow.d/delete` (`:44-56`). The
  new function needs the identical helper. Rather than clone it (a second
  definition), **hoist `run_quiet(@cmd)` into `CWF::Common`** (exported), and
  consume it from both the new `TaskPath` function and `delete` (whose local copy
  is removed). The new code path writes zero duplicated runner code.
- **Child exit**: the hoisted runner's post-failed-`exec` child MUST use
  `POSIX::_exit(127)`, not `exit` (Task-159 convention: avoid running inherited
  END blocks — `CWF::Common` is broadly imported, so this matters more than in
  the original local copy). `POSIX` is core.
- **Rationale**: "Reuse over duplication, always." `CWF::Common` is the
  established shared-helper home and already exports git-touching helpers
  (`find_git_root`, `resolve_head_sha`). One definition, two callers.
- **Trade-offs**: Touches the integrity-tracked, security-sensitive `delete`
  script (existing tests cover it; change is mechanical: drop local sub, import
  from `Common`). Accepted as the cost of genuine de-duplication; a relocate-but-
  leave-the-copy half-measure would be worse.

### Return Contract (tri-state)
`parent_branch_ancestry($task_path)` returns:
- `1`     → parent branch IS an ancestor of the current branch (`true`)
- `0`     → parent branch exists but is NOT an ancestor (`false`, diverged)
- `undef` → undecidable (`null`) — every FR4 case

This tri-state (defined-but-false vs undef) is what lets callers distinguish
"diverged" from "undecidable" (NFR usability, AC3). Perl's `0` vs `undef` carries
it without a sentinel string.

## System Design

### Component Overview
- **`CWF::Common::run_quiet(@cmd)`** (hoisted from `delete`, exported): list-form
  fork/exec runner — stdio to `/dev/null`, returns child exit code (`$? >> 8`),
  `-1` on fork failure, child `POSIX::_exit(127)` on failed `exec`. No shell, no
  interpolation (NFR3).
- **`CWF::TaskPath::parent_branch_ancestry($task_path)`** (new): the whole
  decision. Derives the parent branch, guards existence, runs the ancestry test,
  returns the tri-state. Added to `@EXPORT_OK`.
- **`context-manager.d/hierarchy`** (modified): calls the function once after
  `resolve`, emits the JSON field unconditionally and the markdown line
  conditionally.
- **`task-workflow.d/delete`** (modified): drops its local `run_quiet`, imports
  the shared one from `CWF::Common`. No behaviour change.

### Data Flow
1. `hierarchy <task>` resolves `$result` (existing).
2. `hierarchy` calls `parent_branch_ancestry($task_path)` → `$anc` (1/0/undef).
3. Inside the function:
   a. `get_parent($task_path)` → undef ⇒ return undef (top-level, no parent).
   b. `resolve($parent_path)` → undef ⇒ return undef. (`resolve` already returns
      parsed `num/type/slug`; an unparseable parent dirname yields undef here, so
      no separate parse guard is needed.)
   c. `format_branch($p->{num},$p->{type},$p->{slug})` → `$parent_branch`.
   d. existence guard: `run_quiet('git','rev-parse','--verify','--quiet',
      "refs/heads/$parent_branch")` ≠ 0 ⇒ return undef (branch absent).
   e. ancestry: `run_quiet('git','merge-base','--is-ancestor',$parent_branch,
      'HEAD')` → `0`⇒return 1; `1`⇒return 0; anything else⇒return undef.
4. `hierarchy` maps `$anc` into output (see Interface Design).

**Detached HEAD**: no special-casing. `merge-base --is-ancestor <parent> HEAD`
resolves `HEAD` to the current commit even when detached, giving a correct
true/false answer against that commit (more informative than forcing `null`).
Only a genuinely unborn/empty HEAD makes `merge-base` error (rc ∉ {0,1}) ⇒ `null`.
This refines FR4's original "detached ⇒ null" wording — chosen because the rc-only
runner cannot capture the branch name an `abbrev-ref` check would require, and the
commit-level answer is the more useful behaviour.

### Interface Design

**Library function**
```
parent_branch_ancestry($task_path)  # exported from CWF::TaskPath
  -> 1 | 0 | undef
```

**JSON (`--format=json`)** — new additive field, emitted as a bare literal
(the existing serialiser is hand-rolled string interpolation, no encoder):
```
  "parent_branch_is_ancestor": true|false|null
```
Mapping: `defined($anc) ? ($anc ? 'true' : 'false') : 'null'`. Placed after the
existing `depth` field (the current last field); prior field *content* and order
are unchanged, but the `depth` line gains a trailing comma so the appended field
keeps the JSON valid (NFR4-reliability, AC4).

**Markdown (default)** — additive line, printed only when the task has a parent
(`$result->{parent_path}` set), consistent with the conditional `Parent:` line:
```
Parent branch ancestor of HEAD: yes|no|unknown
```
Mapping: `defined($anc) ? ($anc ? 'yes' : 'no') : 'unknown'`. A subtask whose
parent branch is missing prints `unknown` (informative); a top-level task prints
no line at all.

### Edge-case → result mapping (FR4)
| Case                                              | Return | JSON   | Markdown  |
|---------------------------------------------------|--------|--------|-----------|
| Parent branch is ancestor of HEAD (incl. same tip)| 1      | true   | yes       |
| Parent branch exists, diverged from HEAD          | 0      | false  | no        |
| Detached but valid HEAD (answered vs the commit)  | 1 / 0  | t/f    | yes/no    |
| Top-level task (no parent)                        | undef  | null   | (no line) |
| Parent path unresolvable                          | undef  | null   | unknown   |
| Parent branch absent (renamed/merged-deleted)     | undef  | null   | unknown   |
| `merge-base` errors — unborn/empty HEAD (rc ∉{0,1})| undef  | null   | unknown   |

## Constraints
- Perl core only; `docs/conventions/perl.md` (shebang, `PERL5OPT`, `use utf8;`).
- All new git calls list-form; MUST NOT reuse `branch_exists` (backtick/shell
  form, `TaskPath.pm:510`) for the existence guard — use `run_quiet` +
  `rev-parse --verify --quiet` instead (NFR3).
- Additive only to `hierarchy`; no CLI-surface change beyond the new field/line.

### Integrity-tracked files edited (hash-refresh disclosure)
All four edited files are in `.cwf/security/script-hashes.json`; their hashes are
refreshed in the same exec commit (per `hash-updates.md`):
`.cwf/lib/CWF/Common.pm`, `.cwf/lib/CWF/TaskPath.pm`,
`.cwf/scripts/command-helpers/context-manager.d/hierarchy`,
`.cwf/scripts/command-helpers/task-workflow.d/delete`.

## Decomposition Check
- [ ] Time >1 week? No. — [ ] People >2? No. — [ ] 3+ concerns? No.
- [ ] High-risk isolation? No. — [ ] Separable parts? No.

Single task — no decomposition.

## Validation
- [ ] Design review completed (plan-review subagents)
- [ ] Integration point (`hierarchy` after `resolve`) verified against current code

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Implemented exactly as designed: the `run_quiet` hoist into `CWF::Common` (one
definition, two callers), `parent_branch_ancestry` in `CWF::TaskPath` returning the
1/0/undef tri-state, additive JSON+markdown in `hierarchy`, and the mechanical
`delete` refactor. The edge-case→result table maps 1:1 onto the TC-1…TC-9 results.
The `POSIX::_exit(127)` child-exit decision proved load-bearing — both security
reviews called it out as the property that lets `delete` (which imports
`File::Path`) share the runner without an inherited-END-block cleanup hazard.

## Lessons Learned
*Consolidated in j-retrospective.md.*
