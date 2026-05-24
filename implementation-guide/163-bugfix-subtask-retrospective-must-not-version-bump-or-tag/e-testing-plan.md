# subtask retrospective must not version-bump or tag - Testing Plan
**Task**: 163 (bugfix)

## Task Reference
- **Task ID**: internal-163
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/163-subtask-retrospective-must-not-version-bump-or-tag
- **Template Version**: 2.1

## Goal
Lock the subtask-skip behaviour and the `is_subtask_num` predicate contract, and prove no regression to the integer (top-level) path.

## Test Strategy
### Test Levels
- **Unit**: `is_subtask_num` predicate truth table in `t/versioning.t`.
- **Integration**: per-helper CLI behaviour in `t/cwf-version-bump.t`, `t/cwf-version-tag.t`, `t/cwf-version-next.t` (existing `make_repo`/`run_script` harness).
- **Regression**: full `prove t/` run; existing version-helper subtests must still pass unchanged.

### Coverage Targets
- **Critical path** (subtask → clean skip; integer → unchanged behaviour): 100%.
- **Edge cases** (malformed dotted values route to the error path): explicit per helper.
- **Predicate**: every documented true/false row asserted independently of the CLI capture regex.

## Test Cases

### Unit — `t/versioning.t` (predicate)
- **TC-U1**: `is_subtask_num` true rows.
  - **Given**: the exported predicate.
  - **When**: called with `'3.2'`, `'3.2.1'`, `'163.4'`.
  - **Then**: returns true for each.
- **TC-U2**: `is_subtask_num` false rows (locks contract independent of capture regex).
  - **Given**: the predicate.
  - **When**: called with `'163'`, `'3.'`, `'.2'`, `'3..2'`, `'x'`, `undef`.
  - **Then**: returns false for each.

### Integration — each of bump / tag / next
- **TC-1 (skip)**: subtask number → clean no-op.
  - **Given**: a repo with a valid `cwf-project.json` (`major_minor: v1.0`).
  - **When**: `--task-num=3.2`.
  - **Then**: exit 0; stdout matches `^skipped: version actions apply to top-level tasks only \(subtask 3\.2\)`; for bump, `last_released` is **untouched**; for tag, no tag created (`git tag -l` empty); for next, no version printed.
- **TC-2 (no side effect / short-circuit before read_config)**: subtask skip works with no readable config.
  - **Given**: a git repo with **no** `cwf-project.json` (`make_repo(undef)`), and separately a malformed one (`make_repo('{ }')`, no `major_minor`).
  - **When**: `--task-num=3.2`.
  - **Then**: exit 0 + skip line in both cases (proves the skip exits before `read_config()`, which would otherwise `die` with "not found" / "major_minor missing").
- **TC-3 (malformed dotted → error, not skip)**: 
  - **Given**: a valid repo.
  - **When**: `--task-num=3.`, `--task-num=.2`, `--task-num=3..2`.
  - **Then**: exit 1; stdout matches `unknown argument`; no skip line; no side effect.
- **TC-4 (integer path unchanged — regression)**:
  - **Given/When/Then**: existing integer subtests (e.g. bump `--task-num=114` → `bumped: v1.0.114`; idempotent; `bump_version=false` skip; missing `major_minor` → exit 1) continue to pass byte-for-byte.

### `cwf-version-tag` specific
- **TC-5 (skip with `--message` present)**:
  - **Given**: a valid repo.
  - **When**: `--task-num=3.2 --message=foo` and the reversed order `--message=foo --task-num=3.2`.
  - **Then**: exit 0 + skip line in both orders; no tag created (confirms the `--message` arm does not interfere with the skip).

### Integrity / system
- **TC-6 (validate clean)**: after the four `sha256` refreshes, `.cwf/scripts/cwf-manage validate` reports no version-helper/`Versioning.pm` violations (the pre-existing, unrelated `cwf-security-reviewer-changeset.md` perms drift is out of scope and noted separately).

## Non-Functional
- **Security**: confirm the relaxed capture stays anchored `^…$`; no decimal value reaches `next_version`/`tag_at` (the `git tag -l '$version'` backtick invariant, `Versioning.pm:165`). Covered structurally by TC-1/TC-2 (skip before mutation) + TC-4 (`^\d+$` backstop intact).
- **Reliability**: TC-2 is the graceful-degradation case (skip independent of config state).

## Test Environment
- Standard Perl test harness (`prove`), core modules only (`Test::More`, `File::Temp`, `Cwd`, `JSON::PP`) — no new deps (`feedback_perl_core_only`).
- Each integration subtest builds an isolated throwaway git repo via `make_repo` and `chdir`s back to `$orig_cwd` after; no production config touched.

## Validation Criteria
- [ ] TC-U1, TC-U2 pass (predicate truth table).
- [ ] TC-1..TC-5 pass for each applicable helper.
- [ ] TC-6: `cwf-manage validate` clean for the touched files.
- [ ] Full `prove t/` green — no regressions.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned test cases (TC-U1/U2, TC-1..TC-6) executed and passed — 45 targeted tests. Results recorded in `g-testing-exec.md`. The full-suite run surfaced 2 pre-existing, unrelated failures (perms drift on a Task 162 file), documented and dispositioned there.

## Lessons Learned
Asserting the predicate truth table independently of the CLI capture regex (TC-U2) was worthwhile: it locks the contract at the unit level so a future capture-regex change cannot silently weaken classification. See `j-retrospective.md`.
