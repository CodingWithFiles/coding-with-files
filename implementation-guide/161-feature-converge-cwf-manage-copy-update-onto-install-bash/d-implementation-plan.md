# converge cwf-manage copy update onto install.bash - Implementation Plan
**Task**: 161 (feature)

## Task Reference
- **Task ID**: internal-161
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/161-converge-cwf-manage-copy-update-onto-install-bash
- **Template Version**: 2.1

## Goal
Implement the copy-method convergence per c-design-plan.md (D1-D7): a single shared `cwf-check-tree-symlinks` guard, invoked pre-removal in `install_copy`, with the `cwf-manage` copy branch delegating to `scripts/install.bash`.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- **CREATE** `.cwf/scripts/command-helpers/cwf-check-tree-symlinks` (new Perl helper, mode `0500`) — ports `_escapes_src`/`_collapse_dotdot` (`cwf-manage:546-575`) verbatim; CLI `cwf-check-tree-symlinks <root>...`; self-decodes `@ARGV` (D2); `main() unless caller();` so the escape-check sub stays unit-testable.
- **EDIT** `scripts/install.bash` `install_copy` (`:211-248`) — define one `(src,dest)` list; run the guard over existing source roots **before** the `rm -rf` (`:221-223`); iterate the same list for `cp -r` (D3).
- **EDIT** `.cwf/scripts/cwf-manage` — converge the copy branch (`:490-496`) to delegate to `install.bash` (D1, collapse with the subtree branch `:476-489` into one method-parameterised block); remove `update_copy`/`copy_tree` and the relocated `_escapes_src`/`_collapse_dotdot`; remove the copy-branch `create_skill_symlinks`/`create_agent_symlinks` calls **iff** the caller audit clears (D6); prune now-unused imports.

### Supporting Changes
- **EDIT** `.cwf/security/script-hashes.json` — add a `scripts` entry for `cwf-check-tree-symlinks` (`path`, `permissions: "0500"`, `sha256`); refresh the `cwf-manage` sha256. Co-committed with the respective edits (D7).
- **CREATE** `t/cwf-check-tree-symlinks.t` — migrate the escape-logic subtests (below) and add the source-root-equal and multi-root-CLI cases.
- **EDIT** `t/cwf-manage-update.t` — remove the migrated `copy_tree:*` / `_escapes_src:*` subtests (`:147-256`); keep flock, path-traversal, and `validate_install_manifest` subtests.

## Implementation Steps (ordered — D2→D3→D1/D6, so the guard is live before the old one is removed)

### Step 1: New guard helper + its tests (D2)
- [ ] Write `.cwf/scripts/command-helpers/cwf-check-tree-symlinks`: `#!/usr/bin/env perl`, `use strict/warnings/utf8`, core modules only (`File::Find`, `File::Spec`, `File::Basename`, `Encode`). Decode each `@ARGV` element from UTF-8 at startup (`Encode::decode`). Port the **escape-check subs** `_escapes_src`/`_collapse_dotdot` (`cwf-manage:546-575`) **verbatim** — but the `copy_tree` *walk* is NOT ported: the helper validates only, it never copies.
  - **Multi-root correctness (load-bearing)**: `main(@ARGV)` iterates the roots and runs **one `File::Find::find` per root**, closing over that root as `$src`. Do not call `find(@roots)` once — a symlink under root B must be checked against root B, not the first root.
  - **Validation-only callback**: inspect only symlinks — `lstat` then act `if -l _`; `next`/return on directories and regular files (no `make_path`, no `copy`). Use the full path `$File::Find::name` (not `$_`) for the escape check — preserves the chdir-independence the original comment at `cwf-manage:587-589` documents.
  - **Fail-closed edges**: on the first escaping symlink, print `refusing escaping symlink target: <entry> -> <link>` to STDERR and exit non-zero. A `readlink` failure is **also** fail-closed (non-zero exit + STDERR message, mirroring the original `readlink(...) // die_msg`). Exit 0 only if every root is clean.
  - Guard `main(@ARGV) unless caller();` so the subs are unit-testable.
