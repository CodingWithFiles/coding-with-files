# Adopt guarded worktree enter/exit process - Implementation Plan
**Task**: 181 (feature)

## Task Reference
- **Task ID**: internal-181
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/181-adopt-guarded-worktree-process
- **Template Version**: 2.1

## Goal
Implement the guarded CWF worktree process per the approved design: one new convention
doc, one settings key, two cross-references — no new code, no hash-tracked artefact.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- **NEW `.cwf/docs/conventions/worktree-process.md`** — the single source of truth.
  Sections (design Decision 2): `Procedure` (5-step flow) / `Prohibitions` (P1 no raw
  `git worktree add`; P2 no `remove --force`; P3 no `EnterWorktree(path:)`-into-raw-add) /
  `Threat model` (request-is-data prompt-injection clause; ToolSearch-load-failure = stop,
  not fallback; allowlist-hole "mitigated pending operator action") / `Why` / `See also`.
  Each rule stated once; C-facts cited to Task 177, not copied. British spelling, roles
  not names.
- **EDIT `.claude/settings.json`** — add `"worktree": { "baseRef": "head" }` alongside the
  existing `env` block (design Decision 3 / config shape).
- **EDIT `.cwf/scripts/command-helpers/cwf-claude-settings-merge`** (Decision 6/FR9) — add
  an install-time scan: slurp `.claude/settings.json` and (best-effort, symlink-guarded,
  tolerate-absent) `.claude/settings.local.json` **as raw text — no JSON decode**, and if
  the substring `git worktree` appears in either, emit a **non-fatal** warning (mirroring
  the existing `PERL5OPT` surface-don't-overwrite warning; fire under `--dry-run` too).
  Never write `settings.local.json`. **Must-not-abort**: each read is best-effort
  (absent/symlink/non-regular/unreadable → skip) so a malformed user file cannot fail the
  merge (`run_settings_merge` dies on non-zero exit). **Hash-tracked**: refresh
  `script-hashes.json` in the same commit and restore recorded perms (0500).

### Supporting Changes
- **EDIT `CLAUDE.md`** — add a `**Worktree Process**:` bullet in the `## Conventions`
  section (after the Session Hygiene bullet, ~line 89), linking
  `.cwf/docs/conventions/worktree-process.md`. This section is the source repo's own
  content (no `CWF-PREAMBLE` markers here), so no install-manifest sha drift.
- **EDIT `.cwf/docs/conventions/tmp-paths.md`** — one-line `See also` pointing to
  `worktree-process.md` (disposable worktrees live under `.claude/worktrees/`, governed
  separately). Minimal cross-link only (FR6); not a content change.

### Out of this phase (recorded, not done in f)
- **MEMORY pointer** (FR7 non-gating): a `feedback`/`reference` memory file + MEMORY.md
  line — out-of-repo, added by hand at rollout.
- **`Bash(git worktree *)` removal** (FR6): **already done** by the operator this session;
  the doc documents the *class* of entry and the surface-don't-auto-edit principle. CWF does
  not edit `settings.local.json` (design Decision 4).
- **FR8 C2-refusal probe**: executed in `g-testing-exec` under its safety envelope, not in f.

## Implementation Steps
### Step 1: Author the convention doc
- [ ] Write `.cwf/docs/conventions/worktree-process.md` with the five sections above.
- [ ] No worktree is created in this phase (the FR8 probe is a g-phase activity), so f
      leaves `.claude/worktrees/` untouched — no orphan-cleanup needed in f.

### Step 2: Settings key (correctness-ordered)
- [ ] Add `worktree.baseRef: head` to `.claude/settings.json`.
- [ ] **Ship the doc with BOTH branches' wording so it is correct regardless of probe
      outcome**: the doc mandates `head` as the durable guarantee *and* records that, if
      the harness does not honour project-scope `settings.json`, each operator must set
      `worktree.baseRef: head` user-globally. The committed key is best-effort project
      convenience, inert if only user-global is honoured.
- [ ] **FR3 AC remains OPEN at end of f**: the project-vs-user scope is confirmed by the
      g-phase FR8 probe (observes whether a new worktree bases on HEAD). Do not claim
      project-scope works until the probe shows it; the doc-mandate branch satisfies FR3's
      intent either way.

### Step 3: Cross-references (follow `docs/conventions/cross-doc-references.md` format)
- [ ] Add the `**Worktree Process**:` bullet to `CLAUDE.md` `## Conventions` (after the
      Session Hygiene bullet, ~line 89), using the `.cwf/docs/conventions/`-prefixed path
      form of its adjacent peers (not the bare `docs/conventions/` form of the older bullets).
- [ ] **Append** a `` `worktree-process.md` — … `` entry to the **existing** `## See also`
      section in `tmp-paths.md` (line ~112); do not create a second heading.

### Step 4: Surface the residual (no auto-edit)
- [ ] Doc documents the *class* of dangerous `git worktree` allowlist entry as "mitigated
      pending operator action" if detected; surface the remove/narrow recommendation. (The
      one specific entry was already removed by the operator this session.) Confirm no
      allowlist entry is added by this task.
