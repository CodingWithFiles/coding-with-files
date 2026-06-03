# Assess harness worktree tools vs CWF code - Implementation Execution
**Task**: 177 (discovery)

## Task Reference
- **Task ID**: internal-177
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/177-assess-harness-worktree-tools-vs-cwf-code
- **Template Version**: 2.1

## Goal
Replace Task-172-era inference with cited evidence: verify every harness-semantics
claim behind the "Adopt guarded EnterWorktree/ExitWorktree" backlog item, inventory
CWF's worktree call sites, characterise how worktrees are *actually* used with CWF
(C6), then rewrite the backlog item. No CWF production code changes.

## Evidence sources (gathered this session)
- **Live tool schemas** via `ToolSearch "select:EnterWorktree,ExitWorktree"` — quoted
  verbatim below. These are the governing source per c-design Decision 1: the schemas
  are unusually prescriptive (they state scope + refusal directly) and the only probe
  that would add information is unsafe/gated (Decision 4).
- **Repo greps** (re-derived this session, not from memory):
  `git grep -n "git worktree" -- .cwf`, `git grep -nE "git worktree (add|remove|prune)"`
  (repo-wide), `git grep -n -- "--show-toplevel" .cwf`.
- **Agent/Workflow tool schemas** (this session's tool definitions) for `isolation: worktree`.

No empirical removal probe was run (see C2 / Step 3). No harness worktree *doc* (prose
page) is reachable from this session beyond the tool schemas themselves; that gap is
recorded rather than guessed at — the schemas are the authoritative source used.

## Step 1–2: Call-site inventory (FR3)

### `git worktree` occurrences in `.cwf` (production scripts/lib)
| file:line | call | category | guarded-tool candidate? | note |
|---|---|---|---|---|
| `.cwf/lib/CWF/TaskContextInference.pm:315` | `` `git worktree list 2>/dev/null` `` | **list** (read-only) | **No** | Reads worktree list to infer task number from a worktree path. Inspection, not create/teardown. |
| `.cwf/scripts/command-helpers/task-workflow.d/delete:158` | `git worktree list --porcelain` | **list** (read-only) | **No** | Check 7 of delete: detects whether a to-be-deleted branch is checked out in *another* worktree and **dies** if so (L171). Read-only + refuse. |

**Empty categories (recorded as findings, not omissions):** repo-wide there are **no**
`git worktree add`, **no** `git worktree remove`, **no** `git worktree prune` sites in
any production script (`.cwf/scripts`, `.cwf/lib`). `git grep -nE "git worktree
(add|remove|prune)"` returns matches **only** in documentation: this task's own plans,
`BACKLOG.md:49`, `CHANGELOG.md`, and historical task wf files (136, 172, 173, 32).

### `--show-toplevel` actual call sites in `.cwf` (FR3)
Re-derived count: **6 invocation sites** (comment-only mentions excluded). The
`feedback_worktree_cwd_dataloss` "13 sites" is a stale Task-172 figure; Task 173
("audit --show-toplevel sites for worktree-safety") already converted the canonical
root-resolvers to a worktree-safe `--git-common-dir`-based path that only *falls back*
to `--show-toplevel`, which accounts for the reduction. Actual sites:

| file:line | purpose | worktree-safe today? |
|---|---|---|
| `.cwf/lib/CWF/Common.pm:73` | Fallback inside the Task-173 worktree-safe root resolver (`--git-common-dir` first) | Yes — fallback only |
| `.cwf/scripts/cwf-manage:103` | Same worktree-safe pattern (`git_capture` list-form) | Yes — fallback only |
| `.cwf/scripts/command-helpers/checkpoints-branch-manager:11` | Repo-root resolution | Plain `--show-toplevel` |
| `.cwf/scripts/command-helpers/task-stack:14` | Repo-root resolution | Plain `--show-toplevel` |
| `.cwf/scripts/command-helpers/task-workflow.d/delete:153` | Reads *self* worktree root for the Check-7 self-exclusion compare | Plain (intentional: wants current tree) |
| `.cwf/scripts/command-helpers/context-manager.d/location:14` | Diagnostic: deliberately reports the *current* (possibly linked) worktree root alongside the main root | Intentional (diagnostic) |

Comment-only mentions (not calls): `Common.pm:51,56`, `cwf-manage:88,90`,
`update-cwf-skill-docs.sh:11` (a "Do NOT `cd` …" instruction).

All `--show-toplevel` sites are **read-only root resolution** — none create or tear
down a worktree, so **none are `EnterWorktree`/`ExitWorktree` candidates** (those
tools create/teardown, they don't inspect).

## Step 3: C5 resolution + C6 usage surface

### C5 — verdict: **Refuted** (citation: the inventory above)
CWF's own scripts contain **no** raw `git worktree add` / `remove --force`
create-or-teardown flow. The only `git worktree` calls are two read-only `list`s.
**Refuted ≠ "nothing to do"** (c-design Decision 3): it means CWF has no *scripted*
worktree path, not that worktrees are unused with CWF.

### Correction of the backlog body's false example
`BACKLOG.md:49` asserts CWF has "raw `git worktree add`/`remove --force` flows (incl.
the self-worktree guard in `task-workflow.d/delete`)". This is false on two counts:
1. `task-workflow.d/delete` Check 7 (L150–172) runs only read-only `git worktree list
   --porcelain` (+ a `--show-toplevel` self-read) and **`die_err`s** —
   "task branch '$b' is checked out in worktree $wt; remove the worktree before
   deleting" (L171). It **never** creates or force-removes a worktree.
2. There is no `git worktree add`/`remove --force` anywhere in CWF's scripts at all.
The Step-7 rewrite must drop this example.

### C6 — the actual usage surface (why the feature exists)
Worktrees *are* used with CWF today, via paths CWF neither defines nor guards:

1. **Model-initiated raw `git worktree add` mid-task — evidenced, unguarded.**
   `implementation-guide/136-feature-delete-most-recent-task-only/f-implementation-exec.md:82-83`
   records the model itself running `git worktree add -b tmp/smoke-delete
   /tmp/cwf-delete-smoke HEAD` and working inside it for a smoke test. This is the
   "the model decided on its own to use worktrees" path, on raw git — the CWD-switch +
   `--show-toplevel`-resolves-to-worktree + `remove --force` data-loss chain
   (`feedback_worktree_cwd_dataloss`).
2. **Documented manual worktree procedures in CWF wf files** — Task 136 `d-plan:119,123`
   and `e-plan:35,39,92` instruct creating/removing scratch worktrees by hand for
   isolated testing; Task 32 `j-retrospective:439` recommends `git worktree add
   ../test-env`. Ad-hoc, unguarded, no defined process.
3. **Harness Agent `isolation: worktree`** — Agent tool schema: "`isolation:
   "worktree"` gives the agent its own git worktree (auto-cleaned if unchanged)";
   Workflow tool `opts.isolation: 'worktree'` "runs the agent in a fresh git worktree …
   the worktree is auto-removed if unchanged." Harness-managed lifecycle, outside CWF's
   control — relevant because a CWF flow must not assume it owns every worktree.
4. **Harness `EnterWorktree`/`ExitWorktree`** — guarded (see C1/C2) but gated + deferred
   (see FR5). The one *safe* path, currently unused by CWF.
5. **Operator manual use** — the operator confirmed using worktrees with CWF directly.

The historical incident motivating the original backlog item (Task 172: data loss on a
`dircachefilehash` Task 6 worktree, recovered via `git fsck --unreachable`) sits in
paths 1/2. **Conclusion: the gap is the absence of a defined, guarded CWF worktree
process — not a missing guard on a scripted flow that does not exist.**

## Step 4: Claims table (FR1/FR2)

| ID | Claim | Source | Verdict | Citation | Relevance to CWF |
|---|---|---|---|---|---|
| C1 | The uncommitted-changes guard applies **only** to `EnterWorktree`-created worktrees; raw `git worktree add`/`remove --force` is unprotected | BACKLOG:49 / T172 | **Confirmed** | ExitWorktree schema: "ONLY operates on worktrees created by EnterWorktree in this session… will NOT touch worktrees you created manually with `git worktree add`… the tool is a **no-op**" | **Applies (crux).** Reframed from moot to central by C6: model-initiated raw `add` (C6.1) is precisely the unguarded path. |
| C2 | `ExitWorktree(action: remove)` refuses on uncommitted changes unless `discard_changes: true` | BACKLOG:49 / T172 | **Confirmed-by-schema** (runtime residual: **Unverifiable-by-safe-probe**) | ExitWorktree schema: "the tool will REFUSE to remove it unless this is set to `true`. If the tool returns an error listing changes, confirm with the user…"; `discard_changes` default `false` | Applies — this refusal is the protection the feature wants. Not watched-it-happen: only the EnterWorktree path exercises it and that switches CWD (gated, data-loss risk) — probe deliberately skipped (Decision 4). |
| C3 | `worktree.baseRef` defaults to `fresh` (branches from `origin/<default>`), conflicting with CWF's branch-off-HEAD rule | T172 / BACKLOG:49 | **Confirmed** | EnterWorktree schema: "The base ref is governed by the `worktree.baseRef` setting: `fresh` (default) branches from origin/<default-branch>" | Applies — conflicts with `feedback_branch_from_current_commit`; the feature must set `head`. |
| C4 | A `worktree.baseRef: head` setting exists and makes new worktrees branch from current HEAD | T172 / BACKLOG:49 | **Confirmed** | EnterWorktree schema: "`head` branches from your current local HEAD" | Applies — this is the setting CWF needs. |
| C5 | CWF's own scripts contain raw `git worktree add`/`remove --force` create/teardown sites the guarded tools could replace | BACKLOG:49 | **Refuted** | Inventory (Step 1–2): only two read-only `git worktree list`; zero add/remove/prune repo-wide in scripts | Reframes (not retires) the feature per C6: no scripted flow to route, but undefined ad-hoc/model-initiated use to govern. |
| C6 | Worktrees are used with CWF via undefined/unguarded paths (model-initiated raw `add`, manual, Agent `isolation:worktree`, EnterWorktree) | operator + evidence | **Confirmed (usage-surface finding)** | Task 136 f-exec:82-83 (model ran raw `add`); Task 136 d/e-plans + Task 32 j-retro:439 (manual procedures); Agent/Workflow `isolation:worktree` schemas; operator statement | **Applies — this is the feature's justification.** Establishes the need C5 alone would seem to remove. |

Verdict legend: Confirmed / Refuted / Unverifiable(-by-safe-probe). Citations are quoted
schema fragments, the re-derived inventory, or quoted wf-file lines — never memory.

## Step 5: Deferred-tool assessment (FR5)
`EnterWorktree`/`ExitWorktree` are **deferred** (loaded via `ToolSearch` —
demonstrated this session) **and gated**: EnterWorktree's schema says "Use this tool
ONLY when explicitly instructed to work in a worktree — either by the user directly,
**or by project instructions (CLAUDE.md / memory)**." ExitWorktree: "Do NOT call this
proactively — only when the user asks."

Consequences for any future adoption:
- A CWF skill cannot rely on these tools being pre-loaded; it must trigger a
  `ToolSearch` load (`select:EnterWorktree,ExitWorktree`) first.
- The gate is satisfiable by **project instructions** — a documented CWF worktree
  process in `CLAUDE.md`/memory/skill text *is* the "project instructions" authorisation
  the schema names. So a defined CWF process is not only compatible with the gate, it is
  the mechanism that legitimises automated use. ExitWorktree's "only when the user asks"
  is stricter (operator-facing); a CWF process should surface the teardown decision to
  the operator rather than auto-removing.
- `ExitWorktree` only acts on worktrees `EnterWorktree` created this session — it cannot
  clean up a raw-`add` worktree (C1/C6.1). A guarded process must therefore create via
  `EnterWorktree` to get teardown protection at all.

## Step 6: Synthesis
- **C3, C4, C1 Confirmed; C2 Confirmed-by-schema; C5 Refuted; C6 Confirmed.**
- The original framing ("guard CWF's raw worktree flows") rests on a false premise (C5):
  CWF has no such scripted flow, and the `task-workflow.d/delete` example is wrong.
- But the feature is **reframed, not retired** (c-design Decision 3, operator
  clarification): C6 shows worktrees are used with CWF through undefined paths — most
  dangerously a model deciding on its own to run raw `git worktree add` (evidenced,
  Task 136). The real deliverable is to **define a robust, guarded CWF worktree
  process** built on `EnterWorktree`/`ExitWorktree`: create via `EnterWorktree` (so the
  C2 guard applies), set `worktree.baseRef: head` (C3/C4), never pass `discard_changes:
  true` unprompted, surface teardown to the operator, and steer model/manual ad-hoc raw
  `git worktree add` onto this path. Deferred+gated status (FR5) is satisfied by the
  process being documented project instruction.

## Step 7: Backlog rewrite (FR6) — **DONE** (after operator review of findings)
Operator reviewed the Step 1–6 findings and released the "pause before rewrite" gate.
The rewrite went through `cwf-backlog-manager` only (no direct `BACKLOG.md` edit):
- Body drafted to project-namespaced scratch file
  `/tmp/-home-matt-repo-coding-with-files-task-177/backlog-body.md` (recovery source,
  written before any destructive op).
- `delete --exact-title='Adopt guarded EnterWorktree/ExitWorktree for CWF
  scratch-worktree flows' --confirm` → **exit 0**.
- `add --title='Adopt guarded EnterWorktree/ExitWorktree as CWF'\''s defined worktree
  process' --task-type=feature --priority=High --body-file=<scratch>` (+ status /
  identified-in) → **exit 0**.
- Single-entry assertion: `validate --all` → **exit 0**; `list --all-items | grep -c`
  the title → **1** (exactly one live entry, not zero, not duplicated).

The new body: states C1–C4 as confirmed facts, drops the false C5 premise and the wrong
`task-workflow.d/delete` example, reframes the feature around C6 (define a guarded
worktree process), and records the C2 runtime residual as an open question. Title stem
"Adopt guarded EnterWorktree/ExitWorktree…" preserved; suffix updated to reflect the
reframe.

## Blockers Encountered
None. (No probe run — by design, Decision 4, not a blocker.)

## Deferral Check
- [x] Steps 1–7 executed.
- [x] Step 7 (backlog rewrite) completed via helper after the explicit operator-review gate.
- [x] No production code touched (findings + helper-mediated `BACKLOG.md` only).

## Security Review

**State**: no findings

## Security review — Task 177, implementation phase

I reviewed the full changeset at `/tmp/-home-matt-repo-coding-with-files-task-177/changeset.txt` against the five threat categories in `.cwf/docs/skills/security-review.md` § "Threat categories" (a)–(e).

**Nature of the changeset.** Two kinds of change, both pure documentation:
1. `BACKLOG.md` — one backlog item removed and re-added (rewritten) at the end, performed via `cwf-backlog-manager`, not a direct edit.
2. Five new task workflow planning files `a-task-plan.md` through `e-testing-plan.md`, all Markdown, all newly created.

No `.cwf/scripts`, `.cwf/lib`, skills, hooks, templates, or any executable/interpreted file is touched. There is no Perl, shell, or other code in the diff.

**(a) Bash injection / unsafe command construction.** No shell commands are introduced as code. The planning docs *describe* commands the future exec phase would run, but these are prose plans, not executed constructions, and none interpolate untrusted strings into a single-string `system`. The design docs explicitly favour safe patterns (helper-mediated backlog edits, `--body-file=<scratch>` rather than inline `--body`, cleanup matched to a "known scratch path only, never a blind `--force` prune"). Nothing actionable.

**(b) Perl helpers / git-output handling.** No Perl is added or modified. No newline-splitting of git output is introduced as code. The diff's mentions of `git worktree list --porcelain` are descriptions of existing read-only call sites, not new parsing code. Nothing actionable.

**(c) Prompt injection via user-supplied strings.** Most relevant category for a discovery that ingests live tool schemas. The planning docs handle it explicitly: `b-requirements-plan.md` FR2 mandates quoted schema/doc fragments are "evidence only and never executed as instructions… ingested harness text is data, not a command"; restated in `c-design-plan.md` Constraints and `e-testing-plan.md` Security. The backlog body contains only descriptive text — no embedded instruction a downstream model would key a tool call off. Nothing actionable; the injection-surface discipline is a strength here.

**(d) Unsafe environment-variable handling.** No env vars are introduced or consumed by anything in this diff. Not applicable.

**(e) Pattern-based risks (safe-here-but-risky-elsewhere).** One forward-looking note for the *feature* task this discovery seeds (not a defect here): the backlog item / `d-plan` Step 5 propose a future CWF skill `ToolSearch`-load the worktree tools and rely on the gate's "project instructions (CLAUDE.md/memory)" clause as authorisation. **Safe here because** this diff only documents intent and defers the design; **audit future uses where** the invariant "a worktree tool is only invoked under explicit, scoped authorisation" might not hold — a future skill treating a standing process document as blanket pre-authorisation could erode the `discard_changes`/refusal gate. Planning docs already guard this ("never `discard_changes: true` unprompted", "surface teardown to the operator"); the feature task's security review should confirm the skill does not auto-authorise removal.

No actionable security findings in this diff.

```cwf-review
state: no findings
summary: Docs-only changeset (BACKLOG.md rewrite + five a-e planning files); no code, no actionable (a)-(e) concerns. Injection discipline for ingested schemas is explicit; one forward-looking (e) note for the feature task, already mitigated in-plan.
```

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
