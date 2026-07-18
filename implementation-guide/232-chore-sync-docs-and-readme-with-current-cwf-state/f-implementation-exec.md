# Sync docs and README with current CWF state - Implementation Execution
**Task**: 232 (chore)

## Task Reference
- **Task ID**: internal-232
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/232-sync-docs-and-readme-with-current-cwf-state
- **Template Version**: 2.1

## Goal
Apply the doc corrections from d-implementation-plan.md so README and the maintainer/spec
docs match the implementation that ships today. Documentation-only change set.

## Ground-truth re-verification (Step 1 — divergence rule)
Recounted at exec; **matches** the d-plan exactly (no divergence, plan numbers authoritative):
- `.claude/skills/`: **21 dirs = 20 `/cwf-*` command skills + `test-cwf-skill`** (internal),
  plus 2 loose `.md` fragments (`current-task-wf.md`, `current-task-wf-verbose.md`).
- Helper scripts: **27** non-`.d` entries.
- Workflow phase docs: **10**, named by phase (not lettered).
- Release: `last_released = v1.1.231`; latest git tag `v1.1.230` (v1.1.231 untagged).
- Recorded permission modes span `0700`/`0500` (executables) and `0444` (read-only data);
  `hash-updates.md` confirms the **upper-bound / clamp-down** ceiling model.

## Actual Results

### Step 2: CLAUDE.md (3 edits) — DONE
- **Security-model line (L130)**: reworded to the ceiling model — recorded `permissions`
  are an upper bound; `validate` flags a file only when *more* permissive than recorded,
  `fix-security` clamps down (`actual & recorded`); modes range `0700`/`0500`→`0444`.
  **Verified against `hash-updates.md` L20** and the recorded-mode census (14×`0444`,
  40×`0500`, 8×`0700`) before writing — the security-review caveat is satisfied.
- **Skill list**: added `/cwf-current-task` under **Core Skills** (task-stack context
  tracking, already referenced at L138) and `/cwf-backlog-manager` under **Utility Skills**
  (backlog management), each in the existing grouping — not appended loosely. `cwf-manage`
  kept labelled as the management **script**.
- **Version example (L136)**: genericised the `git describe` example to
  `format <tag>-<commits-since>-g<short-sha>`, e.g. `v1.1.x-<n>-g<sha>` — shape preserved,
  no bare-tag collapse.

### Step 3: DESIGN.md (2 edits) — DONE
- **Permission framing (L79–80)**: aligned to the same ceiling model (recorded ceiling
  `0700`/`0500`/`0444`, upper bound flagged only when more permissive). The nearby
  `fix-security` prose (L84–87) already read consistently and was left untouched.
- **Version example (L96)**: genericised the `git describe` example to the same
  `<tag>-<commits-since>-g<short-sha>` / `v1.1.x-<n>-g<sha>` shape.

