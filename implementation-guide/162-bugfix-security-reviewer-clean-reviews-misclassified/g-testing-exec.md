# security-reviewer clean reviews misclassified - Testing Execution
**Task**: 162 (bugfix)

## Task Reference
- **Task ID**: internal-162
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/162-security-reviewer-clean-reviews-misclassified
- **Template Version**: 2.1

## Goal
Execute the test plan in e-testing-plan.md and record results.

## Test Results

### Functional — Classifier (`t/security-review-classify.t`) — the acceptance gate
`prove t/security-review-classify.t` → **18/18 PASS**.
- TC-C1 (core bug fix): clean verdict after heavy reasoning prose → `no findings`. **PASS** — this is the case that historically misclassified as `error`.
- TC-C2/C3: `findings`/`error` states. **PASS**.
- TC-C4: markdown noise (bold/backtick/blockquote) around the block. **PASS**.
- TC-C5/C6: empty stdin / prose-only → `error`. **PASS**.
- TC-C7: invalid `state:` value → `error`. **PASS**.
- TC-C8: whitespace-only `state:` → `error` (not silently dropped). **PASS**.
- TC-C9: unterminated fence → `error`. **PASS**.
- TC-C10/C11: two valid blocks (same / conflicting) → `error`. **PASS**.
- TC-C12: echoed non-token example alone → `error`; alongside one real block → real state. **PASS**.
- TC-C13: case/whitespace normalisation. **PASS**.
- TC-C14: `--help`. **PASS**.

### Functional — SubagentStop hook (`t/subagentstop-security-verdict-guard.t`)
`prove t/subagentstop-security-verdict-guard.t` → **18/18 PASS**. Every case asserts exit 0 (fail-open / never traps).
- TC-H1: valid `no findings` block → allow (empty stdout). **PASS**.
- TC-H2: no valid block, not looping → block with fixed-literal reason; valid JSON. **PASS**.
- TC-H3: no valid block but `stop_hook_active=true` → allow. **PASS**.
- TC-H4: malformed stdin → fail-open allow. **PASS**.
- TC-H5: missing `last_assistant_message` → fail-open allow. **PASS**.
- TC-H6: valid `findings` block → allow. **PASS**.
- TC-H7: injection-shaped message → blocks, reason contains no message-derived data (no `rm -rf`/`pwned`/`approve`). **PASS**.

### Functional — Merge helper (`t/cwf-claude-settings-merge.t`, extended)
`prove t/cwf-claude-settings-merge.t` → **21/21 subtests PASS** (16 retained + 5 new).
- TC-M1: directive-less hook → matcher-less Stop group, no spurious `matcher` key. **PASS**.
- TC-M2: SubagentStop + matcher directives → `{matcher, hooks}` group under `hooks.SubagentStop`; not duplicated under Stop. **PASS**.
- TC-M3: idempotency across events — re-run byte-identical, one group per event. **PASS**.
- TC-M4: invalid `event`/`matcher` directives → fall back to Stop / no matcher; attacker event key not created. **PASS**.
- TC-M5: symlinked hook path → directives not read (default Stop). **PASS**.
- Backward-compat guard: TC-U1 / TC-U3 (byte-identical Stop path) retained and green. **PASS**.

### Regression — full suite + integrity
- `prove t/` → **574 tests, all PASS** (51 files; no regressions).
- `cwf-manage validate` → **OK** (4 hash touches — agent def + merge helper refreshed, classifier + hook added — all verify).

### Non-Functional Tests
- **Security**: classifier + hook consume input on stdin only (no shell, no message-derived paths — TC-H7); directive values regex-validated (TC-M4); block `reason` is a fixed literal via `JSON::PP->encode` (TC-H2/H7); integrity green after the 4 hash touches.
- **Reliability**: hook always exits 0 / fails open (TC-H3–H5).
- **Usability**: `--help` stub (TC-C14).
- **Performance**: n/a — line-oriented parsers over a single message.

### System corroboration (best-effort, NON-GATING) — INCONCLUSIVE this session
Per e-testing-plan, a live re-run of the subagent is corroborating, not a gate. Ran the new `cwf-security-reviewer-changeset` agent against a small clean synthetic changeset (list-form `system('git', …)`, no untrusted input).

- **Observation**: the subagent returned a bare `no findings` on line 1 followed by prose, with **no trailing `cwf-review` block**. Piping that verbatim output through `security-review-classify` yields `error` (zero valid blocks — the conservative default fired correctly).
- **Diagnosis**: this output is a textbook match for the *old* sentinel-first contract, not the new container contract. The on-disk agent definition is confirmed to be the new version (`grep`: contains "End your response with a single fenced `cwf-review` block"; no "VERY FIRST" sentinel language). The running Claude Code session therefore appears to have **loaded the agent definition at session start and not reloaded it after the edit** — so the live subagent exercised the pre-edit definition.
- **Conclusion**: end-to-end confirmation that the *new* agent emits a parseable block **could not be demonstrated in this session**; it requires a fresh session that loads the updated definition. This is a session-lifecycle limitation, not a code defect — the parser/hook/merge logic is fully proven by the deterministic suite, and the classifier correctly defaulted the (block-less, old-style) live output to `error`. **Flagged for rollout: re-run a bucket-B changeset in a fresh session to capture the positive end-to-end evidence.**

## Coverage Report
- Classifier parse-rule branches + enumerated edge cases: covered (TC-C1–C14).
- Hook decision matrix incl. every fail-open branch: covered (TC-H1–H7).
- Merge helper new event/matcher path + byte-identical backward-compat: covered (TC-M1–M5, TC-U1/U3).

## Validation Criteria (from e-testing-plan)
- [x] `t/security-review-classify.t` green — deterministic acceptance gate.
- [x] `t/subagentstop-security-verdict-guard.t` green (fail-open confirmed).
- [x] `t/cwf-claude-settings-merge.t` green incl. TC-U1/U3 + TC-M*.
- [x] Full `prove t/` green (574, no regressions).
- [x] `cwf-manage validate` clean.
- [~] System corroboration (best-effort): **inconclusive this session** — agent definition cached at session start; needs a fresh session. Documented above.

## Security Review

**State**: error

error: changeset exceeds 500-line review cap; split the change or perform manual review

(Deterministic skill-authored outcome: `security-review-changeset --phase=testing` = 982 lines across 10 files, anchor `638131d`. Phase g added only `g-testing-exec.md` (under `implementation-guide/`, not security-relevant) — the security-relevant changeset is unchanged from phase f. The manual threat-category walkthrough recorded in `f-implementation-exec.md` § Security Review (categories a–e, fail-open/DoS analysis) covers this identical changeset and found no actionable findings. Per "surface, never smooth" the `error` cap state stands; recommend accept-and-record.)

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
