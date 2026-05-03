# Add security-review subagent to plan/exec skills - Design
**Task**: 123 (feature)

## Task Reference
- **Task ID**: internal-123
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/123-add-security-review-subagent-to-plan-exec-skills
- **Template Version**: 2.1

## Goal
Specify the integration shape: where the threat model lives, how plan-review.md grows from 3 → 4 subagents, how the exec phases invoke their security subagent, and how the three return states are recorded.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility. The hard constraint is *consistency* with the existing 3-subagent plan-review pattern (don't invent a new shape).

## Key Decisions

### Decision 1: Two integration points, one canonical doc
- **Decision**: Add `.cwf/docs/skills/security-review.md` as the canonical doc for the CWF threat model. Plan-phase invocation extends `.cwf/docs/skills/plan-review.md`'s existing 3-row criteria-lookup table to 4 rows. Exec-phase invocation lives in a small prompt template inside `security-review.md`, referenced from `cwf-implementation-exec/SKILL.md` and `cwf-testing-exec/SKILL.md`.
- **Rationale**: The plan-review pattern already inlines its prompt template with parameter substitution (`{plan_type}`, `{focus_area}`, `{criteria}`); replicating it for the 4th row keeps the pattern intact. Exec-phase has no analogous host doc, so the prompt template lives in the new canonical doc next to the threat model it consumes. Threat-model definitions live in exactly one place.
- **Trade-offs**: Two prompt locations (plan-review.md row 4, security-review.md exec template) instead of one. Acceptable because each prompt is short (~10 lines) and the *threat model* — the volatile/long content — is in one place. The alternative (move all 4 plan-review prompts into a separate doc) breaks the existing pattern for one new feature; rejected.

### Decision 2: `git diff` defines the changeset for exec-phase review
- **Decision**: Exec-phase subagent receives a parameter `{changeset}` that is the verbatim output of `git diff $(git merge-base HEAD main)..HEAD -- '*.pl' '*.pm' '*.bash' '*.sh' '.cwf/scripts/**' '.claude/scripts/**' '.claude/skills/**' '.claude/hooks/**' '.cwf/lib/**' '.cwf/docs/skills/**' '.claude/rules/**' '.claude/settings.json' 'implementation-guide/cwf-project.json'`. The pathspec is the **single source of truth** and lives in `.cwf/docs/skills/security-review.md` § "Pathspec coverage"; both exec SKILLs reference that section.
- **Rationale**: Anchoring on `git diff` makes the change set unambiguous and gives the subagent the same view a code reviewer would have. `git merge-base HEAD main` correctly returns the branch point even if main has advanced. Empty diff → subagent records `no findings: empty changeset` per FR2.
- **Edge cases**:
  - **On-main**: SKILL checks `git rev-parse --abbrev-ref HEAD` first; if `main`, records `no findings: on main` and skips the subagent call. Avoids spending tokens on an empty diff and a confusing merge-base self-comparison.
  - **Diff >500 lines**: Do NOT silently truncate. SKILL counts diff lines first; if >500, records `error: changeset exceeds 500-line review cap; split the change or perform manual review per docs/conventions/design-alignment.md` and proceeds without invoking the subagent. A bloated diff is a planning problem, not a review problem; surfacing it is the right behaviour.
  - **New security-relevant tree added** (e.g. a future `.cwf/scripts/post-install/`): pathspec must be updated in the canonical doc. The doc carries a comment ("when adding a new security-relevant directory, update this pathspec") so a maintainer can't silently expand the attack surface.
- **Trade-offs**: Hardcoded pathspec is a known limitation; mitigated by single-source-of-truth in the canonical doc and the inline maintainer note. The 500-line cap is a deliberate quality gate, not a silent loss.

### Decision 3: Three return states recorded verbatim, with a fallback classifier
- **Decision**: The SKILL records the subagent's output verbatim into the wf step file under a `## Security Review` section. Classification is robust to model variation:
  1. **Primary**: first non-blank line starts with `findings:` / `no findings` / `error:` → use that state directly.
  2. **Fallback** (if the primary fails): scan the body for a numbered list (`^\s*\d+[.)]\s`) or the literal phrase `actionable finding` → classify as **findings**.
  3. **Conservative default**: if neither primary nor fallback matches, classify as **error** (never silently classify as "no findings" — that would mask a malformed-output failure).
  4. **Tool-level failure** (Agent call errors, timeout, allowlist violation): classify as **error** regardless of body content.
- **Rationale**: Verbatim recording survives compaction and audit. The fallback prevents a verbose model intro ("I found three issues…") from being misclassified as "no findings". The conservative default biases toward visibility — a misclassified error is louder than a missed finding.
- **Trade-offs**: Three-tier classifier is slightly more code than a strict sentinel match, but the failure mode of strict matching (silent "no findings" on a verbose response) is the worst possible outcome for a security tool.

### Decision 4: No new helper script
- **Decision**: This is a docs-and-skills task. No new `.cwf/scripts/command-helpers/` script. The Agent tool call is in the SKILL Markdown (matching how plan-review.md describes its 3 subagent calls).
- **Rationale**: Helper scripts are for *deterministic* operations (per CLAUDE.md). Subagent invocation is LLM logic; lives in the SKILL prose and gets executed by Claude.
- **Trade-offs**: Cannot unit-test the subagent invocation in `prove`. Mitigation: AC8's deferred dogfood verification in g-testing-exec is the integration test.

### Decision 5: Pattern-risk findings carved out of "actionable only" rule
- **Decision**: The prompt explicitly allows pattern-based risk findings per FR4(e), with required framing (`safe here because X; audit future uses where X might not hold`). All other "could be a problem someday" suggestions remain out of scope.
- **Rationale**: Per the plan-review subagent's finding on this requirements plan, security reviews legitimately flag risky patterns even when current callsites are safe. Without the carve-out, the subagent suppresses real signal.
- **Trade-offs**: Slightly more verbose findings. Acceptable; the framing requirement keeps them disciplined.

## System Design

### Component Overview

| Component | Purpose | Owner location |
|-----------|---------|----------------|
| Threat-model doc | Canonical CWF threat categories with anti-patterns | `.cwf/docs/skills/security-review.md` (new) |
| Plan-phase prompt | 4th row of criteria-lookup table | `.cwf/docs/skills/plan-review.md` (edit) |
| Exec-phase prompt template | Reusable prompt parameterised by changeset | inside `.cwf/docs/skills/security-review.md` |
| Plan-phase invocation | Single-message Agent call with 4 parallel subagents | unchanged in `.claude/skills/cwf-{requirements,design,implementation}-plan/SKILL.md` (the SKILLs already say "follow plan-review.md"; plan-review.md does the work) |
| Exec-phase invocation | New numbered step in two SKILLs | new step in `.claude/skills/cwf-{implementation,testing}-exec/SKILL.md` |
| Result recording | `## Security Review` section appended to wf step file | inside `f-implementation-exec.md` and `g-testing-exec.md` per task |

### Data Flow

**Plan phase** (b/c/d → plan-review.md):
1. Plan-phase SKILL writes the wf step file
2. SKILL invokes plan-review.md per its existing instructions
3. plan-review.md launches 4 parallel Agent calls (now including security row)
4. Each subagent reads `Read/Grep/Glob`-only and reports findings
5. SKILL synthesises and applies findings (existing REDUCE step)

**Exec phase** (f/g):
1. Exec SKILL completes implementation/testing steps
2. NEW STEP: SKILL constructs `{changeset}` from `git diff <merge-base>..HEAD -- <pathspec>`
3. SKILL invokes one Agent call with the security subagent prompt template from `security-review.md`
4. Subagent returns one of three sentinel-prefixed outputs
5. SKILL appends a `## Security Review` section to the wf step file with the verbatim output
6. SKILL proceeds to existing checkpoint commit

## Interface Design

### Threat-model doc structure (`.cwf/docs/skills/security-review.md`)

```
# Security Review

## Scope
This doc owns the CWF threat model and the security-review subagent prompts.
Two callers: plan-review.md (row 4 of the criteria-lookup table) and the
exec-phase invocations in cwf-implementation-exec / cwf-testing-exec.

Boundary: this subagent reviews JUDGEMENT-CALL security concerns
(design intent, code patterns, input flow). Deterministic integrity
checks (file permissions, sha256 of recorded files) are owned by
`.cwf/scripts/cwf-manage validate`. Not duplicated here.

The user-facing built-in /security-review command is a separate,
broader, branch-level review tool — also not duplicated here.

## Threat categories

### (a) Bash injection / unsafe command construction
- Definition: ...
- Anti-pattern (cite real CWF file:line if one exists; otherwise illustrative):
  ```bash
  system("git checkout $branch")  # $branch from task slug — unquoted
  ```
- Do instead: `system("git", "checkout", $branch)` (list form, no shell)

### (b) Perl helpers consuming git/user output without -z
[same shape]

### (c) Prompt injection via user-supplied strings
[same shape]

### (d) Unsafe environment-variable handling
[same shape, cite CWF_SOURCE in cwf-manage]

### (e) Pattern-based risks (safe-here-but-risky-elsewhere)
[same shape; framing requirement spelled out]

## Plan-phase row (referenced from plan-review.md table)
The plan-review.md criteria-lookup table row for `security` reads:
| security | requirements: ... | design: ... | implementation: ... |
(See plan-review.md for the actual row; this section explains what
each cell asks the subagent to check.)

## Exec-phase prompt template
Substitute {changeset}, {phase} (= "implementation" or "testing").

```
Review the {changeset} below for security concerns per the threat model
in `.cwf/docs/skills/security-review.md` §"Threat categories".

You may only use Read, Grep, and Glob (no Bash, no edits).

Start your response with one of three sentinel lines:
- `findings:` followed by numbered actionable findings (what is wrong,
  where in the diff, what to do).
- `no findings` if the diff is clean for your focus area. May be
  followed by a one-line note.
- `error:` if you cannot perform the review (state the reason).

Pattern-based risk findings allowed: a pattern that is safe at the
callsite but risky if reused elsewhere may be reported with the
framing "safe here because X; audit future uses where X might not hold."
Aspirational suggestions (no concrete CWF surface) are out of scope.

Changeset:
{changeset}
```
```

### Plan-review.md changes

Procedure header: "Launch 3 Subagents" → "Launch 4 Subagents".

Criteria-lookup table gains a 4th column:

| | Improvements | Misalignment | Robustness | **Security** |
|--|--|--|--|--|
| requirements | … | … | … | Are security-relevant requirements (input handling, file permissions, env vars, prompt-injection surface) named explicitly? Are any missing? See `.cwf/docs/skills/security-review.md` §"Threat categories" for the CWF threat model. |
| design | … | … | … | Does the design name how each FR4 threat category is addressed (or explicitly out-of-scope)? Are new components introducing new attack surface (file writes, exec, hook registration, env-var reads) without a deliberate decision? |
| implementation | … | … | … | Do the planned code changes introduce any of the FR4(a–d) anti-patterns? Are they pattern-risks per FR4(e)? See `.cwf/docs/skills/security-review.md` for examples and remediation. |

(In Markdown the table is wider and the existing 3 columns stay verbatim.)

### Exec SKILL changes

Both `cwf-implementation-exec/SKILL.md` and `cwf-testing-exec/SKILL.md` gain a new sequentially-numbered Step 8 (Security Review). The existing Step 8 (Checkpoint commit) becomes Step 9; existing Step 9 (Next Steps) becomes Step 10. Sequential renumbering matches the precedent set by Task 71's checkpoint-commit insertion (commit `be933c7`); no `7a`-style sub-steps.

New Step 8 text (parameterised on phase = "implementation" or "testing"):

```
**Step 8 (Security Review)**:
- Read `.cwf/docs/skills/security-review.md` §"Exec-phase prompt template" and §"Pathspec coverage".
- Determine current branch: `git rev-parse --abbrev-ref HEAD`.
  - If `main`: append `## Security Review\n\nno findings: on main\n` to the wf step file and proceed to Step 9.
- Construct changeset: `git diff $(git merge-base HEAD main)..HEAD -- <pathspec from §"Pathspec coverage">`.
  - If empty: append `## Security Review\n\nno findings: empty changeset\n` and proceed to Step 9.
  - If >500 lines (count via `wc -l`): append `## Security Review\n\nerror: changeset exceeds 500-line review cap; split the change or perform manual review\n` and proceed to Step 9.
- Invoke ONE Agent call with `subagent_type="Explore"` using the prompt template.
- Append `## Security Review\n\n<verbatim subagent output>\n` to the wf step file.
- Classify the result per Decision 3 (primary sentinel → fallback numbered-list scan → conservative-default error). Record the classification on a `**State**: findings|no findings|error` line above the verbatim block.
- Do NOT block the workflow on `findings` state. Record them; the user decides whether to fix-and-re-run or accept-and-record before Step 9 (Checkpoint commit).
```

The "do not block" choice keeps the subagent advisory; the user decides. This matches how plan-review handles disagreements (REDUCE applies judgement, not a hard gate).

## Constraints (re-stated from b-requirements-plan)
- Read/Grep/Glob allowlist
- ≤400-token prompt budget
- British spelling
- No `find`/`sed` in prescribed snippets (anti-pattern *examples* in the doc are exempt)
- No callable dependency on built-in `/security-review`

## Decomposition Check
- [ ] Time: <1 day → no
- [ ] People: single author → no
- [ ] Complexity: 1 new doc, 1 doc edit, 2 SKILL edits — one pattern → no
- [ ] Risk: medium-tier, in-task mitigable → no
- [ ] Independence: plan and exec phases share the prompt doc → no

No decomposition.

## Validation
- [ ] Design review completed (subagent map/reduce per Step 8)
- [ ] All FR4(a–e) categories have a designated home in the canonical doc structure above
- [ ] Pathspec for `git diff` lives in canonical doc (single source of truth) and enumerates all current security-relevant trees
- [ ] Three-tier classifier (sentinel → numbered-list fallback → conservative-default error) prevents silent "no findings" misclassification
- [ ] Edge cases (on-main, empty diff, >500-line diff) handled in Step 8 SKILL text without invoking the subagent unnecessarily
- [ ] Step renumbering preserved (existing Step 8 → 9, Step 9 → 10) per Task 71 precedent
- [ ] No conflict with existing `cwf-manage validate` scope (FR4 boundary preserved; doc explicitly carves out deterministic checks)
- [ ] AC8 (dogfood verification) wired into e-testing-plan as a TC; g-testing-exec records the verbatim subagent output for this very task

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 123
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 5 Decisions landed unchanged at exec time. The three-tier classifier (Decision 3) proved its worth in TC-AC8 — fallback fired on the verbose-intro response, biasing toward visibility exactly as designed.

## Lessons Learned
Sequential renumbering precedent (Task 71 commit be933c7) caught by plan-review subagent — adopting it instead of the original `Step 7a` notation kept workflow-file shape consistent across CWF.
