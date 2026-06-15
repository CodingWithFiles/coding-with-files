# Resolve .cwf paths from project root, not cwd - Implementation Plan
**Task**: 204 (bugfix)

## Task Reference
- **Task ID**: internal-204
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/204-resolve-cwf-paths-from-project-root-not-cwd
- **Template Version**: 2.1

## Goal
Anchor each skill's shell cwd to the main repo root at its first Bash action, so
relative `.cwf/...` invocations resolve from any cwd, without breaking the
permission allowlist.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Implementation refinement of D3 (read first)
The committed design (D3) proposed a preamble "Step 0" plus prepends to
non-preamble skills. Codebase inspection refines this to something **smaller**:

- **Every** skill already opens with a universal first Bash action —
  `**First**: Run `.cwf/scripts/command-helpers/context-manager location``
  (17 skills) — or, for the 3 without it, a first `.cwf/...` invocation.
- The Bash tool's **cwd persists across calls within a skill invocation**, so
  anchoring at that single first action covers *every* later `.cwf/...` call,
  including the preamble's own Step 1-2. Therefore **no preamble "Step 0",
  no retitling the 10 "Steps 1-4" references** — the anchor attaches to the
  existing first-action line instead.

This is a strict reduction in blast radius and is recorded here as the
implementation-level realisation of D1's "anchor once per skill at entry".

## Phase 0 — Spike FIRST (gates the whole approach) — EXECUTED ✓
The spike was run at the start of f-implementation-exec (results recorded there).
Outcomes that feed this plan:
- **P0.1 PASS** — anchor at cwd==root raises **no** permission prompt. Confirmed
  mechanistically: the user-global `no-redundant-cd` rule only fires on a `cd` to a
  target it can *prove* equals cwd (`.`, `$PWD`, abspath==cwd); the anchor's
  `cd "$r"` targets a variable behind a `[ "$PWD" = "$r" ]` guard → never flagged.
- **P0.2 PASS** — from a subdir, a bare relative `.cwf/...` call fails exit 127;
  anchor-then-call succeeds. The live `cd "$r"` (cwd≠root) also raised no prompt.
- **P0.3 PASS** — `pretooluse-bash-tool-check` ships inert for the anchor (no
  checked-in rules; user-global rules don't match the idiom).
- **P0.4 → A1 CORRECTED** — the Read tool resolves a relative `file_path` against
  the **shell cwd**, not project root (relative `.cwf/docs/...` from a subdir
  fails). So doc-reads break too — but the **same anchor fixes them** (cwd persists;
  relative Read succeeds after the anchor). Scope *narrows* (1 mechanism, surfaces
  1+2), not expands. **Also surfaced surface 3 (hook registration) → folded in.**
- **P0.5 PASS** — cwd persists across separate Bash tool calls.
- **P0.6 PASS** — idiom run from a fixture linked worktree anchors to the MAIN root.
- **P0.7** — `cwf-init`: tolerant idiom no-ops pre-repo; same block, no special
  variant (D3). Exact line position pinned in Step 3.

The original gate semantics are retained for the record: had P0.1 failed (prompts
every time) or P0.4 implied an unfixable doc-read break, the approach would have
been brought back to the user. Neither occurred.

## Canonical anchor idiom (single reference; copied into each first-action block)
```bash
# Anchor to the MAIN repo root so relative .cwf/ paths resolve from any cwd
# (worktree-safe via --git-common-dir; tolerant when not yet in a git repo).
gcd=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
if [ -n "$gcd" ]; then r=$(cd "$(dirname "$gcd")" && pwd); [ "$PWD" = "$r" ] || cd "$r"; fi
```
The tolerant `if`/`-n` guard makes it a safe no-op outside a git repo, which also
satisfies the `cwf-init` bootstrap caveat (D3) — one idiom, no init-special-case.

**This tolerant block is THE canonical form** and supersedes the earlier
illustrative idiom in c-design-plan.md's Interface Design section (which used a
bare `root=…` without the `-n` guard). Reconciliation:
- The drift-guard test (Step 4) asserts byte-identical copies **across SKILL.md
  sites only**. It must NOT grep repo-wide: `tmp-paths.md` and
  `update-cwf-skill-docs.sh` deliberately use the *variable-assignment* form
  (`repo_root=$(…)`, no `cd`) for the no-cd convention and would false-positive.
- Variable names `gcd`/`r` are intentional (short, local, no collision with the
  `repo_root` used by the tmp-paths derivation).

