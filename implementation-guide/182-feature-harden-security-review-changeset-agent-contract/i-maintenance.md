# Harden security-review-changeset agent contract - Maintenance
**Task**: 182 (feature)

## Task Reference
- **Task ID**: internal-182
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/182-harden-security-review-changeset-agent-contract
- **Template Version**: 2.1

## Goal
Define ongoing maintenance, monitoring, and support requirements for Harden security-review-changeset agent contract.

## Monitoring Requirements
There is no service to monitor — `security-review-changeset` is a synchronous CLI helper run per exec phase. "Monitoring" reduces to the standing integrity and contract guards:

- **Integrity**: `cwf-manage validate` (run at every checkpoint commit and available on demand) must report `OK` for `security-review-changeset` and `cwf-security-reviewer-changeset.md`. Any future edit to either requires a same-commit hash refresh (hash-updates convention) or validate fails loudly.
- **Contract adherence**: exec-phase Step 8 must branch on exit-code-first then the reported count. A `## Security Review` section recording `**State**: error` with "no parseable confirmation line" is the signal that the helper's stdout contract drifted (e.g. the confirmation format changed without updating the SKILLs' regex).
- **The originating symptom to watch**: agents appending `> /tmp/…; wc -l; grep` boilerplate to the invocation. Its recurrence would mean the stricter SKILL wording is being ignored and the contract needs re-tightening.

## Maintenance Tasks
### Triggered (not scheduled) maintenance
This helper has no periodic upkeep. Maintenance is triggered by specific events:
- **Editing the helper or agent**: refresh the SHA256 (and, for the script, chmod to the recorded `0500`) in `.cwf/security/script-hashes.json` in the **same commit**. Run `cwf-manage validate` before finishing.
- **Adding a new workflow step**: extend the `%WF_STEP` allowlist in the helper (and the matching usage text + `security-review.md`). Keep every entry a fixed kebab-case literal containing no `/` or `.` — that literal-ness is the path-injection defence (see Audit notes).
- **Adding a new exec call site**: pass `--wf-step=<that step>` exactly as written; do not reintroduce `--max-lines=500` (it is the default) or any redirect/`wc`/`grep` wrapper.
- **Dead-code audit** (see `.cwf/docs/dead-code-audit.md`): periodic sweep using the documented methodology; nothing in this task adds a periodic obligation.

### Forward-looking audit notes (raised by the f/g security reviews — carry into future audits)
1. **`--wf-step` allowlist is the sole gate** making the `<wf-step>` filename component injection-safe. If a future task ever relaxes `%WF_STEP` from a fixed-literal set to a regex or free-form value, the `security-review-changeset-<wf-step>.out` interpolation becomes a path-injection vector. Audit any change that admits values containing `/`, `.`, or non-`[a-z-]` characters.
2. **`mkdir-first 0700` idiom**: the helper creates its scratch dir itself before calling `atomic_write_text`, because the helper's `make_path` fallback uses umask-default mode. Any *other* `atomic_write_text` caller that writes into a `/tmp`-class (world-writable) parent and relies on the helper to create the directory inherits a world-traversable-dir weakness. Audit new `atomic_write_text` callers targeting `/tmp`.

## Incident Response
### Common Issues
- **`invalid --wf-step '<x>' (expected one of: …)` / `(missing)`** → the caller omitted `--wf-step` or passed a non-allowlisted value (incl. the removed `--phase`). **Resolution**: invoke exactly `security-review-changeset --wf-step=<implementation-exec|testing-exec>`.
- **Exit 1 `cannot create scratch dir …` or `cannot write …`** → `/tmp` is unwritable, full, or the per-task dir is owned by another user / pre-planted hostile. **Diagnosis**: `ls -ld /tmp/<dashified-main-root>-task-<num>`. **Resolution**: clear/relocate the offending path; the helper fails closed (no partial confirmation) by design.
- **Exit 2 `cap exceeded: <P> production lines > 500`** → the changeset's production-weighted count exceeds the default cap. **Resolution**: this is the gate working; either split the change or, if genuinely warranted, re-run with an explicit `--max-lines=<N>` override. The `.out` file is still written, so a manual reviewer can read it.
- **Step 8 records `error: changeset helper produced no parseable confirmation line`** → stdout did not match `security-review-changeset: wrote <N> lines to <path>`. **Diagnosis**: run the helper directly and inspect stdout; check whether the confirmation format or the SKILLs' parse regex changed. **Resolution**: realign the two (single source of truth is the helper's `print` line).

### Escalation
Single-maintainer project; no tiered on-call. A reproducible integrity failure (`cwf-manage validate` flags the helper/agent) is the one stop-the-line condition — investigate before any further commits, per the "surface security issues, never smooth them" principle (do **not** add tooling that silences validate).

## Documentation
- **Canonical contract**: `.cwf/docs/skills/security-review.md` (flag, file-output model, exit/empty semantics, prompt template).
- **Helper self-doc**: the `security-review-changeset` header comment block + `--help`.
- **Conventions in play**: `.cwf/docs/conventions/tmp-paths.md` (path form + mkdir guard), `.cwf/docs/conventions/hash-updates.md` (same-commit refresh).

## Success Criteria
- [x] Integrity guard identified (`cwf-manage validate`) and confirmed `OK`
- [x] Triggered-maintenance procedures documented (edit/extend/new-call-site)
- [x] Common failure modes documented with diagnosis + resolution
- [x] Forward-looking audit notes recorded for future reviewers
- [x] No periodic/SLA obligation introduced (none applies to a synchronous CLI helper)

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
No standing maintenance burden introduced. The two forward-looking audit notes (allowlist relaxation; `atomic_write_text` callers into `/tmp`) are the only items to carry forward, and both are documented here and in the f/g security-review sections rather than left implicit.

## Lessons Learned
- The security reviews' "audit future uses where the invariant might not hold" framing produces concrete maintenance artefacts, not just review prose — capturing them here means a future maintainer who relaxes `%WF_STEP` has a written warning at the exact decision point.
