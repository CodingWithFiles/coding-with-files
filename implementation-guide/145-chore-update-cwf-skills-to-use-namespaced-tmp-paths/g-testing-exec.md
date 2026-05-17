# update cwf skills to use namespaced tmp paths - Testing Execution
**Task**: 145 (chore)

## Task Reference
- **Task ID**: internal-145
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/145-update-cwf-skills-to-use-namespaced-tmp-paths
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps
- [x] Update status to "Finished" when all pass

## Test Results

### Functional Tests

| Test ID | Test Case | Expected | Actual | Status | Notes |
|---------|-----------|----------|--------|--------|-------|
| TC-1 | tmp-paths.md exists with 5 required headings | 5 headings, in order | All 5 found by `grep -E '^## (Convention\|Threat model\|Why\|Out of scope\|See also)'`; file lives at `.cwf/docs/conventions/tmp-paths.md` (ships to adopters via subtree) | PASS | — |
| TC-2 | Canonical form documented unambiguously, no "form A vs B" fallbacks, worked example matches `/tmp/-home-matt-repo-coding-with-files-task-145/` | one canonical form, no alternatives offered, example present | Canonical form `/tmp/<dashified-absolute-repo-path>-task-<num>/` stated exactly once in § Convention; worked example matches verbatim; `A short-form fallback (...) is *not* offered` paragraph explicitly *rejects* the alternative form (the grep hit on "short-form" is the rejection text, not an offer of a second form) | PASS | The single grep hit was the negation paragraph — verified by reading § Why |
| TC-3 | Derivation snippet copy-pasted from doc produces non-colliding paths for two repo roots | both paths valid, differ, no shell metachars | `/tmp/-home-matt-repo-coding-with-files-task-145/derive.sh` invoked with `repo_root=/tmp/repo-a num=145` → `/tmp/-tmp-repo-a-task-145`; with `repo_root=/tmp/repo-b num=145` → `/tmp/-tmp-repo-b-task-145`; paths differ; only path-safe characters | PASS | — |
| TC-4 | `mkdir -m 0700` guard documented | ≥1 match in § Threat model | 3 hits in tmp-paths.md (snippet + threat-model body + invariant explanation); all in § Convention or § Threat model | PASS | — |
| TC-5 | `**Tmp Paths**` bullet present in CLAUDE.md § Conventions, references `.cwf/docs/conventions/tmp-paths.md`, style matches `**Commit Messages**` | one match, reference present | awk-extracted Conventions section contains `**Tmp Paths**: Per-task scratch directories ... See `.cwf/docs/conventions/tmp-paths.md`...`. Style matches surrounding bullets (bold-name, colon, one-line, three sub-bullets) | PASS | First awk attempt with range `/^## Conventions/,/^## /` collapsed to one line (range matches on same start line); rewrote with flag-based awk and confirmed |
| TC-5b | design-alignment.md scope paragraph acknowledges adopter-shipped conventions live under `.cwf/docs/conventions/` | additive, one-line edit at lines 7-8 | Lines 7-11 now read "Conventions that need to ship with installed CWF copies — because adopters' agents face the same constraint in their own repositories — live under `.cwf/docs/conventions/` (e.g. `subagent-tool-selection.md`, `tmp-paths.md`), with no dev-repo mirror." Slightly longer than one line (added concrete examples to anchor the rule); surrounding paragraphs preserved | PASS | Deviation: 5 lines instead of 2, documented in f-implementation-exec.md § Step 2 |
| TC-6 | security-review.md:98 carries the `illustrative — not a canonical scratch path` annotation; original anti-pattern code preserved | both greps match once each; annotation co-located with anti-pattern line | grep #1: 1 match (annotation present); grep #2: 1 match (`/tmp/cwf-update` still present at line 98); Read tool window at offset=94 limit=10 confirms annotation lines 99-101 sit immediately after line 98 anti-pattern | PASS | Annotation split across 3 comment lines for column-width readability; intent identical |
| TC-7 | Glossary decision recorded — entry exists OR "no new term coined" documented | one path or the other | `grep -niE 'namespaced scratch\|canonical tmp\|tmp.path' .cwf/docs/glossary.md` returns zero matches both pre- and post-implementation. Decision: **no new term coined** — convention doc uses plain English ("scratch directory", "scratch path"); no glossary entry needed | PASS | Decision recorded here per the test plan's "or" clause |

### Non-Functional Tests

- **TC-NF1 (security read)**: PASS. § Threat model explicitly names the symlink-attack scenario ("hostile local user could pre-create the scratch directory or a file within it as a symlink to an attacker-owned target") and prescribes `mkdir -m 0700 -p "$scratch"` *before* any write. Read-after-write surface separately called out (default umask). Mandatory-guard placement is in § Convention's derivation snippet AND restated in § Threat model. A reader unfamiliar with the convention would correctly avoid both symlink-clobber and secret leakage.
- **TC-NF2 (`cwf-manage validate` regression)**: PASS. Pre-implementation: 1 violation (perms drift on `cwf-security-reviewer-changeset.md`, exit 0). Post-implementation (after f-step 6 chmod): `[CWF] validate: OK`, exit 0, zero violations. The expected Step 6 success signal.
- **TC-NF3 (chmod-only, no content drift)**: PASS. `sha256sum .claude/agents/cwf-security-reviewer-changeset.md` returns `c7033a74da495e7ef7b401f0b88ab6b8d8e53cfb69acb1a924c463bb182095e5`, exactly matching `script-hashes.json:27`. Restoration touched permissions only.
- **TC-M1 (memory grep gate)**: PASS per the gate's exception clause. 3 literal `/tmp/task-*` / `/tmp/msg.txt` hits remain (`feedback_no_tee_permissions.md:19`, `feedback_no_heredocs.md:25`, `MEMORY.md:20`), and each is inside an explicit historical/rationale annotation that warns against propagation. A 4th memory file (`project_archaeological_main.md`) was discovered during gate run and updated to canonical form — see f-implementation-exec.md § Step 5 deviation note.

## Test Failures

None.

## Coverage Report

100% of e-testing-plan.md test cases executed (TC-1 through TC-7, TC-5b, TC-NF1 through TC-NF3, TC-M1). All pass.

The plan's headline goal — "two simulated repo roots produce non-colliding scratch paths via the documented snippet" — is met by TC-3.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: no findings

no findings
The diff adds an inline comment to an existing illustrative code example, pointing readers to the canonical scratch-path convention. No executable code, configuration, or security-relevant logic changes.

## Lessons Learned
- awk range expressions `/start/,/end/` can collapse to a single line when `end` happens to match `start` (`/^## /` matches the same `## Conventions` line that opened the range). Use a flag-based awk pattern when "between markers" semantics are needed.
- Cross-grep gate (e.g. TC-M1) is genuinely load-bearing: it caught a 4th memory file (`project_archaeological_main.md`) not on the original plan list. Treat the plan's file list as a starting point; the gate is the final arbiter.
