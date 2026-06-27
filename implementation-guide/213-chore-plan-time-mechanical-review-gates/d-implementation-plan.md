# Plan-time mechanical review gates - Implementation Plan
**Task**: 213 (chore)

## Task Reference
- **Task ID**: internal-213
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/213-plan-time-mechanical-review-gates
- **Template Version**: 2.1

## Goal
Add one deterministic Perl helper to the plan-review pipeline that scans a plan file and
surfaces two defect classes — broken referenced helper/script paths and declared symbol
deletions with live remaining references — as findings the REDUCE step folds in.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Resolved Decisions (from a-plan Open Decisions)
- **OD1 — one helper, two checks.** Both scans read the same plan file in one pass and write one findings file. Mirrors `best-practice-resolve`.
- **OD2 — pre-MAP deterministic resolver.** New helper runs at `plan-review.md` Step 0 alongside `best-practice-resolve` (a sibling resolver, *not* a reviewer-agent edit). Findings are consumed in REDUCE. Rationale: determinism + testability + "agents skip optional work" — a helper is mandatory and unit-testable; an agent body is neither. Reuses an established pattern (Rule of Three: `best-practice-resolve`, `security-review-changeset`).
- **OD3 — deletion intent via a declared convention, not a heuristic.** The helper reads a `- **Deletes**: name1, name2` line from the plan file (mirrors the existing `- **Tags**:` convention `best-practice-resolve` already parses). Human declares *intent*; the machine does the exhaustive repo-wide sweep the human forgot (the Task-174 failure mode). No `**Deletes**` line ⇒ the symbol check is a clean no-op.

## Design Detail
**Helper**: `.cwf/scripts/command-helpers/plan-mechanical-check` (Perl, 0500, hash-tracked).
**Contract** (mirrors `best-practice-resolve`):
- Invocation: `plan-mechanical-check --task-num=NUM --plan-type=TYPE` where `TYPE ∈ {requirements, design, implementation}`. Resolution is two-step (robustness F3): `CWF::TaskPath::resolve_num(NUM)->{full_path}` returns the task **directory**; the helper then joins the plan-type→filename map `{requirements→b-requirements-plan.md, design→c-design-plan.md, implementation→d-implementation-plan.md}`. (Self-resolving; no caller-supplied path → no path-injection surface.)
  - Task dir unresolvable (bad/unknown `--task-num`) ⇒ **exit 1** (resolution failure).
  - Task dir resolves but the specific plan file is absent (phase not reached yet) ⇒ **exit 0, 0 findings** (normal, fail-open).
- Output file: `<scratch>/task-<num>/plan-mechanical-check-<plan-type>.out` via `CWF::Common::scratch_dir`. Reuse the shared tmp-paths guard — do **not** copy `best-practice-resolve`'s private `scratch_out_path`. Note `scratch_dir` returns a `($path, $kind)` tuple (robustness note) — handle the error kind, don't assume a scalar.
- stdout: exactly one confirmation line — `plan-mechanical-check: wrote <N> findings to <abs-path>`.
- Exit: `0` ok (incl. N=0); `1` resolution failure (bad args, invalid `--task-num`, unresolvable root, scratch/write failure). Scan-internal errors are **fail-open** (degrade to "no finding for that item", never abort) per C5.

