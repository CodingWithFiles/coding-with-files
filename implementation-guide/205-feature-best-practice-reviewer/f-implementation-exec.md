# Best-practice reviewer for plan and exec steps - Implementation Execution
**Task**: 205 (feature)

## Task Reference
- **Task ID**: internal-205
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/205-best-practice-reviewer
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [ ] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [ ] Verify all prerequisites met
- [ ] Execute implementation steps sequentially
- [ ] Update "Actual Results" for each step
- [ ] Document any deviations from plan
- [ ] Update status to "Implemented" when complete

## Implementation Steps (from d-implementation-plan.md)

See d-implementation-plan.md Steps 1–4; actual results below.

## Actual Results

### Step 1: Helper + tests
- **Actual**: Created `.cwf/scripts/command-helpers/best-practice-resolve` (0500),
  reusing `CWF::Common` (`find_git_root`), `CWF::TaskPath` (`resolve_num`),
  `CWF::ArtefactHelpers` (`atomic_write_text`); core deps `Cwd`, `Encode`,
  `JSON::PP`. `--task-num` + `--phase` are both mandatory and allowlist/regex
  validated (filename components); `--max-bytes`/`--max-files` validated
  `/^[1-9]\d*$/`. Deterministic order (project→user, array order, lexical dir
  walk), per-member realpath confinement for project paths, dedup by realpath,
  random per-run sentinel, byte + member caps. Created `t/best-practice-resolve.t`
  — 21 subtests (TC-1…TC-22 less the planning-only TC-9 folded into TC-1),
  all PASS. One correctness fix during test: `realpath` resolves a
  non-existent leaf under an existing parent without error, so a missing source
  is detected with an explicit `-e` check, not a `defined` check.
- **Deviations**: none vs d-plan.

### Step 2: Agents + shared doc
- **Actual**: Created `.cwf/docs/skills/best-practice-review.md` (single normative
  source: manifest discipline, prompt templates, config reference, precedence,
  limitations) and the two agents (`cwf-plan-reviewer-best-practice.md`,
  `cwf-best-practice-reviewer-changeset.md`, both 0444, tools
  `Read, Grep, Glob, LSP, WebFetch` — no Bash). Hash entries authored in this
  commit (sha256 via `sha256sum`); `cwf-manage validate` OK.

### Step 3: Wiring
- **Actual**: `plan-review.md` gained a pre-MAP `best-practice-resolve --phase=plan`
  step and a conditional 5th column launched in the **same parallel MAP message**.
  Fixed the dangling "Criteria Lookup Table" cross-ref in `security-review.md:126`.
  Both exec SKILLs: see deviation below.
- **DEVIATION (per direct user direction during exec)**: d-plan/c-design (KD8)
  described exec integration as a *second* `## Best-Practice Review` step
  mirroring the single security step. The user required that **all review
  sub-agents run in parallel** (planning and exec), the sole exception being a
  strict output→input data dependency. Accordingly the two exec SKILLs were
  restructured into a single **Step 8 (Changeset Reviews — parallel)**: the two
  deterministic helpers (`security-review-changeset`, `best-practice-resolve`)
  run in Prep (their `.out` files are strictly-required agent inputs), then the
  security and best-practice changeset reviewers are launched **together in one
  message** (parallel) and classified independently by the shared
  `security-review-classify`. This is a velocity-improving refinement that keeps
  the verdict contracts unchanged; it does not alter the helper/agent/classifier
  reuse the design mandated.

### Step 4: Validate
- **Actual**: `prove t/best-practice-resolve.t` PASS (21). Full `prove t/` PASS
  (70 files, 881 tests) after tightening `t/security-review-changeset.t` TC-DOCS:
  its `--phase` guard was scoped to the `security-review-changeset` invocation so
  the new, legitimate `best-practice-resolve --phase=…` in the exec SKILLs does
  not false-positive (intent preserved, not weakened). `cwf-manage validate` OK
  (three new hash entries; no perm drift). Output-level smoke covered by TC-1
  (sentinel-wrapped sections + ### URLS), TC-10 (### SKIPPED), TC-17 (truncation).

## Blockers Encountered

None.

## Security Review

**State**: no findings

**Cap note (surfaced, not smoothed)**: `security-review-changeset` reported
`cap exceeded: 1082 production lines > 500` (exit 2). The cap-exclude config
(`t/**`, `implementation-guide/**`) correctly discounted the test file and the
wf-step planning docs, but the production code shipped by this task (the helper
+ two agents + the shared doc + SKILL/plan-review wiring ≈ 1082 lines) genuinely
exceeds the default cap. Rather than record a bare `error` and skip review of a
security-sensitive helper, the `cwf-security-reviewer-changeset` agent was
invoked deliberately on the full changeset `.out` (3178 lines). Verdict below,
classified by `security-review-classify` → `no findings`.

Reviewed against FR4 (a)–(e): no Bash/shell construction; strong pre-filesystem
argument validation; defensive fail-open config parsing; per-member realpath
confinement for project paths (TOCTOU-safe, re-checked each recursion step);
random-sentinel untrusted-data wrapper with verdict-forgery defence; opt-in,
https-only, host-allowlisted URL policy (helper never fetches); standard
two-level 0700 scratch guard with parent-symlink reject. Documented accepted
residuals reported as audit-on-reuse pattern notes (not defects): DNS-rebinding
/ host-allowlist SSRF model; non-crypto `rand()` sentinel (forgery payoff is
fail-open with no guessing oracle).

```cwf-review
state: no findings
summary: Helper implements its threat model faithfully; SSRF (DNS-rebinding/host-allowlist) and non-crypto sentinel are documented accepted residuals, not defects.
```

## Best-Practice Review

**State**: no findings

no findings: no applicable best practices (this repo has no `best-practices.json`
in `.cwf/` or `~/.cwf/`; `best-practice-resolve --task-num=205
--phase=implementation-exec` wrote 0 matched entries). The reviewer is correctly
a no-op when unconfigured — the dog-fooding path exercises the 0-match branch.

## Deferral Check
Before marking status=Finished, verify:
- [ ] All steps from d-implementation-plan.md executed
- [ ] All success criteria from a-task-plan.md met
- [ ] All requirements from b-requirements-plan.md addressed (if applicable)
- [ ] All design guidance in c-design-plan.md followed (if applicable)
- [ ] No planned work deferred without user approval
- [ ] If work deferred: Follow-up task created and linked

**If deferral required**: Get user approval, document rationale, create follow-up task.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Helper + two agents + shared doc + planning/exec wiring delivered; exec reviews
restructured to run in parallel (the significant deviation). Security review
`no findings` (cap breach surfaced, reviewed anyway). See § above and `j-retrospective.md`.

## Lessons Learned
A new reviewer belongs as a parallel peer in the existing MAP; serialising is
justified only by a strict output→input dependency (fast deterministic helpers
feeding agent inputs are not one). See `j-retrospective.md` and memory
`feedback-reviewers-parallel`.
