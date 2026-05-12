# Intent-CTA skill descriptions with reference docs - Testing Execution
**Task**: 134 (chore)

## Task Reference
- **Task ID**: internal-134
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/134-intent-cta-skill-descriptions-with-reference-docs
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation
from d-implementation-plan.md.

## Test Results

### Functional Tests

| Test ID | Test Case | Expected | Actual | Status | Notes |
|---------|-----------|----------|--------|--------|-------|
| TC-1 | Convention doc exists at canonical location | exit 0 | exit 0 | PASS | |
| TC-2 | Convention doc names four mandatory rules | matches for location / 30 words / 30 lines / SKILL.md / author-curated\|hardcoded\|not-derived | 1 / 1 / 1 / 7 / 2 hits respectively | PASS | First attempt failed due to a shell-quoting bug in the test runner (`\|` vs `|` under `grep -E`); content was fine, re-ran correctly. |
| TC-3 | Reference doc exists at canonical location | exit 0 | exit 0 | PASS | |
| TC-4 | Reference doc ≤ 30 lines | ≤ 30 | 19 | PASS | |
| TC-5 | Reference doc contains 3-5 example user phrasings | 3 ≤ N ≤ 5 | 5 | PASS | Counted lines matching `^- "` |
| TC-6 | Neither new doc references `SKILL.md` (instance only) | 0 hits in instance | 0 hits (grep exit 1) | PASS | Convention doc legitimately names SKILL.md in prohibition context (7 hits); rule applies to instance docs only per test plan. |
| TC-7 | Frontmatter description ≤ 30 words | ≤ 30 | 23 | PASS | Verified by `/tmp/cwf-task-134/verify-skill.pl` |
| TC-8 | SKILL.md parses as valid YAML | no parse error, all required keys present | parse OK; name, description, user-invocable, allowed-tools all present | PASS | Used `YAML::XS` (strict libyaml). Initial unquoted form failed (caught during exec, fixed to double-quoted). |
| TC-9 | New description names user-facing domain | grep -i "backlog" matches | "Show or manipulate the project backlog/changelog..." | PASS | |
| TC-10 | Description contains 2-3 example phrasings | 2 ≤ N ≤ 3 | 3 | PASS | Counted paired `\"...\"` sequences in description. |
| TC-11 | SKILL.md body unchanged | diff bounded to frontmatter | only line 3 (description) changed | PASS | `git diff ef9a623~ ef9a623 -- .claude/skills/cwf-backlog-manager/SKILL.md` shows a one-line edit in the frontmatter region. |
| TC-12 | Follow-up backlog entry filed at Low priority | one match present | "Roll intent-CTA description convention to remaining skills" present under `## Low` | PASS | |

### Non-Functional Tests

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| NFT-1 | `cwf-manage validate` regression | exit 0, "[CWF] validate: OK" | exit 0, "[CWF] validate: OK" | PASS |
| NFT-2 | `backlog-manager validate --all` regression | exit 0 | exit 0 | PASS |
| NFT-3 | Intent-match plausibility (manual) | "what's in the backlog" appears verbatim in description | Verbatim match present | PASS |
| Regression | `prove t/` (existing test suite) | 0 failures | 441 tests, 40 files, all PASS | PASS |

## Test Failures
None.

## Coverage Report

Every success criterion in `a-task-plan.md` is covered by at least one of
TC-1 through TC-12. No new code paths introduced (docs-only task), so
line/branch coverage is not applicable. The existing test suite (`prove t/`)
provides regression coverage for the broader CWF system; all 441 tests pass.

## Security Review

**State**: findings

**Classification note**: The subagent's first non-blank line was descriptive
prose ("Now I'll analyze the changeset against each threat category...")
rather than the required `findings:` / `no findings` / `error:` sentinel.
Per `security-review.md` § "Exec-phase prompt template" the primary
classification failed. The fallback rule triggered on a numbered list in
the body (enumerating the three reviewed files, not actual findings); per
the rule's literal wording, that mandates `findings` classification.
Substantively, the subagent's closing line is "no findings." and all five
threat categories were explicitly cleared. The classification reflects the
sentinel-format failure, not an actual security concern. (The same
sentinel-format issue occurred in the f-exec security review and is worth
considering as a follow-up improvement to the subagent prompt.)

The changeset is identical to the f-exec review (no CWF-internal-prefix
changes were made during the testing phase), so the substantive review is
unchanged.

### Verbatim subagent output

Now I'll analyze the changeset against each threat category (a)–(e) from the security review document.

The changeset modifies:
1. `.claude/skills/cwf-backlog-manager/SKILL.md` - description field update
2. `.cwf/docs/skills/reference/cwf-backlog-manager.md` - new reference doc
3. `.cwf/docs/skills/skill-reference-convention.md` - new convention doc

Let me examine the key security-relevant aspects:

**Category (a) - Bash injection**: The files contain only Markdown and YAML. No shell commands or interpolation of user input into shell constructs. No risk.

**Category (b) - Perl/git output parsing**: No Perl code in this changeset. Not applicable.

**Category (c) - Prompt injection via user-supplied strings**: This is the critical area. The changeset updates the `description` field in SKILL.md. The new description is:

```
"Show or manipulate the project backlog/changelog. Examples: \"what's in the backlog\", \"add a backlog entry for X\", \"retire item Y for task N\"."
```

Looking at the new convention document `.cwf/docs/skills/skill-reference-convention.md`, lines 49-58 establish the security rule:

> "Example phrasings in both the frontmatter `description` and the reference doc MUST be hardcoded by the task author. They MUST NOT be derived from user-controlled sources (BACKLOG titles, branch names, task descriptions, issue bodies, etc.). The description flows into every session's system prompt; treating it as an untrusted-content surface would create a prompt-injection channel via documentation."

The examples in the updated description (`"what's in the backlog"`, `"add a backlog entry for X"`, `"retire item Y for task N"`) appear to be generic, hardcoded templates rather than derived from actual BACKLOG or user input. However, I should verify that the reference doc similarly uses hardcoded examples.

Looking at `.cwf/docs/skills/reference/cwf-backlog-manager.md`, lines 10-13:
```
- "what's in the backlog?"
- "show me the high-priority items"
- "add a backlog item for X"
- "retire that backlog entry — it shipped in task N"
- "delete the typo'd backlog entry titled Y"
```

These appear to be template examples (using generic placeholders like "X", "N", "Y"). They are not actual BACKLOG titles or user-derived content. This follows the convention correctly.

**Category (d) - Unsafe environment-variable handling**: No environment variable access in these documentation/config files. Not applicable.

**Category (e) - Pattern-based risks**: No risky patterns that are safe at callsite but would be dangerous elsewhere. This is documentation establishing conventions for future code.

The convention doc itself (lines 65-74) includes YAML validity guidance and correctly quotes the description when it contains the "Examples: " pattern with internal quotes, using `\"` escape sequences. This is properly formatted.

no findings. The changeset correctly implements the skill-reference convention with hardcoded example phrasings that do not derive from user-controlled sources, and properly escapes the YAML description field per the convention's own guidance.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
- The security-review subagent prompt does not enforce sentinel-first output;
  both this phase and f-phase ended up misclassified by the three-tier rule.
  Substance was clean both times. Filed as a follow-up backlog entry.
- See j-retrospective.md for the broader process learnings.
