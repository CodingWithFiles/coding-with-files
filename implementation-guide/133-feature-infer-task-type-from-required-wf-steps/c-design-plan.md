# Infer task type from required wf steps - Design
**Task**: 133 (feature)

## Task Reference
- **Task ID**: internal-133
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/133-infer-task-type-from-required-wf-steps
- **Template Version**: 2.1

## Goal
Specify how the 2-arg form of `/cwf-new-task` and `/cwf-new-subtask` resolves a task type without invoking a new helper script: a shared rubric doc, LLM reasoning inside the skill, and the existing `task-workflow create` helper for the actual file copy.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### Decision 1: Inference lives in skill prose, not in a new helper script
- **Decision**: The inference logic is documented in a single rubric file under `.cwf/docs/workflow/` and executed by the LLM at skill-invocation time. No new Perl/Bash helper is introduced.
- **Rationale**: The inference is a one-shot judgement call over a fuzzy free-text description; that is the LLM's job, not a deterministic script's. Wrapping it in code would require either an NLP library (disallowed by NFR1/constraints) or hand-coded keyword heuristics (brittle and worse than LLM reasoning). The existing `task-workflow create`/`template-copier-v2.1` chain is unchanged.
- **Trade-offs**:
  - **+** No new code to maintain, hash, or audit. Smaller blast radius. Reversible by deleting the rubric doc + reverting two SKILL.md files.
  - **+** LLM can handle paraphrase and idiomatic descriptions without a keyword table.
  - **−** Non-deterministic — same description across LLM versions may pick differently. Mitigated by FR5 (prompt on ambiguity) and AC8 (resolution gate is finite-set, not free-text).

### Decision 2: Single rubric file at `.cwf/docs/skills/task-type-inference.md`
- **Decision**: One markdown file is the authoritative source of inference rules. Both `cwf-new-task/SKILL.md` and `cwf-new-subtask/SKILL.md` reference it by **hard-coded path** (no substitution from user input); no rubric prose is duplicated.
- **Rationale**: Progressive disclosure pattern used elsewhere in CWF (`.cwf/docs/skills/workflow-preamble.md`, `.cwf/docs/skills/checkpoint-commit.md`, `.cwf/docs/skills/plan-review.md` — all skill-referenced shared instructions live under `.cwf/docs/skills/`). Placing the rubric there matches that convention. One edit-point keeps the two skills in lock-step (FR7). Hard-coding the path eliminates a path-injection surface (see Security Threat Coverage).
- **Trade-offs**:
  - **+** Satisfies AC5 by construction.
  - **+** Documents the *why* of each task type for human readers as a side effect.
  - **−** Adds one Read call per 2-arg invocation; negligible cost on a single small file.

### Decision 3: Canonical step sets encoded as a table in the rubric doc (static, not runtime-discovered)
- **Decision**: The `{type → step-set}` mapping is encoded as a markdown table inside the rubric doc. The skill does **not** enumerate `.cwf/templates/<type>/` at runtime. Adding a new task type requires three coordinated data edits: (i) create `.cwf/templates/<new-type>/` with the appropriate template symlinks; (ii) add `<new-type>` to `cwf-project.json:supported-task-types`; (iii) add a row to the rubric doc's canonical-step-set table.
- **Rationale**: Three converging considerations:
  - **Security**: runtime FS enumeration via Bash glob is the threat-category-(a) anti-pattern (bash injection via crafted directory names). Avoiding the FS scan removes the surface entirely.
  - **Simplicity**: the rubric must already be updated when a new type is added (the LLM needs to know what the new type *means*), so deriving step sets from FS adds a second source of truth without removing the first.
  - **Determinism**: a static table in markdown is trivially auditable and version-controlled; runtime discovery is not.
  - This relaxes the literal wording of FR6 ("read from filenames") but preserves its intent ("adding a new task type requires no skill code changes"). The change is recorded here as a deliberate requirements relaxation.