- [ ] `chmod 0500` the helper, then `git add` it so the **committed mode carries the executable bit** (see Step 3 — the guard is run straight from the clone before any `chmod`, so its checked-out executability depends on the committed git mode).
- [ ] Write `t/cwf-check-tree-symlinks.t`: `require` the helper (caller-guard keeps it from running) and unit-test the escape sub for: sibling/in-tree allowed; same-dir allowed; absolute rejected; `..`-escape rejected; multi-parent rejected; **source-root-equal rejected** (new, `_escapes_src:553`). Plus CLI-level tests via `fork`+exec: clean multi-root tree → exit 0; a root containing an escaping symlink → non-zero + message; a non-escaping (pool-pointing) symlink → exit 0.
- [ ] `prove -lv t/cwf-check-tree-symlinks.t` green.

### Step 2: Ledger entry for the helper (D7)
- [ ] Add the `cwf-check-tree-symlinks` entry to `.cwf/security/script-hashes.json` (`sha256` via `sha256sum`, `permissions: "0500"`).
- [ ] `cwf-manage validate` OK.
- [ ] **Checkpoint commit** (helper + test + ledger entry together).

### Step 3: Wire the guard into `install_copy` (D3)
- [ ] Refactor `install_copy` to build one ordered `(src,dest)` list: `($clone_dir/.cwf, .cwf)`, `($clone_dir/.claude/skills, .cwf-skills)`, and the `-d`-guarded `($clone_dir/.claude/rules, .cwf-rules)`, `($clone_dir/.claude/agents, .cwf-agents)`.
- [ ] **Before** the `rm -rf` (`:221-223`): collect the existing source roots from that list and run `"$clone_dir/.cwf/scripts/command-helpers/cwf-check-tree-symlinks" "${roots[@]}"`; `die` on non-zero. (The helper is executed straight from `$clone_dir` — pre-laydown, before `install_copy`'s `chmod u+rx` at `:246` and before `apply_exact_perms_or_die` — so it relies on the committed `+x` bit from Step 1, not on any runtime perm-fix.)
- [ ] Replace the four hand-written `cp -r` blocks with a loop over the same list.
- [ ] `prove -lr t/install-bash-reinstall.t` (and any install.bash test) green.
- [ ] **Checkpoint commit**.

### Step 4: Converge `cwf-manage` copy branch + remove dead code (D1, D6)
- [ ] **Caller audit first** (`grep -n` each sub in `cwf-manage`). Expected outcome, pre-verified in planning: `update_copy`/`copy_tree`/`_escapes_src`/`_collapse_dotdot` are copy-path-only, and `create_skill_symlinks`/`create_agent_symlinks` are called **only** at `:495-496` (the copy branch being deleted; `post_install:256-259` covers symlink creation on delegation). So all six are removable — the grep is the safety gate confirming nothing changed, not an open question. If any sub unexpectedly has another caller, keep it.
- [ ] Rewrite `cmd_update`'s `if/elsif` method dispatch (`:476-499`) as one delegation block parameterised by `$method` (subtree|copy); pass the full env block with `CWF_METHOD=$method`.
- [ ] Delete `update_copy`, `copy_tree`, `_escapes_src`, `_collapse_dotdot`, and (audit clearing) `create_skill_symlinks`/`create_agent_symlinks`.
- [ ] Prune unused imports — pre-verified: after these deletions, `find` (`:579,623`), `copy` (`:597`), `rmtree` (`:608-610`), and `make_path` (`:595,635,662`) lose **all** callers, so remove all three import lines: `use File::Find;` (`:22`), `use File::Copy qw(copy);` (`:23`), `use File::Path qw(rmtree make_path);` (`:21`). Re-grep to confirm before dropping.
- [ ] Remove the migrated subtests **and the now-dead library loader** from `t/cwf-manage-update.t` — range `:142-256` (the `# --- copy_tree symlink branch ---` comment + `require ".../cwf-manage"` at `:145` + all `copy_tree:*`/`_escapes_src:*` subtests). Keep the `no API keys` subtest at `:259` and `done_testing()`.
- [ ] Refresh `cwf-manage` sha256 in `.cwf/security/script-hashes.json` (same commit).
- [ ] `prove -lr t/` full suite green; `cwf-manage validate` OK.
- [ ] **Checkpoint commit**.

## Code Changes (illustrative)
### `install_copy` — guard before destructive removal
```bash
# Before (scripts/install.bash:217-243, abridged)
git -C "$clone_dir" checkout --quiet "$ref"
if [[ "$CWF_FORCE" == "1" ]]; then rm -rf .cwf .cwf-skills .cwf-rules .cwf-agents; fi
cp -r "$clone_dir/.cwf" .cwf
cp -r "$clone_dir/.claude/skills" .cwf-skills
[[ -d "$clone_dir/.claude/rules" ]] && cp -r "$clone_dir/.claude/rules" .cwf-rules
[[ -d "$clone_dir/.claude/agents" ]] && cp -r "$clone_dir/.claude/agents" .cwf-agents

# After (single source-of-truth list; guard precedes rm -rf)
git -C "$clone_dir" checkout --quiet "$ref"
# (src, dest) pairs — the ONLY place copy sources are enumerated
pairs=( ".cwf:.cwf" ".claude/skills:.cwf-skills" ".claude/rules:.cwf-rules" ".claude/agents:.cwf-agents" )
roots=(); for p in "${pairs[@]}"; do s="$clone_dir/${p%%:*}"; [[ -d "$s" ]] && roots+=("$s"); done
"$clone_dir/.cwf/scripts/command-helpers/cwf-check-tree-symlinks" "${roots[@]}" \
    || die "refusing to install: upstream tree contains an out-of-tree symlink"
if [[ "$CWF_FORCE" == "1" ]]; then rm -rf .cwf .cwf-skills .cwf-rules .cwf-agents; fi
for p in "${pairs[@]}"; do s="$clone_dir/${p%%:*}"; [[ -d "$s" ]] && cp -r "$s" "${p##*:}"; done
```
### `cwf-manage` copy branch — delegate like subtree
```perl
# Before: copy branch runs update_copy + create_*_symlinks (cwf-manage:490-496)
# After: one block for both methods, differing only by CWF_METHOD
local $ENV{CWF_METHOD} = $method;   # 'subtree' or 'copy'
# ... same CWF_FORCE/CWF_SOURCE/CWF_REF env + system('bash',$installer) + rc-handling
```

## Test Coverage
**See e-testing-plan.md for the complete test plan.** Summary: new `t/cwf-check-tree-symlinks.t` (unit + CLI, incl. source-root-equal); migrated-out subtests removed from `t/cwf-manage-update.t`; install/update integration coverage (guard on both paths, `.cwf-rules`/symlink parity vs subtree per AC8) defined in e.

## Validation Criteria
**See e-testing-plan.md.** Gating: `prove -lr t/` green and `cwf-manage validate` OK at every checkpoint commit; AC1-AC9 from b-requirements satisfied.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished. If work must be deferred: get user approval, update success criteria, create a follow-up task, and document the deferral in Actual Results.

## Decomposition Check
- [ ] Time >1 week? No. — [ ] People >2? No. — [x] Complexity 3+ concerns? Borderline, sequenced. — [ ] Risk isolation? Guard is verbatim port w/ both-path tests. — [ ] Independence? No (ordered steps). **Flat task.**

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned steps executed; full detail in f-implementation-exec.md. Two documented deviations: (1) the `install_copy` guard wiring added an explicit `[[ -x "$guard" ]] || die` precheck the plan's snippet didn't show (FR2/NFR5 — silent skip would be fail-open); (2) five orphaned imports were removed, not the three the plan named (`File::Spec`/`File::Basename` were orphaned by deleting `_escapes_src`/the symlink subs, verified against HEAD).

## Lessons Learned
The plan's caller-enumeration step caught the dead subs cleanly, but the import count was eyeballed from the `use` list rather than derived by grepping each import's symbols against HEAD — which is why it under-counted by two. Future deletion tasks should grep imports the same way they grep callers. See j-retrospective.md.
