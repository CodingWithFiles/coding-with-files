# Aggregate cross-project retrospective lessons - Implementation Execution
**Task**: 219 (discovery)

## Task Reference
- **Task ID**: internal-219
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/219-aggregate-cross-project-retrospective-lessons
- **Template Version**: 2.1

## Goal
Execute the map-reduce corpus pipeline and record the corroborated, novelty-filtered,
per-axis CwF improvement recommendations.

---

## §1 Method & coverage reconciliation

**Pipeline** (per c-design-plan / d-implementation-plan): deterministic survey →
parallel MAP of read-only extraction agents (one per project/shard) + a session-log
miner + per-axis LMM sweeps → orchestrator reconcile → two-stage reduce (per-axis then
global) → this deliverable. All mined text treated as untrusted data; the orchestrator
is the sole writer; digest filenames derive from the dispatch key, not agent-returned
fields.

**Survey denominator** (tracked `{h,j}-retrospective.md`, both conventions, 11 project
roots, 2026-07-07): **601**. No survey-level gaps (all roots readable).

**Coverage reconciliation** (survey-authoritative):

| Project | Survey | Scanned (union) | Residual |
|---|---:|---:|---:|
| coding-with-files | 214 | 191 | 23 |
| gate-to-breakout-tech | 101 | 65 | 36 |
| lmm | 105 | 105 | 0 |
| thenetworking.app | 76 | 71 | 5 |
| dircachefilehash | 37 | 37 | 0 |
| lensman | 25 | 26 | −1 |
| omnilsp | 24 | 25 | −1 |
| terminfo | 11 | 11 | 0 |
| gresearch | 5 | 6 | −1 |
| gocryptoknock | 2 | 3 | −1 |
| cwf-install-test | 1 | 1 | 0 |
| **Total** | **601** | **541** | **~60** |

- **541 / 601 (~90%) of tracked retros read.** The reconciliation step caught two
  first-pass mis-slices (gate/lmm shard splits) and one range gap (cwf 196+); all three
  were closed by gap-fill extractors (lmm now reconciles exactly).
- **Residual ~60 = subtask retros** (decimal-numbered, e.g. `28.1`, `3.2`) nested inside
  already-covered parent-task ranges — same projects, same eras. Logged, not smoothed;
  they would reinforce the findings below, not overturn them (every general finding
  already has 3–8 project corroboration).
- Negative residuals (lensman/omnilsp/gresearch/gocryptoknock, −1 each) are untracked
  on-disk in-flight retros not in the tracked survey count. Expected; logged.

**Friction-signal overlay**: session-log miner over the `cwf-permissions-block` (6.4 MB,
`d63455c3…`) and `atch` non-CwF baseline (`39b08569…`) sessions; three per-axis LMM
sweeps (`github@mattkeenan.net`). No overlay gaps.

**Corroboration rule**: a finding is **general** iff ≥2 *external* projects corroborate
(this repo counts ≤1). **Novelty** diffed against `MEMORY.md`, feedback memories,
`error-patterns.md`, `docs/conventions/`, `.cwf/docs/conventions/`.

---

## §2 Findings by axis

Tag key: **[G]** general (≥2 external projects) · **[S]** single-project · novelty in
*italics*.

### Axis 1 — Token efficiency

- **T1 — Per-subagent context re-initialisation overhead** *(net-new)* **[G-ish]**.
  Every subagent spawn re-sends the deferred-tools listing (30+ names, ~3–4k tokens),
  permission-mode, agent-listing, and MCP instructions — no delta model; the
  permission-analysis session read 338k cached tokens vs 57k in the non-CwF `atch`
  baseline (~6×). CwF *amplifies* this: plan-review runs 4–5 agents/phase across ~10
  phases, and this task alone spawned 19. Harness-owned at root, but CwF's agent-heavy
  design is the multiplier. Source: session-miner; this-repo 5-reviewer MAP.
- **T2 — Over-scripted testing-exec re-verifies unchanged artefacts** *(net-new)* **[G]**.
  Heavy AC pipelines re-run when the artefact is unchanged since f-exec; "read the
  artefact" is the right default for ≤500-line unchanged files. Source: thenetworking
  (1,10), this-repo.
