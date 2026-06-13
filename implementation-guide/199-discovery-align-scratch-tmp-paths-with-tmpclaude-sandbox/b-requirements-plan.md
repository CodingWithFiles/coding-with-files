# Align scratch tmp-paths with /tmp/claude sandbox - Requirements
**Task**: 199 (discovery)

## Task Reference
- **Task ID**: internal-199
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/199-align-scratch-tmp-paths-with-tmpclaude-sandbox
- **Template Version**: 2.1

## Goal
Define what "the CWF workflow conforms to the `/tmp/claude` sandbox restriction"
means, and how each claim is verified — covering the documented per-task scratch
convention, the subagents/skills/helpers that write under a temp root, and the
agent-memory that drives the behaviour.

## Audit Findings (write-site inventory)
The temp/scratch surface, classified by sandbox exposure. This inventory is the
primary discovery artefact; FR1 requires it be complete.

| # | Site | Class | Exposure | Disposition |
|---|------|-------|----------|-------------|
| 1 | `.cwf/docs/conventions/tmp-paths.md` (canonical form, snippet, examples) | (b) explicit `/tmp/<dashified>-task-N/` | EXPOSED | re-root → FR2 |
| 2 | `security-review-changeset` `$scratch` (:261) + path-literal comments (:59, :344) | (b) explicit | EXPOSED; hash-tracked | re-root + same-commit hash refresh → FR3 |
| 3 | agent-memory `feedback_no_heredocs`, `feedback_no_tee_permissions`; `MEMORY.md` squash-commit entry | (b) behavioural guidance | EXPOSED | re-root in-session (user-global, uncommittable) → FR5 |
| 3a | `.claude/skills/cwf-implementation-exec/SKILL.md:65`, `.claude/skills/cwf-testing-exec/SKILL.md:59` (subagent `.out` scratch dir) | (b) **indirect** — delegates to `tmp-paths.md` | EXPOSED via convention | self-updates when FR2 re-roots; no literal edit → FR1/FR5 |
| 4 | `.cwf/lib/CWF/ArtefactHelpers.pm:66` `File::Temp->new(DIR=>$dir)` | (a) workspace-internal | SAFE | no change (DIR = dest dir, in-repo) |
| 5 | `.cwf/lib/CWF/Versioning.pm:131` `File::Temp->new(DIR=>$dir)` | (a) workspace-internal | SAFE | no change |
| 6 | `.cwf/scripts/command-helpers/cwf-apply-artefacts:647-648` `File::Temp->new` (no DIR) | (c) default-location | DEPENDS on TMPDIR-in-sandbox | disposition recorded → FR4 |
| 7 | `.cwf/scripts/cwf-manage:490` `tempdir(CLEANUP=>1)` (update clone) | (c) default-location | DEPENDS on TMPDIR-in-sandbox | disposition recorded → FR4 |
| 8 | `template-copier-v2.0/v2.1` `--destination=/tmp/test` (usage comments) | illustrative | none | cosmetic-only; out of scope |
| 9 | `.cwf/docs/skills/security-review.md:104` `/tmp/cwf-update` (injection example, already annotated "not a canonical scratch path") | illustrative | none | no change |
| 10 | `.cwf/docs/conventions/worktree-process.md:117` (see-also cross-ref to tmp-paths) | cross-ref | none | follow rename only |
| 11 | `.claude/settings.local.json` existing `Bash(/tmp/...)` allowlist entries | user-owned | n/a | carve-out: do not rewrite |

**Notes on site #2**: only `:59`, `:261`, `:344` are path *literals* to rewrite;
`:224` and `:263` are prose cross-references to `tmp-paths.md` by name and must
not be churned. The scratch construction at `:264-271` is **already fail-closed**
(`mkdir(...,0700) or { warn; exit 1 }`) — the re-root must preserve that exit-1
behaviour, not introduce a silent fallback (see NFR2).

