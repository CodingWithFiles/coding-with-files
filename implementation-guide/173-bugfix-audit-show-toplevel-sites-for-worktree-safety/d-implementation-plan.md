# Audit show-toplevel sites for worktree-safety - Implementation Plan
**Task**: 173 (bugfix)

## Task Reference
- **Task ID**: internal-173
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/173-audit-show-toplevel-sites-for-worktree-safety
- **Template Version**: 2.1

## Goal
Implement the worktree-safe root resolution from c-design-plan: repoint `CWF::Common::find_git_root`, route inline-backtick sites to it, fix the Class A CWD/prose sites, and apply the OQ-resolved treatments — all with in-commit hash refresh.

> **Gate**: OQ-1..OQ-4 in c-design-plan are maintainer judgement calls. This plan encodes the *proposed* resolutions; if review changes any OQ, update the corresponding step before exec.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Change (choke-point)
- `.cwf/lib/CWF/Common.pm` (`find_git_root`, line 52) — repoint to worktree-safe behaviour: `git rev-parse --path-format=absolute --git-common-dir`, `File::Spec` parent when result ends in `/.git`, else fall back to `--show-toplevel`. Argument-free backtick retained. **Add `use File::Spec;` to the preamble** (not currently imported; core module, used by sibling modules). Fixes T1/T2/T3 transitively.

### Routed Perl sites (inline backtick → `find_git_root()`)
- `.cwf/lib/CWF/TaskPath.pm:38` — already a `CWF::` module; add `use CWF::Common qw(find_git_root)` (Common is a leaf, no cycle).
- `.cwf/lib/CWF/WorkflowFiles.pm:159` — same.
- `.cwf/scripts/command-helpers/template-copier-v2.0:120` — has `use lib` but **no** existing `use CWF::Common` line (imports only TaskPath/WorkflowFiles); add a **new** `use CWF::Common qw(find_git_root);`.
- `.cwf/scripts/command-helpers/template-copier-v2.1:159` — already `use CWF::Common`; extend import list.
- `.cwf/scripts/command-helpers/checkpoints-branch-manager:11` — **no lib plumbing**: add `use FindBin; use lib "$FindBin::Bin/../../lib"; use CWF::Common qw(find_git_root);` (mirror sibling helpers) OR inline the safe snippet. Prefer plumbing for consistency.
- `.cwf/scripts/migrations/migrate-v2.1-file-order:31` — has `use FindBin`; add `use lib` + `use CWF::Common qw(find_git_root)`.

### Class A — CWD mutation / prose (single canonical snippet)
- `.cwf/scripts/update-cwf-skill-docs.sh:10` — replace `cd "$(git rev-parse --show-toplevel)"` with the worktree-safe shell snippet.
- `.claude/skills/cwf-init/SKILL.md:87` — fix prose per OQ-3 (drop the `GIT_ROOT` capture if the arg is non-load-bearing; else make it main-tree-safe).
- `.cwf/docs/conventions/tmp-paths.md:28` — fix `repo_root=$(...)` prose to the same safe snippet.

### OQ-dependent
- `.cwf/scripts/command-helpers/context-manager.d/location:13` — **OQ-2**: print both `Git repo root (main)` and the current worktree, rather than substituting.
- `.cwf/scripts/cwf-manage:86` — **OQ-4**: repoint its own `find_git_root` (uses list-form `git_capture`) to the safe derivation.
- `.cwf/scripts/command-helpers/task-stack:14` — **OQ-1**: proposed **no change** (capture feeds error text only). If maintainer wants a shared stack, separately change `$STACK_FILE` resolution.

### No change (rationale recorded)
- `.cwf/scripts/command-helpers/task-workflow.d/delete:153` — Class C self-worktree guard; must stay worktree-local.
- `scripts/install.bash:59` — runs during bootstrap *before* `.cwf/` exists and is not reachable from inside a CWF worktree; "must run from git root" guard. No change (note disposition so the audit is honestly complete).
- `t/template-copier-baseline-default.t:57` — test helper capturing the live repo root; legitimately worktree-local for the test harness. No change.

### Supporting
- `.cwf/security/script-hashes.json` — refresh hashes for every edited **hashed** artefact, **same commit**. Note: `update-cwf-skill-docs.sh` is **not** hashed — edit it, but do not add a hash entry. Derive the actual refresh set from `git diff --name-only` of changed files cross-referenced against the hash manifest, not from a static list (OQ-3/OQ-4 change which files are edited).
- New test file (see e-testing-plan) — worktree-safe resolver regression test, covering **both** `CWF::Common::find_git_root` **and** `cwf-manage`'s independent resolver (if OQ-4 routes it).

## Implementation Steps
### Step 1: Failing test first (TDD)
- [ ] Write a test that creates a real `git worktree`, runs the resolver from inside it, and asserts it returns the **main** tree root (currently fails — returns worktree root). See e-testing-plan.
- [ ] Assert the verified flag ordering (`--path-format=absolute` before `--git-common-dir`) and the `/.git`-parent derivation.

