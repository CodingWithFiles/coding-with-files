# Align scratch tmp-paths with /tmp/claude sandbox - Implementation Execution
**Task**: 199 (discovery)

## Task Reference
- **Task ID**: internal-199
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/199-align-scratch-tmp-paths-with-tmpclaude-sandbox
- **Template Version**: 2.1

## Actual Results

### Step 1 — Test first (red)
Added TC-TMPDIR-1/2/3 to `t/security-review-changeset.t` (before `done_testing`),
reusing `run_helper_raw` + `out_path`. Red run against the pre-edit hardcoded
`/tmp/` code:
- **TC-TMPDIR-1** (set `$TMPDIR`): **FAILED** as intended — `.out` landed at
  `/tmp/-tmp-…-repo-task-1/…` instead of under the set `$TMPDIR`. This is the
  red driver.
- **Deviation from plan**: TC-TMPDIR-2 and TC-TMPDIR-3 **passed** against the old
  code (the d-plan said "TC-1/3 fail"). Correct on reflection: old code already
  routes to `/tmp`, so the unset (TC-2) and empty (TC-3) fallbacks were already
  green. TC-TMPDIR-3 is a guard on the **new** impl's `length`-check (it would
  fail if the new code used `// '/tmp'` instead of the length test), not a red
  against old code. Kept as the load-bearing empty-string assertion.

### Step 2 — Core implementation (green)
- `security-review-changeset` `$scratch` (`:261`) → honour-`$TMPDIR` mirror:
  `my $base = (defined $ENV{TMPDIR} && length $ENV{TMPDIR}) ? $ENV{TMPDIR} : '/tmp';
  $base =~ s{/+$}{}; my $scratch = "$base/${dashed}-task-${task_num}";`. The
  `unless -d / mkdir 0700 / exit 1` block + 0600 write left intact.
- Doc-comment path literals updated to `${TMPDIR:-/tmp}/…` at the top `#` comment
  and the `usage()` heredoc.
- **Deviation / lesson**: the `usage()` block is an **interpolating** heredoc
  (it carries `$PROG`), so a literal `${TMPDIR:-/tmp}` was parsed by Perl as a
  variable deref → compile error → 44/45 tests failed. Fixed by escaping the
  `$` (`\${TMPDIR:-/tmp}`), matching the file's existing `\$` escapes (e.g.
  `/^\\d+…\$/`). The top `#`-comment needed no escape. Lesson captured below.
- Hash refresh (same commit): `sha256sum` → `b5662d45…8cb5ad`; updated the
  `security-review-changeset` entry in `.cwf/security/script-hashes.json`.
  Pre-refresh check: the file's last commits (194/182/174) were clean at the
  e-checkpoint, so the working-tree edit is the sole divergence. Working perms
  already `0500` (= recorded ceiling; no clamp needed). `cwf-manage validate`: **OK**.
- Green: full `t/security-review-changeset.t` → 45/45 pass.

### Step 3 — Convention doc (`tmp-paths.md`)
Canonical form, derivation snippet (with `base="${base%/}"` strip), worked
examples, threat-model note (per-user `/tmp/claude` base), and the namespacing
"Why" updated to the `${TMPDIR:-/tmp}` form; added a **Sandbox alignment**
subsection (honour `$TMPDIR`; sandbox sets `TMPDIR=/tmp/claude`; single-user-trust
caveat; Task-199 ref + Task-178 distinction).

### Step 4 — Cross-surface guidance (in-session, NOT committed — user-global)
Updated example scratch paths to the `${TMPDIR:-/tmp}` form in:
- `memory/feedback_no_heredocs.md`
- `memory/feedback_no_tee_permissions.md`
- `memory/MEMORY.md` (squash-commit example)

These live outside the repo and cannot ride this task's commit — recorded here as
a cross-surface dependency. `tmp-paths.md` remains the SSOT; the memories point at
it. (No standalone `tmp-paths` memory file exists.)

### Step 5 — Validation
- `prove t/security-review-changeset.t`: 45/45 pass.
- Full suite `prove -j4 t/`: **63 files, 762 tests, all pass** (no regression).
- `cwf-manage validate`: **OK** (hash refreshed same commit).
- AC3 grep gate: `security-review-changeset` has zero bare-`/tmp/` literals (all
  `${TMPDIR:-/tmp}`); remaining `/tmp/` in `tmp-paths.md` are explanatory
  (`/tmp/claude` resolution), rejected-alternative illustrations, or carve-outs.
  `template-copier --destination=/tmp/test` is the documented illustrative carve-out.
