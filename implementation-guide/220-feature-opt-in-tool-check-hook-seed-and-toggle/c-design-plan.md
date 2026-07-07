# opt-in tool-check hook seed and toggle - Design
**Task**: 220 (feature)

## Task Reference
- **Task ID**: internal-220
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/220-opt-in-tool-check-hook-seed-and-toggle
- **Template Version**: 2.1

## Goal
Define architecture and design decisions for opt-in tool-check hook seed and toggle.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### DK1 — `active` is a top-level settings key, resolved across the **trusted** layers only
- **Decision**: Extend the layer settings schema from `{"rules":[…]}` to
  `{"active": <bool, optional>, "rules":[…]}`. The hook resolves the effective
  `active` **high → low** over the two author-trusted, non-clone layers
  **project-local > user-global**; the first that defines `active` wins. A
  **checked-in** `active` value is **ignored** for kill-switch resolution.
- **Rationale**: A checked-in `active:false` travels via `git clone`, so honouring it
  would let a cloned repo silently disable a downstream user's own user-global rules —
  the same clone-untrusted-layer hazard the code already guards for `perl` rules
  (`load_layer` drops checked-in `perl` before compile). A boolean can't execute code
  and tool-check has no allow-more path, so the harm is bounded (removes nudges, never
  grants capability) — but it is a suppression vector, so we close it by trust boundary,
  not by luck. Ignoring checked-in `active` costs nothing: seeded checked-in rules are
  active anyway via the default (DK2), and the toggle writes project-local. Reuses the
  `layer_paths` order + the decoded HASH the hot path already reads (no new file/lookup),
  satisfying NFR1. AC7 still holds: a project-local `active:false` turns off seeded rules.
- **Trade-offs**: The flag shares a file with `rules`; mitigated by a distinct key name
  (`active`, not the per-rule `enabled`). A repo genuinely wanting to ship "off" cannot
  force it on cloners — acceptable (they opt in locally).

### DK2 — `active` defaults to **true**, and only a JSON **boolean** counts as defining it
- **Decision**: When no trusted layer defines `active`, the effective value is **true**
  (kill-switch, not an enable gate). A layer "defines `active`" **iff the key is a JSON
  boolean** (`JSON::PP` `true`/`false`); any other type (`"false"` string, `0`, `null`,
  array) is **ignored** and falls through to the next layer / the default. An
  `undef`/error layer (symlink, bad JSON, non-HASH — `read_layer_file` → `error`)
  likewise contributes no `active` and is skipped.
- **Rationale**: **Backward-compatible.** Current settings files carry `rules` and no
  `active` key (e.g. the maintainer's user-global set); default-false would silently
  disable every existing rule on upgrade. Default-true keeps today's behaviour (rules +
  no flag → active; no rules → the existing `return unless @$merged` allow). The
  boolean-only rule is a **correctness guard**: a hand-typed `"active":"false"` is
  Perl-truthy, so a naive check would leave the kill-switch ON contrary to intent —
  exactly the failure the flag must never have. Refines **D3**: absent/￢boolean ≡
  today's behaviour (active if rules present, allow if not).
- **Trade-offs**: "Off" must be an explicit JSON `false`; no ambiguous absent-means-off.
  Safer.

### DK3 — Seed → checked-in layer; toggle → project-local layer (resolves D1a/D1b)
- **Decision**: `seed` installs starter rules into the **checked-in**
  `{root}/.cwf/tool-check/bash/settings.json` (shared, regex-only, safe to clone),
  via a **preserving** read-modify-write (`merge_seed`, add-missing-by-`id`). `on`/`off`
  write **only** the **project-local** `settings.local.json` — also a **preserving**
  RMW that flips *only* the `active` key and keeps any local `rules`. `seed` also
  clears a project-local `active:false` so "seed implies on".
- **Gitignore prerequisite (verified gap)**: `.cwf/tool-check/bash/settings.local.json`
  is **not currently gitignored** (`git check-ignore` → NOT-IGNORED; the "(gitignored)"
  notes in `tool-check-rules.md`/hook header never bit because Task 201 shipped inert
  with no writer). Task 220 is the first writer, so the design **adds the ignore entry
  via the existing `gitignore-entries` artefact in `.cwf/install-manifest.json`** (applied
  by `cwf-apply-artefacts`, line-additive) — never by hand-editing `.gitignore`. Without
  this, a toggle leaves an untracked file in `git status` and FR2/AC3 fail.
- **Seed write ordering (F3)**: seed performs two atomic writes (checked-in rules, then
  clear project-local `active:false`). Order is **rules first, then clear the local off**,
  so a crash between them leaves the hook conservatively **still off** (never on-without-
  rules); a re-run reconciles (idempotent). The "seed implies on" is an eventual, re-run-
  convergent guarantee, not a single-atomic one — stated so it is not read as atomic.
- **Rationale**: A live toggle must not dirty tracked state (FR2/AC3); the project-local
  layer (once ignored) is highest-precedence, so a local `off` cleanly overrides a shared
  seeded `on`. Seed is a deliberate, committable team config; toggle is ephemeral/personal.
