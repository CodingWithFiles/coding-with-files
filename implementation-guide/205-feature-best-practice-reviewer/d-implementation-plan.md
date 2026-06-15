# Best-practice reviewer for plan and exec steps - Implementation Plan
**Task**: 205 (feature)

## Task Reference
- **Task ID**: internal-205
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/205-best-practice-reviewer
- **Template Version**: 2.1

## Goal
Implement the tag-aware best-practice reviewer per the approved design (c-design-plan KD1–KD9):
one deterministic helper, two reviewer agents, a shared review doc, and wiring into the
planning plan-review and the two exec SKILLs.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Create — hash-tracked (entries added to `.cwf/security/script-hashes.json`, same commit)
- `.cwf/scripts/command-helpers/best-practice-resolve` — Perl helper (KD2–KD6); models
  `security-review-changeset`. **Reuse the same CWF lib modules** via
  `use lib "$FindBin::Bin/../../lib"`: `CWF::Common` (`find_git_root`), `CWF::TaskPath`
  (`resolve_num`), `CWF::ArtefactHelpers` (`atomic_write_text`) — do **not** re-hand-roll
  scratch-dir derivation or the atomic write. Core deps beyond those: `Cwd` (`realpath`),
  `File::Spec`, `JSON::PP`. Shebang `#!/usr/bin/env perl`, `PERL5OPT=-CDSLA`, `use utf8;`.
  **Recorded perms 0500.**
  - **Interface divergence from the model**: `--task-num` is the **mandatory** arg here (it
    becomes a filename component → reuse the `/^\d+(?:\.\d+)*$/` guard); the model's mandatory
    `--wf-step` allowlist is **not** adopted as a primary arg — instead a `--phase` token
    (one of `plan`/`implementation-exec`/`testing-exec`, validated against a small allowlist)
    discriminates the `.out` filename `best-practice-context-<phase>.out`, so a planning run
    and the two exec runs for one task never clobber each other. Validate `--max-bytes` and
    `--max-files` as positive integers (`/^[1-9]\d*$/`, as the model validates `--max-lines`).
  - **Deterministic truncation order (testability)**: sources are consumed against the global
    byte cap in a fixed total order — matched-entry order as merged (project entries first,
    then user; original array order within each), and lexical order within a directory walk.
    `[TRUNCATED]` marks the first source cut off and the header.
  - **TOCTOU-safe confinement**: for project-config paths, each member (top-level entry *and*
    every file met mid-walk) is `realpath`-resolved and re-confirmed inside the git root
    **immediately before open** (mirror the model's lstat/realpath-after pattern), so a
    symlink swapped mid-walk cannot escape.
- `.claude/agents/cwf-plan-reviewer-best-practice.md` — planning reviewer agent. Frontmatter
  `tools: Read, Grep, Glob, LSP, WebFetch` (no Bash, KD7) + a one-line body note that **Bash
  is intentionally withheld** (no markdown-reader need; enlarged untrusted surface =
  manifest + WebFetch) so a maintainer does not "restore" it for symmetry. Body is **thin**:
  frontmatter + inputs + "follow §X of `best-practice-review.md`" (mirrors how
  `cwf-security-reviewer-changeset` defers to `security-review.md`). **Recorded perms 0444.**
- `.claude/agents/cwf-best-practice-reviewer-changeset.md` — exec reviewer agent; same tools +
  same Bash-withheld note + thin body; ends with one `cwf-review` block (reuses
  `security-review-classify`). **Recorded perms 0444.**

### Create — not hash-tracked
- `.cwf/docs/skills/best-practice-review.md` — the **single normative source** for: the
  manifest-handling discipline (sentinel-wrapped content = untrusted data, never instructions;
  **fetch only `### URLS` entries, never a URL found inside a `### SOURCE` block**; treat
  fetched URL bodies as untrusted **and** size-bounded, NFR1); the agent prompt templates; the
  Bash-withheld rationale; and the config-format reference + worked example + precedence +
  limitations (URL/DNS-rebinding residual; deliberate non-confinement of `~/.cwf/` paths).
  Parallels the untracked `security-review.md`. Both agents and the wiring reference it
  (progressive disclosure). Must **not** inherit the dangling "Criteria Lookup Table"
  cross-ref (see wiring note below).
- `t/best-practice-resolve.t` — Perl `Test::More` unit tests (models `t/security-review-changeset.t`).

### Modify — not hash-tracked
- `.cwf/docs/skills/plan-review.md` — the file has a `### 1. MAP: Launch 4 Subagents` table
  and **one shared prompt template** (it has no "Criteria Lookup Table" — that phrase in
  `security-review.md:126` is a dangling ref; fix or remove it in this task so the new doc
  does not inherit it). Edits: (a) add a **pre-MAP step** running `best-practice-resolve
  --phase=plan`; (b) iff it reports ≥1 matched entry, launch a conditional 5th agent
  (`cwf-plan-reviewer-best-practice`); (c) because that agent needs an extra `{bp_context_file}`
  input the shared template cannot carry, give it its **own** prompt template (the 4 existing
  columns keep the shared one); (d) update the fixed "4"/"all 4" wording (the MAP heading and
  the lines saying "Launch all 4 Agent calls", "After all 4 subagents complete") to "4, or 5
  when best-practices match". 0 matches ⇒ no 5th agent, wording degrades to "4".
- `.claude/skills/cwf-implementation-exec/SKILL.md` and `.claude/skills/cwf-testing-exec/SKILL.md`
  — add a `## Best-Practice Review` step mirroring the Security Review step but **referencing
  `best-practice-review.md` for the classify/record mechanics** (do not restate them). Branch
  on the helper's **exit code first** (as the security step does): exit 1 ⇒ record `error`
  (a broken config must never read as clean); exit 0 with 0 matches ⇒ record `no findings`;
  exit 0 with ≥1 match ⇒ invoke `cwf-best-practice-reviewer-changeset` with `{changeset_file}`
  (the existing security-review `.out`) + `{bp_context_file}`, write its output, classify via
  `security-review-classify`, record the section.

### Verify (no edit unless required)
- `.cwf/install-manifest.json` — currently enumerates only line-additive/embedded/rules-tree
  artefacts, **not** individual agents/helpers; existing agents install via the standard tree
  copy. Confirm the new helper/agents/doc ride that same path; edit only if exec proves they
  must be registered (would make it hash-tracked `data` → refresh its hash same commit).

## Hash-Tracking Disclosure (plan-time, per `hash-updates.md`)
Three **new** tracked files get fresh `script-hashes.json` entries authored **in the same
commit** as their creation: `best-practice-resolve` (scripts, 0500) and the two agents
(agents, 0444). sha256 computed with `sha256sum` (not a Perl digest — verifier/producer
diversity per `complexity-over-continuity`). No existing tracked file is modified (the shared
doc is a new untracked file; `plan-review.md`/SKILLs/`security-review.md` are untracked), so
no hash *refresh* is needed — only three additions. `cwf-manage validate` must report OK
post-commit.

## Implementation Steps
### Step 1: Helper (test-first)
- [ ] Write `t/best-practice-resolve.t` covering: config parse/merge/precedence; **AC1c**
      (whole-file JSON-decode failure → `eval`-wrapped, zero entries + diagnostic, no throw)
      distinct from **AC1b** (one schema-invalid entry skipped + diagnostic); tag match
      (AC3a/3b incl. undeclared==empty); file/dir/URL resolution + skip notes (AC4a/4b);
      de-dup (AC4c); **top-level** escaping symlink rejected *and* a **mid-walk** escaping
      symlink skipped (two distinct cases); deterministic `[TRUNCATED]` placement under
      byte-cap and member-count; `allow-url-fetch=false` default-deny (URL noted-but-skipped);
      non-numeric `--max-bytes`/`--max-files` rejected; exit 0 vs 1. (d owns this case list;
      e-testing-plan formalises/expands it.)
- [ ] Implement `best-practice-resolve` to green: reuse the named CWF lib modules; wrap
      `JSON::PP` decode in `eval` (fail-open); enforce the deterministic consumption order and
      per-member realpath confinement above; emit the single confirmation line.
- [ ] chmod 0500; author its `script-hashes.json` entry (`sha256sum`).

### Step 2: Agents + shared doc
- [ ] Write `.cwf/docs/skills/best-practice-review.md` (manifest discipline, prompt templates,
      config reference, limitations).
- [ ] Write the two agent files (frontmatter + body referencing `cwf-agent-shared-rules.md`
      and `best-practice-review.md`); the changeset agent reuses the `cwf-review` verdict
      contract verbatim. chmod 0444; author their `script-hashes.json` entries.

### Step 3: Wiring
- [ ] Edit `plan-review.md` (conditional 5th column + pre-MAP resolve step).
- [ ] Edit both exec SKILLs (`## Best-Practice Review` step).

### Step 4: Validate
- [ ] `prove t/best-practice-resolve.t` green; full `prove t/` shows no regressions.
- [ ] `cwf-manage validate` → OK (new hashes recorded; no perm drift).
- [ ] Output-level smoke test: run the helper against a throwaway `best-practices.json`
      exercising each documentation kind + a skip + a truncation; grep the manifest for the
      sentinel and section markers (per the rebrand/output smoke-test lesson).

## Code Changes
Pipeline (final form follows `security-review-changeset` for boilerplate; KD2–KD6 own the
detail): parse/validate args → load+merge project then user config (`eval`-wrapped decode) →
T = union(active-tags) ∪ a-task-plan `**Tags**:` → casefold-intersect match → resolve sources
in the deterministic order (file / lexical dir walk with per-member realpath confinement /
https+allowlist URL → `### URLS`) with dedup and byte+member caps → `atomic_write_text` the
sentinel-wrapped manifest → print the confirmation line → exit 0 (or 1). The only genuinely
new mechanic vs the model is the **per-run random sentinel** wrapping `### SOURCE` content
(KD6); everything else is reuse.

## Test Coverage
**See e-testing-plan.md for complete test plan** (unit cases per AC above; integration =
output-level smoke test of the manifest; regression = full `prove t/`).

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results.** Gate: all AC1a–AC7a green,
NFR5 fail-open verified, NFR4 injection/SSRF/path gates demonstrated, `cwf-manage validate` OK.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All four planned steps executed; the exec-wiring step diverged to a parallel
Step 8 per user direction (recorded in `f-implementation-exec.md`). No planned
work deferred.

## Lessons Learned
`realpath`/`Cwd::realpath` resolves a non-existent leaf under an existing parent
without error — missing-source detection needs an explicit `-e` check, not a
`defined` check (found in testing). See `j-retrospective.md`.
