# Harden security-review-changeset agent contract - Implementation Plan
**Task**: 182 (feature)

## Task Reference
- **Task ID**: internal-182
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/182-harden-security-review-changeset-agent-contract
- **Template Version**: 2.1

## Goal
Implement the four-site contract migration per the approved design (D1–D6).

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary (the script)
- `.cwf/scripts/command-helpers/security-review-changeset` — option parse, allowlist, default cap, scratch path + write, confirmation, exit handling, header/usage.

### Consumers (D6 four-site migration)
- `.claude/skills/cwf-implementation-exec/SKILL.md` — Step 8 invocation + branching.
- `.claude/skills/cwf-testing-exec/SKILL.md` — Step 8 invocation + branching.
- `.claude/agents/cwf-security-reviewer-changeset.md` — `{phase}`→`{wf_step}`, `{changeset}`(inline)→`{changeset_file}`(path it Reads).
- `.cwf/docs/skills/security-review.md` — `--wf-step` flag, file-output model, empty/exit semantics, prompt template.

### Supporting
- `.cwf/security/script-hashes.json` — refresh the script's SHA256 + recorded perms (same commit; hash-updates convention).
- `t/security-review-changeset.t` — updated in the **testing** phase (e/g), not here.

## Implementation Steps
### Step 1: Script — CLI surface (FR1/FR2/FR3, D3/D4)
- [ ] Add `find_git_root` to the existing `use CWF::Common qw(...)` import; add `use CWF::ArtefactHelpers qw(atomic_write_text)`.
- [ ] Define a fixed allowlist (hash) of the ten wf-step suffixes; replace `%opt` key `phase`→`wf_step`.
- [ ] Replace the `--phase=(implementation|testing)` arm with `--wf-step=(.+)`; after the parse loop, require `wf_step` defined **and** in the allowlist, else `warn "$PROG: invalid --wf-step '…' (expected one of: …)"; exit 1`. `--phase=…` now falls through to the existing unknown-argument arm (exit 1).
- [ ] Change `max_lines => undef` default to `max_lines => 500`. Keep the `/^[1-9]\d*$/` validation for explicit overrides.

### Step 2: Script — scratch path + write, UNIFIED for empty & non-empty (FR4/FR4.1/FR4.2/FR4.3, D1/D2)
Route the empty and non-empty cases through **one** write path so the mkdir-0700 guard and the line count cannot diverge (robustness/security finding). The current early `!@included → exit 0` branch (`:151-154`) is replaced by computing `$diff=''` and falling through.
- [ ] After task-num resolution, derive `repo_root = find_git_root()` (undef → `warn "$PROG: …"; exit 1`); dashify (`(my $d=$repo_root)=~s{/}{-}g` — absolute path ⇒ canonical leading-dash form); `$scratch = "/tmp/${d}-task-${task_num}"`.
- [ ] `mkdir($scratch, 0700) unless -d $scratch;` on `mkdir` failure `warn "$PROG: cannot create scratch dir $scratch: $!"; exit 1`. Script-owned, before any write — do NOT rely on `atomic_write_text`'s umask `make_path`. **Fail-closed note**: `unless -d` does not re-assert mode on a pre-existing foreign-owned dir; the fail-closed defence in that case is the subsequent `atomic_write_text(mode=>0600)` write failing (per tmp-paths.md), which the `eval` maps to exit 1.
- [ ] `$out = "$scratch/security-review-changeset-$opt{wf_step}.out"`.
- [ ] `$diff = @included ? capture_git('diff', "$anchor", '--', @included) : '';` Normalise: append `\n` iff non-empty and not newline-terminated. `$line_count = ($diff =~ tr/\n//)` — by construction this equals `wc -l $out` (the D5/FR5.1 round-trip invariant). **Delete** the old `my $line_count = (... tr/\n//)` and `print $diff` at `:157-158` (a second `my $line_count` would warn under `use warnings`).
- [ ] `eval { atomic_write_text($out, $diff, mode => 0600) }; if ($@) { warn "$PROG: cannot write $out: $@"; exit 1 }`.

