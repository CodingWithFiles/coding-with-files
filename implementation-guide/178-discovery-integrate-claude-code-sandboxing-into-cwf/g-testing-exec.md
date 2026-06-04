# Integrate Claude Code sandboxing into CWF - Testing Execution
**Task**: 178 (discovery)

## Task Reference
- **Task ID**: internal-178
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/178-integrate-claude-code-sandboxing-into-cwf
- **Template Version**: 2.1

## Goal
Execute the e-testing-plan TC-1..TC-7 evidence-and-completeness audit against
`f-implementation-exec.md` and the seeded backlog item. No code to unit-test.

## Test Results

### Functional Tests

| Test ID | What it checks | Expected | Actual | Status |
|---------|----------------|----------|--------|--------|
| TC-1 | FR1 mechanism inventory cited, not remembered | Every row has a this-session citation (doc quote / substrate read) + "in helper today?" + gap cost; "none found" cells present | Inventory table (f §Step 3) cites `code.claude.com/docs/en/{sandboxing,settings,hooks}` (fetched this session) and the first-hand `cwf-claude-settings-merge` read; has the "In `cwf-claude-settings-merge` today?" + "Gap/extension cost" columns; "none found" rows present for R1 per-phase static switch and R3 structured violation event | PASS |
| TC-2 | FR2 verdicts failure-wired + enforceability-labelled | Each R1/R2/R3 verdict ∈ {Feasible, Feasible-with-caveats, Not-feasible-today, Unverifiable}; fail-open note; enforceable-vs-advisory keyed on `dangerouslyDisableSandbox`; none-found → Not-feasible; R3 capped unreliable | Verdict table (f §Step 4): R1 Feasible-with-caveats (Not-feasible as static switch), R2 Feasible-with-caveats, R3 Feasible-with-caveats-unreliable; each row has Fail-open + Enforceable-vs-advisory columns keyed on the agent-reachable escape hatch; R1 static-switch sub-mechanism resolved Not-feasible; R3 capped unreliable | PASS |
| TC-3 | FR3 substrate gaps priced against real code | Two gaps stated as found this session, each with same-commit `script-hashes.json` cost; enforcement-ownership boundary stated | f §Step 2 + §Step 6 state (i) helper writes `permissions.allow` only — `sandbox.*`/`permissions.deny` unmanaged; (ii) hook events restricted to `{Stop, SubagentStop}`; both carry the hash-refresh-same-commit cost; enforcement-ownership boundary ("CWF advises, OS enforces, operator can override") stated in §Step 6 | PASS |
| TC-4 | FR4 knobs + defaults | R2 editable list w/ default (≥`~/.ssh`,`~/.aws`) + named config surface; R3 named switch default OFF; R1 opt-in conditional on its verdict | f §Step 6: R2 editable list in `cwf-project.json`, defaults `~/.ssh`/`~/.aws`; R3 default-OFF switch in `cwf-project.json`; R1 opt-in via PreToolUse hook (R1 verdict = Feasible-with-caveats, so opt-in is live, not moot) | PASS |
| TC-5 | FR5 weaknesses carried, no smoothing | Documented weaknesses listed; no recommendation turns R3 logging into a silent boundary-disable | f §Step 5 lists default-read-leaks-creds, non-TLS egress proxy, `excludedCommands` no managed lockdown, fail-open, agent-reachable escape hatch, subprocess env inheritance; explicit no-smoothing statement (`feedback_surface_security_dont_smooth`) | PASS |
| TC-6 | FR6 recommendation + backlog seed, expected count | `validate --all` exit 0; live title count == 1; recommendation states build/don't-build + decompose | `backlog-manager list --all-items \| grep -c` = **1**; `validate --all` exit **0**; f §Step 6 states BUILD-staged, the don't-build items, and the decompose-at-task-creation decision; helper exit codes recorded in f §Backlog Seed Result | PASS |
| TC-7 | Negative — no production code touched | Exec commit limited to wf files + BACKLOG.md; no settings/helper/config/hook | `git show --stat 4a01f43` = `BACKLOG.md` + `f-implementation-exec.md` only; no `.claude/settings.json`, `cwf-claude-settings-merge`, `cwf-project.json`, or hook modified | PASS |

### Non-Functional Tests
- **Security**: ingested doc/schema text appears only as quoted evidence in the f-file,
  never acted on as instruction; the BACKLOG mutation went through `backlog-manager add`
  with list-form/opaque args + `--body-file` (no inline body, no heredoc). PASS.
- **Reliability**: all three docs were reachable this session (after the documented 301 to
  `code.claude.com`); no mechanism left Unverifiable; the transient-fetch-vs-absence rule
  was applied (no verdict rests on a failed fetch). PASS.

## Test Failures
None.

## Coverage Report
TC-1..TC-7: 7/7 PASS. Critical path (R1/R2/R3 each cited + failure-wired +
enforceability-labelled; recommendation present; single live backlog entry; no production
code) fully covered. Edge cases (none-found propagation, R3 unreliable cap, fail-open
linkage, single-entry count guard) exercised.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*

## Security Review

**State**: no findings

