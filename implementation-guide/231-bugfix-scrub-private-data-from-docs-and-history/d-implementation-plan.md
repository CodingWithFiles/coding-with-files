# scrub private data from docs and history - Implementation Plan
**Task**: 231 (bugfix)

## Task Reference
- **Task ID**: internal-231
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/231-scrub-private-data-from-docs-and-history
- **Template Version**: 2.1

## Goal
Build and verify the redaction tooling (scratch), and stage the owner runbook, per the
c-design plan. The live-repo rewrite is a human step (see Sequencing).

## Corrections to c-design (folded in from d-plan review)
- **Tag handling** (c-design said "orphans 39 tags; owner re-creates"): **wrong**.
  `git filter-repo` **re-points every tag ref automatically** and, with
  `--replace-message`, rewrites the **30 annotated** tags' message objects too (verified:
  30 annotated + 9 lightweight = 39, mixed `v0.x`/`v1.0.x`/`v1.1.x` + one
  `migration-backup-*`). The owner does **not** re-create tags; the runbook only verifies
  them. Tag **messages** are in the scrub scope and the verify gate.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Sequencing (read first — this task ships no redaction diff)
A history rewrite cannot be a branch diff. So:
1. This task's **committed** artefacts are only its workflow docs (a/c/d/e/f/g/j).
2. The redaction **tooling** (rules file + scripts) is built and verified in **scratch**
   against a throwaway clone (D4/D5).
3. After this task squashes to main (human), the **owner** runs the verified rewrite over
   all of main — scrubbing every commit/message/tag, including this task's own docs —
   then pushes (human-only runbook).

## Files to Modify
### Committed (this branch)
- This file and sibling e/f/g/j workflow docs — normal CWF checkpoints only.

### Rewritten by the pass (NOT hand-edited, NOT a branch commit)
Raw strings live in the scratch inventory, never in committed docs (D4):
- `implementation-guide/**` — 58 files w/ paths, 2 w/ personal email, ~15 w/ distinctive
  names, plus Class-B sites (`inv-paths-emails.txt`, `inv-distinctive-names.txt`,
  `inv-classB-sites.txt`).
- `CHANGELOG.md` — 3 saturated impact lines.
- **Commit messages** (`Co-developed-by: … <claude@…>` trailers, paths/names) **and the
  30 annotated-tag messages**.

### Scratch only (untracked, never committed — D4)
- `redact-rules.txt`; `scrub.sh` (test-loop wrapper, not a shipped entry point);
  `verify.sh` (D6 gate).

## Implementation Steps

### Step 1: Build the rules file (`redact-rules.txt`, scratch)
- [ ] **Emails**: literal `<personal-email>==>user@example.com` (the personal non-public address).
- [ ] **Paths** (regex, most-specific first): this-repo → `<repo-root>`; other-repo
      (`/home/<user>/repo/<name>`) → `/path/to/<other-project>`; bare home → `/home/<user>`
      (username-only); disposable log → `/var/tmp/<other-project>.log`. (Placeholder
      token is `<user>` throughout — matches the c-design Placeholder Table.)
- [ ] **Distinctive names**: one literal per name in `inv-distinctive-names.txt` →
      `<other-project>`.
- [ ] **Class-B ambiguous project-refs** (`inv-classB-sites.txt`): one literal **per
      occurrence**, each carrying enough surrounding punctuation to excise cleanly.
      **Never** a bare common-word rule (the two ambiguous project words or `lmm`).
- [ ] **Rosters**: literal whole-line replacement → "(N other projects)".
- [ ] **Kept-address invariant (all classes, not just emails)**: assert **no** rule —
      email, name, or path — matches `github@mattkeenan.net`. Record its whole-tree
      occurrence count now as the pre-image for the Step-3 count check.
- [ ] Order rules most-specific-first; non-matching comment header.

### Step 2: Write the tooling (`scrub.sh`, `verify.sh`, scratch)
- [ ] `scrub.sh <clone-dest>`: `git clone` to the operator dest, run `git filter-repo
      --replace-text redact-rules.txt --replace-message redact-rules.txt --force`, print
      the runbook. Quote all expansions (author-only patterns).
