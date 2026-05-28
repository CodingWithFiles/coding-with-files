# install manifest baselines disagree with subtree - Testing Plan
**Task**: 167 (bugfix)

## Task Reference
- **Task ID**: internal-167
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/167-install-manifest-baselines-disagree-with-subtree
- **Template Version**: 2.1

## Goal
Bind every c-design §Validation bullet and a-plan §Success Criterion to a concrete test case, identify which existing subtests already cover each invariant, and define the verification ordering so f-implementation-exec can mechanically execute.

## Test Strategy

### Test Levels

- **Tier A (new pure-Perl test)** — `t/installmanifest-integrity.t`. Loads the real shipped `.cwf/install-manifest.json` and asserts (i) sanity floor (≥1 artefact), (ii) INV-1 source-SHA agreement, (iii) INV-2 anti-recurrence schema rule. Pure file-system reads + sha256_hex. No fixtures, no tempdir, no chdir.
- **Tier B (existing-test regression)** — every test file that references `rules-inject` must remain green after the cleanup. One assertion update required (`t/cwf-apply-artefacts.t:186-187`); all other subtests unchanged.
- **Tier C (build-time hygiene)** — `cwf-manage validate` clean post-edit; `git grep` confirms no stray `rules-inject` references in non-test code beyond the deliberate residual (SKILL.md hook command + the file itself).

### Test Coverage Targets

- **Every a-plan §Success Criterion (AC1-AC5) → bound to at least one TC** (mapping below).
- **Every c-design §Validation bullet → bound to at least one TC** (mapping below).
- **All existing subtests in the four `rules-inject`-touching test files remain green** — this is the regression floor.
- **Full `prove -r t/` green** — sibling-test regression sweep.
- **No subtest skips, no `xfail`, no `TODO` markers**.

## Test Cases

### Mapping: ACs and Validation bullets → concrete subtests

| AC / Validation bullet | TC ID | Subtest location |
|---|---|---|
| **AC1**: every manifest artefact has `sha256` matching its `source` file | TC-INV1 | **NEW** `t/installmanifest-integrity.t — INV-1 source agreement` |
| **AC2**: regression check makes drift visible at dev time | TC-INV1 + TC-INV2 + TC-SANITY | `t/installmanifest-integrity.t` (all three subtests collectively form the regression check) |
| **AC3**: non-interactive `cwf-manage update` no longer aborts on `rules-inject` conflict | TC-INV2 (schema rule) + TC-EXISTING-E2E | INV-2 catches the recurrence at the manifest level; the existing `t/cwf-manage-update-end-to-end.t` confirms cwf-manage update succeeds against the post-fix manifest. See §Reproducer Scope below for rationale. |
| **AC4**: `cwf-manage validate` clean post-fix; hash refresh in same commit | TC-VALIDATE | Step 9 of d-implementation-plan executes `cwf-manage validate` — must report `[CWF] validate: OK` |
| **AC5**: shipped `rules-inject.txt` content survives the update (file populated post-fix) | TC-EXISTING-SUBTREE | Pre-existing `t/install-bash-reinstall.t:174` — `ok(-s "$consumer/.cwf/rules-inject.txt", '.cwf/rules-inject.txt non-empty after reinstall')` |
| **c-Validation: D1 applied** (no `rules-inject` entry in manifest) | TC-INV2 + TC-NO-STRAY | INV-2 trivially satisfied = entry gone; `git grep` (Step 10) confirms no stray references |
| **c-Validation: D2 applied** (14 cleanups) | TC-NO-STRAY + Tier B | `git grep` covers code-path references; Tier B regression covers behavioural correctness |
| **c-Validation: D3 applied** (test exists and passes) | Existence: `prove -v t/installmanifest-integrity.t` | The test file itself exists at the canonical path and runs green |
| **c-Validation: D4 honoured** (strategy machinery + TC-RI-1..5 intact) | TC-RI-PRESERVED | `prove -v t/cwf-apply-artefacts.t` green; TC-RI-1 regex updated per Refinement 1 |
| **c-Validation: D5 satisfied** (single commit) | Manual review of `git show <commit>` | f-exec checkpoint commit contains all D1+D2+D3 + hash refreshes |
| **c-Validation: `cwf-manage validate` clean** | TC-VALIDATE | as above |
| **c-Validation: `prove -r t/` green** | TC-FULL-SWEEP | Step 10 of d-plan |
| **c-Validation: Reproducer** | See §Reproducer Scope | — |

### Functional Test Cases (new Tier-A subtests)

**TC-SANITY: manifest has at least one artefact**
- **Given**: `.cwf/install-manifest.json` parsed.
- **When**: `scalar @{ $manifest->{artefacts} }`.
- **Then**: `cmp_ok($n, '>=', 1, ...)`. Catches the "future commit empties the array" case so INV-2 doesn't silently pass on a vacuous loop.

