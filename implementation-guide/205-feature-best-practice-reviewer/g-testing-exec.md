# Best-practice reviewer for plan and exec steps - Testing Execution
**Task**: 205 (feature)

## Task Reference
- **Task ID**: internal-205
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/205-best-practice-reviewer
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [ ] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [ ] Verify test environment ready
- [ ] Execute test cases sequentially
- [ ] Record pass/fail for each test
- [ ] Document failures with reproduction steps
- [ ] Update status to "Testing" when in progress, "Finished" when all pass

## Test Results

Automation: `prove t/best-practice-resolve.t` → **21 subtests, all PASS**.
Full regression: `prove t/` → **70 files, 881 tests, all PASS** (no regressions).
The e-testing-plan TC-1…TC-22 cases are realised as 21 subtests (planning-only
TC-9 — "each kind resolves to citable content" — is folded into TC-1, which
already asserts file, dir, and URL resolution).

### Functional Tests

| TC | Maps to | What it asserts | Status |
|----|---------|-----------------|--------|
| TC-1  | AC1a | file + dir + allowed-URL entries all resolve into the manifest | PASS |
| TC-2  | AC1b | schema-invalid entries (missing doc / empty tags) skipped with naming diagnostic; valid ones load | PASS |
| TC-3  | AC1c | unparseable JSON → 0 entries + diagnostic, exit 0 (fail-open) | PASS |
| TC-4  | AC2a | project precedence on `documentation` collision; active-tags unioned | PASS |
| TC-5  | AC2b | neither config present → 0 matches, exit 0, empty manifest | PASS |
| TC-6  | AC3a | casefold exact-token match (golang/Golang match, postgres does not) | PASS |
| TC-7  | AC3b | empty T → 0 matches | PASS |
| TC-8  | tags-src | per-task `**Tags**` unions with active-tags | PASS |
| TC-10 | AC4b | missing / binary / non-UTF-8 member / empty dir → each skipped-with-note, no abort | PASS |
| TC-11 | AC4c | two entries → same realpath emitted once (dedup) | PASS |
| TC-12 | NFR4 | top-level project symlink escaping root rejected, target not read | PASS |
| TC-13 | NFR4 | mid-walk escaping member skipped-with-note (distinct msg); sibling resolves | PASS |
| TC-14 | NFR4 | user-config path outside any repo IS resolved (deliberate non-confinement) | PASS |
| TC-15 | NFR4 | URL default-deny (allow-url-fetch false) → noted-but-skipped, not in ### URLS | PASS |
| TC-16 | NFR4 | scheme/host gate: http refused, non-allowlisted host refused, allowed https emitted | PASS |
| TC-20 | NFR4 | embedded ` ```cwf-review ` fence stays inside the sentinel wrapper | PASS |
| TC-19 | NFR5 | bad --max-bytes/--max-files/--task-num/--phase + missing args → exit 1, no confirmation | PASS |
| TC-21 | FR5/6 | confirmation count is the branch signal (0 vs ≥1) | PASS |
| TC-22 | AC6b | exec verdict classified by the existing security-review-classify (findings / error) | PASS |

### Non-Functional Tests
- **NFR1 (caps)**: TC-17 (deterministic byte-cap truncation; re-run byte-identical once the random sentinel is normalised) and TC-18 (directory member cap) — **PASS**.
- **NFR4 (security gates)**: path-escape (TC-12/13), URL default-deny + scheme/host (TC-15/16), fence-forgery containment (TC-20) — **PASS**.
- **NFR5 (fail-open)**: every failure mode (unparseable config, bad entry, unresolvable/binary source, missing args) degrades to a skip-note / `error` / exit-1, never a workflow abort — covered across TC-2/3/10/19 — **PASS**.
- **Output smoke**: TC-1 asserts the sentinel-wrapped `### SOURCE` blocks + `### URLS`; TC-10 the `### SKIPPED` section; TC-17 the `[TRUNCATED]` marker + `# truncated: yes` header.

## Test Failures

None.

## Coverage Report

Helper critical paths: every config-failure branch, every documentation kind,
every confinement/skip/truncation path has a case (per e-testing-plan coverage
targets). Regression: 0 failures in `prove t/`. The two agents and the
SKILL/plan-review wiring are prose exercised via the f-phase parallel review
step (live agent verification) — the dog-fooding 0-match branch was exercised in
f; a populated `best-practices.json` live-agent run is left to a consuming repo
(no fixture repo with matching docs is committed here).

## Security Review

**State**: no findings

**Cap note (surfaced, not smoothed)**: `security-review-changeset --wf-step=testing-exec`
reported `cap exceeded: 1082 production lines > 500` (exit 2) — the **identical**
production count to the f-phase review. The testing phase added only test-result
documentation (`g-testing-exec.md`, under the excluded `implementation-guide/**`)
and no production code, so the security surface is byte-for-byte unchanged from
the f-phase changeset that the `cwf-security-reviewer-changeset` agent already
reviewed with a `no findings` verdict (see f-implementation-exec.md § Security
Review). Re-invoking the agent on identical code would add no signal; the cap
breach is surfaced here rather than smoothed, and the standing verdict carries
forward.

## Best-Practice Review

**State**: no findings

no findings: no applicable best practices (`best-practice-resolve --task-num=205
--phase=testing-exec` wrote 0 matched entries — this repo has no
`best-practices.json`).

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
21 unit subtests + 881-test full regression, all PASS; one correctness fix
(`-e` vs `defined` on `realpath`) found and resolved during the run. See § Test
Results above.

## Lessons Learned
When production code is byte-identical across f and g (testing added only
excluded docs), carry the security verdict forward and surface the cap rather
than redundantly re-reviewing. See `j-retrospective.md`.