- **Trade-offs**:
  - **+** No Bash call at skill invocation; no permission prompts; no shell-glob attack surface.
  - **+** Single source of truth (the rubric) with a stable, auditable schema.
  - **−** A drift risk: someone could add `.cwf/templates/foo/` without updating the rubric. Mitigation: `cwf-security-check` (or a future linter) can compare the two; for this task, document the three-step add-a-type procedure in the rubric doc itself.

### Decision 4: Closest-fit by symmetric difference, with always-prompt-on-non-exact
- **Decision**: Given inferred step set `S` and candidate type `T` with canonical step set `C_T`, distance is `|S Δ C_T|` (size of symmetric difference). The skill picks the type with the smallest distance and proceeds silently iff distance == 0 (exact match). For any non-zero distance, or any tie at distance 0 across multiple types (impossible in practice — canonical sets are distinct), the skill prompts the user.
- **Rationale**: "Closest fit" without an exact match is fundamentally a judgement call about which omitted step the user implicitly wanted. The conservative answer is to ask, not guess. The 5 canonical task types cover 5 of the 16 `(b,c,h,i)` combinations; the other 11 either don't occur in practice or warrant a human decision.
- **Trade-offs**:
  - **+** Simple, explicable algorithm; one inequality test.
  - **+** Eliminates silent misclassification (Task 59's failure mode).
  - **−** Prompts on edge cases (~11/16 of the combinatorial space) — but those should be rare given canonical-pattern bias in real descriptions.

### Decision 5: Type validation still routes through `template-copier-v2.1::validate_task_type`
- **Decision**: After the skill resolves a type string, it passes that string to the existing `task-workflow create` helper unchanged. The helper continues to validate against `cwf-project.json:supported-task-types`.
- **Rationale**: Two-stage validation: the skill enumerates `.cwf/templates/` to *propose* a type; the existing helper *enforces* it via config. If the two disagree (e.g. a stray `.cwf/templates/foo/` directory without a config entry), the helper's error message points the user at the config — a clear remediation path.
- **Trade-offs**:
  - **+** Zero changes to the helper script's interface or internals.
  - **−** A user adding a new type must update *two* places (template dir + config). Documented in the rubric doc.

## System Design

### Component Overview
1. **Rubric doc** — `.cwf/docs/skills/task-type-inference.md` (new file). Sections: step semantics, inference questions, closest-fit algorithm, ambiguity-prompt format. Read at skill execution.
2. **`cwf-new-task/SKILL.md`** (modified) — adds a conditional inference block that runs when `<type>` is omitted from the argument list. Inference block references the rubric doc.
3. **`cwf-new-subtask/SKILL.md`** (modified) — same conditional inference block, referencing the same rubric doc.
4. **Existing `task-workflow create`** (unchanged) — accepts a resolved type string; validates against `cwf-project.json`; copies templates.
5. **Existing `.cwf/templates/<type>/`** (unchanged) — source of truth for canonical step sets.
6. **Existing `cwf-project.json:supported-task-types`** (unchanged for this task) — authoritative list of valid types.

### Data Flow (2-arg form)
```
1. User invokes /cwf-new-task <num> "<description>"
2. SKILL.md argument parser:
   - If 3 positional tokens after the command AND the second token is a member
     of cwf-project.json:supported-task-types → treat as 3-arg form (skip inference)
   - Else → treat as 2-arg form (continue below)
3. SKILL.md reads the rubric at the hard-coded path
   .cwf/docs/skills/task-type-inference.md (Read tool)
4. LLM applies rubric to description → step set S = {a, d, e, f, g, j} ∪ {b? c? h? i?}
5. SKILL.md reads the canonical-step-set table from the rubric (already loaded)
   and computes |S Δ C_T| for each candidate type T
6a. If exactly one T has distance 0 → use that T silently
6b. Otherwise → AskUserQuestion-style prompt naming top candidates and the
    step letters that differ
7. Resolved type passed to task-workflow create (existing helper, unchanged)
8. Existing flow: directory creation, git branch checkout, next-step suggestion
```

The 3-arg form skips steps 3–6 entirely.

### Rubric Doc Interface (`.cwf/docs/skills/task-type-inference.md`)
**Schema** (markdown headings):
- `# Task Type Inference`
- `## Step Semantics` — table mapping each wf step letter (a–j) to its purpose and the question that determines its inclusion
- `## Always-Required Steps` — names the steps every task type has (a, d, e, f, g, j) and explains why
- `## Discriminating Questions` — four yes/no signals: `b` (requirements?), `c` (design?), `h` (rollout?), `i` (maintenance?), each with prompts that help the LLM judge from a description
- `## Resolution Algorithm` — exact pseudocode-free description of the symmetric-difference rule, exact-match-wins-silently, ambiguity-prompts-always
- `## Ambiguity Prompt Format` — example of what the skill shows the user (which candidates, which step letters differ)

The rubric doc is read by skills *and* serves as human-readable documentation for the rationale behind task types. No code parses it.

### Inference Question Table (rubric content preview)

| Letter | Step | Include when… |
|---|---|---|
| a | task-plan | Always |
| b | requirements | The work has fuzzy or elastic acceptance criteria; the user describes outcomes rather than a specific change; multiple plausible "what should it do?" interpretations exist |
| c | design | Multiple plausible *how* approaches exist; the change touches an interface boundary or architectural seam; non-trivial trade-offs need to be recorded |
| d | implementation-plan | Always |
| e | testing-plan | Always |
| f | implementation-exec | Always |
| g | testing-exec | Always |
| h | rollout | Changes end-user-visible behaviour, deploy surface, or external contract; needs migration, announcement, or coordinated cutover |
| i | maintenance | Introduces something requiring ongoing care (cron, dashboard, deprecation window, runbook entry, monitoring) |
| j | retrospective | Always |

Mapping to canonical types:

| Type | (b,c,h,i) | Step set |
|---|---|---|
| chore | (0,0,0,0) | a,d,e,f,g,j |
| hotfix | (0,0,1,0) | a,d,e,f,g,h,j |
| bugfix | (0,1,0,0) | a,c,d,e,f,g,j |
| discovery | (1,1,0,0) | a,b,c,d,e,f,g,j |
| feature | (1,1,1,1) | a,b,c,d,e,f,g,h,i,j |

### Skill Modification Interface

For both `cwf-new-task/SKILL.md` and `cwf-new-subtask/SKILL.md`, the argument-parsing section gains:

```
**Parse arguments**: `<num> [<type>] "<description>"`
  Disambiguation rule:
    - If a token between <num> and the (quoted) description matches a value in
      cwf-project.json:supported-task-types, that token IS <type>; proceed to
      validation and the existing 3-arg flow with no inference.
    - Otherwise <type> is treated as omitted; invoke type inference (see
      .cwf/docs/skills/task-type-inference.md).
  Edge case: a description that happens to be a single bare type-name word
  (e.g. "feature") must be quoted or the 3-arg form will swallow it as <type>.
  This is acceptable because such descriptions are degenerate and the slug
  validation in template-copier-v2.1 would reject them anyway.
```

A short "Type inference" subsection in each SKILL.md links to the rubric doc and lists the 4 steps the LLM performs (read rubric → infer S from description signals → compute distances against rubric's canonical table → pick if exact match, else prompt). The rubric itself is not inlined.

### Ambiguity Prompt Format (example)

When no exact match exists, the skill shows the user something like:

```
No exact task-type match for description: "Investigate why X is slow and fix it"
Inferred steps: a, b, c, d, e, f, g, j  (requirements + design + standard execution + retrospective, no rollout/maintenance)

Closest matches:
  1. discovery  (distance 0 if you don't need rollout)  — differs in: none (exact)
  2. feature    (distance 2)                            — differs in: h, i (would add rollout + maintenance)
  3. bugfix     (distance 1)                            — differs in: b   (would drop requirements)

Pick a type (1/2/3), or rerun with explicit type (e.g. /cwf-new-task <num> feature "...").
```

The exact prose lives in the rubric doc; the skill copies the form. Response handling: a numeric pick maps to a candidate; any other input cancels and shows the 3-arg form hint.

## Failure Modes and Recovery
Listed in order of likelihood. In all cases the skill refuses gracefully **before** any directory creation or git branch checkout — the existing 3-arg flow is the recommended fallback. No half-created tasks.

1. **Rubric file missing or unreadable.** The Read tool returns an error. The skill displays `Type inference unavailable: cannot read .cwf/docs/skills/task-type-inference.md. Re-invoke with explicit <type> (e.g. /cwf-new-task <num> feature "...").` and exits without side effects.
2. **LLM produces a malformed step set.** Any letter outside `a–j`, missing one of the always-required `{a, d, e, f, g, j}`, or unparseable output → skill displays the malformed output, asks the user to pick a type explicitly via the 3-arg form, and exits.
3. **Inferred set is far from every canonical type.** If the minimum distance across all candidate types is ≥ 3 (i.e. no type fits within 2 differing step letters), treat as a degenerate inference: display the inferred set, all candidate types with their distances, and the 3-arg form hint. Refuse to auto-pick or auto-prompt — a distance of 3+ usually means the rubric or the description is wrong, not that one of the canonical types is "close enough".
4. **User cancels the ambiguity prompt** (response not in `1..N`): skill exits with the 3-arg form hint. No directory created.
5. **Type resolved but rejected by `template-copier-v2.1::validate_task_type`** (rubric/config drift). The existing helper's error message already names `supported-task-types`; the skill displays it verbatim and exits. Drift is rare and self-healing (the next user of the new type will fix the gap).
6. **Description fails slug validation** (existing `generate_slug` rule, ≤50 chars, allowed chars): existing helper error path. No change.

For each failure: **no `task-workflow create` call is made, no git branch is created, no files are written**. The user sees a clear message and a copy-pastable 3-arg form fallback.

## Security Threat Coverage
Mapping against `.cwf/docs/skills/security-review.md` § "Threat categories":

- **(a) Bash injection / unsafe shell composition**: avoided by Decision 3 — no Bash glob over `.cwf/templates/*/` at runtime. The skill's only Bash use is the existing `BASELINE_COMMIT=$(git rev-parse HEAD)` line, which is unchanged.
- **(b) Unsafe Perl-side git/output handling**: not applicable. No new Perl code; the existing `template-copier-v2.1` chain is unchanged.
- **(c) Prompt injection via free-text**: addressed at two layers. First, the rubric path is **hard-coded** in the SKILL.md prose (Decision 2) — a description cannot redirect the rubric read. Second, the type-selection gate is a finite-set lookup against the rubric's canonical table; the description influences the LLM's step-set inference but cannot select a type directly. AC8 tests this.
- **(d) Unsafe environment-variable handling**: no new env vars (requirements NFR4 reaffirmed). The skill reads the rubric from a hard-coded path and the supported-types list from `cwf-project.json` (existing `template-copier-v2.1::load_config` path).
- **(e) Pattern-based risks**: file permissions and write paths inherit from `template-copier-v2.1` (unchanged). The skill performs only Read operations on the rubric; no new write paths are introduced.

## Constraints
- No new helper scripts (per requirements NFR3).
- No new env vars (per requirements NFR4).
- No changes to `template-copier-v2.1` interface.
- POSIX-only, British spelling, no personal names in committed docs.

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people on parts? No.
- [ ] **Complexity**: 3+ distinct concerns? No — one rubric doc + two SKILL.md edits + tests.
- [ ] **Risk**: High-risk isolation needed? No.
- [ ] **Independence**: Parts separable? No — they must ship together.

**Decomposition not needed.**

## Validation
- [ ] Design satisfies FR1–FR7 (manually traced in rubric + skill changes)
- [ ] No code path bypasses `template-copier-v2.1::validate_task_type`
- [ ] AC6 verified by stub-type test fixture (added in e-testing-plan)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
