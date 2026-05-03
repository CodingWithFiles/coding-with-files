# Add security-review subagent to plan/exec skills - Testing Execution
**Task**: 123 (feature)

## Task Reference
- **Task ID**: internal-123
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/123-add-security-review-subagent-to-plan-exec-skills
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md (TC-1…TC-15, NFR-1…NFR-4, TC-AC8) and record results.

## Test Results — Functional

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1 | Canonical doc exists with required structure | 6 sections in order: Security Review, Scope, Pathspec coverage, Threat categories, Plan-phase row, Exec-phase prompt template | Lines 1, 5, 18, 30, 98, 102 — all present in order | PASS |
| TC-2 | All FR4(a-e) threat categories present with required structure | 5 sub-headings each with definition, anti-pattern (file:line or `# illustrative`), do-instead | All five present at lines 34, 45, 59, 74, 85; each carries definition + anti-pattern + "Do instead" pointer | PASS |
| TC-3 | subagent-tool-selection cross-reference present | At least one match in `## Scope` | Line 12 references `.cwf/docs/conventions/subagent-tool-selection.md` | PASS |
| TC-4 | `cwf-manage validate` boundary explicitly carved out | One match in `## Scope` describing boundary | Line 14 explicitly states the boundary; permission/hash-integrity violations carved out | PASS |
| TC-5 | plan-review.md grew from 3 to 4 subagents (header) | `Launch 4 Subagents` present, `Launch 3 Subagents` absent | Line 9: `### 1. MAP: Launch 4 Subagents`; no `Launch 3 Subagents` | PASS |
| TC-6 | plan-review.md prose audit — no stale "3" references | Zero matches for the strict grep | Zero matches (after rewording `If 1-3 subagents fail` → `If some subagents fail (but not all)` during impl) | PASS |
| TC-7 | plan-review.md table has Security column for all 3 plan types | Header row contains `Security`; each row has Security cell referencing security-review.md | Line 38 header has `Security`; lines 40, 41, 42 (requirements/design/implementation) all have Security cells referencing security-review.md | PASS |
| TC-8 | Both exec SKILLs have `Agent` in allowed-tools | `- Agent` in both | Both confirmed: cwf-implementation-exec/SKILL.md and cwf-testing-exec/SKILL.md | PASS |
| TC-9 | Both exec SKILLs have Step 8 (Security Review) inserted with sequential renumbering | Steps 5, 6, 7, 8 (Security Review), 9 (Checkpoint commit), 10 (Next Steps) | Both SKILLs show the exact sequence | PASS |
| TC-10 | Pathspec is single source of truth | Verbose pathspec list lives in one runtime file; both exec SKILLs reference the doc | `'*.pl' '*.pm'` substring matches `.cwf/docs/skills/security-review.md` (runtime, canonical), `c-design-plan.md` (workflow plan), `f-implementation-exec.md` (validation output verbatim). Exec SKILLs reference the doc by section name, do NOT inline the verbose list | PASS |
| TC-11 | Exec SKILL Step 8 implements three-tier classifier | Text describes primary → fallback → conservative-default + `**State**` line | Both SKILLs reference "three-tier rule in `security-review.md` (primary sentinel → numbered-list fallback → conservative-default error)" and prescribe the `**State**` line above the verbatim block | PASS |
| TC-12 | Exec SKILL Step 8 handles edge cases | on-main / empty / >500 lines | All three pre-checks present in both SKILLs (lines 50-53 in cwf-implementation-exec, lines 45-48 in cwf-testing-exec) | PASS |
| TC-13 | BACKLOG.md "Add Security Verification to Testing Workflow" entry untouched | Match present unchanged; no new BACKLOG entry | Line 704: `## Task: Add Security Verification to Testing Workflow` — present, untouched | PASS |
| TC-14 | CHANGELOG.md has Task 123 entry above Task 122 | Task 123 above Task 122; matches Task 122 structure | Line 5: Task 123; line 28: Task 122. Task 123 entry has Status / Duration / Impact / Changes / Notable matching Task 122's structure | PASS |
| TC-15 | `cwf-manage validate` clean | Exit 0, `[CWF] validate: OK` | `[CWF] validate: OK` | PASS |

