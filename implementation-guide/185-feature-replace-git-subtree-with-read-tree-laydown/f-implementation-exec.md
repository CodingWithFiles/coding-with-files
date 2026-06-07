# Replace git-subtree with read-tree laydown - Implementation Execution
**Task**: 185 (feature)

## Task Reference
- **Task ID**: internal-185
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/185-replace-git-subtree-with-read-tree-laydown
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [ ] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [ ] Verify all prerequisites met
- [ ] Execute implementation steps sequentially
- [ ] Update "Actual Results" for each step
- [ ] Document any deviations from plan
- [ ] Update status to "Implemented" when complete

## Implementation Steps (from d-implementation-plan.md)

All six steps executed. Summary of actual results below; see d-implementation-plan.md
for the planned detail.

## Actual Results

### Step 1–2: install.bash — read-tree laydown, default, deprecation
- **Actual**: Added file-level `readonly CWF_PAIRS` SoT array; `install_copy` and the new
  `install_read_tree` both iterate it. `install_read_tree` = guard → `git fetch
  --no-tags <clone> HEAD` → unconditional clear of all four prefixes (`git rm -r --cached
  --ignore-unmatch` + `rm -rf`, fail-closed `&&`) → `read-tree --prefix` each mapped
  `FETCH_HEAD:<src>` → NUL-safe materialise of only the four prefixes. Default flipped to
  `read-tree`; method validation refuses `subtree` with guidance; `install_subtree` and the
  subtree ≥1-commit guard removed; dispatch arm now `read-tree)`.
- **Deviation (fetch ref)**: plan sketched `git fetch … "$ref"`. A raw SHA (the update
  path passes `$sha`) is not fetchable by name on the local transport unless advertised, so
  the code fetches the clone's **HEAD** (just checked out to `$ref`) — always advertised,
  works for tag/branch/SHA alike. Verified end-to-end.

### Step 3: cwf-detect-merges (new helper, hash-tracked, 0500)
- **Actual**: Read-only Perl/core-only. Enumerates merges NUL-separated
  (`git log --merges -z --format='%H%x1f%s%x1f%P%x1f%(trailers:…)' HEAD`); CWF subset =
  subject `^Add CWF (core|skills|rules|agents) ` AND a subtree marker; under-claims on
  ambiguity; counts-only output; `exit 0` always. Forked-child capture uses
  `POSIX::_exit`.
- **Deviation (fingerprint signal)**: an empirical probe showed `git subtree add --squash`
  emits **no** `git-subtree-dir` trailer on the merge — the marker that actually fires is
  the **second parent's subject** `^Squashed '…' content`. The helper checks both (trailer
  OR squash-second-parent); the design's OR already covered this. Probe-verified:
  total=3 / cwf=1 / other=2 on a fixture with one real subtree merge + one unrelated merge
  + one ambiguous decoy (under-claimed correctly).

### Step 4: cwf-manage — migration + subcommand
- **Actual**: `cmd_update` accepts `read-tree`; translates a recorded `subtree` to
  `read-tree` **before** the env build (so the target install.bash never receives subtree);
  **adds** `$v{cwf_method} = $laydown_method` to the version write (gated on laydown
  success — fail-closed); after a migration, invokes `run_detect_merges` (rc ignored). New
  `cmd_check_merges` + `run_detect_merges` helpers; `check-merges` registered in `%dispatch`
  and documented in `cmd_help`.

### Step 5: integrity + docs
- **Actual**: Refreshed `script-hashes.json` for `cwf-manage` and added `cwf-detect-merges`
  (perms 0500) in this same commit. Rewrote INSTALL.md (read-tree primary / copy fallback /
  subtree deprecated+refused; Manual Method 1 is now read-tree covering all four trees;
  removed the "first-class" line and the `CWF_METHOD` default). Added a `CWF_METHOD`
  install-method deprecation entry to `docs/conventions/design-alignment.md` §4.

### Step 6: validation
- **Actual**: `cwf-manage validate: OK`. End-to-end read-tree install smoke (consumer repo,
  source = this repo's HEAD): **merge-free** (laydown staged; after commit 1 parent, 0
  merges), all four prefixes laid down, **each dest tree SHA == mapped source tree SHA**,
  and an unrelated **dirty user file was preserved** (scoped materialise, not `-a`).
  `cwf-detect-merges` and `cwf-manage check-merges` verified functionally.

## Blockers Encountered

None blocking. Two findings surfaced for review (not smoothed):

