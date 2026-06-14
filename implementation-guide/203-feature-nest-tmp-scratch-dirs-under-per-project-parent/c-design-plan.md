# Nest tmp scratch dirs under per-project parent dir - Design
**Task**: 203 (feature)

## Task Reference
- **Task ID**: internal-203
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/203-nest-tmp-scratch-dirs-under-per-project-parent
- **Template Version**: 2.1

## Goal
Define the concrete form, creation algorithm, and call-site changes for nesting
per-task scratch dirs under one per-project parent.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### D1 — Canonical form
- **Decision**: `${TMPDIR:-/tmp}/cwf<dashified-repo>/task-<num>/`, where
  `<dashified-repo>` is the absolute repo path with every `/` → `-` (leading dash
  preserved, exactly as today). The literal `cwf` prefix sits immediately before the
  leading dash, so the parent reads cleanly: `cwf-home-matt-repo-coding-with-files`.
  Worked example (this repo, task 203):
  `${TMPDIR:-/tmp}/cwf-home-matt-repo-coding-with-files/task-203/`.
- **Rationale**: Reuses the existing dashify rule verbatim — the helper already computes
  `(my $dashed = $repo_root) =~ s{/}{-}g` (`-home-…`), so `cwf$dashed` yields the clean
  single-dash parent with **no code change to the dashify step**. The parent is a stable
  per-project prefix; tasks become `task-<num>` leaves under it.
- **Trade-offs**: One extra directory level and one extra `mkdir` at first use vs. a
  permanently stable allowlist anchor and one prompt per project. Net win.

### D2 — Two-level creation algorithm (the contract both the doc snippet and helper follow)
```
parent = <base>/cwf<dashified-repo>
leaf   = parent/task-<num>
1. mkdir 0700 parent  (unless -d)          # atomic owner-only mode on create
2. (helper only) reject unless (-d parent && !-l parent) → warn + exit 1   # lstat, defence-in-depth
3. mkdir 0700 leaf    (unless -d) or warn + exit 1   # fail-closed; explicit owner-only mode
```
No sentinel file (`.cwfkeep` cut — see rejected alternatives in D3).
- **Containment boundary (unchanged from today)**: the atomic `mkdir 0700` **plus** the
  fail-closed `0600` write of the `.out` (a foreign-owned parent makes that write fail) —
  exactly the posture documented at `security-review-changeset:267-268`. Step 2 does **not**
  replace that boundary.
- **Step 2 is defence-in-depth diagnostics, framed honestly**: it rejects a **symlinked**
  parent (`!-l`, i.e. `lstat` semantics — a plain `stat` follows the link and would
  validate the target, defeating the check) because the parent is now shared and
  longer-lived across tasks. Ownership is **not** re-asserted here — it stays enforced by
  the fail-closed write (avoids a racy TOCTOU stat masquerading as the boundary). **Never
  auto-chmod** a wrong-mode pre-existing parent (surface, never smooth). This refines
  requirements NFR4a, whose owner/mode stat is subsumed by "symlink-reject + fail-closed write".
- **Ordering is load-bearing (race-tolerant)**: the `-d && !-l` recheck MUST follow the
  `mkdir` — it tolerates a concurrent create by another agent session (a supported scenario)
  yet still rejects a symlink. Mirrors the precedent's "race-tolerant: re-check below"
  comment (`pretooluse-bash-tool-check:127`).
- **Reuse (with one deliberate divergence)**: this mirrors the existing, working pattern in
  `.cwf/scripts/hooks/pretooluse-bash-tool-check:124-131` (`mkdir 0700 unless -d`; then
  `unless -d && !-l`) — so the symlink-reject is an **established in-repo idiom, not new
  surface**. It **omits** that precedent's best-effort `chmod 0700` clamp (line 129) on
  purpose — the helper must not auto-chmod a foreign/wrong-mode parent (surface, never
  smooth). An inline code comment flags this so the clamp is not reintroduced by copying the
  precedent verbatim.
- **`mkdir 0700` is umask-safe**: owner-only bits requested; umask only ever *removes*
  bits, so the result is at most `0700` and never gains group/other bits — no explicit
  `chmod` needed for the freshly-created case. Step 1 failing because the parent exists as
  a **plain file** (not a dir) exits 1 via the existing `or do { warn; exit 1 }` — covered
  upstream, not a step-2 concern.
- **Doc snippet vs helper asymmetry (deliberate)**: the copy-paste snippet in
  `tmp-paths.md` performs steps 1 and 3 only (`mkdir -m 0700 -p`) — matching today's snippet
  (no stat check) for ad-hoc single-user use. The **helper** adds step 2 because it is
  long-lived automation that may meet a pre-existing shared parent; cost is ~2 lines. Stated
  in the doc so it is a conscious choice, not drift.
