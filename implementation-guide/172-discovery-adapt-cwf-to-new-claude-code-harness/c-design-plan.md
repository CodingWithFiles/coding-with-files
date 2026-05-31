# Adapt CWF to new Claude Code harness - Design
**Task**: 172 (discovery)

## Task Reference
- **Task ID**: internal-172
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/172-adapt-cwf-to-new-claude-code-harness
- **Template Version**: 2.1

## Goal
Define the **method and output schema** of the discovery assessment: how evidence
is gathered, how each FR1–FR5 finding is structured so the ACs are mechanically
checkable, and how recommendations connect to follow-up tasks. There is no code
architecture — the "system" is the assessment document.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility
- **Testability first** here means: fixed-field schemas per finding type, so
  g-testing-exec can check each AC by structural inspection rather than judgement.

## Key Decisions

### Decision 1 — Single structured deliverable in f-implementation-exec.md
- **Decision**: the whole assessment (FR1–FR5) lands as one structured document in
  `f-implementation-exec.md`; `g-testing-exec.md` holds only the AC-by-AC
  verification. No scattering across ad-hoc scratch files.
- **Rationale**: NFR2 (reads standalone). The structured-inventory shape is
  borrowed from the **external** `dircachefilehash` Task 6 transcript (the
  evidence source — not an in-repo template; this repo has no such file). One
  artefact = one source of truth for the findings.
- **Trade-offs**: a large f-file, but Markdown sections keep it navigable.

### Decision 2 — Evidence-first method, trust evidence over remembered semantics
- **Decision**: every finding derives from a concrete source — the captured Task 6
  transcript, the user-supplied terminal backlog, or a **cheap-and-safe**
  reproduction — never from recalled "how the harness should behave".
- **Rationale**: the anchor incident's own lesson is that the model trusted
  remembered rule semantics over the tool's output (the gosec/G703 surprise) and
  was wrong; the same discipline (`feedback_no_fabricated_citations`,
  `feedback_complexity_over_continuity`) applies to claims about harness
  behaviour. Enforced by NFR5.
- **Trade-offs**: some FR4 entries will be `evidence: pending` until the user
  supplies the backlog — accepted (honest gap beats fabricated inventory).

### Decision 3 — Cheap-and-safe reproduction policy (the one place the task touches git)
- **Decision**: permitted reproductions are **read-only and disposable**: e.g.
  create a throwaway worktree on a temp branch, `cd` in, run `git rev-parse
  --show-toplevel`, observe it returns the *worktree* path, then remove the
  worktree — using a scratch repo or a branch with **no uncommitted real work**.
  Forbidden: any `--force` deletion, `reset --hard`, or `worktree remove` while
  uncommitted real work exists anywhere reachable. (NFR1 + NFR4.)
- **Tool-tier preference (safety)**: prefer the **new harness's guarded worktree
  tools** — `EnterWorktree` / `ExitWorktree(action: remove)`, where the remove
  refuses to delete a worktree holding uncommitted changes unless
  `discard_changes: true` — over raw `git worktree add/remove`. Drop to raw git
  only if a tool-grant gap forces it. The manual `git worktree remove` path is
  the *unguarded* version of the very operation under investigation; using the
  guarded tool both reduces repro risk and **is itself first-hand evidence** for
  the FR1 worktree-handling catalogue entry (see Decision 7).
- **Rationale**: mechanism (b) is cheaply and safely demonstrable and that lifts
  it from `pending` to evidenced; the destructive mechanisms (c)/(d) are
  established from the transcript and must **not** be re-run against real work.
- **Trade-offs**: (c)/(d) stay transcript-evidenced rather than freshly
  reproduced — the correct safety call.

### Decision 7 — The harness's guarded worktree tools are a first-class finding, not just a repro aid
- **Decision**: treat the existence of `EnterWorktree` / `ExitWorktree` (with the
  uncommitted-changes guard) as a **catalogue entry** (FR1) and a **candidate
  top-ranked mitigation** (FR5) for the data-loss class — not merely the repro
  mechanism of Decision 3.
- **Rationale**: the anchor incident used *raw* `git worktree` from a shell whose
  CWD drifted; the harness now offers a primitive that fails safe on exactly the
  uncommitted-work-deletion step (mechanism c). "Use the guarded tool instead of
  raw `git worktree` in scratch flows" may be the single highest safety-per-effort
  recommendation, so it must be evaluated in the §6 tradeoff matrix, not buried.