**Insertion mechanics (improvements F2)**: insert this as a NEW fenced bash block
immediately *above* the existing `**First**:` prose line — do not merge it into or
rewrite that prose. The anchor and the `context-manager location` call remain two
separate Bash tool invocations; cwd persistence (P0.5) carries the anchor forward.

## Files to Modify
### Skill first-action anchoring (the fix)
Prepend the canonical idiom to the first Bash action of each skill. 17 skills
already have a `**First**: Run context-manager location` line — fold the idiom
into a fenced block immediately above that invocation:
- 10 workflow skills: `cwf-task-plan`, `cwf-requirements-plan`, `cwf-design-plan`,
  `cwf-implementation-plan`, `cwf-implementation-exec`, `cwf-testing-plan`,
  `cwf-testing-exec`, `cwf-rollout`, `cwf-maintenance`, `cwf-retrospective`
- 7 non-preamble skills with a First line: `cwf-init` (anchor above its existing
  `**First**: … context-manager location` line like the others — *not* above the
  later perm-repair step; Misalignment F3), `cwf-new-task`, `cwf-new-subtask`,
  `cwf-status`, `cwf-config`, `cwf-security-check`, `cwf-extract`

### Skills needing a new first-action block (no current First line)
**Blocking subtlety (robustness F1)**: in these three the `.cwf/...` calls appear
only inside *per-subcommand example* fenced blocks — there is no single block
that always runs first (the invoked subcommand depends on the user's request).
Folding the anchor into one example would not run for the others. Fix: add an
explicit, unconditional `**First**: run the anchor block (below) via Bash` line
*outside* and *above* the per-subcommand examples, so it runs regardless of which
subcommand follows.
- `cwf-current-task` — new First line above the `task-stack {operation}` examples
  (this skill is the most likely to be invoked from a non-root cwd, e.g. push/pop
  during nested work).
- `cwf-delete-task` — new First line above the `task-workflow delete` example.
- `cwf-backlog-manager` — new First line above the Subcommands examples.

### Surface 3 — hook registration (folded in, per D6)
**`.cwf/scripts/command-helpers/cwf-claude-settings-merge`** (hash-tracked):
- **Hook-command emission** (line ~179, `partition_manifest`): change
  `command => $path` to `command => "\${CLAUDE_PROJECT_DIR}/$path"`. **Perl-escaping
  (Security)**: the `$` of `${CLAUDE_PROJECT_DIR}` MUST be backslash-escaped (or the
  string single-quoted/concatenated) so Perl emits the literal token rather than
  interpolating an (empty) Perl variable — a silent interpolation would emit a
  bare `/` prefix and the hook would resolve relative again (silent regression).
  `$path` stays the manifest-derived relative path; only the emitted *command
  string* gains the prefix. Covers all manifest hooks incl. R3/guard (same
  emission). **Allowlist push (line ~174) stays `Bash($path)` — unchanged** (D6).
- **Rules-inject literal** (line ~336): repoint `$CANONICAL_RULES_INJECT_CMD` to
  `cat "${CLAUDE_PROJECT_DIR}/.cwf/rules-inject.txt" 2>/dev/null || true` (same
  Perl-escaping discipline).
- **Frozen legacy constant (Robustness F1)**: because the canonical constant is
  being repointed, introduce a **separate frozen** `$LEGACY_RULES_INJECT_CMD =
  'cat .cwf/rules-inject.txt 2>/dev/null || true'` for the prune to match. The
  prune must NOT derive its target from `$CANONICAL_RULES_INJECT_CMD` (now the new
  value) or it will never match the old on-disk entry.
- **Literal-token discipline (Security F2)**: the prefix is a compile-time string
  constant in the source; never `$ENV{CLAUDE_PROJECT_DIR}` read at generate-time.
- **New prune (Security F3 + Robustness F2)**: add
  `prune_stale_relative_cwf_hooks($settings)` modelled on
  `prune_dead_userpromptsubmit_matcher` — anchored **full-string** match (never
  substring) against the **complete, gate-state-independent** CWF command set:
  the bare relative `.cwf/scripts/hooks/<name>` for **all 6 manifest hooks**
  (`pretooluse-bash-tool-check`, `pretooluse-planning-write-guard`,
  `pretooluse-sandbox-logging`, `stop-stale-status-detector`,
  `stop-uncommitted-changes-warning`, `subagentstop-security-verdict-guard`) —
  derived from the manifest walk, **not** from the gated emit set, so a prior
  sandbox-on install's relative R3/guard entries are still pruned — plus
  `$LEGACY_RULES_INJECT_CMD`. Tolerate malformed settings, never die. Call it
  before `merge_hooks` (slots between the existing `prune_dead_*` call and
  `merge_hooks`, ~line 572-580) so regen replaces (not duplicates) old entries.
  **Surface the prune count on the same code paths as the existing migration note
  (incl. `--dry-run`)** (Robustness F5; feedback: surface, never smooth).
- **Hash refresh (same commit)**: refresh this script's `sha256` in
  `.cwf/security/script-hashes.json`; restore recorded working perms (0500).

**`.claude/settings.json`** (NOT hash-tracked): regenerate by running
`.cwf/scripts/command-helpers/cwf-claude-settings-merge` after the edit + hash
refresh; verify every CWF hook command now carries the `${CLAUDE_PROJECT_DIR}/`
prefix and no duplicate (relative + prefixed) pair remains.

**Mechanism confirmation (Misalignment F1)**: the `${CLAUDE_PROJECT_DIR}`
placeholder in a hook `command` is **documented** Claude Code behaviour
(code.claude.com/docs/en/hooks: *"Do not use relative paths in hook commands.
Always use absolute paths or the placeholder variables"*, with the example
`"${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/…"`; the var is also exported to the
hook process). Confirmed this session via the claude-code-guide agent reading that
page. Exec adds a path-resolution check (substitute the var = repo root and
confirm the emitted command string locates the script) so correctness does not
rest on documentation alone; the live gate-fires assertion is the Step 5 test.

### Explicitly NOT modified
- No *other* helper scripts — those using `find_git_root` stay self-resolving;
  `cwf-claude-settings-merge`'s own cwd==root invocation invariant still holds via
  the D1 anchor (only its hook-command *emission* changes, not how it is invoked).
- Allowlist (`permissions.allow`) entries — unchanged (D6 deciding constraint).

## Implementation Steps
### Step 1: Phase 0 spike — gate — DONE ✓
- [x] Ran P0.1–P0.7 (results above + in f-implementation-exec). P0.1+P0.2 pass →
      proceed. A1 corrected; surface 3 discovered and folded in.

### Step 2: Apply anchor to a single pilot skill
- [ ] Edit one workflow skill (e.g. `cwf-status`, smallest) with the idiom.
- [ ] Exercise it from cwd==root and cwd≠root; confirm fix + no new prompt.

### Step 3: Roll out the anchor to the remaining skills
- [ ] Apply the identical idiom block to all SKILL.md sites (17 with a `**First**`
      line; 3 needing a new explicit first-action line — see Files to Modify).
- [ ] Pin `cwf-init`'s anchor position relative to any `git init` (tolerant idiom
      no-ops pre-repo; confirm placement).