- **Improvements-reviewer dissent (recorded, twice)**: a reviewer argued step 2 is beyond
  the single-user threat model and should be cut. Kept: the shared, long-lived parent is the
  one material change, and the check is the **same `!-l` idiom the carved-out hook already
  uses** (`pretooluse-bash-tool-check:128`) — consistency, not new surface (correctness >
  maintainability). Independently removable if the user later prefers the cut.

### D3 — `.cwfkeep` sentinel: CUT (rejected alternative)
- **Decision**: Do **not** create a `.cwfkeep` (or any sentinel) file. The named
  `cwf-home-matt-repo-coding-with-files` parent **is** the devops-discoverability marker;
  a sentinel would only restate the directory name. Its other mooted purpose (anti-reap
  anchor) doesn't hold — an age-based reaper sweeps files by atime too.
- **Why recorded**: it was the user's original instruction; cut after the user confirmed,
  backed by unanimous plan-review across all phases. Removing it also simplifies test
  cleanup (no non-empty-parent wrinkle).

### D4 — Allowlist pattern: documented only, no settings edit (FR4)
- **Decision**: CWF modifies **no** settings file. `tmp-paths.md` documents the optional
  rules a user MAY add themselves. Correct syntax (verified against
  `code.claude.com/docs/en/permissions.md` and existing `settings.local.json` entries):
  - **Write tool** (gitignore path semantics; `//`=absolute, `**`=subtree):
    `Write(//tmp/cwf-home-matt-repo-coding-with-files/**)` (and
    `Write(//tmp/claude/cwf-home-matt-repo-coding-with-files/**)` for the sandbox base).
  - **Script execution** (Bash rules match the **command string**; `*` spans `/`; `**` is
    **not** supported): `Bash(/tmp/cwf-home-matt-repo-coding-with-files/*)` (and the
    `/tmp/claude/...` variant).
- **Rationale**: the path embeds a machine-specific absolute path and the file is user-owned
  — not CWF's to edit. Documenting the pattern lets each checkout opt in.
- **Trade-off (must be stated in the doc)**: framed as **per-project vs per-task
  granularity** — the old sibling form let a user allowlist a *single* task's path; the
  nested form's natural rule covers the *whole* `cwf-<repo>/` subtree, so a script written
  into **any** task leaf by **any** session executes without a prompt. A deliberate,
  user-owned widening bounded to this project's parent under the single-user model. The doc
  must also retain `tmp-paths.md`'s existing no-secrets-in-scratch caution — more important
  now that the subtree is pre-approved for execution.

### D6 — Provision + signpost at task start (FR5)
- **Decision**: `/cwf-new-task` creates the parent **and** task leaf
  (`mkdir -m 0700 -p "${TMPDIR:-/tmp}/cwf<dash>/task-<num>"`) and surfaces the path in its
  next-steps output; `tmp-paths.md` tells the agent to use `…/cwf<dash>/task-<num>/`.
- **Reuse the canonical snippet (no parallel derivation)**: the skill MUST use the
  `tmp-paths.md` derivation snippet (worktree-safe via `git rev-parse --path-format=absolute
  --git-common-dir`), extended for the `cwf` prefix + leaf — **not** a fresh inline
  `${repo_root//\//-}` one-liner, which would silently drop worktree-safety and create
  doc↔skill drift. Single source = the `tmp-paths.md` snippet.
- **Where**: the **skill step** (not the hashed `task-workflow` helper) — keeps "at the
  beginning of each new task" literal without hash churn. In `/cwf-new-task` it follows the
  existing branch-creation step 4 (where sibling side-effects already live). `/cwf-new-subtask`
  has **no `git checkout -b` step** (it stays on the parent branch), so place its provisioning
  after its "Create Subtask" step; it reuses the same project parent with its own
  `task-<subnum>/` leaf.
- **Failure handling (non-fatal, honest signpost)**: a failed `mkdir` warns but never blocks
  directory/branch creation (task creation does not need scratch). On failure the next-steps
  output must **not** print the path as if it exists — suppress it or annotate "will be
  created on first use". The on-demand creation in consumers (D2) is the safety net if a
  reaper later removes the dir.
- **Symlink-guard asymmetry (deliberate)**: D6 uses the snippet form (steps 1+3, no step-2
  `!-l` reject). Acceptable because provisioning is best-effort/non-fatal — a hostile
  pre-planted symlinked parent just yields a tolerated failed `mkdir`; the **helper's** step-2
  reject plus the fail-closed `0600` write remain the boundary on any consuming write.

