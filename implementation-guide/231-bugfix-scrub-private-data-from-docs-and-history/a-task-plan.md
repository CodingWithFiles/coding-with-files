# scrub private data from docs and history - Plan
**Task**: 231 (bugfix)

## Task Reference
- **Task ID**: internal-231
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/231-scrub-private-data-from-docs-and-history
- **Baseline Commit**: 7f24cfa69c236290f6c8545f0538c871a84be12d
- **Template Version**: 2.1

## Goal
Remove private data from the CWF repository — both the working tree and git
history — so it can be made public without leaking the maintainer's private
work or identity.

**Why (intent):** The repo is about to be made public. Its `implementation-guide`
docs contain a privacy fingerprint of the maintainer: names of ~10 *other* private
repositories, personal absolute paths that expose the username and home-directory
layout, and a personal email address. Publication is effectively irreversible
(clones, forks, archives), so the data must be gone from **all** commits, not just
the current tip, before the first public push.

**Explicit request (deliverables named by the owner, verbatim intent):**
1. Remove internal absolute paths (username-bearing `/home/<user>/repo/…`) and the
   internal file-hash-log path under `/var/tmp/`.
2. Remove the ~10 private project names.
3. Remove any `@mattkeenan.net` email address **except** `github@mattkeenan.net`
   (that one is already public and is to be kept).
4. Rewrite git history so the removed data is unrecoverable from past commits
   (owner decision, this session).
5. Replace redacted values with **generic placeholders** (owner decision, this session).

<!-- The goal is owner-owned. Do not unilaterally narrow or widen it. Surface any
     scope change (either direction) or goal/why tension to the owner as a decision. -->

## Success Criteria
<!-- Outcome-shaped: observable results, not named mechanisms. -->
- [ ] No `@mattkeenan.net` address other than `github@mattkeenan.net` appears
      anywhere in the tracked tree.
- [ ] No username-bearing absolute path (`/home/<user>/...`) or the internal
      file-hash-log path appears in the tracked docs; each is replaced by
      a non-identifying placeholder that leaves the surrounding prose readable.
- [ ] No distinctive private other-project name appears in the tracked tree;
      ambiguous common-word names (e.g. "gate") retain only their legitimate,
      non-project uses.
- [ ] The three categories above are also absent from **every** commit reachable
      from the branch tip — a scan of all historical blobs is clean.
- [ ] CWF integrity verification and the test suite pass after the change
      (no `cwf-manage validate` regression, no broken tests).

## Original Estimate
**Effort**: ~1 day
**Complexity**: Medium — mechanical redaction is easy; the history rewrite is
irreversible and the ambiguous-name disambiguation needs manual judgement.
**Dependencies**:
- A history-rewrite tool (`git filter-repo` preferred; `git filter-branch`/BFG fallback).
- The public push must happen **after** this task lands (sequencing constraint).

## Major Milestones
1. **Redaction ruleset agreed**: the exact match/replace rules for emails, paths,
   and distinctive names, plus the manual policy for ambiguous names.
2. **Working-tree redaction applied and verified**: current tip scans clean.
3. **History rewrite applied**: all reachable commits scan clean; backup preserved.
4. **Integrity/tests green**: `cwf-manage validate` and tests pass; branch ready
   for the owner to re-tag and push.

## Risk Assessment
### High Priority Risks
- **History rewrite is irreversible and rewrites every SHA**: invalidates existing
  `v1.1.x` tags and any clones/branches; a mistake is hard to undo.
  - **Mitigation**: capture a full backup (backup ref + `git bundle`) before the
    rewrite; run the all-commits scan as the gate; do it before any public push;
    document the re-tagging need for the owner (tagging is human-only).
- **Blind replacement of ambiguous common-word names corrupts legitimate text**:
  "gate" alone matches 365 files, almost all non-project ("quality gate").
  - **Mitigation**: never global-replace common words; scope those edits to the
    specific project-reference sites (concentrated in Task 219's aggregation) by
    manual review.

### Medium Priority Risks
- **`script-hashes.json` / `cwf-manage validate` regression**: the rewrite must not
  alter any hashed script — only docs.
  - **Mitigation**: restrict text replacement to `*.md` (and confirmed doc) blobs;
    run `validate` after and treat any hash drift as a stop.
- **Incomplete inventory — a private name/path slips through**: the initial scan may
  miss a variant.
  - **Mitigation**: the post-rewrite all-commits scan (SC4) is the backstop, not the
    initial grep; broaden patterns before declaring done.

## Dependencies
- `git filter-repo` (or an agreed fallback) available in the environment.
- Owner performs the human-only follow-ups (re-tagging `v1.1.x`, the public push)
  after this task lands.

## Constraints
- Redacted values become generic placeholders (owner decision), not context-carrying
  aliases.
- `github@mattkeenan.net` is explicitly retained.
- History rewrite is in-scope and required (owner decision).
- Tagging / pushing tags / pushing to a public remote remain human-only actions.

## Open Decisions
- **Scope breadth**: `implementation-guide/**` only, or the **entire tracked tree**
  (BACKLOG, CHANGELOG, README, `docs/`, skills)? The goal (public repo, no private
  data) argues for the whole tree; the owner framed it around the guide docs. Needs
  an explicit answer before design fixes the match set.
- **Placeholder literals**: the exact strings for each class — e.g. this-repo path
  vs other-repo path, and other-project names (`/path/to/repo`, `<other-project>`,
  etc.). Direction is "generic"; the literals are unchosen.
- **History-rewrite tool**: `git filter-repo` vs `git filter-branch` vs BFG —
  which is available and acceptable here.
- **Rewrite surface**: replace text only in doc blobs, or whole-tree — trades safety
  against completeness.
- **Ambiguous-name enumeration**: which exact ambiguous-word occurrences (the two
  common-word project names, plus the retained `lmm`) are project references vs common
  words — to be pinned down (manually) in design.
- **Tag handling**: whether/how `v1.1.x` tags are re-created on the rewritten history,
  and confirmation the owner does that (human-only).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — ~1 day.
- [ ] **People**: Does this need >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? Borderline (redaction, history rewrite,
      tag/integrity) but tightly coupled and sequential.
- [ ] **Risk**: High-risk component (history rewrite)? Yes — but isolating it into a
      subtask does not help; it depends on the redaction ruleset from the same task.
- [ ] **Independence**: Can parts be worked separately? No — redaction and rewrite are
      strictly sequential on the same content.

**Conclusion**: Do not decompose. One high-risk signal, but the parts are coupled and
sequential; a single task with a design phase is the right container.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five success criteria met, verified on a disposable clone (see g-testing-exec.md).
Scope widened by owner decision: whole tracked tree + commit/tag messages, and the task's
own workflow docs genericised. The live rewrite + push is staged as a human-only runbook
(f-exec Step 4). Tag re-push deferred (exposure open — see j-retrospective Future Work).

## Lessons Learned
The estimate priced the mechanical redaction, not the epistemics ("is it complete?",
"what is already public?"), which dominated the effort. See j-retrospective.md.
