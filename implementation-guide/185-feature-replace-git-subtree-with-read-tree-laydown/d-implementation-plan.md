# Replace git-subtree with read-tree laydown - Implementation Plan
**Task**: 185 (feature)

## Task Reference
- **Task ID**: internal-185
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/185-replace-git-subtree-with-read-tree-laydown
- **Template Version**: 2.1

## Goal
Implement the merge-free read-tree laydown, subtree deprecation + migrate-on-update, and
the read-only merge-commit detection surface, per c-design-plan.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `scripts/install.bash` (outside `.cwf/`, NOT hash-tracked):
  - Hoist the source→dest pair list (`.cwf:.cwf`, `.claude/skills:.cwf-skills`,
    `.claude/rules:.cwf-rules`, `.claude/agents:.cwf-agents`) to a file-level `readonly`
    array; have the symlink guard, `install_copy`, and `install_read_tree` all iterate it.
  - Add `install_read_tree()` (see Code Changes).
  - Flip default `CWF_METHOD` (`:22`) `subtree`→`read-tree`.
  - Method validation (`:77-79`): accept `read-tree|copy`; **refuse `subtree`** with
    guidance (read-tree primary / copy fallback / reason: forces merge commits).
  - Remove the subtree-only "requires ≥1 commit" guard (`:64-69`) — read-tree leaves a
    staged laydown the user commits, so no pre-existing HEAD is required.
  - Remove `install_subtree()` (`:159-209`); dispatch `case` (`:313-316`): drop
    `subtree)`, add `read-tree)`.
- `.cwf/scripts/cwf-manage` (hash-tracked):
  - `cmd_update`: method check (`:483-484`) accept `read-tree`; when recorded method is
    `subtree`, set laydown method to `read-tree` **before** the `local %ENV` build
    (`:493-498`); **add** `$v{cwf_method} = $laydown_method` to the version-write block
    (`:521-526`); after a subtree→read-tree migration, invoke `cwf-detect-merges` to warn.
    Resolve the helper via the same `"$git_root/.cwf/scripts/command-helpers/<name>"`
    idiom as `run_apply_artefacts` (`:312`), but **ignore its rc** (the helper always
    exits 0; defence-in-depth — a detection bug must never abort a good migration). No
    `-x` tolerance branch (the helper ships in the same release).
  - Add `cmd_check_merges` (one-line delegate to `cwf-detect-merges`, same path idiom);
    register `check-merges` in `%dispatch` (`:846`) and add one line to the `cmd_help`
    Commands block (`:810-818`).
- `.cwf/scripts/command-helpers/cwf-detect-merges` (NEW, hash-tracked, exec 0500): see
  Code Changes.

### Supporting Changes
- `.cwf/security/script-hashes.json`: refresh `cwf-manage` (modified) + add
  `cwf-detect-merges` (new) — **same commit** as the edits (hash-updates convention);
  record `cwf-detect-merges` perms as `0500`.
- `INSTALL.md`: rewrite the method section — read-tree primary, copy fallback, subtree
  deprecated; remove the "all three … first-class" line (`:102`) and the subtree-as-
  primary framing.
- Deprecation note per `docs/conventions/design-alignment.md` (in-repo deprecation entry
  for `subtree`).
- Tests under `t/` — enumerated in e-testing-plan.

## Implementation Steps
### Step 1: install.bash — shared pair list + install_read_tree
- [ ] Hoist the four source→dest pairs to a file-level `readonly` array; refactor
      `install_copy` and the guard call to iterate it.
- [ ] Add `install_read_tree()`: guard → `git fetch --no-tags "$clone_dir" "$ref"` →
      clear all four prefixes (`git rm -r --cached --ignore-unmatch` + worktree `rm -rf`) →
      `read-tree --prefix` all four → materialise only the four prefixes (NOT `-a`).
      Fail-closed `die` on any step.

### Step 2: install.bash — dispatch, default, deprecation
- [ ] Flip default to `read-tree`; add `read-tree)` arm; remove `subtree)` + `install_subtree`.
- [ ] Method validation refuses `subtree` with the guidance message.
- [ ] Remove the subtree-only ≥1-commit guard.

### Step 3: cwf-detect-merges (new helper)
- [ ] Read-only Perl/core-only; NUL-safe git read (see Code Changes); classify CWF
      subset (subject + subtree marker), under-claim on ambiguity; counts-only output;
      `exit 0` always.

### Step 4: cwf-manage — migration + subcommand
- [ ] `cmd_update`: accept `read-tree`; translate `subtree`→`read-tree`; add `cwf_method`
      to version write; post-migration `cwf-detect-merges` warning.
- [ ] Add `cmd_check_merges` + `%dispatch` + `cmd_help` entries.

### Step 5: integrity + docs
- [ ] Refresh `script-hashes.json` (cwf-manage + new helper, perms 0500) in the same commit.
- [ ] Update INSTALL.md; add the design-alignment deprecation entry.

### Step 6: tests + validation
- [ ] Implement tests per e-testing-plan; run full `t/` suite (`prove`); `cwf-manage
      validate` clean; fresh-install + subtree-fixture migration smoke per a-plan ACs.

