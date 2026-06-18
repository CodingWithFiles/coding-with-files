# Skip non-regular files in untracked sweep - Retrospective
**Task**: 209 (bugfix)

## Task Reference
- **Task ID**: internal-209
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/209-skip-non-regular-files-in-untracked-sweep
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-18

## Executive Summary
- **Duration**: ~1 day (estimated <1 day — on target).
- **Scope**: Unchanged from plan — one-line filter in `list_untracked_files()`
  plus two tests and a same-commit hash refresh.
- **Outcome**: Success. A CWF user's sandbox (Claude Code `/dev/null` bind-mount
  masks at the repo root) surfaced char-device untracked entries that aborted the
  changeset reviewer's `git add -N`. The filter restricts the sweep to
  git-indexable types; the reviewer no longer aborts.

## Variance Analysis
### Time and Effort
- **Estimated**: <1 day total (Low complexity).
- **Actual**: ~1 day across planning → design → impl-plan → testing-plan →
  exec → testing-exec → retrospective. No phase overran.
- **Variance**: None material. The bulk of the effort was empirical
  investigation (what git enumerates, how to reproduce the char device), not the
  one-line code change — as expected for a bugfix of this shape.

### Scope Changes
- **Additions**: none beyond plan.
- **Removals**: none.
- **Impact**: n/a.

### Quality Metrics
- **Test Coverage**: `t/security-review-changeset.t` 49/49 (was 47); full suite
  871/871. `cwf-manage validate` clean.
- **Defect Rate**: 0 post-fix; the reported bug is fixed and regression-guarded.
- **Performance**: n/a (a filetest per untracked path; negligible).

## What Went Well
- **Empirical verification over assumption.** Rather than trust that "fifos/
  devices break `git add -N`", I tested it: fifos/sockets are *not* enumerated by
  `git ls-files --others` (so they never reach the bug), and only char/block
  devices reproduce it. This corrected the test design before code was written.
- **Faithful reproduction.** `unshare -rm` + `mount --bind /dev/null` reproduces
  the sandbox char-device mask without root, giving TC-209-2 a genuine
  red-then-green (verified abort on the unpatched helper).
- **Plan reviews earned their keep.** The misalignment reviewer surfaced the
  `stop-stale-status-detector` sibling precedent; robustness flagged the
  red-then-green and chmod-to-recorded gaps. All folded in before exec.

## What Could Be Improved
- **Best-practice resolver keeps matching off-domain corpora.** Every review
  phase resolved `golang`/`postgres` tags for a Perl helper change, and the
  reviewer noted the resolver output format does not match the `### DOCS` shape
  its agent expects. Noise, not a defect here — but recurring across all five
  review phases. Logged as a backlog follow-up.

## Key Learnings
### Technical Insights
- `git ls-files --others` (git 2.43) enumerates only regular files and symlinks
  by concrete d_type; fifos/sockets are skipped. Char/block devices leak in via
  the `DT_UNKNOWN` path (e.g. a bind-mount over a dir entry), which is exactly
  why the sandbox masks reproduce the bug and a plain fifo does not.
- `git add -N` accepts dangling symlinks and symlinks-to-devices (stores link
  text), so `-l` retention is load-bearing — a bare `-f` would silently drop
  reviewable symlinks.

### Process Learnings
- For "can't create the failing artefact as an unprivileged user" cases, a
  user+mount namespace (`unshare -rm`) is a portable-enough reproduction with a
  clean SKIP gate, beating a vacuous mock.

## Recommendations
### Future Work
- Investigate `best-practice-resolve`: why it tag-matches off-domain corpora for
  a Perl task, and align its output format with the `### DOCS` shape the reviewer
  agents expect. (Backlog item added.)

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-18
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Links to planning documents and artefacts
- Links to implementation PRs and commits
- Links to test results and quality reports
- Links to deployment and monitoring dashboards
