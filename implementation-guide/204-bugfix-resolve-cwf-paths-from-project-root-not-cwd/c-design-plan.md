# Resolve .cwf paths from project root, not cwd - Design
**Task**: 204 (bugfix)

## Task Reference
- **Task ID**: internal-204
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/204-resolve-cwf-paths-from-project-root-not-cwd
- **Template Version**: 2.1

## Goal
Make CWF resolve `.cwf/...` correctly regardless of the agent's working directory
— across skill Bash invocations, skill Read/Edit doc-refs, **and hook
registration** — without breaking the permission allowlist or worktree-safety.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Problem Decomposition: three path-resolution surfaces

CWF references `.cwf/...` from three mechanisms that resolve relative paths
**differently**:

1. **Bash tool invocations** (`Run `.cwf/scripts/command-helpers/...``) — resolved
   by the shell against its **persisted cwd**. These BREAK when the shell cwd is
   not the repo root (subagent, manual `cd`, nested invocation).
2. **Read/Edit tool paths** (`Read `.cwf/docs/...``) — resolved by the harness
   against the **shell cwd** (assumption A1 was that the harness used the project
   root; the Phase-0 spike **disproved** it — see below). These BREAK identically
   to (1) when cwd ≠ root.
3. **Hook registration** in `.claude/settings.json` (`"command":
   ".cwf/scripts/hooks/..."`) — run by the **harness** at hook-fire time from the
   session cwd. These BREAK when cwd ≠ root, and **fail open** silently
   (Claude Code reports a non-blocking "command not found" and proceeds). This was
   discovered during the Phase-0 spike (the `pretooluse-bash-tool-check` hook
   errored `not found` while cwd was a subdirectory) and **folded into this task**
   (same bug class, highest severity).

**A1 correction (spike finding).** The Phase-0 spike showed the Read tool
resolves a relative `file_path` against the **shell cwd**, not the project root
(a relative `Read .cwf/docs/...` from a subdir returns "File does not exist").
So surface (2) breaks too — but the **same anchor fixes it for free**: the anchor
is each skill's first Bash action, it sets cwd = root, and cwd persists across
tool calls (verified), so every later relative Read/Edit resolves. This *narrows*
the design (one mechanism covers surfaces 1 + 2), it does not expand it.

Surfaces (1) and (2) are fixed by the cwd anchor (D1). Surface (3) **cannot** be
fixed by the anchor — the hook fires at the harness layer *before* the command
body (where the anchor runs) executes — so it needs a registration-time fix (D6).

**Failure mechanism (the decisive point).** The break is the shell *locating the
executable*, which happens **before** any in-script logic runs. A helper that
self-resolves its data root (most CWF helpers call `find_git_root` internally,
e.g. `context-manager` → `TaskPath::resolve`) is still un-invocable when cwd ≠
root, because the shell cannot find the binary in the first place. Reproduced
(Task-204 design verification):

```
$ ( cd /tmp && .cwf/scripts/command-helpers/context-manager location )
/bin/bash: .../context-manager: No such file or directory   # exit 127
```

So internal self-resolution does **not** make this a non-problem; *every*
relative script invocation fails when cwd ≠ root. (Surveyed surface: **149**
`.cwf/...` references across the SKILL.md files — 10 workflow skills via the
preamble, 10 non-preamble skills directly.)

## The deciding constraint: the permission allowlist is keyed on relative strings

`cwf-claude-settings-merge` derives `.claude/settings.json` allowlist entries
from `.cwf/security/script-hashes.json` as **relative** command-string matchers,
e.g. `Bash(.cwf/scripts/command-helpers/context-manager:*)` and
`Bash(.cwf/scripts/cwf-manage:*)`. Claude Code matches these as command-string
prefixes.

Therefore rewriting invocations to an absolute form
(`"$root/.cwf/scripts/..."` or `cd "$root" && .cwf/...`) would **stop matching**
the allowlist → a permission-prompt on every CWF script call, plus
machine-specific absolute paths embedded in skills. This rules out the
"prefix every reference" approach the env-var framing implies.

## Key Decisions

