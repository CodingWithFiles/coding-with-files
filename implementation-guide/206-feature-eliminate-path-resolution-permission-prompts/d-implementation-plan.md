# Eliminate path-resolution permission prompts - Implementation Plan
**Task**: 206 (feature)

## Task Reference
- **Task ID**: internal-206
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/206-eliminate-path-resolution-permission-prompts
- **Template Version**: 2.1

## Goal
Implement the design: a paths-injecting `UserPromptSubmit` hook + shared `CWF::Common::scratch_parent`/`scratch_dir`, refactor `security-review-changeset` onto `scratch_dir`, and strip the prompting inline blocks from the 20 skills + the `tmp-paths` convention.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Trigger model (carry from design)
The harness prompts on **any** agent-issued Bash command containing a shell variable/expansion (`$VAR`, `${VAR}`, `$(...)`, backticks, `$?`). Acceptance is therefore: the migrated, agent-issued command forms are **all-literal** (helper name + literal positional args), no `$`/backtick anywhere. Shell vars *inside* the helper scripts are fine — they are not agent-issued.

## Files to Modify
### Primary Changes
- `.cwf/lib/CWF/Common.pm` — add two pure functions (no `exit`/`print`), both to `@EXPORT_OK`:
  - `scratch_parent()` — `$num`-free, **no filesystem**: `find_git_root()` → `s{/}{-}g` dashify (leading `/`→leading `-`) → `${TMPDIR:-/tmp}` base (trailing-slash strip) → `"$base/cwf$dashed"`. Returns `($parent, undef)` | `(undef, 'not_a_repo')`.
  - `scratch_dir($num)` — `scratch_parent()` + leaf + write-time guard: validate `^[0-9]+(\.[0-9]+)*$` **before** any FS work; `mkdir($parent,0700)` **then** re-`lstat` reject symlinked parent (`-d && !-l`); leaf `mkdir($scratch,0700)`; **never auto-chmod** (carry the `:274-276` surface-never-smooth comment). Returns `($path, undef)` | `(undef, $kind∈{not_a_repo,bad_num,symlink_parent,mkdir_failed})`.
- `.cwf/scripts/hooks/userpromptsubmit-context-inject` (new) — paths-only `UserPromptSubmit` hook. Leading comment carries `# cwf-hook-event: UserPromptSubmit`. Body (whole thing `eval`-wrapped, **always exit 0**): read stdin JSON, take `cwd` (fallback `Cwd::getcwd()`); if `cwd` is a non-empty existing dir, `chdir` to it **and check the return value — on `chdir` failure do NOT call `find_git_root()`, emit cwd-only** (a silent chdir failure would otherwise resolve the wrong repo); `my $root = find_git_root() // $ENV{CLAUDE_PROJECT_DIR}`; `my ($parent) = scratch_parent()`; print the `CWF PATHS` block (cwd always if known; project_root + scratch only if resolved). `#!/usr/bin/env perl`, `use utf8;`, `use FindBin; use lib "$FindBin::Bin/../../lib";` — hooks and command-helpers are **co-depth** under `.cwf/scripts/`, both `../../lib` (cf. `pretooluse-bash-tool-check:49`). Core-only, perms 0500. Do **not** call `check_perl5opt()` (no hook does; it only warns to stderr — pure noise here). **FR4(d) note for the exec changeset**: this is the first CWF hook to `chdir` to a payload-supplied path each turn — trusted only under the single-user model, fails closed to cwd-only.
- **Registration gate**: the new hook is neither the R3 nor the guard opt-in-gated hook (`cwf-claude-settings-merge:170-173`), so a manifest entry registers it unconditionally on every regen.
- `.cwf/scripts/command-helpers/security-review-changeset` — replace inline block (`:255-287`) with a `scratch_dir($task_num)` call; map any `(undef,$kind)` → existing `warn + exit 1`. Net: helper shrinks; exit-1-on-failure preserved.

