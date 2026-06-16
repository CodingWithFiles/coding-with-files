# Simplify best-practice review to doc pointers - Plan
**Task**: 207 (chore)

## Task Reference
- **Task ID**: internal-207
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/207-simplify-best-practice-review-to-pointers
- **Baseline Commit**: e06185f2c8920fa4ec4d8c03e09983a6d3e774c2
- **Template Version**: 2.1

## Goal
Reduce the best-practice review (task 205) to its essence: a config entry is a
plain file/dir pointer + tags; the resolver selects the tag-matched pointers and
the reviewer Reads them directly — deleting URL support and every mechanism that
existed only to make untrusted/remote content safe.

## Success Criteria
- [ ] `best-practices.json` schema is just `active-tags` + `best-practices[]`
      (`documentation` path + `tags`); `allow-url-fetch` and `url-allow-hosts`
      are gone, and unknown keys are ignored without error.
- [ ] The resolver emits a tag-matched **list of local doc paths** (file or dir)
      with no inlining, no per-run sentinel, no byte cap, no dir content-walk,
      and no URL handling; it still prints a count that is the branch signal
      (`0` ⇒ skip reviewer, `≥1` ⇒ run it).
- [ ] Both reviewer agents read the pointed-at docs directly via Read/Grep/Glob;
      the `WebFetch` grant is removed from both agent definitions.
- [ ] Project-config paths remain realpath-confined to the git root; user-config
      paths remain trusted (this property survives the simplification).
- [ ] `best-practice-review.md` reflects the new contract; the URL / SSRF /
      DNS-rebinding / sentinel / byte-cap sections are removed.
- [ ] Test suite green; a fresh sample run and a repo grep show no stale
      references to the removed surface (allow-url-fetch, url-allow-hosts,
      sentinel, WebFetch, ### URLS, TRUNCATED).

## Original Estimate
**Effort**: ~0.5 day
**Complexity**: Low (net code removal; one retained security property)
**Dependencies**: Task 205 (the feature being simplified)

## Major Milestones
1. **Schema + resolver slimmed**: config loses URL knobs; resolver emits a
   path list, all untrusted-content machinery deleted.
2. **Agents + docs aligned**: WebFetch dropped from both agents; prompts and
   `best-practice-review.md` describe "Read these doc paths and assess".
3. **Tests + hashes + changelog**: tests rewritten to the new contract, hashes
   refreshed in the same commit, breaking change recorded.

## Risk Assessment
### High Priority Risks
- **Dropping a real security property, not just dead defence**: the sentinel /
  inlining guarded *untrusted* content; project-path repo-confinement is a
  *separate* property that must NOT be removed with it.
  - **Mitigation**: explicitly retain realpath confinement for project-config
    paths in the slimmed resolver; cover it with a test.
- **Hash-tracked files**: the resolver and (via permissions) the agent defs and
  `settings.json` are in `script-hashes.json`; an edit/delete that skips the
  same-commit hash refresh breaks `cwf-manage validate`.
  - **Mitigation**: follow `hash-updates.md` — refresh hashes in the same commit
    as the change; verify with `cwf-manage validate` before finishing exec.

### Medium Priority Risks
- **Breaking config change**: any existing `best-practices.json` using
  URL entries / `allow-url-fetch` would silently lose those entries.
  - **Mitigation**: feature is new (v1.1.205, unlikely to be in real use);
    resolver ignores unknown keys gracefully; record the break in CHANGELOG.
- **Agent definitions are session-cached**: edits to the agent `.md` files won't
  be live this session, so behaviour can't be fully smoke-tested now.
  - **Mitigation**: validate file content statically; note fresh-session
    verification in the retrospective.

## Dependencies
- Builds directly on task 205 (`205-feature-best-practice-reviewer`).
- Branches off `main` @ `e06185f` (the v1.1.206 tip).

## Constraints
- All work flows through the CWF workflow (this repo eats its own dog food).
- Perl core-modules only; POSIX; British spelling in prose.
- Open design decision for d-plan: does the resolver survive as a slim helper
  (config merge + tag match + path emit) or collapse entirely into the reviewer
  prompt? Decide in design with bias toward the smallest moving part.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No (~0.5 day).
- [ ] **People**: Does this need >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No (one feature, mostly removal).
- [ ] **Risk**: High-risk components needing isolation? No.
- [ ] **Independence**: Separable parts? No — schema, resolver, agents and docs
      change together as one contract.

0 signals triggered → no decomposition; proceed as a single task.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Delivered, with one success criterion deliberately overturned mid-task. The
final design went **beyond** this plan: the resolver hands the reviewer the
`documentation` path verbatim, so the 4th criterion ("project-config paths
remain realpath-confined to the git root") was **dropped on the maintainer's
direction**, not met — confinement is gone for a read-only advisory feature.
The other criteria hold:
- [x] Schema is `active-tags` + `best-practices[]`; URL keys gone; unknown keys
      ignored.
- [x] Resolver emits tag-matched local doc paths with no inlining/sentinel/
      byte-cap/dir-walk/URL handling; count is the branch signal.
- [x] Both agents read docs via Read/Grep/Glob; WebFetch removed.
- [~] **Confinement intentionally removed** (was "retain") — see Lessons Learned
      and `f-implementation-exec.md` § Revision; surfaced as an advisory
      security finding and accepted by the maintainer.
- [x] `best-practice-review.md` reflects the new contract; URL/SSRF/sentinel/
      byte-cap sections removed.
- [x] Suite green (866/72); sample run + repo grep show no stale removed surface.

Resolver 612 → ~290 lines. `cwf-manage validate: OK`. Full variance in
`j-retrospective.md`.

## Lessons Learned
- The plan named confinement as a high-priority property to **retain**, but never
  wrote down its threat model. When pressure-tested at exec ("what can a
  read-only reviewer do with a bad path?"), dropping it proved acceptable. Treat
  any "retain property P" plan note as a prompt to record P's threat model, so a
  later decision to drop P is made against the same model.
- For a "simplify X" task, the design should state the *minimal* end state and
  justify anything kept. Carrying a moderate cut (path list + confinement) into
  exec meant a second, more aggressive cut (verbatim paths) was discovered in
  review rather than designed up front.