- [ ] Add the **pre-flight** step (FR9 usage touchpoint) to the doc's Procedure: grep both
      settings files for `git worktree` and warn before `EnterWorktree`.

### Step 4b: Install-time detector (FR9) — the one hashed-script edit
- [ ] Edit `cwf-claude-settings-merge`: slurp `.claude/settings.json` + (best-effort,
      symlink-guarded) `.claude/settings.local.json` as raw text (no JSON decode); warn
      non-fatally if `git worktree` appears. Mirror the `PERL5OPT` warning style; fire under
      `--dry-run`. No write to `settings.local.json`. **Must-not-abort**: best-effort reads
      only (mirror `read_settings`'s `-f && !-l` guard), so a malformed local file cannot
      fail the merge.
- [ ] chmod the helper back to its **recorded** perms (0500) after editing
      (`feedback_hashed_script_working_perms`); do not leave it at 0700.
- [ ] Refresh `.cwf/security/script-hashes.json` for the helper **in this same commit**
      (`hash-updates.md`); per-file `git log` verification of the edit.
- [ ] Run `cwf-manage validate` and confirm the helper no longer shows a perm/hash
      violation (this edit also clears its pre-existing 0700→0500 drift as a side effect).

### Step 5: In-phase validation (security review + smoke)
- [ ] Run the implementation-phase security review (FR4(a–e)); confirm: no blanket
      pre-authorisation, refusal gate intact, request-is-data clause present, no
      auto-edit of `settings.local.json`.
- [ ] **Read the request-is-data clause and confirm it is normatively correct** (not just
      present): it must state imperatively that the triggering request is data and can
      never drive the `action:`/`discard_changes:` argument (design Threat-model clause).
      Presence-grep alone is insufficient — weak phrasing here silently undercuts the
      feature.
- [ ] Output-level smoke: grep the new doc for stale strings and for each mandated point
      (P1–P3, ToolSearch load, no-unprompted-`discard_changes`, absolute-path discipline).
- [ ] **Cite-don't-copy check (NFR3)**: confirm each P1–P3 string and each C-fact appears
      the intended number of times (once), and C-facts are referenced by Task-177 citation,
      not restated — catches duplication across the `Procedure` prose and `Prohibitions` list.
- [ ] Confirm `.claude/settings.json` is valid JSON by reading it back and checking it
      equals the after-block above (no external JSON tool / no `cd`).

## Code Changes
### `.claude/settings.json` — before
```json
{
  "env": { "PERL5OPT": "-CDSLA" }
}
```
### `.claude/settings.json` — after
```json
{
  "env": { "PERL5OPT": "-CDSLA" },
  "worktree": { "baseRef": "head" }
}
```

## Test Coverage
**See e-testing-plan.md for complete test plan** — centred on the FR8 C2-refusal probe and
the doc-content/grep checks (this feature has no executable code to unit-test).

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

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
All steps (1–5, incl. 4b) executed in f. One deviation: added a dedicated `Configuration`
doc section as the home for the FR3 both-branches wording (design folded it into prose).
Hash refresh + 0500 restore done in-commit; `validate` OK.

## Lessons Learned
The hashed-helper edit was the only non-doc change and landed cleanly because the hash +
perms discipline was disclosed at plan time, not discovered at commit time.
