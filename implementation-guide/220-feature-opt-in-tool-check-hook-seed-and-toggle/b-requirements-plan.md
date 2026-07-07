# opt-in tool-check hook seed and toggle - Requirements
**Task**: 220 (feature)

## Task Reference
- **Task ID**: internal-220
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/220-opt-in-tool-check-hook-seed-and-toggle
- **Template Version**: 2.1

## Goal
Define functional and non-functional specifications for opt-in tool-check hook seed and toggle.

## Functional Requirements
### Core Features
- **FR1 — Global runtime activation flag (`active`)**: The hook honours a single
  global `active` flag, **named distinctly from the existing per-rule `enabled:false`
  disable directive** (`CWF::ToolCheck`) to avoid a same-token/two-scope clash. When
  not active, the hook short-circuits to allow (**exit 0, empty stdout**) *before*
  compiling or matching any rule. An **absent** flag is semantically identical to
  today's inert behaviour (no flag, no rules → allow). Active with **zero rules is
  still allow-all** (existing `return unless @$merged`) — activation alone never
  denies. The flag read is **symlink-safe** (`-f && !-l`) and fail-open. Effective
  **live** — no session restart, no `.claude/settings.json` edit.
- **FR1a — Flag precedence across layers**: If `active` is set in more than one
  layer, the **existing layer precedence** decides (project-local > checked-in >
  user-global). So a project-local `active:false` overrides a seeded checked-in
  `active:true` — the basis for a local silence that does not touch shared state.
- **FR2 — `/cwf-config tool-check` subcommand**: `on`/`off` set `active`; `seed`
  installs the starter ruleset (and implies `on`). Each prints the resulting state
  (active? rule count). Unknown/absent argument prints current state + usage.
  `/cwf-config` retains its existing `init|list|reset` behaviour. **`on`/`off` write
  the gitignored project-local layer** (`settings.local.json`) so a live toggle never
  dirties a git-tracked file (satisfies the "temporarily silence" story without an
  accidental commit).
- **FR3 — Regex-only starter ruleset**: A defined starter set of **regex-only** rules
  (each with stable `id`, `regex`, `guidance`) ships with CWF and is what `seed`
  installs. Regex-only so it is safe in any layer including checked-in. Content covers
  the highest-frequency prompt-tripping idioms established by Task 219 finding P1
  (e.g. `cat`/`head`/`tail` reads, `sed -n` line ranges, heredocs, shell loops,
  redundant `git -C <root>`) — the exact set is a design decision. `seed` **adds only
  missing rule `id`s and never overwrites an existing one**, reporting how many it
  skipped — a re-seed preserves user edits (no clobber) while staying idempotent.
- **FR4 — `cwf-init` opt-in confirm**: `cwf-init` offers the seed behind an explicit
  confirm with a one-line description. **Accept** → seed installed + flag on.
  **Decline** (the default) → hook left strictly inert; no flag, no rules written.
- **FR5 — Docs + backlog correction**: `.cwf/docs/tool-check-rules.md` documents the
  flag, its precedence, the seed, and the `/cwf-config tool-check` surface. The
  Task-219 R3 backlog entry's stale premise ("not shipped / this-repo-only") is
  corrected.

### User Stories
- **As a** new CWF user **I want** an offered starter set of shell-hygiene nudges at init **so that** I get working permission-prompt avoidance without hand-authoring an empty settings file.
- **As a** project maintainer **I want** to toggle the tool-check hook on/off live **so that** I can silence it temporarily without editing `settings.json` or restarting the session.

## Non-Functional Requirements
### Performance (NFR1)
- Location-neutral cost bound (does not pre-judge open decision D2): the inactive
  path resolves with **at most a single small-file stat/read and no rule compilation
  or match loop** — no per-rule work when the flag is off.

### Usability (NFR2)
- Every `/cwf-config tool-check` operation echoes the resulting state (active? rule count).
- The `cwf-init` prompt is explicit, one-line, and **defaults to decline** (no surprise activation).
- Consistent with existing `/cwf-config` and `--check` conventions.

### Maintainability (NFR3)
- Seed + toggle share **one code path** invoked by both `cwf-init` and `/cwf-config` (DRY).
- Starter rules keyed by stable `id` for override/disable and add-missing seeding.
- Changes to `pretooluse-bash-tool-check` stay within its existing structure; no new dependency.