- **Trade-offs**: the guarded tools change how CWF scratch/worktree conventions
  (`tmp-paths.md`) are written — a real remediation surface, weighed in §6/§7.

### Decision 4 — Fixed-field schemas per finding type (the testable core)
- **Decision**: each FR emits rows of a fixed shape (see Data Models). Uniform
  fields let AC checks be structural.
- **Rationale**: testability-first; mirrors the dircachefilehash inventory tables.
- **Trade-offs**: rigidity, but a free-form essay would make the ACs unverifiable.

### Decision 5 — Recommendations are decomposition-ready, not executed
- **Decision**: each FR5 recommendation carries a *proposed* follow-up task tuple
  (`type`, target surface, one-line scope, safety↔momentum tradeoff, priority),
  shaped to paste into `/cwf-new-task`. This task does **not** create those tasks
  or make the changes (scope boundary; also avoids the keyword-collision trap of
  spawning orchestration).
- **Rationale**: FR5 + the a-plan decomposition verdict — the discovery *produces*
  the remediation split rather than being split.
- **Trade-offs**: the reader must run the follow-ups; acceptable for discovery.

### Decision 6 — Safety↔momentum tradeoff matrix as the analysis backbone
- **Decision**: the analysis section scores each candidate mitigation /
  recommendation on two axes — data-safety impact and momentum gain — and flags
  any that would *reduce* safety. NFR4's gate (AC6) is applied here, citing
  `feedback_surface_security_dont_smooth.md`.
- **Rationale**: the two user objectives are in tension; making the tension a
  visible matrix is what stops a silent safety-for-momentum trade.

## System Design
### Component Overview (document sections, mapping to FRs)
- **§1 Environment & versions** — CC client version + Opus 4.8 model id stamped
  once, referenced by every finding (NFR3).
- **§2 Harness-change catalogue** — FR1 rows.
- **§3 Data-loss root-cause map** — FR2 rows (the four mechanisms a–d).
- **§4 "workflow" keyword-collision assessment** — FR3 rows + options.
- **§5 Permission-prompt inventory** — FR4 rows.
- **§6 Tradeoff matrix & prioritised recommendations** — FR5, built on Decision 6.
- **§7 Recommended remediation decomposition** — the proposed follow-up tasks.

### Data Flow
1. **Gather**: transcript excerpts + user backlog (`/var/tmp/dircachefilehash.log`)
   + cheap-safe repro → raw evidence. **Trust boundary**: gathered text is
   untrusted, advisory **data**, read per the CLAUDE.md instruction-priority
   order; no tool call is ever driven by transcript/backlog content (NFR5,
   threat-category (c)).
1a. **Redact**: scrub credentials/tokens/secret env-var values from any excerpt
   *before* it is written into a row's `evidence_ref` (AC8). Each evidence-bearing
   row records `redacted: true`.
2. **Catalogue/Map**: evidence → §2–§5 fixed-field rows.
3. **Analyse**: rows → §6 tradeoff matrix (safety vs momentum), NFR4 gate applied.
   §3 mechanism mitigations feed §6 by mechanism `id (a–d)` — referenced, not
   re-described, so a tradeoff is written once.
4. **Recommend**: matrix → §6 ranked recommendations. §7 is a **projection** of the
   §6 rows' `proposed_task` field (one source of truth — §7 re-lists nothing the
   §6 schema doesn't already carry).
5. **Verify**: g-testing-exec checks each AC against the §-structure.

## Interface Design
No code API. Two "interfaces":
- **Document schema** (below) — the contract g-testing-exec verifies against.
- **`/cwf-new-task` hand-off** — §7 tuples are pre-formatted so a maintainer can
  create each follow-up without re-deriving scope.