**TC-INV1: source-SHA agreement (per artefact)**
- **Given**: A parsed manifest with at least one artefact.
- **When**: Iterate artefacts. For each one with a `source` and `sha256`, compute `sha256_hex(slurp_raw("$REPO/$source"))`. For `kind: tree`, iterate `files{*}` similarly.
- **Then**: Computed SHA equals recorded `sha256`. One assertion per artefact entry. Test name embeds the artefact `id` for diagnosis on failure.
- **Expected pass-count on HEAD post-fix**: 3 entries asserted (claude-md-preamble + cwf-rules-bundle/cwf-workflow-files.md + nothing else). `gitignore-entries` and `claude-rules-symlinks` skipped (no source SHA to check).

**TC-INV2: anti-recurrence schema rule**
- **Given**: A parsed manifest.
- **When**: Iterate artefacts. For each one with a `dest` or `container` field, check the prefix.
- **Then**: `unlike($dest_or_container, qr{\A\.cwf/}, "$id: target must not be under .cwf/")`.
- **Pre-fix expected**: FAIL on the `rules-inject` entry (dest `.cwf/rules-inject.txt`) — this is the proof the test catches the historical defect.
- **Post-fix expected**: PASS on all current artefacts (dest is `.gitignore`, `.cwf-rules/`, `.claude/rules/`; container is `CLAUDE.md` — none under `.cwf/`).

### Functional Test Cases (regression, Tier-B)

**TC-RI-1 (updated assertion)**: `t/cwf-apply-artefacts.t:186-187`
- **Given/When/Then**: unchanged; the synthetic fixture in this subtest builds its own `rules-inject` manifest entry and exercises `apply_replace`. **Only the log-format regex changes** — from `qr{rules-inject\.txt updated \(was , now }` to `qr{rules-inject: installed \.cwf/rules-inject\.txt}`.

**TC-RI-2..5 + TC-FR5-***: `t/cwf-apply-artefacts.t:190-310`
- **Status**: Unchanged. Each subtest constructs its own synthetic manifest + helper invocation. Removal of the real manifest's `rules-inject` entry does not affect these.

**TC-CMU-***: `t/cwf-manage-update.t` (every subtest)
- **Status**: Unchanged. Subtests use synthetic manifests at lines 88-95.

**TC-E2E-***: `t/cwf-manage-update-end-to-end.t` (every subtest)
- **Status**: Unchanged. `build_upstream` (line 94) copies `$REPO_ROOT/.cwf/` into a tempdir; after our fix the copied manifest no longer has `rules-inject`, so `apply-artefacts` cleanly skips it.
- **Side benefit**: the `CWF_UPGRADE_RESOLVE=new` workaround at line 150 is no longer load-bearing for `rules-inject` (still load-bearing for CLAUDE.md preamble if a synthetic test ever drifts it — leave the env var in place).

**TC-IBR-***: `t/install-bash-reinstall.t`
- **Status**: Unchanged. Specifically TC-IBR-1's assertion at line 174 (`ok(-s ".cwf/rules-inject.txt")`) continues to pass — install.bash's subtree-add still lays down the populated 331-byte file.

### Non-Functional Test Cases

- **Performance**: Not benchmarked. The new test reads JSON + hashes ≤3 small files. `prove -v t/installmanifest-integrity.t` should complete in < 1s on a developer laptop. No degradation against any baseline measurable.
- **Security**: Inherits from c-design §Constraints (allowlist tightening in `Validate/Security.pm`, hash refresh per `[[hash-updates]]`). The plan-review security subagent on d-plan returned `no findings`. INV-1 adds an independent SHA-tamper-detection check (verifier/producer diversity per [[feedback-complexity-over-continuity]]). Will be re-verified post-implementation by the f-phase security-review subagent on the resulting changeset.
- **Usability**: No user-facing surface changes. `cwf-manage update` now succeeds where it previously aborted; the absence of the abort prompt is the only user-visible delta.
- **Reliability**: D3 anti-recurrence rule means any future change that re-introduces a `kind: file` dest under `.cwf/` (or equivalent for tree/embedded-block) fails the test suite. Catches drift at PR review, not at consumer-update time.

## Reproducer Scope Decision

The a-plan AC3 specifies "a `cwf-manage update` invocation from v1.1.155 to the post-fix tip, with `CWF_UPGRADE_RESOLVE` unset and no TTY, completes without an apply-artefacts rules-inject conflict prompt." A literal end-to-end reproducer would:

