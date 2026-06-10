# Reviewer agents prefer tools over Bash - Testing Plan
**Task**: 186 (chore)

## Task Reference
- **Task ID**: internal-186
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/186-reviewer-agents-prefer-tools-over-bash
- **Template Version**: 2.1

## Goal
Verify the guidance sharpening (LSP + markdown-reader) and the
`allowed-tools:`→`tools:` grant fix (`Read, Grep, Glob, LSP, Bash`): the
reviewers carry the defined grant, the guidance/docs are consistent, no
procedure breaks, and integrity is intact.

## Test Strategy
### Test Levels
- **Static assertions** (automatable, this session): grep/text checks on the
  changed files + `cwf-manage validate`.
- **Integrity**: `cwf-manage validate` (sha256 + recorded-permission ceiling).
- **Regression**: full `prove t/` — no test depends on the old `allowed-tools:`.
- **Fresh-session acceptance** (manual, **new session required**): agent defs
  are session-cached (`feedback_agent_def_session_cache`), so the grant change
  is only observable after `/clear` or a new session. This session's registry
  reflects the *pre-change* cached defs.

### Coverage Targets
- Every changed file has at least one asserting check.
- Critical path (grant fix on all five agents): 100%.
- No numeric code-coverage target (documentation/frontmatter change).

## Test Cases
### Functional / Static (this session)
- **TC-1 — No ignored key remains**
  - **Given**: the five `.claude/agents/cwf-*reviewer*.md` files post-edit.
  - **When**: `grep -n 'allowed-tools:' .claude/agents/`.
  - **Then**: zero matches.
- **TC-2 — Honoured key present, exact set**
  - **Given**: same five files.
  - **When**: grep `^tools:` across them.
  - **Then**: exactly five lines, each exactly
    `tools: Read, Grep, Glob, LSP, Bash` (no `Edit`/`Write`).
- **TC-3 — Grant matches the documented invariant (now updated)**
  - **Given**: the updated `security-review.md` grant enumeration.
  - **When**: compare the TC-2 grant to that enumeration.
  - **Then**: identical (`Read, Grep, Glob, LSP, Bash`); `security-review.md`
    no longer asserts "No `Bash`" and records the guided-Bash posture.
- **TC-4 — Guidance sharpened**
  - **Given**: `cwf-agent-shared-rules.md` and `subagent-tool-selection.md`.
  - **When**: read the Tool-tier preference / tier sections.
  - **Then**: tier 1 names `LSP` ("when a language server is configured") and
    `Read` for structured text; tier 2 names the **markdown-reader** skill;
    shared-rules lead says "strongly prefer … over raw Bash"; tiers 3–5
    retained (reviewers hold Bash).
- **TC-5 — Integrity clean**
  - **Given**: all edits + the six refreshed sha256 entries.
  - **When**: `cwf-manage validate`.
  - **Then**: `validate: OK`.
- **TC-6 — CHANGELOG updated**
  - **Given**: `CHANGELOG.md`.
  - **When**: grep for the Task 186 entry.
  - **Then**: an entry exists describing the fix + the security note.

### Regression
- **TC-7 — Suite green**
  - **Given**: `t/`.
  - **When**: `prove t/`.
  - **Then**: all pass; no test referenced the old `allowed-tools:` key.

### Fresh-session acceptance (new session required)
- **TC-8 — Registry shows the exact grant**
  - **Given**: a fresh session with this branch checked out.
  - **When**: inspect the agent registry / tool grant for the five reviewers.
  - **Then**: each shows **exactly** `Read, Grep, Glob, LSP, Bash` and
    excludes `Edit`/`Write` — not merely "not All tools" (the old bug
    *silently* produced "All tools", so assert the positive enumeration).
    Also confirm `LSP` was accepted as a grant token (no load error).
- **TC-9 — Reviewer functions and can reach markdown-reader**
  - **Given**: the grant from TC-8 in a fresh session.
  - **When**: invoke one plan reviewer (e.g. `cwf-plan-reviewer-misalignment`)
    on an existing plan file, and confirm it can invoke the markdown-reader
    skill (or run its script via Bash) to read a section.
  - **Then**: the review completes normally and markdown-reader is reachable.
    If the markdown-reader skill is not reachable at runtime, fall back to
    declaring it via a `skills:` field (documented remediation) — the core
    grant fix still holds.
- **TC-10 — Changeset reviewer verdict block intact under the new grant**
  - **Given**: `cwf-security-reviewer-changeset` with the new grant, fresh session.
  - **When**: invoke it on a sample `.out` changeset.
  - **Then**: it emits exactly one well-formed `cwf-review` block that
    `security-review-classify` parses to a valid state — granting Bash must
    not disturb the deterministic verdict path or the SubagentStop guard.

## Non-Functional Test Cases
- **Security**: TC-2/TC-3/TC-8 — the change is a tightening from *all tools*
  to a defined set; confirm no `Edit`/`Write`. Bash is retained by deliberate
  choice (guided, not enforced); runtime Skill access is unchanged from the
  prior all-tools state and is out of scope to narrow here.
- **Reliability**: TC-9 — graceful operation under the defined grant.
- **Performance / Usability**: N/A (documentation/frontmatter change).

## Test Environment
- The repo on branch `chore/186-reviewer-agents-prefer-tools-over-bash`.
- No DB, no external services. TC-8/TC-9 require a **fresh** Claude Code
  session (agent-def cache); all other TCs run in-session.

## Validation Criteria
- [ ] TC-1…TC-7 pass in-session (static + integrity + regression).
- [ ] TC-8…TC-9 pass in a fresh session and are recorded in g-testing-exec.
- [ ] `cwf-manage validate` clean.
- [ ] No regression in `prove t/`.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
TC-1..TC-7 ran in-session: 7/7 PASS (zero `allowed-tools:`, five exact `tools:`
grants with no Edit/Write, docs consistent, `validate` clean, 706 tests green).
TC-8/9/10 deferred to a fresh session (agent-def cache) and recorded as DEFERRED in
`g-testing-exec.md`.

## Lessons Learned
Writing TC-8/9/10 as fresh-session-only from the start prevented any in-session
registry output from being misread as acceptance. Full learnings in
`j-retrospective.md`.
