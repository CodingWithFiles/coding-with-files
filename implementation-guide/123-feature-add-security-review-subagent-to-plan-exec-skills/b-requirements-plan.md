# Add security-review subagent to plan/exec skills - Requirements
**Task**: 123 (feature)

## Task Reference
- **Task ID**: internal-123
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/123-add-security-review-subagent-to-plan-exec-skills
- **Template Version**: 2.1

## Goal
Specify what the security-review subagent must do (functional) and to what standard (non-functional), so design has unambiguous targets.

## Functional Requirements

### Core Features

- **FR1: Plan-phase security subagent**
  - The plan-review map/reduce procedure (currently 3 subagents: improvements, misalignment, robustness) MUST gain a fourth **security** subagent.
  - Acceptance: `.cwf/docs/skills/plan-review.md` documents 4 subagents; the criteria-lookup table has a `security` row covering all three plan types (`requirements`, `design`, `implementation`); the procedure header says "4 parallel subagents".

- **FR2: Exec-phase security subagent**
  - Both `cwf-implementation-exec` (f) and `cwf-testing-exec` (g) MUST invoke a security-review subagent against the just-changed code as a numbered workflow step (peer of the existing "Step 8: Checkpoint commit" — i.e. a major workflow phase, not a sub-step).
  - The subagent runs over `git diff <task-base>..HEAD` for that task; if the diff is empty (e.g. doc-only change, or step re-run with no further edits), the subagent returns `no findings: empty changeset` and the step is recorded as completed.
  - Acceptance: each SKILL.md has a numbered step that reads the canonical doc, runs one Explore subagent scoped to the diff, and records the result in the wf step file. Empty-changeset case explicitly handled.

- **FR3: Threat model in canonical doc; prompts inlined where they run**
  - The CWF threat model (the categories and CWF-specific anti-pattern examples) MUST live in one new canonical doc, `.cwf/docs/skills/security-review.md`. The doc is the single source of truth for *what to look for*.
  - Plan-phase prompt: a new fourth row added to the criteria-lookup table inlined in `.cwf/docs/skills/plan-review.md` (matching the existing 3 rows). The row's `criteria` cell points at the canonical doc rather than restating the threats inline.
  - Exec-phase prompt: a short prompt template added to the canonical doc, parameterised by changeset; the two exec SKILL files reference the doc rather than inlining the prompt.
  - Rationale: the existing plan-review pattern inlines its prompt template — `.cwf/docs/skills/plan-review.md` is itself the canonical doc for plan-review prompts. Don't break that pattern; add to it.
  - Acceptance: canonical doc exists; plan-review.md table has 4 rows including security; both exec SKILL files reference the canonical doc; threat categories appear in exactly one place (the canonical doc).

- **FR4: CWF-grounded threat model — subagent scope (judgement) vs cwf-manage validate scope (deterministic)**
  - The subagent reviews *judgement-call* security concerns: design intent, code patterns, and input-flow analysis where a human reviewer would form an opinion.
  - The subagent does **not** duplicate the deterministic checks already performed by `.cwf/scripts/cwf-manage validate` (which invokes `CWF::Validate::Security` and verifies SHA256 + recorded permissions against `.cwf/security/script-hashes.json`). Permission and hash-integrity violations are caught by `cwf-manage validate` and are out of scope for the subagent.
  - The threat-model categories the subagent MUST cover:
    - **(a) Bash injection / unsafe command construction** in skill scripts and helper scripts (e.g. interpolating task slugs, branch names, or file paths into shell commands without quoting; `system()` calls with concatenated user input).
    - **(b) Perl helpers consuming git or user output without `-z` / input validation** (per `docs/conventions/perl-git-paths.md`); shell-out via backticks where the input is partly user-controlled.
    - **(c) Prompt injection via user-supplied strings** reaching skill prompts (task descriptions, slugs, branch names, file content quoted into LLM context).
    - **(d) Unsafe environment-variable handling** influencing security-critical operations (e.g. `CWF_SOURCE` controlling which repo `cwf-manage update` clones from; unvalidated paths reaching `chmod`/`rm`).
    - **(e) Pattern-based risks** — patterns that are safe in the current callsite but would be exploitable if reused elsewhere (e.g. backtick execution of an argument that happens to be safe today). Report with explicit "safe here because X; audit future uses where X might not hold" framing rather than as a current defect.
  - Acceptance (sharper than just "categories present"): for each category, the canonical doc has (i) a one-line definition, (ii) at least one CWF-grounded anti-pattern example with file:line citation, (iii) a one-line "what to do instead" pointer.

