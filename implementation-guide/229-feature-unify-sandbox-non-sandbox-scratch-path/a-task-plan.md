# unify sandbox and non-sandbox scratch path - Plan
**Task**: 229 (feature)

## Task Reference
- **Task ID**: internal-229
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/229-unify-sandbox-non-sandbox-scratch-path
- **Baseline Commit**: b77a8c1b24e8593438a648ce9a30e131f096da5e
- **Template Version**: 2.1

## Goal
Make CwF's per-task scratch path resolve to one canonical location that a
path-based permission rule can match regardless of whether the session is running
sandboxed or has fallen back to non-sandbox.

**Why (intent):** A session can fall back from sandbox to non-sandbox on the fly
depending on user settings. Path-based permission rules (Write/Bash allowlists on
the scratch subtree) are keyed on an absolute path; today `scratch_parent()`
derives that path from `$TMPDIR`, which differs by process context (unsandboxed
context-inject hook vs sandboxed Bash tool vs off-sandbox fallback). So the path
the hook *advertises* can differ from the path a writer *actually writes*, and an
allowlist rule keyed on one form silently misses the other. A real user report
also shows a non-idempotent **doubling** (`cwf-<slug>/cwf-<slug>/…`) when the
harness sets `$TMPDIR` to a value that already contains the scratch parent.

**Explicit request:** "investigate this further and implement a fix"; "wherever
possible we should use the same path so that path based permissions work
regardless of whether in sandbox mode or not (because depending on the user
settings the agent can fallback to non sandbox on the fly)"; make it a **feature**
task rather than a bugfix task.

<!-- The goal is owner-owned. Do not unilaterally narrow or widen it. Surface any
     scope change (either direction) or goal/why tension to the owner as a decision. -->

## Success Criteria
<!-- Criteria must be outcome-shaped (observable results), never named after a
     not-yet-chosen mechanism. See `planning.md`, "Open-decisions gate & outcome-shaped
     criteria", for the definition and worked examples. -->
- [ ] For a given repo, the scratch path resolved in the unsandboxed hook context and
      the path resolved in the sandboxed Bash-tool context are identical (what is
      advertised is what gets written to).
- [ ] Scratch path resolution is idempotent: no repeated `cwf-<slug>` segment appears,
      whatever value the harness places in `$TMPDIR`.
- [ ] Within a single session, a path-based permission rule for the scratch subtree keeps
      matching across a sandbox → non-sandbox fallback.
- [ ] No regression in the properties tmp-paths already guarantees: scratch stays writable
      under a `/tmp`-read-only sandbox, and the symlink-attack / `0700` guards still hold.
- [ ] The divergent-context, doubling, and writability-preservation behaviours are covered
      by tests.

## Original Estimate
**Effort**: 1-2 days
**Complexity**: Medium
**Dependencies**: `CWF::Common::scratch_parent`/`scratch_dir` (single derivation point);
`userpromptsubmit-context-inject` hook (advertises the path); `tmp-paths.md` convention

## Major Milestones
1. **Investigate**: Characterise the actual `$TMPDIR` value seen in each context (hook,
   sandboxed Bash, off-sandbox), reproduce the doubling, and determine whether a
   within-session sandbox→non-sandbox fallback changes `$TMPDIR`.
2. **Design**: A resolution that is idempotent and context-invariant while preserving
   sandbox writability and the existing guards.
3. **Implement**: Change the single derivation point; refresh script hashes in the same
   commit; update `tmp-paths.md` and its permission-allowlist examples to match.
4. **Verify**: Tests covering divergent-context, doubling, and writability preservation.

## Risk Assessment
### High Priority Risks
- **Writability regression**: Pinning one base that is not writable under a
  `/tmp`-read-only sandbox would make every scratch write fail closed and break all writers.
  - **Mitigation**: Preserve the writability probe/behaviour; test under a simulated
    read-only `/tmp`; treat writability as a non-negotiable invariant of any chosen base.
- **Hashed-file edit**: `.cwf/lib/CWF/Common.pm` is hash-tracked. Edit and
  `script-hashes.json` refresh must land in the same task and same commit.
  - **Mitigation**: Disclosed now (hash-updates convention); refresh in the exec commit and
    confirm with `cwf-manage validate`.

