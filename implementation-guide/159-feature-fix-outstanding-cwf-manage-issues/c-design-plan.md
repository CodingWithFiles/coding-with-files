# fix outstanding cwf-manage issues - Design
**Task**: 159 (feature)

## Task Reference
- **Task ID**: internal-159
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/159-fix-outstanding-cwf-manage-issues
- **Template Version**: 2.1

## Goal
Define the design for the four cwf-manage fixes (FR1-FR4) plus the cross-cutting integrity refresh (FR5). Each FR is independent; each lands in its own phase/commit.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility. Per project tradeoff order: correctness > maintainability > performance; reuse over duplication.

## Decision D1 — FR1: derive `cwf_version` from the resolved SHA; preserve requested ref in `cwf_ref`
- **Conceptual model (maintainer-confirmed)**: tags are the human-blessed release points (tagging is a deliberate post-review human action). It follows that `cwf_version` should **always be tag-derived** — the semver that describes the installed SHA — while `cwf_ref` records *intent* (`latest`/branch/SHA). `latest` therefore means "the highest semver tag" (the existing `resolve_ref` behaviour, `:162-172`, preserved), and `cwf_version` is never a bare ref.
- **Where**: `cmd_update` (`.cwf/scripts/cwf-manage:375-485`). The fix is confined to the authoritative version-file write block (`:477-482`).
- **Inputs already in scope**: `$ref` (`:376-377`, the originally-requested ref, defaulted to `latest`); `$resolved` (`:413`, semver for `latest`, verbatim ref otherwise); `$sha` (`:414`, the resolved 40-char SHA); `$clone_dir` (`:407`, a normal clone — `git clone` of a URL fetches tags, so tags are present in the normal case; the tags-absent case degrades, see below).
- **Decision**:
  - Add a helper `git_describe_version($clone_dir, $sha)` that calls the **shared `git_capture` helper from D4** (not a raw `git -C`) with `('-C', $clone_dir, 'describe', '--tags', '--always', $sha)`, so it gets the audited capture + exit-code path:
    - SHA exactly on a version tag → `v1.1.155` (satisfies AC1).
    - SHA not on a tag → long form `v1.1.155-3-gabcdef` (nearest-ancestor tag; satisfies AC2 untagged case — a meaningful semver lineage, consistent with the tags-are-authoritative model).
    - No tags reachable → `--always` yields the abbreviated SHA (a commit identifier, never a branch name or `HEAD`).
    - **`describe` exits non-zero** (garbage `$sha`, corrupt clone): fall back to `$sha` (the resolved 40-char SHA), which keeps "never a bare ref / never empty" true and never crashes the update (NFR5). The version-file field must never be written empty.
  - `:477` `cwf_version` ← `git_describe_version($clone_dir, $sha)` (was `$resolved`).
  - `:478` `cwf_ref` ← `$ref` (was `$resolved`) — the original request (`latest`/`HEAD`/branch/SHA) is preserved.
- **Why describe over "use `$resolved` when it's a tag"**: uniform. For `latest`, `$sha` sits on the tag so `describe` returns that exact tag — same result, one code path, no special-casing.
- **Tradeoff**: one extra `git` call per update (negligible, NFR1). The degrade chain (exact tag → long form → SHA) is always strictly better than recording a bare ref.
- **Knock-on (per requirements)**: `cmd_list_releases:305` reads `cwf_version` to flag the `(installed)` release. After D1 it keys off a real semver, so for tagged installs the marker now correctly matches a `v*` tag. Verify no regression in `t/cwf-manage-list-releases.t` (AC10).

## Decision D2 — FR2: thread a `dry_run` flag through `_apply_recorded_perms`
- **Where**: `cmd_fix_security` (`:861`), `_apply_recorded_perms` (`:782`), dispatch (`:954`).
- **Decision**:
  - Add a `$dry_run` parameter (default false) to `_apply_recorded_perms($git_root, $data, $mode, $dry_run)`. The two pre-`chmod` gates — existence (`:806`) and sha256-match (`:823`) — run **unchanged**, so missing-file and sha-mismatch unfixables are surfaced identically in dry-run. At the mutation point (`:842`), when `$dry_run` is true, **skip `chmod`** and record the entry into `@repaired` as a would-be repair (same data shape: `rel`/`from`/`to`). The chmod-failure unfixable branch (`:848`) is therefore unreachable in dry-run — correct, because that case is only knowable by attempting the mutation (per requirements).
  - `apply_exact_perms_or_die` (`:887`, the laydown path) keeps calling `_apply_recorded_perms(..., 'exact')` with `$dry_run` omitted (false) — **unaffected**.
  - `cmd_fix_security` parses args in this **explicit order**: (1) detect `--dry-run` via `grep { $_ eq '--dry-run' } @ARGV` (mirroring `:950`) and **remove it from `@ARGV`**; (2) any element *remaining* in `@ARGV` is unrecognised → `die_msg("fix-security: unknown argument '$arg'")` (non-zero exit). Order matters: `--dry-run` must be stripped before the leftover-check, or it would flag itself. (`fix-security --dry-run extra` → accepts `--dry-run`, rejects `extra`.) The `list-releases` precedent only *inspects* `@ARGV`; the strip-then-reject sweep is new to this sub.
  - Print repaired lines with a `[dry-run] ` prefix when dry-run; in dry-run, do **not** `exit 1` purely because would-be repairs exist (nothing failed) — but still `exit 1` if there are genuine unfixables (missing/sha-mismatch), matching the live classification of an un-repairable install.
  - **Docs (NFR2)**: update `cmd_help` text (`:919-920`) to document `--dry-run`, and the `cwf-security-check` / cwf-manage SKILL/docs surface as appropriate. `cmd_help` lives in the hash-tracked `cwf-manage`, so this is part of the same FR2 commit + hash refresh.
