# Reviewer agents prefer tools over Bash - Testing Execution
**Task**: 186 (chore)

## Task Reference
- **Task ID**: internal-186
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/186-reviewer-agents-prefer-tools-over-bash
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready
- [x] Execute test cases sequentially (in-session: TC-1..TC-7)
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps (none)
- [x] Update status (Finished for in-session; TC-8..TC-10 deferred to fresh session)

## Test Results

### Functional Tests (in-session)

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1 | No ignored key remains | zero `allowed-tools:` under `.claude/agents/` | zero matches | PASS |
| TC-2 | Honoured key, exact set | five `tools: Read, Grep, Glob, LSP, Bash`; no Edit/Write | five exact lines, no deviation, no Edit/Write | PASS |
| TC-3 | Grant matches documented invariant | `security-review.md` enumerates the same set, drops "No Bash", adds FR4(c) | grant at line 12, no "No Bash", FR4(c) at line 14 | PASS |
| TC-4 | Guidance sharpened | tier 1 LSP, tier 2 markdown-reader, "strongly prefer" lead, tiers 3–5 retained, mirrored in both docs + anti-pattern rows | all present in shared-rules + subagent-tool-selection | PASS |
| TC-5 | Integrity clean | `cwf-manage validate` → OK | `validate: OK` | PASS |
| TC-6 | CHANGELOG updated | Task 186 entry present | entry at line 5 | PASS |
| TC-7 | Suite green | `prove t/` all pass | Files=61, Tests=706, Result: PASS | PASS |

### Fresh-session acceptance (DEFERRED — new session required)

TC-8, TC-9, TC-10 cannot run in this session: agent definitions are
session-cached (`feedback_agent_def_session_cache`), so the
`allowed-tools:`→`tools:` grant change is only observable after `/clear`
or a fresh session. This session's registry still reflects the
*pre-change* cached defs. Run these in a new session on this branch:

| Test ID | Test Case | Expected | Status |
|---------|-----------|----------|--------|
| TC-8 | Registry shows exact grant | each reviewer shows exactly `Read, Grep, Glob, LSP, Bash`, excludes Edit/Write; `LSP` accepted (no load error) | DEFERRED |
| TC-9 | Reviewer functions + reaches markdown-reader | a plan reviewer runs and can invoke markdown-reader (or run its script via Bash) | DEFERRED |
| TC-10 | Changeset reviewer verdict intact | `cwf-security-reviewer-changeset` emits one well-formed `cwf-review` block that `security-review-classify` parses | DEFERRED |

### Non-Functional Tests
- **Security**: TC-2/TC-3 confirm the tightening from *all tools* to a
  defined set with no `Edit`/`Write`. Bash retained by deliberate choice
  (guided, not enforced). The f-phase exec security review returned
  `no findings`; this g-phase review is below.
- **Reliability**: deferred to TC-9 (fresh session).
- **Performance / Usability**: N/A (documentation/frontmatter change).

## Test Failures

None.

## Coverage Report

- Every changed file has at least one asserting check (TC-1..TC-7).
- Critical path (grant fix on all five agents): 100% (TC-2).
- In-session validation criteria (TC-1..TC-7): **7/7 PASS**.
- Fresh-session criteria (TC-8..TC-10): deferred, must be recorded before
  the task is considered fully accepted.

## Security Review

**State**: no findings

I have the full picture. The changeset is the testing-exec phase changeset for Task 186, which encompasses the entire diff for the task (doc edits, frontmatter grant changes, hash refresh, CHANGELOG, and the workflow files). Let me reason through the threat categories.

This task changes five reviewer agent frontmatter declarations, updates two tool-tier guidance docs, updates the security-review threat-model doc, refreshes six sha256 hashes, and adds a CHANGELOG entry plus workflow process files. There is no Perl, no shell command construction, no env-var handling, and no executable code of any kind being added or modified. The substantive security-relevant change is a tool-grant change on the reviewer agents.

**Hash/permission integrity** — Out of my scope per the §"Boundary vs `cwf-manage validate`" carve-out; the diff shows a same-commit, self-consistent sha256 refresh for the six tracked files, and TC-5 records `validate: OK`. Nothing to flag.