1. Synthesise a v1.1.155-style upstream (with the buggy `install-manifest.json` containing the `rules-inject` entry).
2. Install consumer from it via `install.bash`.
3. Mutate the upstream to the post-fix manifest.
4. Run `cwf-manage update` without `CWF_UPGRADE_RESOLVE` set.
5. Assert exit 0, `.cwf/rules-inject.txt` populated.

**Decision**: do NOT write this as a new TC. Rationale:
- INV-2 catches the recurrence at the schema level (where the defect actually lives — a misclassified manifest entry).
- `t/install-bash-reinstall.t:174` guards "subtree-add still lays the populated file" (the AC5 invariant).
- `t/cwf-manage-update-end-to-end.t` exercises the full update pipeline against a post-fix manifest copied from `$REPO_ROOT/.cwf` — once the fix lands, every subtest in that file runs through the same code path the consumer hit, and demonstrates it succeeds.
- The existing `build_upstream` (`t/cwf-manage-update-end-to-end.t:94`) copies the *current* repo's `.cwf/` — it cannot synthesise a v1.1.155-style upstream without git-historical fixtures or an in-test manifest patch. The plumbing is ~60 lines of new code to reproduce one specific historical state.

The combination of (INV-2 + existing apply-artefacts unit tests + existing e2e tests + existing install-bash-reinstall guard) covers the AC transitively. **Filed as a candidate for future enhancement** (Low priority — a "historical bug reproducer" TC) if developer experience later warrants it; not gating this task.

## Test Environment

### Setup Requirements

- **Perl ≥ 5.16** (matches existing `t/` floor; no new floor introduced).
- **Core modules only**: `Test::More`, `Digest::SHA`, `JSON::PP`, `FindBin`, `File::Spec`. All already used by `t/cwf-claude-settings-merge.t` and `t/cwf-apply-artefacts.t`. **No CPAN deps** ([[feedback-perl-core-only]]).
- **POSIX filesystem** with `open '<:raw'` semantics. macOS and Linux verified parity throughout the existing suite.

### Test Isolation Discipline

`t/installmanifest-integrity.t` runs against the **real shipped manifest** in the repo — no tempdir, no chdir, no fixtures. The test is a read-only assertion over committed files. Discipline:
- Resolve repo root via `File::Spec->rel2abs("$FindBin::Bin/..")` once at the top of the file.
- Use `slurp_raw` with `'<:raw'` mode for the manifest and every source file (Refinement 5).
- Never modify any file inside the test.

### Automation

- Test framework: `Test::More` via `prove`.
- Execution sequence (also the f-implementation-exec verification gate):
  1. `prove -v t/installmanifest-integrity.t` — focused, MUST be green post-fix; MUST FAIL on HEAD pre-fix (the test-first verification in Step 3 of d-plan).
  2. `prove -v t/cwf-apply-artefacts.t` — green (TC-RI-1 assertion updated).
  3. `prove -v t/cwf-manage-update.t t/cwf-manage-update-end-to-end.t t/install-bash-reinstall.t` — green.
  4. `prove -r t/` — full sweep green.
  5. `cwf-manage validate` — `[CWF] validate: OK`.
- No CI changes required (existing `prove -r t/` invocation suffices).

## Validation Criteria

- [ ] Every §Mapping row has a passing subtest (existing or new).
- [ ] `prove -v t/installmanifest-integrity.t` PASS post-fix; FAIL pre-fix (captured to `/tmp/-home-matt-repo-coding-with-files-task-167/test-fail-pre-fix.txt` per d-plan Step 3).
- [ ] `prove -v t/cwf-apply-artefacts.t` PASS (TC-RI-1..5 + TC-FR5-* all green).
- [ ] `prove -v t/cwf-manage-update.t t/cwf-manage-update-end-to-end.t t/install-bash-reinstall.t` PASS.
- [ ] `prove -r t/` PASS (full sweep; no sibling-test regressions).
- [ ] `cwf-manage validate` clean.
- [ ] `git grep -nE 'rules-inject' -- ':!t/' ':!implementation-guide/' ':!CHANGELOG.md' ':!BACKLOG.md'` — returns only legitimate residuals (SKILL.md line 116 hook command + the file `.cwf/rules-inject.txt` itself; possibly Task 99/158 retrospective docs).

## Decomposition Check
- [x] **Time**: bounded by 3 new subtests + 1 assertion update + grep validation; well under 0.5 day → no.
- [x] **People**: solo → no.
- [x] **Complexity**: one test file + one assertion update → no.
- [x] **Risk**: tests *are* the risk-mitigation; they have no separable risk → no.
- [x] **Independence**: tests land with the implementation in one commit per d-plan D5 → no.

**Verdict**: 0/5. No subtasks.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 167
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
