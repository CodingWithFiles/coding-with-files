# classify auto-discover review outputs - Implementation Execution
**Task**: 214 (chore)

## Task Reference
- **Task ID**: internal-214
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/214-classify-auto-discover-outputs
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status to "Finished" when complete

## Actual Results

### Step 1: Helper — refactor parser, add discovery mode
- **Planned**: Extract the block-walk into `classify_text()`; add `--dir`/`--phase` arg parsing; add discovery loop (readdir + single-pass capture + lstat-filter + per-line emit); zero-match + per-file-open-failure warnings; update both the leading comment and `usage()`.
- **Actual**: `.cwf/scripts/command-helpers/security-review-classify`:
  - Header comment Usage/Output/Exit block now documents both modes (incl. the allowlist/no-prompt rationale and the `<DIR>`-is-trusted invariant).
  - `usage()` string rewritten to show both invocation forms.
  - Arg loop replaced with a `while (@ARGV)` parser accepting `--dir`/`--phase` (space and `=` forms), preserving `--help`/`-h` and unknown-arg rejection. `defined($dir) xor defined($phase)` ⇒ exit 1.
  - The block-walk extracted verbatim into `sub classify_text($input) → token` (single parse authority, Task 162 invariant intact). `%VALID` declared file-scoped before the sub.
  - Discovery block: `opendir`; one-pass `map`/`grep`/`sort` building `[reviewer, file]` pairs from `^(.+)-review-output-\Q$phase\E\.out$`, filtered to `-f && ! -l`; per file prints `"$who: ", classify_text(...)`; per-file open failure prints `"$who: error"` + stderr warning; zero matches ⇒ stderr warning. stdin path unchanged (`print classify_text(<STDIN>), "\n"`).
- **Deviations**: None.

### Step 2: Refresh hash
- **Planned**: Update `script-hashes.json`; restore working perms to recorded `0500`.
- **Actual**: `chmod 0500` on the helper; recomputed sha256 with `sha256sum` (producer/verifier implementation diversity) and updated the `security-review-classify` entry in `.cwf/security/script-hashes.json` (`e5a6…8053` → `c009…4c4e`) in this same commit. `cwf-manage validate` ⇒ OK.
- **Deviations**: None. `fix-security` was *not* used to mutate the hash (it only repairs perms when sha256 matches — sha256 is surface-never-smooth); the hash was updated by hand as the legitimate same-commit refresh.

### Step 3: Skills + docs
- **Planned**: Edit the two exec SKILLs and the two `.cwf/docs/skills/*-review.md` snippets.
- **Actual**:
  - `cwf-implementation-exec/SKILL.md` Step 8 "Classify + record": replaced the per-file `< <file>` loop with the single `--dir/--phase implementation-exec` invocation; added the explicit `<reviewer> → ## Heading` map for all five reviewers and the launched-vs-classified cross-check (absent line ⇒ `error`).
  - `cwf-testing-exec/SKILL.md` Step 8: same edit for the 2-reviewer (`security`, `best-practice`) testing-exec set.
  - `security-review.md` Classification §: documents the discovery-mode invocation as primary, keeps the stdin form for the SubagentStop hook / single-file callers, notes one shared parser.
  - `best-practice-review.md` Classification §: same — points at the exec SKILL's single discovery invocation, retains the stdin form for ad-hoc use.
- **Deviations**: None.

### Step 4: Tests
- **Planned**: Extend `t/security-review-classify.t`; run full `t/`.
- **Actual**: Added `writef()`/`discover()` helpers and TC-D1..TC-D6 (happy path/order, phase scoping, zero-match, symlink+subdir skip, open-failure→error, arg errors); imported `tempdir`. `prove t/security-review-classify.t` ⇒ 30/30. Full suite `prove t/` ⇒ **931 tests, all pass**.
- **Deviations**: The four integrity tests (`cwf-manage-fix-security`, `…-update-end-to-end`, `…-update-migrate`, `version-records-commit-sha`) failed on the first full-suite run *before* the hash refresh (expected — they validate repo integrity against a now-stale recorded hash); all green after Step 2.

