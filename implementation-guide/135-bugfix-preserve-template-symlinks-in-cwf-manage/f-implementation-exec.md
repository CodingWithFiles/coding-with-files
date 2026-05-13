# Preserve template symlinks in cwf-manage - Implementation Execution
**Task**: 135 (bugfix)

## Task Reference
- **Task ID**: internal-135
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/135-preserve-template-symlinks-in-cwf-manage
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Actual Results

### Step 1: Audit symlinks in source tree
- **Planned**: enumerate every symlink under `.cwf/` and `.claude/skills/`; confirm all targets are relative and resolve within the source tree.
- **Actual**: `git ls-files -s -- .cwf .claude/skills | awk '$1 == "120000"'` returned 38 symlinks. Every target matches the pattern `../pool/<name>`. No absolute targets, no escapes. Precondition for `_escapes_src` met.

### Step 2: Add `CWF::Validate::Templates`
- **Planned**: create `.cwf/lib/CWF/Validate/Templates.pm` per the skeleton; use `supported_types()`; declare `use utf8;`; bare-import pattern (no FindBin).
- **Actual**: file created exactly per the skeleton. Validates against `CWF::Validate::Config.pm` as the pattern source — same header style, same Exporter usage, same `use CWF::WorkflowFiles::V21 qw(supported_types);`. No FindBin (siblings don't have it). Hash recorded later in Step 5.

### Step 3: Wire validator into `cmd_validate`
- **Planned**: add `use CWF::Validate::Templates ();` after the existing PerlConventions import; add the call site to `@all_violations`.
- **Actual**: both edits applied verbatim. `cwf-manage validate` (run after Step 5) reports `validate: OK` on the live repo.

### Step 4: Patch `copy_tree`
- **Planned**: add `use File::Spec ();`, `_escapes_src` helper above `copy_tree`, and a `lstat` + `-l _` branch in the `find` callback.
- **Actual**: applied as planned. **Real bug surfaced during testing**: `File::Spec->abs2rel` does not collapse `..` segments when the entry is nested inside `$src` (e.g. `entry_dir = $src/feature`). The lexical prefix-strip produces `feature/../../etc/passwd`, which fails the leading-`..` regex. Added a small POSIX-only `_collapse_dotdot` helper to canonicalise the absolute path before the inside-`$src` check. `_escapes_src` is now: short-circuit on absolute target, resolve link against entry_dir, collapse `..` segments, prefix-check against the canonicalised `$src`. Unit-tested directly.

### Step 5: Register new module in `script-hashes.json`
- **Planned**: hand-add stub `{ "path": ..., "sha256": "0" }` then run `cwf-manage fix-security` to compute the real hash.
- **Actual**: deviation — `fix-security` only repairs **permissions** (when the sha256 already matches); it treats a sha256 mismatch as drift and reports `UNFIXABLE`. The plan's procedure was incorrect. Recovery used: read the actual sha256 from the `UNFIXABLE` report line, paste it into the manifest. Same procedure applied to `cwf-manage` itself after each script edit. Final state: `cwf-manage validate` reports `validate: OK`.

### Step 6: Tests
- **Planned**: 10 cases in `t/validate-templates.t`; 5 cases extending `t/cwf-manage-update.t`; core-only modules.
- **Actual**: `t/validate-templates.t` (10 subtests) — happy path, type/regular-file, type/directory, target/dangling, pool-name, absolute target, escape, multi-violation deterministic order, pool/ ignored, missing type-dir. `t/cwf-manage-update.t` extended with 6 subtests — relative symlink preserved, pool-pointing symlink preserved, absolute target rejected (fork+exec to capture `die_msg`'s `exit 1`), escape target rejected, in-tree non-pool symlink allowed, plus `_escapes_src` direct unit cases. Two minor deviations to make the tests work:
  1. Added `main() unless caller;` guard at the bottom of `.cwf/scripts/cwf-manage` so the script is loadable as a library via `require`. The existing `cwf-manage-update.t` tests didn't exercise `copy_tree` directly — they tested adjacent helpers via subprocess or fixture-only paths. The guard is a standard Perl idiom and adds zero overhead when the script runs as a script.
  2. The map-as-hash gotcha (`map { $a => $b } LIST` parses as `map +{ ... }` anonymous hashref) plus a subtest-scope `$a`/`$b` quirk in the `sort` block produced empty `%order` lookups. Replaced with explicit `for` loops and a monotonic-index check. Same coverage, less Perl trivia.
- All 457 tests pass under `prove -r t/`.

### Step 7: Run existing suite for regressions
- **Planned**: `prove -rv t/`; `cwf-manage validate`; manual break-and-fix smoke test on the live repo.
- **Actual**: `prove -r t/` → 41 files, 457 tests, all green. `cwf-manage validate` → `validate: OK`. Smoke test: removed `.cwf/templates/feature/a-task-plan.md.template`, replaced it with a regular file containing `inlined regression\n`. `cwf-manage validate` reported:
  ```
  [TEMPLATES] .cwf/templates/feature/a-task-plan.md.template
    Field:    type
    Actual:   regular file
    Expected: symlink to ../pool/a-task-plan.md.template
    Fix:      Re-run 'cwf-manage update' to restore symlinks, or 'ln -sfn ../pool/a-task-plan.md.template .cwf/templates/feature/a-task-plan.md.template'.
  ```
  Both recovery hints present, exit non-zero. Restored the symlink with `ln -sfn`; `validate` is green again.

### Step 8: Documentation
- **Planned**: no user-facing docs; short comment on helper explaining security purpose.
- **Actual**: `_escapes_src` carries a 5-line comment block stating its purpose and that only the symlink target string is canonicalised (no on-disk follow). `_collapse_dotdot` is one-line documented (purpose + POSIX-only).

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed.
- [x] All success criteria from a-task-plan.md met: symlinks preserved by `copy_tree`; `validate` catches symlink-vs-file mismatch; happy path still green; recovery via re-run of `update` confirmed by test; pool/ layout unchanged.
- [x] All design guidance in c-design-plan.md followed (single exact-pattern check in validator, single security gate in `_escapes_src`, uppercase `TEMPLATES` category).
- [x] No planned work deferred.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 135
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: no findings

no findings

This implementation-phase changeset introduces symlink validation and safe copying without detectable security concerns per threat categories (a)-(e).

**Key security aspects verified:**

(a) **Bash injection**: All spawning uses list-form `system()` with no shell metacharacter exposure.

(b) **Git/input validation**: Script uses `-CDSL` (UTF-8 enabled). No vulnerable newline-splitting of git output in the diff.

(c) **Prompt injection**: Not applicable; this is a filesystem validator module with no LLM context flow.

(d) **Env-var handling**: No new env vars introduced; existing `CWF_SOURCE` usage remains safe (list-form spawn).

(e) **Pattern-based risks**: The `_escapes_src()` function is the security-critical gate. It performs lexical path canonicalization (no disk access), correctly collapses `..` segments, and validates symlink targets cannot escape `$src`. The logic handles edge cases correctly (test: empty components, trailing slashes, relative escapes). The Templates.pm validator independently enforces exact-form symlink matching (`../pool/<name>`). Tests comprehensively exercise the gate and cover absolute targets, parent-directory escapes, in-tree references, and multi-level traversal. The `main() unless caller;` guard allows safe require-ability from tests. Safe here because symlink targets are validated before being written, and `$src` comes from a trusted `git clone`; audit future uses if symlink copying moves outside the CWF update context.

## Lessons Learned
- `File::Spec->abs2rel` is a lexical prefix-strip, not a true canonicaliser. For any path-escape check, collapse `..` segments before comparing.
- `cwf-manage fix-security` repairs permissions only; sha256 drift is reported as `UNFIXABLE` by design. The friction (hand-pasting the new hash, or recomputing out-of-band with a *different* implementation like `sha256sum`) is the feature: it forces a deliberate human-visible acknowledgement of why the script changed, and the use of an independent implementation breaks circularity at the verifier/producer boundary. Do **not** propose a `cwf-manage recompute-hashes` subcommand; it would turn the integrity signal into a no-op that agents would silently invoke to paper over compromise.
- `map { K => V } LIST` is a parse gotcha inside subtest closures; prefer explicit `for` loops when populating hashes from arrays in test code.