### Security (NFR4)
- `seed`/toggle/flag writes are **confined to the resolved settings file** — no other file mutated.
- Those writes are **symlink-safe and atomic** (reject `-l` target; temp-file + `O_EXCL` + `rename`; mode 0600), mirroring the hook's existing `write_last_denied` state-writes, so a pre-planted symlink cannot redirect the write.
- The flag can only **deny/nudge**; it can never widen what Bash is permitted to run (the hook has no allow-more path).

### Reliability (NFR5)
- **Fail-open invariant preserved**: inactive, missing, malformed, or symlinked flag/settings all resolve to allow — never block Bash.
- `seed` is **idempotent and non-destructive** — adds missing `id`s only, never overwrites an existing rule.
- `on`/`off` are idempotent; atomic writes mean a concurrent hook read never sees a torn file.

## Constraints
- Perl **core modules only**; POSIX portability (macOS system Perl).
- **Fail-open** is non-negotiable — a tool-check must never brick Bash.
- **perl rules never in the checked-in layer** (dropped before compile by design).
- `pretooluse-bash-tool-check` is hash-tracked — a source edit refreshes `script-hashes.json` in the **same commit**. **If the starter ruleset ships as a data file under `.cwf/`, that file is likewise hash-tracked in the same commit**; if it is embedded in the shared code path, design says so explicitly (no unrecorded runtime file).
- Toggle must be a **runtime flag the hook reads**, not hook (de)registration — registration is session-cached and would not take effect live.

### Open decisions (refined from `a-task-plan.md` D1–D3; resolved in design)
- **D1a — Seed target**: checked-in project layer (shareable, **regex-only**). Recommendation stands.
- **D1b — Toggle target**: gitignored project-local layer, so live `on`/`off` never dirties tracked state (per FR2/FR1a). *New split surfaced by review.*
- **D2 — Flag name/location**: name resolved to **`active`** (distinct from per-rule `enabled`); physical location still design's call, bounded by NFR1's location-neutral cost.
- **D3 — Absent-flag default**: absent ≡ today's inert no-op (allow).

## Decomposition Check
Unchanged from `a-task-plan.md`: 1 borderline signal (complexity), below the
2-signal threshold — **do not decompose**.

## Acceptance Criteria
- [ ] **AC1** (FR1): With `active` off, a command a seeded rule would deny is **allowed** (exit 0, empty stdout); toggling `active` on makes the same command deny — no restart between. Active with zero rules allows everything.
- [ ] **AC2** (FR1/NFR5): Absent flag, empty settings, malformed settings, and a **symlinked** flag/settings path all **allow** (fail-open) — no Bash call ever blocked by a tool-check error.
- [ ] **AC3** (FR2): `/cwf-config tool-check on|off|seed` each produce the documented state change and echo the resulting active/rule-count state; unknown arg prints state + usage. A live `on`/`off` **leaves every git-tracked file unmodified** (writes only the gitignored project-local layer).
- [ ] **AC4** (FR3/NFR4): The seeded ruleset is **regex-only**; every seeded rule fires on its target command and no-ops on a benign command; no `perl` rule is written to the checked-in layer.
- [ ] **AC5** (FR4): `cwf-init` accept seeds + enables; **decline leaves the tree byte-for-byte inert** (no flag, no settings file created).
- [ ] **AC6** (FR3/NFR5): `seed` run twice is idempotent; a `seed` over a **user-edited** rule of the same `id` **preserves the edit and reports the skip** (no clobber); `on`/`off` idempotent.
- [ ] **AC7** (FR1a): With `active:true` seeded in the checked-in layer and `active:false` in the project-local layer, the hook is **off** (project-local precedence wins).
- [ ] **AC8** (NFR4): A `seed`/toggle whose target path is a pre-planted **symlink** does not write through it (rejected or written atomically to the real intended path); the on-disk file ends mode 0600.
- [ ] **AC9** (FR5): `tool-check-rules.md` documents flag + precedence + seed + config surface; `cwf-manage validate` passes; the hook — and the starter-ruleset file if it ships as data — have hashes refreshed in the same commit as any source edit.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All AC1–AC9 met and traced in g-testing-exec.md. The `enabled` requirement was refined
to the `active` kill-switch (default-true, trusted-layers-only) without weakening any
acceptance criterion.

## Lessons Learned
Refining a requirement's mechanism (enable-gate → kill-switch) mid-flow is fine when
every original AC still holds — the AC → test traceability made that check concrete
rather than a judgement call.