### Step 4: README.md (3 edits + owner-opted JSON refresh) — DONE
- **Plan/exec overstatement ×3** (L65, L118–119, L154): reworded to the hedged form
  COMMANDS.md uses ("where applicable" / "where a stage benefits from it — implementation
  and testing"). Only implementation and testing have separate `-exec` phases.
- **Left L26** (file-structure line) untouched per the robustness-review caveat.
- **`cwf-project.json` sample (L215–216)**: refreshed `major_minor` `v1.0`→`v1.1` and
  `last_released` `v1.0.0`→`v1.1.232` per the owner decision below.

### Step 5: CWF-PROJECT-SPEC.md (2 edits) — DONE (owner opted in)
- **`last_released` samples (L52, L122)**: refreshed `v1.1.188`→`v1.1.232` per the owner
  decision. `major_minor` at L121 already read `v1.1` (no change).

### Step 6: Grep sweep (sole verification) — PASS
- Stale-string scan (`minimum 0500`, `v1.1.187`, `v1.1.188`, `gcea1c19`, `"v1.0.0"`,
  `"major_minor": "v1.0"`, `always split`, `separated for each stage`) → **0 hits**.
- All 20 `/cwf-*` command names in CLAUDE.md map to real skill dirs; none omitted, none
  invented; `test-cwf-skill` correctly absent; `cwf-manage` labelled a script.
- `git describe` examples keep the `-<n>-g<sha>` shape (no bare tag).
- Config-value samples are concrete `v1.1.232` (README L216, SPEC L52/L122).
- Changed tracked files: exactly CLAUDE.md, DESIGN.md, README.md, CWF-PROJECT-SPEC.md.
- None of the four edited paths appears in `.cwf/security/script-hashes.json` (docs-only,
  no hash refresh). COMMANDS.md and INSTALL.md left unchanged (audited-clean).

## Owner decision (resolved at plan review)
The two `cwf-project.json` **config-value** samples cannot be genericised (they must match
`/^v\d+\.\d+\.\d+$/`). Surfaced at plan review as leave-vs-refresh; the owner chose to
**refresh to `v1.1.232`** — the version this task bumps `last_released` to at retrospective
and the tag used before the public push, so the samples are accurate rather than re-stale.
This brought CWF-PROJECT-SPEC.md (and the optional README JSON block) into the change set.
The `git describe` **format** examples stay genericised (they illustrate output shape, not a
release tag) — only the config-value samples take the concrete number.

## Blockers Encountered
None.

## Changeset Reviews (Step 8 — 5-reviewer MAP, all parallel)
Prep: `security-review-changeset` exit 0, 866 lines (32 production) → security + 3 lens
agents launched; `best-practice-resolve` exit 0, 3 corpora matched → bp agent launched.
Classifier (`security-review-classify`) over the scratch dir returned all five as
`no findings`; launched set == classified set (no reviewer dropped).

### Security Review
**State**: no findings

Documentation-only sync; edits touch four prose files (CLAUDE.md, CWF-PROJECT-SPEC.md,
DESIGN.md, README.md) plus the task workflow docs. No shell/Perl/hook/skill/template/
`script-hashes.json` change. Categories (a)–(e) all clear. The reworded security prose
(recorded `permissions` as an upper bound; `validate` flags only *more*-permissive files;
`fix-security` clamps `actual & recorded`) verified consistent with the ceiling model and
corrects the prior misleading "minimum 0500" claim.
```cwf-review
state: no findings
summary: Documentation-only sync (4 prose files + task workflow docs); no code, command, input-flow, or integrity surface touched.
```

### Best-Practice Review
**State**: no findings

Three corpora resolved (golang, postgres, perl — all readable, not an error case). Each
governs writing source code in a specific language; none covers CWF's own Markdown prose,
which is the entire changeset. No applicable code artefact.
```cwf-review
state: no findings
summary: Docs-only changeset (Markdown prose + CWF wf-step files); no Go/Perl/Postgres code for the resolved best-practice corpora to apply to.
```

### Improvements Review
**State**: no findings

No source/helper/template surface to duplicate. The security-model and `git describe`
restatements are brief summary-doc surfaces referencing the canonical `hash-updates.md`,
not clones; README reuses COMMANDS.md's hedged plan/exec phrasing. Nothing to reduce.
```cwf-review
state: no findings
summary: Docs-only sync; no code/helper duplication, summary-doc restatements are canonical-referenced not cloned.
```

### Robustness Review
**State**: no findings

The load-bearing security-model rewrite matches `hash-updates.md` L20/L22 and the
`cwf-manage` clamp logic (`$want = $actual_perms & $recorded`) exactly — a robustness
improvement over the prior inverted "minimum 0500" floor. Both added skills resolve to real
dirs; genericised `git describe` keeps the `-<n>-g<sha>` shape. No fragile claim.
```cwf-review
state: no findings
summary: Docs-only sync; security-model rewrite verified accurate against hash-updates.md and cwf-manage clamp logic, and corrects a previously inverted invariant.
```

### Misalignment Review
**State**: no findings

Every reworded fact traces to an existing single source of truth: the ceiling model
(`hash-updates.md`), the real skill interfaces (`cwf-current-task`, `cwf-backlog-manager`
syntax), the `git describe` format, and COMMANDS.md's hedged wording. Config-value samples
kept concrete (schema requires `/^v\d+\.\d+\.\d+$/`) rather than genericised — the correct
distinction. No reinvented abstraction.
```cwf-review
state: no findings
summary: Docs sync faithfully reuses existing conventions (hash-updates ceiling model, real skill interfaces, git-describe format); no reinvented abstractions.
```

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met (skill-list maps to real skills;
      quantitative claims recounted; no stale version assertion; architecture docs current;
      grep sweep clean — no generated-artefact smoke test, removed at plan review as N/A)
- [x] b/c-phase criteria — N/A (chore skips requirements/design)
- [x] No planned work deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
A documentation invariant can be *inverted*, not just stale ("minimum 0500" floor vs the real
ceiling). Doc syncs should check invariant direction, not only currency. See j-retrospective.md.