- **Dispatch**: `:954` becomes `sub { cmd_fix_security($git_root) }` still — arg parsing lives inside `cmd_fix_security` reading `@ARGV` (consistent with `list-releases` reading `@ARGV` in its dispatch closure). Equivalent either way; keeping it in `cmd_fix_security` co-locates the flag logic with its consumer.
- **Tradeoff**: one extra param on a shared sub vs a duplicate dry-run walk. Threading the flag reuses the single perms-walk (no duplication) and keeps the exact-mode laydown path untouched.

## Decision D3 — FR3: **DEFERRED to its own task** (maintainer decision at review gate, 2026-05-24)
**Outcome**: FR3 (copy-method convergence) is **deferred**. It remains as the existing backlog item "Converge cwf-manage copy-method update onto install.bash" (`BACKLOG.md:1242`) — it is **not** retired by Task 159. This task implements FR1, FR2, FR4 only. The analysis below is retained as the design record that motivated the deferral and pre-seeds the future task.

The convergence wants its own focused task because: the natural guard-extraction (`scripts/check-tree-symlinks`) lands outside both the hash ledger and the security-review changeset auto-include set, so the "verified guard" benefit needs extra plumbing (`@CWF_INTERNAL_PREFIXES` registration) to be real; and the convergence carries two correctness preconditions (`CWF_FORCE=1` env contract, `.cwf-rules` laydown divergence) that deserve dedicated test coverage. For a Low-priority FR bundled with three surgical fixes, deferral keeps Task 159's changeset small and ledger-clean.

---

**Problem (retained analysis)**: today the symlink-escape guard (`_escapes_src`/`_collapse_dotdot`, `cwf-manage:498-588`) protects **only** the `cwf-manage update` copy path. `install.bash install_copy` (`scripts/install.bash:211-248`) uses bare `cp -r` with no guard — so **fresh copy-method installs already have no guard today**. Converging the update path onto `install.bash` (so there is one laydown) therefore *requires* a guard in `install.bash`, or the guard is lost.

**Options considered**:

- **Option A — reimplement the guard in bash inside `install_copy`.** Rejected. Reimplementing path-canonicalisation (`..` collapsing, absolute-target detection) in bash duplicates an audited security check in a second language and is error-prone (the exact class of bug the guard exists to prevent). Violates "reuse over duplication" and "correctness first".
- **Option B — extract the guard to a standalone Perl checker that `install.bash` invokes before `cp -r`.** The existing `_escapes_src`/`_collapse_dotdot` logic moves into a small script co-located with `install.bash` (proposed: `scripts/check-tree-symlinks`). `install_copy` runs `perl "$here/check-tree-symlinks" "$clone_dir/.cwf"` (and the `.claude/skills|rules|agents` sources) and aborts non-zero before any `cp -r` if a symlink target is absolute or escapes its source root. Then `cmd_update`'s copy branch delegates to `install.bash` like the subtree branch, and the dead `cwf-manage` helpers are deleted.
  - **Required env contract (robustness)**: the copy branch must pass the **full env block** the subtree branch uses (`cwf-manage:439-444`): `CWF_FORCE=1`, `CWF_METHOD=copy`, `CWF_SOURCE=file://$clone_dir`, `CWF_REF=$sha`. `CWF_FORCE=1` is mandatory — `install.bash` aborts (exit 3) if `.cwf/` exists unless forced (`install.bash:72-75`), and during an update `.cwf/` always exists. The removal semantics shift from `update_copy`'s own `rmtree` to `install_copy`'s `CWF_FORCE` rm-rf branch (`install.bash:221-223`).
  - **Caller enumeration before deletion (Task 155 lesson, `155-feature-converge.../c-design-plan.md:142`)**: the copy branch (`:456-458`) calls **three** things — `update_copy`, `create_skill_symlinks`, `create_agent_symlinks`. Delegation must replace all three. `install.bash post_install` (`:256-259`) already creates skill/rule/agent symlinks, so those become redundant — confirm before deleting. The impl-plan must list every remaining caller of each sub marked for deletion (`update_copy`/`copy_tree`/`_escapes_src`/`_collapse_dotdot`) and verify none are reached elsewhere.
  - **Behaviour change — `.cwf-rules` (robustness)**: `update_copy` (`:566-588`) lays down only `.cwf`, `.cwf-skills`, `.cwf-agents` — **not** `.cwf-rules`. `install_copy` (`install.bash:234-237`) **does** copy `.cwf-rules`. Converging therefore changes what a copy-method update produces (gains `.cwf-rules` staging). Likely desirable (parity with fresh install + subtree), but must be confirmed against `run_apply_artefacts` (`:465`) to avoid double-handling.
  - **Benefits**: one laydown path (FR3 goal); one guard implementation, reused; closes the pre-existing fresh-install gap (fresh copy installs currently have no guard); `cmd_update` copy/subtree branches become symmetric.
  - **Costs / new surface**:
    - `install.bash` gains a Perl dependency at the copy step (Perl is already a hard project dependency).
    - Fresh copy-install gains a new failure mode (a malicious upstream symlink now aborts install — desired, but a behaviour change).
    - **Integrity-coverage gap (misalignment + security)**: `script-hashes.json` tracks **only installed `.cwf/` paths** (all 62 entries are `.cwf/`-prefixed); repo-root `scripts/` is **outside the hash ledger** — Task 155 settled this explicitly (`155-feature-converge.../c-design-plan.md:114`: "install.bash is outside the hash ledger (no refresh obligation)"). So the new `scripts/check-tree-symlinks` would **not** be integrity-verified by `cwf-manage validate` — which materially weakens the "closes the gap" benefit, since the guard script itself is unverified. Additionally it is **not** in the security-review changeset's unconditional-include prefixes (`security-review-changeset:56-66` lists `.cwf/scripts/`, `.cwf/lib/`, etc., not repo-root `scripts/`), so future edits to the guard are only re-reviewed if its shebang is recognised. Option B should therefore also register repo-root `scripts/` (or the checker) in `@CWF_INTERNAL_PREFIXES`.
- **Option C — defer FR3 back to the backlog.** FR3 is Low priority; FR1/FR2/FR4 are independent and ship regardless. The requirements pre-authorise this if the design is judged disproportionate. Option C removes: the new (unverifiable-by-ledger) guard script, the `install.bash` Perl coupling, the `@CWF_INTERNAL_PREFIXES` change, the `.cwf-rules` behaviour change, and the `CWF_FORCE`/removal-semantics handoff — i.e. all of this task's net-new code and risk.

**Recommendation**: **lean Option C (defer FR3 to its own task).** The design review converged on this from three angles: (improvements) Option B is the only disproportionate slice and adds the most moving parts for a Low-priority FR; (misalignment + security) the new guard script sits outside both the hash ledger and the changeset auto-review set, so Option B's headline benefit — a verified guard closing the fresh-install gap — is itself only partially realised without extra plumbing; (robustness) Option B carries two genuine correctness preconditions (`CWF_FORCE`, `.cwf-rules` divergence) that want their own focused task. Deferring lands FR1 (Very High), FR2, FR4 cleanly with zero new files. **This is the headline decision for the review gate — maintainer to confirm B vs C.**

## Decision D4 — FR4: convert the two backtick sites via a shared `git_capture` helper
- **Sites**: `find_git_root:67` (`git rev-parse --show-toplevel`, needs stderr suppressed in the not-in-a-repo case) and `cmd_list_releases:309` (`git ls-remote --tags "$source" 'v*'`, needs `$source` passed as a list arg, dies on non-zero).
- **Decision**: add `git_capture(@argv)` using `IPC::Open3` (core since 5.000) — spawns `git @argv` with child **stderr redirected to `/dev/null`** (no shell, so no `2>/dev/null`), captures stdout, reaps the child, and returns `(\@stdout_lines, $exit_code)`. Both sites call it:
  - `find_git_root`: `my ($out, $rc) = git_capture('rev-parse', '--show-toplevel'); $rc == 0 or die_msg("Not inside a git repository");` — returns the same root path for the same cwd (no `-C`/`chdir` introduced; runs in the process cwd exactly as the backtick did), stderr noise discarded.
  - `cmd_list_releases`: `my ($out, $rc) = git_capture('ls-remote', '--tags', $source, 'v*'); die_msg(...) if $rc;` — `$source` is now a list element (no shell-string interpolation; narrows the `CWF_SOURCE`-derived metacharacter surface, NFR4).