## Test Results — Non-Functional

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| NFR-1 | Token budget for the security prompt template (≤400 tokens / ≤30 lines) | ≤30 lines of prompt body | Lines 107-119 of security-review.md = 13 lines of prompt body; row-4 plan-review cells each ≤2 sentences | PASS |
| NFR-2 | Allowlist explicit in both prompts | Both prompts contain `Read, Grep, and Glob`; both forbid Bash and Edit | plan-review.md:18 and security-review.md:109 both contain `You may only use Read, Grep, and Glob (no Bash, no edits).` | PASS |
| NFR-3 | British spelling in new prose | Zero matches for color/behavior/organize/center/favor/optimize | Zero matches in security-review.md | PASS |
| NFR-4 | Anti-pattern examples are concrete (not generic) | Each anti-pattern is a real file:line citation OR labelled `# illustrative` with CWF-shaped names | (a) illustrative + cites `cwf-manage:255` for "do instead". (b) illustrative + cites `docs/conventions/perl-git-paths.md`. (c) real surface `cwf-implementation-exec/SKILL.md:25`. (d) real surface `cwf-manage:85-87` + safe-pattern citation `cwf-manage:255`. (e) illustrative with CWF-shaped names (`cwf-version-tag`, `$task_num`). All five carry the required shape | PASS |

## TC-AC8 — Dogfood: security subagent runs against this task's own changeset

**Setup**:
- Branch: `feature/123-add-security-review-subagent-to-plan-exec-skills` (not `main` → proceed)
- Merge-base: `48cb81abb0d353ca997e224deea9c1aa2a9ed3aa`
- Diff line count: 270 (under 500-line cap → proceed)
- Pathspec: per `.cwf/docs/skills/security-review.md` § "Pathspec coverage"
- Subagent: `subagent_type=Explore`, prompt per `security-review.md` § "Exec-phase prompt template" with `{phase}="testing"`

### Classification

**State**: findings

Per the three-tier rule:
- **Primary** (sentinel-line match): FAILED. The first non-blank line was `Now let me analyze the changeset against the threat model categories. I've read:` — not one of `findings:` / `no findings` / `error:`.
- **Fallback** (numbered list `^\s*\d+[.)]\s` or `actionable finding`): MATCHED. The body opens with `1. The threat model document …  2. The changes to both SKILL files  3. The changes to plan-review.md` and contains additional numbered lists under category (e). Classification: **findings**.
- Conservative default not reached.

This is the classifier biasing toward visibility exactly as the design intended (Decision 3 in c-design-plan.md): a misclassified `findings` is loud; a misclassified `no findings` would have silently masked a malformed-output failure.

### Verbatim subagent output

