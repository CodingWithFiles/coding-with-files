# security-reviewer clean reviews misclassified - Testing Plan
**Task**: 162 (bugfix)

## Task Reference
- **Task ID**: internal-162
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/162-security-reviewer-clean-reviews-misclassified
- **Template Version**: 2.1

## Goal
Validate that the `cwf-review` container + `security-review-classify` correctly classify reviews regardless of prose position/markdown (fixing the misclassification), that genuinely malformed output still yields `error`, that the SubagentStop hook fails open, and that the merge-helper extension registers the hook without regressing existing Stop-hook behaviour.

## Test Strategy
### Test Levels
- **Unit (deterministic — the acceptance gate)**: `t/security-review-classify.t` — stdin → token, covering the full D3 parse rule and edge cases.
- **Integration**: `t/cwf-claude-settings-merge.t` (extended) — SubagentStop+matcher registration, directive parsing/validation, idempotency, backward-compat; and `t/subagentstop-security-verdict-guard.t` (new) — the hook's decision matrix and fail-open discipline as a subprocess.
- **System (corroborating, best-effort, NOT a gate)**: re-run the live subagent against historical bucket-B changesets.
- **Regression**: full `prove t/` + `cwf-manage validate` (hash integrity after refreshes).

### Test Coverage Targets
- **Classifier**: 100% of parse-rule branches and the enumerated edge cases (the bug-fix evidence).
- **Hook**: every branch of the decision matrix (block vs allow vs fail-open).
- **Merge helper**: new event/matcher path + byte-identical backward-compat Stop path.
- **Regression**: existing `cwf-claude-settings-merge.t` Stop subtests (TC-U1, TC-U3) remain green unmodified.

## Test Cases
### Functional — Classifier (`t/security-review-classify.t`)
- **TC-C1 (the core bug fix)**: clean verdict after heavy reasoning prose.
  - **Given**: input = many paragraphs of analysis, then a trailing ```` ```cwf-review ```` block with `state: no findings`.
  - **When**: piped to `security-review-classify` on stdin.
  - **Then**: stdout = `no findings`; exit 0. (This is the case that historically misclassified as `error`.)
- **TC-C2**: `state: findings` → `findings`. **TC-C3**: `state: error` → `error`.
- **TC-C4 (markdown tolerance)**: block surrounded by bold/backtick/blockquote prose noise → still `no findings`.
- **TC-C5**: empty stdin → `error`. **TC-C6**: prose only, zero blocks → `error`.
- **TC-C7**: invalid `state:` value (e.g. `clean`) → `error`.
- **TC-C8**: lone block with empty/whitespace `state:` → `error` (not silently dropped).
- **TC-C9**: unterminated fence (opened, no closing ```` ``` ````) → `error`.
- **TC-C10**: two valid blocks, same state → `error`. **TC-C11**: two valid blocks, conflicting → `error`.
- **TC-C12 (echoed example)**: echoed non-token example block (`state: <no findings|findings|error>`) alongside exactly one real valid block → the real state; echoed example **alone** → `error`.
- **TC-C13**: case/whitespace normalisation (`State:  NO FINDINGS ` ) → `no findings`.
- **TC-C14**: `--help` prints usage; exit 0.

### Functional — SubagentStop hook (`t/subagentstop-security-verdict-guard.t`)
Hook invoked as a subprocess with JSON on stdin; assert stdout + that exit is **always 0**.
- **TC-H1**: `last_assistant_message` carries a valid `no findings` block → stdout empty (allow); exit 0.
- **TC-H2**: message has no valid block, `stop_hook_active=false` → stdout = `{"decision":"block",...}` with the fixed literal reason; valid JSON (round-trips via decode); exit 0.
- **TC-H3**: no valid block but `stop_hook_active=true` → allow (empty stdout); exit 0.
- **TC-H4 (fail-open)**: malformed/non-JSON stdin → allow; exit 0.
- **TC-H5 (fail-open)**: JSON missing `last_assistant_message` → allow; exit 0.
- **TC-H6**: message carries a `findings` block (valid verdict) → allow; exit 0.
- **TC-H7 (no injection)**: `last_assistant_message` containing shell metacharacters / fake JSON → treated as inert; reason output unchanged, exit 0 (no interpolation).

