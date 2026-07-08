# Seed exclude-path defaults, raise review cap 1000 - Requirements
**Task**: 221 (feature)

## Task Reference
- **Task ID**: internal-221
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/221-seed-exclude-path-defaults-raise-review-cap-1000
- **Template Version**: 2.1

## Goal
Ship a seeded default `security.review` config (generic, cross-ecosystem exclude
globs) and raise the built-in default cap from 500 to 1000, so the changeset
review stops false-tripping on non-production churn and long baselines, without
changing Task 218's resolution semantics.

## Seed surface & precedent
The canonical seed is `.cwf/templates/cwf-project.json.template`, copied to
`implementation-guide/cwf-project.json` by `/cwf-init` (SKILL.md step "Create
… from template"). The template already carries an analogous optional block —
`sandbox` + its `_sandbox-note` — seeded the same way. This task mirrors that
precedent for `security.review`. The template ships to **every** ecosystem, so
the seeded globs must be generic (not CWF/Perl-specific paths like `t/**`).

## Functional Requirements
### Core Features
- **FR1 — Seeded generic exclude default**: The template carries a
  `security.review.max-lines-exclude-paths` array of git-pathspec globs covering
  two categories that are non-production across common ecosystems:
  - **test**: e.g. `**/*_test.*`, `**/*.test.*`, `**/*_spec.*`, `**/test/**`,
    `**/tests/**`, `**/spec/**`
  - **generated/vendored**: e.g. `**/vendor/**`, `**/node_modules/**`,
    `**/dist/**`, `**/build/**`, `**/__pycache__/**`, `**/*.min.*`,
    `**/*.generated.*`
  (Exact strings finalised in design; the two categories are fixed here.)
  Acceptance: a changeset whose churn is confined to paths matching the seeded
  set counts 0 production lines against the cap.
- **FR2 — Doc-only markdown exclusion (scoped)**: The seeded set additionally
  excludes doc-only markdown, but scoped to conventional doc locations (e.g.
  `**/docs/**/*.md` and top-level `*.md`), **not** a blanket `**/*.md` — because
  markdown carries genuine production content in doc-heavy repos (fail-open, see
  NFR4). Exact doc scope is the one design decision this FR defers; the
  non-blanket constraint is fixed here.
- **FR3 — Security-path guardrail**: No seeded glob matches CWF's own
  security-relevant paths — `.cwf/scripts/`, `.cwf/hooks/`, `.cwf/security/`,
  `cwf-project.json`. Acceptance: a changeset touching any of those paths still
  counts as production (not discounted) under the seeded config.
- **FR4 — Raised built-in default cap**: With no `--max-lines` flag and no
  `security.review.max-lines` config, the effective cap is 1000 (was 500). This
  requires updating both the executable constant (`$DEFAULT_MAX_LINES`,
  `security-review-changeset:101`) **and** the non-interpolating hand-maintained
  `500` literal in the file's `#` header banner (`:34`) in lockstep. Acceptance:
  a 1000-production-line changeset passes; 1001 exits 2; no stale `500` remains
  in the helper.
- **FR5 — Unchanged precedence**: Resolution stays `--max-lines` >
  `security.review.max-lines` > built-in default. Acceptance: an explicit
  `--max-lines=N` and a configured `security.review.max-lines` each still
  override the new default, in that order.
- **FR6 — Dog-food the new default**: This repo's installed
  `implementation-guide/cwf-project.json` currently sets an explicit
  `security.review.max-lines: 1000` that becomes redundant once the built-in is
  1000. Drop that explicit key so the repo falls through to and exercises the new
  built-in default; retain its CWF-specific `max-lines-exclude-paths`
  (`t/**`, `implementation-guide/**`).
- **FR7 — Spec doc kept current**: `CWF-PROJECT-SPEC.md` frames the `security`
  block as keys that merely "appear in the dog-fooded config". Once
  `security.review` is template-seeded that framing is stale — update the spec to
  document the seeded block (including `max-lines` and the exclude default).

### Out of Scope
- New Perl-side path matching or a new "deweight" code path — Task 218's git
  `:(glob,exclude)` mechanism already deweights; this task only supplies defaults
  and the cap constant.
- Any config surface outside `security.review.*`.
- Validator changes: `security.review` remains a pass-through (unvalidated) key.

### User Stories
- **As a** CWF user starting a project **I want** the review cap to ignore test
  and generated churn by default **so that** I do not hand-tune excludes before
  the first review passes.
- **As a** CWF user reviewing a long-running task **I want** a 1000-line default
  cap **so that** a full-baseline diff does not spuriously trip the guard.

## Non-Functional Requirements
### Usability (NFR2)
- Seeded-glob intent is recorded in a sibling `_security-review-note` key
  (strict JSON has no comments — mirrors the existing `_sandbox-note` pattern) so
  a user can see why the paths are excluded and safely edit the set.

### Maintainability (NFR3)
- The default cap has one executable definition (`$DEFAULT_MAX_LINES`); the only
  other copy is the documented non-interpolating header-banner literal, updated
  in lockstep (FR4). The seeded exclude set has one canonical definition (the
  template), not duplicated across skills.

### Security (NFR4)
- Both changes are deliberate **fail-open** tradeoffs and are accepted as such:
  (a) excluding a path exempts any genuine production code under it from the cap;
  (b) raising the default cap widens the "diff too large to auto-review" backstop
  for every project that has not set its own `max-lines`, diluting reviewer
  attention on 501–1000-line diffs. Mitigations: the seeded set is conservative
  (test/generated/vendored + scoped doc-markdown only), the security-path
  guardrail (FR3) is testable, and doc-markdown is non-blanket (FR2).
- No new external input, env-var, or command-execution surface: seeded globs are
  CWF-authored constants passed to git's pathspec engine via list-form exec
  (no shell); the prompt-injection surface is unchanged.

### Reliability (NFR5)
- Fail-safe preserved: a malformed exclude pattern still degrades to git-fatal →
  helper exit 1, never a silent miscount. Seeded globs are verified valid so this
  path is not entered by default.
- Ecosystem edge case: when seeded globs match no path in the target project
  (e.g. a layout using none of the conventional dirs), the cap simply counts
  normally — safe by omission. The "ignore test churn" benefit is therefore
  best-effort per layout, not guaranteed for every ecosystem.

## Constraints
- Perl core-only; git owns all glob matching (no Perl-side path classification).
- `security-review-changeset` is hash-tracked — any edit requires a same-commit
  `.cwf/security/script-hashes.json` refresh (`hash-updates.md`).
- Must not alter Task 218's config key names.

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — config seed + cap constant + doc sync.
- [ ] **Risk**: high-risk isolation needed? No.
- [ ] **Independence**: separable parts? No.

No decomposition.

## Acceptance Criteria
- [ ] AC1 (FR1): a changeset touching only seeded test/generated/vendored paths
      counts 0 production lines; all seeded globs parse (helper never exits 1 on a
      default-config read).
- [ ] AC2 (FR2): doc-markdown exclusion is scoped (a top-level/doc `*.md` is
      discounted) but a production `*.md` outside doc locations still counts.
- [ ] AC3 (FR3): a changeset touching `.cwf/scripts/`, `.cwf/hooks/`,
      `.cwf/security/`, or `cwf-project.json` still counts as production.
- [ ] AC4 (FR4): default cap is 1000 — 1000 passes, 1001 exits 2, with no
      flag/config; no `500` literal remains in the helper.
- [ ] AC5 (FR5): `--max-lines` and `security.review.max-lines` still override, in order.
- [ ] AC6 (FR6): this repo's config no longer sets `security.review.max-lines`;
      its exclude-paths are retained; `cwf-manage validate` exits 0.
- [ ] AC7 (FR7): `CWF-PROJECT-SPEC.md` documents the seeded `security.review` block.
- [ ] AC8 (FR1/FR5): new template differs from the prior template only by the
      added `security.review` block + `_security-review-note`.
- [ ] AC9 (constraint): edited hashed file's `script-hashes.json` entry refreshed
      in the same commit; `cwf-manage validate` exits 0.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
