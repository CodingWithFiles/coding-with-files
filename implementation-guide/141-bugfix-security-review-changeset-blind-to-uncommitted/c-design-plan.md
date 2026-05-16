# security-review-changeset blind to uncommitted - Design
**Task**: 141 (bugfix)

## Task Reference
- **Task ID**: internal-141
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/141-security-review-changeset-blind-to-uncommitted
- **Template Version**: 2.1

## Goal
Pick the helper-side fix for the "blind to uncommitted work" bug from the three options the BACKLOG entry sketched, specify the resulting behaviour precisely, and identify the touched call sites and tests.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### Decision 1: Option (a) — drop `..HEAD` from both diff spec sites
- **Decision**: Replace `git diff ${anchor}..HEAD` with `git diff ${anchor}` (and the equivalent in `git diff --name-only -z ${anchor}..HEAD`). The diff window becomes "anchor → working tree" instead of "anchor → HEAD".
- **Rationale**:
  - Smallest behavioural change that fixes the bug. Existing tests' invariant — invocation after the commit has landed — is unaffected (when working tree == HEAD, the two diff shapes return identical output).
  - Aligns the helper's mental model with how an interactive reviewer thinks: "show me what's changing on this branch", not "show me what's committed but not yet merged."
  - The BACKLOG entry's preferred fix (verbatim: "(a) is the smallest change and best aligns with how an interactive reviewer would think").
  - Discarded: option (b) (warn-on-uncommitted-state). Adds a code path that requires the agent to take action (commit + re-run) before getting a useful review. That's the workaround we're trying to eliminate, not codify. Loud-but-still-broken is worse than quiet-and-fixed.
  - Discarded: option (c) (workflow-doc-only fix). The BACKLOG entry itself excluded this: "trains every future agent to remember a non-obvious ordering."
- **Trade-offs**:
  - **Benefit**: agents can run security-review *before* checkpoint commit; the recurring "commit-then-re-run" round-trip from Tasks 137–140 disappears.
  - **Cost**: the diff window now silently includes uncommitted scratch/debug edits that happen to sit in the working tree at review time. Mitigated by Decision 2 (stderr disclosure).
  - **Reversibility**: trivial — the change is two `${anchor}..HEAD` → `${anchor}` edits; reverting is a one-character-per-site addition.

### Decision 2: Disclose "includes uncommitted work" in the stderr summary
- **Decision**: When the helper's diff window picks up any uncommitted state (staged or working-tree), append `, includes uncommitted` to the existing stderr summary line. Detection: `git diff --quiet HEAD` exit code via the existing `git_check()` helper (list-form spawn at line 229 — same pattern as the trunk-name validation).
- **Detection invocation** (explicit to avoid the shell-form anti-pattern per FR4(a)):
  ```perl
  my $rc = git_check('diff', '--quiet', 'HEAD');
  # rc == 0: clean; rc == 1: dirty; rc >= 2: git error (treat as clean — skip disclosure rather than die, since the diff itself has already succeeded by this point and the disclosure is informational only)
  ```
- **Rationale**:
  - Decision 1's behaviour change is silent to the reviewer otherwise. The subagent reviewing the diff has no way to know whether the changes are "what the agent committed" vs "what the agent has in flight." Disclosure lets the reviewer adjust their assessment (e.g. "the script-hashes.json edit is uncommitted but consistent with the source-code change above" is a meaningful observation).
  - One-line addition; no new code path beyond a single list-form `git_check()` call.
  - **Error policy**: if `git diff --quiet HEAD` returns rc ≥ 2 (e.g. corrupted index, missing HEAD ref), skip the disclosure suffix rather than failing the whole helper. The primary `git diff <anchor>` call has already succeeded by this point (we are in the summary-emit code path), so a subsequent rc ≥ 2 on the dirty-check is a fail-quiet-and-degrade-gracefully condition. The disclosure is informational; its absence is recoverable; helper failure here would block the entire review.
- **Trade-offs**:
  - **Benefit**: scope-of-review is now reviewer-visible, without adding a code path the agent must trigger.
  - **Cost**: changes the summary-line shape (existing tests asserting on `qr{reviewed N files}` continue to pass; any test pinning the exact-string summary would need a regex update — grep shows none do today).

### Decision 3: Don't add a `--include-worktree` opt-in flag
- **Decision**: The new behaviour is unconditional. No CLI flag toggles it.
- **Rationale**:
  - Adding a flag means defaulting one way and supporting both. The whole point of the fix is that the un-flagged invocation should Just Work. A flag would re-introduce the "agent must remember to set it" failure mode that this task is trying to delete.
  - If a use case appears that genuinely needs the old `..HEAD` semantics (e.g. "review only what's about to be pushed"), add `--committed-only` then — but no such use case exists today, so defer.

## System Design

### Component Overview
Single component, no new modules. Modifications confined to one Perl script:

- **`.cwf/scripts/command-helpers/security-review-changeset`** — three minimal changes:
  1. `list_changed_files()` (line 341): drop `..HEAD` from the diff spec.
  2. Main flow (line 168): drop `..HEAD` from the diff-emit call.
  3. Main flow (after line 173): add the "includes uncommitted" disclosure to the stderr summary if `git diff --quiet HEAD` exits non-zero.