### Functional — Merge helper (`t/cwf-claude-settings-merge.t`, extended)
- **TC-M1 (backward compat)**: existing Stop hooks (no directives) register matcher-less under `hooks.Stop[0].hooks`, shape byte-identical (no spurious `matcher` key). *(TC-U1/TC-U3 retained unmodified as the guard.)*
- **TC-M2**: a hook declaring `# cwf-hook-event: SubagentStop` + `# cwf-hook-matcher: cwf-security-reviewer-changeset` registers under `hooks.SubagentStop` as `{matcher, hooks}`.
- **TC-M3 (idempotency)**: re-run adds nothing; the command lives in exactly one matcher group per event.
- **TC-M4 (directive validation)**: a hook with a bogus `event`/`matcher` value (failing the regex) is not written under an attacker-chosen settings key (defaults to Stop / no matcher or is skipped).
- **TC-M5 (read guard)**: a symlink/non-regular path is not opened for directive parsing.

### Non-Functional Test Cases
- **Security**: classifier and hook consume input on stdin only — no shell, no message-derived paths (verified structurally + TC-H7); directive values regex-validated (TC-M4); block `reason` is a fixed literal built via `JSON::PP->encode` (TC-H2); `cwf-manage validate` green after the 4 hash touches (integrity).
- **Reliability**: hook always exits 0 / fails open (TC-H3–H5) — a broken or absent classifier never traps the subagent.
- **Performance**: n/a — small line-oriented parsers over a single message; no measurable budget.
- **Usability**: `--help` usage stub (TC-C14) for parity with sibling command-helpers.

## Test Environment
### Setup Requirements
- Synthetic fixtures only (no network, **no live LLM** for the gating tests). Classifier fixtures are inline strings; merge-helper/hook tests build a synthetic repo/JSON per the existing `security-review-changeset.t` pattern (`File::Temp`, `File::Path`, core modules).
- The corroborating system test requires a live `cwf-security-reviewer-changeset` subagent and historical changesets — run manually in g, explicitly non-gating.

### Automation
- `Test::More`, run via `prove t/`. Core-Perl only. No CI change required (existing `prove t/` covers the new files).

## Validation Criteria
- [ ] `prove t/security-review-classify.t` green (all TC-C*) — the deterministic acceptance gate for the bug fix.
- [ ] `prove t/subagentstop-security-verdict-guard.t` green (all TC-H*, fail-open confirmed).
- [ ] `prove t/cwf-claude-settings-merge.t` green incl. retained TC-U1/TC-U3 (backward-compat) and new TC-M*.
- [ ] Full `prove t/` suite green (no regressions).
- [ ] `cwf-manage validate` clean (hash refreshes correct).
- [ ] System corroboration recorded in g (best-effort): bucket-B sample re-run classifies `no findings`.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Deterministic gate fully green: classifier 18 (TC-C1–C14), hook 18 (TC-H1–H7, fail-open + injection-inertness), merge helper +5 (TC-M1–M5) with TC-U1/U3 retained. Full suite 574 tests pass; `cwf-manage validate` clean. The best-effort live system corroboration was **inconclusive in-session** — the running session had the agent definition cached at start, so the live subagent emitted old-contract output (correctly classified `error` by the helper). Deferred to a fresh session (filed as future work).

## Lessons Learned
Synthetic fixtures were the correct gate: the historical corpus predates the `cwf-review` format and would have classified `error` wholesale. The unit-level acceptance gate is independent of the live agent, so it remained authoritative even when the live corroboration couldn't run.
