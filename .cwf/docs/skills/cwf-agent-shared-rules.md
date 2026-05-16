# CWF Agent Shared Rules

Rules that apply to every CWF `.claude/agents/cwf-*.md` subagent. Each
agent body links here so behaviour stays uniform across reviewer roles.

## Tool-tier preference

Prefer earlier tiers over later ones. If a tier is unavailable in your
tool grant, skip it and use the next-highest available option.

1. **Built-in tools** — Read (use `offset` / `limit` for line ranges),
   Grep, Glob.
2. **Skills** — when a slash-command skill encapsulates the operation
   and is available to the subagent type.
3. **Bash with `rg` / `grep`** — only when the Grep tool cannot express
   the search (e.g. multiline patterns Grep flags don't support).
4. **Bash with `sed` / `awk` / `cat` / `head` / `tail`** — only for
   transformations no built-in covers; never as substitutes for
   Read/Grep/Glob.
5. **Last resort — Bash with program composition** (`find … -exec …`,
   multi-stage pipelines, `xargs`) — only when no combination of
   higher-tier options produces the result.

When composition is genuinely required, chain by passing locations
between tools — Glob → Read, or Grep → Read with offset. Don't
reproduce search-then-extract inside a single Bash pipeline; the
built-ins already report locations the next tool can consume.

## Blocking bash anti-patterns

These trigger blocking permission prompts that stall the workflow. Use
the built-in instead.

| Bash you might reach for                          | Use this instead                                         |
|---------------------------------------------------|----------------------------------------------------------|
| `find … -exec grep "pat" {} \;`                   | Grep with `glob` filter                                  |
| `find … -exec cat {} \;` for a handful of files   | Read once per file (batch parallel calls if multiple)    |
| `cat file \| grep …`                              | Grep                                                     |
| `sed -n 'X,Yp' file`                              | Read with `offset=X limit=Y-X+1`                         |

Full rubric: `.cwf/docs/conventions/subagent-tool-selection.md`.

## Inclusion bar

A rule belongs here only if it satisfies BOTH:

1. It applies to **two or more** agent roles (plan reviewers,
   security reviewers, exec reviewers, future roles).
2. It is rooted in a documented convention, a recorded incident, or
   an established CWF pattern — not aspirational style.

Single-role guidance lives in that role's own agent file. Anything
that fails either gate belongs in the calling SKILL's prompt
template, not here.