### Supporting Changes
- `.cwf/security/script-hashes.json` — **add** the new hook entry (path, `"permissions":"0500"`, sha256); refresh `Common.pm` + `security-review-changeset`. Same commit (hash-update convention). The manifest entry is what lets `cwf-claude-settings-merge` register + allowlist the hook.
- `.claude/settings.json` — **do not hand-edit**. Run `.cwf/scripts/command-helpers/cwf-claude-settings-merge` (manifest-driven) so the new hook is added as a *second* `UserPromptSubmit` group entry + its allow rule; the rules-inject `cat` entry stays untouched. (`cwf-claude-settings-merge` source is **not** modified.)
- `.cwf/docs/conventions/tmp-paths.md` — (a) document the hook-injected scratch parent + `scratch_parent`/`scratch_dir` as single source of truth; (b) re-label the shell Derivation snippet (`:36-47`) as spec, not agent-use; (c) rewrite the "helper deferred" bullet (`:205-207`); (d) fix the "Trivially derivable … no helper script" line (`:148`); (e) re-point the threat-model prose (`:114-126`) at the shared functions; (f) **preserve** the `pretooluse-bash-tool-check` carve-out (`:196-204`) — keeps its own `s{[^A-Za-z0-9]+}{-}g` rule, NOT folded onto `scratch_parent`.
- 20 × `.claude/skills/*/SKILL.md` — delete the "anchor the shell" block (prose para + fenced ```bash anchor) outright. No replacement note (injected context carries cwd + root). Not hashed (`.claude/skills/` absent from `script-hashes.json`).
- `.claude/skills/cwf-new-task/SKILL.md` & `cwf-new-subtask/SKILL.md` Step 5 — replace the inline `${repo_root//\//-}` derivation + `mkdir` with: `mkdir -m 0700 -p <injected scratch parent>/task-<num>` (literal, referencing the injected scratch path; no expansion). Preserve the surrounding non-fatal-on-failure prose.
- `t/` — new `scratch.t`; confirm `security-review-changeset` tests still pass.

### Out of scope (confirm, do not touch)
- `.cwf/scripts/command-helpers/cwf-claude-settings-merge` source (registration is via manifest directive, not a code change).
- `.cwf/scripts/command-helpers/context-manager` (no subcommand — dropped).
- `.cwf/scripts/update-cwf-skill-docs.sh` (one-shot Task-40 dev script).
- `pretooluse-bash-tool-check` hook + its `-tool-check` state dir (carved out, `tmp-paths.md:196-204`).
- Any *other* shell-var usage in skills beyond the anchor/scratch blocks — candidate follow-up backlog item (wider audit), not this task.

## Implementation Steps
### Step 1: Verify the UserPromptSubmit stdin contract (de-risk before building)
- [ ] Confirm the `UserPromptSubmit` payload carries `cwd` (3-line stdin-dump probe; no fabricated assumption). Record the finding. Hook is correct regardless via the `getcwd()`/`CLAUDE_PROJECT_DIR` fallbacks, but this confirms the primary path.

### Step 2: Shared lib + tests first
- [ ] Add `scratch_parent()` and `scratch_dir($num)` to `CWF::Common.pm`; export both.
- [ ] Write `t/scratch.t`: `scratch_parent` happy path byte-identical to the `tmp-paths` snippet form (plain checkout + worktree main-root, via the `t/find-git-root-worktree.t` fixture); `scratch_dir` `bad_num` for `1..2`,`..`,``,`1/2`,`a` (and **no** FS work on reject) + leading-zero accepted; `not_a_repo`; symlink-parent reject (no chmod); idempotent re-call.

### Step 3: The hook
- [ ] Create `userpromptsubmit-context-inject` (directive, eval-wrapped, always exit 0, cwd→getcwd→CLAUDE_PROJECT_DIR fallbacks, **chdir-return checked**); chmod 0500. `use lib "$FindBin::Bin/../../lib"` (co-depth, confirmed).
- [ ] Hook test (canned stdin → assert stdout): happy path emits 3 literals; chdir-failure / no-cwd → cwd-only or nothing; not-a-repo → cwd-only; always exit 0; output contains no `$`/backtick token.
- [ ] Add its `script-hashes.json` entry; register via `cwf-claude-settings-merge`; confirm settings.json now has two `UserPromptSubmit` entries (cat + new hook) and the allow rule.

### Step 4: Refactor the existing consumer
- [ ] Point `security-review-changeset` at `scratch_dir`; run its test(s) green (no behaviour change, still exit-1 on failure).

### Step 5: Migrate skills + convention
- [ ] Delete the anchor block from all 20 skills (no replacement note). Editing hygiene: the anchor block sits just above a `**First**: Run context-manager location` line in many skills — leave that line intact (it is all-literal, no prompt) and don't orphan its surrounding prose. (The now-partly-redundant `context-manager location` calls are a follow-up audit, not this task.)
- [ ] Replace Step-5 derivation in `cwf-new-task` / `cwf-new-subtask` with the literal-path `mkdir`, preserving non-fatal prose.
- [ ] Update `tmp-paths.md` (a–f above).

### Step 6: Hashes + validate
- [ ] `sha256sum` each edited/new `.cwf` file; refresh/add entries in `script-hashes.json`; hook perms 0500.
- [ ] `cwf-manage validate` clean; `prove` the suite green.
- [ ] Migration grep (fixed-string `-F`, dodging the `$`-anchor trap): `grep -rlF 'anchor the shell' .claude/skills/` → empty; no Step-5 ```bash block contains `repo_root//`.

## Code Changes
### `security-review-changeset:255-287` → call the shared lib
```perl
# Before: ~25 lines of find_git_root + dashify + base + mkdir(parent) + lstat-reject + mkdir(leaf).
# After:
my ($scratch, $kind) = scratch_dir($task_num);
unless (defined $scratch) {
    warn "$PROG: scratch unavailable ($kind)\n";   # not_a_repo|symlink_parent|mkdir_failed
    exit 1;
}
```
### Hook output (illustrative)
```
CWF PATHS (use these literal absolute paths directly; do not re-resolve):
  cwd:          /home/matt/repo/coding-with-files
  project_root: /home/matt/repo/coding-with-files
  scratch:      /tmp/cwf-home-matt-repo-coding-with-files     # leaf: <scratch>/task-<num>
```
### Skill anchor block — delete (illustrative, `cwf-task-plan/SKILL.md:23-31`)
Remove the "**Before anything else — anchor the shell…**" paragraph and its fenced `gcd=$(git rev-parse …)` block. No replacement.

### FR4(e) invariant note (Step-5 literal mkdir)
The migrated `mkdir -m 0700 -p <scratch-parent>/task-<num>` bypasses `scratch_dir`'s in-code num-validation — it is safe here **only because `<num>` is the validated task-number argument**. Any future skill that interpolates a non-task-number value (slug, branch) into that literal path would break the invariant `scratch_dir` enforces; such a skill must route through `scratch_dir` instead.

## Test Coverage
**See e-testing-plan.md for the complete test plan.** Core: `t/scratch.t` (unit: both functions, all failure kinds, no-FS-on-bad-num, worktree byte-identity), `security-review-changeset` regression, the hook's fail-open/fallback behaviour, and the FR2 migration grep as a guard.

## Validation Criteria
**See e-testing-plan.md.** Plus: `cwf-manage validate` clean (hashes refreshed same commit), full `prove` suite green.

**Test execution must not itself trip permission prompts** (the property under test): drive tests via the already-allowlisted `prove ...` rule, keeping all dynamic logic *inside* `.t`/Perl (not agent-issued shell). Manual verification commands the agent issues must be all-literal; avoid ad-hoc `$VAR`/`$(...)`/`$?` one-liners — write any needed helper to a file (under the injected scratch path) and run it by literal path. The hook's own output is verified inside a `.t` (feed it canned stdin, assert stdout), not by triggering a live turn. Detailed in e-testing-plan.

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
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