1. **Fresh-install perms ceiling (pre-existing, method-independent).** After a fresh
   `curl|bash` install, `cwf-manage validate` reports recorded-ceiling **permission**
   violations (e.g. a 0500-recorded script materialised 0700 under umask 077). This is
   **identical for the existing `copy` method** (verified: 42 violations each) — neither
   `cp` nor `git checkout-index` sets the recorded ceiling; both honour umask. The clamp is
   delivered by the `cwf-manage update` / `fix-security` path (`apply_exact_perms_or_die`),
   which the **migration path runs**, so a subtree→read-tree update validates clean. read-tree
   is therefore **no regression** vs copy. b-requirements **AC1** ("fresh install … validate
   clean") is stricter than the established contract (`install-bash-reinstall.t` asserts no
   fresh-install validate; `cwf-manage-update-end-to-end.t` asserts validate post-update).
   **Decision for review**: keep read-tree matching copy (recommended), or add a
   `cwf-manage fix-security` clamp to `post_install` (fixes both methods; adds an
   installer→cwf-manage coupling at bootstrap).

2. **Three existing test files fail (expected).** `install-bash-reinstall.t`,
   `version-records-commit-sha.t`, and `cwf-manage-update-end-to-end.t` build **subtree**
   fixtures via `install.bash`, which now refuses subtree by design. Migrating them to
   read-tree / crafted-subtree fixtures plus adding TC-1..TC-13 is **g-testing-exec** work
   per e-testing-plan (which names these files and the crafted-subtree fixture explicitly).
   Addressed in the testing-exec phase that follows.

## Security Review

**State**: no findings

This changeset replaces the `git subtree` install method with a `git read-tree` laydown, deprecates/refuses `subtree`, migrates existing subtree installs on `cwf-manage update`, and adds a read-only `cwf-detect-merges` helper. The security-relevant new code is in three files: `scripts/install.bash` (`install_read_tree`, method validation), `.cwf/scripts/cwf-manage` (`run_detect_merges`, `cmd_check_merges`, `cmd_update` migration logic), and the new Perl helper `.cwf/scripts/command-helpers/cwf-detect-merges`.

(a) Bash injection: every new git invocation in `install_read_tree` is list/argv form under `set -euo pipefail`; `$dest`/`$src` are hardcoded `readonly CWF_PAIRS` literals, `$tree` is a git-emitted hex SHA, `--` guards path args, and the materialise is a NUL-delimited `ls-files -z | checkout-index -z --stdin` pipe. `$CWF_METHOD` reaches only a `die` message. No injection surface.

(b) Perl/git output: `cwf-detect-merges` uses list-form fork/exec `capture_git` (no shell/backticks), enumerates merges NUL-separated (`-z` + `%x1f` fields), and the forked child bails via `POSIX::_exit`. No newline-splitting of porcelain; the only `split /\s+/` is on hex `%P` parents.

(c) Prompt injection: output is counts-only — commit subjects are regex-matched but never echoed, so a crafted consumer-repo subject can at most shift a count by one and never reaches stdout or any LLM-bound string. The design's central anti-injection property, correctly implemented.

(d) Env vars: `CWF_METHOD` flows only into a `case` dispatch / string comparisons (never a path or command); migration translates recorded `subtree`→`read-tree` before the env build and is fail-closed (`cwf_method` rewritten only after laydown/artefacts/perms succeed). `run_detect_merges` passes the internally-resolved `$git_root` via list-form `system`.

(e) Pattern notes (advisory, not findings): keep new laydown sources as `CWF_PAIRS` literals (a `../`-bearing `$dest` would let `read-tree --prefix` escape the staging area); if `cwf-detect-merges` ever gains a caller-supplied revision, keep the chdir-only/never-as-rev treatment.

Integrity manifest (`script-hashes.json`) adds `cwf-detect-merges` at 0500 and refreshes `cwf-manage` sha256 in the same commit — consistent with the diff; owned by `cwf-manage validate`, not this review.

```cwf-review
state: no findings
summary: read-tree laydown, migration, and counts-only detector are list-form/NUL-safe/fail-closed; two advisory pattern-risk notes (CWF_PAIRS literals; helper rev-args) for future reuse only.
```

## Deferral Check
Before marking status=Finished, verify:
- [ ] All steps from d-implementation-plan.md executed
- [ ] All success criteria from a-task-plan.md met
- [ ] All requirements from b-requirements-plan.md addressed (if applicable)
- [ ] All design guidance in c-design-plan.md followed (if applicable)
- [ ] No planned work deferred without user approval
- [ ] If work deferred: Follow-up task created and linked

**If deferral required**: Get user approval, document rationale, create follow-up task.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