### D1 — Anchor the shell cwd to the repo root (chosen)
- **Decision**: Each skill's FIRST Bash action is a guarded `cd` to the
  worktree-safe main repo root. All subsequent `.cwf/...` invocations stay
  **relative** (verbatim, allowlist-matching) and resolve correctly because cwd
  is now the root. cwd persistence across Bash calls (harness guarantee) means
  one `cd` per skill suffices; env vars are *not* relied on (they do not persist).
- **Canonical idiom** (worktree-safe, tolerant; matches `find_git_root` / tmp-paths.md):
  ```bash
  gcd=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
  if [ -n "$gcd" ]; then r=$(cd "$(dirname "$gcd")" && pwd); [ "$PWD" = "$r" ] || cd "$r"; fi
  ```
- **Failure contract (Robustness F1)**: outside a git repo `gcd` is empty → the
  whole block is a **no-op** (never `cd ""` to a wrong/empty target). The first
  relative `.cwf/...` call then fails **visibly** (exit 127), which is the
  acceptable degrade: fail to the original visible error, never silently to a
  wrong root. This single tolerant shape serves every skill; `cwf-init` needs no
  special variant (it simply no-ops until the repo exists — D3).
- **Rationale**: Preserves the relative command strings the allowlist depends on;
  guard makes it a **no-op in the common case** (cwd already root) → zero
  behavioural change and no new permission prompt on the normal path; uses the
  existing canonical `--git-common-dir` derivation so it returns the MAIN root
  even from a linked worktree.
- **Trade-offs**: When cwd ≠ root, the `cd` may incur one permission prompt
  (rare; far better than silent failure). Relies on cwd persisting across Bash
  tool calls — a documented harness behaviour, re-verified in testing.
- **Reconciliation with the "do NOT cd" convention** (Task 173): standalone
  maintenance scripts (`update-cwf-skill-docs.sh`, the tmp-paths.md derivation)
  deliberately resolve the root *into a variable* and reference it explicitly,
  never moving the shell cwd — because they control all their own paths and want
  worktree-safety by explicit reference. Skills are a **different context**: the
  permission allowlist forces their script references to stay *relative*
  (above), and a relative reference only resolves from cwd == root. So skills
  cannot use the variable-reference form without breaking the allowlist. The
  guarded `cd` is therefore a **deliberate, scoped exception** to the no-cd rule,
  bounded to skill entry and made safe by anchoring to the **main** root (never a
  worktree — the no-cd rule's data-loss concern is `cd`-ing *into* a disposable
  worktree, the opposite direction). The no-cd rule stands unchanged for
  standalone/worktree-targeting code.
- **Reconciliation with `feedback_no_cd_git_rev_parse.md` (the binding no-cd
  rule, Misalignment F1)**: that rule fires on `cd "$(git rev-parse
  --show-toplevel)"` and raises two objections, both addressed here:
  1. *"The relative `.cwf/...` already enforces run-from-root via ENOENT; the cd
     adds nothing."* — True only when cwd is **already** root (the feedback's
     assumption). The anchor's purpose is the case where cwd is **not** root:
     because cwd persists across Bash calls, one anchor fixes **all** subsequent
     relative refs at once — Bash invocations *and* Read/Edit doc-refs (surface 2,
     which the spike showed also key off cwd). That is a capability ENOENT-per-call
     cannot provide. The anchor establishes root once; it does not redundantly
     re-cd when already there (the `[ "$PWD" = "$r" ]` guard).
  2. *"`$(git rev-parse …)` substitution trips a blocking permission prompt."* —
     **Empirically disproved for this idiom in the Phase-0 spike**: the anchor
     (including the `git rev-parse --git-common-dir` substitution) ran from
     cwd==root and from a subdirectory with **no** permission prompt and no
     bash-tool-check block. The feedback concerned a different construction; this
     idiom's `git rev-parse` reads only, the result is quoted, and the harness did
     not prompt. The "no new prompt on the normal path" claim therefore holds (and
     is re-asserted as TC in e). The `update-cwf-skill-docs.sh` variable-reference
     precedent (F2) is the *standalone-script* shape; skills are the allowlist-
     bound exception, which is exactly why this anchor is justified rather than
     redundant.
- **Do NOT allowlist the anchor**: the rare cwd ≠ root prompt is accepted as-is.
  The `cd`/`git` compound must never be added to a `Bash(...)` allowlist grant to
  suppress it (that is the broadening `worktree-process.md` forbids).