- [ ] Keep every `.cwf/...` reference string verbatim/relative (allowlist-safe).

### Step 4: Hook-registration fix (surface 3, D6)
- [ ] Edit `cwf-claude-settings-merge`: prefix hook `command`s with the literal
      `${CLAUDE_PROJECT_DIR}/`; update `$CANONICAL_RULES_INJECT_CMD`; add the
      anchored full-string `prune_stale_relative_cwf_hooks` (surface its count)
      and call it before `merge_hooks`. Allowlist emission unchanged.
- [ ] Refresh the script's `sha256` in `script-hashes.json` (same commit);
      restore recorded working perms (0500).
- [ ] Regenerate `.claude/settings.json` by running the helper; confirm every CWF
      hook command carries the `${CLAUDE_PROJECT_DIR}/` prefix and **no duplicate**
      (relative + prefixed) pair remains. **This static check is not the completion
      criterion** — the surface-3 fix is only done when the Step 5 gate-fires test
      passes (Robustness F3).

### Step 5: Drift-guard + regression tests
- [ ] Add the anchor drift+**coverage** test (SKILL.md sites only — byte-identical
      form *and* presence-before-first-ref; Robustness F3).
- [ ] Add the two-halves regression test (Robustness F4): from a non-root cwd,
      assert (a) a bare relative `.cwf/...` call fails exit 127 and (b)
      anchor-then-call succeeds.
- [ ] Add the hook-path test: a regenerated settings.json hook command resolves
      from a non-root cwd, and the two gate hooks fire (Robustness F2/F5).