- **FR5: Read-only subagent scope**
  - The security subagent MUST be restricted to `Read`, `Grep`, `Glob`. No `Bash`, no `Edit`, no `Write`. Same restriction as the existing 3 plan-review subagents.
  - Acceptance: subagent prompts in plan-review.md and exec-review (or wherever they live) explicitly list the allowed tools.

- **FR6: Actionable-findings-only output, with pattern-risk allowance**
  - The subagent reports only actionable findings (what is wrong, where, what to do). Aspirational suggestions ("consider rate limiting") are out of scope unless tied to a concrete CWF surface.
  - Pattern-based risk findings (FR4(e)) are *not* aspirational and ARE allowed: the subagent may flag a pattern that is safe at the callsite but risky if copy-pasted, with explicit "safe here because X; audit future uses where X might not hold" framing.
  - If the change is sound, the subagent says so briefly.
  - Concrete shape: actionable = "bash injection risk at `cwf-manage:127`: `\`git -C $dir tag\`` interpolates `$dir`; if `$dir` ever holds a slug or user-supplied path, this shells out unquoted. Quote: `\`git -C "$dir" tag\``." Non-actionable = "consider adopting Bash strict mode."
  - Acceptance: prompt includes the actionable-findings instruction near-verbatim from the existing 3 plan-review subagent prompts; explicitly carves out pattern-based risk per above.

### User Stories
- **As** a CWF developer **I want** security concerns surfaced during plan review **so that** I don't ship insecure designs that then need to be fixed in a follow-up task.
- **As** a CWF developer **I want** security review of the actual code I just wrote **so that** I catch concrete defects (input not escaped, file written world-readable, helper not handling NUL-separated git output) before retrospective.
- **As** a CWF maintainer **I want** the security prompt to live in one canonical doc **so that** the prompt evolves in one place and SKILL files don't drift.

## Non-Functional Requirements

### Performance (NFR1)
- Wall-clock cost of plan-review stays constant by construction: the 4th subagent is added to the same single-message Agent-call block. This is procedurally enforced by `.cwf/docs/skills/plan-review.md` §1 ("Launch all … Agent calls in a single message (parallel execution)") — no extra acceptance criterion required beyond conformance.
- Token cost per security subagent call: target ≤400 tokens of prompt (matching the upper end of the existing 3 prompts at ~250–400 tokens). The relaxation from 300 reflects FR4's expanded threat-model with 5 categories × file:line examples.

### Usability (NFR2)
- Output format MUST match existing plan-review subagent style ("what is wrong / where / what to do"). New format would force operators to learn two reading patterns.
- Doc cross-references MUST point at `.cwf/docs/skills/security-review.md` consistently; the user-facing built-in `/security-review` command is mentioned once at the top of the doc as a broader, branch-level alternative, not embedded in workflow steps.

### Maintainability (NFR3)
- Single canonical prompt doc (FR3). No copy-paste between SKILL files.
- Threat-model categories documented inline in the canonical doc with one-line descriptions, so a future maintainer can add a category without hunting for the prompt in 5 places.
- Plan-review.md and exec-review references MUST follow the progressive-disclosure convention from the new design-alignment doc (Task 122): SKILL.md files reference the doc, the doc owns the prose.

### Security (NFR4)
- The subagent itself MUST not be a security regression. Its tool allowlist is read-only (FR5); it cannot mutate state or shell out.
- The threat-model list (FR4) MUST itself be reviewed by the new subagent during this task's design and implementation phases — i.e. dogfood the subagent against its own design.