### Step 3: Script — stdout/exit contract (FR5/D2/D5)
- [ ] After the write, print the single confirmation line to stdout: `print "security-review-changeset: wrote $line_count lines to $out\n";` (both empty and non-empty — no diff ever goes to stdout).
- [ ] Keep the stderr `reviewed N files, M lines (P production)…` summary (it already handles the 0-files wording) and the `--verbose` path list.
- [ ] Move the cap check to **after** the write+confirmation: `if ($production > $opt{max_lines}) { warn "cap exceeded: …"; exit 2 }` (max_lines now always defined ⇒ drop the `defined` guard). Otherwise `exit 0`.

### Step 4: Script — header & usage
- [ ] Update the top-of-file comment block (Usage, Output, Exit) and `print_usage()` to `--wf-step`, the file-output model, and the new stdout/exit semantics.

### Step 5: Consumers (D6) — all land in the **same commit** as the script (no half-migrated state)
- [ ] `cwf-implementation-exec/SKILL.md` Step 8: invocation → `.cwf/scripts/command-helpers/security-review-changeset --wf-step=implementation-exec` (drop the now-redundant `--max-lines=500` — it is the default); state it is agent-invoked and run exactly as written; rewrite branching per D6 (exit-first, then count from the confirmation line; pass the `.out` path to the agent); **preserve** the existing "surface any stderr `warning:` line verbatim" instruction (`:57`); **name** (not rename — no fixed name exists today) the verdict scratch file `security-review-output-implementation-exec.out`.
- [ ] `cwf-testing-exec/SKILL.md` Step 8: same with `--wf-step=testing-exec` / `…-output-testing-exec.out`; drop `--max-lines=500`; preserve the `warning:` surfacing.
- [ ] `cwf-security-reviewer-changeset.md`: `## Inputs` → `{wf_step}` + `{changeset_file}` (path); procedure body line "Review the `{phase}`-phase changeset…" → `{wf_step}` and "Read the changeset at `{changeset_file}`"; remove the trailing inline `Changeset:\n{changeset}` block. (Sweep the whole file for `{phase}`/`{changeset}` — both occur in the body, not just Inputs.)
- [ ] `security-review.md`: § "Changeset coverage" invocation line (`--phase`→`--wf-step`), the literal § "Exec-phase prompt template" block (`phase: {phase}` → `wf_step: {wf_step}`; `changeset: |` + `{changeset}` → `changeset_file: <path>`), and the empty/exit/file-output prose (incl. the exit-2/empty wording that currently says "diff already on stdout").

### Step 6: Hash refresh (Constraints, AC8)
- [ ] chmod the script back to its **recorded** perm value (read from `script-hashes.json`, likely 0500) after editing.
- [ ] Refresh the script's SHA256 + perms in `.cwf/security/script-hashes.json` (per hash-updates convention; same commit as the script edit). Per-file `git log` verification before refresh.
- [ ] `.cwf/scripts/cwf-manage validate` clean for the changed script (the pre-existing `cwf-claude-settings-merge` drift is out of scope — separate backlog item).

## Test Coverage
**See e-testing-plan.md for complete test plan** — covers AC1–AC8 incl. the worktree-path, symlink-referent, empty-changeset, and confirmation round-trip cases.

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
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Steps 1–6 executed as written; the unified empty/non-empty write path and exit-ordering landed cleanly. One deviation: Step 6 listed only the script for hash refresh — the edited `cwf-security-reviewer-changeset.md` agent is also hash-tracked and needed its SHA refreshed in the same commit (`cwf-manage validate` caught it). See `f-implementation-exec.md` Step 6.

## Lessons Learned
Plan-time hashed-file enumeration should be driven by grepping `script-hashes.json` for every file to be edited, not by an author's "primary vs supporting" split. Recommended as a process improvement in the retrospective.
