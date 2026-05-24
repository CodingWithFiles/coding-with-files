# fix outstanding cwf-manage issues - Implementation Plan
**Task**: 159 (feature)

## Task Reference
- **Task ID**: internal-159
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/159-fix-outstanding-cwf-manage-issues
- **Template Version**: 2.1

## Goal
Implement FR1 (`cwf_version` semver derivation), FR2 (`fix-security --dry-run`), FR4 (backtick→`IPC::Open3`) per the design. FR3 is deferred (see c-design D3). Implementation order **FR4 → FR1 → FR2** (FR4's `git_capture` is FR1's dependency).

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why".

## Files to Modify
### Primary
- `.cwf/scripts/cwf-manage` — all three FRs (single file). New `git_capture` + `git_describe_version` helpers; edits to `find_git_root`, `cmd_list_releases`, `cmd_update`, `cmd_fix_security`, `_apply_recorded_perms`, `cmd_help`.

### Supporting
- `.cwf/security/script-hashes.json` — refresh the `cwf-manage` `sha256` value (entry block `:204-208`; the `sha256` field is line **`:207`**) in the **same commit** as the `cwf-manage` edits (hash-updates convention; `sha256sum .cwf/scripts/cwf-manage` → write the digest).
- Tests (cases specified in e-testing-plan): `t/cwf-manage-update.t` and/or `t/cwf-manage-update-end-to-end.t` (FR1), `t/cwf-manage-fix-security.t` (FR2), `t/cwf-manage-list-releases.t` (FR1 knock-on regression + FR4 `cmd_list_releases` behaviour).

## Implementation Steps

### Step 0: Setup
- [ ] Confirm on branch `feature/159-...`; baseline tests green: run the cwf-manage `t/*.t` suite to capture a clean pre-change baseline.

