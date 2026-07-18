# scrub private data from docs and history - Testing Plan
**Task**: 231 (bugfix)

## Task Reference
- **Task ID**: internal-231
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/231-scrub-private-data-from-docs-and-history
- **Template Version**: 2.1

## Goal
Prove the redaction is complete (all three categories, all surfaces: content, commit
messages, tag messages) and that the verification gate itself can fail — all against a
disposable clone, never the live repo.

## Test Strategy
### Test Levels
- **Gate self-test (negative control)**: prove `verify.sh` fires on a planted leak and
  does not fire on the kept address. A gate never shown to fail cannot be trusted to pass.
- **System test (end-to-end)**: `scrub.sh` → rewritten clone → full D6 gate green.
- **Regression**: existing `prove -r t/` suite + `cwf-manage validate` on the clone.
- **Acceptance**: sampled scrubbed lines read as coherent English (redaction didn't
  mangle the docs).

### Coverage Targets
- **Critical path (100%)**: every D6 gate item exercised; all three categories (emails,
  paths, names) and all three surfaces (file content, commit messages, annotated-tag
  messages) covered.
- **Kept-address invariant**: explicitly asserted (count unchanged, not flagged).
- **Edge**: git-grep exit-code polarity across `xargs` batches; ambiguous-name false
  positives (`quality gate`, `mcp__lmm__*`) must survive.

## Test Cases
### Functional
- **TC-1 — Negative control, Class A (gate fires)**
  - **Given**: the rewritten clone, plus a planted known Class-A string (a distinctive
    name / personal email / private path) in a tracked file.
  - **When**: `verify.sh` runs.
  - **Then**: it exits non-zero and names the planted file; removing the plant restores PASS.
- **TC-2 — Negative control, Class B (gate fires)**
  - **Given**: the clone with a planted ambiguous-name project-ref site (e.g. a
    `gate (N)` tally line).
  - **When**: `verify.sh` runs.
  - **Then**: non-zero exit flagging it.
- **TC-3 — Kept address survives**
  - **Given**: the rewritten clone.
  - **When**: the kept-address check runs.
  - **Then**: `github@mattkeenan.net` occurrence count equals the pre-rewrite pre-image,
    and it is never reported as a leak.
- **TC-4 — Content scan clean (all commits)**
  - **Given**: the rewritten clone.
  - **When**: `git rev-list --all | xargs -r git grep -nE <patterns>` runs.
  - **Then**: no Class-A pattern or Class-B site matches in any commit's tree.
- **TC-5 — Commit-message scan clean**
  - **Given**: the rewritten clone.
  - **When**: `git log --all --format='%B'` is scanned for the patterns.
  - **Then**: no match — the `Co-developed-by: … <claude@…>` trailers and any path/name
    in message bodies are gone.
- **TC-6 — Annotated-tag-message scan clean**
  - **Given**: the rewritten clone (30 annotated tags).
  - **When**: each `tag` object body (`git cat-file tag`) is scanned.
  - **Then**: no pattern matches.
- **TC-7 — Tag state preserved**
  - **Given**: pre- and post-rewrite `git for-each-ref refs/tags` on the clone.
  - **When**: compared.
  - **Then**: the 39 tag **names/count are identical** (re-pointed, not dropped); no
    manual re-creation was needed.
- **TC-8 — Exit-code polarity across batches**
  - **Given**: a leak planted only in an **early-history** commit (a later `xargs` batch
    is clean).
  - **When**: the content scan runs.
  - **Then**: overall exit is non-zero — a later clean batch does not mask the early
    match (guards the `git grep` 0=match / 1=no-match inversion).
- **TC-9 — Ambiguous-name false positives survive**
  - **Given**: the rewritten clone.
  - **When**: searched for legitimate `quality gate`, `mcp__lmm__*`, "LMM corpus".
  - **Then**: they are **present and unchanged** — no bare-word rule over-matched.
- **TC-10 — Integrity + suite green**
  - **Given**: the rewritten clone.
  - **When**: `.cwf/scripts/cwf-manage validate` and `prove -r t/` run.
  - **Then**: validate OK (no hash/permission drift — no hashed blob was altered) and the
    full suite passes.
- **TC-11 — Readability (acceptance)**
  - **Given**: the rewritten clone.
  - **When**: sampled scrubbed lines (CHANGELOG impact lines; Task 219 tallies) are read.
  - **Then**: they are coherent English; placeholders (`<other-project>`, `<repo-root>`,
    `(N other projects)`) read sensibly.
- **TC-12 — Scratch purge**
  - **Given**: a passed gate.
  - **When**: the Step-5 cleanup runs.
  - **Then**: the `git bundle`, `redact-rules.txt`, `verify.sh`, and disposable clone are
    removed — no unredacted plaintext remains in scratch.

### Non-Functional
- **Security**: after purge, no scratch file contains any Class-A/B string (re-grep the
  scratch dir); the f-exec runbook states the remote-retention caveat (doc assertion).
- **Reliability**: `verify.sh` fails closed — any single leak, in any surface or batch,
  yields non-zero; the negative control runs **first** and gates trust in a PASS.
- **Performance**: the ~1981-commit `rev-list --all` scan uses `xargs` (not `$(…)`) and
  completes without ARG_MAX issues.

## Test Environment
### Setup
- A disposable `git clone` of the repo under scratch `task-231/clone-test` — **never the
  live repo** (the "test DB, never production" rule for history rewrites).
- `git bundle --all` backup captured before any rewrite.
- Tools: `git filter-repo` (`/usr/bin/git-filter-repo`), `.cwf/scripts/cwf-manage`, `prove`.

### Automation
- The gate is `verify.sh` (scratch), run `chmod +x && ./verify.sh <clone>`; results
  captured verbatim into g-testing-exec. No CI integration (one-off task).

## Validation Criteria
- [ ] TC-1..TC-12 all pass on the rewritten clone.
- [ ] Negative controls (TC-1, TC-2) demonstrate the gate fails on a planted leak.
- [ ] Kept-address invariant (TC-3) holds.
- [ ] All three surfaces clean (TC-4, TC-5, TC-6); tags preserved (TC-7).
- [ ] `cwf-manage validate` + `prove -r t/` green (TC-10).
- [ ] Scratch purged (TC-12).

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
TC-1..TC-12 all executed and passed on the rewritten clone (see g-testing-exec.md). The
content scan (TC-4) additionally caught a self-leak in f-exec (G1), fixed and re-verified.
Coverage confirmed across all 432 refs, not just `main`.

## Lessons Learned
The gate must scan the task's own docs too — the verification pattern matches the doc that
describes it (describe plants, never embed them). See j-retrospective.md.