## Code Changes
### install.bash — method validation (before → after)
```bash
# before (:77-79)
if [[ "$CWF_METHOD" != "subtree" && "$CWF_METHOD" != "copy" ]]; then
    die "Invalid CWF_METHOD: $CWF_METHOD (must be 'subtree' or 'copy')"
fi
# after
if [[ "$CWF_METHOD" == "subtree" ]]; then
    die "CWF_METHOD=subtree is deprecated: it forces merge commits into your history. Use 'read-tree' (default) or 'copy' if read-tree cannot run."
elif [[ "$CWF_METHOD" != "read-tree" && "$CWF_METHOD" != "copy" ]]; then
    die "Invalid CWF_METHOD: $CWF_METHOD (must be 'read-tree' or 'copy')"
fi
```

### install.bash — install_read_tree (sketch; critical primitive)
Notes pinning the fail-closed contract (mirror `install_copy` exactly, install.bash:226-237):
- `CWF_PAIRS` elements hold **bare** source subpaths (`.claude/skills:.cwf-skills`); copy
  and the guard prefix `$clone_dir/`, read-tree uses the bare form for `FETCH_HEAD:$src`.
- Build `roots` by filtering `CWF_PAIRS` sources through `[[ -d "$clone_dir/$src" ]]`
  (present-dir filter) — same as `install_copy`; do NOT pass dest prefixes to the guard.
- Keep `install_copy`'s `-x` guard-exists die; do not rewrite `install_copy` beyond
  switching it to read `CWF_PAIRS` (preserve its present-dir filter so already-tested
  behaviour does not regress).
```bash
install_read_tree() {
    local clone_dir="$1" ref="$2" p src dest tree
    local guard="$clone_dir/.cwf/scripts/command-helpers/cwf-check-tree-symlinks"
    local -a roots=()
    for p in "${CWF_PAIRS[@]}"; do src="$clone_dir/${p%%:*}"; [[ -d "$src" ]] && roots+=("$src"); done
    # 1. fail-closed symlink guard (guard-exists -x check then invoke) — as install_copy
    [[ -x "$guard" ]] || die "symlink-escape guard missing from source tree ($guard); cannot safely install"
    "$guard" "${roots[@]}" || die "refusing to install: source tree contains an out-of-tree symlink"
    # 2. source objects into the consumer object store (local clone; no network)
    git fetch --no-tags "$clone_dir" "$ref" >/dev/null || die "git fetch from clone failed"
    # 3. clear all four prefixes first (index + worktree), unconditional + idempotent;
    #    fail-closed (&&) so a partial clear cannot silently precede read-tree
    for p in "${CWF_PAIRS[@]}"; do dest="${p##*:}"
        git rm -r --cached --quiet --ignore-unmatch -- "$dest" >/dev/null \
            && rm -rf -- "$dest" || die "failed to clear prefix $dest before laydown"
    done
    # 4. read all four (index only; refuses overlay — prefixes are now clear).
    #    Use the FETCHED object only; never re-resolve $ref to a moving tip after fetch.
    for p in "${CWF_PAIRS[@]}"; do src="${p%%:*}"; dest="${p##*:}"
        tree="$(git rev-parse "FETCH_HEAD:$src")" || die "no source subtree $src"
        git read-tree --prefix="$dest/" "$tree" || die "read-tree failed for $dest"
    done
    # 5. materialise ONLY the four prefixes, NUL-safe (no shell word-split/glob)
    git ls-files -z -- .cwf .cwf-skills .cwf-rules .cwf-agents \
        | git checkout-index -f -z --stdin || die "checkout-index materialise failed"
}
```

### cwf-detect-merges — NUL-safe enumeration (pins the FR4(b) contract)
```
# merge SHAs are hex (newline-split safe); per-commit fields read NUL/US-separated:
git log --merges -z \
    --format='%H%x1f%s%x1f%P%x1f%(trailers:key=git-subtree-dir,valueonly)' HEAD
# split records on \0, fields on \x1f. Subject (%s) is single-line by definition.
# CWF subset iff subject =~ /^Add CWF (core|skills|rules|agents) / AND
#   ( git-subtree-dir trailer present  OR  second parent's subject =~ /^Squashed '.*' content/ ).
# Ambiguous (subject only) -> total, NOT subset. Classified strings are display-only,
# never reused as command args. Output counts only; exit 0 always.
```

## Test Coverage
**See e-testing-plan.md for complete test plan** (read-tree laydown merge-free + tree
equivalence; subtree refusal; subtree-fixture migration incl. negative/fail-closed;
reinstall determinism; symlink-escape refusal; detection total/subset/under-claim;
`validate` clean). The testing plan MUST also realise the two failure modes surfaced in
plan review: (a) a clear-step / mid-laydown failure leaves a recoverable state and re-run
is idempotent; (b) a `cwf-detect-merges` failure during migration does not abort the
migration.

## Validation Criteria
**See e-testing-plan.md.** Gate: full `t/` suite green, `cwf-manage validate` clean, and
the a-plan ACs (AC1–AC10) demonstrated.

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
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
