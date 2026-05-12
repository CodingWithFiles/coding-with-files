# Intent-CTA skill descriptions with reference docs - Implementation Plan
**Task**: 134 (chore)

## Task Reference
- **Task ID**: internal-134
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/134-intent-cta-skill-descriptions-with-reference-docs
- **Template Version**: 2.1

## Goal
Reshape the `cwf-backlog-manager` frontmatter `description` into an intent-CTA
form, and establish (with one worked instance) a convention for short per-skill
reference docs that aid skill selection without inviting agents to Read+follow
SKILL.md outside the Skill-tool harness.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary Changes
- `.cwf/docs/skills/skill-reference-convention.md` *(new)* — defines location,
  shape, size budget, prohibition on referencing `SKILL.md` paths, and the
  hardcoded/author-curated examples rule.
- `.cwf/docs/skills/reference/cwf-backlog-manager.md` *(new)* — first instance
  conforming to the convention. Brief purpose + 3-5 example user phrasings.
- `.claude/skills/cwf-backlog-manager/SKILL.md` — rewrite frontmatter
  `description` only. Body unchanged.

### Supporting Changes
- `BACKLOG.md` — add follow-up entry to roll the convention to remaining skills
  (filed via `.cwf/scripts/command-helpers/backlog-manager add`, not direct edit).

### Out of Scope (explicit)
- Other skills' descriptions. They follow the same reference-style pattern and
  exhibit the same selection-miss risk, but rolling the change to all of them
  is a separate task (filed as the follow-up above) so the convention can first
  be validated on this single instance.
- A linter / pre-commit hook enforcing the size budget. Listed as a possible
  future follow-up, not built here.

## Design Decisions

### D1. Location: `.cwf/docs/skills/reference/<skill-name>.md`
`.cwf/docs/skills/` already holds cross-cutting skill docs (`checkpoint-commit.md`,
`plan-review.md`, `workflow-preamble.md`, etc.). Adding per-skill instance docs
alongside them mixes two categories. A `reference/` subdirectory keeps the
distinction clean: cross-cutting docs at the top level, per-skill reference docs
one level deeper. The convention doc itself stays at the top level because it
*is* a cross-cutting doc, not an instance.

### D2. The frontmatter description, not the SKILL.md body, is the selection signal
The frontmatter `description` is loaded into every session's system prompt;
SKILL.md body is loaded only when the Skill tool is invoked. The description is
therefore the only text the agent sees when deciding whether to invoke. Its job
is intent-matching, not summarising subcommands.

### D3. No SKILL.md references from the description or the reference doc
If the agent sees a SKILL.md path, it may Read+follow it as plain instructions —
bypassing the Skill-tool harness (allowed-tools, user-confirmation surface). The
reference doc may name the skill (so the agent knows what to invoke) but must
not link to `SKILL.md`.

### D4. Size budgets
- Frontmatter `description`: ≤ 30 words. Multiplied across ~20 skills, every
  word counts as system-prompt overhead.
- Reference-doc *instances* (one per skill): ≤ 30 lines. Past that, the doc
  starts overlapping SKILL.md and negates progressive disclosure.
- The convention doc itself is meta-guidance, not an instance, so it is
  exempt from the 30-line budget (but should still be terse).