### Step 5: Validation
- **Planned**: `cwf-manage validate`; empirical no-prompt check.
- **Actual**: `validate: OK`. Smoke-tested discovery happy path (correct lexical order, phase scoping excludes `testing-exec` + `-changeset-` files), stdin regression (`no findings`), zero-match (stderr warning, empty stdout), and arg error (exit 1) — all in this session under the existing allowlist with no permission prompt.

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] b-requirements-plan.md — N/A (chore)
- [x] c-design-plan.md — N/A (chore; design captured in d)
- [x] No planned work deferred
- [x] No follow-up task required

## Changeset Reviews (Step 8)

All five reviewers launched in parallel; classified in **one** discovery-mode invocation
(`security-review-classify --dir <scratch> --phase implementation-exec`) — the feature this
task adds, dogfooded, with no permission prompt. 5 launched → 5 lines (cross-check passes).

The two `findings` (improvements, misalignment) are the **same advisory point**: the new
`--dir`/`--phase` interface diverges from the sibling `security-review-changeset`
(`--wf-step` validated against the canonical step allowlist, scratch dir derived internally
via `CWF::Common::scratch_dir()`). Both reviewers note this is a **deliberate, documented**
choice in d-implementation-plan.md (read-only helper, single literal argv for the allowlist),
not an accidental re-implementation. Surfaced for the user to accept or revisit; recorded,
not blocking. A possible follow-up — a `--task-num` form reusing `scratch_dir()` and a shared
phase/step name — is noted for the retrospective.

### Security Review

**State**: no findings

Worked through FR4(a–e). The only executable change is the helper; no `system`/`qx`/backticks/`exec`, file access via `opendir`/`readdir` + three-arg `open`. No git-output parsing (`readdir`, not porcelain); `\Q$phase\E`-quoted; `use utf8;` present. Reviewer prefix and `$dir` are SKILL-derived, not from `{arguments}`. `-f && ! -l` symlink skip and trusted-`$dir` patterns safe under the 0700 scratch-dir invariant; both documented inline. Hash refreshed same commit. No actionable concerns.

### Best-Practice Review

**State**: no findings

Tag-matched sources (golang, postgres) are language/database-specific; the changeset is Perl + Markdown + JSON with no Go/SQL surface. The tag match is a resolver artefact, not content overlap — no applicable best practice to diverge from. Valid review (both corpora readable), not an error.

### Improvements Review

**State**: findings

Parser reuse is correct (block-walk → shared `classify_text()`, single-parser invariant intact; stdin contract untouched). Advisory: `--dir`/`--phase` forgoes the sibling's existing `scratch_dir()` derivation and canonical wf-step allowlist — both deliberate per plan. No avoidable duplicated code.

### Robustness Review

**State**: no findings

All failure modes surfaced: per-file open failure → `<reviewer>: error` + stderr WARNING (no bare `next`); opendir failure → safe warn + exit 0; SKILL cross-check catches a launched-but-absent line. `-f && ! -l` lstat skip correct; phase scoping robust (`-review-output-` infix excludes the changeset `.out`, `\Q$phase\E` quoted, greedy `(.+)` bounded by fixed suffix). Arg edge cases (=-forms, xor, unknown-flag) handled and test-pinned (TC-D1..D6).

### Misalignment Review

**State**: findings

Good reuse (single parser; `writef`/`discover` test helpers mirror existing `classify()`; `use utf8;` present; `[CWF] WARNING:` matches the file's own style; hash refreshed at 0500). One substantive misalignment (advisory): interface diverges from the matched-pair sibling `security-review-changeset` — `--phase` (unvalidated) vs `--wf-step` (allowlist-validated), caller-supplied `--dir` vs reusing the `scratch_dir()` abstraction. Consciously chosen and documented; the user may accept it.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
Same-commit hash refresh before the full-suite run avoids a transient integrity-test red. The discovery-mode pattern (write per-reviewer `.out`, classify the dir in one call) is smoother than the per-file loop for both the permission surface and the launched-vs-classified cross-check. See j-retrospective.md.