- **Trade-offs**: Two files carry state. Precedence makes their interaction deterministic;
  `--check` surfaces the resolved value.

### DK4 — Starter ruleset **embedded in the helper**, not a separate data file (resolves S2)
- **Decision**: The regex-only starter set lives as a Perl data structure inside the
  new `tool-check-seed` helper (the single DRY writer), emitted as JSON on seed —
  not shipped as a standalone `.json` under `.cwf/`.
- **Rationale**: A standalone data file read/installed at runtime would be a new
  hashed artefact (else invisible to the allowlist-based `cwf-manage validate`).
  Embedding puts the starter set inside an already-hash-tracked script, so there is
  no unrecorded runtime file and one source of truth. (Security-review S2.)
- **Trade-offs**: Editing the starter set means editing the helper (+ a hash refresh
  in the same commit) — acceptable; the set changes rarely.

### DK5 — Pure policy in `CWF::ToolCheck`, I/O in a thin helper (mirror the hook split)
- **Decision**: New pure functions in `CWF::ToolCheck` (unit-tested, no I/O):
  `resolve_active(\@trusted_decoded_high_to_low)` and `merge_seed(\@existing, \@starter)`
  → `(\@merged, $added, $skipped)`. All file reads/writes live in the helper and
  the hook, mirroring the existing `CWF::ToolCheck` (pure) ↔ hook (impure) split.