**(a) Bash injection / unsafe command construction** — No shell command is constructed anywhere in the diff. No `system()`, no backticks, no string interpolation into commands. Not applicable.

**(b) Perl helpers consuming git/user output without `-z`** — No Perl is added or modified. The `script-hashes.json` change is pure data. Not applicable.

**(c) Prompt injection via user-supplied strings** — This is the live category. The change grants `Bash` (and `LSP`) to five reviewer agents that ingest untrusted input (plan files, diffs carrying task descriptions and `{arguments}`). Granting `Bash` to an untrusted-content-ingesting agent widens the prompt-injection blast radius from read/search to arbitrary command execution. The diff handles this in the "surface, don't smooth" manner the project requires: `security-review.md:14` adds an explicit named **Residual threat (FR4(c))** paragraph stating exactly this — untrusted content, Bash widens the blast radius to command execution, mitigations are tool-tier guidance plus the absence of `Edit`/`Write`. The `d-implementation-plan.md` Security Notes and the CHANGELOG repeat the disclosure, and a narrowing follow-up (remove Bash, or settings-permissions Skill scoping) is recorded. This is a disclosed, deliberately-accepted posture, not an actionable finding.

One thing worth noting for completeness, but which is not a defect in this diff: the *net* posture is a tightening, not a loosening. The `allowed-tools:` key was silently ignored on subagents, so the five reviewers were in fact inheriting **all tools** (including `Edit`/`Write`/`Agent`/`WebFetch`). Moving to the honoured `tools: Read, Grep, Glob, LSP, Bash` removes `Edit`/`Write` and everything else. So relative to the actual prior state, the prompt-injection blast radius shrinks (Edit/Write/Agent/WebFetch are dropped); relative to the *intended* no-Bash state it grows by `Bash`. Both framings are disclosed in the diff.

**(d) Unsafe environment-variable handling** — No env-var handling introduced or modified. Not applicable.

**(e) Pattern-based risks (safe-here-but-risky-elsewhere)** — The f-phase exec review already surfaced one carve-out note that applies equally to this testing-exec changeset, and I concur with it: the grant `tools: Read, Grep, Glob, LSP, Bash` is now the established copy-paste template for CWF reviewer agents, applied uniformly across all five. It is safe **here** because the callsite invariant holds — these agents are read-only by procedure and `Edit`/`Write` are withheld, so Bash can only launch the read-only markdown-reader skill / `rg`. The risk: if a future agent definition copies this `tools: …, Bash` grant into a context where `Edit`/`Write` are *also* granted, the "guided, not enforced" no-mutation property collapses entirely — Bash plus Edit/Write on untrusted-content ingestion is a full command-execution-plus-persistence surface with nothing structural left to stop it. Framed per the required carve-out: **safe here because Edit/Write are withheld and the procedures are read-only; audit any future reviewer/agent definition that copies the `tools: …, Bash` grant to confirm it likewise withholds Edit/Write.** This is an audit pointer for future uses, consistent with the narrowing follow-up the doc itself flags — not a defect in the present diff.

The testing-exec workflow file (`g-testing-exec.md`) itself records TC-1..TC-7 passing and TC-8..TC-10 (the fresh-session grant verification) correctly deferred, because agent-def edits are session-cached — that deferral is a process correctness matter, not a security concern, and it is honestly disclosed.

Verdict: this is a doc/frontmatter/data-only changeset. The sole security-relevant change is a tool-grant change that the diff itself discloses, names against FR4(c), attributes to a deliberate user decision, and pairs with a recorded narrowing follow-up. The hash refresh is self-consistent and out of my scope to re-verify. No undisclosed or actionable security concern remains. The category (e) note is an audit pointer with the required safe-here framing, carrying no actionable defect.

```cwf-review
state: no findings
summary: Doc/frontmatter/data-only diff; the sole security-relevant change (reviewer Bash+LSP grant, net a tightening from silent all-tools) is explicitly disclosed and named against FR4(c), with no Edit/Write granted and a self-consistent hash refresh. One category-(e) audit pointer (safe here: Edit/Write withheld, read-only procedures) carries no actionable defect.
```

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
