# Always review docs regardless of line cap - Implementation Plan
**Task**: 223 (feature)

## Task Reference
- **Task ID**: internal-223
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/223-always-review-docs-regardless-of-line-cap
- **Template Version**: 2.1

## Goal
Implement Always review docs regardless of line cap following the approved design and requirements.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cwf/scripts/command-helpers/security-review-changeset` [hash-tracked, 0500] —
  add `doc_pathspec()` (KD4/KD5); union its exclude into the cap count; write the
  doc-scoped `.out` + second confirmation line on over-cap (KD2); update ALL
  "one confirmation line" self-contract sites: header Output/Exit prose (64-65,
  75-81) AND `print_usage` POD (356-357) (misalignment F1).
- `.claude/skills/cwf-implementation-exec/SKILL.md` [hash-tracked] — rewrite the
  Step 8 `exit 2` branch (line 66) and the best-practice gate (line 77) for the
  deferred-docs path; add the `## Changeset Review — Code (Deferred)` /
  `**State**: deferred` record.
- `.claude/skills/cwf-testing-exec/SKILL.md` [hash-tracked] — same for the
  narrower 2-reviewer MAP (Step 8 line 60; bp gate line 71).

### Supporting Changes
- `.cwf/docs/skills/security-review.md` — exit-2 contract prose (lines 47-51);
  the "prints one confirmation line" wording at line 28 (misalignment F1);
  reconcile the always-on base-path-markdown discount with the *configurable*
  `max-lines-exclude-paths` (line 47 frames discounting as purely configurable —
  misalignment F2); counting basis (numstat = edit-lines, already true) and
  cap-value rationale (FR3, backlog fold-in); DRY home for the deferred-section
  contract (improvements F3, see Step 8).
- `.cwf/templates/cwf-project.json.template` — extend `_security-review-note`
  (line 32) to state that base-path task-doc markdown is ALSO discounted
  always-on, independent of the configurable list (misalignment F2). [check if
  hash-tracked; refresh if so]
- `.cwf/security/script-hashes.json` — refresh sha256 for the hashed files in
  THIS commit (hash-updates.md).
- `t/security-review-changeset.t` — extend (base-path exclusion, guards,
  deferred artefact).
- `t/exec-changeset-reviewers.t` — extend if it models skill Step-8 recording;
  confirm scope during exec.

<!-- No named symbols are deleted (doc_pathspec is new; existing subs unchanged).
     Omitting the Deletes line deliberately. -->

## Implementation Steps
TDD order (Test → minimal impl → green). Anchors are current line numbers.

### Step 1: Pre-flight — validator surface for the new State token (KD3 check)
- [ ] Grep `t/validate-security.t`, `t/validate-security-coverage.t`,
      `t/validate-workflow.t` and any `security-review-classify` consumer for an
      enumerated set of review-section `**State**:` tokens. Record whether
      `deferred` on a NON-classifier section trips anything. If it does, extend
      that validator in the same commit; if not, note "no section-State
      enumeration — `deferred` is free-form skill prose".

### Step 2: Tests first — `t/security-review-changeset.t`
- [ ] **Test isolation (misalignment F2)**: the harness MUST write its own
      `cwf-project.json` with a non-default `base-path` (e.g. `docs-tree`) AND an
      explicit `max-lines-exclude-paths` that does NOT already cover it —
      otherwise this repo's real `implementation-guide/**` / seeded `*.md` excludes
      mask the new discount and the assertions prove nothing.
