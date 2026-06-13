# Align scratch tmp-paths with /tmp/claude sandbox - Plan
**Task**: 199 (discovery)

## Task Reference
- **Task ID**: internal-199
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/199-align-scratch-tmp-paths-with-tmpclaude-sandbox
- **Baseline Commit**: 45b0aa2306ddbb1dbfe04aa5fa46ce4d16eca26e
- **Template Version**: 2.1

## Goal
Re-root CWF's per-task scratch convention and every workflow `/tmp` write site
under the sandbox-permitted `/tmp/claude/` prefix, so the workflow's subagents,
skills, and helpers operate within the new sandbox without losing cross-repo
namespacing.

## Success Criteria
- [ ] **Complete inventory**: every CWF `/tmp` write site is enumerated and
  classified migrate / keep / out-of-scope — conventions, helper scripts, skill
  and agent docs, the `settings.local.json` allowlist, and the driving
  agent-memory entries. The inventory itself is an acceptance artefact.
- [ ] **Canonical form realigned**: `tmp-paths.md` mandates
  `/tmp/claude/<dashified-repo>-task-<num>/`, keeps the `mkdir -m 0700` guard and
  the cross-repo namespacing rationale, and documents the
  sandbox-unavailable fallback behaviour.
- [ ] **All migrate-class sites emit the new form**: an output-level grep finds
  zero canonical-context references to the bare `/tmp/<dashified>-task-` form
  outside the documented carve-outs (install-time, historical files, user-owned
  settings).
- [ ] **Verification defined and run**: the sandbox-denial behaviour is exercised
  in a genuinely sandboxed session, or recorded BLOCKED-ENV with the exact
  fresh-sandboxed-session repro steps (the dev session is unsandboxed).
- [ ] **Gates stay green**: `cwf-manage validate` and the full test suite pass;
  any hash-tracked helper edit carries a same-commit `script-hashes.json` refresh.

## Original Estimate
**Effort**: 1-2 days
**Complexity**: Medium
**Dependencies**: None blocking. Independent of (but cross-references) the pending
Task-178 CWF-managed sandbox feature.

## Major Milestones
1. **Audit complete**: write-site inventory captured in b-requirements.
2. **Convention realigned**: new canonical form + unavailable-sandbox fallback
   decided in c-design.
3. **Call sites migrated**: helpers, docs, skills, and memory updated; hashes
   refreshed (f-implementation-exec).
4. **Verified**: sandboxed-session smoke test run or documented BLOCKED-ENV
   (g-testing-exec).

## Risk Assessment
### High Priority Risks
- **Unsandboxed dev session**: denial cannot be observed here (probe: the legacy
  `/tmp/...` mkdir still succeeds), so a fix could be built against a wrong model
  of what the sandbox permits.
  - **Mitigation**: probe already confirmed `/tmp/claude` allows owned subdirs +
    writes; verify the *denial* path in a real sandboxed session before claiming
    done (BLOCKED-ENV pattern, per Tasks 143/162).
- **Incomplete audit**: a missed write site silently breaks a subagent under the
  sandbox.
  - **Mitigation**: treat the grep inventory as an AC; sweep skills, agents,
    helpers, docs, and agent-memory; finish with an output-level smoke test
    (rebrand-smoke-test discipline).

### Medium Priority Risks
- **Agent-memory lives outside the repo**: `feedback_no_heredocs`,
  `feedback_no_tee_permissions`, and the `tmp-paths` memory drive the behaviour
  but cannot be committed by this task.
  - **Mitigation**: update those memory files in-session and record the
    cross-surface dependency; `tmp-paths.md` stays the single source of truth and
    the memories reference it.
- **Hash-tracked helper edits** (e.g. `security-review-changeset`): require a
  same-commit hash refresh.
  - **Mitigation**: plan-time disclosure per the hash-updates convention.

## Dependencies
- None blocking. Distinct from Task-178: this task *conforms* CWF's own paths to
  the harness sandbox; Task-178 *builds* a CWF toggle that writes sandbox config.
  The two should cross-reference but do not gate each other.

## Constraints
- POSIX-only; core-Perl-only.
- Must preserve cross-repo namespacing — `/tmp/claude` is a host-global Claude
  scratch root shared across projects (probe found foreign scratch already
  present), so the dashified-repo prefix must survive the re-root.
- "Surface, never smooth": verification must actually exercise the sandbox, not
  assume it.
- Honour the existing `tmp-paths.md` carve-outs (install-time paths, historical
  `implementation-guide/`/BACKLOG/CHANGELOG, user-owned `settings.local.json`).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: >1 week? No — bounded re-root + audit.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? Borderline — convention, helpers,
  docs/memory, and verification — but one coherent re-root applied across sites.
- [ ] **Risk**: high-risk components needing isolation? No.
- [ ] **Independence**: separable parts? Splittable, but the surfaces must move
  together to avoid a half-migrated convention; splitting adds drift risk.

**Conclusion**: 0-1 signals triggered → do not decompose now. Per the user's
direction, reassess after reviewing the requirements and design plans.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