### Step 6: Validation
- [ ] `prove t/` green (existing suite + new tests).
- [ ] `.cwf/scripts/cwf-manage validate` green (only `cwf-claude-settings-merge`
      hash changed, refreshed in-commit; no other hashed-file diff).
- [ ] **Changed-file guard (Robustness F4)**: `git diff --stat` shows exactly the
      script, `script-hashes.json`, and `.claude/settings.json` (plus the skill
      files + new tests) — no unexpected hashed-file churn, no perms drift on the
      0500 script.
- [ ] Output-level smoke test: regenerate via `cwf-claude-settings-merge` and
      confirm (a) relative `Bash(.cwf/scripts/...:*)` allowlist entries unchanged,
      (b) hook commands prefixed, (c) no duplicate hook entries.

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Plan Review Synthesis
### Round 1 (4 reviewers, original cwd-anchor scope)
- **F1 (robustness, blocking) — applied**: the 3 no-`First` skills reference
  `.cwf/` only in per-subcommand examples; added explicit unconditional First
  lines above the examples.
- **Idiom drift (all 4) — applied**: declared the tolerant block canonical,
  superseding the design's illustrative form; scoped the drift test to SKILL.md
  sites only (convention-doc/script copies legitimately differ).
- **Worktree spike, init ordering, P0.4 fail-branch, two-halves regression
  (robustness F3/F4/F5, improvements F3) — applied** to Phase 0 / Step 4.
- **Security** — no FR4(a–e) surface (idiom interpolates only quoted git output;
  `CLAUDE_PROJECT_DIR` not referenced); `pretooluse-bash-tool-check` confirmed
  inert/fail-open. **Accepted.**
- **Insertion mechanics (improvements F2) — applied**: new fenced block above the
  existing prose line, not a rewrite.

### Round 2 (4 reviewers, after folding in surface 3)
- **Robustness F1 / Improvements (blocking) — applied**: repointing
  `$CANONICAL_RULES_INJECT_CMD` orphans the old literal; added a **separate frozen
  `$LEGACY_RULES_INJECT_CMD`** for the prune to match.
- **Robustness F2 / Misalignment F2 (blocking) — applied**: the prune set must
  enumerate **all 6 manifest hooks** (incl. sandbox-gated R3/guard) gate-state-
  independently, plus the legacy rules-inject literal — else a prior sandbox-on
  install leaves stale relative orphans.
- **Security (Perl escaping) — applied**: emit `"\${CLAUDE_PROJECT_DIR}/$path"`
  with the `$` escaped so Perl emits the literal token, not an empty interpolation
  (a silent relative-resolution regression otherwise).
- **Misalignment F1 — applied**: `${CLAUDE_PROJECT_DIR}`-in-hook-command is
  documented Claude Code behaviour (confirmed via claude-code-guide reading the
  hooks doc page); added an exec path-resolution check + the Step-5 gate-fires test.
- **Misalignment F3 — applied**: `cwf-init` anchors above its existing `**First**`
  line, not above the later perm-repair step.
- **Robustness F3/F4/F5 — applied**: Step 4 completion = Step 5 gate-fires test
  (not the static check); Step 6 `git diff --stat` changed-file guard; prune count
  surfaced on the same paths (incl. `--dry-run`) as the existing migration note.
- **Phantom-file finding (improvements/misalignment, 3 reviewers) — REJECTED**:
  reviewers claimed `update-cwf-skill-docs.sh` does not exist; **verified it does**
  (`git ls-files` → `.cwf/scripts/update-cwf-skill-docs.sh`). The drift-test
  reconciliation reference is correct and retained.
- **Security (literal-token, full-string prune, in-commit hash) — confirmed safe**.

**Decomposition**: 0 signals (two tightly-coupled mechanisms, one bug class). No subtasks.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned steps executed. 20 skills received the byte-identical anchor (17 via the
idempotent inserter, 3 via manual Edit; test-cwf-skill excluded). The generator gained
the gate-independent `prune_stale_relative_cwf_hooks` + prefixed emission; sha256
refreshed in-commit, recorded perms (0500) restored.

## Lessons Learned
A plan-reviewer false positive (`update-cwf-skill-docs.sh` "missing") cost a cycle;
`git ls-files` confirmed it exists and the finding was rejected. Lexical-scope ordering
bit once — the legacy-literal constant had to be declared above the prune function.