### Medium Priority Risks
- **Harness `$TMPDIR` scheme is not ours to control**: A fix that assumes a particular
  `$TMPDIR` shape may break on a different harness (the report's `$TMPDIR` already embeds
  the scratch parent; ours does not).
  - **Mitigation**: Make resolution defensive and idempotent rather than assuming structure;
    test several `$TMPDIR` input shapes.
- **Doc / convention drift**: `tmp-paths.md`, the allowlist examples, and every consumer of
  the injected path must move together or the documentation lies.
  - **Mitigation**: Treat `tmp-paths.md` and its examples as part of the changeset.

### Low Priority Risks
- **Orphaned old-form scratch dirs / allowlist rules**: Changing the form leaves old-form
  dirs and user allowlist entries pointing nowhere.
  - **Mitigation**: Scratch is ephemeral and reaped; document the change; no migration.

## Dependencies
- `CWF::Common::scratch_parent` / `scratch_dir` — the single derivation point (Task 206).
- `userpromptsubmit-context-inject` hook — emits the `CWF PATHS` scratch line each turn.
- `.cwf/docs/conventions/tmp-paths.md` — the convention this behaviour implements.
- Prior context: the Task 215 hook/sandbox `$TMPDIR` asymmetry (memory:
  `reference_hook_sandbox_tmpdir_asymmetry`).

## Constraints
- Perl core-only; `use utf8;`; `PERL5OPT=-CDSLA` already in the settings env.
- Resolution must remain in the single derivation point — do not reintroduce inline
  `$(...)`/`${//}` derivation (the per-call permission-prompt storm Task 206 removed).
- Preserve the `0700` create and symlink-attack guard semantics.
- Hashed-file edit: same-commit hash refresh; confirm with `cwf-manage validate`.
- Out of scope (per tmp-paths.md): the `pretooluse-bash-tool-check` state dir, which uses a
  separate base and dashify rule; install-time one-shot paths; historical references.

## Open Decisions
- Does a within-session sandbox→non-sandbox fallback actually change `$TMPDIR` (and thus the
  derived base), or does the harness hold `$TMPDIR` constant for the session? This
  determines whether reconciliation must span *differing bases* or merely *differing
  contexts* — the investigation milestone answers it.
- What is the canonical base, given writability genuinely differs by mode? Candidate
  directions to weigh in design: (a) keep per-mode bases but guarantee the
  permission-relevant portion is coverable by one rule pattern; (b) pin a single base that
  is writable in both modes when it exists (e.g. always the per-uid sandbox temp), falling
  back only when absent; (c) normalise `$TMPDIR` to a repo-independent temp root, stripping
  any harness-injected repo/uid segment.
- What is the idempotency mechanism? Candidates: strip a trailing `cwf-<slug>` from the base
  before appending; skip the append when the base already ends in `cwf-<slug>`; or fully
  canonicalise the base first.
- Which contexts must produce a byte-identical path — all three (hook, sandboxed Bash,
  off-sandbox), or only the pair a permission rule spans (hook advertises, Bash writes)?
- Do we keep the `SANDBOX_TMP_PROBE` branch as-is, fold it into the new resolution, or
  retire it if the canonical-base decision subsumes it?

<!-- If genuinely none, write exactly: "None open — <one-line justification>". A bare
     "None" is not conformant. -->

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? If yes, consider decomposition
- [ ] **People**: Does this need >2 people working on different parts? If yes, consider decomposition
- [ ] **Complexity**: Does this involve 3+ distinct concerns? If yes, consider decomposition
- [ ] **Risk**: Are there high-risk components that need isolation? If yes, consider decomposition
- [ ] **Independence**: Can parts be worked on separately? If yes, consider decomposition

**Conclusion**: No decomposition. A single derivation point (`scratch_parent`), its
convention doc, and tests — one person, well under a week, one tightly-coupled concern. No
signal triggered.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Goal delivered, but by a stronger mechanism than the "reconcile `$TMPDIR` across contexts"
framing implied: the fix stops reading `$TMPDIR` and derives the base from the EUID, making
the doubling structurally impossible. All five Open Decisions were closed in c-design.

## Lessons Learned
The mode-invariance requirement had exactly one satisfying input — the EUID. Framing the
goal as "reconcile the variable" almost hid the better answer, "remove the variable".
