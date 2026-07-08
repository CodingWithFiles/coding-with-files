# Always review docs regardless of line cap - Design
**Task**: 223 (feature)

## Task Reference
- **Task ID**: internal-223
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/223-always-review-docs-regardless-of-line-cap
- **Template Version**: 2.1

## Goal
Design the "docs always reviewed, cap gates only code" contract across the
`security-review-changeset` helper and the two exec skills, plus the FR1
base-path markdown cap-exclusion — reusing existing machinery, adding no new
runtime engine.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### KD1 — Reframe the cap: docs uncapped, code gated (satisfies FR2/FR3)
- **Decision**: the production count already discounts docs (FR1); the cap
  therefore gates the **code** portion only. On over-cap, instead of "record
  error, launch nothing", the helper writes a **doc-scoped changeset artefact**
  and the exec skills review it — code review is *deferred*, docs are *always*
  reviewed.
- **Rationale**: directly implements the goal; expresses the backlog's
  "warn/hard-stop split" as graceful degradation rather than a bolt-on.
- **Trade-offs**: the over-cap path does more work (one extra `git diff` +
  agent launches) than today's immediate error; acceptable — it is the point.
- **Security posture note** (per security review): the deferred-doc `.out`
  carries the SAME untrusted-markdown-content posture as today's full `.out`
  (`security-review.md:13-14`); the deferred path launches the same agents on the
  same kind of artefact — no new prompt-injection surface, coverage strictly increases.

### KD2 — Extend the existing `exit 2` contract, no new exit code (FR2/FR4)
- **Decision**: keep `exit 2` = "code exceeds cap", but extend its contract: on
  `exit 2` the helper ALSO writes `…-<step>-docs.out` (diff limited to the FR1
  markdown pathspec) and prints a second confirmation line
  `security-review-changeset: wrote <D> doc lines to <doc-abs-path>` (`D` = doc
  line count). The full `.out` is still written unchanged (record/inspection).
  The banner's code-line count reuses the **existing** `cap exceeded: <P>
  production lines > <cap>` stderr line (helper:318) the skills already capture —
  no third stdout line is invented (per improvements review).
- **Rationale**: no exit-code renumber ⇒ old skills degrade safely (unknown line
  ignored, exit 2 still reads as today's error). Reuses the atomic-write and
  numstat paths already present. Fewer moving parts than a new exit 3.
- **Contract-prose update (per misalignment review)**: the helper's own
  "**exactly one** confirmation line" self-contract (header:64; `print_usage`
  POD:356-357) contradicts the new second line — update both in the same commit,
  and include that wording in AC2d's stale-wording grep set.
- **Trade-offs**: `exit 2` is semantically richer (nonzero but now actionable);
  mitigated by the explicit second confirmation line the skill keys on.

### KD3 — Deferral = an explicit distinct State, not only a prose banner (FR2/AC2b)
- **Decision**: the doc-review agents emit their normal `cwf-review` verdicts
  (no findings/findings/error) on the doc artefact — those verdicts describe the
  *docs*. The skill ADDITIONALLY emits a dedicated record
  **`## Changeset Review — Code (Deferred)`** carrying a first-class
  **`**State**: deferred`** line plus the reused `cap exceeded: <P> … > <cap>`
  detail. The deterministic classifier and its `no findings|findings|error`
  token set are UNCHANGED (the `deferred` State is skill-authored, on its own
  section — not a classifier token).
- **Rationale (per robustness F2)**: a prose-only banner leaves the five reviewer
  sections showing `**State**: no findings`, which a State-keyed grep reads as a
  pass. A dedicated section with `**State**: deferred` makes the deferral visible
  to State-based readers, not just prose readers — satisfying "distinct State,
  never mistaken for a pass" structurally.
- **Implementation check (FR4 coherence)**: verify whether any validator
  enumerates allowed review-section State tokens (`validate-security.t`,
  `validate-security-coverage.t`, workflow validators). If so, extend it to admit
  `deferred` on the code-review record — same-commit.
- **Trade-offs**: one extra section on the deferred path; justified by the
  testability it buys (AC4 greps the State line, not only prose).

### KD4 — Single source of truth for the doc pathspec (FR1/FR2 tie)
- **Decision**: one helper sub `doc_pathspec()` derives the markdown pathspec from
  `directory-structure.base-path` and returns a **hashref** (context-safe, per
  best-practice review) with both forms: `{ exclude =>
  ':(glob,exclude)<bp>/**/*.md', include => ':(glob)<bp>/**/*.md' }` — or a bare
  `return;` on fail-safe. The exclude feeds the cap count (unioned with the seeded
  excludes); the include feeds the doc-scoped `git diff`. FR1's cap-excluded set
  and FR2's reviewed doc set are therefore identical by construction.
