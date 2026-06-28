# fix hook sandbox tmpdir scratch path - Design
**Task**: 215 (bugfix)

## Task Reference
- **Task ID**: internal-215
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/215-fix-hook-sandbox-tmpdir-scratch-path
- **Template Version**: 2.1

## Goal
Make the `CWF PATHS` hook emit a scratch path that is writable inside Claude Code's bash sandbox, despite the hook running **outside** the sandbox (where `$TMPDIR` is unset).

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Root Cause (recap)
Hooks run unsandboxed (`$TMPDIR` unset → `${TMPDIR:-/tmp}` = `/tmp`); the Bash tool runs sandboxed (`$TMPDIR=/tmp/claude-<uid>`, `/tmp` read-only). `scratch_parent` resolves correctly in whichever env it runs, but the hook resolves in the host env and freezes `/tmp/cwf-…`, which is read-only in-sandbox.

## DECISION PENDING REVIEW — two candidate approaches
The plan review surfaced a simpler alternative than the original cache. Both are documented; **Approach A is recommended**. Pick one before the implementation plan (d).

### Approach A (recommended) — self-validating uid-path probe
Add one branch to `CWF::Common::scratch_parent`: when `$ENV{TMPDIR}` is unset, probe the conventional sandbox temp `/tmp/claude-$>` (effective uid); if it is a writable directory (`-d && -w`), use it as the base; else fall back to `/tmp`.
- **Verified**: from the unsandboxed hook env, `/tmp/claude-1000` is `drwx------ matt`, `-d && -w` true (same uid as the sandbox). The agent's in-sandbox Bash writes there too. So the hook emits the correct literal with **no hook change**.
- **Eliminates** (vs Approach B): the `.cwf/config.local.json` file, the gitignore entry, the `scratch_dir` write path, `atomic_write_json` use, the `cwf-manage update` clean-tree carve-out, the cached-value validation, the cold-start coverage gap, and the symbolic fallback. Net change ≈ a few lines in `scratch_parent` + a test.
- **Self-validating** → strictly ≥ today everywhere: if the convention ever differs (e.g. a future path scheme), `-d && -w` fails and it degrades to `/tmp` (status quo), never a wrong/read-only literal.
- **Trade-offs**: couples to the `/tmp/claude-<uid>` naming convention, which is **undocumented** (the documented contract is `$TMPDIR`, not a fixed path); Linux/WSL2-oriented (macOS Seatbelt uses a different temp dir → probe misses → `/tmp` fallback, i.e. unchanged on macOS).