- **Why a shared helper over inlining**: removes both backticks with one audited capture path; `IPC::Open3` (vs the `open '-|'` idiom in `resolve_ref`) is chosen because only `IPC::Open3` cleanly suppresses child stderr, which `find_git_root` needs. `resolve_ref`/`resolve_sha` are already perlcritic-clean and are **out of scope** (a future consolidation onto `git_capture` is a backlog candidate, not this task).
- **Result**: `perlcritic --severity 3` reports no `ProhibitBacktickOperators`; behaviour preserved (AC7/AC8).

## Decision D5 — FR5: integrity refresh per phase
- `.cwf/scripts/cwf-manage` is hash-tracked (`.cwf/security/script-hashes.json:204`). Every commit that edits it refreshes its sha256 in the **same commit** (hash-updates convention). FR1, FR2, FR4 all edit `cwf-manage` → each phase commit carries its hash refresh.
- **Correction (misalignment review)**: the hash ledger tracks **only installed `.cwf/` paths**. Repo-root `scripts/install.bash` and a hypothetical `scripts/check-tree-symlinks` are **outside the ledger** and carry **no refresh obligation** — this is the position Task 155 settled (`155-feature-converge.../c-design-plan.md:114`). (Earlier draft of this design wrongly claimed otherwise.) The integrity-coverage consequence of that for Option B is captured in D3's cost list.
- `cwf-manage validate` must pass at each phase checkpoint (already enforced by `cwf-checkpoint-commit`).

## Component / Data-flow summary
- **FR4 (do first — `git_capture` is a dependency of FR1)**: new `git_capture()` in `cwf-manage`; `find_git_root` + `cmd_list_releases` call it.
- **FR1**: `cmd_update` → new `git_describe_version()` (calls `git_capture`, falls back to `$sha` on non-zero) → version-file write (`cwf_version`=tag-derived, `cwf_ref`=`$ref`). No new files.
- **FR2**: `cmd_fix_security` (strip `--dry-run`, reject leftovers) → `_apply_recorded_perms($..., $dry_run)` → stdout only when dry-run; `cmd_help` text updated. No new files.
- **FR3 (Option B, if chosen)**: `cmd_update` copy branch → `system('bash', install.bash)` [full env block incl. `CWF_FORCE=1`, `CWF_METHOD=copy`] → `install_copy` → `perl check-tree-symlinks` (abort on escape) → `cp -r`. New file: `scripts/check-tree-symlinks` (outside hash ledger); register repo-root `scripts/` in `@CWF_INTERNAL_PREFIXES`. Deletes dead copy helpers from `cwf-manage` after caller enumeration. **(Option C: skip entirely; FR3 returns to backlog.)**

## Constraints
- Dog-food workflow; Perl core-only (`IPC::Open3` ✓); POSIX / macOS system-Perl; hash refresh same-commit.
- FR3 must not weaken the guard under any option (requirements NFR4).

## Decomposition Check (post-FR3-deferral)
- [ ] Time >1 week? No (now three surgical edits to one file).
- [ ] People >2? No.
- [x] **Complexity**: 3+ concerns? Borderline — three independent FRs, all confined to `cwf-manage`.
- [ ] **Risk**: high-risk component needing isolation? No — the high-risk slice (FR3) was deferred out. FR1/FR2/FR4 are low-risk surgical edits.
- [x] **Independence**: separable? Yes.

**Decision**: one flat task, scope now FR1/FR2/FR4. Implementation order is **FR4 → FR1 → FR2** (FR4's `git_capture` is a dependency of FR1's `git_describe_version`); FR1 is the Very High fix and lands right after its dependency.

## Validation
- [x] Design review completed (4 plan-review subagents)
- [x] FR3 option confirmed at the review gate → **deferred** (maintainer, 2026-05-24)
- [ ] Integration point verified: `_apply_recorded_perms` callers (`cmd_fix_security` additive, `apply_exact_perms_or_die` exact) — dry-run param must not perturb the exact-mode laydown path

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None (FR3 deferred; scope is FR1/FR2/FR4)

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
FR1/FR2/FR4 designs implemented as specified. D5's claim that install.bash/scripts/ are hash-tracked was corrected during review (Task 155 settled they are outside the ledger). D4 chose IPC::Open3, later superseded by `open '-|'` at the implementation-plan review.

## Lessons Learned
The design gate was the right place to defer FR3: the convergent reviewer signal (new guard script outside the hash ledger + auto-review set, CWF_FORCE/.cwf-rules preconditions) removed the task's only High-risk milestone cleanly rather than forcing a weaker bash symlink guard. See j-retrospective.md.
