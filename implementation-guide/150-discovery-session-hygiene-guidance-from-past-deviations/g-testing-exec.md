# Session hygiene guidance from past deviations - Testing Execution
**Task**: 150 (discovery)

## Task Reference
- **Task ID**: internal-150
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/150-session-hygiene-guidance-from-past-deviations
- **Template Version**: 2.1

## Goal
Execute the 16 test cases from e-testing-plan.md against the f-exec output.

## Test Environment
- Branch: `discovery/150-session-hygiene-guidance-from-past-deviations` post-f-exec (commit `dcc1222`).
- Validate baseline at `/tmp/-home-matt-repo-coding-with-files-task-150/validate-baseline.txt` (7 lines; one pre-existing `[SECURITY]` for `.claude/agents/cwf-plan-reviewer-misalignment.md` permissions — Task 149 carry-over).
- Section extracts at `/tmp/-home-matt-repo-coding-with-files-task-150/sec-{clear,compact,boundaries}.txt`.

## Test Results

### Functional Tests

| Test ID | Maps to | Mechanical check | Expected | Actual | Status |
|---------|---------|------------------|----------|--------|--------|
| TC-1  | NFR2.1 | `wc -l session-hygiene.md` | ≤60 | 59 | PASS |
| TC-2  | FR1.AC1.1 | Bullets in §"When to `/clear`" | ≥3 | 4 | PASS |
| TC-3  | FR1.AC1.2 | Bullets citing `P[1-5]` in §"When to `/clear`" | ≥2 | 2 (P1, P4) | PASS |
| TC-4  | FR2.AC2.1 | `/compact` + `auto-compact` both in §"When to `/compact`" | both ≥1 | 2, 1 | PASS |
| TC-5  | FR2.AC2.2 | "standing security rules" literal + preservation-list bullets | ≥1, ≥3 | 1, 3 | PASS |
| TC-6  | FR3.AC3.1, AC3.2 | MEMORY.md + session-start + correction terms in §"Session boundaries" | each ≥1 | 1, 1, 1 | PASS |
| TC-7  | FR3.AC3.3 | "re-derive" + on-disk/a-task-plan-through-j-retrospective/Status-fields | each ≥1 | 1, 3 | PASS |
| TC-8  | FR4.AC4.1 | `git diff --name-status main...HEAD -- .cwf/docs/conventions/` | one `A` line | `A .cwf/docs/conventions/session-hygiene.md` | PASS |
| TC-9  | FR4.AC4.2, AC4.3 | CLAUDE.md grep for `session-hygiene.md`; line has no `[[X]]` | ≥1, 0 | 1, 0 | PASS |
| TC-10 | FR4.AC4.3 | `[[X]]` in produced doc | 0 (or all MEMORY.md slugs) | 0 | PASS |
| TC-11 | NFR4.1 | "surface" + "never smooth" in §3 | each ≥1 | 1, 1 | PASS |
| TC-12 | NFR4.2 | Anti-pattern enum ≥1; defender-framing first-filter regexes | ≥1, 0, 0 | 2, 0, 0 | PASS |
| TC-13 | NFR4.3 | Manual reader-pass for defender framing | reviewer attests PASS | attested below | PASS |
| TC-14 | Process | BACKLOG removed, CHANGELOG appended, `backlog-manager validate` exit 0 | 0, ≥1, 0 | 0, 1, 0 | PASS |
| TC-15 | Step 5.5 | `cwf-manage validate` diff vs baseline shows no new `[SECURITY]` | 0 | 0 | PASS |
| TC-16 | low-stakes | Self-reference count in produced doc | 0 | 0 | PASS |

### TC-13 attestation (NFR4.3 manual judgement gate)
Reader-pass on `.cwf/docs/conventions/session-hygiene.md` with NFR4.3 in mind:
- Every sentence describing the P2 failure mode (`/compact` boundary, standing-rule loss) is phrased defender-side: "preserve across the boundary", "the friction is the feature", "surface security signals; never smooth them".
- The anti-pattern enumeration appears only inside the "Do not propose" sub-bullet — explicitly labelled as forbidden, not recommended.
- No recipe phrasing: no instruction enumerates inputs that reliably trigger rule-loss.
- The `/clear`-as-gate-bypass mention is in a defender bullet ("Do NOT `/clear` to escape a stuck security gate, hash mismatch, or failing validator. Surface the issue; never smooth it.") — it describes what NOT to do, not how to induce gate-bypass.

**Verdict**: PASS.

### Non-Functional Tests
- **Performance**: N/A (documentation only).
- **Security**: TC-11 (inline principle), TC-12 (anti-pattern enumeration + defender first-filter), TC-13 (manual review), TC-15 (validate diff) all PASS.
- **Usability**: Line budget (TC-1) PASS at 59/60. Declarative `when X → do Y` shape verified by TC-2 / TC-4 / TC-5 / TC-6 / TC-7 structural greps.
- **Reliability**: N/A.

## Test Failures
None.

## Coverage Report
- 100% requirement coverage: every FR1–FR4 sub-AC and every NFR2.1 / NFR4.1–NFR4.3 has at least one passing TC.
- 100% validation-gate coverage: every Step-5 mechanical gate (5.1–5.5) and Step-6 manual gate from d-implementation-plan has a passing TC.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 150
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
- Pre-extracting the three target sections to `/tmp` files via a small Perl helper made the per-section greps trivial and avoided shell-quoting fragility (sections have backticks and special chars in their headings).
- The d-plan's anti-pattern first-filter regexes auto-passed because the doc's `/clear` mentions are wrapped in backticks (`` `/clear` ``) or followed by hyphens, so `/clear\s+` never matches — a structural property that fell out of normal prose, not a contortion.

## Security Review

**State**: no findings

no findings: empty changeset
