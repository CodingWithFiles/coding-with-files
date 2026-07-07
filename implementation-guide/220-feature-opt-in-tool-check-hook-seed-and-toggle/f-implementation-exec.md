# opt-in tool-check hook seed and toggle - Implementation Execution
**Task**: 220 (feature)

## Task Reference
- **Task ID**: internal-220
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/220-opt-in-tool-check-hook-seed-and-toggle
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Actual Results

### Step 2: Pure policy (`CWF::ToolCheck`) + unit tests
- **Planned**: add `use JSON::PP ()`, `resolve_active`, `merge_seed`; extend `@EXPORT_OK`; unit-test coercion, precedence, no-clobber.
- **Actual**: added both pure functions. `resolve_active` walks trusted layers high→low, counts only a JSON boolean (`JSON::PP::is_bool`), default 1. `merge_seed` appends starter ids absent from `@existing`, returns `(\@merged,$added,$skipped)`, rules-only. Added TC-U1–U5 to `t/tool-check.t` (12 subtests total, all pass).
- **Deviations**: none.

### Step 3: Hook hot-path + `--check` (`pretooluse-bash-tool-check`)
- **Planned**: `load_merged` returns decoded layers (single read pass); `trusted_layers` transform (checked-in excluded); insert `return unless resolve_active(...)` after the zero-rules guard, before compile/match; extend `--check`.
- **Actual**: `load_merged` now returns `($merged,\@notes,\@decoded)` low→high from one read pass. Added `trusted_layers` selecting `[project-local, user-global]` high→low. Kill-switch inserted at the planned point. `run_check` gained an "Effective active" line (derived through the same `resolve_active`+`trusted_layers`) and per-layer `active=<v>` with a `(active ignored)` marker on checked-in. Added TC-H1–H8 to `t/pretooluse-bash-tool-check.t` (17 subtests, all pass).
- **Deviations**: TC-H7's compile-probe first used a `BEGIN { open… print($f…) }` sentinel whose `print` form was ambiguous inside the JSON-embedded string; switched to `BEGIN { mkdir … }` (unambiguous) with a positive control. No production change.

### Step 4: `tool-check-seed` helper + tests
- **Planned**: new `on|off|seed` helper — embedded regex-only starter set; symlink-safe dir creation; atomic preserving RMW (0600); unknown-subcommand reject; state echo; add a 0500 hash entry.
- **Actual**: wrote `.cwf/scripts/command-helpers/tool-check-seed`. `seed` merges the starter set into the checked-in layer (preserving RMW) then clears a project-local `active:false` (rules-first ordering per F3); `on`/`off` flip the project-local switch. Every read refuses a symlink/non-regular/non-JSON file; every write is symlink-safe parent creation + temp+`O_EXCL`+`rename` at 0600; every syscall checked. Unknown subcommand → exit 2, usage to stderr, no write. `--help` on stdout. Starter set (regex-only, from the documented anti-pattern corpus): `no-sed-line-range`, `no-cat-pipe-grep`, `no-find-exec`. Added `t/tool-check-seed.t` (TC-S1–S8, 8 subtests, all pass). Recorded a `0500` hash entry.
- **Deviations**: none.

### Step 5: Skill wiring + gitignore + docs + backlog
- **Planned**: `/cwf-config tool-check <on|off|seed>` dispatch; `/cwf-init` opt-in confirm (default decline); reconcile `.gitignore` via `cwf-apply-artefacts`; update `tool-check-rules.md`; correct the R3 backlog premise.
- **Actual**: extended `cwf-config/SKILL.md` (parse + dispatch section + success criterion) and `cwf-init/SKILL.md` (new step 7b opt-in, default decline, non-fatal; step-8 `git add` now includes `.cwf/tool-check/`). Ran `cwf-apply-artefacts` (update mode, `CWF_UPGRADE_RESOLVE=keep`) — it added exactly one `.gitignore` line (`.cwf/tool-check/*/settings.local.json`) and kept all other artefacts. `tool-check-rules.md` now documents the `active` flag (trusted-layer precedence, boolean-only, checked-in ignored, default-true, F2 degradation) and the gitignore-as-security-control rationale. Corrected BACKLOG R3 (stale "re-derive" premise) and the standalone tool-check-seed entry (mechanism now exists; remaining work is a rollout decision).
- **Deviations**: none — the manifest already declared the glob (design DK3's "add to manifest" wording was superseded in d-plan; confirmed here, no manifest edit needed).

### Step 6: Validation + hash refresh
- **Actual**: refreshed sha256 for `CWF::ToolCheck` and `pretooluse-bash-tool-check`, added the `tool-check-seed` entry (all in this commit). `cwf-manage validate` → **OK**. Full `prove t/` → **968 tests, all pass** (no Task-201 regression). Manual smoke: `--check` renders the new "Effective active: yes" + per-layer `active` columns with the checked-in `(active ignored)` marker. Dogfooding note: during exec, a `head` command tripped the real user-global tool-check rule and was correctly denied → used Read instead.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] All requirements from b-requirements-plan.md addressed
- [x] All design guidance in c-design-plan.md followed (DK1–DK5)
- [x] No planned work deferred (the this-repo checked-in-seed decision was always an h-phase/rollout item, not exec scope)