- **T3 — Stale/unsourced counts in backlog/plan prose taken at face value** *(under-enforced —
  `error-patterns.md` names it, still recurs)* **[G]**. "8-byte offset" was 12
  (dircachefilehash 24); "13 sites" was 6 (this-repo 172); backlog "10–100×" measured
  3.1–8.6× (lmm 102). Source: dircachefilehash (3,24,31), this-repo (150,160,172,173),
  lmm (102).
- **T4 — Discovery front-loading pays off** *(validates the discovery task type; positive)*
  **[G]**. Comprehensive discovery → follow-ups 60–70% faster (unknowns pre-resolved).
  Source: lmm (68-69,82,94), this-repo (178). *No action — evidence the pattern works.*

### Axis 2 — Permission-prompt reduction

- **P1 — Shell operators & command decoration defeat the Bash allowlist** *(codified as
  ~10 scattered avoidance memories; under-enforced as a whole; net-new packaging)* **[G]**.
  The session miner quantified it: operators (`|`, `&&`, `;`, `$()`, `>`, redirects)
  defeat the allowlist ~45–55% of the time; `git -C`, `cd &&`, `cat`/`head`/`tail`,
  inline `-c`/`-e` (~15%), `awk` (~10%), heredocs, `find` abs-path, `perl <script>` all
  trip prompts. Corroborated in retros as concrete cost: this-repo (39,132 — "~20×
  slowdown", 205/206), lmm (96,98), omnilsp (23,24 — commit-message globs), gate (1),
  lensman (2), terminfo (1), dircachefilehash. **7+ projects.** The rules exist
  (`no_heredocs`, `no_find_no_sed`, `no_tee`, `no_echo_exit`, `chmod_and_execute`,
  `sleep_git_prefix`, …) but as ~10 separate memories each project re-learns; the
  path-injection hook that fixed the `$()`/`cd` case (Task 206) is **this-repo-only** and
  not shipped.
- **P2 — Unpathed `.cwf` helper calls & missing allowlist seed** *(net-new)* **[G-ish]**.
  Unpathed helper invocations trip the same prompt as unpathed script calls (this-repo
  216); a standing wrapper removes repeated cross-repo friction (lmm 105 test-DB
  wrapper; session-miner `cwf-git` suggestion). New projects inherit no allowlist.
- **P3 — tool-check hook fails open from a subdirectory** *(net-new; security-relevant)*
  **[S, severe]**. Verified 2026-06-14: a bare relative hook path `.cwf/scripts/hooks/…`
  doesn't resolve when cwd is a subdir → **all** tool-check rules silently skip. The
  guard is off with no signal. Source: session-miner.

### Axis 3 — SDLC friction

- **S1 — Security-review 500-line cap trips on test/generated/doc lines** *(partially
  addressed — Task 218 made the cap configurable, exclude-paths exists — but
  under-enforced: not defaulted at init)* **[G, dominant]**. Test files, sqlc/golden
  generated code, and CWF plan markdown count as "production", so the semantic review is
  skipped or the phase errors. **7 projects, ~40+ task instances**: omnilsp (11),
  lensman (8), terminfo (5), dircachefilehash (5), this-repo (166/168/174), lmm
  (93,100,104), thenetworking. Every project re-discovers and sets exclusions late,
  after being bitten.
- **S2 — Non-terminal Status leaks onto committed phase files** *(root-fix not codified;
  under-enforced — a status *sweep* is documented, the *cause* isn't fixed)* **[G]**.
  Planning skills set the *next* file's status but not their own, so phase files carry
  `Planning`/`Requirements`/invalid enums to the retrospective; `validate` warns but
  doesn't fail; a manual j-phase sweep cleans up. **8 projects**: omnilsp (6 tasks),
  lensman (3), terminfo (2), thenetworking (5+), this-repo (202,203), lmm (21,103),
  dircachefilehash, cwf-install-test.
- **S3 — CwF upgrade friction cluster** *(net-new as a consolidated runbook + a code fix)*
  **[G]**. `.cwf/version` is staged-deleted+rewritten-untracked every read-tree upgrade
  (manual `git add`); the update lock is acquired *before* the clean-tree check;
  predicting a hop requires reading the *installed* tool's source, not the target's;
  the CwF sandbox blocks in-session `cwf-manage update` (owner must run it unsandboxed);
  upgrades surface pre-existing permission drift (need `fix-security`). **5 projects**:
  lensman (6,12,17,23,25), lmm (88,92,100–104), dircachefilehash (5,9,14,22,29), gate
  (53), terminfo (6).
- **S4 — Plan-review is load-bearing but has blind spots** *(net-new refinements)* **[G]**.
  Universally credited with catching pre-code defects (positive), but misses cross-file
  coupling (TC assertions spanning test files), requirement contradictions (accept/reject
  sets), and produces false positives that cost a verification cycle; the REDUCE needs
  live-session context (subagents don't see the conversation). **5 projects**:
  thenetworking (14), omnilsp (2,3,5,10,11), terminfo (1,8), this-repo (160,163,174),
  dircachefilehash (2,5,14).
- **S5 — Late architecture/surface decisions cause design churn** *(net-new)* **[G]**.
  Surface/mechanism decisions (chat transport, firewall model, UUID anchor, project
  layout) surface at design or exec instead of task-plan, driving ~3× re-plans;
  mechanism-named ACs age badly after a pivot. **6 projects**: gocryptoknock (1),
  lensman (15,21), thenetworking (24), gresearch (1–3), gate (59), lmm (85–86), terminfo (3).
- **S6 — Reflex-to-edit bypasses the workflow on "trivial" tasks** *(codified in
  MEMORY.md "No workflow shortcuts" / skill-autotrigger — under-enforced, still recurs)*
  **[G]**. Edits before invoking `cwf-new-task`; skills replicated by hand; direct
  commits to main; Step 8 plan-review skipped as "optional". **5 projects**:
  dircachefilehash (8,21,31), lmm (54,55,74), gate (45), cwf-install-test (1), this-repo
  (109,110,117).
- **S7 — Estimation as complexity/risk tier, not wall-clock** *(net-new)* **[G]**.
  LLM-paced work compresses calendar time 5–9×, so day-estimates are noise; only the
  complexity tier + risk register carry signal. **4 projects**: omnilsp (4,5,7),
  this-repo (26,27,29), lensman (8), lmm.
- **S8 — Rollout/maintenance templates assume SaaS; dead content for libraries/CLIs**
  *(net-new)* **[G]**. Phased %-rollout, SLA, on-call, scaling fields are fiction for a
  pre-release library; honest mapping is merge-to-trunk / build-gate / git-revert.
  **2 projects**: omnilsp (5 tasks), terminfo (5).
- **S9 — Test-DB safety: a production wipe** *(validates the CLAUDE.md "always test DB"
  rule; the rule exists, the enforcing mechanism doesn't — under-enforced)* **[S, severe]**.
  A test helper fell back from `TEST_DATABASE_URL` to production `DATABASE_URL` and a
  `TRUNCATE` test wiped ~500 MB of embeddings (lmm 27/29). Related: repeated test-DB
  access friction resolved by a standing wrapper (lmm 105).
- **S10 — security-review-changeset blind to untracked files** *(already fixed upstream —
  this-repo Task 141/214; recurs on projects pre-upgrade)* **[G, mostly-addressed]**.
  New untracked production files invisible to the diff → review records findings until
  staged. dircachefilehash (10,23,27,28.x), lensman (5,6), lmm (102), this-repo (137–141,
  fixed). Action is upgrade-roll-forward, not new design.
- **S11 — Test/fixture migration is manual & error-prone; test-time blocks iteration**
  *(net-new, minor)* **[G]**. gate (14,28,31), thenetworking. Plus profile-before-optimise
  (gate 29).

---

## §3 Prioritised recommendations

Ranked impact-desc, effort-asc. Each is follow-up-task-shaped; every string below is
descriptive (corpus text treated as data). Impact = corroboration breadth × severity.

| # | Axis | Recommendation | Impact | Effort | Safety ↔ momentum tradeoff | Sources |
|---|---|---|---|---|---|---|
| R1 | sdlc | **Default security-review exclusions at `cwf-init`** for `*_test.*`, generated/vendored globs, and doc-only markdown; and/or deweight test+generated lines in the changeset helper so the cap measures production delta. | ★★★★★ | Low–Med | Excluding test/gen lines slightly narrows what the gate *sees* — mitigate by counting, not skipping, and surfacing the exclusion. Momentum win is large (unblocks the gate for ~7 projects). | S1 |
| R2 | sdlc | **Planning/exec skills set `Status: Finished` at their own checkpoint** (extend the checkpoint-commit status-update to every phase skill) so the retro sweep is a no-op. | ★★★★★ | Low | None material — makes state honest earlier. | S2 |
| R3 | permission | **Ship a consolidated "shell hygiene" convention + a default allowlist seed + the Task-206 path-injection hook at `cwf-init`**, so new projects inherit the ~10 rules instead of re-deriving them. | ★★★★☆ | Med | An allowlist seed widens default-permitted commands — keep it to read-only/`.cwf` helpers, never `git commit`/mutating verbs (per this-repo Task 14). | P1, P2 |
| R4 | sdlc | **Task-plan "unresolved decisions" gate**: name every open surface/mechanism/constraint (licensing, transport, layout) as an a-plan question; forbid mechanism-named ACs. | ★★★★☆ | Low | None — pure front-loading. | S5 |
| R5 | sdlc | **CwF upgrade runbook + fix `.cwf/version` read-tree churn** (auto-restage), document sandbox-off requirement and expect-perm-drift/`fix-security`. | ★★★★☆ | Med | The `.cwf/version` auto-restage touches the upgrade path — gate behind clean-tree check. | S3 |
| R6 | sdlc | **Estimation = complexity tier + risk register**; deprecate the day-effort field in `a-task-plan`. | ★★★☆☆ | Low | Losing calendar estimates removes a (noisy) planning signal — the risk register replaces it. | S7 |
| R7 | permission | **Bugfix: tool-check hook fails open from a subdirectory** — resolve the hook path from the git root, not cwd. | ★★★☆☆ | Low | Security-positive (a silently-disabled guard is worse than a noisy one). | P3 |
| R8 | sdlc | **Plan-review refinements**: add a testing-plan contradiction check (expected verdicts vs locked rules); instruct reviewers to verify against source before asserting; REDUCE weighs live-session corrections over subagent doc-citation consensus. | ★★★☆☆ | Low–Med | More review steps cost a little time; they cut false-positive verification cycles. | S4 |
| R9 | sdlc | **Fail-closed test-DB config** — never fall back to production `DATABASE_URL`; provide a standing test-DB wrapper. Enforces the existing CLAUDE.md rule. | ★★★☆☆ | Low | Fail-closed can block a test run on misconfig — that is the point (prevents prod wipes). | S9 |
| R10 | sdlc | **Library/internal task-type variant** with non-SaaS rollout/maintenance templates (merge-to-trunk / build-gate / git-revert). | ★★★☆☆ | Med | A new variant adds surface to maintain — justified by 2 projects filling SLA fields with fiction. | S8 |
| R11 | token | **Testing-exec: read-not-script default** for unchanged ≤500-line artefacts. | ★★☆☆☆ | Low | Less scripting = less mechanical proof; scope to *unchanged* artefacts only. | T2 |
| R12 | token | **Gate reviewer/agent count by changeset size** to curb per-spawn re-init token overhead (skip lens reviewers on trivial diffs). | ★★★☆☆ | Med | Fewer agents on small diffs = marginally less coverage where least needed. | T1 |
| R13 | token | **Extend `plan-mechanical-check` to flag unsourced count claims** ("N sites", "M bytes") for re-verification at plan time. | ★★☆☆☆ | Med | Adds a plan-gate check (advisory, non-blocking). | T3 |
| R14 | sdlc | **Fixture-migration helper + targeted-test guidance** (`-run` filters; profile-before-optimise) to cut test-time iteration cost. | ★★☆☆☆ | Med | Tooling to build/maintain; pays back on fixture-heavy projects. | S11 |

*Already-addressed (no new task): S10 (untracked-file blindness — fixed this-repo Task
141/214; action is roll the upgrade forward). T4 (discovery front-loading — keep doing).*

---

## §4 Seeded follow-up tasks

Each is a one-line proposed CwF task title (descriptive; a maintainer opens them via the
normal workflow):

1. **feature** — Seed default `security.review.max-lines-exclude-paths` (test/generated/doc) at `cwf-init` and deweight test lines in `security-review-changeset`. *(R1)*
2. **feature** — Set terminal `Status` at each phase's own checkpoint commit across all `cwf-*-plan`/exec skills. *(R2)*
3. **feature** — Ship a consolidated shell-hygiene convention, default allowlist seed, and the path-injection hook at `cwf-init`. *(R3)*
4. **feature** — Add an "unresolved decisions" gate to `a-task-plan` and forbid mechanism-named acceptance criteria. *(R4)*
5. **feature** — CwF upgrade runbook; fix `.cwf/version` read-tree restage; document sandbox-off + expect-perm-drift. *(R5)*
6. **chore** — Replace the `a-task-plan` day-effort field with a complexity tier + risk register. *(R6)*
7. **bugfix** — Resolve tool-check hook paths from the git root so rules don't silently skip from a subdirectory. *(R7)*
8. **feature** — Plan-review: testing-plan contradiction check + verify-before-assert + REDUCE live-context weighting. *(R8)*
9. **feature** — Fail-closed test-DB configuration + standing test-DB wrapper. *(R9)*
10. **feature** — Library/internal task-type variant with non-SaaS rollout/maintenance templates. *(R10)*
11. **chore** — Testing-exec read-not-script default for unchanged small artefacts. *(R11)*
12. **feature** — Size-gate reviewer/agent fan-out on trivial changesets. *(R12)*
13. **chore** — Extend `plan-mechanical-check` to flag unsourced count claims. *(R13)*
14. **feature** — Fixture-migration helper + targeted-test/profile-first guidance. *(R14)*

*Incidental defect observed during this task (not corpus-derived): `plan-mechanical-check`
emitted `Wide character in print at …/ArtefactHelpers.pm line 73` — a UTF-8 output
defect (missing `binmode`/`PERL5OPT=-CDSLA` on that emit path). Worth a small bugfix task.*

---

## Actual Results (per d-implementation-plan step)

- **Step 1 Setup** — *Actual*: scratch leaf pre-provisioned; `digests/` created; inputs
  (11-root list, axis taxonomy, cap=12, schema) fixed. *Deviation*: none.
- **Step 2 Survey** — *Actual*: `survey.sh` counted both `{h,j}` conventions via
  `git -C <root> ls-files -z … | grep -zc .`; denominator 601; no survey gaps.
  *Deviation*: used `git -C` inside the one-off script (internal to the script process,
  no per-call prompt) rather than a cwd-scoped call — acceptable for a cross-repo survey.
- **Step 3 Parallel MAP** — *Actual*: 15 sharded read-only extractors + 1 session-miner
  launched together; 3 LMM axis sweeps run by the orchestrator. *Deviation*: LMM sweeps
  executed as orchestrator tool-calls (not a separate agent) — miners still peers of the
  map in time.
- **Step 4 Persist + reconcile** — *Actual*: digests written under dispatch-key filenames;
  reconciliation caught 2 mis-slices + 1 range gap → 3 gap-fill extractors → 541/601
  (~90%), residual ~60 subtask retros logged.
- **Step 5 Two-stage reduce** — *Actual*: per-axis clustering → corroboration filter
  (≥2 external) → novelty diff against the 5 baselines → ranked. §2/§3 above.
- **Step 6 Deliverable** — *Actual*: §1–§4 written; 14 recommendations, 14 seeded tasks.

## Blockers Encountered
None. (Shard mis-slicing was caught and closed by the reconciliation step, as designed.)

## Deferral Check
- [x] All d-plan steps executed
- [x] a-plan success criteria met (corpus digested, per-axis, corroborated, novelty-diffed, follow-up-shaped, assessment-only)
- [x] b-plan requirements addressed (FR1–FR6, NFR1–NFR5)
- [x] c-plan design followed (read-only agents, sole-writer, two-stage reduce, dispatch-key filenames)
- [x] Residual subtask-level coverage (~60) logged, not silently dropped — the one bounded gap, disclosed per the no-silent-truncation constraint.

## Security Review

**State**: no findings

Docs-only discovery changeset; injection containment (read-only agents, sole-writer
orchestrator, dispatch-key filenames) is correctly designed; no executable code, perms,
or hashes change. (Incidental non-security note surfaced: `Wide character in print` in the
existing `plan-mechanical-check`/`ArtefactHelpers.pm` — captured as a seeded bugfix.)

## Best-Practice Review

**State**: no findings

Markdown-only changeset; golang/postgres best-practice sources (both readable) cover code
absent from the diff, so nothing to bind against.

## Improvements Review

**State**: no findings

No committed code, no duplicated helpers; the deliverable itself diffs findings against
existing codified rules and frames recommendations as extensions (R1/R2/S10).

## Robustness Review

**State**: no findings

Described pipeline handles gaps/injection/truncation/path-escape with fail-safe defaults.
Advisory: `g-testing-exec` is an unfilled template — that is the next phase.

## Misalignment Review

**State**: no findings

Discovery docs reuse existing CWF abstractions (`scratch_dir`, tmp-paths, git-path-output;
correct helper/config names); no reinvention.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
