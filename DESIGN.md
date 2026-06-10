# CWF Design Rationale

This document explains **why** Coding with Files (CWF) is shaped the way it is. It stays
at the level of design intent and trade-offs; for operational detail it points elsewhere
rather than restating it:

- Workflow phases and their semantics: `.cwf/docs/workflow/`
- Architecture overview and conventions: `CLAUDE.md`
- Command reference: `COMMANDS.md`
- Config schema: `CWF-PROJECT-SPEC.md`

## Problem

Claude Code works best with focused context and natural file tools (Glob, Grep, Read).
A long-lived software task, however, accumulates planning, requirements, design,
implementation, testing, and retrospective material that does not fit in one window and
should not all be loaded at once. CWF's job is to hold that material on disk in a shape
that an agent can navigate precisely — reading only what the current step needs — while
keeping a durable, reviewable record of the work.

## Core Design Decisions

### Files on disk as the unit of state
Task state lives in Markdown files under `implementation-guide/`, not in a database or
in conversation memory. This is the system's namesake premise: the filesystem is the
source of truth, so any agent (or human) can re-derive exactly where a task stands by
reading its files, and the work survives context loss, compaction, and session restarts.

### Decimal-numbered task hierarchy
Tasks are directories named `<num>-<type>-<slug>`, numbered with decimal notation
(`1`, `1.1`, `1.1.1`) so nesting is encoded directly in the number and mirrored by the
directory tree. The number captures scope and parent/child relationships without a
separate index, and subtasks sit physically inside their parent. Decomposition is driven
by five universal signals (time, people, complexity, risk, independence) rather than ad
hoc judgement.

### Lettered a–j phase files, plan/exec split
Each task runs a subset of ten lettered phases, `a`-task-plan through `j`-retrospective.
The letter prefix gives every phase a stable, sortable filename and a one-to-one mapping
to the skill that owns it (`a-` → `/cwf-task-plan`, `f-` → `/cwf-implementation-exec`, …).
Planning and execution are deliberately separate files (`d-implementation-plan` vs
`f-implementation-exec`, `e-testing-plan` vs `g-testing-exec`): the plan is committed and
reviewed before the work it describes, so intent is recorded independently of outcome.
Task types select which phases apply — a chore skips requirements, design, rollout, and
maintenance; a hotfix keeps rollout but drops design — so the ceremony matches the risk.

### Central template pool with per-type symlinks
Phase templates have a single source of truth in `.cwf/templates/pool/`, and each task
type exposes its file set through symlinks. The authoritative per-type set lives in code
(`%WORKFLOW_FILES` in `CWF::WorkflowFiles::V21`), not in prose, so the template laid down
for a task and the set the validator expects cannot drift apart. This is the Rule of
Three applied to templates: one definition, many consumers.

### Token-efficient context inheritance via structural maps
A subtask does not inherit its parents by reading their files in full. Instead it
receives a structural map — headers, line ranges, and the Read parameters needed to fetch
any section on demand — costing ~50-100 tokens per parent instead of ~500-1000. The agent
keeps agency over what to read in depth; the system just makes the cheap overview the
default. Status markers on the map flag how reliable each parent's context is.

### Helper scripts for deterministic work, the LLM for judgement
Filesystem traversal, hierarchy resolution, status aggregation, version parsing, and
config validation are handled by a suite of Perl helper scripts under
`.cwf/scripts/command-helpers/`. Anything deterministic belongs in a script — it is
faster, testable, and not subject to model variance — leaving the LLM to make the
judgement calls (what to decompose, what a plan should contain, whether a change is
sound). Perl is chosen for portability to system Perl on macOS, using core modules only.

### Progressive disclosure
Skills reference documentation under `.cwf/docs/` rather than duplicating it, and helper
scripts surface structural information rather than full content. The reader pulls detail
when it is relevant instead of paying for it up front. This same principle governs this
document: it links to the operational sources instead of copying them, so there is one
place to maintain each fact.

## Security Model

CWF treats its own installed files as integrity-critical. Helper scripts and skills are
held at minimum permissions (`u+rx`, typically `0500`) and every hash-tracked file has a
recorded SHA256 in `.cwf/security/script-hashes.json`. `cwf-manage validate` (and
`/cwf-security-check`) compare on-disk content against those hashes; a content change
that is not accompanied by a matching hash refresh in the same commit fails validation.

The guiding principle is **surface, never smooth**: integrity friction is a feature, not
a nuisance. `fix-security` will restore expected permissions only when the recorded hash
still matches — it is explicitly *not* a button that clears a tampering warning. There is
no tool that turns a content-mismatch signal into a silent no-op, by design.

## Installation Model

CWF is laid into a host repository by a `read-tree` operation (the default): it writes
the `.cwf/` tree and the skill set without creating a merge commit, keeping the host's
history clean. A plain file copy is the fallback for static or air-gapped installs.
Git-subtree installation is deprecated and refused — it forced a merge commit into the
host's history for no benefit the read-tree laydown does not already provide. Versions
are tracked with `git describe` (e.g. `v1.1.187-5-gcea1c19`) so an installed tree's
provenance is always recoverable.

## What This Buys

- **Resumability**: state is on disk, so work survives context loss and any agent can
  re-derive it.
- **Reviewability**: plans are committed before execution; the phase files are a durable
  audit trail of decisions and their outcomes.
- **Scale without context explosion**: structural maps and section extraction keep token
  cost roughly flat as a task tree grows.
- **Low drift**: per-type file sets and the config schema are defined once in code and
  enforced by validation, so documentation and behaviour stay aligned.
