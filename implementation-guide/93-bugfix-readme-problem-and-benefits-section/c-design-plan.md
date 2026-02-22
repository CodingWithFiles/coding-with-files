# readme-problem-and-benefits-section - Design
**Task**: 93 (bugfix)

## Task Reference
- **Task ID**: internal-93
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/93-readme-problem-and-benefits-section
- **Template Version**: 2.1

## Goal
Specify the exact content and insertion point for the "Why CWF?" section.

---

## Insertion Point

Insert between `## Overview` and `## Project Status` — after the reader knows what CWF is,
before they see maturity caveats. This gives the value proposition maximum prominence without
burying the beta warning.

---

## Section Design

**Title**: `## Why CWF?`

**Structure**: Problem statement paragraph → Benefits list

**Guiding principle**: Write for a developer who has used an AI coding assistant for a week
and already feels the pain. Name the symptoms they recognise, then show how CWF addresses each.

---

### Proposed content

```markdown
## The Problem With AI-Assisted Coding

AI coding agents are powerful in short bursts but lose the thread fast. Across multiple
sessions on a real project, you spend more time re-explaining context than actually
building — what decisions were made, why, and where things stand. Context windows fill,
sessions reset, and the agent starts contradicting earlier work. For solo developers
shipping serious software, this is a constant tax.

## What CWF Does

Coding with Files externalizes that context into structured markdown files that live in
your repo. Each task gets an implementation guide — phase-by-phase documents the agent
reads, picks up, and continues without being re-briefed. A feature like "add OAuth login"
becomes a directory with separate files for planning, design, implementation, and testing.
The agent always knows where it is, even after a restart.

## Why the Structure Matters

CWF enforces typed workflow phases — plan, design, implement, test, ship — and matches
them to the task type. A hotfix skips the design phase; a new feature doesn't. This
prevents the classic AI failure mode of jumping straight to code before the problem is
understood. It also uses token-efficient context inheritance, so subtasks get just enough
parent context to stay aligned without being overwhelmed — reducing context overhead by up
to 80% in some steps of task execution.

CWF gives the solo developer + AI agent pairing the discipline that software teams enforce
through standups, code review, and project management. It turns your AI coding agent from
a smart but forgetful assistant into a structured, accountable engineering partner.

On [Dan Shapiro's Five Levels of AI Software Development](https://www.danshapiro.com/blog/2026/01/the-five-levels-from-spicy-autocomplete-to-the-software-factory/),
CWF is designed to operate at **Level 3** (Developer as Manager) — you direct the agent
through structured phases and review its work rather than writing code yourself, with the
system targeting Level 3–3.3 of that scale.
```

---

## Key Decisions

- **Three headed paragraphs** not a bullet list — builds a narrative arc: problem → solution → why it works
- **"The Problem With AI-Assisted Coding"** names the pain immediately; more compelling than a question
- **Concrete example** ("add OAuth login becomes a directory…") makes it tangible
- **Token efficiency figure** (up to 80%) folded into "Why the Structure Matters" as a specific, credible claim
- **Closing sentence** earns its place: "smart but forgetful assistant → structured, accountable engineering partner"

## Decomposition Check
No — single file, one new section.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 93
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Design iterated twice: original bullet-list discarded for friend's narrative version; Dan Shapiro reference added. Final content implemented as designed.

## Lessons Learned
Narrative paragraphs outperform bullet lists for positioning copy. Starting from reader pain beats starting from features.
