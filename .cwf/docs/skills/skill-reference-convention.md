# Skill Reference-Doc Convention

A short per-skill reference doc helps the agent decide whether to invoke a
skill without ever Read+following `SKILL.md` outside the Skill-tool harness
(which would bypass `allowed-tools` and user-confirmation controls). This
file defines the convention for those docs and for the frontmatter
`description` that points at them.

## Location

- Per-skill instance reference docs MUST live at
  `.cwf/docs/skills/reference/<skill-name>.md` (one level below
  `.cwf/docs/skills/`).
- Instance docs MUST NOT live at the top level of `.cwf/docs/skills/` —
  that level is reserved for cross-cutting docs shared across all skills
  (e.g. `checkpoint-commit.md`, `plan-review.md`, `workflow-preamble.md`,
  this file).

## Frontmatter `description` shape

The `description` field in `.claude/skills/<skill>/SKILL.md` is loaded into
every session's system prompt. It is the only text the agent sees when
deciding whether to invoke a skill, so write it as an intent-CTA, not a
verb-list summary.

- ≤ 30 words. Multiplied across all skills, every word is system-prompt
  overhead.
- Must name the user-facing domain (e.g. "the backlog/changelog", "the
  status line", "the CWF init flow") so the agent can pattern-match user
  phrasings.
- Should include 2-3 example user phrasings inside quotes. Pattern-matching
  examples is more effective than abstract domain naming alone.
- MUST NOT reference `SKILL.md` paths. Naming the reference doc
  (`.cwf/docs/skills/reference/<skill>.md`) is acceptable; pointing at
  `SKILL.md` invites the agent to Read+follow it and defeats the harness.

## Reference-doc instance shape

- ≤ 30 lines per instance (`wc -l`). Beyond that the doc overlaps SKILL.md
  and negates progressive disclosure.
- Contents:
  1. 1-2 sentence purpose statement.
  2. 3-5 example user phrasings (verbatim, in quotes) covering the common
     invocations.
  3. Optional 1-2 line note on what the skill is NOT for, only if a
     near-miss confusion is likely.
- MUST NOT include operational instructions, subcommand reference, or
  links to `SKILL.md`. Operational detail belongs in `SKILL.md` and is
  loaded only when the Skill tool fires.

## Author-curated examples (security rule)

Example phrasings in both the frontmatter `description` and the reference
doc MUST be hardcoded by the task author. They MUST NOT be derived from
user-controlled sources (BACKLOG titles, branch names, task descriptions,
issue bodies, etc.). The description flows into every session's system
prompt; treating it as an untrusted-content surface would create a prompt-
injection channel via documentation.

## YAML validity

The Claude Code harness's YAML parser is lenient and accepts an unquoted
plain scalar containing `Examples: "..."` (colon-space + embedded double
quotes). Strict parsers (e.g. `YAML::XS`/libyaml) reject this form with
"mapping values are not allowed in this context". To stay portable across
parsers, the `description` value MUST be explicitly quoted when it contains
`Examples: "..."` patterns. Use double-quoted form with `\"` for internal
double quotes:

```yaml
description: "Show or manipulate ... Examples: \"what's in the backlog\", ..."
```

After writing a new `description`, load the SKILL.md through `YAML::XS`
(or any strict YAML 1.1/1.2 parser) to confirm — `cwf-manage validate`
does not inspect frontmatter syntax.

## This convention doc itself

This file is meta-guidance, not an instance, so it is exempt from the
30-line budget. Other top-level `.cwf/docs/skills/` files are similarly
cross-cutting and unbudgeted.
