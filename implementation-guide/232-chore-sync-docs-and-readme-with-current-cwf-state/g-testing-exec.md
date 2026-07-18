# Sync docs and README with current CWF state - Testing Execution
**Task**: 232 (chore)

## Task Reference
- **Task ID**: internal-232
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/232-sync-docs-and-readme-with-current-cwf-state
- **Template Version**: 2.1

## Goal
Execute the deterministic grep/ls checks defined in e-testing-plan.md against the live tree
and confirm the doc edits are accurate, introduce no new stale claim, and stay in scope.

## Test Environment
Live working tree on branch `chore/232-…`; doc edits already committed at the f checkpoint
(`1a338d0`). Tools: `ls`/`grep` (read-only), `.cwf/scripts/cwf-manage`, `prove`. No
repo-state mutation, no throwaway task generated (per e-plan — not a rebrand).

## Test Results

### Functional Tests

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1 | Skill-list completeness | 20 CLAUDE.md `/cwf-*` entries == 20 real command dirs; `test-cwf-skill` absent; `cwf-manage` = script | Both lists identical (20 names); `cwf-current-task` + `cwf-backlog-manager` now present; `test-cwf-skill` absent; `cwf-manage` labelled the management script | PASS |
| TC-2 | Permission-model ceiling invariant | CLAUDE.md + DESIGN.md state recorded perms are an upper bound; `validate` flags *more*-permissive; `fix-security` clamps down; `0444` included; no "minimum 0500" | CLAUDE.md L132 and DESIGN.md L78–80 both state the upper-bound/clamp-down model with `0700`/`0500`/`0444`; verified against `hash-updates.md` L20 and `cwf-manage` clamp (`actual & recorded`); "minimum 0500" gone | PASS |
| TC-3 | README plan/exec wording bounded | 3 anchors hedged ("where applicable" / implementation+testing); L26 file-structure line unchanged | L65, L119, L154 all hedged; L26 verbatim unchanged | PASS |
| TC-4 | `git describe` examples preserve format | `<tag>-<n>-g<sha>` shape kept; no bare-tag collapse; old `v1.1.187` pin gone | CLAUDE.md L138 + DESIGN.md L97 show `format <tag>-<commits-since>-g<short-sha>`, e.g. `v1.1.x-<n>-g<sha>`; no bare tag | PASS |
| TC-5 | Config-value samples match owner decision | Uniform, format-valid, per owner's refresh choice | README L215–216 and SPEC L52/L121–122 all `v1.1` / `v1.1.232` (owner chose refresh); satisfy `/^v\d+\.\d+(\.\d+)?$/`; no mix | PASS |
| TC-6 | No new stale count/version claim | `minimum 0500`, `v1.1.187`, `v1.1.188`, `gcea1c19`, `"v1.0.0"`, `"major_minor": "v1.0"`, `always split`, `separated for each stage` → 0 hits across edited docs | 0 hits | PASS |
| TC-7 | Scope containment; no hash-tracked file | Only CLAUDE.md, DESIGN.md, README.md, CWF-PROJECT-SPEC.md changed; COMMANDS.md/INSTALL.md untouched; none in `script-hashes.json` | f-commit `1a338d0` touches exactly those 4 docs (+ the wf file); COMMANDS.md/INSTALL.md absent; `grep -c` of the 4 paths in `script-hashes.json` = 0 | PASS |

### Non-Functional Tests

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-8 | Integrity + suite green | `validate: OK` (no sha256/permission drift); `prove -r t/` passes | `cwf-manage validate` → `OK`; `prove -r t/` → **Files=78, Tests=1077, Result: PASS** | PASS |
| TC-9 | Prose conventions | British spelling, no superlatives, "CwF" in prose, no personal names in edited passages | Edited passages introduce no superlative, no American spelling ("genericise" used), no personal name, and no new "CWF"/"CwF" prose token; the sole superlative-scan hit (DESIGN.md L14 "works best") is pre-existing intro text outside the edited passages | PASS |

## Test Failures
None. All TC-1..TC-9 pass.

## Coverage Report
- **100% of d-plan edits asserted**: skill-list (TC-1), permission model ×2 files (TC-2),
  README plan/exec ×3 anchors (TC-3), version-example format (TC-4), config samples (TC-5).
- **Negative assertions**: no bare-tag `git describe` (TC-4); README L26 and the
  audited-clean files (COMMANDS.md, INSTALL.md) unchanged (TC-3, TC-7).
- **Out of scope (per e-plan)**: no generated-artefact smoke test — prose edits do not flow
  into template output; not a rebrand.

## Changeset Reviews (Step 8 — 2-reviewer MAP, parallel)
Prep: `security-review-changeset --wf-step=testing-exec` exit 0, 940 lines (32 production) →
security agent launched; `best-practice-resolve --phase=testing-exec` exit 0, 3 corpora
matched → bp agent launched. Classifier over the scratch dir returned both as `no findings`;
launched set == classified set.

### Security Review
**State**: no findings

Documentation-only diff (4 prose files + 6 task workflow markdown files); no Perl/shell/
hook/skill/template/`script-hashes.json` change. Categories (a)–(e) all clear. The
security-model rewrite is factually consistent with the ceiling/clamp model, correcting
rather than introducing an inaccuracy. One **non-actionable** audit note: the diff carries
literal `cwf-review` fenced blocks inside `f-implementation-exec.md` (recorded prior-phase
verdicts) — inert here because the classifier parses each reviewer's own output file, not the
changeset; flagged only as a forward-looking caution, no fix needed for this diff.
```cwf-review
state: no findings
summary: Docs-only sync (4 prose files + 6 task workflow markdown files); no code, command-construction, input-flow, env-var, or integrity surface touched. Categories (a)-(e) clear; one non-actionable pattern note on embedded cwf-review blocks in the diff.
```

### Best-Practice Review
**State**: no findings

Three corpora resolved (golang, postgres, perl — all readable). Each governs source code in
its language; none applies to a prose-only Markdown changeset. No code artefact in the diff.
```cwf-review
state: no findings
summary: Docs-only changeset (Markdown prose + CWF wf-step files); the resolved golang/postgres/perl corpora govern source code, and no Go/SQL/Perl code appears in the diff.
```

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
Deterministic grep/ls + `validate` + `prove` fully covered a prose-only change; no repo-state
mutation needed. See j-retrospective.md.
