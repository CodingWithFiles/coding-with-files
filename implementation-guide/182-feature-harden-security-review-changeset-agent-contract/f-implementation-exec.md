# Harden security-review-changeset agent contract - Implementation Execution
**Task**: 182 (feature)

## Task Reference
- **Task ID**: internal-182
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/182-harden-security-review-changeset-agent-contract
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status when complete

## Actual Results

### Step 1: Script — CLI surface (FR1/FR2/FR3, D3/D4)
- **Planned**: add `find_git_root`/`atomic_write_text` imports; `%WF_STEP` allowlist; `--phase`→`--wf-step`; `max_lines` default 500.
- **Actual**: done as planned. `--phase=` now falls through to the unknown-argument arm (exit 1). `--wf-step` validated against the ten-value `%WF_STEP` hash after the parse loop (missing → `(missing)`, bad/traversal → `'<value>'`, both exit 1). `max_lines => 500` default; explicit-override `/^[1-9]\d*$/` validation retained.
- **Deviations**: none.

### Step 2: Script — unified scratch path + write (FR4/4.1/4.2/4.3, D1/D2)
- **Planned**: one write path for empty & non-empty; `find_git_root` + dashify; `mkdir($scratch,0700) unless -d`; `atomic_write_text(mode=>0600)` in `eval`→exit-1; delete old `print $diff`.
- **Actual**: done as planned. `$diff = @included ? capture_git(...) : '';` then trailing-`\n` normalisation; `$line_count = ($diff =~ tr/\n//)`. `eval { atomic_write_text(...); 1 } or do { warn; exit 1 }`. Old early `!@included` exit and the `print $diff` removed.
- **Deviations**: none.

### Step 3: Script — stdout/exit contract (FR5/D2/D5)
- **Planned**: single confirmation line; keep stderr summary; move cap check after write+confirm; drop `defined` guard on `max_lines`.
- **Actual**: `print "$PROG: wrote $line_count lines to $out\n";` (both empty & non-empty). stderr summary + `--verbose` unchanged. Cap check `if ($production > $opt{max_lines})` moved after the confirmation. Empty-branch special-case `warn` dropped — the unified `sprintf` summary handles 0 files.
- **Deviations**: none.

### Step 4: Script — header & usage
- **Planned/Actual**: top-of-file comment block (cap, new "Agent contract" section, Usage, Output, Exit) and `print_usage()` updated to `--wf-step`, file-output model, default 500, new exit semantics.

### Step 5: Consumers (D6) — same commit
- **Actual**: `cwf-implementation-exec` and `cwf-testing-exec` Step 8 rewritten — exact one-command invocation (no `--max-lines=500`, agent-invoked, no boilerplate), exit-code-first branching with the new `count == 0` / `no parseable confirmation line` arms, `{wf_step}`/`{changeset_file}` agent inputs, verdict file pinned to `security-review-output-<wf-step>.out`, `warning:` surfacing preserved. Agent def: `{phase}`→`{wf_step}`, inline `{changeset}` block removed, `{changeset_file}` path the agent Reads. `security-review.md`: invocation line, cap prose, exit/empty prose, and prompt template all migrated.
- **Deviations**: none.

### Step 6: Hash refresh (Constraints, AC8)
- **Planned**: chmod script to recorded 0500; refresh script SHA256 in `script-hashes.json`; per-file `git log` verification; `cwf-manage validate` clean.
- **Actual**: script chmod 0500; SHA256 refreshed (`f2a25dec…`→`828cceb4…`). **Plan omission corrected**: the `cwf-security-reviewer-changeset.md` agent is *also* hash-tracked and was edited in Step 5 — `cwf-manage validate` flagged it, and its SHA256 was refreshed in the same commit (`a26c7765…`→`2d2cc05a…`, perm 0444 unchanged) per the hash-updates convention. `cwf-manage validate` now `OK`.
- **Deviations**: the plan's "Files to Modify" listed only the script under `script-hashes.json`; the agent-file hash refresh was a necessary addition surfaced by `validate`.

## Smoke tests (manual, during exec)
- Confirmation line format verified: `security-review-changeset: wrote 750 lines to <abs>` with `.out` at 0600, dir 0700, count == `wc -l`.
- Error paths: `--phase=implementation` (unknown arg), `--wf-step=bogus`, `--wf-step=../escape`, missing `--wf-step` — all exit 1.
- Stale-string sweep: no `--phase=`, `--max-lines=500`, bare `{phase}`/`{changeset}` remain in `.cwf`/`.claude` source. (Full automated coverage is g-testing-exec.)

