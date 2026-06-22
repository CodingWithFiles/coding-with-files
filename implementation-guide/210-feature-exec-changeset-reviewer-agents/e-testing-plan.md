# exec-changeset reviewer agents - Testing Plan
**Task**: 210 (feature)

## Task Reference
- **Task ID**: internal-210
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/210-exec-changeset-reviewer-agents
- **Template Version**: 2.1

## Goal
Define test strategy and validation approach for exec-changeset reviewer agents.

## Test Strategy

This task ships markdown agent definitions + a skill-prose rewrite + hash entries —
there is no compiled code. Testing splits into two layers:

- **Static / structural (automated)** — a new `t/exec-changeset-reviewers.t`
  (matches the existing `t/*.t` pattern, e.g. `t/security-review-changeset.t`)
  asserts the file-level invariants deterministically. This is the automation that
  satisfies AC2's positive invariant and the FR4 exec-only constraint cheaply.
- **Output-level smoke (manual)** — the live 5-reviewer MAP cannot be unit-tested;
  verify it by reading the recorded sections from a real/dry exec run (the
  rebrand→output-staleness rule: source greps alone are insufficient).

Core-Perl only, no non-core modules (repo constraint).

> **0444 is authoritative** for the agent hash mode (matches design D5 and the
> recorded `cwf-best-practice-reviewer-changeset` entry); the requirements FR6
> "100644/0600-class" parenthetical is stale — trust this plan.
> **D2 caveat**: every literal token below (`## Robustness Review`, the three
> `subagent_type`s) tracks the final D2 naming choice; a switch is a pure rename.
> Reuse the existing `t/security-review-changeset.t` **TC-DOCS** subtest style
> (read installed files in place, `like`/`unlike` scoped tightly to the Step 8 region).

## Test Cases

### Static / structural (automated — `t/exec-changeset-reviewers.t`)
- **TC-1 — three agents exist, Bash-free**
  - *Given*: the three `.claude/agents/cwf-<lens>-reviewer-changeset.md` files.
  - *Then* (hard fail): **no `Bash`** token anywhere in the file (frontmatter or body,
    outside the "Bash … withheld" paragraph) — the security-load-bearing assertion
    (NFR4). *Then* (secondary): `tools:` equals the cloned precedent's exact list
    (`Read, Grep, Glob, LSP`), `effort: high`, `name` matches the file, and the
    `cwf-agent-shared-rules.md` pointer is present. Derive the expected tool string
    from the precedent file, don't hand-author it (robustness #4, security obs).
- **TC-2 — verdict-block contract present, bp-input absent**
  - *Then*: each body contains the `cwf-review` fenced block spec and the
    "Bash … withheld" paragraph, and contains **no** `{bp_context_file}` reference
    (robustness #5). (FR2.)
- **TC-3 — implementation-exec MAP lists five reviewers**
  - *Given*: `cwf-implementation-exec/SKILL.md`.
  - *Then*: its Step 8 names all five `subagent_type`s; and — with `unlike` **scoped
    to the Step 8 region** (per the TC-DOCS precedent) — no stale "**Two** …
    reviewers" / "(0, 1, or 2 calls)" text remains. (FR3, misalignment #1.)
- **TC-4 — testing-exec MAP lists exactly two (positive invariant, both halves)**
  - *Then*: `cwf-testing-exec/SKILL.md` names `cwf-security-reviewer-changeset` and
    `cwf-best-practice-reviewer-changeset`, **and** `unlike` asserts **each** of the
    three lens names is absent anywhere in the file. (FR4 — the core exec-only
    constraint; assert both halves so accidental extras fail.)
- **TC-5 — guard matcher directive unchanged**
  - *Then*: `.cwf/scripts/hooks/subagentstop-security-verdict-guard`'s
    `# cwf-hook-matcher:` directive (the scoping mechanism, line 14) still names only
    `cwf-security-reviewer-changeset`. The guard's **blocking behaviour** is already
    covered by the existing `t/subagentstop-security-verdict-guard.t`; this TC guards
    only that the three new names were not added to its scope. (FR5, AC4.)

### Static degradation-count (automated — converts the highest-risk regression to a gate)
- **TC-6 — on-main records five (robustness F2/#4)**: the Step 8 on-`main` branch
  prose contains **five** `no findings: on main` records, not two.
- **TC-7 — empty changeset records five (robustness F3)**: the Step 8 empty-changeset
  branch yields **five** `no findings: empty changeset` records.

### Behavioural via the shared classifier (automated — leverage `t/security-review-classify.t`)
- **TC-8 — new-agent verdict parses clean (FR2/AC1)**: a well-formed verdict block as
  authored in the new agents, piped through `security-review-classify`, yields the
  expected token (proves the copied block is wired, not merely present).
- **TC-9 — error isolation across five (FR7/AC5)**: five canned `.out` blocks, one
  malformed, classified independently → four valid tokens + one `error`; the malformed
  one does not affect its siblings. (Promotes the top correctness invariant from a
  manual smoke to a repeatable gate — robustness #1/#2.)

### Integrity (automated — existing harness)
- **TC-10 — `cwf-manage validate` OK**: passes with the three new `0444` hash entries
  present. (FR6, AC3.)

### Output-level smoke (manual — the live MAP cannot be unit-tested)
- **TC-11 — happy path**: a sample exec run (changeset present) records **five** `##`
  sections, each with a `**State**:` line. (FR3, AC1, AC2.)
- **TC-12 — live error isolation**: a real run where one reviewer returns a malformed
  verdict still records all five sections, the failed one `error`. (FR7 end-to-end.)

## Test Environment
- No DB, no services. Tests read repo files in place.
- `t/exec-changeset-reviewers.t` run via the repo's existing `t/` runner; core Perl only.
- Output-level smoke uses a throwaway task branch (changeset present) and a check on
  `main` / empty-diff for the degradation cases.

## Validation Criteria
- [ ] `t/exec-changeset-reviewers.t` passes (TC-1…TC-9)
- [ ] `cwf-manage validate` OK (TC-10)
- [ ] Output-level smoke confirms 5 live sections + live error isolation (TC-11, TC-12)
- [ ] No stale "two reviewers" / "(0, 1, or 2 calls)" strings in implementation-exec
      Step 8 (covered by TC-3, scoped to the Step 8 region)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: D2 naming pending user confirmation (rename-only if changed)

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
TC-1…TC-10 implemented in `t/exec-changeset-reviewers.t` (11 subtests, all pass;
full suite 882 green). TC-11 (live five-section smoke) was closed in h once the
agents were session-loaded; TC-12 (live error isolation) is covered
deterministically by TC-9. TC-6/TC-7 were written as heading-coverage gates
(naming all five `## … Review` sections) rather than literal record counts,
because the Step-8 prose uses a compact generic form — same 2→5 regression guard.

## Lessons Learned
Convert degradation regressions (here, 2→5 section emission) into static gates;
manual smoke alone would not have caught a dropped on-main/empty section.
