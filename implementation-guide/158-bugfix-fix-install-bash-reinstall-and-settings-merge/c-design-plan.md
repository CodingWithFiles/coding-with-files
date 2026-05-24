# Fix install.bash reinstall and settings-merge - Design
**Task**: 158 (bugfix)

## Task Reference
- **Task ID**: internal-158
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/158-fix-install-bash-reinstall-and-settings-merge
- **Template Version**: 2.1

## Goal
Define how to fix the install.bash force-reinstall commit bug (item 1) and the
settings-merge gap (item 2), and the security-review.md doc omission (item 3),
and settle the one open scope question (apply-artefacts parity).

## Design Priorities
Correctness → Testability → Consistency → Simplicity → Reversibility

For a bugfix the priority is a correct, minimal change that mirrors the existing
working precedent (`cwf-manage`'s post-laydown steps) rather than introducing a
new mechanism.

## Key Decisions

### Decision 1 — Item 1: commit only the dirs actually removed
- **Decision**: The edit is **scoped to `install.bash:177-188`** — the `for` loop body and the commit — *inside* the existing `if [[ "$CWF_FORCE" == "1" ]]` guard at line 176 (do not re-add that guard). Accumulate the dirs that `git rm` actually staged into an array and pass *only that array* as the commit pathspec; skip the commit when the array is empty. Illustrative (final form in d-plan):
  ```bash
  # (inside the existing CWF_FORCE guard at :176)
  local -a removed=()
  for dir in .cwf .cwf-skills .cwf-rules .cwf-agents; do
      [[ -d "$dir" ]] || continue
      if git rm -rf --quiet "$dir"; then
          removed+=("$dir")          # tracked dir, deletion staged
      elif git ls-files --error-unmatch "$dir" >/dev/null 2>&1; then
          die "git rm failed for tracked $dir"   # tracked but rm failed -> abort
      fi
      rm -rf "$dir"                  # untracked copy dir: clean the worktree
  done
  if (( ${#removed[@]} > 0 )); then
      git commit -m "CWF: remove existing install for reinstall" \
          --quiet -- "${removed[@]}"
  fi
  ```
- **Rationale**: The bug is that a pathspec naming a never-tracked path (`.cwf-agents` on a pre-agents copy install) makes `git commit` fail wholesale, leaving the *other* staged deletions in the index, which then breaks `git subtree add`. Committing only the dirs actually staged for deletion guarantees a clean index. **Robustness refinement (reviewer):** `git rm` failing must be split into two cases — an *untracked* dir (expected; skip and `rm -rf` the worktree copy) vs. a *tracked* dir whose `git rm` failed for some other reason (must `die`, not silently `rm -rf` and leave a dangling index entry — that would reproduce the very dirty-index class being fixed). Removing `--allow-empty` and the blanket `|| true` is deliberate: the old swallow is what hid this bug. (`die` is install.bash's existing error helper — confirm its name in d-plan.)
- **Trade-offs**: A few more lines than the one-line hardcoded pathspec, and a tracked-but-unremovable dir now aborts rather than limping on. Both are correct for a Correctness-first bugfix. The code comment (185-186) is rewritten to describe the actual invariant.

### Decision 2 — Item 2: post_install invokes cwf-claude-settings-merge
- **Decision**: Invoke the just-laid-down `.cwf/scripts/command-helpers/cwf-claude-settings-merge` from `post_install`, mirroring `cwf-manage`'s `run_settings_merge` (`.cwf/scripts/cwf-manage:273-282`). Mirror its **`-x` guard** too (`return unless -x $helper` → in bash, `if [[ -x "$helper" ]]; then ...`): a missing/non-executable helper is tolerated, not a hard install abort. When present, a non-zero exit **aborts the install before the `.cwf/version` write** (see ordering below) — do not claim success on a partial merge.
- **Placement / ordering (reviewer)**: `post_install` currently does symlinks then writes `.cwf/version` (`scripts/install.bash:251-263`). The completion call(s) must run **after the symlinks and before the version write**, mirroring `cwf-manage`'s "aborting before version-file update" ordering (`.cwf/scripts/cwf-manage:464-468`). An aborted install must never record a version it did not fully reach.
- **Both install methods (reviewer)**: `post_install` runs for *both* `subtree` and `copy` (`scripts/install.bash:289-295`), so this call covers the copy method too — no separate change needed there. Confirm in d-plan that the helper lands executable under both methods (subtree laydown vs. `install_copy`'s `chmod u+rx` over `.cwf/scripts`, line 240).
- **Rationale**: install.bash is laydown-only; completion is normally the *caller*'s job — `/cwf-init` (SKILL.md 6d) for fresh installs, `cwf-manage update` for updates. The consumer's raw `CWF_FORCE=1 bash install.bash` migration (the documented Task-155 bootstrap-recovery path) has no completion caller, so new-version PERL5OPT/allowlist entries never merge. The helper is **idempotent** (header line 31; PERL5OPT add-if-absent, allowlist union/dedup), so redundant runs via `/cwf-init` or `cwf-manage update` are harmless.
- **Trust boundary (security reviewer)**: this executes a freshly-laid-down Perl helper that mutates the tool-call env (`env.PERL5OPT`). This is **not new surface** — it is the same laid-down-then-executed pattern `cwf-manage` already uses (`run_settings_merge`), and the helper hardcodes `PERL5OPT=-CDSLA` as a compile-time constant (`cwf-claude-settings-merge:171-175`), refusing any external value. Trust posture unchanged.
- **Trade-offs**: A fresh-install user who then runs `/cwf-init` triggers a second, idempotent merge — a no-op cost for a self-sufficient installer. Accepted.

### Decision 3 — Item 3: add `.claude/agents/` to the doc enumeration
- **Decision**: Edit `.cwf/docs/skills/security-review.md` §"Pathspec coverage" item (1) to add `.claude/agents/` to the listed CWF-internal prefixes, matching the helper.
- **Rationale**: The helper `security-review-changeset` already includes `.claude/agents/` (`:63`); the doc's enumeration is simply stale (agents were added in Task 143). The helper is the single source of truth and is correct; only the prose drifted. Pure doc accuracy — no code or behaviour change.
- **Trade-offs**: None. security-review.md is not hash-tracked, so no refresh.

### Resolved Decision — apply-artefacts parity REJECTED; settings-only (Option B)
- **History**: An earlier draft recommended Option A (install.bash also calls `cwf-apply-artefacts`), on the premise that a `CWF_FORCE` reinstall leaves `.cwf/rules-inject.txt` empty and silently breaks the PreToolUse rule-injection hook. The d-plan robustness review challenged this; **direct verification refuted it**:
  - `.cwf/rules-inject.txt` (the file the hook consumes) is tracked **inside `.cwf/`** — blob `61c9507`, 331 bytes, **populated** with the actual CWF rules. The empty blob (`e69de29`) is only the *template* at `.cwf/templates/install/rules-inject.txt`, a different file. The earlier "evidence" confused template with dest.
  - `install_subtree` lays down `.cwf/` via `subtree split --prefix=.cwf` (`scripts/install.bash:170`), so a reinstall lays down the **populated** `.cwf/rules-inject.txt` directly. **No breakage.**
  - Worse: the proposed Option A call (`cwf-apply-artefacts … --bootstrap-init`) would, per the manifest (`install-manifest.json:16-21`: `rules-inject` → `strategy: replace`, `source:` the empty template, `sha256: e3b0c44…` = SHA of zero bytes), copy the **empty template over** the populated dest — *causing* the very emptiness it claimed to prevent. Option A is not just unnecessary, it is harmful.
- **Decision**: **Option B — fix items 1–3 only; do not add an apply-artefacts call to install.bash.** Item 2 (settings-merge) is the real migration gap because `.claude/settings.json` lives at repo root (not in the subtree) and accrues new allowlist/PERL5OPT entries on upgrade that must be re-merged. The other apply-artefacts outputs do not need install.bash to act: `.cwf/rules-inject.txt` ships populated in the subtree; `.claude/rules` symlinks are already created inline by `post_install` (`:252`); `.gitignore`/CLAUDE.md preamble persist from the prior install across a migration.
- **Residual (out of scope, optional follow-up)**: a migration via raw `CWF_FORCE bash install.bash` would not pick up *new-version* `.gitignore`/CLAUDE.md-preamble additions (root-level, not in the subtree, no completion caller). This is minor drift, not breakage, and the consumer did not report it. A follow-up could address it — but **not** by a naive `cwf-apply-artefacts` call, which currently empties `rules-inject.txt` (a separate latent oddity worth its own investigation). Filed as a note, not bundled.
- **Lesson**: three reviewers confirmed an empty-blob fact and misattributed it (template vs. consumed dest); one careful reviewer + direct `git ls-files -s` checking caught it. Verify which file a hook actually reads before asserting a breakage.

## System Design

### Components touched (all existing)
- **`scripts/install.bash`** — `install_subtree` removal block (item 1); `post_install` (item 2, and item-A apply-artefacts if chosen).
- **`.cwf/docs/skills/security-review.md`** — §Pathspec coverage prose (item 3).
- **Existing helpers reused unchanged**: `cwf-claude-settings-merge`, `cwf-apply-artefacts` (option A).

### Data Flow (corrected reinstall path, item 1)
1. `CWF_FORCE=1` → for each existing CWF dir: `git rm` (record if staged; abort if a *tracked* dir fails) + `rm -rf`.
2. Commit only the recorded (tracked-and-removed) dirs → clean index.
3. `git subtree add` each prefix against the now-clean index → succeeds.

Note (reviewer): Decision 1 is **subtree-only** — `install_copy`'s force block (`scripts/install.bash:216`) is a plain `rm -rf` with no git operations, so it is unaffected. Decision 2 (and Option A) live in `post_install`, which runs for **both** methods (`:289-295`), so the completion calls cover copy installs as well.

## Interface Design
- **No new interfaces.** install.bash invokes existing helpers by their laid-down path (`.cwf/scripts/command-helpers/<helper>`), exactly as `cwf-manage` does.

## Constraints
- Neither in-scope file is hash-tracked → no `script-hashes.json` refresh (verified during planning).
- Mirror the `cwf-manage` precedent rather than inventing a new completion mechanism (Consistency).
- Test coverage reuses the Task-155 `t/cwf-manage-update-end-to-end.t` fixture-server pattern; do not build new harness scaffolding.

## Decomposition Check
- [ ] **Time**: >1 week? No
- [ ] **People**: >2 people? No
- [ ] **Complexity**: 3+ distinct concerns? Two install.bash fixes + a doc edit; cohesive. No
- [ ] **Risk**: High-risk isolation needed? No
- [ ] **Independence**: Separable? Doc fix is independent but trivial. No

No decomposition.

## Validation
- [ ] Item 1: a `CWF_FORCE` reinstall with a CWF dir absent in the pre-state produces a clean index and all subtree adds succeed
- [ ] Item 1 (failure path): a *tracked* dir whose `git rm` fails aborts the install rather than limping on with a dirty index
- [ ] Item 2: settings-merge call mirrors cwf-manage (`-x` guard; runs before the `.cwf/version` write)
- [ ] Item 2 (failure path): when the merge helper exits non-zero, the install aborts and `.cwf/version` is **not** written / success is **not** reported
- [ ] Item 3: doc enumeration matches the helper's `@CWF_INTERNAL_PREFIXES`
- [ ] apply-artefacts parity REJECTED (Option B): install.bash gains no apply-artefacts call; `.cwf/rules-inject.txt` verified to ship populated in the subtree (a reinstall does not empty it)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None — apply-artefacts parity resolved (rejected; Option B) during d-plan review

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Decisions 1–3 implemented as designed. The Resolved Decision (Option B) held
through exec — no apply-artefacts call was added to install.bash.

## Lessons Learned
Verifying which file the rule-injection hook actually consumes (`.cwf/rules-inject.txt`,
shipped populated in the subtree) versus the empty *template* was decisive: the
rejected Option A would have copied the empty template over the populated dest.
