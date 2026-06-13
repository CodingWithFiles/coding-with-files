# Align scratch tmp-paths with /tmp/claude sandbox - Testing Execution
**Task**: 199 (discovery)

## Task Reference
- **Task ID**: internal-199
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/199-align-scratch-tmp-paths-with-tmpclaude-sandbox
- **Template Version**: 2.1

## Test Results

### Functional (sandbox-independent) — all PASS
| TC | Result | Evidence |
|----|--------|----------|
| TC-TMPDIR-1 (honour set `$TMPDIR`) | **PASS** | `.out` lands under the set `$TMPDIR` (subtest 43, 3/3 ok) |
| TC-TMPDIR-2 (unset → `/tmp`, no regression) | **PASS** | `.out` under `/tmp/...` (subtest 44, 2/2 ok) |
| TC-TMPDIR-3 (empty → `/tmp`, no root collapse) | **PASS** | `^/tmp/` matches, `^/-` does not (subtest 45, 3/3 ok) |
| TC-RED (red before edit) | **CONFIRMED** | TC-TMPDIR-1 failed against the pre-edit hardcoded `/tmp/` (recorded in f-exec) |

### Non-Functional — all PASS
| Check | Result | Evidence |
|-------|--------|----------|
| Regression (NFR5) | **PASS** | full `prove -j4 t/`: 63 files, 762 tests, all pass |
| Hash integrity (NFR4) | **PASS** | `cwf-manage validate`: OK (sha256 refreshed same commit) |
| Fail-closed (NFR4) | **PRESERVED** | `unless -d / mkdir 0700 / exit 1` + 0600 write unchanged; security-review confirmed |
| AC3 grep gate (NFR3) | **PASS** | `security-review-changeset` zero bare-`/tmp/` literals; `tmp-paths.md` `/tmp/` hits all explanatory / rejected-illustration / carve-out |
| Output smoke | **PASS** | TC-TMPDIR-1 is the artefact-level proof; also observed live: the f-exec security-review helper wrote `.out` to `/tmp/-home-…-task-199/` (TMPDIR unset → `/tmp` fallback) |

### BLOCKED-ENV (FR7 / D2) — sandbox required, not available in dev
The dev session is **confirmed unsandboxed** (live probe during this task: `TMPDIR`
unset, a bare `/tmp` mkdir outside `/tmp/claude` was ALLOWED, no
`CLAUDE_SANDBOX`/`SANDBOX` env markers). The two sandbox checks cannot run here and
are **recorded, not waived**:

- **TC-SANDBOX-TMPDIR (D2 pivot)**: confirm `TMPDIR=/tmp/claude` in an active
  sandbox. **Repro**: in a fresh sandboxed session, `echo "$TMPDIR"`.
  Evidence supporting the leading hypothesis (set): `/tmp/claude/go-build` exists
  (Go test/build temp keys off `$TMPDIR`).
- **TC-SANDBOX-DENY (FR7)**: a bare-`/tmp/x` write is denied and `/tmp/claude/x`
  permitted. **Repro**: in a fresh sandboxed session, `mkdir /tmp/x` (expect deny)
  vs `mkdir /tmp/claude/x` (expect allow); then run the helper and confirm its
  `.out` lands under `/tmp/claude/...`.

**Resolution rule** (carried from FR4 AC(ii)/(iii)): once D2 is resolved —
- **set** (expected) → class-(c) sites (`cwf-apply-artefacts`, `cwf-manage`
  `File::Temp`/`tempdir`) are disposition **(ii) already safe**, no code change;
- **unset** → raise a class-(c) BACKLOG follow-up (export `TMPDIR` in those helpers
  or pin `DIR`). Do not silently defer.

## Coverage
- Critical path (honour `$TMPDIR`, empty-string defence): 100% (3 explicit subtests).
- Regression: full suite green.
- Residual (sandbox denial / TMPDIR-set fact): BLOCKED-ENV with documented repro.

## Validation Criteria (e-testing-plan rollup)
- [x] TC-TMPDIR-1/2/3 pass; TC-RED confirmed.
- [x] Full `t/security-review-changeset.t` green (regression).
- [x] `cwf-manage validate` clean (hash refreshed same commit).
- [x] AC3 grep gate green with documented carve-outs.
- [x] Output smoke: `.out` lands under a set `$TMPDIR`.
- [~] FR7 TC-SANDBOX-* — **BLOCKED-ENV** with repro (dev session unsandboxed).
- [~] FR4 class-(c) disposition — **(ii) pending D2 confirmation** (BLOCKED-ENV).

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: FR7/D2 sandbox checks BLOCKED-ENV (unsandboxed dev session) — recorded with repro, not waived.

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
- The honour-`$TMPDIR` design made the core contract testable *without* a sandbox
  (assert `.out` location under a set `$TMPDIR`), shrinking the irreducible
  BLOCKED-ENV residue to just the denial-enforcement + TMPDIR-set facts.

## Security Review

**State**: no findings

This testing-exec changeset re-roots `$scratch` from hardcoded `/tmp` to
`${TMPDIR:-/tmp}` (helper + `tmp-paths.md`), with a same-commit hash refresh and
three new tests. Executable surface = the helper edit + tests; rest is docs.

**(a) Bash injection.** No new shell invocation; `$base`/`$scratch` flow only into
`mkdir`/`atomic_write_text` (Perl built-ins), no `system($string)`/backtick.
**(b) Perl/git output.** No new git-porcelain parsing; `-z`/NUL conventions untouched.
**(c) Prompt injection.** No new `{arguments}`/untrusted-string flow.
**(d) Env-var handling (central).** `$ENV{TMPDIR}` used verbatim; empty/undef guard
`(defined && length) ? … : '/tmp'` matches shell `${TMPDIR:-/tmp}` (no root-collapse,
TC-TMPDIR-3 asserts `unlike ^/-`); containment unchanged (`mkdir 0700` + 0600
same-dir-rename; fail-closed on foreign dir is the 0600 write failing); verbatim use
accepted under the documented single-user threat model; off-sandbox = `/tmp`, no new
exposure.
**(e) Pattern-risk.** Verbatim-`$TMPDIR` safe here (single-user + guarded
`mkdir 0700`/atomic-rename); audit future reuse on multi-user hosts or feeding the
path to `chmod`/`rm`/`unlink`. `tmp-paths.md` § "Sandbox alignment" already names the
invariant.
**Hash integrity.** sha256 refreshed same commit; `0500` perm unchanged;
`cwf-manage validate` clean (deterministic check, outside review scope).

No actionable defect.

```cwf-review
state: no findings
summary: $TMPDIR re-root in security-review-changeset is guarded (mkdir 0700 + 0600 atomic rename unchanged), empty/unset falls back to /tmp (TC-TMPDIR-3 tested, no root-collapse), verbatim-$TMPDIR documented as single-user-only — a pattern-risk caveat, not a defect.
```
