# Subagent Tool Selection

This document describes the convention for selecting and composing tools when a
subagent (launched via the Agent tool) reads, searches, or lists files. It
applies within whatever tool grant the subagent has — if a tier is unavailable,
skip it and use the next-highest available option.

## Convention

**Do not use program composition with the Bash tool for simple tasks; use the built-in tools instead.**

Prefer earlier tiers over later ones:

1. **Built-in tools** — Read (use `offset` / `limit` for line ranges), Grep, Glob
2. **Skills** — when a slash-command skill encapsulates the operation and is
   available to the subagent type
3. **Bash with `rg` / `grep`** — only when the Grep tool can't express the
   search (e.g. multiline patterns Grep flags don't support)
4. **Bash with `sed` / `awk` / `cat` / `head` / `tail`** — only for
   transformations no built-in covers; never as substitutes for Read/Grep/Glob
5. **Last resort — Bash with program composition** (`find … -exec …`,
   multi-stage pipelines, `xargs`) — only when no combination of higher-tier
   options produces the result

When composition is genuinely required, chain by passing locations between
tools — Glob → Read, or Grep → Read with offset. Don't reproduce
search-then-extract inside a single Bash pipeline; the built-ins already
report locations the next tool can consume.

## Anti-patterns

Use the built-in instead:

| Bash you might reach for | Use this instead |
|---|---|
| `sed -n 'X,Yp' file` | Read with `offset=X limit=Y-X+1` |
| `cat file \| grep …` | Grep |
| `find … -name 'pat'` | Glob |
| `find … -exec cat {} \;` for a handful of files | Read once per file (batch parallel calls if multiple) |
| `for f in $(grep -l …); do …; done` | Grep first, then Read the matching paths |
| `head -n N file` / `tail -n N file` | Read with `offset` / `limit` |

## Why

Built-in tools have richer output (line-number prefixes, mode-aware
formatting). The harness tracks file state through them, so subsequent edits
and reads stay consistent. They avoid the off-by-one errors and quoting
hazards of shell pipelines, and reading whole files via `cat` or scanning
with `find … -exec` reads more bytes than the corresponding Read with
`offset`/`limit` or targeted Grep.

## Existing usage

- `.cwf/docs/skills/plan-review.md` — inlines a brief excerpt of this rubric
  in the prompt template for plan-review subagents
- `.cwf/docs/skills/workflow-preamble.md` Step 4 — the Read offset/limit
  pattern as already used by CWF skills outside subagent contexts