- **Rationale**: eliminates drift between "what's discounted" and "what's
  reviewed on deferral" (robustness ask); markdown-only closes the cap-bypass
  vector (security ask — code under the task tree still counts). Hashref (not a
  bare list) prevents a scalar-context caller silently taking one element.

### KD5 — Bounded, fail-safe base-path derivation (FR1/AC1c, NFR4/NFR5)
- **Decision**: read the real kebab key `directory-structure.base-path` via the
  existing eval-guarded `read_config()`. Return **no** exclude (⇒ docs count as
  production, the stricter direction) unless the value passes ALL of:
  - **positive charset allowlist** `\A[A-Za-z0-9._/-]+\z` (per security review —
    this rejects glob/pathspec-magic `* ? [ ] ( ) : ,` that would otherwise
    expand the exclude repo-wide, e.g. `**` ⇒ discount all markdown = cap-bypass.
    `\A`/`\z` NOT `^`/`$`: `$` matches before a trailing newline, so `^…$` would
    accept `"docs-tree\n"` — a porous-anchor hole in a security validator, per
    Perl best-practice regex #149/#150);
  - not absent/empty, not `.`/`./`, no leading `./`, no trailing `/`, no `//`
    (per robustness F4 — keep the include/exclude pathspecs well-formed);
  - no `..`, not absolute, does not name/prefix `.cwf` or resolve to the repo root.
  Absent/empty ⇒ silent fail-safe; present-but-**malformed** (fails a check) ⇒
  `carp` a **diagnostic** message (which key, the rejected value, that
  counting-as-production is the fallback — per best-practice guideline 177) then
  fail-safe. The derived pathspec routes through the same list-form git argv the
  existing exclude reader uses (no shell).
- **Rationale**: over-exclusion is the dangerous failure; every ambiguity fails
  toward counting. Guardrail (`.cwf/*`, `cwf-project.json` never discounted)
  holds structurally: the exclude is markdown-under-base-path, the charset guard
  blocks wildcard escape, and adversarial base-paths are rejected.
- **Trade-off / note**: do NOT reuse `template-copier-v2.1:194`'s snake_case
  accessor (`directory_structure.base_path`) — it never matches the kebab key
  and silently defaults; that is a latent copier bug (backlog follow-up).
  `carp`-and-continue (vs `die`) on malformed config is a deliberate deviation
  from PBP-171, justified by the fail-toward-counting safety axis.

## System Design
### Components touched (the complete `exit 2` consumer set — FR4)
- **`security-review-changeset` (helper)** [hash-tracked, refresh sha256]:
  new `doc_pathspec()` sub (KD4/KD5); union its exclude into
  `count_production_lines`; on over-cap write the doc-scoped `.out` + print the
  doc confirmation line (KD2); update the "exactly one confirmation line" prose
  at header:64 and `print_usage` POD:356-357 (KD2 misalignment finding). The doc
  diff MUST run inside the intent-to-add window (helper:249-257 add `-N`, `END`
  restores) so untracked task markdown is captured (robustness F5).
- **`cwf-implementation-exec/SKILL.md` Step 8** [hash-tracked]: replace the
  `exit 2 → error, no agents` branch (line 66) AND revise the **best-practice**
  gate (line 77) — on the deferred doc `.out` the bp reviewer must also treat it
  as a usable changeset so the MAP stays 5-reviewer (robustness F1 / misalignment
  M1). Behaviour: parse the doc confirmation line → doc lines > 0 ⇒ launch the
  5-reviewer MAP on the doc `.out` + emit the `deferred` code-review section;
  0 ⇒ five sections `no findings: no docs to review` + the `deferred` section,
  no agents.
- **`cwf-testing-exec/SKILL.md` Step 8** [hash-tracked]: same change, narrower
  2-reviewer MAP (line 60) with the sibling bp gate (line 71).
- **`.cwf/docs/skills/security-review.md`** [not hash-tracked]: update the
  exit-2 contract prose (lines 47-51); document the counting basis (numstat
  added+deleted = edit-lines, already true — closes backlog axis 2) and the
  cap-value rationale (FR3).
- **NOT changed — documented non-consumers**:
  - *SubagentStop verdict guard*: name-matched to `cwf-security-reviewer-changeset`;
    fires only when that agent runs. On deferral we DO run it (on docs) ⇒ works
    unchanged; on no-docs we don't run it ⇒ never fires. No change.
  - *Exec templates f/g*: the Changeset Reviews section is skill-generated, not
    templated — no exit-2 wording present. No change.

### Data flow (over-cap / deferred path)
1. Skill runs `security-review-changeset --wf-step=<step>`.
2. Helper writes full `.out`; computes production count with
   `@exclude = seeded ∪ doc_pathspec.exclude`.
3. production > cap ⇒ helper writes `…-docs.out` (`git diff <anchor> -- <doc
   include-pathspec>`, inside the intent-to-add window), prints the doc
   confirmation line, `warn`s the `cap exceeded: <P> …` line, exits 2. If that
   doc `git diff` itself fails, `capture_git` exits 1 (collapses exit-2→exit-1,
   the safe/surface direction — the impl must NOT rescue it into a pass; F5).
4. Skill's exit-2 branch reads the doc line: docs>0 ⇒ 5/2-reviewer MAP on
   `…-docs.out` (all reviewers incl. bp), record per-reviewer doc verdicts + the
   `## Changeset Review — Code (Deferred)` section (`**State**: deferred`).
   docs==0 ⇒ five sections `no findings: no docs to review` + the `deferred`
   section, no agents (AC2c: no spurious `error`, no empty launch).

## Interface Design
### Helper CLI / output contract (delta only)
- **Unchanged**: args, the primary `wrote <N> lines to <abs-path>` line, exit 0
  and exit 1 semantics.
- **New on exit 2**: a second stdout line
  `security-review-changeset: wrote <D> doc lines to <doc-abs-path>` and the
  `…-<step>-docs.out` file. Absent when the doc set is empty (skill treats a
  missing/zero-count line as "no docs").

### `doc_pathspec()` (internal)
```
return;  # bare, on fail-safe (absent/invalid/adversarial base-path)
# otherwise:
return { exclude => ':(glob,exclude)<bp>/**/*.md',
         include => ':(glob)<bp>/**/*.md' };   # hashref, context-safe
```

## Constraints
- Perl core-only; POSIX; hash-tracked helper + skills → same-commit sha256
  refresh (0500 ceiling for the helper).
- Reuse existing `read_config()`, `capture_git()` list-form argv, `atomic_write_text`,
  numstat counting — no new engine (NFR3).
- Dog-food a non-default `base-path` in tests, not only `implementation-guide`.

## Decomposition Check
Design confirms the plan/requirements conclusion — one task. The change set is
tight (1 helper + 2 skills + 1 doc + 2 test files) and the SubagentStop guard and
templates need no change, shrinking the surface below the requirements estimate.
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ parallel concerns? No — layers of one contract change.
- [ ] **Risk**: Isolation needed? No — contract risk handled by KD2's safe-degrade.
- [x] **Independence**: FR1 vs FR2 separable but share the helper; not decomposing.

## Validation
- [ ] Design satisfies FR1 (KD4/KD5), FR2 (KD1/KD2/KD3), FR3 (KD1 + security-review.md)
- [ ] All exit-2 consumers enumerated; non-consumers justified (SubagentStop guard, templates)
- [ ] Backward-compat: old skill + new helper degrades safely (KD2)

## Plan Review (5 reviewers + 2 resolvers)
Applied: charset allowlist `^[A-Za-z0-9._/-]+$` closing the wildcard cap-bypass +
`./`/trailing-`/` normalisation (Security, Robustness F4); reshaped KD3 to a
first-class `**State**: deferred` code-review section, not prose-only, so a
State-keyed reader sees the deferral (Robustness F2) + validator-extension check;
revised the separately-gated best-practice reviewer to fire on the deferred doc
`.out`, keeping the MAP 5/2 (Robustness F1, Misalignment M1); added the helper's
"exactly one confirmation line" self-contract to the update+grep set (Misalignment
M2); `doc_pathspec()` returns a hashref (Best-practice); renamed the `M` symbol
collision to `D`/`C` and reused the existing `cap exceeded` stderr for the banner
(Improvements); noted the intent-to-add ordering window + safe exit-2→exit-1
collapse (Robustness F5); diagnostic carp text (Best-practice).
Adjudicated noise: the two mechanical `SKILL.md` path-high findings are false —
the files exist under `.claude/skills/`.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 223
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
KD1–KD5 implemented as designed. The `\A…\z` anchor fix (surfaced in design review)
shipped; the documented non-consumers (SubagentStop guard, exec templates) were
confirmed unchanged in exec.

## Lessons Learned
The design-review "non-consumer" determination (guard/templates) was load-bearing —
enumerating exit-2 consumers up front is what shrank the surface below the plan's budget.