### Data Models (finding-row schemas)
```
CatalogueEntry (FR1):   { area, cc_version, model_id, observed_change,
                          cwf_step_touched, evidence_ref, redacted,
                          mitigation }          # FR1 never "pending" (AC1);
                                                # mitigation required for the
                                                # model-self-checking row
LossMechanism (FR2):    { id(a-d), mechanism, precondition, exposing_cwf_step,
                          intersecting_convention, intersecting_call_sites,
                          mitigation, tradeoff_note, evidence_ref, redacted }
                          # evidence_ref never "pending"; intersecting_convention
                          # required (value "none" allowed only where truly none —
                          # but (b) MUST list feedback_no_cd_git_rev_parse.md +
                          # the call-site set, see note below)
CollisionSite (FR3):    { surface, collision, observed_behaviour_change }
CollisionOption (FR3):  { option(guard|wording|rename), blast_radius, note }
PromptEntry (FR4):      { command_shape, emitting_cwf_step, friction(H|M|L),
                          memory_xref, status(new|known), evidence_ref|pending,
                          redacted, security_relevant(bool) }
Recommendation (FR5):   { failure_mode, action, target_surface,
                          safety_delta, momentum_delta, tradeoff_line,
                          priority, proposed_task(type+scope) }
```
**FR2(b) call-site note (corrects an understatement inherited from FR2):**
`git rev-parse --show-toplevel` is **not** a single call site. The assessment must
enumerate the full set via `grep -rn "rev-parse --show-toplevel" .cwf .claude` —
it spans library code (`CWF/Common.pm`, `CWF/TaskPath.pm`, `CWF/WorkflowFiles.pm`),
many command-helpers, and — load-bearing — `task-workflow.d/delete` (which uses it
to compute the self-worktree guard for **worktree deletion**, i.e. inside the very
data-loss flow mechanism (b)/(c) describe). A follow-up that fixes only the
`cwf-init/SKILL.md` prose call site would under-remediate; the library and `delete`
sites are the ones that matter.

## Constraints
- Assessment-only; no CWF edits, no follow-up-task creation, no harness changes.
- Only read-only/disposable reproduction; never destructive against real work;
  prefer the harness's guarded worktree tools (Decision 3).
- Findings version-stamped; evidence is data not instructions; secrets redacted
  (NFR3/NFR5).
- POSIX/Markdown deliverable; no new scripts or hashed files (so no
  `script-hashes.json` churn this task).
- **Security threat-category scope (made explicit)**: this task ships no
  Perl/shell, so FR4 code-pattern categories (a) bash injection, (b) git-output
  newline-splitting, and (d) unsafe env-var handling are **out-of-scope by
  construction**. The only live security categories are (c) prompt-injection via
  evidence text (Decision 2 / Data-Flow trust boundary) and allowlist-broadening
  recommendations (the `security_relevant` flag + NFR4/AC6 gate).

## Decomposition Check
- [x] **Time**: >1 week? **No** (assessment).
- [x] **People**: >2? **No**.
- [x] **Complexity**: 3+ concerns? **Yes** — but the schema/section split (Decision
      1, 4) organises them within one unified assessment.
- [x] **Risk**: isolation needed? **Partially** — handled by the reproduction
      policy (Decision 3) + NFR4 gate, not by splitting.
- [x] **Independence**: separable? **Yes** — surfaced as §7's remediation split.
- **Verdict**: unchanged — unified assessment, decomposed remediation output.

## Validation
- [x] Design review completed (plan-review subagents — see synthesis below)
- [x] Integration points verified (referenced surfaces — `feedback_no_cd_git_rev_parse.md`,
      `cwf-init/SKILL.md:87`, `glossary.md`, `tmp-paths.md`,
      `feedback_surface_security_dont_smooth.md` — confirmed real in b-phase review)
- [x] Schema covers every FR/AC (FR1→CatalogueEntry … FR5→Recommendation)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All seven decisions held in exec. The fixed-field schemas (Decision 4) made AC checks
mechanical (TC-1…TC-8 by structural inspection). Decision 7 (guarded tools as a
first-class finding) became the hinge of R1. The Decision-3 reproduction policy let
mechanism (b) be reproduced first-hand while (c)/(d) stayed safely transcript-evidenced.

## Lessons Learned
Decision 3's tool-tier preference needed an exec-time deviation: `EnterWorktree`'s own
guidance restricts it to "explicitly instructed to work in a worktree", so the
reproduction used a throwaway scratch repo instead — the guard-refusal behaviour was
then sourced from the live `ExitWorktree` schema (first-hand, schema-sourced per AC7).