### D5 — `pretooluse-bash-tool-check` state dir: carve out (second consumer)
- **Finding**: the hook `.cwf/scripts/hooks/pretooluse-bash-tool-check` (`state_dir`, lines
  112-120) is a *second* consumer of the tmp-paths convention. It writes
  `${TMPDIR:-/tmp}/<dashified-root>-tool-check/`. (Note: under `hooks/`, **not**
  `command-helpers/` — and it is a hashed script; D5 leaves it untouched, so no hash churn.)
- **Decision**: **do not** nest it under the new `cwf<dash>/` parent. Carve it out, and
  have `tmp-paths.md` explicitly acknowledge it (so the doc is complete, not silently
  contradicted).
- **Rationale**:
  1. It is already **one stable dir per project** (not per-task) — it never proliferated,
     so it does not have the per-task permission-prompt problem this task solves.
  2. It is written by the hook **programmatically** (hooks run automatically), not executed
     via a Bash prompt — the FR4 allowlist anchor is irrelevant to it.
  3. It uses a **different dashify rule** (`s{[^A-Za-z0-9]+}{-}g`) than the helper
     (`s{/}{-}g`). Truly sharing the parent would require unifying both rules across two
     hashed scripts for zero functional gain and non-trivial risk.
- **Trade-off**: the convention gains one named exception rather than a perfectly uniform
  "everything nests" story. Honest and minimal beats uniform-but-risky.

## Affected Surface
- **`.cwf/docs/conventions/tmp-paths.md`** — canonical form, derivation snippet, worked
  example, artefact-path examples, threat-model guard text, optional-allowlist-pattern note
  (D4), agent active-use instruction (D6), and a note acknowledging the `-tool-check`
  state-dir carve-out (D5).
- **`.cwf/scripts/command-helpers/security-review-changeset`** — path assembly (line 263),
  mkdir block (255-275) → two-level + symlink-reject, header comments (59, 347).
  Hash refresh in same commit (`.cwf/security/script-hashes.json`).
- **`CLAUDE.md`** — Tmp Paths convention bullet (~line 89).
- **`.claude/skills/cwf-new-task/SKILL.md`** (and `cwf-new-subtask`) — provisioning step +
  surface the scratch path (D6). Not a hashed file.
- **Tests** — `t/security-review-changeset.t` asserting helper-derived path shape +
  parent/leaf 0700 and the parent-symlink reject.
- **NOT touched**: any `settings.json`/`settings.local.json` (D4).

## Out of Scope (carve-outs)
`pretooluse-bash-tool-check` `-tool-check` state dir (D5, documented exception);
`INSTALL.md` one-shot paths; `BACKLOG.md`/`CHANGELOG.md`/older `implementation-guide/`
history; legacy `settings.local.json` per-task entries. Agent memory `[[tmp-paths]]`
updated post-merge (not a repo file).

## Constraints
- POSIX-only; Perl core modules only; `use utf8;` where Perl is touched.
- Single-user host threat model unchanged; the atomic `mkdir 0700` + fail-closed write is
  the boundary.
- No settings-file edits (D4). Reversibility: the symlink-reject (D2 step 2) and the D6
  provisioning step are independently removable.

## Decomposition Check
- [x] No signals triggered (see a/b). Single coherent change.

## Validation
- [ ] `t/` test asserts nested path shape + parent/leaf 0700 from the helper (happy path)
- [ ] `t/` **negative** test: parent pre-created as a symlink → helper exits 1 (D2 step 2)
- [ ] `t/` **reuse positive** test: pre-existing correctly-owned 0700 parent → helper
      proceeds, writes leaf, no chmod attempted (the second-task shared-parent path)
- [ ] Output-level smoke test: run helper, confirm `.out` lands at nested path
- [ ] Provisioning smoke: `/cwf-new-task` creates the parent+leaf and surfaces the path;
      a forced `mkdir` failure does not block task/branch creation
- [ ] Grep sweep (old dash-separator vs new slash-separator) clean of non-carved-out refs;
      confirm `-tool-check` dir still uses its own form (D5 carve-out intact)
- [ ] `cwf-manage validate` passes after hash refresh

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All key decisions (D1–D6) implemented as designed. D2's two-level mkdir + `-d && !-l`
reject (omitting the hook's chmod-clamp, with an inline anti-reintroduction comment) and
D3's `.cwfkeep` cut shipped unchanged. The improvements-reviewer dissent on D2 step 2 was
recorded and overruled; it remains independently removable. The mid-task `.cwfkeep` touch
was confirmed a one-off and did not reinstate the sentinel.

## Lessons Learned
*Consolidated in j-retrospective.md.*