- [ ] **Cap exclusion**: with `directory-structure.base-path` = a non-default
      value (e.g. `docs-tree`), markdown under it is discounted; a code file
      under it still counts (markdown-scoped, not tree); a `.cwf/**/*.md` path is
      NEVER discounted — keep this as a HARD assertion (security: it's the control
      stopping `base-path: .cwf` from discounting CWF's own security docs).
- [ ] **Guards (fail-first)**: base-path ∈ {absent, empty, `.`, `./`, `foo/`,
      `./foo`, `../x`, `/abs`, `.cwf`, `**`, `a*b`, `a,b`} each ⇒ no exclude
      (docs count as production); malformed emits a `carp`/STDERR diagnostic,
      absent/empty is silent.
- [ ] **Deferred artefact**: an over-cap changeset writes
      `…-<step>-docs.out` containing only the doc markdown diff, prints
      `wrote <D> doc lines to <path>`, still `warn`s `cap exceeded:` and exits 2.
- [ ] **No-docs over-cap**: over-cap with an empty doc set writes no doc line
      (or `0 doc lines`) — the skill treats it as "no docs".

### Step 3: `doc_pathspec()` in the helper (KD4/KD5)
- [ ] Add sub reusing `CWF::Versioning::read_config()` (as `max_lines_exclude_paths`
      does, lines 553-556). Read `directory-structure.base-path`.
- [ ] Apply the KD5 guard: positive charset **`\A[A-Za-z0-9._/-]+\z`** (NOT
      `^…$` — `$` matches before a trailing newline, letting `"x\n"` through a
      security validator; Perl regex best-practice #149/#150); reject `.`/`./`,
      leading `./`, trailing `/`, `//`, `..`, absolute, NUL, `.cwf`(+prefix),
      repo-root. Pass ⇒ return hashref `{exclude, include}`; else `carp`
      (malformed) or silent (absent/empty) then bare `return;`.
- [ ] **Memoize (all 5 reviewers)**: call `doc_pathspec()` ONCE near line 305,
      hold the hashref (or undef) in a lexical `$doc`, and reuse it in both Step 4
      and Step 5 — one `read_config()`, one guard pass, one `carp` at most, and
      the include/exclude provably derive from the same read (KD4 "identical by
      construction"). Do NOT re-call it in the over-cap block.

### Step 4: Wire the exclude into the cap count (FR1)
- [ ] At the exclude assembly (line 305), union `$doc->{exclude}` (when `$doc`
      is defined) into `@exclude` before `count_production_lines` (line 306).
      Order is irrelevant to git; keep seeded excludes first for readability.

### Step 5: Deferred doc artefact on over-cap (KD1/KD2)
- [ ] In the `$production > $opt{max_lines}` block (lines 317-320), BEFORE
      `exit 2`, when `$doc` is defined: `git diff <anchor> -- $doc->{include}`
      via `capture_git` (list-form; runs inside the intent-to-add window from
      lines 249-257 so untracked task markdown is captured); normalise the diff
      to a trailing newline exactly as the primary path (helper:290) and count
      `<D>` via `tr/\n//` — the **raw diff-line** basis matching `<N>` (helper:291),
      NOT numstat — so `D==0` reliably means an empty doc diff (robustness F2);
      `atomic_write_text` to
      `$scratch/security-review-changeset-$opt{wf_step}-docs.out` (mode 0600).
- [ ] **Distinguishing contract (robustness F1)** — the line's presence encodes
      whether the feature engaged:
      - `$doc` **defined** (base-path valid): ALWAYS print
        `security-review-changeset: wrote <D> doc lines to <abs>`, even when
        `D==0` (configured, but this changeset has no task-doc markdown).
      - `$doc` **undef** (base-path absent/malformed/adversarial): print NO doc
        line — docs were not separable, so they counted toward the cap.
      This lets the skill tell "configured, no docs" (`0` line) from "docs not
      separable" (absent line) rather than mislabel real markdown as "no docs".
- [ ] `capture_git` failure exits 1 (safe collapse — do not rescue).
- [ ] Update header prose: Output/stdout (64-65) → note the second line on cap
      breach; Exit (80-81) → exit 2 now also writes the doc `.out` + second line.

### Step 8a: Shared deferred-section contract in `security-review.md` (DRY, improvements F3)
- [ ] Add ONE canonical description of the deferred path to `security-review.md`:
      the doc-confirmation-line parse, the `## Changeset Review — Code (Deferred)`
      / `**State**: deferred` section shape, and the line-present-with-0 vs
      line-absent distinction (robustness F1). Both skills reference it rather than
      restating the mechanics, so the two copies can't drift.

### Step 6: exec skill Step 8 — implementation-exec (FR2/FR4)
- [ ] Replace the `exit 2` branch (line 66), pointing at the Step-8a shared
      contract: doc line present with `D>0` ⇒ launch security + 3 lens agents on
      the doc `.out`; present with `D==0` ⇒ those four `no findings: no docs to
      review`; **line absent** ⇒ `no findings: docs not separable (base-path
      unconfigured)` (robustness F1 — do NOT claim "no docs"). In ALL cases emit
      `## Changeset Review — Code (Deferred)` / `**State**: deferred` + the reused
      `cap exceeded: <P> … > <cap>` detail.
- [ ] Revise the bp gate (line 77) so the deferred doc `.out` counts as a usable
      changeset (bp launches on docs too — keeps the MAP 5-reviewer).

### Step 7: exec skill Step 8 — testing-exec
- [ ] Same as Step 6 for the 2-reviewer MAP: `exit 2` branch (line 60), bp gate
      (line 71), plus the `deferred` section — via the Step-8a shared contract.

### Step 8: Doc — `.cwf/docs/skills/security-review.md`
- [ ] Rewrite the exit-2 contract (lines 47-51) + the "one confirmation line"
      wording (line 28): over-cap now reviews docs + records `deferred` for code.
- [ ] **Reconcile the two discount layers (misalignment F2)**: line 47 frames
      markdown-discounting as purely configurable; state that base-path task-doc
      markdown is ADDITIONALLY discounted always-on (union with the configurable
      `max-lines-exclude-paths`), and why (CWF never bills a consumer's cap for
      CWF-authored process docs).
- [ ] Document the counting basis (numstat = edit-lines, already the case —
      closes backlog axis 2) and the cap-value rationale (1000, raised Task 221).
      Empirical calibration (axis 1) noted scope-flagged per FR3/AC3b.

### Step 9: Hash refresh + validation
- [ ] Refresh sha256 for the hashed files in `.cwf/security/script-hashes.json`
      (same commit; helper perms clamp to recorded 0500). Include the template if
      it is hash-tracked.
- [ ] `prove t/security-review-changeset.t t/exec-changeset-reviewers.t`.
- [ ] `.cwf/scripts/cwf-manage validate` clean.
- [ ] Output smoke (AC4 — source grep alone insufficient): force an over-cap run,
      grep the generated exec artefact for `**State**: deferred` AND absence of
      stale "exit 2 → error/no agents" wording. Grep the whole helper + both
      skills + security-review.md for the now-false "one confirmation line"
      wording (all sites: header 64-65, POD 356-357, doc line 28).

### Step 10: Backlog follow-ups (note, do not implement here)
- [ ] `template-copier-v2.1:194` snake_case `base_path` latent bug (never reads a
      custom base-path). And: three independent `read_config()` sites in the helper
      now — a shared cached-config read is the clean fix but out of this scope.

## Code Changes
Sketches are in `c-design-plan.md` (KD4/KD5 `doc_pathspec()`, KD2 output
contract). No additional code sketch needed here — the design carries them.

## Test Coverage
**See e-testing-plan.md for complete test plan** (this plan lists the cases;
e- formalises them as TCs with expected results).

## Validation Criteria
**See e-testing-plan.md.** Gate: all `t/` green, `cwf-manage validate` clean,
AC4 output-smoke grep passes.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Plan Review (5 reviewers + 2 resolvers)
Applied: `\A…\z` (not `^…$`) anchors on the charset guard — `$` matches before a
trailing newline, a porous security-validator hole (Best-practice, also corrected
in c-design KD5); memoize `doc_pathspec()` to one call/one `read_config`/one
`carp` (all 5 reviewers); the present-0 vs absent doc-line distinguishing contract
so unconfigured base-path never mislabels real markdown as "no docs" (Robustness
F1); `<D>` on the raw diff-line basis matching `<N>`, not numstat (Robustness F2);
DRY the deferred-section contract into security-review.md (Improvements F3); two
more stale "one confirmation line" sites — POD 356-357 and security-review.md:28
(Misalignment F1); reconcile the always-on base-path discount with the
configurable list + test-isolation against this repo's own excludes (Misalignment
F2); keep `.cwf/**/*.md never discounted` a HARD test assertion (Security).
Backlog notes: copier snake_case bug, shared cached-config read.
Adjudicated noise: the three mechanical path-advisory findings (`foo/`, `./foo`,
`../x`) are adversarial test-input examples, not paths.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 223
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All steps executed in TDD order. Only the helper needed a same-commit sha256 refresh:
the exec skills, template, and doc are NOT in `script-hashes.json`, contrary to this
plan's "[hash-tracked]" annotations on the skills.

## Lessons Learned
Trust the hash manifest over assumptions about what is hash-tracked — `.claude/skills`
are not in `script-hashes.json` in this repo, so the plan's tracking notes were wrong.
