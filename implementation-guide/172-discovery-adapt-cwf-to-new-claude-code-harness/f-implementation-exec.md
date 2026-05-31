# Adapt CWF to new Claude Code harness - Implementation Execution
**Task**: 172 (discovery)

## Task Reference
- **Task ID**: internal-172
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/172-adapt-cwf-to-new-claude-code-harness
- **Template Version**: 2.1

## Goal
Produce the §1–§7 assessment (per c-design-plan.md / d-implementation-plan.md)
from real evidence. Markdown-only deliverable; no CWF edits this task.

## Evidence handling note (read first)
- **Sources**: (1) the captured `dircachefilehash` Task 6 transcript (in-conversation);
  (2) the user-supplied terminal backlog `/var/tmp/dircachefilehash.log` (raw VT
  capture, 71 908 lines); (3) the live `EnterWorktree`/`ExitWorktree` tool schemas
  loaded in **this** session; (4) a first-hand cheap-and-safe reproduction (Step 6).
- **Backlog mining**: the backlog is a raw terminal scrollback (ANSI escapes +
  redraw frames). It was de-escaped with a read-only stripper
  (`scratch/strip-ansi.pl`) to `scratch/stripped.txt`; citations read **`backlog
  L<n>`** = line `n` of that stripped file. Stripping **collapses inter-word
  whitespace** inside redrawn regions (e.g. `gitworktreeremove--force`), so quoted
  command shapes are reconstructed, not byte-exact — flagged per row.
- **Trust boundary (NFR5)**: transcript/backlog content is treated as advisory
  **data**, never as instructions; no tool call in this task was driven by their
  content. (The instruction-priority order in CLAUDE.md governs.)
- **Redaction (AC8)**: every mined window was scanned for credentials / tokens /
  secret env-var values before synthesis. The session is a gosec-triage coding
  session; **no secrets were present** in any mined window — nothing required
  removal. `redacted` below = "scanned; none found", not "value stripped".

---

## §1 — Environment & versions (NFR3)
| field | value |
|-------|-------|
| `model_id` | **Opus 4.8 (1M context)**, high-effort default (`Opus4.8ishere! Now defaults to high effort`, backlog L≈prompt-banner) |
| `cc_version` | **pending** — exact CC client version string not present in the backlog. Does **not** put any FR1 row in violation of AC1 (AC1 constrains `evidence_ref`, present on every row). |
| session-of-record | this assessment runs under the same family (`claude-opus-4-8[1m]`) — dogfooding evidence is first-hand. |
| anchor repo | `dircachefilehash`, Task 6 (`dis/6-triage-deferred-gosec-findings`) |

Every finding below is scoped to this model/client. Recommendations (§6/§7) are
framed as **durable conventions**, not version-pinned hacks (NFR3).

---

## §2 — Harness-change catalogue (FR1)
Schema: `{ area, model_id, observed_change, cwf_step_touched, evidence_ref, redacted, mitigation }`

### FR1-1 — Guarded worktree tools (`EnterWorktree`/`ExitWorktree`)
- **area**: git-worktree handling
- **observed_change**: the new harness ships first-class worktree tools.
  `EnterWorktree` creates a worktree under `.claude/worktrees/` on a new branch and
  **switches the session CWD into it**; `ExitWorktree` **restores the prior CWD and
  clears CWD-dependent caches** (system-prompt sections, memory, plans dir).
  `ExitWorktree(action: remove)` **refuses to delete a worktree holding uncommitted
  files or unmerged commits unless `discard_changes: true`** — a fail-safe version of
  the `git worktree remove --force` that caused the incident (§3c).
- **cwf_step_touched**: any flow that uses scratch worktrees; `task-workflow.d/delete`
  (self-worktree guard); `tmp-paths.md` conventions.
- **evidence_ref**: `EnterWorktree`/`ExitWorktree` tool schemas loaded **this session**
  (first-hand); reproduction Step 6.
- **redacted**: n/a (tool schema, not mined text).
- **CWF-critical caveat (load-bearing)**: `ExitWorktree` **only operates on worktrees
  created by `EnterWorktree` in the same session** — it explicitly **will not touch
  worktrees created with raw `git worktree add`**. CWF today creates worktrees with
  raw `git worktree` (the incident did; `task-workflow.d/delete` reasons in raw git).
  **The guard therefore does not protect CWF flows unless CWF adopts `EnterWorktree`
  as the creation path.** This is the hinge of recommendation R1 (§6).