### D2 — `CLAUDE_PROJECT_DIR`: not used for the cwd anchor; adopted for hooks (D6)
- **Decision (anchor)**: For surfaces (1)/(2) the env var is **not** adopted; the
  git idiom is authoritative and is the **single canonical form** (Improvements
  F1 — no `${CLAUDE_PROJECT_DIR:-…}` fallback branch: it is admittedly unreliable
  in the general Bash env, never authoritative, and a second code path in a
  snippet copied into ~20 files is pure drift/test surface for zero correctness
  gain).
- **Decision (hooks)**: For surface (3) `${CLAUDE_PROJECT_DIR}` **is** adopted —
  it is the one context where the var is reliable. It is hooks-only, and hook
  registration is precisely a hook context, where Claude Code **documents** it as
  the recommended way to reference project scripts cwd-independently (*"Do not use
  relative paths in hook commands. Always use absolute paths or the placeholder
  variables."* — code.claude.com/docs/en/hooks). See D6.
- **Rationale**: `CLAUDE_PROJECT_DIR` is hooks-only — confirmed missing from the
  general Bash environment (claude-code #33815). In the *general* Bash tool env it
  is unreliable, so the anchor must not depend on it; in the *hook* env it is
  guaranteed, so it is exactly right for D6. The original "not a dependency"
  framing was correct for the surface known at planning time (Bash invocations);
  the hook surface, discovered in the spike, is the documented exception.

### D3 — Centralise the anchor at each skill's first action; do not edit the 149 refs individually
- **Authoritative placement model (Improvements F4)**: attach the anchor at each
  skill's **existing first Bash action** — the universal `**First**: Run
  `.cwf/scripts/command-helpers/context-manager location`` line (17 skills) — as a
  new fenced bash block immediately *above* that line. cwd persistence then
  carries it forward to every later `.cwf/...` use (Bash *and* Read/Edit).
  **There is no "Step 0" and no preamble retitle** — the earlier "Step 0 in
  workflow-preamble.md / retitle to Steps 0-4" idea is **superseded** by this
  model (it created divergence between the preamble and the non-preamble skills for
  no benefit). The 3 skills with no `**First**` line (calls only inside
  per-subcommand examples) get a new explicit unconditional first-action line —
  details in d-implementation-plan.md.
- **Placement rule**: the anchor must precede the first relative `.cwf/...` use of
  *either* kind (Bash invocation or Read/Edit doc-ref) — both break off-root
  (A1 corrected). It uses no user input, so it sits before any task-path
  validation and cannot disturb the preamble's injection-safe ordering.
- **`cwf-init` bootstrap**: needs no special variant — the tolerant idiom (D1)
  no-ops outside a repo, so init's anchor is the same block; it simply does
  nothing until the repo exists. Implementation plan pins the exact line position
  relative to any `git init`.
- **Rationale**: The `.cwf/...` reference strings stay verbatim (allowlist-safe);
  only the *entry condition* (cwd == root) is established once per skill. One
  canonical idiom, no 149-site rewrite. Consistency + simplicity.
- **Drift control**: the idiom is *copied* into ~20 SKILL.md files — a duplicated
  snippet, not a single-source literal. Guarded at the testing phase by a grep
  asserting both (a) one byte-identical canonical form **and** (b) *coverage* —
  every skill referencing `.cwf/...` has the anchor before its first such use, so
  a skill that silently loses its anchor is caught (Robustness F3), not only one
  that drifts in form.
- **Trade-off**: ~20 skill files change (to add the anchor block), but each change
  is the same single idiom.

### D5 — Interaction with `pretooluse-bash-tool-check` (verify, not change)
- The Step-0 `cd` is itself a Bash command and passes through the
  `pretooluse-bash-tool-check` hook (which inspects `command` + `cwd`). The
  design assumes it neither blocks nor warns on a guarded `cd`; this is a
  verification item for the testing phase, not a planned change.

### D4 — Helper scripts: no change required, by design
- **Decision**: Scripts are left as-is. Those already using `find_git_root`
  (`backlog-manager`, `task-stack`, `template-copier-*`, `context-manager.d/location`,
  `cwf-manage`) stay self-resolving. Those relying on cwd == root by documented
  invariant (`cwf-claude-settings-merge`, which *must* emit relative allowlist
  entries) keep working because D1 upholds cwd == root before they run.
- **Rationale**: Reuse over duplication; avoid touching hashed scripts (no hash
  churn, no validate risk) when the cwd anchor already satisfies their invariant.
- **Trade-off**: Defence-in-depth self-resolution is not added to
  `cwf-claude-settings-merge`; justified because it is invoked only by `cwf-init`
  (which anchors first) and its relative-emit invariant is intentional.
- **Amendment (D6)**: `cwf-claude-settings-merge` *is* now changed — but only its
  hook-`command` emission (surface 3), not its allowlist emission. Its
  cwd==root invariant for *its own* invocation still holds via D1.

### D6 — Hook registration: emit `${CLAUDE_PROJECT_DIR}/.cwf/...` (folded-in)
- **Problem**: `cwf-claude-settings-merge` writes every hook `command` in
  `.claude/settings.json` as a bare relative `.cwf/scripts/hooks/<name>` (and the
  rules-inject command as `cat .cwf/rules-inject.txt …`). When the session cwd ≠
  root the harness cannot find these and the hook **fails open silently**. Two of
  the affected hooks are gates (`pretooluse-bash-tool-check`,
  `subagentstop-security-verdict-guard`) and one injects the standing CWF rules —
  so the failure silently disables quality/security gates. This is the most severe
  instance of the task's bug class and the anchor (D1) cannot reach it.
- **Decision**: The generator emits hook commands prefixed with
  `${CLAUDE_PROJECT_DIR}/` — `${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/<name>` for
  manifest-derived hooks (incl. the R3/guard literals), and
  `cat "${CLAUDE_PROJECT_DIR}/.cwf/rules-inject.txt" 2>/dev/null || true` for the
  rules-inject literal. `${CLAUDE_PROJECT_DIR}` is harness-expanded and guaranteed
  set in hook execution (D2).
- **Literal-token rule (Security F2, FR4(e))**: the generator emits the **literal
  string** `${CLAUDE_PROJECT_DIR}/` (a compile-time constant in the generator
  source). It must **never** read `$ENV{CLAUDE_PROJECT_DIR}` at generate-time and
  bake an absolute path into `settings.json` — that would put a machine-specific
  (and potentially stale/attacker-influenced) value on the hook command path. The
  token is expanded by the harness at hook-fire time, not by the generator.
- **Allowlist stays relative**: the `permissions.allow` entries
  (`Bash(.cwf/scripts/hooks/<name>)`) are **unchanged** — they govern *agent* Bash
  invocations of a hook (e.g. `… --check`, which the agent calls relative under the
  anchored cwd), not the harness's hook execution. Two independent surfaces:
  hook-`command` (harness-run → prefixed) vs allowlist (agent-run → relative). So
  no allowlist storm, satisfying the deciding constraint above.
- **Migration (avoid duplicate hooks)**: `merge_hooks` dedups by *exact* command
  string, so emitting the new prefixed command while the old relative command
  still sits in a user's `settings.json` would register **both** (the hook would
  run twice). The generator therefore prunes any existing CWF hook command before
  merging the prefixed forms — modelled on the existing
  `prune_dead_userpromptsubmit_matcher`, and **surfacing the prune count**
  (feedback: surface, never smooth). `.claude/settings.json` is regenerated in
  this task.
- **Exact-shape prune predicate (Security F3)**: the prune must match **only
  CWF-owned command shapes** by **anchored full-string** comparison — never a
  substring match on `.cwf/scripts/hooks/` (which could delete a user's
  deliberately-relative override). The match set is: each manifest-derived hook
  name as the exact string `.cwf/scripts/hooks/<name>`, plus the exact old
  rules-inject literal `cat .cwf/rules-inject.txt 2>/dev/null || true`. Like
  `prune_dead_userpromptsubmit_matcher`, it tolerates hand-edited/malformed
  settings without dying and never touches user-authored hook commands
  ("ownership-by-shape").
- **Worktree**: harmless. The docs do not specify whether `${CLAUDE_PROJECT_DIR}`
  points to the worktree or main root, but it only needs to locate the hook
  *script* (present in either checkout, since `.cwf/` is tracked); each hook then
  calls `find_git_root()` internally to resolve the main data root (Task 173).
- **Security (FR4(e))**: the emitted command stays a **compile-time literal** —
  `${CLAUDE_PROJECT_DIR}` is a fixed token expanded by the harness, never
  attacker-sourced data — so the existing "hook command must stay constant"
  invariant (the `$CANONICAL_RULES_INJECT_CMD` rationale) is preserved.
- **Hash**: `cwf-claude-settings-merge` is hash-tracked → its `sha256` is
  refreshed in the **same commit** as the edit (hash-updates convention).
  `.claude/settings.json` is **not** hash-tracked → no manifest churn there.

### Rejected alternatives
- **Prefix every *Bash invocation* with `$root/` or `$CLAUDE_PROJECT_DIR/`**:
  breaks the permission allowlist (relative-string matchers), embeds machine paths,
  and the env var is unreliable in the general Bash env. Rejected for surfaces
  (1)/(2). (Note: prefixing is *correct* for surface (3) hook commands — D6 — a
  different, allowlist-free, env-guaranteed context.)
- **`cd "$root" && .cwf/...` per invocation**: command string no longer begins
  with `.cwf/...` → allowlist miss on every call. Rejected (D1 cd's once, separately).
- **A `.cwf` helper that prints the root**: bootstrapping paradox — locating the
  helper itself needs the root. Root resolution must be a pure-git/env idiom.

## System Design
### Component Overview
- **Skill first-action anchor** (surfaces 1 + 2): each skill's first Bash action
  runs the guarded-`cd` anchor before any relative `.cwf/...` Bash invocation or
  Read/Edit doc-ref. (The implementation plan refines D3's "Step 0" to attach at
  each skill's existing `**First**` line — cwd persistence carries it forward.)
- **`cwf-claude-settings-merge`** (surface 3): emits hook `command`s prefixed with
  `${CLAUDE_PROJECT_DIR}/`; prunes stale relative CWF hook commands first;
  allowlist emission unchanged. Hash refreshed in-commit.
- **`.claude/settings.json`**: regenerated so its hook commands carry the prefix.
- **Other helper scripts**: unchanged (D4).

### Data Flow
*Surfaces 1 + 2 (skill, runtime):*
1. Skill invoked → first Bash action runs the guarded-`cd` anchor (pure git, no `.cwf` dependency).
2. cwd is now the main repo root (or already was → no-op).
3. All subsequent relative `.cwf/...` Bash invocations *and* Read/Edit doc-refs resolve (and Bash invocations match the allowlist).

*Surface 3 (hooks, harness):*
1. `cwf-claude-settings-merge` writes `"command": "${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/<name>"`.
2. Hook fires from any cwd → harness expands `${CLAUDE_PROJECT_DIR}` → script located and run.
3. The hook script calls `find_git_root()` internally → main data root resolved (worktree-safe).

## Interface Design
The canonical anchor idiom (single source of truth; tolerant form per D1 — d
restates it as the byte-identical block copied into each skill's first action):
```bash
# Anchor to the MAIN repo root so relative .cwf/ paths resolve from any cwd
# (worktree-safe via --git-common-dir; tolerant when not yet in a git repo).
gcd=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
if [ -n "$gcd" ]; then r=$(cd "$(dirname "$gcd")" && pwd); [ "$PWD" = "$r" ] || cd "$r"; fi
```
For surface (3) the generator emits the literal hook-command prefix
`${CLAUDE_PROJECT_DIR}/` (D6). No new script, no new config key, no new data model.

## Plan Review Synthesis
### Round 1 (4 reviewers, original cwd-anchor scope)
- **Scope challenge (robustness/misalignment/improvements)** — "helpers already
  self-resolve via `find_git_root`, so invocations don't break." **Rebutted with
  evidence**: the break is *executable location* (exit 127), which precedes any
  in-script resolution (see Failure mechanism). Broad scope retained.
- **Convention conflict (misalignment F1)** — `cd` contradicts the Task-173
  "do NOT cd, resolve to a variable" rule. **Applied**: added explicit scoped-
  exception reconciliation (D1) + "do not allowlist the anchor" note.
- **Factual fixes (all)** — 138→**149** refs; `cwf-init` git-bootstrap; bash-
  tool-check hook interaction (D5). **Applied.**
- **Security** — no injection surface (`$root` from git output only, quoted).

### Round 2 (4 reviewers, after folding in the hook-registration fix + spike)
- **Robustness F1 (substantive) — applied**: anchor empty-`$root` would `cd ""`
  silently → adopted the **tolerant** idiom (no-op outside a repo, visible exit
  127 on first ref) with an explicit failure contract (D1).
- **Robustness F2 → e**: `${CLAUDE_PROJECT_DIR}` unset at hook fire would re-create
  silent fail-open. Added e-testing item to **empirically confirm the two gate
  hooks fire from a non-root cwd** post-change (close the fail-open), not merely
  that the script resolves.
- **Robustness F3 → e**: drift grep checks *form* but not *coverage*; a skill that
  loses its anchor passes silently. Strengthened the drift test to assert
  **coverage** (anchor present before first `.cwf/` ref in every referencing skill).
- **Misalignment F1 (substantive) — applied**: reconciled against the binding
  `feedback_no_cd_git_rev_parse.md` (not only Task 173): rebutted objection 1 via
  the cwd-persistence/surface-2 distinction and objection 2 via the **empirical
  spike** (the `git rev-parse` substitution did **not** prompt). D1 updated.
- **Improvements F1 — applied**: dropped the optional `${CLAUDE_PROJECT_DIR:-…}`
  anchor fallback → one canonical form (D2).
- **Improvements F4 — applied**: resolved the "Step 0 + retitle" vs `**First**`-
  attachment ambiguity by making `**First**`-attachment authoritative; no Step 0,
  no preamble retitle (D3).
- **Security F2 — applied**: D6 must emit the **literal** `${CLAUDE_PROJECT_DIR}/`
  token, never read `$ENV{CLAUDE_PROJECT_DIR}` at generate-time (FR4(e)).
- **Security F3 — applied**: D6 prune predicate must be **anchored full-string**
  ownership-by-shape, never a substring on `.cwf/scripts/hooks/`.
- **Security F1/F4/F5 (confirm-safe)** — FR4(e) literal invariant verified against
  source; anchor adds no exec/env surface; worktree ambiguity handled by in-hook
  `find_git_root()`. **Accepted.**

## Constraints
- Must not alter the relative command strings the permission allowlist matches.
- Worktree-safe: anchor to the main root, never a linked worktree (Task 173 / 172).
- No `cd` into a disposable worktree (data-loss class); anchoring to the main
  root from a subdirectory of the same tree is safe.
- Perl/POSIX/British-prose conventions. No `CLAUDE_PROJECT_DIR` dependency for the
  cwd anchor (surfaces 1/2); `${CLAUDE_PROJECT_DIR}` *is* used for hook
  registration (surface 3) — the one context where it is guaranteed (D6).

## Decomposition Check
- [x] **Time**: >1 week? No.
- [x] **People**: >2 people? No.
- [x] **Complexity**: 3+ distinct concerns? No — two tightly-coupled mechanisms
  (cwd anchor for skills; `${CLAUDE_PROJECT_DIR}` for hook registration) addressing
  one bug class (relative `.cwf/` breaks off-root). Not independent enough to split.
- [x] **Risk**: High-risk components needing isolation? No.
- [x] **Independence**: Separable parts? Preamble vs non-preamble skills, but trivially small.

**Verdict**: No decomposition. 0 signals.

## Validation
- [x] Design review completed (4 parallel reviewers; synthesis above)
- [ ] Integration points verified (bash-tool-check hook, allowlist match) — testing phase

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Design held through implementation. The cwd-anchor idiom (mirroring `find_git_root()`
via `--git-common-dir`) and the surface-3 `${CLAUDE_PROJECT_DIR}/`-prefix decision
shipped as designed. D6 (keep the hook allowlist relative) proved correct — the
allowlist still matches after prefixing the command strings.

## Lessons Learned
The Phase-0 spike disproved assumption A1 (Read/Edit resolve against project root):
they resolve against the **shell** cwd, so one anchor fixes doc-reads too. Surfacing
path-resolution assumptions as explicit spike items belongs in design, not exec.
