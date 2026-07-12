# Separate goals from requirements in plan stage - Testing Execution
**Task**: 226 (bugfix)

## Task Reference
- **Task ID**: internal-226
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/226-separate-goals-from-requirements-in-plan-stage
- **Template Version**: 2.1

## Goal
Execute the e-testing-plan.md binding assertions (TC-1…TC-10, deterministic grep/sha256/
validate/render) and the confirmatory TC-11 replay. No code — the tests are doc-content
regressions.

## Test Results Summary
**All TC-1…TC-10 (binding) PASS. `cwf-manage validate` clean. TC-11 (confirmatory) satisfied
by inspection.**

### Functional Tests (binding — deterministic)

| Test ID | KD | Assertion | Actual | Status |
|---------|----|-----------|--------|--------|
| TC-1 | KD2 | `planning.md`: unfenced "What can be removed"/"minimal solution"/"Keeping the system simple" **absent**; means-only fence present | fence at lines 7–11; no unfenced prompts | PASS |
| TC-2 | KD2 | "best part is no part" in **both** `planning.md` (fenced) and `requirements.md`; challenge-requirements discipline in `requirements.md` | both present; discipline at requirements.md:18 | PASS |
| TC-3 | KD1 | dual-capture ("why AND explicit request") in `planning.md`, `SKILL.md`, pool template; lossy "single-sentence objective" gone from all three | present ×3; lossy phrasing absent ×3 | PASS |
| TC-4 | KD1 | "none stated" allowance in `planning.md` + pool template | present in both | PASS |
| TC-5 | KD3 | goals owner-owned / no unilateral narrow-or-expand / surface in `planning.md` + SKILL | planning.md:13, SKILL.md:51 | PASS |
| TC-6 | KD5 | two new SKILL Success-Criteria items (faithful capture; surface scope change) | SKILL.md:49, :51 | PASS |
| TC-7 | KD4 | `cwf-agent-shared-rules.md` new top-level `## Goal integrity and scope changes` with "never a silent de-scope" rule | section at :68, rule at :73 | PASS |
| TC-8 | KD4 | all 10 reviewer defs still link shared-rules; none modified by this task | 10 links; 0 agent defs in diff | PASS |
| TC-9 | KD6 | recorded sha256 == on-disk; `validate` clean; doc+manifest same commit | `d079837a…` matches; validate OK; both in `3eadeb2` | PASS |
| TC-10 | KD5 | 5 template symlinks resolve to pool; fresh render carries new placeholder | symlinks OK; rendered bugfix task shows dual-capture Goal | PASS |

### Non-Functional Tests

- **TC-11 (Reliability — replay, CONFIRMATORY/soft, not a gate)** — Satisfied by inspection.
  The Task-31 failure chain was: lossy goal paraphrase → a named deliverable dropped from the
  goal → a review agent proposing to defer it. Both links are now structurally blocked: the
  dual-capture instruction (KD1) forbids paraphrase that drops a named deliverable and mandates
  "none stated" rather than invention; the owner-surface rule (KD3) in `planning.md` **and** the
  reviewer-binding `## Goal integrity` section (KD4) forbid any agent — planner or reviewer —
  from silently de-scoping a user-named deliverable, routing it to the owner instead. A live
  end-to-end replay is soft/non-gating per the plan; recorded, not gated.
- **Usability** — PASS (manual read). Edited prose matches each doc's existing voice; British
  spelling and role-only phrasing preserved.

## Test Failures
None.

## Coverage Report
- 100% of KD1–KD6 covered by ≥1 binding assertion (TC-1…TC-10).
- Every edited file asserted (required strings present; relocated strings absent from origin).
- Environment: repo working tree post-f-exec; tools Grep/Read, `sha256sum`,
  `template-copier-v2.1`, `cwf-manage validate`, `git show`. No external services / test DB.

## Changeset Reviews (Step 8 — 2-reviewer MAP, run in parallel)
Branch is a task branch (not main). `security-review-changeset --wf-step=testing-exec` → exit 0,
1093 lines (77 production); `best-practice-resolve --phase=testing-exec` → 3 matched entries.
Both reviewers launched; `security-review-classify` returned `no findings` for both (launched
set = classified set). Verbatim outputs archived in the per-task scratch `.out` files.

### Security Review
**State**: no findings

Instruction/doc-only change; no executable surface across categories (a)–(e). The
`agent-shared-rules` sha256 refresh (`d079837a…`) is in-scope for `cwf-manage validate`, not a
judgement finding. **Advisory (category e), surfaced**: the new `Explicit request` field
captures user free-text verbatim; safe here because it is read only as informational plan
content and never drives a tool call — but audit any *future* consumer that begins keying logic
off that field rather than the validated task number, at which point the verbatim text would
become a live injection vector.

### Best-Practice Review
**State**: no findings

3 matched sources (golang / postgres / perl), all readable. Changeset is doc/template/JSON
prose only — no code surface for the language conventions to apply to. Genuine clean.

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
See per-TC table above — all binding cases PASS, validate clean.

## Lessons Learned
Static assertions cover structure (KD1–KD6 present/relocated); the behavioural guarantee
(TC-11) stays confirmatory — prose-instruction reliability is provable only in field use,
so the structural blocks are necessary but the replay remains soft, not a gate.