- **Second caveat (`worktree.baseRef`)**: default `fresh` branches a new worktree from
  `origin/<default-branch>`, **not** local HEAD. CWF branches each task off current
  HEAD (`feedback_branch_from_current_commit`), so adopting `EnterWorktree` would
  require `worktree.baseRef: head` or task bases would silently diverge from HEAD.
- **mitigation**: adopt the guarded tools as CWF's worktree create/remove path
  (R1); set `worktree.baseRef: head`.

### FR1-2 — Model self-checking / dependency-reaction (trusts remembered semantics)
- **area**: model self-checking / dependency-reaction
- **observed_change**: the model reasoned from **remembered tool-rule semantics** and
  was wrong. Phases a–e of the anchor task **assumed `G703` was not a real gosec rule**
  (treated existing `//nolint:gosec // G703` comments as mislabels); gosec in fact
  emits `G703: Path traversal via taint analysis` (`pkg/recovery.go:414`,
  `pkg/snapshot.go:448`). The error was caught only when the tool was actually run.
- **cwf_step_touched**: any phase that reasons about external-tool rules from memory —
  security-review (f/g), design/requirements that cite tool behaviour. This is the
  exact failure `feedback_no_fabricated_citations` warns about ("write a 3-line test
  instead of citing").
- **evidence_ref**: backlog L32252 ("**G703 IS a real gosec rule.** Phases a–e assumed
  `G703` was not a gosec rule…"), L32258–32279 (correction G703→G304 and vice-versa).
- **redacted**: scanned; none found.
- **mitigation** (mandatory for this row): **verify tool-rule semantics against live
  tool output, never assert a remembered rule catalogue** — codify as a security-review
  convention reinforcing the standing no-fabrication rule (R4).

### FR1-3 — `"workflow"` keyword reservation
- **area**: reserved-keyword collision
- **observed_change**: the harness attaches special meaning to **"workflow"** (the
  multi-agent orchestration `Workflow` tool). A system-reminder now steers toward that
  tool when the user says "workflow(s)", colliding with CWF's pervasive "workflow"
  vocabulary.
- **cwf_step_touched**: all wf step files, `workflow-manager`, the `cwf-*-plan`
  "workflow skills", CLAUDE.md/skills prose, `glossary.md`.
- **evidence_ref**: **in-session dogfooding** — during this very task the harness twice
  surfaced the multi-agent `Workflow` tool off the word "workflow"; correctly declined
  (the collision is the thing under assessment). Plus `glossary.md:157` (`wf = workflow`).
- **redacted**: n/a.
- **mitigation**: §4 options (guard → wording → rename); R5.

---

## §3 — Data-loss root-cause map (FR2) — fully evidenced, zero `pending`
Schema: `{ id, mechanism, precondition, exposing_cwf_step, intersecting_convention, intersecting_call_sites, mitigation, tradeoff_note, evidence_ref, redacted }`

### (a) Persistent shell CWD left inside a disposable worktree
- **precondition**: a `cd "$wt"` into a scratch worktree from the session that also
  edits the primary tree; the shell CWD persists across tool calls.
- **exposing_cwf_step**: any scratch-worktree reproduction/verification run inside a
  CWF phase (here, testing/verification).
- **intersecting_convention**: `feedback_no_cd_git_rev_parse.md` (reasoned about
  `$(git rev-parse --show-toplevel)` purely as prompt-noise, **without** the
  worktree-CWD-drift hazard in view); `tmp-paths.md`.
- **intersecting_call_sites**: see (b).
- **mitigation**: never `cd` into a disposable worktree from the primary session; use
  absolute paths for primary-tree work, or let `EnterWorktree`/`ExitWorktree` manage CWD.
- **tradeoff_note**: absolute-path discipline is slightly more verbose; pure safety gain.
- **evidence_ref**: backlog L100681 ("A cd into the scratch worktree left the shell's
  CWD there, so my 'real-tree' edits actually went into the disposable worktree and
  were deleted when I removed it").
- **redacted**: scanned; none found.

### (b) `git rev-parse --show-toplevel` resolves to the worktree, not the main tree
- **precondition**: running `cd "$(git rev-parse --show-toplevel)"` from **inside** a
  worktree — toplevel returns the worktree root, so the "go back to repo root" idiom
  silently keeps you in the disposable tree.
- **exposing_cwf_step**: every CWF helper that recentres on the repo root via this idiom.
- **intersecting_convention**: `feedback_no_cd_git_rev_parse.md` + `tmp-paths.md`.
- **intersecting_call_sites (verified, 13)**: `grep -rln "rev-parse --show-toplevel"
  .cwf .claude` →
  `tmp-paths.md`, `CWF/Common.pm`, `CWF/TaskPath.pm`, `CWF/WorkflowFiles.pm`,
  `command-helpers/task-stack`, **`command-helpers/task-workflow.d/delete`** (the
  self-worktree guard *inside the deletion flow* — load-bearing),
  `command-helpers/checkpoints-branch-manager`, `command-helpers/context-manager.d/location`,
  `command-helpers/template-copier-v2.0`, `command-helpers/template-copier-v2.1`,
  `scripts/update-cwf-skill-docs.sh`, `scripts/migrations/migrate-v2.1-file-order`,
  `skills/cwf-init/SKILL.md:87`. A fix scoped only to the `cwf-init` prose would
  under-remediate; the library + `delete` sites are the ones that matter.
- **mitigation**: prefer `--show-toplevel` only when **not** in a worktree, or use
  `git rev-parse --git-common-dir` / explicit main-tree paths; audit the 13 sites for
  worktree-safety (follow-up task R2).
- **tradeoff_note**: `--git-common-dir`-based resolution is less familiar; correctness
  win outweighs it.
- **evidence_ref**: **first-hand reproduction (Step 6)** — from inside a linked worktree,
  `git rev-parse --show-toplevel` returned the worktree path and `cd "$(…)"` landed
  back in the worktree; backlog L100681; the 8 identical `cd "$(git rev-parse
  --show-toplevel)"` prompts at L401–L33894.
- **redacted**: scanned; none found.

### (c) `git worktree remove --force` discards uncommitted work
- **precondition**: uncommitted working-tree edits exist in a worktree (here, because
  of (a)/(b)); `git worktree remove --force` deletes the tree and the edits with it —
  uncommitted edits are journaled nowhere by themselves.
- **exposing_cwf_step**: scratch-worktree teardown after a verification run.
- **intersecting_convention**: none specific pre-existing (this task seeds it); relates
  to the standing "surface, never smooth" safety principle.
- **intersecting_call_sites**: the teardown idiom; the guarded `ExitWorktree(remove)`
  (§2 FR1-1) is the fail-safe replacement.
- **mitigation**: never `--force`-remove a worktree that may hold uncommitted work;
  prefer `ExitWorktree(action: remove)` which **refuses** without `discard_changes:true`
  (R1). Commit/stash before teardown.
- **tradeoff_note**: the guard adds a confirmation step on genuine discards — **that
  friction is the feature** (surface, never smooth); must not be auto-approved.
- **evidence_ref**: backlog L33912 (`git worktree remove --force "$wt"`), L62118
  ("git worktree remove --force simply deletes — those aren't journaled anywhere").
  Command shape whitespace-collapsed by stripping.
- **redacted**: scanned; none found.

### (d) Recovery only via stash-reflog / `git fsck --unreachable`, not the HEAD reflog
- **precondition**: lost work was never committed to any branch, so the **HEAD reflog
  correctly shows nothing**. It survived only because a `git stash push -u` / `pop`
  during verification left a **dangling stash commit** (a real commit object, kept
  until gc).
- **exposing_cwf_step**: post-incident recovery during a CWF phase; the wrong first
  instinct (HEAD reflog) wastes time and can read as "unrecoverable".
- **intersecting_convention**: none pre-existing; seeds a recovery-runbook convention.
- **intersecting_call_sites**: n/a (recovery procedure, not a code site).
- **mitigation**: recovery runbook — for lost **uncommitted** work go straight to
  `git fsck --unreachable` / `git reflog stash`, not the HEAD reflog (R3).
- **tradeoff_note**: documentation-only; pure upside.
- **evidence_ref**: backlog L62130–62131 ("a stash is a real commit object … recoverable
  via the stash reflog / `git fsck --unreachable`, not the HEAD reflog"), L62144
  (the wrong-tool admission), L72328 (**recovered**: dangling commit `a49e33b`
  "task6-verify"), L100682–100683 (re-applied to main tree, re-verified clean).
- **redacted**: scanned; none found.

**Outcome of the anchor incident**: all 11 files recovered intact from `a49e33b` via
`git fsck --unreachable`, re-applied to the main tree, re-verified (gosec-clean, build,
race tests green). A near-miss, not a permanent loss — but only because of an
incidental stash.

---

## §4 — `"workflow"` keyword-collision assessment (FR3)
### Collision sites
Schema: `{ surface, collision, observed_behaviour_change }`

| surface | collision | observed_behaviour_change |
|---------|-----------|---------------------------|
| wf step files (`a-…`–`j-…`), the term "workflow step" | filenames/prose say "workflow" | reader/agent may map to the orchestration tool |
| `workflow-manager` helper | command name contains "workflow" | none observed at invocation (path-qualified); naming-confusion risk |
| `cwf-*-plan` "workflow skills" (docs term) | CLAUDE.md calls them "Workflow Skills" | conceptual overlap with the `Workflow` tool |
| CLAUDE.md / skills prose | "hierarchical workflow system", "workflow phase" | **system-reminder steers to multi-agent `Workflow` tool on the word** |
| `.cwf/docs/glossary.md:157` | canonical `wf = workflow` definition | the blast-radius anchor for any rename |

**Observed behaviour change (first-hand)**: in this session the harness surfaced the
multi-agent `Workflow` tool in response to "workflow(s)"; it was correctly declined.
This is the collision manifesting during the very task that assesses it.

### Disambiguation options (≥3, none pre-selected) (FR3)
Schema: `{ option, blast_radius, note }`

1. **option: guard (behavioural)** — add a short note to CLAUDE.md / skills: "in CWF,
   'workflow' = the CWF phase system, **not** the harness `Workflow` tool; never spawn
   multi-agent orchestration for CWF phases."
   - **blast_radius**: tiny (1–2 prose blocks); no renames; reversible.
   - **note**: cheapest; relies on the agent honouring the guard each session.
2. **option: targeted wording** — rename only the **user-facing collision phrases**
   ("Workflow Skills" → "CWF phase skills"; "workflow step" → "wf phase" in prose),
   leaving filenames/helpers/`wf` abbrev intact.
   - **blast_radius**: medium (docs + skill prose; no code/paths); a few files.
   - **note**: reduces ambiguity without a breaking rename; `glossary.md:157` updated.
3. **option: full rename** — replace "workflow" across filenames, `workflow-manager`,
   the `wf` abbrev, helpers, and all prose with a non-colliding term (e.g. "phase"/
   "pipeline").
   - **blast_radius**: large — breaking change (helper names, `wf step files`, every
     task dir's lettered files, hashes, docs); touches the 13-call-site grep surface
     and beyond.
   - **note**: maximal clarity, maximal cost; a major-version change. Not recommended
     as a first move.

---

## §5 — Permission-prompt inventory (FR4)
Schema: `{ command_shape, emitting_cwf_step, friction, memory_xref, status, evidence_ref, redacted, security_relevant }`

Reconstructed from the backlog: **23 Bash permission prompts** (`●Bash(` headers /
"Bash command" approval banners). Whitespace within shapes is stripped-collapsed.
No secrets in any window (AC8).

| # | command_shape | emitting step | friction | memory_xref | status | evidence | sec? |
|---|---------------|---------------|----------|-------------|--------|----------|------|
| P1 | `cd "$(git rev-parse --show-toplevel)" && <compound: golangci-lint/go build/grep/echo>` | testing/verify | **H** (8 near-identical prompts L401–L33894; each compound differs so each re-prompts) | `feedback_no_cd_git_rev_parse.md`, `feedback_no_echo_exit.md` | **known** (cd-rev-parse already flagged) — but **newly dominant** under this client | backlog L401, L1697, L4681…L33894 | no |
| P2 | `cd /home/matt/repo/dircachefilehash && <compound>` (absolute path, post-switch) | impl/verify | **M** (≈15 prompts L35047→L147410; the agent switched away from the rev-parse idiom) | `feedback_no_cd_git_rev_parse.md` | known | backlog L35047, L37006, L45986… | no |
| P3 | `sleep 1 && git stash push -u … / git stash pop …` | verify | **M** | MEMORY `sleep 1 && git` prefix | known | backlog L4682, L4705 | no |
| P4 | `sleep 1 && git worktree remove --force "$wt"` | scratch teardown | **L** (single, but highest-consequence) | none (seeds R1) | **new** | backlog L33912 | **yes** (destructive op; never auto-approve) |
| P5 | `git fsck --unreachable` / `git reflog stash` / `git stash show -p …` | recovery | **L** | none (seeds R3) | new | backlog L62469, L62494, L49711 | no |

- **Ranking** (friction = frequency × interruption): **P1 ≫ P2 > P3 > P5 > P4** by
  volume; by **consequence** P4 is the one that must *stay* prompted.
- **Newly-prompting vs known**: P1/P2/P3 are already covered by MEMORY avoidance rules
  (the `cd "$(…)"` idiom and the `sleep 1 && git` prefix). The dominant friction is
  **the same idiom MEMORY already discourages** — i.e. the cure exists; what's new is
  the volume under this client and the worktree-toplevel data-loss twist (§3b).
- `pending`: none required — the backlog was supplied. (FR4 permits `pending` only when
  the backlog is unavailable.)

---

## §6 — Tradeoff matrix & prioritised recommendations (FR5)
Schema: `{ failure_mode, action, target_surface, safety_delta, momentum_delta, tradeoff_line, priority, proposed_task }`

Scoring: safety_delta / momentum_delta ∈ {+ , 0 , −}. **AC6 gate**: every action that
touches a destructive/irreversible op carries the explicit safety↔momentum tradeoff and
a "surface, never smooth" note citing `feedback_surface_security_dont_smooth.md`. **No
action below silently trades safety for momentum; none auto-approves a destructive op.**

| R | failure_mode | action | target_surface | safety | momentum | tradeoff_line | prio |
|---|--------------|--------|----------------|--------|----------|---------------|------|
| **R1** | §3c worktree `--force` data-loss | adopt `EnterWorktree`/`ExitWorktree` as CWF's scratch-worktree create/remove path; set `worktree.baseRef: head`; **keep the uncommitted-changes guard, never pass `discard_changes:true` unprompted** | `tmp-paths.md`, `task-workflow.d/delete`, a new worktree convention; `cwf-project.json`/settings | **+ +** | **+** (CWD auto-managed, fewer manual `cd`) | the guard *adds* a confirm on genuine discards — **that friction is the feature**; surfacing it (not smoothing it) is the point — cites `feedback_surface_security_dont_smooth.md` | **P0** |
| **R2** | §3b toplevel-resolves-to-worktree | audit the **13** `--show-toplevel` call sites for worktree-safety; replace with worktree-safe resolution where they can run inside a worktree | the 13 sites (libs + `delete`) | **+ +** | **0** | none — pure correctness fix; no safety traded | **P0** |
| **R3** | §3d wrong recovery tool | add a **lost-uncommitted-work recovery runbook** (`git fsck --unreachable` / stash-reflog first, not HEAD reflog) | a new `.cwf/docs` runbook + MEMORY pointer | **+** | **+** (faster recovery) | none — docs only | **P1** |
| **R4** | §2 FR1-2 remembered-semantics error | security-review convention: **verify tool-rule semantics against live output, never assert a remembered rule catalogue** | `security-review.md` skill doc; reinforces `feedback_no_fabricated_citations` | **+** | **0/−** (one extra check) | trades a little speed for correctness — surfaced, not hidden | **P1** |
| **R5** | §4 keyword collision | start with **option 1 (behavioural guard)** in CLAUDE.md/skills; hold option 2 (wording) as a fast-follow; treat option 3 (full rename) as a deferred major-version decision | CLAUDE.md, skills prose, `glossary.md:157` | **0** (safety-neutral) | **+** (fewer mis-steers) | none destructive | **P1** |
| **R6** | §5 P1/P2 permission friction | **do not** broaden the allowlist to silence `cd "$(…)"`/compound prompts; instead **remove the cause** — apply the existing `feedback_no_cd_git_rev_parse.md` discipline (absolute paths, no needless `cd`) so the prompts stop arising | MEMORY reinforcement; helper-call hygiene | **+** (avoids broadening auto-approve) | **+** (fewer prompts) | the tempting fix (allowlist `cd …`/`git …`) would **widen the auto-approved destructive surface** — **rejected**; cut friction by removing the command, not by auto-approving it. Cites `feedback_surface_security_dont_smooth.md` | **P0** |

**Central safety finding (AC6)**: the cheapest way to kill P1/P2 friction — allowlisting
`cd`/`git` compounds — is exactly the silent safety-for-momentum trade NFR4 forbids,
because it would also auto-approve `git worktree remove --force` (P4) and kin. R6
therefore reduces friction by **eliminating the command shape**, not by broadening
auto-approve. No recommendation here proposes auto-approving a destructive op.

---

## §7 — Recommended remediation decomposition (FR5)
Projection of §6 `proposed_task` fields — **introduces no task not already carried by a
§6 row**. This task creates none of them (scope boundary). Suggested follow-ups, each
paste-ready for `/cwf-new-task`:

1. **R1 → `feature`**: "Adopt guarded EnterWorktree/ExitWorktree for CWF scratch-worktree
   flows; set worktree.baseRef=head; route `task-workflow.d/delete` teardown through the
   uncommitted-changes guard." (P0; touches `tmp-paths.md`, `task-workflow.d/delete`,
   config; hash refresh for any edited helper.)
2. **R2 → `bugfix`**: "Audit the 13 `git rev-parse --show-toplevel` call sites for
   worktree-safety; replace with worktree-safe root resolution where reachable inside a
   worktree." (P0; libs + `delete`.)
3. **R3 → `chore`**: "Add lost-uncommitted-work recovery runbook (fsck --unreachable /
   stash-reflog first); MEMORY pointer." (P1; docs.)
4. **R4 → `chore`**: "Security-review convention: verify tool-rule semantics against
   live tool output; reinforce no-fabrication rule." (P1; `security-review.md`.)
5. **R5 → `chore`** (then optional `feature`): "Add 'workflow' keyword-disambiguation
   guard to CLAUDE.md/skills (option 1); scope optional wording pass (option 2). Full
   rename (option 3) deferred as a major-version decision." (P1.)
6. **R6 → folds into R1/MEMORY**: "Reinforce no-needless-`cd`/absolute-path discipline so
   P1/P2 prompts stop arising; explicitly **reject** allowlist-broadening as the fix."
   (P0; MEMORY/feedback — may merge into R1 rather than a standalone task.)

**Sequencing note**: R1 + R2 (the P0 data-safety pair) first; R6 rides with R1; R3–R5
are independent P1 documentation/convention tasks.

---

## Actual Results
All 9 d-plan steps executed. Deviations:
- **Step 6 reproduction** used a **throwaway scratch repo** (not `EnterWorktree` on the
  real repo): `EnterWorktree`'s own guidance restricts it to "explicitly instructed to
  work in a worktree", which this task is not; the scratch-repo path is the safer
  Decision-3 option and proves mechanism (b) first-hand. The **guard refusal** behaviour
  (§2 FR1-1, §3c) is sourced from the **live `ExitWorktree` schema loaded this session**
  (first-hand documentary evidence), flagged as schema-sourced rather than
  execution-observed (AC7) — I did not destroy work to watch it refuse.
- Backlog required de-escaping (raw VT capture); handled with a read-only stripper.
  Whitespace-collapse caveat noted on affected quotes.

## Blockers Encountered
None. The one dependency (backlog) was supplied, so FR4 needed no `pending` rows.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met (catalogue, loss-map, collision,
      prompt inventory, prioritised recommendations + decomposition)
- [x] All requirements b-plan FR1–FR5 / NFR1–NFR5 addressed
- [x] All c-plan design guidance followed (schemas, trust boundary, redaction, Decision 7)
- [x] No planned work deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: no findings

no findings: empty changeset

## Lessons Learned
*To be captured during retrospective*