### Data Flow (unchanged shape, widened input)
1. `resolve_anchor_from_baseline()` reads `a-task-plan.md` for the recorded baseline — **unchanged**.
2. `list_changed_files($anchor)` — **input widened**: returns files changed between anchor and working tree (was: anchor and HEAD).
3. File-classification logic (CWF-internal vs shebang-sniff) — **unchanged**.
4. `git diff ${anchor} -- @included` emits the filtered diff to stdout — **input widened**.
5. Stderr summary line emitted — **disclosure suffix added** when working tree is dirty.

### Helper-internal invariants preserved
- Diff anchor resolution: still baseline-first, merge-base fallback.
- File classification: still CWF-internal-prefix-and-exact-file plus shebang-sniff.
- Symlink / non-regular-file rejection in `looks_like_script()`: unchanged.
- **Output contract**: stdout is still a `git diff`. Stderr is still the one-line summary — informational, consumed by the exec-phase Agent prompt template (the entire changeset is dropped into the prompt) and by test assertions. The exec-phase SKILLs themselves classify the subagent's *response* via the three-tier sentinel rule; they do not parse the helper's stderr. The summary-line shape change (optional `, includes uncommitted` suffix) is therefore additive and non-breaking for any current consumer.

### Behavioural notes on the widened diff window
- **Deleted files** (`rm` without `git rm` — file gone from working tree, still tracked): `list_changed_files()` will list them under the new diff spec; `looks_like_script()`'s `-e $path` guard at line 367 then filters them from the classification pass (correctly — there's nothing to sniff). Net effect: deletions of CWF-internal-prefix paths are still reviewed (the classification doesn't need a shebang for them); deletions outside CWF-internal paths are silently excluded (same as today, just via a different code path).
- **Untracked files** (created but never `git add`-ed): `git diff` does not list them by design; they are invisible to the helper under both the old and new behaviour. **Intentional** — security-review-changeset reviews changes the agent is in the process of making to the project's tracked state. If a future use case needs to review untracked files (e.g. uncommitted draft scripts), that's a separate flag.
- **Edge: `HEAD == anchor`** (fresh task branch, no commits since `cwf-new-task`): old behaviour returns empty diff; new behaviour shows just the uncommitted work. This is the primary case the fix targets and is desired.

## Interface Design

### CLI surface
**Unchanged.** Existing flags (`--phase`, `--task-num`, `--verbose`, `--help`) keep their meaning. No new flag.

### stdout contract
**Same shape.** `git diff <baseline> [-- <classified paths>]` output. The only observable difference per invocation is what's *in* the diff when the working tree is dirty.

### stderr contract — single-line change
- **Before**: `reviewed N files, M lines, anchor=<sha7>`
- **After (clean tree)**: `reviewed N files, M lines, anchor=<sha7>` (identical)
- **After (dirty tree)**: `reviewed N files, M lines, anchor=<sha7>, includes uncommitted`

### Exit codes
**Unchanged.** 0 success (including empty changeset), 1 error.

## Constraints
- Perl core modules only (per repo convention).
- POSIX-only.
- Single-stat `git diff --quiet HEAD` for dirty-tree detection — no porcelain-parsing.
- Output contract must remain greppable by the existing exec-phase SKILL parsing (`reviewed N files`, `anchor=<sha7>`).

## Decomposition Check
- [ ] **Time**: >1 week? — No.
- [ ] **People**: >2? — No.
- [ ] **Complexity**: 3+ distinct concerns? — No, single concern (diff-spec widening + disclosure).
- [ ] **Risk**: high-risk components needing isolation? — No.
- [ ] **Independence**: parts can be worked on separately? — No, the two diff-spec edits + disclosure + regression test must land together.

No signals triggered — single task is appropriate.

## Validation
- [ ] All existing `t/security-review-changeset.t` cases pass without modification (committed-state behaviour is preserved).
- [ ] New regression test `TC-Task141-uncommitted` (named for traceability) in `t/security-review-changeset.t`:
  - **Setup**: `make_synthetic_repo(baseline => '__MAIN__')`. Add a CWF-internal script and commit it (so we have a baseline that includes a script). On the task branch, modify the script with both a staged edit (`git add`) AND an additional unstaged working-tree edit (no `git add`).
  - **Assert 1**: helper exit 0.
  - **Assert 2**: stdout diff contains the *specific text* of both the staged edit and the unstaged edit (proves both halves of the working tree are picked up, not just one).
  - **Assert 3**: stderr summary matches `qr{reviewed 1 files,.*includes uncommitted}` (proves the disclosure suffix fires).
- [ ] Manual end-to-end smoke during f-implementation-exec on this very task: run the helper mid-phase (before checkpoint commit) and confirm it sees the in-progress edits. **This is the canonical regression — the fix succeeds iff this works on first try.** Record the stderr line in f-implementation-exec.md as evidence.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 141
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
