# converge cwf-manage copy update onto install.bash - Testing Plan
**Task**: 161 (feature)

## Task Reference
- **Task ID**: internal-161
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/161-converge-cwf-manage-copy-update-onto-install-bash
- **Template Version**: 2.1

## Goal
Define the test strategy verifying FR1-FR5 / AC1-AC9: a single shared symlink-escape guard, applied fail-closed on both the fresh-install and update copy paths, with no laydown drift and no integrity-coverage gap.

## Test Strategy
### Test Levels
- **Unit** (`t/cwf-check-tree-symlinks.t`, new): the ported escape-check subs (`require` the helper under its `caller()` guard).
- **CLI** (same file): the helper's exit code / STDERR contract over real symlink trees.
- **Integration — fresh install** (new TCs in `t/install-bash-reinstall.t`, `method => 'copy'`): the guard on the `bash install.bash` copy path, reusing the existing `build_upstream`/`fresh_consumer`/`do_install` harness.
- **Integration — update** (new TCs in `t/cwf-manage-update-end-to-end.t`, fixture-server pattern): the guard and parity on the `cwf-manage update --method=copy` path.
- **Integrity** (`cwf-manage validate`): ledger coverage + tamper detection of the new helper.
- **Regression**: full `prove -lr t/` and confirmation the migrated-out subtests are gone.

### Coverage Targets
- Every acceptance criterion AC1-AC9 maps to ≥1 TC (table below).
- Critical path (the symlink-escape guard) covered at unit, CLI, **and** both integration paths — 100%.
- Both escaping forms (absolute, `..`-escape) **and** the source-root-equal branch (the one branch with no existing test) exercised.

## Test Cases (Given/When/Then)

### Functional

- **TC-1 — guard logic unit cases** (AC3; FR2). *Given* the helper `require`d as a library. *When* the escape-check sub is called with: `../pool/x` (sibling), `inner` (same-dir), `/etc/passwd` (absolute), `../../etc/passwd` (`..`-escape), `../../..` (multi-parent), and a target resolving to **exactly the source root**. *Then* sibling/same-dir return allowed; absolute, `..`-escape, multi-parent, and source-root-equal return rejected. (Migrates `cwf-manage-update.t:248-256` + adds the source-root-equal case.)

- **TC-2 — guard CLI contract** (AC2, AC5; FR2). *Given* the helper invoked as a CLI over multiple roots. *When* (a) all roots are clean, (b) one root contains an escaping symlink, (c) a symlink whose `readlink` fails. *Then* (a) exit 0, no output; (b) non-zero exit with `refusing escaping symlink target: <entry> -> <link>` on STDERR; (c) non-zero exit (fail-closed on `readlink` failure). Confirms per-root attribution: an escaping symlink under the *second* root is still caught.

- **TC-3 — fresh copy install refuses escaping upstream** (AC4; FR2). *Given* an upstream built with an absolute-target and a `..`-escaping symlink under `.cwf/`. *When* `do_install($consumer, $upstream, method => 'copy')` (no pre-existing install). *Then* install exits non-zero before any `cp -r`; the consumer's `.cwf/` is not created. (Closes the previously-unguarded fresh-copy gap.)

