# backlog validate minimum structural contract - Implementation Execution
**Task**: 190 (feature)

## Task Reference
- **Task ID**: internal-190
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/190-backlog-validate-minimum-structural-contract
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

All five planned steps executed. See per-step actual results below.

## Actual Results

### Step 1: Predicate in `CWF::Backlog` (BACKLOG-000)
- **Planned**: Add `backlog_structure_errors($tree,$path)`, export it, call from `validate_backlog_tree`; intro-region scan via `_file_lines_and_fence`; POD note.
- **Actual**: Added `backlog_structure_errors` (`Backlog.pm`) exactly per the d-plan snippet — `$hi` = `entries[0]{header_lineno}-2` or `$#$lines` when no entries; `$first` = first non-blank/non-fenced index; H1 exemption `/^#[ \t]/`; heading `/^#{1,6}[ \t]/` and list `/^[ \t]*([-*+]|\d+[.)])[ \t]/` classifiers; static message naming kind + 1-based line + the `cwf-backlog-manager.md` reference, no verbatim echo. Exported after `validate_changelog_tree`. `validate_backlog_tree` appends its result under a documenting comment (the doc block serves as the POD note).
- **Deviations**: None.

### Step 2: Mutation gate in `backlog-manager`
- **Planned**: Import the predicate; add `assert_backlog_structure`; gate `cmd_add`/`cmd_modify`/`cmd_delete`/`cmd_retire` between parse and write; retire gated before CHANGELOG bootstrap.
- **Actual**: Imported `backlog_structure_errors`; added `assert_backlog_structure($tree,$path)` (dies via `die_user` on the first error). Gate inserted in all four subcommands: `cmd_add` after parse (before `add_entry`), `cmd_modify`/`cmd_delete` after parse (before mutate), `cmd_retire` immediately after the BACKLOG parse and **before** the CHANGELOG parse/bootstrap — so a refusal writes neither file. Fifth touchpoint (`_normalise_one` → `validate_backlog_tree`) verified silent on heading-bearing legacy via TC-15; no code change there.
- **Deviations**: None.

### Step 3: Hash + perms refresh (same commit)
- **Planned**: Restore perms (`Backlog.pm` 0600, `backlog-manager` 0500); refresh both sha256 entries after per-file `git log` verification; `cwf-manage validate` clean.
- **Actual**: On-disk perms already at recorded (600 / 500 — Edit tool restored). Verified **no pre-existing drift**: recorded sha256 for both files matched their `HEAD` versions exactly before editing (so this is the legitimate same-commit refresh case, not absorbing unreviewed drift). Refreshed both `sha256` entries in `.cwf/security/script-hashes.json`. `cwf-manage validate` → `OK`.
- **Deviations**: None.

### Step 4: Tests + docs
- **Planned**: Unit cases in `t/backlog-tree-validate.t`; mutation-gate + two-file-retire + 5th-touchpoint cases in `t/backlog-manager.t`; unterminated-fence boundary pin; AC4 corpus check; update `cwf-backlog-manager.md`.
- **Actual**: Added TC-1…TC-10 (unit, BACKLOG-000) and TC-11…TC-15 (integration gate). All pass. `prove -lr t/` → 724 tests; the two failing suites (`cwf-manage-fix-security.t` 1,9-10; `security-review-changeset.t` 35) fail **identically on clean HEAD** (709 tests, same failures) — environment-specific working-tree-perm fixtures, not a Task-190 regression. Net: +15 tests, all green, zero new failures. Doc updated: `cwf-backlog-manager.md` gained a "Structural contract (`BACKLOG-000`)" section (the target of the error message's reference), describing the preamble rule, the mutation refusal, and the accepted boundaries.
- **Deviations**: TC-8 implemented as a zero-entry file whose only heading is inside a closed fence (genuinely exercises the intro-range fence skip), rather than a `## Task:`-bearing file whose body fence is never scanned anyway — strictly stronger coverage of the same branch.

### Step 5: Validation
- **Planned**: All ACs demonstrated; output-level smoke (foreign → fails, empty → clean).
- **Actual**: The integration tests drive the real `backlog-manager` binary against foreign (refuse, byte-unchanged) and conformant (succeed) temp files — the output-level smoke test. AC1–AC8 mapped via TC-1…TC-15 (see e-testing-plan).

## Blockers Encountered

None. The full-suite failures observed mid-flow were traced to a same-commit sha256 drift (expected, from editing two hash-tracked files) plus two pre-existing environment-specific failures confirmed present on clean HEAD.

## Deferral Check
Before marking status=Finished, verify:
- [ ] All steps from d-implementation-plan.md executed
- [ ] All success criteria from a-task-plan.md met
- [ ] All requirements from b-requirements-plan.md addressed (if applicable)
- [ ] All design guidance in c-design-plan.md followed (if applicable)
- [ ] No planned work deferred without user approval
- [ ] If work deferred: Follow-up task created and linked

**If deferral required**: Get user approval, document rationale, create follow-up task.

## Security Review

**State**: no findings

## Security review

**Changeset scope.** The diff comprises: a new pure predicate `backlog_structure_errors` in `CWF::Backlog`, a mutation gate `assert_backlog_structure` plus four call sites in `backlog-manager`, a hash-manifest refresh, test additions, a doc update, and the standard a-e workflow guide files.

**(a) Arbitrary code/command execution.** The predicate is pure Perl operating over an already-parsed in-memory tree. No `system`, `exec`, backticks, `qx`, `eval` of strings, or `open` with a pipe are introduced. The regexes are static literals — no user-supplied content is interpolated into a pattern, so there is no regex-injection or code-in-pattern vector. The mutation gate `die_user`s before any write. No findings.

**(b) Path traversal / unsafe file writes.** The new code performs no I/O. `backlog_structure_errors` reads `$tree->{entries}` and the cached line/fence arrays via `_file_lines_and_fence($tree)` — no filesystem access. The mutation gate only *prevents* writes (it `die`s before `write_tree`); it never opens or writes a path itself. `$path` is used solely as a label in the error record, never to open anything. The `retire` symlink refusal is untouched and the gate is correctly placed after it. No findings.

**(c) Prompt-injection / untrusted-content interpolation.** Most relevant category, since `BACKLOG.md` is attacker-influenceable data and the error message flows into operator/LLM context. The message interpolates exactly two non-static values: `$kind` (a fixed enum — only `'heading'`/`'list item'`) and an integer line number. The offending line text `$l` is *never* interpolated. The design's "no verbatim echo" claim holds, asserted by TC-7. No findings.

**(d) Secrets/credential exposure.** None. The hash-manifest change is two sha256 refreshes (expected, same-commit hash-update convention). No findings.

**(e) Unsafe handling of environment variables or external input.** No `$ENV` access, no new argument parsing. Pattern note (not a finding): `backlog_structure_errors` is now `@EXPORT_OK` for future `CHANGELOG.md` reuse (KD5); safe here because no file content is interpolated — but any future edit that cites verbatim line text would reopen the FR4(c) surface and must apply NFR2 control-char-stripping/length-bounding.

**Other observations (non-security).** Accepted-boundary limitations are coverage gaps in a *defensive* check (fail-open on edge cases grants no new capability), documented and pinned by TC-9. Tests write to `File::Temp` dirs, never repo files. No weakening of existing `GLOBAL-*` checks.

The diff is clean across all five threat categories.

```cwf-review
state: no findings
summary: Pure read-only predicate + mutation gate; no exec/IO/secrets, error message interpolates only fixed-enum kind + line number (no verbatim file content). One pattern note recorded for future reuse, not actionable here.
```

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