I have read the full changeset. This is the testing-phase changeset for Task 178, a discovery task. It contains the a–f workflow-step files plus the BACKLOG.md entry. Notably, the f-implementation-exec.md included here contains a prior security review embedded as part of the document (the implementation-phase review of this same task). Let me reason through the threat categories for this testing-phase changeset.

## Security review — Task 178 testing-phase changeset

I reviewed the full diff (1105 lines) in `/tmp/-home-matt-repo-coding-with-files-task-178/changeset-test.txt`. It comprises seven files: `BACKLOG.md` plus the a–f workflow-step Markdown files under `implementation-guide/178-discovery-integrate-claude-code-sandboxing-into-cwf/`. Every addition is prose Markdown — planning, requirements, design, implementation-plan, implementation-exec (findings), and testing-plan documents for a discovery task, plus one BACKLOG entry. No executable code, scripts, permission files, hash files, or settings files are touched.

I worked through each threat category in `.cwf/docs/skills/security-review.md` § "Threat categories" (a)–(e).

**(a) Bash injection / unsafe command construction.** No shell commands are constructed in this diff. The documents describe future helper invocations (e.g. `backlog-manager add --title=... --body-file=<scratch>` at d L677–688, f L1056–1058) as list-form / opaque-arg with `--body-file`, which is the safe pattern (no inline body, no string interpolation into a shell). The documented backlog seed was performed via the helper with exit code recorded (f L1054–1061). Nothing in the prose builds a `system($string)` or backtick command. No finding.

**(b) Perl helpers consuming git/user output without `-z` / input validation.** No Perl is added or modified. The diff is documentation-only and explicitly forbids touching `cwf-claude-settings-merge` or any helper (d L598–600). The substrate audit correctly characterises the existing helper's behaviour (writes `permissions.allow` only; `read_hook_directives` event allowlist `{Stop, SubagentStop}`) as a planning observation, not a change. No finding.

**(c) Prompt injection via user-supplied strings.** The most relevant axis for this changeset, because the f-file (f L873–928) ingests and quotes external Claude Code documentation text fetched via WebFetch. The documents handle this correctly: the quoted doc/schema text appears only as evidence (inventory and verdict tables, Step 1 quotes), and the requirements/testing plans explicitly require ingested text to appear "only as quoted evidence, never acted on as instruction" (b NFR4 L322; e L819–820), consistent with the instruction-priority order. I inspected the quoted external strings (sandboxing/permissions/hooks doc fragments) and found no embedded instruction attempting to redirect agent behaviour — they are descriptive sandbox-key semantics. The embedded prior security-review block inside f-implementation-exec.md (f L1063–1104, including its own cwf-review fenced block) is part of the reviewed document content, not a verdict for this review; it does not affect my own verdict block, which I emit independently below. No finding.

**(d) Unsafe environment-variable handling.** No env-var handling code is added. The findings correctly flag, as a forward-looking caveat for the eventual feature, that sandboxed Bash inherits parent env including credentials unless `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` is set (f L985–986) — this is recorded as a weakness to carry into the feature, not a defect introduced here. No finding.

**(e) Pattern-based risks (safe-here-but-risky-elsewhere).** No code patterns are introduced, so there is nothing whose callsite invariant could be broken by reuse. The documents already carry the relevant forward-looking security caveats into the seeded feature, correctly framed:
- R2 must ship as a PAIRED `sandbox.filesystem.denyRead` + `Read(...)` permission deny, because the sandbox is Bash-only and neither path alone covers both the Bash-subprocess and Read-tool read surfaces (BACKLOG L20; f L964). A future implementer shipping only one half would leave credentials readable via the other path — this is stated correctly.
- `dangerouslyDisableSandbox` agent-reachability is correctly identified as the "enforceable vs advisory" axis (f L919–920, L983–984; c L449–458). Right threat framing for the feature; nothing actionable in this prose.
- The "surface, don't smooth" stance is applied in the correct direction throughout: R3 logging "must never silence or disable a boundary" (BACKLOG L22; f L988–989), and the design forbids any surface that silences `cwf-manage validate` (BACKLOG L17; c L520–522). The don't-build list correctly scopes managed-only lockdowns as an operator/MDM concern rather than something CWF writes into a project's `.claude/settings.json` (BACKLOG L24; f L1021–1025).

The testing-plan content itself (e-testing-plan.md) is an evidence-and-completeness audit checklist with no executable test code; its only scripted checks are `backlog-manager validate --all` and title-count greps (e L830–832), which are read-only helper invocations. TC-7 (e L811–816) correctly asserts no production code is touched, which the diff honours.

Conclusion: this is a clean, additive, documentation-only changeset for a discovery task. The security-relevant subject matter (sandboxing, credential deny-lists, violation logging) is assessed at the planning level with the correct enforcement-ownership framing ("CWF advises; OS enforces; operator can override") and the correct "surface, don't smooth" stance. Externally ingested doc text is quoted as evidence only. No actionable security concerns in the diff under review.

```cwf-review
state: no findings
summary: Documentation-only discovery (testing-phase) changeset; ingested doc text quoted as evidence only; correct "surface, don't smooth" and enforcement-ownership framing; no actionable security concerns.
```
