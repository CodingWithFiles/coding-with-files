# scrub private data from docs and history - Implementation Execution
**Task**: 231 (bugfix)

## Task Reference
- **Task ID**: internal-231
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/231-scrub-private-data-from-docs-and-history
- **Template Version**: 2.1

## Goal
Build and verify the redaction tooling (scratch), and stage the owner runbook, per
d-implementation-plan.md. The live-repo rewrite is a human step (see Runbook).

## Sequencing (ships no redaction diff)
This branch commits only its workflow docs (a/c/d/e/f/g/j). The redaction **tooling**
(rules + scripts) is built and verified in **scratch** against a throwaway clone. After
this task squashes to main, the **owner** runs the verified rewrite over all of main
(scrubbing every commit/message/tag, including this task's own docs), then pushes.

## Owner decision folded in (execution finding)
Verification surfaced that **`lmm` is not a cleanly-scrubbable third-party project**: it
is the memory-integration name, present in the `mcp__lmm__*` tool namespace (unchangeable
— the real API), in a tracked **directory path** (`implementation-guide/107-…-via-lmm-mem`,
which `--replace-text` cannot rewrite — it rewrites content, not paths), and in ~95
legitimate references. **Owner decision (Task 231): retain `lmm` entirely.** The other
~9 names are content-only and cleanly scrubbable. `lmm` is the only entangled token — the
two ambiguous project words (one a shorthand for a longer distinctive name) are confined
to the Task-219 tallies and CHANGELOG/228 rosters, handled at their specific sites.

## Files
### Committed (this branch)
- This file and sibling workflow docs — normal CWF checkpoints only.

### Scratch only (untracked, never committed — D4)
- `redact-rules.txt` — the filter-repo rules (raw→placeholder; **is** the private data).
- `scrub.sh` — clone + `filter-repo --replace-text … --replace-message …` driver.
- `verify.sh` — the D6 gate (embeds raw patterns; scratch-only for the same reason).

### Rewritten by the owner's live pass (NOT hand-edited)
- `implementation-guide/**` (paths, personal email, distinctive names, Class-B sites),
  `CHANGELOG.md` (rosters + names), **commit messages** (`claude@…` trailers, paths,
  names), and the **30 annotated-tag messages**. All verified doc-confined — **no hashed
  script contains any pattern**, so the pass cannot alter a hashed blob (confirmed:
  post-scrub `validate` shows zero sha256 violations).

## Actual Results

### Step 1: Build `redact-rules.txt` (scratch) — DONE
Rules are applied by filter-repo as **all literals first (file order), then all regexes
(file order)**, over the whole blob (`regex.sub` sees `\n`) — verified by reading the
installed `git_filter_repo.py` (`get_replace_text`, blob apply loop). Consequences:
- `#` is **not** a comment in a replace-text file (it becomes a literal→`***REMOVED***`).
  So the rules file carries **rules only** (blank lines are safely skipped).
- The rule set (described **by category** — the raw tokens live only in the scratch
  `redact-rules.txt`, never in this committed doc, so this file adds nothing back that the
  task removes):
  - **Email**: the owner's personal non-public address → a generic placeholder. The public
    git-identity address (`github@mattkeenan.net`, already in every commit's author field)
    is deliberately untouched — a distinct local-part, and no other local-part on that
    domain exists (verified).
  - **Class-B roster** (composite literal, before the ambiguous-word regex): the single
    tally line listing two ambiguous project words alongside the retained `lmm` →
    placeholders for the two, `lmm` kept.
  - **Class-B shorthand** — a handful of context-bearing literals for one ambiguous
    project word, **each collision-checked against the Task-219 f-exec** (comma/period-
    anchored tally forms, plus one regex for the line-wrapped form). **Never a bare
    single-word rule** — so ordinary phrases like “quality gate” survive. The probe caught
    a real false-positive risk: another task uses the same word as an everyday
    validation-gate reference, so the un-anchored form is unsafe — hence the anchors.
  - **Class-A distinctive names** (global literals → `<other-project>`): the ~7
    unambiguous private project names (one has a `.app`-suffixed form, ordered before its
    bare form). Being unambiguous, a global literal is safe.
  - **Ambiguous-word regex**: one `\bword\b` regex for a second ambiguous project word,
    verified confined to project refs (no unrelated system-tool sense anywhere in the
    tree), ordered after the roster literal.
  - **Paths**: regexes for the two repo-root absolute paths (current and former repo name)
    → `<repo-root>`; a home catch-all → `/home/<user>`; and the **dashified** username form
    → `home-<user>` (added post-review — see Changeset Reviews). The dashified scratch/
    analysis paths embed the username with a `-`, not `/`, before `home`, so the slash
    rules miss them; **72 committed docs** carry this form. The distinctive-name and
    dashified-home rules together de-identify them.

### Step 2: Write `scrub.sh`, `verify.sh` (scratch) — DONE
Both run `chmod +x && ./script`. `verify.sh` derives its scan patterns from the same raw
set; it is scratch-only. The D6 gate: (1) all-history content scan, (2) commit-message
scan, (3) annotated-tag-message scan via `git cat-file tag`, (4) kept-address integrity
(HEAD-tree count vs pre-image + history presence), (5) legit-token survival
(`mcp__lmm__`, `quality gate`), (6) `cwf-manage validate`, (7) `prove -r t/`. All scans
capture output (a match in **any** `xargs` batch ⇒ fail), so batch position cannot mask a
leak (TC-8 by construction).

### Step 3: Test against a throwaway clone — DONE (gate GREEN on the redaction)
`scrub.sh` cloned the repo (`--no-local`) and rewrote **1981 commits + 30 annotated tags**
in ~3 s. `verify.sh <clone> 22`:
- **content scan (all commits, whole tree): clean** ✓
- **commit-message scan: clean** ✓ (the `claude@…` Co-developed-by trailers are gone)
- **annotated-tag-message scan: clean** ✓
- **kept-address**: `github@mattkeenan.net` HEAD count **22 == pre-image 22**, present in
  history ✓
- **legit tokens survive**: `mcp__lmm__` present, `quality gate` present ✓ (lmm retained;
  no bare-word over-match)
- **negative controls (TC-1 Class A + TC-2 Class B)**: a planted leak file carrying one of
  each category — a distinctive project name, a username-bearing absolute path (slash and
  dashified), the personal email, a project roster, and a synthetic Class-B tally line —
  made the gate **fire and name exactly that file** — and only it — while the kept address,
  an `mcp__lmm__` token, and a `quality gate` phrase in the same file were **not** flagged.
  The gate is proven able to fail. (The plant strings are described here, not embedded, so
  this doc carries no raw private-looking token — a lesson from the g-phase scan, below.)
- **integrity**: post-scrub `validate` violations are **100% permission-drift**
  (`Field: permissions`, umask-derived 0700/0600 on a raw checkout — git records only the
  exec bit, so recorded 0500/0444 are not reproduced by clone) — **zero sha256/content/
  existence violations**. `cwf-manage fix-security` clamped them → **`validate: OK`**,
  confirming no hashed blob was altered.
- **suite**: `Files=78, Tests=1077`; the sole failure was `t/cwf-manage-fix-security.t`
  test 10, which **passes on the live repo** and exercises `cwf-manage` (a file the scrub
  never touched) — a clone-only artifact of the manual `fix-security` run, not a
  redaction regression.
- **readability (TC-11)**: the CHANGELOG:41 roster keeps “6 projects (…)”; the Task-219
  survey table keeps this repo (`coding-with-files`, a public name) and the retained
  `lmm`, with private projects genericised to `<other-project>` (distinct-project
  distinction intentionally dropped — generic placeholders, not aliases).

### Step 4: Owner runbook (do NOT execute — human-only boundary)
Run from the task-231 scratch tooling directory (the per-project scratch base +
`/task-231/`, per the tmp-paths convention — deliberately not written out here so this
doc carries no username), after Task 231 is on main and you are ready to publish:

1. **Backup**: `git bundle create pre-rewrite.bundle --all` (restore:
   `git clone pre-rewrite.bundle <restore-dir>`). Keep until the public push is confirmed.
2. **Rewrite in place** (from the live repo root):
   `git filter-repo --replace-text redact-rules.txt --replace-message redact-rules.txt --force`
   — rewrites every commit/message and **re-points all 39 tags automatically** (30
   annotated messages rewritten; no manual re-creation). filter-repo drops the `origin`
   remote — re-add it before pushing.
3. **Restore recorded perms** (filter-repo's final checkout is umask-derived):
   `.cwf/scripts/cwf-manage fix-security` → expect `validate: OK`.
4. **Verify**: `./verify.sh . <N>` — where `<N>` is the current `github@…` count on the
   pre-rewrite tree (`git grep -cI 'github@' HEAD` before Step 2), **not** a hard-coded
   literal: the count drifts as docs mention the address, so a stale number causes a false
   mismatch. The count only guards against accidental *modification* of the kept address;
   **presence + zero-leak is the real gate**. Expect GATE: PASS (content/messages/tags
   clean, kept address present + unmodified, legit tokens survive). Also `prove -r t/`.
5. **Purge local originals**: `git reflog expire --all --expire=now && git gc --prune=now`;
   remove `.git/filter-repo/`.
6. **Push — `main` ONLY** (explicit confirmation gate): `git remote add origin <url>`.
   First confirm `main` is the sole public branch: `git ls-remote --heads origin` → expect
   exactly `refs/heads/main`; if any other branch exists on the remote it still points at
   unredacted history — delete it (`git push origin --delete <branch>`) before proceeding.
   Then `git push --force origin main`. **Never `git push --all` / `--tags` / `--mirror`**:
   those would publish the ~432 local branches (task + checkpoint) and the 17 local-only
   tags — new public copies of history that is deliberately kept local, the opposite of the
   goal.

   ⚠️ **Tags: DEFERRED** (owner decision — not re-pushed in this pass). The 22 tags already
   on `origin` point at the OLD, unscrubbed commits, and a force-push of `main` does **not**
   move them — so until the tags are separately force-updated to the rewritten commits or
   deleted, `git clone` + `git log <tag>` still exposes the old private-data history.
   Deferring tags leaves that exposure open; close it as a deliberate follow-up.
7. **Final scratch purge** (TC-12): remove `redact-rules.txt`, `verify.sh`, `scrub.sh`,
   the inventories, the bundle, and any clone — all hold unredacted plaintext.

**Remote surface & retention**: the only public/remote is `origin` (GitHub, public,
`main` + 22 tags). The `backup` remote is a local `file://` bare repo — out of scope, as
are all 432 local branches and the 17 local-only tags (local copies of the owner's own
data are not a concern; only public/remote copies are). **The private data is already
public**: `origin/main` currently carries **58 files** with personal paths / email /
project names, so this scrub is *remediation* of a live exposure, not only prevention.
Task 231's own docs are not yet on `origin/main`, so they are scrubbed before their first
push (prevention for those). A force-push of the rewritten `main` does **not** immediately
purge the old commits — they stay reachable by SHA until the remote gc's — but with **0
PRs and 0 forks confirmed** (nothing pins `refs/pull/*` or a fork object-network), GitHub
gc reclaims the now-unreferenced branch objects on its own schedule; no delete/recreate or
Support purge is required for the branch history. **Tags are the exception** (Step 6
caveat): until the 22 public tags are force-updated or deleted they keep the old unscrubbed
commits reachable. Prior clones / third-party mirrors are outside this scrub's reach — the
rewrite closes future access via `origin`, it cannot un-expose what was already published.
Not secrets, so no credential rotation.

### Step 5: Cleanup — DEFERRED to the owner's final step (Step 4.7)
The scratch tooling is **retained** now because the owner needs it to run the live
rewrite (human-only boundary). The disposable test **clone and test bundle were purged**
immediately after the gate passed (they held full unredacted history). Final purge of the
rules/scripts/inventories is the last runbook step, after the public push.

## Deviations from plan
- **`lmm` retained** (owner decision) — not scrubbed; d-plan had listed it among the
  Class-B ambiguous set. Reason: memory-integration name, in the `mcp__lmm__` namespace
  and a tracked directory path; content-only scrubbing would be inconsistent for no gain.
- **Other-repo path placeholder**: the c-design table showed `/path/to/<other-project>`.
  Because filter-repo applies name **literals before** path **regexes**, a distinctive
  repo path (personal home + a distinctive project name) becomes
  `/home/<user>/repo/<other-project>` via the name rule + home catch-all — equally
  de-identified, and the generic-repo regex was dropped as redundant. Consistent and simpler.
- **`fix-security` step added to the runbook** — filter-repo's final checkout resets perms
  to umask; recorded 0500/0444 must be re-clamped (and this is what makes `validate` pass).

## Blockers Encountered
None. One decision (lmm) was surfaced to and resolved by the owner mid-execution.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed (live rewrite is the human-only
      boundary, staged as a verified runbook — not deferred work).
- [x] All a-task-plan.md success criteria met (verified on the clone).
- [x] All c-design-plan.md guidance followed (deviations documented above).
- [x] No planned work deferred without approval.

## Changeset Reviews
The parallel five-reviewer MAP ran on the changeset (workflow docs; 0 production lines) in
**two rounds**. Verdicts via `security-review-classify`.

**Round 1 (initial f)** caught a real leak: **dashified** username-bearing scratch paths
(of the form `cwf-home-<user>-repo-…`) embed the username with a `-` before `home`, so the
slash-anchored path rules — and the verify scan — missed them (**72 committed docs**).
Fixed in-phase: added a dashified-username regex (`home-<user>`) to `redact-rules.txt`,
added the same form to the `verify.sh` leak pattern, re-scrubbed a fresh clone clean.

**Round 2 (this amendment)** reviewed the owner-runbook push fix and the doc
genericisation. Current verdicts:

### Security Review
**State**: findings (**addressed in-phase**) — (1) reconcile "already public": confirmed
`origin/main` already carries **58** private-data files, so the retention note now frames
the scrub as remediation **and** prevention (Step 4 note); (2) Step 1 embedded raw private
project names — **genericised to categories** per owner decision (raw tokens live only in
scratch `redact-rules.txt`), which also removes the self-covering dependency for this
task's own docs. The push guidance itself was cleared ("directly prevents publishing
private local branches").

### Best-Practice Review
**State**: no findings — docs-only changeset; golang/perl/postgres sources readable but no
applicable code artefact.

### Improvements Review
**State**: no findings — amendment narrows (push scoped to `main`, redundant regex pruned),
reuses `cwf-manage`/`filter-repo`/`prove`, ships no committed tooling. Advisory: mild
overlap between Step 6 and the retention note (each half earns its place).

### Robustness Review
**State**: findings (**fixed in-phase**) — three runbook gaps, all corrected: (A) added a
`git ls-remote --heads origin` sole-public-branch check before the push (a stray public
branch would keep pointing at unredacted history); (B) tag handling made explicit
(DEFERRED, with the exposure caveat); (C) dropped the stale hard-coded `github@` count
`22` (it drifts — presence, not a fixed count, is the gate).

### Misalignment Review
**State**: no findings — the narrowed push + retention note strengthen the human-only
boundary and minimal-public-surface norms; reuses existing CWF abstractions. Advisory
(pre-existing): c-design D3's rule-ordering wording contradicts f-exec Step 1's correction
— reconcilable in c later.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
See Steps 1–5 above.

## Lessons Learned
- filter-repo applies **all literals first (file order), then all regexes (file order)** —
  not most-specific-first; `#` is a literal, not a comment.
- Name literals apply before path regexes, so a distinctive-name rule de-identifies its
  repo path — the generic other-repo regex was redundant.
- The task's own docs are a leak surface: describe example/plant strings, never embed them,
  and don't reintroduce raw private tokens into docs you are about to publish.
- See j-retrospective.md for the full set.