- **Directory-creation safety**: the helper creates each missing component of
  `{root}/.cwf/tool-check/bash/` **symlink-safely** (per-level `-d && !-l`, mirroring the
  hook's `ensure_state_dir`) before the atomic file write — the `write_last_denied`
  pattern guards only the target file and assumes a safe parent, so an unguarded
  `mkdir -p` would leave an intermediate-directory symlink vector.
- **Rationale**: Testability-first (top design priority) and consistency with Task 201.

## System Design
### Component Overview
- **`CWF::ToolCheck` (extended)** — add `resolve_active` (precedence walk, default
  true) and `merge_seed` (add-missing-by-`id`, never overwrite → returns added/skipped
  counts for the echo and AC6 no-clobber). Pure, no I/O.
- **`pretooluse-bash-tool-check` (hot-path change)** — `load_merged` also returns the
  decoded layer objects (or their `active` values) in precedence order; after
  `return unless @$merged`, add `return unless resolve_active(...)` **before** the
  compile/match loop. `--check` gains an "Effective active: yes/no" line plus the
  per-layer `active` values.
- **`tool-check-seed` helper (new, `.cwf/scripts/command-helpers/`)** — the single DRY
  writer for `on|off|seed`. Embeds the starter ruleset; symlink-safe dir creation +
  symlink-safe atomic preserving RMW; echoes resulting state inline. **Rejects an unknown
  subcommand** (non-zero, no default write) so a garbled/injected arg can't select an
  action. Invoked by both `/cwf-config` and `/cwf-init`. Offline tooling — never on the
  hook hot path. (No `status` verb — see the `--check` extension below.)
- **`/cwf-config` skill (extended)** — parse `tool-check <on|off|seed>` and dispatch to
  the helper; retains `init|list|reset`.
- **`/cwf-init` skill (extended)** — explicit opt-in confirm (default decline); on
  accept, calls the helper `seed`.
- **Gitignore artefact** — add `.cwf/tool-check/bash/settings.local.json` to the
  `gitignore-entries` in `.cwf/install-manifest.json` (applied by `cwf-apply-artefacts`);
  the manifest is hash-tracked, so its edit refreshes the hash in the same commit.
- **Docs** — `tool-check-rules.md` documents `active`, its trusted-layer precedence, the
  seed, and the toggle; the Task-219 R3 backlog premise corrected.

### Data Flow
1. **Seed** (`/cwf-init` accept, or `/cwf-config tool-check seed`) → helper reads the
   checked-in settings (symlink-safe; absent → `{}`) → `merge_seed(existing, starter)`
   → atomic temp+`O_EXCL`+`rename` write (0600) → clears any project-local
   `active:false` → echoes "seeded N rules (M already present); tool-check active".
2. **Toggle** (`/cwf-config tool-check off|on`) → helper reads/creates project-local
   settings → sets `active:false`/`true` → atomic write → echoes resolved state. No
   git-tracked file touched.
3. **Hook read** (every Bash call) → `load_merged` reads the 3 layers **once** and
   returns the decoded objects alongside the merged rules (no second stat/read pass —
   protects NFR1) → `return unless @$merged` (no rules) → `return unless
   resolve_active(<project-local, user-global decoded>)` (kill-switch, before any
   compile/match) → bounded first-match-wins loop → deny/allow/bypass (unchanged).

**Known degradation (F2)**: if a project-local layer that held `active:false` later
becomes unreadable/corrupt (symlink, bad JSON), `read_layer_file` yields `error`,
`resolve_active` skips it and falls through to default-**true** — the hook silently comes
back **on**. This is consistent with the deny-is-safe posture (a broken kill-switch fails
toward *more* nudging, never toward capability). Recovery affordance: `--check` surfaces
the per-layer `active` values, and re-running `off` restores the intent. Documented, not
smoothed.

## Interface Design
### Settings schema (extended, backward-compatible)
```
{
  "active": true | false,      // OPTIONAL, JSON boolean only. Absent/non-boolean ⇒ falls through (DK2).
  "rules": [ { "id", "regex"|"perl", "guidance" }, ... ]   // unchanged
}
```
Effective `active` = first **JSON-boolean** `active` across the **trusted** layers
high→low (project-local, then user-global); a **checked-in** `active` is ignored (DK1);
default **true**. Per-rule `enabled:false` (disable directive) is unchanged and orthogonal.

### `tool-check-seed` helper CLI
```
tool-check-seed on      # project-local: set active:true (preserving RMW; clears a prior off)
tool-check-seed off     # project-local: set active:false (preserving RMW; keeps local rules)
tool-check-seed seed    # merge starter rules into checked-in layer, then imply on
<unknown>               # exit non-zero, usage to stderr, NO write
```
Exit 0 on success; non-zero + stderr on a hard failure or unknown subcommand. Being
offline tooling, its exit never affects the fail-open hook. Writes create parent dirs
symlink-safely (per-level `-d && !-l`) then write via the `write_last_denied` pattern
(reject `-l` target, temp + `O_EXCL` + `rename`, mode 0600). State is echoed inline after
each op; the standalone "what's active now" query is the hook's existing **`--check`**
(extended with an "Effective active" line + per-layer `active` values) — no separate
`status` verb.

### Pure functions (`CWF::ToolCheck`)
```
resolve_active(\@trusted_decoded_high_to_low) -> 1|0
    # first layer whose `active` is a JSON boolean wins; undef/error/non-boolean skipped; default 1
    # caller passes ONLY project-local + user-global decoded objects (checked-in excluded per DK1)
merge_seed(\@existing_rules, \@starter_rules) -> (\@merged, $added, $skipped)
    # append starter ids absent from @existing; never overwrite an existing id
```

## Security rationale (carry-forward from best-practice review)
Fail-open here is **not** a "fail-secure" violation. The hook only ever *denies/nudges*
away from prompt-tripping commands; it has **no allow-more path**. So failing open
(on a malformed/absent/symlinked flag or settings) reverts to the **native Claude Code
permission check** — it never bypasses a security gate, it declines to add a
convenience nudge. A later reviewer applying a generic "fail closed" checklist should
read NFR5 in that light. The new writes are the security-sensitive surface and are held
to fail-*closed* discipline (symlink-safe dirs + atomic 0600 files) per NFR4. The one
cross-trust concern — a clone-travelling checked-in `active:false` suppressing a cloner's
own rules — is closed at the trust boundary in DK1 (checked-in `active` ignored), mirroring
the existing checked-in `perl` drop.

## Constraints
- Perl core-only; POSIX; fail-open hot path non-negotiable.
- `pretooluse-bash-tool-check` and `CWF::ToolCheck.pm` are hash-tracked → any edit
  refreshes `script-hashes.json` in the **same commit**; the new helper is added to
  the hashed set on creation.
- The starter set is regex-only (DK4/DK3) — never a `perl` rule (checked-in layer would
  drop it anyway).
- Whether **this repo** seeds a checked-in starter set is a rollout decision (h phase),
  not part of this design — the maintainer already runs a richer user-global set.

## Decomposition Check
Unchanged: 1 borderline signal (complexity) — the pure-lib / hook / helper / skills
split is cohesive around one settings contract. **Do not decompose.**

## Validation
- [x] Design grounded against actual source (`pretooluse-bash-tool-check`, `CWF::ToolCheck.pm`, hook layer model)
- [x] Reuses existing precedence, perl-drop, and atomic-write machinery — no reinvention
- [x] Plan review (design) complete — 5 reviewers; applied cross-trust suppression fix (DK1), boolean-only `active` coercion (DK2), gitignore-entry gap (DK3), seed write-ordering + preserving RMW (DK3), symlink-safe dir creation + unknown-subcommand reject (DK5), dropped the redundant `status` verb, documented the corrupt-layer re-activation degradation (F2). Mechanical-check `{root}` path finding adjudicated a false positive (literal placeholder / the file `seed` creates). Best-practice domain-mismatched (golang/postgres) — no action.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Design keys DK1–DK5 followed. One design decision was strengthened in exec: the
`trusted_layers` ordering, specified per-caller here, was single-sourced into the pure
`CWF::ToolCheck` module after the improvements reviewer flagged the duplication.

## Lessons Learned
A trust boundary named in the design (project-local > user-global, checked-in excluded)
must land as one pure, unit-tested function — designing it as a shared *rule* is not
enough if two callers each implement it.
