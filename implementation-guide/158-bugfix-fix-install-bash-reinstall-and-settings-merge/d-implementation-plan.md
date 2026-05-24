# Fix install.bash reinstall and settings-merge - Implementation Plan
**Task**: 158 (bugfix)

## Task Reference
- **Task ID**: internal-158
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/158-fix-install-bash-reinstall-and-settings-merge
- **Template Version**: 2.1

## Goal
Implement the three fixes per c-design-plan.md, mirroring `cwf-manage`'s
completion-step precedent. **Scope is Option B (settings-only)** — the
apply-artefacts parity option was investigated and rejected during plan review
(`.cwf/rules-inject.txt` ships populated in the subtree, so there is no
breakage, and a naive apply-artefacts call would *empty* it; see c-design-plan
Resolved Decision). install.bash gains **no** apply-artefacts call.

## Workflow
Test harness first → minimal edit → run suite green → commit explains "why".

## Files to Modify
### Primary Changes
- `scripts/install.bash` — item 1 (force-reinstall commit, `install_subtree` ~177-188); item 2 (settings-merge in `post_install` ~246-265).
- `.cwf/docs/skills/security-review.md` — item 3 (insert `.claude/agents/` into the §Pathspec coverage item-(1) prose sentence, line 32).

### Supporting Changes
- `t/install-bash-*.t` (new) — end-to-end coverage reusing the Task-155 fixture-server pattern from `t/cwf-manage-update-end-to-end.t`. (Exact file name + structure in e-testing-plan.md.)

### Not modified
- No `.cwf/security/script-hashes.json` refresh — neither file is hash-tracked (verified in planning).
- `cwf-claude-settings-merge`, `cwf-apply-artefacts` reused unchanged.

## Implementation Steps

### Step 1: Setup + harness first
- [ ] Re-read c-design-plan.md Decisions 1–3 and the Open Decision; confirm the A/B scope decision recorded from plan review before editing
- [ ] Read `t/cwf-manage-update-end-to-end.t` to reuse its fixture-server + scratch-repo helpers
- [ ] Add the failing/red end-to-end test(s) first (per e-testing-plan.md): a `CWF_FORCE` reinstall whose pre-state lacks `.cwf-agents`, asserting clean completion

### Step 2: Item 1 — force-reinstall commit (`install_subtree`, ~177-188)
- [ ] Edit **only** the loop body + commit *inside* the existing `if [[ "$CWF_FORCE" == "1" ]]` guard (line 176 stays; do not re-nest it)
- [ ] Replace the hardcoded-pathspec block with the array form:
  ```bash
  local -a removed=()
  for dir in .cwf .cwf-skills .cwf-rules .cwf-agents; do
      [[ -d "$dir" ]] || continue
      if git rm -rf --quiet "$dir"; then
          removed+=("$dir")
      elif git ls-files --error-unmatch "$dir" >/dev/null 2>&1; then
          die "git rm failed for tracked $dir"
      fi
      rm -rf "$dir"
  done
  if (( ${#removed[@]} > 0 )); then
      git commit -m "CWF: remove existing install for reinstall" --quiet -- "${removed[@]}" \
          || die "failed to commit removal of existing CWF install"
  fi
  ```
- [ ] Rewrite the stale comment (185-186) to state the real invariant (commit only the dirs actually removed; non-matching pathspec was the bug)
- [ ] **set -e notes** (script is `set -euo pipefail`, line 18): `git rm`/`git ls-files` sit in `if`/`elif` conditions (set -e suppressed there) — safe. `(( ${#removed[@]} > 0 ))` is used as an `if` condition, so an empty-array `0` result does NOT abort (it would if used as a bare statement). The explicit `|| die` on `git commit` gives a clean message instead of a bare set -e abort.

### Step 3: Item 2 — settings-merge in post_install (~246-265)
- [ ] Insert, in `post_install` **after** the `create_cwf_symlinks` calls (253) and **before** the `.cwf/version` write (256), mirroring `cwf-manage` ordering:
  ```bash
  local merge_helper=".cwf/scripts/command-helpers/cwf-claude-settings-merge"
  if [[ -x "$merge_helper" ]]; then
      "$merge_helper" || die "cwf-claude-settings-merge failed; .claude/settings.json may be partial"
  fi
  ```
- [ ] `-x` guard mirrors `run_settings_merge`'s `return unless -x $helper` (tolerates pre-helper installs); the `|| die` (with set -e) aborts before the version write on failure
- [ ] Helper executability is **already covered** under both methods — no extra edit: subtree lays down recorded perms; `install_copy` already runs `find .cwf/scripts -type f -exec chmod u+rx` (line 240), which recurses into `command-helpers/`. Confirm at exec, add nothing.

### Step 4: Item 3 — doc fix
- [ ] Edit `.cwf/docs/skills/security-review.md` §Pathspec coverage item (1) — line 32 is a single inline prose sentence enumerating prefixes, **not** a one-per-line list. Insert `.claude/agents/` between `.claude/skills/` and `.claude/hooks/` (preserving the helper's ordering in `security-review-changeset:56-66`). The validation test is "doc enumeration matches the helper's `@CWF_INTERNAL_PREFIXES`". No other change.

### Step 5: Run the suite + manual verification
- [ ] Run the new end-to-end test(s) + the full Perl suite + `cwf-manage validate`
- [ ] Manual: a scratch `CWF_FORCE` reinstall missing `.cwf-agents` completes cleanly; `.claude/settings.json` has PERL5OPT + allowlist after the install
- [ ] Sanity: confirm `.cwf/rules-inject.txt` remains populated after the reinstall (it ships in the subtree; this just guards against accidental regression)

## Code Changes
Concrete diffs are in Steps 2–4 above; final exact text produced at exec time
against the live file (line numbers may shift by ±a few).

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all four steps (items 1–3 + verification) before marking
Finished. Scope is settled (Option B). If, during the optional residual review,
the minor `.gitignore`/CLAUDE.md migration-drift is judged worth addressing, file
it as a *separate* follow-up (and note the `cwf-apply-artefacts` empties-rules-inject
oddity) rather than expanding this task.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None — scope resolved to Option B

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Steps 1–5 executed; the d-plan bash snippets shipped essentially unchanged. No
`script-hashes.json` refresh (neither file hash-tracked), as planned.

## Lessons Learned
The Step-2 set-e reasoning held in practice: `git rm`/`git ls-files` in if/elif
conditions are suppressed under `set -e`; the explicit `|| die` on the commit
gives a clean message instead of a bare abort.
