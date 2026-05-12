# Intent-CTA skill descriptions with reference docs - Implementation Execution
**Task**: 134 (chore)

## Task Reference
- **Task ID**: internal-134
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/134-intent-cta-skill-descriptions-with-reference-docs
- **Template Version**: 2.1

## Goal
Execute the implementation following d-implementation-plan.md and e-testing-plan.md.

## Implementation Steps (from d-implementation-plan.md)

### Step 1: Write the convention doc
- **Planned**: Create `.cwf/docs/skills/skill-reference-convention.md` with
  purpose, location rule (incl. top-level prohibition), description shape
  and word budget, reference-doc shape and line budget, SKILL.md-reference
  prohibition, hardcoded-examples rule, YAML-validity expectation.
- **Actual**: Created. 82 lines (meta-guidance, exempt from 30-line budget
  per D4). All seven rule areas covered.
- **Deviations**: None at this step.

### Step 2: Write the first reference-doc instance
- **Planned**: Create `.cwf/docs/skills/reference/cwf-backlog-manager.md`
  with 1-2 sentence purpose, 3-5 example user phrasings, no operational
  instructions, no `SKILL.md` link. ≤30 lines.
- **Actual**: Created. 19 lines. Contains 5 example phrasings (within the
  3-5 budget) plus a 2-line "Not this skill" near-miss disambiguation
  block. Zero `SKILL.md` mentions (verified with `grep -nE '\bSKILL\.md\b'`,
  exit 1).
- **Deviations**: None.

### Step 3: Rewrite the cwf-backlog-manager frontmatter description
- **Planned (initial)**: Edit lines 1-7 of `.claude/skills/cwf-backlog-manager/SKILL.md`,
  apply the intent-CTA shape, verify YAML validity through a real parser.
- **Actual**:
  1. First applied the description as an unquoted YAML plain scalar.
  2. `YAML::XS` load failed with `mapping values are not allowed in this
     context` (line 2, col 72) — the colon-space inside `Examples: "..."`
     plus embedded double quotes confuses libyaml's plain-scalar rules.
  3. Tested both double-quoted (`\"`-escaped) and single-quoted (`''`-doubled)
     forms via `/tmp/cwf-task-134/test-quoting.pl`; both parsed correctly.
  4. Re-applied as double-quoted form (more readable). Re-ran verification
     via `/tmp/cwf-task-134/verify-skill.pl`: YAML parses OK, 23 words
     (≤30 budget), all required frontmatter keys present.
- **Deviations**:
  - D6 of d-implementation-plan.md was amended mid-exec to reflect this
    finding. The plan's "Code Changes / After" example was updated to show
    the quoted form (the source of truth for the final wording). Convention
    doc § "YAML validity" was likewise rewritten to mandate quoting.
  - The robustness reviewer in the d-plan review subagents flagged this
    risk preemptively; the empirical YAML::XS failure confirmed the warning
    was correct.

### Step 4: File the follow-up backlog entry
- **Planned**: Invoke `cwf-backlog-manager` to add a Low-priority entry
  titled "Roll intent-CTA description convention to remaining skills".
- **Actual**: Added via `backlog-manager add --title=... --task-type=chore
  --priority=Low --body='...' --identified-in=134`. Verified entry appears
  under `## Low` priority band in `backlog-manager list --all-items`.
- **Deviations**:
  - First attempt with `--body-file=/tmp/cwf-task-134/follow-up-body.txt`
    was rejected: `refusing absolute path`. The helper's path allowlist
    excludes `/tmp`. Re-submitted with inline `--body=...` (single-quoted).
  - Body text replaces `≤` with `<=` and dashes with ASCII to avoid any
    shell-quoting surprises in the inline form.

### Step 5: Validation gate
- **Planned**: `cwf-manage validate` pass; zero SKILL.md mentions in the
  reference-doc instance; manual smoke for intent-match.