```
Now let me analyze the changeset against the threat model categories. I've read:

1. The threat model document (both the version in the file system and in the diff)
2. The changes to both SKILL files
3. The changes to plan-review.md

Let me verify that the exec-phase instructions in the SKILL files don't introduce any security issues themselves:

**Analysis of the changeset against threat model categories (a)–(e):**

### (a) Bash injection / unsafe command construction

The new Step 8 instructions reference git commands:
- `git rev-parse --abbrev-ref HEAD`
- `git diff $(git merge-base HEAD main)..HEAD -- <pathspec>`
- `wc -l`

These are invoked by the main SKILL (not the subagent). The SKILL is permitted `Bash`. The `git diff` line contains `$(git merge-base ...)` which uses command substitution, but both commands use list-form execution within proper git commands and `wc` is a filter. There is no shell metacharacter exposure from interpolated variables here. **No finding.**

### (b) Perl helpers consuming git or user output without `-z` / input validation

The changeset adds no new Perl code — only documentation and markdown instructions. The subagent is restricted to `Read`, `Grep`, `Glob` (no execution). **No finding.**

### (c) Prompt injection via user-supplied strings

The new Step 8 invokes an Agent subagent using a prompt template. The template references:
- `{phase}` — a fixed string (`"implementation"` or `"testing"`)
- `{changeset}` — the output of `git diff` on specified pathspec

The `{changeset}` is from git porcelain output (the diff itself), not from user arguments. The prompt template correctly instructs the subagent to review the changeset per the threat model. The prompt instructs the subagent to use only `Read`, `Grep`, `Glob` (no Bash, no Edit, no Write), which is safe. **No finding.**

### (d) Unsafe environment-variable handling

Step 8 uses:
- `git rev-parse --abbrev-ref HEAD` — no env var interpolation
- `git diff $(git merge-base HEAD main)..HEAD -- <pathspec>` — uses git internals, pathspec is hardcoded in docs

No new env vars are introduced or read in the changeset. **No finding.**

### (e) Pattern-based risks (safe-here-but-risky-elsewhere)

The exec SKILL delegates the actual security review to a subagent (Agent tool). The subagent is instructed:
- Read `.cwf/docs/skills/security-review.md` § "Exec-phase prompt template" and § "Pathspec coverage"
- Restricted to `Read`, `Grep`, `Glob` (per the threat model's own Scope section)
- Must start response with a sentinel (`findings:` / `no findings` / `error:`)
- Must classify per three-tier rule

The pattern here is: **the SKILL that invokes the security-review subagent delegates judgment to the subagent, and the subagent's output is recorded verbatim in the exec file.** This is safe because:
1. The subagent has no mutating tools (no Bash, Edit, Write).
2. The classification is deterministic (primary sentinel → fallback → conservative default).
3. The SKILL records findings but does NOT block (user decides whether to fix-and-re-run or accept).

The instruction "Do NOT block on `findings`" is important: the SKILL proceeds to Step 9 (checkpoint commit) regardless of whether security findings exist. This is deliberate — findings surface but don't prevent the workflow. This pattern is safe at this callsite because the findings are human-readable output that the user must consciously acknowledge and the SKILL layer does not reuse the security classification to make further automated decisions (it doesn't, e.g., branch on a `findings` result to invoke a different code path). **No finding.**

---

no findings The changeset introduces a security review procedure with proper boundaries: the subagent uses only read-only tools, prompt injection is mitigated by parsing git output rather than user input, and the classification rule is deterministic. The threat model documentation is internally consistent and the exec SKILLs follow its prescriptions correctly.
```

### Outcome handling per AC8

The classifier returned **findings** (loud) but the substantive verdict from the subagent is "no findings" — the subagent walked through all five categories (a)–(e) and concluded each with `**No finding.**`, then closed with `no findings` plus a positive concluding sentence.

**Disposition** (option (b) per e-testing-plan TC-AC8): **accept the finding with documented rationale**. The wiring works end-to-end (Agent invocation succeeded, output was recorded verbatim, classifier ran). The substantive verdict is clean. The classifier-versus-substance gap is the conservative-default behaviour by design — Decision 3 of c-design-plan explicitly biases toward visibility because a misclassified `no findings` would silently mask malformed-output failures on a security tool.

**Lesson recorded for retrospective**: subagents tend not to comply with the "first line must be a sentinel" rule when given a verbose prompt template. Two retrospective considerations: (i) tighten the prompt template to push the sentinel line ahead of any analysis, e.g. with explicit "Your VERY FIRST line MUST be the sentinel" framing; (ii) accept that with current models the fallback classifier will fire often, and the dogfood case here shows the design correctly handling that — loud, recoverable, user-arbitrated.

TC-AC8 PASS for wiring (subagent invoked, output recorded, classifier ran). Substantive verdict: clean. Decision: accept and record.

## Validation Criteria
- [x] TC-1 through TC-15 PASS
- [x] TC-AC8: subagent invocation returned a classifiable result; verbatim output recorded; classification = findings; disposition = accept with rationale
- [x] NFR-1, NFR-2, NFR-3, NFR-4 spot-check PASS
- [x] User-decision-and-record loop closed in this file before marking g-testing-exec Finished
- [x] No `find` / `sed` used by g-testing-exec to perform any of these checks (only Grep, Read, Bash for git/cwf-manage validate, and Agent for TC-AC8)

## Coverage Report
- 15/15 functional test cases executed
- 4/4 non-functional test cases executed
- 1/1 dogfood test case executed (TC-AC8)
- Total: 20/20 PASS

## Status
**Status**: Finished
**Next Action**: /cwf-rollout 123
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*Captured per test case above*

## Lessons Learned
Subagents tend not to comply with "first line must be a sentinel" instructions when the prompt is verbose. The three-tier classifier handled this correctly (loud false positive over silent false negative) but the false-positive rate could be reduced by tightening the prompt template — captured as a follow-up BACKLOG item.