- **TC-4 — fail-closed ordering on update: existing install survives a refused source** (AC5; FR2/NFR5). *Given* a consumer with an existing copy install and an upstream whose tree contains an escaping symlink. *When* a copy-method update runs (`CWF_FORCE=1`, so `install_copy` would `rm -rf`). *Then* the update aborts non-zero **and** the pre-existing `.cwf/` is still present and intact — proving the guard ran before the destructive `rm -rf`. (Direct regression guard for the design's blocking finding.)

- **TC-5 — copy update over existing install succeeds** (AC7; FR4). *Given* a consumer with an existing `.cwf/`. *When* a clean copy-method update runs. *Then* it completes successfully (no "already installed"/exit-3 abort), and the version file reflects the target ref — confirming the full env block incl. `CWF_FORCE=1` is passed.

- **TC-6 — copy/subtree laydown parity** (AC1, AC8; FR1/FR5). *Given* one upstream fixture. *When* it is installed once via `method => 'copy'` and once via `method => 'subtree'`. *Then* the resulting `.cwf-rules/` contents are identical and the `.claude/rules/` (and skills/agents) symlinks match — confirming the converged copy path produces the subtree-equivalent tree, the `.cwf-rules` tree-replace and rules-symlink regeneration reconcile idempotently, and no double-handling artefact remains.

- **TC-7 — guard is integrity-covered and tamper-detected** (AC6; FR3). *Given* the installed tree after this task. *When* `cwf-manage validate` runs on a clean tree, then after a deliberate one-byte edit to `cwf-check-tree-symlinks`. *Then* clean → OK; tampered → non-zero with the helper flagged. Also assert the helper has a `script-hashes.json` entry and is matched by `@CWF_INTERNAL_PREFIXES`.

- **TC-8 — dead-code + regression** (AC1, AC2). *Given* the converged `cwf-manage`. *When* `grep -n` for `update_copy`/`copy_tree`/`_escapes_src`/`_collapse_dotdot` and the removed `t/cwf-manage-update.t` subtests. *Then* none remain in `cwf-manage`; the migrated subtests + dead `require` are gone; `prove -lr t/` is fully green (no orphaned `main::*` reference, no unused-import warning).

### Non-Functional
- **Security**: TC-3, TC-4 (guard on both paths, fail-closed before mutation), TC-7 (integrity + tamper). The D4 trust-model shift (guard runs from the target-version copy) is a documented, accepted trade-off — not a regression — so it is asserted by documentation/review, not a test.
- **Reliability (NFR5)**: TC-4 (existing install intact on refusal), TC-5 (`CWF_FORCE` removal idempotent over an existing tree).
- **Performance (NFR1)**: the guard adds one lexical walk; no measurable latency — no dedicated TC (asserted by inspection).
- **Maintainability (NFR3)**: TC-8 (two laydown paths collapsed to one; dead subs + imports removed).

## Test Environment
### Setup Requirements
- bash 4+, `git`, Perl with core modules — all gated by existing `plan skip_all` guards in the install/update test files.
- Reuse the Task-155 fixture-server / `build_upstream` + `do_install` harness already present in `t/install-bash-reinstall.t` and `t/cwf-manage-update-end-to-end.t`. No new harness needed.
- Tests that touch a real install operate on tempdir consumers, never the live repo (per the test-database principle).

### Automation
- `prove -lr t/` is the suite entry point; new files auto-discovered. `cwf-manage validate` runs at every checkpoint commit via `cwf-checkpoint-commit`.

## AC → Test Case Map
| AC | TC |
|----|----|
| AC1 (copy update via install.bash; no update_copy/copy_tree) | TC-6, TC-8 |
| AC2 (callers enumerated; no orphaned ref; suite green) | TC-8 |
| AC3 (update refuses absolute/`..`/source-root-equal) | TC-1, (TC-4 path) |
| AC4 (fresh install refuses the three escaping cases) | TC-3 |
| AC5 (guard before any copy; no partial laydown) | TC-2, TC-4 |
| AC6 (ledger + prefixes + tamper detected) | TC-7 |
| AC7 (copy update over existing `.cwf/` succeeds) | TC-5 |
| AC8 (`.cwf-rules` once, identical to subtree; symlinks match) | TC-6 |
| AC9 (hash refresh same commit; validate each phase) | process gate, verified in g + every checkpoint |

## Validation Criteria
- [ ] TC-1..TC-8 all pass
- [ ] `prove -lr t/` fully green (no regressions; migrated subtests removed cleanly)
- [ ] `cwf-manage validate` OK on clean tree; fails on a tampered guard (TC-7)
- [ ] Guard exercised on **both** fresh-install (TC-3) and update (TC-4) paths
- [ ] Copy/subtree parity demonstrated (TC-6)

## Decomposition Check
- [ ] Time >1 week? No. — [ ] People >2? No. — [ ] Complexity 3+? Test concerns track the FRs, coupled. — [ ] Risk isolation? No. — [ ] Independence? No. **Flat task.**

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned TCs (TC-1..TC-8) executed and PASS; results in g-testing-exec.md. Full suite 49 files / 533 tests green (+6). TC-1/TC-2 were authored alongside the helper in the implementation phase; TC-6 (copy/subtree parity) landed in `t/install-bash-reinstall.t` rather than the update e2e file, since it compares two fresh installs.

## Lessons Learned
Testing the guard at four levels (unit `_escapes_src`, CLI exit-codes, fresh-install refusal, update delegation) localised coverage to the right layer — the lexical escape logic at unit level, the guard-before-`rm -rf` ordering at the install-integration level — without needing a full install→update cycle for every escape shape. The one branch not deterministically reproducible (readlink-failure fail-closed, a TOCTOU race) is covered by inspection, documented in the test file. See j-retrospective.md.