- **Actual**:
  - `.cwf/scripts/cwf-manage validate` → `[CWF] validate: OK`.
  - `grep -nE '\bSKILL\.md\b' .cwf/docs/skills/reference/cwf-backlog-manager.md`
    → exit 1 (no match).
  - Convention doc *does* mention SKILL.md by name in prohibition context
    (lines 4, 21, 33, 35, 39, 48, 74). This is expected per the test plan's
    TC-6: the convention doc names what's prohibited; the rule applies to
    *instance* docs.
  - Manual smoke: re-reading the new description, "what's in the backlog"
    is one of the verbatim example phrasings → an LLM scanning the system
    prompt now has a direct pattern-match for the original miss.

## Deviations Summary

1. **Mid-exec plan amendment (D6)**: discovered that strict YAML parsers
   reject the unquoted form. Updated D6 and the Code Changes section of
   d-implementation-plan.md to mandate double-quoted form, and revised the
   convention doc's YAML-validity section accordingly. Both changes
   bundled into the implementation commit (`ef9a623`).
2. **`--body-file=/tmp/...` rejected**: backlog-manager's path allowlist
   excludes absolute paths. Fell back to inline `--body=` with the body
   contents single-quoted on the command line. No functional impact.
3. **Implementation committed before f-checkpoint**: the
   security-review-changeset helper anchors against `anchor..HEAD` (commit
   history only) and so cannot see uncommitted working-tree changes. To
   give the security subagent a non-empty changeset, the implementation
   work was committed as `ef9a623` before invoking the subagent. The
   f-checkpoint commit (this file) is a separate commit.

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed.
- [x] All success criteria from a-task-plan.md met (verified by inspection
  against the file at HEAD).
- [x] No requirements/design phase for chore-shaped task; N/A.
- [x] No planned work deferred. Rollout to remaining skills is *explicitly*
  out of scope per a-task-plan and tracked in the new backlog entry.

## Security Review

**State**: error

**Note**: The subagent body is substantively clean ("findings: none." at the
final line, all checked categories explicitly cleared). However, the response
does not begin with the `findings:` / `no findings` / `error:` sentinel as
required by `security-review.md` § "Exec-phase prompt template", and the body
contains no numbered list to trigger the fallback rule. Per the three-tier
rule's conservative default, classified as `error`. Re-running is unnecessary
because the substance is unambiguous; the user reviewing this file makes the
final call.

The reference doc examples also appear hardcoded: `"what's in the backlog?"`, `"show me the high-priority items"`, `"add a backlog item for X"`, `"retire that backlog entry — it shipped in task N"`, `"delete the typo'd backlog entry titled Y"`. These are not derived from BACKLOG titles or branch names.

Now let me verify the convention doc's claims and check for YAML validity:

The new `skill-reference-convention.md` document enforces the rule that examples MUST be hardcoded. Looking at the YAML in the SKILL.md:

```yaml
description: "Show or manipulate the project backlog/changelog. Examples: \"what's in the backlog\", \"add a backlog entry for X\", \"retire item Y for task N\"."
```

This follows the strict YAML quoting convention mentioned in lines 62–67 of the convention doc: it's double-quoted with escaped internal double quotes. The convention doc states this is required for portability.

Let me verify there are no other security concerns by checking if there are any shell invocations or other risky patterns in the changeset. The diff shows only documentation changes (Markdown and YAML frontmatter), no executable code changes.

**Category (d): Unsafe environment-variable handling**
- No environment variable handling in this changeset. No risk here.

**Category (e): Pattern-based risks**
- No applicable patterns—this is purely documentation. No risk here.

All the examples in both the SKILL.md description and the reference doc are hardcoded, not derived from user-controlled sources. The new convention document itself establishes and reinforces the security rule against prompt injection via documentation.

findings: none. The changeset properly enforces and follows the prompt-injection defense rule (security-review.md § (c)) by mandating hardcoded examples in skill descriptions and reference docs, with explicit security framing in the new convention document. All examples in both modified/new files are author-curated placeholders, not derived from BACKLOG titles or user inputs. YAML syntax is strict-parser-compatible.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
- Always YAML-parse-test the SKILL.md frontmatter through a strict parser
  (`YAML::XS`); the harness's lenient parser is not representative.
- The security-review-changeset script anchors at `anchor..HEAD` (commits only),
  not the working tree. Implementation work must be committed before invoking
  the security-review subagent.
- See j-retrospective.md for the broader process learnings.