- Output smoke: TC-TMPDIR-1 is the artefact-level proof — with `$TMPDIR` set, the
  helper's real `.out` lands under it. Passes.

### FR4 class-(c) disposition (pending D2)
`cwf-apply-artefacts:647-648` and `cwf-manage:490` (`File::Temp`/`tempdir`, no
`DIR`) honour `$TMPDIR` natively → **disposition (ii)** *iff* the sandbox sets
`TMPDIR=/tmp/claude`. That pivot fact (D2) is **BLOCKED-ENV** in this unsandboxed
dev session; finalised in g-testing-exec. If falsified → raise a class-(c)
BACKLOG follow-up (do not silently defer).

## Deviations Summary
1. TC-TMPDIR-2/3 green (not red) against old code — expected on reflection;
   TC-3 guards the new length-check. No plan change needed.
2. Interpolating-heredoc bug on the `usage()` comment edit — fixed by escaping
   `\${`. Lesson below.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: FR7/D2 sandbox checks are BLOCKED-ENV (unsandboxed dev session) — recorded, not waived.

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
- A literal `${VAR:-default}` placed in a Perl **interpolating** heredoc/string is
  parsed as a deref and breaks compilation — escape the `$` (`\${…}`) in usage
  text, or keep such shell-syntax examples in non-interpolating `#` comments.
- Editing a hash-tracked file: the suite's own `TC-VALIDATE` subtest catches a
  missing hash refresh immediately — the refresh is part of "green", not a
  separate chore.

## Security Review

**State**: no findings

## Security review — Task 199 implementation-exec changeset

The substantive code change is a single, well-contained one: the per-task scratch base in `security-review-changeset` moves from a hardcoded `/tmp` to `${TMPDIR:-/tmp}`, mirrored in the `tmp-paths.md` convention, with a same-commit hash refresh and three new tests. The rest of the diff is task-planning markdown (a–j wf files) and a test addition. I focused on the executable surface.

**(a) Bash injection / unsafe command construction.** No new shell invocation is introduced. The `$base`/`$scratch` construction flows only into Perl built-ins (`mkdir`, and `atomic_write_text` which uses a same-dir temp + rename). There is no `system($string)` or backtick interpolation of `$base`, `$scratch`, or `$out`. No injection surface added.

**(b) Perl/git output handling.** No new git-porcelain parsing. `$dashed` derives from `find_git_root()` (unchanged). Nothing regresses the `-z`/NUL conventions.

**(c) Prompt injection.** Not applicable — no new `{arguments}` or untrusted-string flow into LLM context.

**(d) Unsafe environment-variable handling — the central category.** `$TMPDIR` is used verbatim (no `rel2abs`/`..` rejection), accepted under the single-user threat model (`$TMPDIR` harness-set, not attacker-set) and explicitly documented (c-design D1 + `tmp-paths.md` § "Sandbox alignment"). Containment preserved: `mkdir($scratch, 0700)` guard intact; fail-closed on a foreign-owned dir is the 0600 `atomic_write_text` write failing (`warn` + `exit 1`); the same-dir temp + `rename` replaces a planted symlink rather than writing through it. Empty-string defence (`defined && length` → `/tmp`, not root-collapse) is correct and asserted by TC-TMPDIR-3 (`unlike ^/-`). No new off-sandbox exposure.

**(e) Pattern-based risk.** The verbatim-`$TMPDIR` idiom is safe here because the threat model is single-user and the guarded `mkdir 0700` + 0600 atomic-rename write is the containment boundary; audit future uses where the single-user invariant might not hold (multi-user host, or feeding the resolved path to `chmod`/`rm`/`unlink`). The new `tmp-paths.md` § "Sandbox alignment" caveat already encodes this; recorded so the audit-trail names the invariant. Class-(c) sites correctly left unchanged (honour `$TMPDIR` natively; disposition deferred to BLOCKED-ENV D2).

**Verdict.** No actionable defect.

```cwf-review
state: no findings
summary: $TMPDIR-in-path change is guarded (mkdir 0700 + 0600 atomic rename), empty-string fallback tested, verbatim-$TMPDIR documented as single-user-only — a pattern-risk caveat, not a defect.
```