### Step 1: FR4 — `git_capture` helper + convert the two backtick sites
**Mechanism decision (supersedes c-design D4's `IPC::Open3`)**: use the **list-form `open '-|'` fork-and-reopen-`STDERR` pattern**, not `IPC::Open3`. Rationale from the impl-plan review: (1) NFR3 explicitly prefers the existing `open '-|'` idiom already used 4× in this file (`check_clean_tree:118`, `resolve_ref:163,175`, `resolve_sha:189`) — D4's premise that `open '-|'` "cannot suppress stderr" is false (a forked child can reopen `STDERR` before `exec`); (2) avoids two `IPC::Open3` traps — the stderr-merge-into-stdout default (empty err handle dups stderr onto stdout, the opposite of what we want) and the read/reap deadlock; (3) zero existing `IPC::Open3` usage to pattern-match against. Both backtick sites currently use `2>/dev/null`, so both need stderr suppression — a shared helper is still warranted.
- [ ] Add `git_capture(@argv)`:
  - `my $pid = open(my $fh, '-|') // die_msg("git_capture: fork failed: $!");`
  - child (`$pid == 0`): `open(STDERR, '>', '/dev/null');` then `exec('git', @argv);` then `exit 127;` (exec-failed guard).
  - parent: **drain to EOF first** — `my @lines = <$fh>;` — **then** `close($fh);` (close reaps the child; reading before close avoids any pipe-buffer deadlock on large output like `git ls-remote --tags` with many tags). `chomp @lines;` Return `(\@lines, $? >> 8)`.
- [ ] `find_git_root` (`:66-71`): replace the backtick `git rev-parse --show-toplevel` with `git_capture('rev-parse','--show-toplevel')`; keep the existing "not inside a git repository" `die_msg` on non-zero/empty. No `-C`/`chdir` introduced — runs in the process cwd exactly as the backtick did (same resolved root).
- [ ] `cmd_list_releases` (`:309`): replace the backtick `git ls-remote --tags "$source" 'v*' 2>/dev/null` with `git_capture('ls-remote','--tags',$source,'v*')`; `$source` is now a list element (no shell string). Preserve the `die_msg` on non-zero (replaces the `$?` check at `:310`). stderr suppression preserved (the helper redirects it).
- [ ] Confirm `resolve_ref`/`resolve_sha` left untouched (already perlcritic-clean; out of scope).

### Step 2: FR1 — `git_describe_version` + version/ref write
- [ ] Add `git_describe_version($clone_dir, $sha)`: call `git_capture('-C',$clone_dir,'describe','--tags','--always',$sha)`; on exit 0 return the trimmed first line; on non-zero **return `$sha`** (never empty, never a bare ref). **Two distinct paths (load-bearing for NFR5)**: the *no-tags-reachable* case is handled by `--always` → emits the abbreviated SHA at **exit 0** (the normal return path); the *corrupt-clone / bad-committish* case is the **non-zero** exit → `$sha` fallback. They are not the same branch.
- [ ] `cmd_update` version-write block (`:477-478`): `cwf_version` ← `git_describe_version($clone_dir,$sha)` (was `$resolved`); `cwf_ref` ← `$ref` (was `$resolved`). Leave `cwf_sha`/`cwf_installed`/manifest writes unchanged.
- [ ] Sanity: `$ref` here is the original request (`:376-377`, defaulted to `latest`); `$clone_dir`/`$sha` are in scope (`:407`,`:414`).

### Step 3: FR2 — `--dry-run` + unknown-arg rejection + docs
- [ ] `_apply_recorded_perms` (`:782`): add 4th param `$dry_run` (default falsey). At the mutation site (`:842`): when `$dry_run`, skip `chmod` and push the would-be repair (`rel`/`from`/`to`) into `@repaired`. Existence (`:806`) and sha256 (`:823`) gates unchanged.
- [ ] Confirm `apply_exact_perms_or_die` (`:887`) call is unchanged (omits the param → false) — exact-mode laydown untouched.
- [ ] `cmd_fix_security` (`:861`): reads the **global `@ARGV`** (the dispatcher at `:954` calls `cmd_fix_security($git_root)` without passing args — consistent with how `list-releases` greps `@ARGV` at `:950`; confirm this at exec). Parse in order — (1) detect+remove `--dry-run`; (2) any remaining element → `die_msg("fix-security: unknown argument '$arg'")`. Pass `$dry_run` into `_apply_recorded_perms(..., 'additive', $dry_run)`. Prefix would-be-repair lines with `[dry-run] ` when dry-run.
- [ ] **Dry-run summary/exit semantics** (robustness): live `cmd_fix_security` prints `repaired N file(s); validate: OK` (`:880`) on success. In dry-run, the summary MUST NOT claim `validate: OK` (nothing was changed/validated) — print a dry-run-distinct line (e.g. `[dry-run] would repair N file(s); 0 unfixable`) and `exit 0` when there are only would-be repairs. Still `exit 1` (and print the unfixable summary, `:875-877`) on genuine unfixables (missing/sha-mismatch). AC3 asserts the wording + exit code.
- [ ] `cmd_help` (`:919-920`): document `fix-security --dry-run`.

### Step 4: Integrity refresh (FR5) + validate
- [ ] `sha256sum .cwf/scripts/cwf-manage`; write the digest into `.cwf/security/script-hashes.json` `cwf-manage.sha256` (line `:207`).
- [ ] Run `.cwf/scripts/cwf-manage validate` → OK before the phase commit (the checkpoint helper also runs it).

### Step 5: Tests + regression
- [ ] Add/adjust tests per e-testing-plan (FR1 version/ref, FR2 dry-run no-mutation + sha-mismatch surfaced + unknown-arg, FR4 behaviour-equivalence).
- [ ] **`git_capture` unit test**: `t/cwf-manage-list-releases.t` (and the other unit tests) load `cwf-manage` via `do $SCRIPT` with `@ARGV=('help')`, exercising only pure functions — `cmd_list_releases`'s `git ls-remote` path has **no** existing coverage, so AC10's "no regression" guards `filter_releases`, not the FR4 conversion. Add a `main::git_capture(...)` unit test (accessible via the same `do` load) asserting the `(\@lines, $exit)` contract on a known-good invocation (e.g. `git_capture('rev-parse','--show-toplevel')` from inside the repo) and a non-zero case, so the new helper is actually exercised.
- [ ] Run the full cwf-manage `t/*.t` suite; confirm `t/cwf-manage-list-releases.t` passes unchanged (FR1 knock-on, AC10).
- [ ] **AC7 gate — policy-specific**: the file already emits ~20 unrelated severity-3/4 violations, so a bare `perlcritic --severity 3` will not exit clean. Check the specific policy: `perlcritic --single-policy InputOutput::ProhibitBacktickOperators .cwf/scripts/cwf-manage` reports **no** violations (or grep a severity-3 run's output for `ProhibitBacktickOperators` → empty).

## Sequencing / commit note
All three FRs edit the single file `.cwf/scripts/cwf-manage`. The implementation-exec (f) phase implements them in order FR4→FR1→FR2, then performs **one** hash refresh of the final `cwf-manage` state and a single f-phase checkpoint commit.
**No interim commits within phase f.** The `sha256` entry signs the committed file state, and `cwf-manage validate` (run by `cwf-checkpoint-commit`) fails on any mismatch. If FR4/FR1/FR2 were committed separately, each interim commit would need its own hash refresh to keep `validate` green. Instead: accumulate all three edits → refresh once → single checkpoint commit. (Between the first edit and the refresh, `validate` will show a transient mismatch — expected; do not commit in that window.)

## Test Coverage
**See e-testing-plan.md for the complete test plan.**

## Validation Criteria
**See e-testing-plan.md for validation criteria and results.** Headline gates: AC1-AC4, AC7-AC10 from b-requirements (AC5/AC6 belong to the deferred FR3 and are out of scope here).

## Scope Completion
FR1/FR2/FR4 are the full scope. FR3 was descoped at the design review gate with maintainer approval and **remains on the backlog** (`BACKLOG.md:1242`) — not retired by this task. The retrospective must retire only the three implemented backlog items.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned steps executed in order FR4→FR1→FR2 with no scope deviation; full detail in f-implementation-exec.md. The one in-flight fix was collapsing a bare `POSIX::_exit(127)` after `exec` into a single statement to clear perl's "Statement unlikely to be reached" warning.

## Lessons Learned
Switching FR4 from IPC::Open3 to a list-form `open '-|'` fork at the implementation-plan review — before any code — cost nothing, where the same change in exec would have meant rework. Mechanism choices belong at the plan-review gate. See j-retrospective.md.