**Open question (resolve in design/testing)**: whether the active sandbox remaps
`TMPDIR` into `/tmp/claude`. If it does, class (c) sites (#6, #7) are already
safe and need no change; if it leaves `TMPDIR` unset (bare `/tmp`, as in the
unsandboxed dev probe), they are denied. This single fact decides FR4.

## Requirements reconciliation (post c-design)
FR2/FR3 originally specified a hardcoded `/tmp/claude/` root. The c-design phase
(D1) chose to **honour `$TMPDIR`** instead — more portable (`tmp-paths.md` is a
shipped convention binding on all adopters, not only Claude-sandbox users) and it
unifies all temp classes onto one signal. FR2/FR3/AC2/AC3 below are updated to the
`$TMPDIR` form; sandbox-safety now derives from the sandbox setting
`TMPDIR=/tmp/claude` (the FR4 pivot fact), not from a literal in the convention.

## Functional Requirements
### Core Features
- **FR1 — Complete inventory**: every CWF-controlled site that creates a file or
  directory under a temp root is enumerated with `file:line` and classified
  (a) workspace-internal / (b) explicit scratch / (c) default-location /
  illustrative.
  - *AC*: every `grep` hit for `/tmp`, `File::Temp`, `tempdir`, `tempfile` in
    `.cwf/`, `.claude/`, `docs/` maps to a row in the inventory above.
- **FR2 — Sandbox-aware canonical convention**: `tmp-paths.md`'s canonical form
  honours `$TMPDIR` — `${TMPDIR:-/tmp}/<dashified-absolute-repo-path>-task-<num>/`
  (trailing slash on `$TMPDIR` stripped) — so it lands in the sandbox temp root
  when the sandbox sets `TMPDIR` (e.g. `/tmp/claude`) and degrades to `/tmp`
  off-sandbox. Retains the `mkdir -m 0700` first-use guard and the cross-repo
  namespacing rationale. (Form chosen in c-design D1; **supersedes** the earlier
  hardcoded-`/tmp/claude` framing — see reconciliation note below.)
  - *AC*: the doc's canonical form, derivation snippet, and all worked examples
    use the `${TMPDIR:-/tmp}` base; the "Why" section notes the sandbox provides
    `/tmp/claude` via `TMPDIR`, that `/tmp/claude` is a host-global per-user
    (`drwx------`) root, and the off-sandbox `/tmp` fallback.
- **FR3 — Class-(b) sites emit the new form**: every explicit per-task scratch
  path in CWF-controlled code and docs uses the re-rooted form.
  - *AC*: `grep` finds zero `$TMPDIR`-less hardcoded `/tmp/`-rooted scratch
    literals in canonical context (outside the carve-outs);
    `security-review-changeset`'s `$scratch` honours `$TMPDIR` and its hash is
    refreshed in the same commit.
- **FR4 — Class-(c) disposition recorded**: for each default-location temp site
  (#6, #7) the task records one of — (i) made sandbox-safe here, (ii) already
  safe via a sandbox-provided `TMPDIR`, or (iii) deferred to a follow-up with a
  BACKLOG entry — each with rationale.
  - *AC*: #6 and #7 each carry a disposition grounded in the **resolved**
    TMPDIR-in-sandbox fact (the open question above must be answered first).
  - *AC (ii)*: if "already safe via sandbox `TMPDIR`" is chosen, record that
    `TMPDIR` is sandbox-authoritative and state the fail-mode when it is
    unset/escaped (an env-var-influences-path dependency, FR4(d) category) — so
    the reliance is a deliberate, documented decision, not an implicit one.
  - *AC (iii)*: "deferred" is valid only **after** the TMPDIR fact is resolved
    and the site confirmed unsafe; it must not stand in for "not investigated".
- **FR5 — Agent-behaviour guidance aligned**: the agent-memory and any in-repo
  skill doc that instructs writing one-off scripts/captures to a per-task `/tmp`
  dir reference the re-rooted form.
  - *AC*: the two existing memory files `feedback_no_heredocs` and
    `feedback_no_tee_permissions`, plus the `/tmp/...` example in `MEMORY.md`'s
    squash-commit entry, point to `/tmp/claude/...`; no in-repo skill doc
    instructs the bare-`/tmp` form. (No standalone `tmp-paths` memory file
    exists — `[[tmp-paths]]` is a forward-marker; `tmp-paths.md` is the SSOT.
    Memory edits are in-session, not committed — recorded as a cross-surface
    dependency.)
- **FR6 — Sandbox-unavailable correctness**: the re-rooted convention is a single
  unconditional form that also works when no sandbox is active.
  - *AC*: `mkdir -m 0700 -p /tmp/claude/<...>` succeeds in an unsandboxed session
    (already probed OK); the convention has no sandbox-conditional branch.
- **FR7 — Denial verified**: the task exercises that a bare-`/tmp` write is
  denied and a `/tmp/claude/...` write permitted under an active sandbox, or
  records this BLOCKED-ENV with exact fresh-session repro steps.
  - *AC*: g-testing-exec holds the sandboxed-session transcript; BLOCKED-ENV is
    permitted only if a genuinely sandboxed session is unavailable in this
    environment, and then must record the exact repro for a later run (the
    escape hatch is not the default — the dev session is unsandboxed, confirmed
    by the legacy-mkdir probe).

### User Stories
- **As a** CWF subagent (e.g. the security-review changeset reviewer) **I want**
  my scratch `.out` capture path to fall inside the sandbox-permitted prefix **so
  that** my write is not denied when the sandbox is active.
- **As a** CWF maintainer **I want** one canonical scratch form that works with or
  without the sandbox **so that** I don't carry sandbox-conditional path logic.

## Non-Functional Requirements
### Performance (NFR1)
- No hot path affected; no measurable performance requirement.
### Usability (NFR2)
- The convention stays derivable in three lines of shell.
- An unwritable `/tmp/claude` fails closed with an actionable message (consistent
  with "surface, never smooth"), not a silent fallback to an unsafe path.
### Maintainability (NFR3)
- `tmp-paths.md` remains the single source of truth; every other site references
  it rather than restating the form.
### Security (NFR4)
- Preserve the symlink-pre-creation defence (`mkdir -m 0700` first-use guard).
- `/tmp/claude` is per-user (`drwx------`), which strengthens the read-after-write
  posture versus world-writable `/tmp`; document this, do not weaken the guard.
- Hash-tracked edits (`security-review-changeset`) carry a same-commit
  `script-hashes.json` refresh; sha256 drift is surfaced, never smoothed.
- No secrets in scratch (unchanged carve-out).
### Reliability (NFR5)
- `cwf-manage validate` and the full `prove` suite stay green.
- No regression for unsandboxed users: the re-rooted path works identically off-sandbox.

## Constraints
- POSIX-only; core-Perl-only.
- Agent-memory lives in user-global storage outside the repo — updatable
  in-session but not committable by this task; record as a cross-surface dependency.
- Preserve `tmp-paths.md` carve-outs: install-time paths, historical
  `implementation-guide/`/`BACKLOG.md`/`CHANGELOG.md`, user-owned
  `.claude/settings.local.json`.
- Distinct from Task-178: this task *conforms* CWF paths to the harness sandbox;
  Task-178 *builds* a CWF toggle that writes sandbox config. Cross-reference only.

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2? No.
- [x] **Complexity**: 3+ concerns? Two distinct concerns are now explicit —
  **(b)** the per-task scratch convention + subagent/skill behaviour, and
  **(c)** helper-internal default-location temp hygiene (`cwf-apply-artefacts`,
  `cwf-manage`). Borderline (two, not three).
- [ ] **Risk**: isolation needed? No.
- [x] **Independence**: (b) and (c) are separable — they touch different files,
  different mechanisms (documented convention vs `File::Temp` default dir), and
  (c)'s very necessity depends on an unresolved fact (TMPDIR-in-sandbox).

**Conclusion**: 2 signals (Complexity, Independence) lean toward a split —
candidate subtasks **199.1** (scratch-convention re-root + behaviour; the user's
named focus) and **199.2** (helper temp-default hygiene). Per the user's
direction, defer the call to after `c-design`: design will establish whether (c)
is a no-op (sandbox provides `TMPDIR`) — in which case there is nothing to split —
or a real change, in which case 199.2 is justified.

## Acceptance Criteria
- [ ] AC1: write-site inventory complete and classified (FR1).
- [ ] AC2: `tmp-paths.md` canonical form honours `$TMPDIR` (`${TMPDIR:-/tmp}` base), guard + namespacing retained (FR2).
- [ ] AC3: zero `$TMPDIR`-less hardcoded `/tmp/`-rooted scratch literals; `$scratch` honours `$TMPDIR` + hash refreshed (FR3).
- [ ] AC4: class-(c) dispositions recorded against the resolved TMPDIR fact (FR4).
- [ ] AC5: agent-memory + in-repo skill docs aligned to the new form (FR5).
- [ ] AC6: single unconditional form, unsandboxed correctness retained (FR6).
- [ ] AC7: denial behaviour verified under sandbox or BLOCKED-ENV documented (FR7).
- [ ] AC8: `cwf-manage validate` + full suite green; hashes refreshed (NFR4/NFR5).

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
