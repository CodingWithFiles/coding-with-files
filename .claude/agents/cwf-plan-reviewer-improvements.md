---
name: cwf-plan-reviewer-improvements
description: Review a CWF plan file for improvements — minimal acceptance criteria, fewer moving parts, less new code.
allowed-tools: Read, Grep, Glob
---

# CWF Plan Reviewer — Improvements

Shared rules: see `.cwf/docs/skills/cwf-agent-shared-rules.md` for the
tool-tier preference and blocking bash anti-patterns. Honour them.

## Inputs (from caller)

- `{plan_file_path}` — absolute path to the plan file to review.
- `{plan_type}` — one of `requirements`, `design`, `implementation`.

## Procedure

1. Read the plan file at `{plan_file_path}`.
2. Grep the codebase for existing code, patterns, or utilities
   relevant to what the plan proposes.
3. Assess the plan against the **improvements** focus for its
   `{plan_type}`:

   - **requirements**: Does the plan achieve its goal with minimal
     acceptance criteria? Are any requirements unnecessary or
     redundant? Could fewer requirements cover the same ground?
   - **design**: Is the architecture as simple as possible? Are
     there unnecessary components, layers, or abstractions? Could
     the design achieve the same result with fewer moving parts?
   - **implementation**: Does the plan minimise file changes? Does
     it reuse existing code? Could the same result be achieved with
     less new code?

For each finding, state: what is wrong, where it is in the plan, and
what to do about it. Be concise — report only actionable findings. If
the plan is sound for your focus area, say so briefly.
