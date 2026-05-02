# Drop perl -I prefix from script invocations - Retrospective
**Task**: 121 (chore)

## Task Reference
- **Task ID**: internal-121
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/121-drop-perl-i-prefix-from-script-invocations
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-02

## Executive Summary
- **Duration**: <0.5 day (estimated: 0.5 day; variance ~0%)
- **Scope**: Originally a four-file invocation cleanup with two "deliberate exceptions" annotated. Pivoted twice during planning: (i) user clarified the principle is shebang `#!` semantics everywhere except `/cwf-init` step 1a, which uses idiomatic `chmod`; (ii) user further required that chmod values be fetched from `script-hashes.json` (no magic numbers). Final scope: zero `perl -I.cwf/lib` invocations in active code, JSON-driven chmod for the one bootstrap site.
- **Outcome**: 4 source files changed, ~30 net lines of test code added, full suite 253/253 green, repo-wide grep clean.

## Variance Analysis

### Time and Effort
- **Estimated** (a-task-plan): 0.5 day, single-file or near-mechanical edit set
- **Actual**: ~half a working session, ~50 net lines across 4 source files + 1 simplify pass
- **Variance**: ~0% — the user's two pivots changed the *shape* of the work but not its size

### Scope Changes
- **Pivot 1** (mid-planning, user-driven): from "annotate two `perl -I` sites as deliberate exceptions" to "zero `perl -I` in active code; bootstrap via `chmod` for `/cwf-init` step 1a; remove the redundant `INSTALL.md` `-MCWF::Common` check". Captured as `0ba7df7 Task 121: Revise task plan after scope pivot`.
- **Pivot 2** (post-planning, user-driven): "no magic numbers in chmod calls — fetch from `script-hashes.json`". Affected both the SKILL bootstrap (inline `perl -MJSON::PP -e`) and the test scaffolding (new `_read_recorded_perms` helper, `_ensure_cwf_manage_executable` reads JSON). Required retargeting TC-4/TC-5 from `cwf-manage` to `cwf-version-tag` so fix-security's chmod path was still exercised. Captured as `eac2e5c Task 121: Revise plans to drive chmod values from script-hashes.json`.
- **Post-impl simplification** (`/simplify`): unified `run_fix_security`/`run_validate` (near-duplicates) into a shared `_run_cwf_manage($tmp, $subcmd)` helper with one-line public wrappers. Captured as `9b6bc5b Task 121: Simplify (post-/simplify review)`. No behaviour change.

### Quality Metrics
- **Static gate**: repo-wide grep (`perl -I.cwf/lib` over active source) returns zero hits.
- **Regression**: 253/253 tests pass; same count as baseline (this task added zero new tests — only changed scaffolding).
- **Hash refresh count**: 0 (none of the 4 modified files are tracked by `script-hashes.json`).