### Reliability (NFR5)
- The subagent has three distinguishable outcomes; the SKILL must record which:
  1. **findings** — list of actionable items per FR6
  2. **no findings** — review completed cleanly (includes empty-changeset case from FR2)
  3. **error** — subagent failed (timeout, malformed output, allowlist violation)
- Only state (3) triggers the existing failure-handling fallback in `.cwf/docs/skills/plan-review.md` §"Failure Handling" (synthesise remaining if 1–2 fail; warn-and-proceed if all fail). States (1) and (2) are both successful, both recorded.
- A "no findings" result MUST NOT be confused with subagent silence (timeout/error). The exec-phase SKILL records the verbatim subagent string so the distinction survives in the wf step file.

## Constraints
- British spelling in new prose (centre, behaviour, organise).
- The `find`/`sed`-avoidance rule (memory: `feedback_no_find_no_sed_permissions`) applies to **prescribed shell snippets that operators or skills run**. It does **not** apply to anti-pattern *examples* in the threat-model doc — those are illustrative source code, not prescribed commands. Anti-patterns may legitimately show vulnerable shell constructs to be recognised.
- Subagent allowlist matches existing plan-review subagents: Read, Grep, Glob only.
- The user-facing `/security-review` built-in command is *not* a callable dependency — it's user-invoked, branch-level. Design must not assume it can be chained.
- Must not change the BACKLOG entry "Add Security Verification to Testing Workflow" (it's about deterministic `cwf-manage validate`, a different concern). Add the boundary explicitly to the new canonical doc so future readers don't conflate the two.

## Decomposition Check
- [ ] **Time**: ~1 day → no
- [ ] **People**: single author → no
- [ ] **Complexity**: 5 SKILL files + 1 doc, but all variants of one pattern → no
- [ ] **Risk**: medium-tier risks all in-task mitigable → no
- [ ] **Independence**: plan-phase and exec-phase additions share the prompt doc; splitting forces duplicate threat-model survey → no

No decomposition.

## Acceptance Criteria
- [ ] **AC1**: `.cwf/docs/skills/plan-review.md` documents 4 subagents (FR1) with security row in the criteria-lookup table covering `requirements`, `design`, `implementation` plan types
- [ ] **AC2**: `.claude/skills/cwf-implementation-exec/SKILL.md` and `.claude/skills/cwf-testing-exec/SKILL.md` invoke the security subagent as a numbered top-level workflow step, with explicit empty-changeset handling per FR2
- [ ] **AC3**: `.cwf/docs/skills/security-review.md` exists; threat-model definitions live there only; plan-review.md and the two exec SKILLs reference it; no copy-pasted threat-model text outside the canonical doc
- [ ] **AC4**: For each of FR4(a–e), the canonical doc has (i) a one-line definition, (ii) at least one CWF-grounded anti-pattern example with file:line citation, (iii) a one-line "what to do instead". An auditor reading only the canonical doc can identify each required element per category.
- [ ] **AC5**: Subagent prompts in plan-review.md row 4 and the exec template both explicitly list the Read/Grep/Glob allowlist (FR5)
- [ ] **AC6**: Output style matches existing plan-review subagents (NFR2, FR6); pattern-based-risk carve-out present in the prompt
- [ ] **AC7**: Plan-review subagents (now 4) launched in a single Agent-call message — verifiable by reading the SKILL/doc instructions, not by timing
- [ ] **AC8 (deferred verification — exercised in g-testing-exec)**: The new security subagent is invoked against this task's own changes during g-testing-exec; the verbatim subagent output (findings / no findings / error) is recorded in g-testing-exec.md. This proves the subagent is wired correctly, not that it returns any particular verdict.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 123
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 6 FRs and 5 NFRs delivered. AC8 deferred-verification structure worked: chicken-and-egg case closed by g-testing-exec TC-AC8 with explicit findings/no-findings/error outcome handling.

## Lessons Learned
Plan-review subagents added load-bearing items at this phase (env-var threat category as a real surface; pattern-risk carve-out without which the subagent would suppress real signal).
