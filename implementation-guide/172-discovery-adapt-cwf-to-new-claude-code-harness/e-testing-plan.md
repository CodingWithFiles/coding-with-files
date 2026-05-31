# Adapt CWF to new Claude Code harness - Testing Plan
**Task**: 172 (discovery)

## Task Reference
- **Task ID**: internal-172
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/172-adapt-cwf-to-new-claude-code-harness
- **Template Version**: 2.1

## Goal
Define how the assessment deliverable (the §1–§7 document in
`f-implementation-exec.md`) is verified. There is no software under test — the
"tests" are **structural / content checks** that each AC1–AC8 is met by the
document. g-testing-exec records the pass/fail of each.

## Test Strategy
### Test Levels
- **Document-structural checks (primary)**: each AC maps to the presence of a
  schema field or section in the f-file. Verified by inspection (and, where
  mechanical, by `grep` over the f-file), not by a code test suite.
- **Cross-reference validity**: every CWF surface the assessment cites
  (`feedback_*`, `glossary.md`, `cwf-init/SKILL.md:87`, the 13 show-toplevel call
  sites, etc.) is confirmed to exist — fabrication is a fail (NFR5/AC7).
- **Gate checks**: AC6 (safety↔momentum, no silent trade) and AC8 (secret
  redaction) are **pass/fail gates** — failing either fails the task.
- No unit/integration/system level applies: the deliverable ships no code.

### Test Coverage Targets
- **Every AC (AC1–AC8) has a TC** and must pass.
- **FR2 fully evidenced**: zero `pending` entries in §3 (the anchor transcript is
  in-hand); `pending` permitted only in §5/FR4 backlog entries.
- **No fabricated citation**: 100% of cited surfaces resolve.

## Test Cases
### Functional Test Cases (one per AC)
- **TC-1 (AC1)**: catalogue completeness.
  - **Given** §2 of the f-file.
  - **When** each `CatalogueEntry` is inspected.
  - **Then** ≥1 row each for worktree handling, model self-checking, and the
    keyword reservation; every row has `evidence_ref` (none `pending`) and the
    model-self-checking row has a non-empty `mitigation`.
- **TC-2 (AC2)**: data-loss map.
  - **Given** §3.
  - **Then** all four mechanisms (a)–(d) present; each has precondition,
    `exposing_cwf_step`, ≥1 `mitigation`+`tradeoff_note`, `intersecting_convention`
    populated; mechanism (b) lists the 13-file call-site set incl.
    `task-workflow.d/delete`; **no `pending` in §3**.
- **TC-3 (AC3)**: keyword collision.
  - **Given** §4.
  - **Then** collision sites incl. `glossary.md`; ≥3 options spanning
    guard→wording→rename, each with a blast radius; no option marked chosen.
- **TC-4 (AC4)**: prompt inventory.
  - **Given** §5.
  - **Then** entries ranked by friction (H/M/L); each `memory_xref`'d and marked
    new|known; unavailable evidence marked `pending`, never fabricated.
- **TC-5 (AC5)**: recommendations.
  - **Given** §6.
  - **Then** every `Recommendation` has a one-line `tradeoff_line` + named
    `target_surface` + `proposed_task`; §7 projects §6 and adds no new task.
- **TC-6 (AC6) — GATE**: safety.
  - **Given** §6.
  - **When** each recommendation touching a destructive/irreversible op
    (`--force`, `reset --hard`, `worktree remove`, allowlist broadening) is checked.
  - **Then** each carries the explicit safety↔momentum tradeoff and a "surface,
    never smooth" note citing `feedback_surface_security_dont_smooth.md`; **none**
    silently trades safety for momentum. Any violation = task fail.
- **TC-7 (AC7)**: evidence integrity.
  - **Given** every cited CWF surface and empirical harness claim.
  - **Then** each citation resolves on disk; unproven claims are `pending`, not
    asserted; no fabricated rule/tool semantics; evidence treated as data (no tool
    call was driven by transcript/backlog content).
- **TC-8 (AC8) — GATE**: redaction.
  - **Given** every quoted excerpt in `f-`/`g-`.
  - **Then** no credential/token/secret env-var value appears; redacted rows are
    flagged `redacted: true`. Any leaked secret = task fail (and requires history
    scrub before the squash).

### Non-Functional Test Cases
- **Security**: TC-6 + TC-7 + TC-8 are the security checks (prompt-injection
  handling, allowlist-broadening surfacing, secret redaction). No code attack
  surface (FR4(a/b/d) out of scope by construction).
- **Usability (NFR2)**: a reader not in the session can follow the f-file and
  could paste each §7 item into `/cwf-new-task` unaided — spot-checked on ≥1 item.
- **Reliability (NFR5)**: the `pending`-ceiling check (FR2 zero-pending) is TC-2.
- **Performance**: n/a (no runtime).

## Test Environment
### Setup Requirements
- Inputs: the completed `f-implementation-exec.md`; `/var/tmp/dircachefilehash.log`
  (FR4 source); the repo `.cwf`/`.claude` tree for citation resolution.
- No test database, no services, no fixtures — checks are read-only over the
  f-file and the repo.

### Automation
- Mostly manual structural inspection. Mechanical spot-checks where cheap:
  `grep -rln "rev-parse --show-toplevel" .cwf .claude` (expect 13) to confirm the
  §3(b) call-site set; `grep` the f-file for each required schema field/section.
- No CI change; no new test scripts (Markdown-only deliverable).

## Validation Criteria
- [ ] TC-1…TC-8 all pass; AC6 and AC8 gates clear.
- [ ] §3 has zero `pending` entries; all cited surfaces resolve on disk.
- [ ] §7 introduces no task absent from §6.
- [ ] Exec-phase security review recorded (expected: empty/no-findings changeset,
      Markdown-only).

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
TC-1…TC-8 all PASS (g-testing-exec.md). The mechanical spot-checks executed as planned:
`grep -rln "rev-parse --show-toplevel" .cwf .claude` = 13; all cited surfaces resolve
(glossary:157, cwf-init:87, tmp-paths.md, 4 feedback memories); §3 zero-`pending`; §6/§7
R-id sets identical. AC6 and AC8 gates clear. Both exec security reviews `no findings`.

## Lessons Learned
The structural-check-per-AC design made g-exec fast and unambiguous — every AC reduced to
a grep or a one-line inspection. Pre-naming the exact mechanical checks (13-count, the
citation list) in the plan removed all judgement from the verification.