- [ ] `verify.sh <target-repo>`: the D6 gate, patterns derived from `redact-rules.txt`
      (never inlined):
  - **content scan**: `git rev-list --all | xargs -r git grep -nE <patterns>` — but map
    exit codes explicitly: `git grep` returns **0 on match (=leak=FAIL)**, 1 on no-match
    (=PASS); aggregate across all `xargs` batches so a later-batch match is never masked
    (a single match anywhere ⇒ non-zero overall).
  - **commit-message scan**: `git log --all --format='%B'` piped through the patterns.
  - **annotated-tag-message scan**: `git for-each-ref refs/tags --format='%(objecttype)
    %(objectname)'` → `git cat-file tag` for `tag` objects → pattern scan (git log does
    **not** emit tag bodies).
  - **kept-address integrity**: assert `github@mattkeenan.net` occurrence **count** is
    unchanged vs the Step-1 pre-image (presence alone is insufficient — a name/path rule
    overlapping `mattkeenan` could mutate it).
  - `.cwf/scripts/cwf-manage validate` and `prove -r t/`.
  - non-zero exit on any leak/mismatch.
- [ ] Run scratch scripts `chmod +x && ./script` (never `bash`/`perl <script>` — shell-hygiene).

### Step 3: Test against a throwaway clone (never the live repo)
- [ ] `git bundle --all` backup into scratch.
- [ ] `scrub.sh <clone-dest>` → rewritten clone.
- [ ] **Negative control** (first): plant a known Class-A and Class-B string in the clone,
      confirm `verify.sh` flags them; confirm `github@mattkeenan.net` is not flagged;
      remove the plants.
- [ ] **Tag-state check**: `git for-each-ref refs/tags` count/names identical pre/post on
      the clone (re-pointed, not dropped); annotated-tag messages scrubbed.
- [ ] Full D6 gate green (content + commit-message + tag-message + kept-address-count +
      validate + suite).
- [ ] Readability spot-check: sampled CHANGELOG + Task 219 lines coherent.
- [ ] **Line-wrap assumption**: verified no private token spans a line boundary in the
      corpus (checked at plan time), so per-line rules/scan are complete; re-confirm if
      the corpus changes.

### Step 4: Stage the owner runbook (do NOT execute)
Emit into f-exec, for the owner:
- [ ] Pre-flight `git bundle --all` backup; restore command documented
      (`git clone <bundle> <restore>`), and an explicit pre-push confirmation gate.
- [ ] Live `git filter-repo --replace-text … --replace-message … --force` (tags
      re-point automatically — no manual re-creation).
- [ ] Post-run local purge of unredacted remnants: `git reflog expire --all
      --expire=now && git gc --prune=now` and remove `.git/filter-repo/`.
- [ ] `git push --force` (or fresh remote), then **remote-retention caveat**: a
      force-push does **not** purge unreachable objects — scrubbed commits stay reachable
      by old SHA (and via cache/forks/open PRs) until the remote gc's or GitHub support
      purges. State this in the runbook; not secrets, so no credential rotation.

### Step 5: Cleanup + validation
- [ ] After the gate passes, **purge scratch remnants**: the `git bundle`,
      `redact-rules.txt`, `verify.sh`, and the disposable clone (all hold unredacted
      plaintext) — "scratch-only" is not "removed".
- [ ] `.cwf/scripts/cwf-manage validate` OK on this branch (workflow-doc commits only).
- [ ] Definition of done + evidence: **see e-testing-plan.md** (D6 gate green on the
      rewritten clone, negative control proving the gate can fail).

## Test Coverage
**See e-testing-plan.md** — negative-control, content-scan, commit-message-scan,
tag-message-scan, kept-address-count, tag-state, validate, suite, readability.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking Finished.

The live-repo rewrite is a human-only boundary (like merge-to-main), surfaced as a
verified runbook — not deferred work.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Tooling built and the D6 gate went green on a clone. Two additions beyond the plan: a
dashified-username path regex (`home-<user>` — 72 docs the slash rules missed, found in
review) and a `fix-security` step in the runbook (git records only the exec bit, so
recorded 0500/0444 drift on a fresh checkout). `lmm` retained per owner decision.

## Lessons Learned
Enumerate path-embedding variants (slash, dash, URL-encoded) at inventory time, not after
review. See j-retrospective.md.