## Changeset Reviews

Five reviewers ran in parallel over the exec changeset (anchor `ed72881`, 22 files,
2290 lines). Classified by `security-review-classify`. Verbatim outputs in the
per-task scratch dir (`*-review-output-implementation-exec.out`).

### Security Review
**State**: no findings

Shell-free production code; symlink-safe atomic writes (temp+`O_EXCL`+`rename`
0600, per-level `-d && !-l`); `unlink`-before-`O_EXCL` is not TOCTOU (fails closed).
Confirmed all three trust choices: checked-in `active` excluded, boolean-only
coercion, the new early-return can only *allow* (fail-open preserved). No env var
feeds a write path. No actionable concerns.

### Best-Practice Review
**State**: no findings

Matched tags (`golang`, `postgres`) are domain-mismatched to a Perl/markdown
changeset — the known spurious-match noise flagged in the Task-219 retrospective.
Where the Go docs rise to language-agnostic security hygiene, the changeset aligns.

### Improvements Review
**State**: findings — **ADOPTED**

The DK1 trusted-layer ordering was duplicated (hook `trusted_layers` sub + the
helper's inline `effective_active`). **Fix**: moved `trusted_layers` into
`CWF::ToolCheck` (pure, exported, unit-tested via TC-U3b); the hook imports it and
the helper resolves its echo through it — the trust boundary is now single-sourced
and cannot drift.

### Robustness Review
**State**: findings — **ADOPTED** (real bug)

`effective_active` wrapped `read_settings` in `eval`, but `read_settings` failed via
`die_err` → `exit 1`, which `eval` cannot trap — a symlinked/corrupt *user-global*
settings file would turn an already-completed seed/toggle write into a misleading
`exit 1`. **Fix**: added an explicit `soft => 1` mode to `read_settings` (returns
`undef` instead of exiting) and rewired `effective_active` to read every layer soft
and resolve through `trusted_layers` — so the post-write echo degrades gracefully
and matches the hook's resolution exactly. Regression test TC-S9 (symlinked
user-global → `off` still exits 0 and writes).

### Misalignment Review
**State**: findings — **ACCEPTED with rationale** (no change)

The helper hand-rolls JSON read + atomic write rather than reusing
`CWF::ArtefactHelpers`. The reviewer's own analysis is decisive: `atomic_write_text`
uses `make_path` and does **not** reject a symlink target, and `read_json_file` has
no symlink guard — so the shared helpers are *weaker* for this NFR4 threat model and
a direct swap would lose the symlink defence. Coupling a security-sensitive writer
to a general-purpose one to remove duplication is the wrong trade (CWF's own "bad
abstraction is worse than duplication" + verifier/producer implementation-diversity
principle). Kept the self-contained writer. A possible future improvement — add a
symlink-reject option to `atomic_write_text` and converge all three writers — is
recorded here as a candidate, not built (it touches a shared hash-tracked lib used
by other helpers; out of this task's scope).

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
The 5-reviewer exec MAP paid for itself here: robustness caught a real
`eval`-can't-trap-`exit` bug, improvements caught the duplicated `trusted_layers`
(hoisted to the pure module), and misalignment was correctly accepted-with-rationale
(reusing the shared writer would lose the NFR4 symlink defence). Adopt / accept /
document are all first-class dispositions.