### Approach B (original) — last-seen-`$TMPDIR` cache
In-sandbox writers persist `$TMPDIR` to `.cwf/config.local.json`; the unsandboxed hook reads it via `scratch_parent`.
- **Strength**: observes the real `$TMPDIR`, so it is correct on any platform (incl. macOS) **once a writer has run in-sandbox**.
- **Weaknesses surfaced in review**:
  - **Coverage gap (robustness #3)**: only `plan-mechanical-check` and `security-review-changeset` call `scratch_dir`, both late-firing review gates. Ordinary early-session scratch use finds an empty cache → fallback. The cache earns its keep only for non-shell literal-path use inside the pre-first-writer window.
  - Requires: cached-value validation (security/robustness — see below), a `:(exclude) .cwf/config.local.json` carve-out in `cwf-manage` `check_clean_tree` (mirroring `.update.lock`, robustness #1), self-healing overwrite of a corrupt cache (robustness #3), and reuse of `read_json_file` for the read (misalignment #3).
  - Naming: `config.local.json` implies config-loader membership it does not have; a runtime-state name (sibling of `.cwf/task-stack`, `.cwf/.update.lock`) is preferred (misalignment #1).

### Comparison
| | A — probe | B — cache |
|---|---|---|
| Files changed | `scratch_parent` + test | `scratch_parent`, `scratch_dir`, hook, manifest, cwf-manage, +1 new file |
| New runtime state | none | `.cwf/config.local.json` |
| Cold-start | works turn 1 | empty until a writer runs (coverage gap) |
| macOS | no change (→ `/tmp`) | works after first in-sandbox writer |
| Coupling | undocumented `/tmp/claude-<uid>` | documented `$TMPDIR` |
| Failure mode | self-validated → `/tmp` | validated value → `/tmp` |

## Shared decisions (apply to whichever approach)
- **Drop the symbolic `${TMPDIR:-/tmp}` fallback** (was Decision 2). Consensus: it is a footgun — pasted into a Write/Read tool path (the project's no-heredoc scratch pattern) it creates a literal `${TMPDIR:-` directory; and it weakens the hook's "do not re-resolve" contract. Cold-start instead emits today's `/tmp/cwf-…` literal (status quo, one-turn window); Approach A removes even that window.
- **Validate any derived base before use/emit** (security #1, robustness #2): require an absolute path (`^/`), reject newlines/control chars and `..`, strip a trailing slash; on failure use `fallback`. The hook prints `$parent` verbatim into LLM context, so a non-`$ENV` source is a new trust boundary. (Approach A's `-d && -w` probe is inherently a real local dir; Approach B must validate the on-disk string.)
- **`scratch_parent` contract**: `($parent,$err)` → `($parent,$err,$source)` where `source ∈ {env,probe|cache,fallback}`. Backward compatible — the sole internal caller `scratch_dir` destructures two values (`Common.pm:116`).
- **Reuse over new code**: Approach B reuses `read_json_file`/`atomic_write_json` (lazy `require`; `ArtefactHelpers` has no CWF deps → no cycle) and the existing `install-manifest.json` `gitignore-entries` line-additive artefact (no new `.cwf/.gitignore`).

## Security / threat model (FR4)
- **FR4(c) prompt injection**: the hook emits the resolved base into context every turn. Mitigation = the base-validation decision above; Approach A's base is a probed real directory.
- **FR4(a) command construction**: the path is pasted into agent Bash; same validation is the control.
- **Integrity**: Approach B's cache is deliberately kept out of `script-hashes.json` (allowlist-based `validate` ignores it — parity with `.cwf/task-stack`). Unlike those precedents the cache flows into context, so input validation is the compensating control. Approach A adds no new file, so no integrity question.
- **Single-user trust model** per `.cwf/docs/conventions/tmp-paths.md` applies.

## Constraints
- Core Perl only (`JSON::PP`, `File::Temp`, `Digest::SHA` all core).
- The hook `userpromptsubmit-context-inject` is hashed → `script-hashes.json` refresh in the **same commit** (only if the chosen approach edits it; Approach A does not). `install-manifest.json` **is** integrity-verified (`validate_install_manifest_sha`, `cwf-manage:301`) → unconditional same-commit refresh if Approach B edits it.
- Never commit machine-/uid-/OS-specific paths.

## Rejected
- **Symbolic `${TMPDIR:-/tmp}` hook output** — Write-tool footgun (above).
- **Reserved `scratchBaseOverride` key** — YAGNI; no operator. Add it with its reader if the broken-sandbox case (#36759/#43096) is ever tackled.

## Decomposition Check
- [ ] Time <1 week — no · [ ] >2 people — no · [ ] 3+ concerns — no · [ ] high-risk isolation — no · [ ] independent parts — no

0 signals → no decomposition.

## Validation
- [ ] Approach chosen (A or B) at review gate
- [ ] `scratch_parent` contract change verified backward-compatible (done: only `scratch_dir` + hook call it)
- [ ] Chosen mechanism exercised under a real sandbox (self-verifying test preconditions)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan (after approach is chosen)
**Blockers**: Approach A vs B decision (user review)

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Approach A was implemented as designed: the three-way resolver (env → probe
`!-l && -d _ && -w _` → `/tmp`) in `CWF::Common::scratch_parent`, with the overridable
`$SANDBOX_TMP_PROBE` package var for hermetic testing. No design changes were needed
during implementation.

## Lessons Learned
Choosing the approach that *removes* a risk class (no cache → no staleness, commit, or
race) over the one that *mitigates* it was the decisive design call — and the phase
separation let design override the a-plan's assumed mechanism cleanly. See
j-retrospective.md.