### D5. Intent-CTA shape
Description must (a) name the user-facing domain ("the backlog/changelog"), and
(b) include 2-3 example user phrasings. Example phrasings must be author-curated
hardcoded strings, never derived from user input (BACKLOG titles, branch names,
etc.) — the description flows into every session's system prompt and is an
LLM-context surface. The verb-list shape ("Add, modify, list, validate, retire,
or delete…") is what this task replaces.

### D6. YAML validity check (not just word count)
The Claude Code harness accepts unquoted YAML plain scalars containing
`Examples: "..."`, but strict parsers (libyaml/YAML::XS) reject the
unquoted form with "mapping values are not allowed in this context".
**Decision** (revised during exec, after running the actual parser):
require explicit double-quoted form with `\"` for internal double quotes.
Verified by loading the file through `YAML::XS` after the edit.

## Implementation Steps

### Step 1: Write the convention doc
- [ ] Create `.cwf/docs/skills/skill-reference-convention.md`
- [ ] Contents: purpose statement; location rule (D1, including explicit
  "per-skill instance docs MUST live in `reference/`, NOT at the top level");
  description shape and word budget (D2, D4, D5); reference-doc shape and
  line budget (D4); explicit prohibition on `SKILL.md` references (D3);
  hardcoded/author-curated examples rule (D5); YAML-validity expectation (D6).
- [ ] No fixed line budget on the convention doc itself, but keep it terse.

### Step 2: Write the first reference-doc instance
- [ ] Create `.cwf/docs/skills/reference/cwf-backlog-manager.md`
- [ ] Contents: 1-2 sentence purpose, 3-5 example user phrasings, no
  operational instructions, no `SKILL.md` link.
- [ ] Verify ≤ 30 lines (`wc -l` on the file).

### Step 3: Rewrite the cwf-backlog-manager frontmatter description
- [ ] Edit `.claude/skills/cwf-backlog-manager/SKILL.md` frontmatter only
  (lines 1-7). Body unchanged.
- [ ] New description follows D5 (names domain + 2-3 example phrasings, all
  author-curated).
- [ ] Word-count verification: extract just the value after `description: `
  with a Perl one-liner, then `wc -w` on the result; must be ≤ 30. This
  isolates the description from the YAML key and the rest of the frontmatter.
- [ ] No `SKILL.md` reference anywhere in the new description.
- [ ] YAML validity: load `.claude/skills/cwf-backlog-manager/SKILL.md`
  through a Perl YAML loader (`use YAML::PP; YAML::PP->new->load_file($path)`)
  and confirm no parse error. Mandatory because `cwf-manage validate` does
  not inspect frontmatter syntax.

### Step 4: File the follow-up backlog entry
- [ ] Invoke `cwf-backlog-manager` via the Skill tool to add a Low-priority
  entry titled "Roll intent-CTA description convention to remaining skills".
- [ ] Step 3 modifies only the description text (cosmetic; no behavioural
  change to subcommands), so the helper script is fully functional here.
- [ ] Body: brief reference to this task and the convention doc path.

### Step 5: Validation gate
- [ ] `cwf-manage validate` passes (project-wide consistency checks).
- [ ] Grep new docs for `SKILL.md` references — must return zero hits.
- [ ] Manual smoke test: read the new frontmatter description and confirm the
  intent-CTA shape would plausibly match "what's in the backlog" by inspection.

## Code Changes

### Before (`.claude/skills/cwf-backlog-manager/SKILL.md` lines 1-7)
```yaml
---
name: cwf-backlog-manager
description: Add, modify, list, validate, retire, or delete BACKLOG.md / CHANGELOG.md entries via the heading-tree helper.
user-invocable: true
allowed-tools:
  - Bash
---
```

### After (final wording, double-quoted per D6)
```yaml
---
name: cwf-backlog-manager
description: "Show or manipulate the project backlog/changelog. Examples: \"what's in the backlog\", \"add a backlog entry for X\", \"retire item Y for task N\"."
user-invocable: true
allowed-tools:
  - Bash
---
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.
All five steps must be done in this task — no deferral to follow-ups except the
one explicitly named in Step 4 (rolling to other skills).

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five planned steps executed. Step 3 produced one mid-exec deviation: unquoted
YAML form failed `YAML::XS`, fixed by switching to double-quoted form (D6 updated
accordingly). Plan otherwise held.

## Lessons Learned
The 4-subagent plan review caught the YAML risk preemptively. The recommendation
to quote the description value was the correct call — empirical strict-parser
testing confirmed it. See j-retrospective.md.