### Step 2: Repoint the choke-point
- [ ] Rewrite `find_git_root` in `CWF::Common` per the design mechanism; keep the `undef`-outside-repo contract and the documented `--show-toplevel` fallback branch.
- [ ] Confirm transitive callers (Versioning:33, Backlog:669, backlog-manager:46) now resolve the main tree — no edits to them, covered by test.

### Step 3: Route inline-backtick sites
- [ ] Replace each inline `\`git rev-parse --show-toplevel\`` with `find_git_root()`, adding the import/plumbing noted per file. Confirm no behavioural change in the main tree.

### Step 4: Class A CWD + prose
- [ ] Define the canonical worktree-safe shell snippet once; apply verbatim to `update-cwf-skill-docs.sh`, `cwf-init/SKILL.md`, `tmp-paths.md`.

### Step 5: OQ-dependent sites (only after OQ review)
- [ ] **location (OQ-2)**: dual report (main + current worktree). The site uses `2>&1` deliberately so error text surfaces outside a repo — preserve that diagnostic; do **not** route the worktree line through `find_git_root()` (which swallows stderr and returns undef, blanking the report). Use `find_git_root()` only for the new "main" line.
- [ ] **cwf-manage (OQ-4)**: repoint its *own* resolver — keep it on list-form `git_capture('rev-parse', '--path-format=absolute', '--git-common-dir')`, do **not** copy `Common.pm`'s backtick. Preserve the existing `die_msg`/non-undef contract and add the same `/.git`-parent + `--show-toplevel` fallback. cwf-manage is the validator, so a bug here is self-masking — the in-worktree test must exercise this resolver directly (Step 1).
- [ ] **task-stack (OQ-1)**: confirm no-change (capture feeds error text only).

### Step 6: Hashes, perms, validate
- [ ] Derive the hashed-artefact set from `git diff --name-only` ∩ the hash manifest (not a static list — OQ-3/OQ-4 alter which files are edited; `update-cwf-skill-docs.sh` is unhashed and excluded).
- [ ] Refresh `script-hashes.json` for that set in the same commit.
- [ ] Restore each edited script to its **recorded** perms (not bumped); `.pm` stay `100644`.
- [ ] `.cwf/scripts/cwf-manage validate` passes clean.

## Code Changes
### Before (`CWF::Common::find_git_root`)
```perl
sub find_git_root {
    my $root = `git rev-parse --show-toplevel 2>/dev/null`;
    chomp $root;
    return length $root ? $root : undef;
}
```

### After (sketch — exact form set in exec, ordering already verified)
```perl
sub find_git_root {
    # Worktree-safe: from inside a linked worktree, --show-toplevel returns the
    # worktree (data-loss vector, Task 172). Derive the MAIN tree from the common dir.
    # NB: single-value capture — chomp only; no NUL/list parsing needed (argument-free git call).
    my $common = `git rev-parse --path-format=absolute --git-common-dir 2>/dev/null`;
    chomp $common;
    $common =~ s{/+$}{};                       # normalise any trailing slash FIRST
    if (length $common && $common =~ m{/\.git$}) {
        my @dirs = File::Spec->splitdir($common);
        pop @dirs;                             # drop ONLY the trailing .git component
        my $root = File::Spec->catdir(@dirs);  # leading '' preserves the absolute '/'
        return $root if length $root;
    }
    my $root = `git rev-parse --show-toplevel 2>/dev/null`;  # fallback branch
    chomp $root;
    return length $root ? $root : undef;
}
```
*(Illustrative only — the `/.git` match and `File::Spec` derivation must be exercised by the in-worktree test, not trusted from this sketch. The earlier `pop while $dirs[-1] eq ''` form was buggy — it stripped the leading empty element that encodes the root `/` and produced a relative path; the in-worktree equality assertion catches that.)*

### Class A shell snippet (canonical, reused verbatim)
```sh
# worktree-safe repo root (main tree, even inside a linked worktree)
_common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || exit 1
repo_root=$(CDPATH= cd -- "$(dirname "$_common")" && pwd) || exit 1
[ -n "$repo_root" ] || { echo "not inside a git repository" >&2; exit 1; }
# then reference "$repo_root"/… explicitly — do NOT leave the shell cd'd into it
```
Notes:
- The `cd` is inside a command substitution (subshell) so it does **not** mutate the script's persistent CWD — `update-cwf-skill-docs.sh` body must be rewritten to use `"$repo_root"/…` prefixes rather than relying on a moved CWD (it currently `cd`s and uses relative paths; that reliance is the Class A bug and must go).
- Failure path is explicit (`|| exit 1` + empty check) — deliberately *diverges* from the Perl resolver's `undef`-return contract: a shell doc/build script aborting outside a repo is correct, whereas the library returns `undef` for callers to handle.

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
**Next Action**: /cwf-testing-plan 173
**Blockers**: OQ-1..OQ-4 resolutions to confirm at review before exec

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