## Blockers Encountered

None. One in-flight clean-up: `.cwf/scripts/command-helpers/cwf-claude-settings-merge` had a pre-existing working-tree perm drift (0700 vs recorded 0500, no source/hash change) that `cwf-manage validate` reported; chmod 0500 cleared it so `validate` is fully clean. Not committed (working-tree perm only, not git-tracked).

## Deferral Check
Before marking status=Finished, verify:
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met (SC1–SC5)
- [x] All requirements from b-requirements-plan.md addressed (FR1–FR6, NFR1–5)
- [x] All design guidance in c-design-plan.md followed (D1–D6)
- [x] No planned work deferred without user approval
- [x] If work deferred: Follow-up task created and linked (n/a — nothing deferred)

**If deferral required**: Get user approval, document rationale, create follow-up task.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
- The plan's hashed-file list was incomplete: editing the `cwf-security-reviewer-changeset.md` agent (a hash-tracked file) required a hash refresh the plan did not enumerate. `cwf-manage validate` caught it — the integrity gate did its job. Future doc/agent edits should be cross-checked against `script-hashes.json` at plan time.

## Security Review

**State**: no findings

I have verified the dependencies. The implementation matches the design claims. Let me reason through the threat categories.

### Security review — Task 182 (implementation-exec)

I reviewed the full 929-line changeset and cross-checked the two security-load-bearing helpers it depends on (`CWF::ArtefactHelpers::atomic_write_text` and `CWF::Common::find_git_root`) against their on-disk source. The substantive code change is confined to `.cwf/scripts/command-helpers/security-review-changeset`; the rest is doc/skill/agent prose, a hash-table refresh, and new workflow-guide files.

**(a/b) Shell / path / command injection in the new path derivation and filename interpolation.** The two new untrusted-ish inputs that reach the filesystem are `--wf-step` and the derived `$scratch` path. `--wf-step` becomes a literal component of `$out`; it is gated through a fixed-literal allowlist hash (`%WF_STEP`, ten kebab-case suffixes) before it reaches any path, and the guard rejects undefined values too. Traversal-shaped (`../escape`), empty, and the removed `--phase` form all fail the gate (exit 1). Exact-match against literals with no `/`, `.`, or shell metacharacters ⇒ injection-safe. `--task-num` unchanged (`/^\d+(?:\.\d+)*$/`). `$scratch` derives from `find_git_root()` (argument-free backtick, no interpolation surface); undef handled (exit 1). No shell invoked for the write path. No new hazards.

**(d) The `/tmp` write surface and symlink-attack resistance.** Script-owned `mkdir($scratch,0700)` before any write (load-bearing: `atomic_write_text`'s `make_path` fallback would otherwise create the dir at umask-default mode). `unless -d` does not re-assert mode on a pre-existing foreign dir — fail-closed defence there is the subsequent 0600 write failing (accurately documented). `atomic_write_text` writes via same-dir `File::Temp` + chmod 0600 + `rename`; `rename(2)` replaces the destination name, so a pre-planted symlink is replaced and its referent never written through. Truncate-on-overwrite also follows. File 0600, dir 0700. No exploitable race or write-through.

**(c) Secrets / sensitive data.** `.out` holds a full `git diff`, written 0600 in a 0700 per-task dir — appropriate confinement. Hash-table refresh is the expected same-commit update. No concern.

**(e) Pattern-level risks.** The allowlist is the *sole* thing making the filename interpolation safe — already documented (NFR4/D3) as the audit point: a future relaxation of `--wf-step` to a regex/free-form value would reopen path-injection. The `mkdir-first` idiom is correct here; other `atomic_write_text` callers targeting `/tmp`-class dirs should be audited. Both are forward-looking notes, not actionable defects.

### Conclusion
The `/tmp` write surface and `--wf-step` filename interpolation are correctly gated (fixed-literal allowlist + script-owned `mkdir 0700` + atomic same-dir-temp/rename), verified against `atomic_write_text` and `find_git_root`.

```cwf-review
state: no findings
summary: /tmp write surface and --wf-step filename interpolation are correctly gated (fixed-literal allowlist + script-owned mkdir 0700 + atomic same-dir-temp/rename); verified against atomic_write_text and find_git_root. Forward-looking audit note: allowlist relaxation would reopen path-injection.
```