## What Went Well
- **Both user pivots integrated cleanly** because the planning files were the source of truth — each pivot landed as an explicit plan-revision commit (`0ba7df7`, `eac2e5c`) with the retro-trail intact. Implementation only began after the second pivot was agreed.
- **The chmod-via-JSON design avoided the bootstrap chicken-and-egg cleanly**: the SKILL extracts the recorded permission inline (`perl -MJSON::PP -e` is a parser invocation, not a script-substitute), then chmods to that exact value. fix-security then handles every other tracked file. Two-step bootstrap, no magic numbers.
- **Test retarget (TC-4/TC-5 → `cwf-version-tag`)** was the right call. Without it, the bootstrap helper would have masked fix-security's chmod path on the only existing target, silently weakening the test. Identifying this during planning (not during exec) saved a debugging cycle.
- **`/simplify` produced one real win** — the `_run_cwf_manage` factor-out — and the reviewer correctly skipped the lower-value findings (extracting the SKILL one-liner into a helper script would have reintroduced a "perl script" file invocation, defeating the task's principle).

## What Could Be Improved
- **The first plan version assumed two "deliberate exceptions"** (`/cwf-init` step 1a and `INSTALL.md`), reasoning that both were load-bearing. The user disagreed: the SKILL's deliberate exception should still be idiomatic Unix (`chmod`, not `perl -I`), and the `INSTALL.md` line was simply redundant with the `context-manager location` invocation above it. A more aggressive first pass — "what's the *idiomatic* fix here?" — would have caught both at planning time without needing the pivot.
- **Magic-number drift between plan and reality**: the first revision used hardcoded `chmod 0500` in the test helper and `chmod u+x` in the SKILL. Both were "correct enough" but not "tied to the source of truth". The user's "fetch from JSON" pivot caught a real maintainability issue — if `cwf-manage`'s recorded perms ever change, the hardcoded values would silently disagree. The retro lesson: when a permission/value exists in a manifest, prefer reading it over hardcoding, even when the hardcoded value works today.
- **TC-4/TC-5 retarget uncovered a latent test-design subtlety**: tests that mutate the same script that the harness uses to *reach* the device-under-test will get spurious passes after the harness restores it. Worth flagging in `t/lib/CWFTest/Fixtures.pm` if/when other tests need the same pattern.

## Key Learnings

### Technical Insights
- **`cwf-manage` already uses `FindBin` + `use lib "$FindBin::Bin/../lib"`** (line 25–26), so `perl -I.cwf/lib` was strictly redundant for direct invocation — the script was always going to find its libs via the runtime loader. Confirmed by `context-manager.d/location` mirroring the same pattern.
- **`Fcntl qw(:mode)` provides POSIX-named bit constants** (`S_IXUSR`, `S_IRUSR`, etc.) — eliminates `& 0100`-style magic in `stat()`-driven checks. New to this codebase; worth knowing about for future test/lib code.
- **`JSON::PP` is core in Perl 5.14+** — using it inline in the SKILL is dependency-free and robust. The alternative (`jq`) isn't universally installed; brittle grep/sed isn't safe on JSON.
- **Permission validator's bitwise minimum check** (`(actual & expected) == expected`) means `0744` satisfies a `0700` recorded value but doesn't *match* it. The chmod-from-JSON approach matches exactly; a blanket `chmod u+x` would only satisfy minimums, leaving cwf-manage in a near-correct-but-imprecise state. Choosing the JSON-driven approach over symbolic `u+x` is what made the bootstrap precise.

### Process Learnings
- **Plan-mode pivot is cheap when the plan is the single source of truth**: both user redirects landed cleanly because nothing had been implemented yet. The mid-design pivot pattern from Task 120 generalised nicely to mid-planning here.
- **`/simplify` after small chores still pays off**: even with a four-file diff, the agents found one real factor-out and correctly rejected the others. The bar to invoke `/simplify` should be "did I add new code", not "is this a big task".
- **Retargeting tests is sometimes simpler than preserving them under new constraints**: TC-4/TC-5's switch from `cwf-manage` to `cwf-version-tag` is more honest than trying to twist the bootstrap helper to leave cwf-manage perms half-fixed.

### Risk Mitigation Strategies
- **Single source of truth for chmod values**: `script-hashes.json` is now the only place `cwf-manage`'s recorded perm is encoded. Any future change to that value flows through to the SKILL bootstrap and the test helper automatically.
- **Idempotency in the bootstrap helper** (skip-when-user-x-set) means clean-install tests are unaffected by the helper's existence.

## Recommendations

### Process Improvements
- **First-pass planning should ask "what's the idiomatic fix?"**, not just "what's the smallest diff that works". Both pivots in this task could have surfaced at the first plan review by asking that question.
- **Manifest-driven values should stay manifest-driven**: when a permission/path/version lives in a JSON/YAML/TOML manifest, fetch it at use-time rather than copying it. The marginal cost (a JSON parse) is dwarfed by the maintenance cost of drift.

### Tool and Technique Recommendations
- **`Fcntl qw(:mode)`** for permission-bit math in tests and lib code — preferred over raw octal masks like `& 0100`.
- **Inline `perl -MJSON::PP -e`** is the right tool for one-shot JSON extraction in shell scripts and SKILL files (no `jq` dependency, no separate script needed).
- **The `_run_cwf_manage($tmp, $subcmd)` factor-out** in `t/cwf-manage-fix-security.t` is a reusable shape for any future test that exercises multiple cwf-manage subcommands against a fixture.

### Future Work
- **Manual smoke (TC-5/TC-6)** — `/cwf-security-check` and `/cwf-init` end-to-end smokes are documented in `g-testing-exec.md` with reproduction steps; should be run before tagging if integrity-critical.
- **`cwf-manage update` chmod overlap with `fix-security`**: still flagged as out-of-scope from Task 120; this task didn't change anything there. Reconciling remains a future cleanup.

## Status
**Status**: Finished
**Next Action**: Suggest user fast-forward main; tagging is human-only per CLAUDE.md.
**Blockers**: None
**Completion Date**: 2026-05-02
**Sign-off**: Matt Keenan + Claude Opus 4.7

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Source changes: `.claude/skills/cwf-init/SKILL.md`, `.claude/skills/cwf-security-check/SKILL.md`, `INSTALL.md`, `t/cwf-manage-fix-security.t`
- Tests: 7-case `t/cwf-manage-fix-security.t` (scaffolding refactor; assertions JSON-driven)
- Commits on task branch (pre-squash): `79fdcfd → 9b6bc5b` (8 commits)