**Git capture (shared by both scans — supersedes the a-plan's `run_quiet` assumption).** `CWF::Common::run_quiet` redirects child stdout to `/dev/null` and returns only the exit code (`Common.pm:148`) — it **cannot** capture grep/ls-files output. Use the list-form streaming reader `open(my $fh,'-|','git',@args)` mirroring `security-review-changeset:351`, but **do not** copy that helper's `capture_git` wrapper verbatim: it treats any non-zero exit as fatal, which is wrong for `git grep` (see below). Apply the git-path-output convention: `-z` + `split /\0/` (filenames may contain newlines, FR4(b)).

**Path check** (generalised beyond `.cwf/scripts/`, C3):
1. Extract referenced path tokens: backtick-quoted tokens containing `/` with a repo-relative-path shape. **Reject** tokens that are URLs (`://`), pathspecs/globs (leading `:` or `*`), regexes (contain `^`/`$`), or contain a space (robustness F4) — these are not filesystem paths and would yield spurious advisories.
2. Enumerate tracked files once via `git ls-files -z` (capture, NUL-split) to build a basename index.
3. For each token that does **not** resolve against the main root (`find_git_root` + token), classify:
   - **High-signal** — a file with the same *basename* exists in the index: "referenced `<path>` missing; basename found at `<alt>` — likely wrong path." (The exact Task-150 case: `.cwf/scripts/command-helpers/cwf-manage` missing, `.cwf/scripts/cwf-manage` present.)
   - **Advisory** — no basename match: "referenced `<path>` does not exist — confirm it is a new file this task creates, not a typo." (Plans legitimately name files they will create; this is why the check surfaces, never blocks.)

**Symbol check** (language-neutral, opaque-string, C2):
1. Read `- **Deletes**: sym1, sym2` from the plan file (comma-split, trim).
2. For each symbol, capture `git grep -n -w -F -e <sym> -- ':!implementation-guide/<dir>'` repo-wide (security F1: `-e` pins the pattern and `--` terminates options, so a symbol starting with `-` cannot be read as an option; the pathspec excludes the task's **own** dir only, so the `**Deletes**` line and plan prose do not self-match — robustness F5).
3. **Exit-code handling** (robustness F2 — this is the critical correctness point): `git grep` returns **exit 1 on zero matches** (success — safe to delete), exit 0 on match, exit ≥2 on real error. Treat exit 1 as "zero references" (no finding); fail-open (no finding for that symbol) on exit ≥2 — never `die`.
4. Report each symbol with ≥1 remaining reference as a finding listing files + line counts. Zero references ⇒ no finding (the Task-174 fix: it would have listed `t/cwf-check-tree-symlinks.t` and `t/install-bash-reinstall.t`).
5. Word-boundary (`-w`) match bounds substring noise (R1); findings are for reviewer adjudication, not a block.

## Files to Modify
### Primary Changes
- `.cwf/scripts/command-helpers/plan-mechanical-check` - **NEW** Perl helper (above contract). Core-only (`CWF::Common`, `CWF::TaskPath`, `CWF::ArtefactHelpers::atomic_write_text`).
- `.cwf/docs/skills/plan-review.md` - retitle Step 0 to "Pre-MAP resolvers" covering **both** deterministic helpers (`best-practice-resolve` and `plan-mechanical-check`) rather than appending a "Step 0b" (misalignment 1), and add a REDUCE bullet folding the mechanical-check findings file in. Document the grep-precision tradeoff (net-not-proof, C5/R1) inline here.

### Supporting Changes
- `.cwf/security/script-hashes.json` - add `plan-mechanical-check` entry (path, `0500`, sha256) in the **same commit** as the helper (hash-updates convention).
- `.claude/settings.json` - add `Bash(.cwf/scripts/command-helpers/plan-mechanical-check:*)` allowlist entry (sibling to the other command-helpers; dev-repo prompt-avoidance).
- `.cwf/templates/pool/d-implementation-plan.md.template` - add an optional `**Deletes**:` hint near "Files to Modify" so planners declare deletions (supports OD3). Templates are **not** hash-tracked (verified) — no hash refresh.
- `t/plan-mechanical-check.t` - **NEW** test file (see Test Coverage).

## Implementation Steps
### Step 1: Setup & patterns
- [ ] Re-read `best-practice-resolve` (contract/arg-parse) for shape; use `CWF::Common::scratch_dir` directly — do **not** copy its private `scratch_out_path`. Confirm the `scratch_dir` return tuple `($path,$kind)`.
- [ ] Read `security-review-changeset`'s `open '-|'` git-capture (line ~351) as the capture pattern; note its `capture_git` dies on non-zero exit and must **not** be reused as-is for `git grep` (exit 1 = no match).
- [ ] Confirm `CWF::TaskPath::resolve_num` returns `{full_path}` (the task **directory**) for a top-level chore task; the plan-type→filename join happens in this helper.

### Step 2: Tests first (TDD, red)
- [ ] Write `t/plan-mechanical-check.t` with `File::Temp` fixtures reproducing Task-150 and Task-174 (TC list below). Run — expect red (helper absent).

### Step 3: Core implementation (green)
- [ ] CLI parse + validate `--task-num` (`/^\d+(?:\.\d+)*$/`) and `--plan-type` (allowlist) — copy `best-practice-resolve`'s guards.
- [ ] Resolve task dir via `resolve_num` (unresolvable ⇒ exit 1); join plan-type→filename; specific plan file absent ⇒ exit 0 / 0 findings.
- [ ] Add a small list-form git-capture sub (`open '-|'`, `-z`/NUL split) with **per-call exit-code policy** (path check: ls-files exit 0 expected; symbol check: exit 1 = no-match = success, exit ≥2 = fail-open).
- [ ] Path check: extract tokens (apply the URL/glob/regex/space rejection set) → build basename index from `git ls-files -z` → classify high-signal vs advisory.
- [ ] Symbol check: read `**Deletes**` → `git grep -n -w -F -e <sym> -- ':!implementation-guide/<dir>'` → tally files/line-counts.
- [ ] Render findings file + single stdout confirmation line; `atomic_write_text` mode 0600.

### Step 4: Wire into pipeline
- [ ] Edit `.cwf/docs/skills/plan-review.md` (Step 0b + REDUCE bullet + tradeoff note).
- [ ] Add `.claude/settings.json` allowlist entry.
- [ ] Add `**Deletes**:` hint to the d-plan template.

### Step 5: Integrity & validation
- [ ] `chmod 0500` the helper; add `script-hashes.json` entry (same commit).
- [ ] `prove -lr t/plan-mechanical-check.t` green; full `prove -r t/` green (no regressions).
- [ ] `.cwf/scripts/cwf-manage validate` clean.

## Test Coverage
**See e-testing-plan.md for the complete test plan.** Summary of intended cases:
- TC-1 (Task-150): missing referenced path whose basename exists elsewhere → high-signal finding naming both paths.
- TC-2: referenced path with no basename match → advisory finding (not high-signal).
- TC-3 (Task-174): `**Deletes**: SYM` with refs in 2 fixture files → finding lists both + counts.
- TC-4: `**Deletes**: SYM` with zero refs → no finding (safe).
- TC-5: valid paths + no `**Deletes**` → 0 findings, exit 0, confirmation line correct.
- TC-6: self-match exclusion — the `**Deletes**` line and plan prose do not count as references.
- TC-7: bad args / invalid `--task-num` / unknown `--plan-type` → exit 1; task dir resolves but plan file absent → exit 0, 0 findings.
- TC-8: output path under per-task scratch; confirmation-line format exact.
- TC-9: `**Deletes**: -O` (leading-dash symbol) is searched as a pattern, not parsed as a git option (`-e`/`--` guard) — no crash, correct tally.
- TC-10: path-token rejection — a backtick URL/glob/regex in the plan yields no advisory finding.

## Validation Criteria
**See e-testing-plan.md.** Gate: all TCs pass; full suite green; `cwf-manage validate` clean; helper is `0500` + hash-tracked; no permission prompt on invocation.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

If work must be deferred: get user approval, update success criteria, create a follow-up task, and record it in Actual Results.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 213
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Plan executed as written, with the two plan-review corrections folded in: a custom `capture_git_z` (returning `($stdout, $exit)`) replaced both the capture-incapable `run_quiet` and the die-on-nonzero `capture_git`, and `git grep` exit 1 is treated as zero matches. See `f-implementation-exec.md`.

## Lessons Learned
Read the contract of each reused library helper before drafting the plan — the `run_quiet`/`capture_git` assumptions were avoidable. See `j-retrospective.md`.
