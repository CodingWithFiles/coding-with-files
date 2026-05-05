# fix install allowlist and hook enablement - Design
**Task**: 126 (bugfix)

## Task Reference
- **Task ID**: internal-126
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/126-fix-install-allowlist-and-hook-enablement
- **Template Version**: 2.1

## Goal
Specify a single, manifest-driven helper that mutates `.claude/settings.json` to register the right `Bash(...)` allowlist entries and `Stop` hook entries. `/cwf-init` calls the helper; the helper is the only writer.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### KD1: New helper script, not inline Perl in SKILL.md
- **Decision**: Add `.cwf/scripts/command-helpers/cwf-claude-settings-merge` (Perl, like the rest of `command-helpers/`). `/cwf-init` invokes it as a new addition — the existing Step 6 (Skill registration) and Step 6c (PreToolUse rule re-injection) stay unchanged. The helper handles the missing piece: `Bash(...)` allowlist entries and `Stop` hook registration, neither of which Step 6 or 6c touch today.
- **Rationale**: Inline Perl in SKILL.md (the current pattern at Step 1a/Step 6c) is not directly testable. A helper is reachable from `t/` with a fixture-based test. It also auto-joins the integrity manifest via Task 125's coverage guard, so dropping its `script-hashes.json` entry would fail `prove -r t/` immediately.
- **Trade-offs**: One more file to maintain; balanced by avoiding ~50 lines of prose-described JSON manipulation in SKILL.md and producing a re-usable script (callable later from `cwf-manage update`).

### KD2: The integrity manifest is the source of truth for the allowlist
- **Decision**: The helper walks `.cwf/security/script-hashes.json` `scripts` section to derive allowlist entries. No hard-coded list of helpers in either the helper or `cwf-init`.
- **Rationale**: Task 125 made the manifest the canonical inventory of every executable script under `.cwf/scripts/**`. Re-using it eliminates drift: any new helper added under Task 125's coverage guard automatically becomes an allowlist entry the next time `/cwf-init` runs.
- **Trade-offs**: Couples the helper to manifest schema (`scripts.<key>.path`). Schema is stable (used by `Validate::Security`, `cwf-manage validate`, `validate-security-coverage.t`). If schema changes in future, all three readers update together.

### KD3: Allowlist scope rules — top-level only
- **Decision**: Emit allowlist entries only for these manifest paths:
  - `.cwf/scripts/cwf-manage` → `Bash(.cwf/scripts/cwf-manage:*)`
  - `.cwf/scripts/command-helpers/<name>` (top-level, no `/` after `command-helpers/`) → `Bash(.cwf/scripts/command-helpers/<name>:*)`
  - `.cwf/scripts/hooks/<name>` → `Bash(.cwf/scripts/hooks/<name>)` (exact, no glob — see KD4)
  - **Skip** `.cwf/scripts/command-helpers/<parent>.d/<sub>` — invoked by the parent trampoline, not by Claude Code; matched via the parent's `:*` glob.
  - **Skip** lib paths and migration scripts — not Claude-Code-invocable.
- **Trampoline invariant**: The `.d/` skip-rule is safe only while parent trampolines invoke their `.d/` subcommands directly (`exec` or in-process Perl call). If a future trampoline shells out to a sub-script via `system("$dir/parent.d/$sub")` etc., that sub becomes Claude-Code-reachable and would need its own entry. The helper documents this invariant inline near the partition logic; the f-phase implementation must include a comment in the helper code calling out the invariant for future maintainers.
- **Defensive path validation**: Before classifying, the helper rejects any manifest path that does not start with `.cwf/scripts/` or that contains `..` segments. Refusing such paths is FR4(b) hygiene; in practice the manifest never contains them, but the check is a few lines and prevents a tampered manifest from injecting a broader allowlist.
- **Existence check**: The helper also stats each path; if a manifest entry's file is missing on disk (mid-update / partial install), it skips the entry and warns. Avoids registering allowlist globs for files that aren't present.
- **Rationale**: Same partitioning as `validate-security-coverage.t` from Task 125. Adding `.d/` entries would clutter the allowlist with paths Claude Code never sees directly.
- **Trade-offs**: Two consumers now duplicate ~10 lines of partition logic (this helper + the coverage test). Rule-of-three says wait before factoring into `CWF::Manifest::Partition`; if a third consumer appears, refactor then.

### KD4: Entry shape — `:*` for helpers, exact for hooks
- **Decision**: Two shapes:
  - Helpers / `cwf-manage`: `Bash(<path>:*)` (Claude Code matcher: matches `<path>` followed by any string, including subcommands and args).
  - Hooks: `Bash(<path>)` exact (hooks are invoked by Claude Code's hook system as bare commands with no args).
- **Rationale**: The `<path>:*` form is what every working entry in this repo's `.claude/settings.local.json` for command-helpers uses (`cwf-manage:*`, `task-workflow:*`, `context-manager:*`). The exact form for hooks matches lines 68–69 of `.claude/settings.local.json` (the two CWF hooks already there as exact entries).
- **Trade-offs**: A trailing `*` form (`<path> *`) also exists in this repo's settings — evidence both work, but the `:*` form is the canonical one used for the majority of helper entries.

### KD5: Hook registration shape mirrors the working `.claude/settings.local.json`
- **Decision**: When `hooks.Stop` is absent: create
  ```json
  "hooks": { "Stop": [ { "hooks": [
      { "type": "command", "command": ".cwf/scripts/hooks/stop-stale-status-detector",   "timeout": 5 },
      { "type": "command", "command": ".cwf/scripts/hooks/stop-uncommitted-changes-warning", "timeout": 5 }
  ] } ] }
  ```
  When `hooks.Stop` exists: **scan every matcher object's `hooks[]` array** for each CWF hook command (exact string match). If a CWF hook is already present anywhere under `hooks.Stop[]`, leave it. If absent, append it to `hooks.Stop[0].hooks[]` (creating that matcher if `hooks.Stop` is empty).
- **Rationale**: Matches lines 109–125 of this repo's `.claude/settings.local.json` (the working reference). Scanning all matchers (rather than only `hooks.Stop[0]`) makes idempotency robust against the case where a downstream user has manually moved a CWF hook into a different matcher object. This is cheap (linear scan over a typically-tiny array) and removes the only sharp edge on KD5's idempotency contract.
- **Trade-offs**: New entries always land in `hooks.Stop[0]` even if the existing match was found elsewhere — we don't try to reorganise the user's matcher layout. Append-only.

### KD6: PreToolUse rule-injection hook stays as-is
- **Decision**: This task does not touch Step 6c (the rule re-injection hook). The new helper handles `Stop` only.
- **Rationale**: Step 6c works in this repo. The bug report is about CWF-specific Stop hooks not being registered. Mixing concerns risks regressing Step 6c's working behaviour.
- **Trade-offs**: Eventually the helper could absorb Step 6c's logic too (one writer for `.claude/settings.json`). Out of scope for the bugfix.

### KD7: JSON merge semantics — additive, idempotent, structure-preserving
- **Decision**:
  - Verify `.claude/settings.json` is either absent or a regular file (not symlink, not directory) before reading. Refuse otherwise with a clear error — protects against `.claude/settings.json` symlinked to `~/.claude/settings.json` being clobbered.
  - Read existing `.claude/settings.json` (or start from `{}`).
  - For `permissions.allow`: extend with new entries; de-dup by exact string. Preserve original order; append new entries.
  - For `hooks.Stop`: see KD5.
  - Write back via `JSON::PP->new->pretty->canonical->indent_length(2)` for stable diffs (precedent: `.cwf/lib/CWF/Versioning.pm:157`).
  - Atomic write: see KD10.
- **Rationale**: The user may have hand-edited entries unrelated to CWF. Round-tripping with `pretty + canonical` and additive semantics keeps the diff small and readable. The file-type check catches a small but real footgun for users with cross-machine config sharing.
- **Trade-offs**: `canonical` reorders keys alphabetically, which differs from the current free-form ordering in this repo's `settings.local.json`. The reorder happens once on first write; subsequent runs are idempotent. House style — same encoder chain in `CWF::Versioning`.

### KD8: CLI surface
- **Decision**: `cwf-claude-settings-merge [--dry-run]`. With no flags: reads `.cwf/security/script-hashes.json`, writes `.claude/settings.json` (creating it if absent), prints `[CWF] settings: added N allowlist entries, M hook entries`. With `--dry-run`: same merge logic, prints the proposed file contents to stdout, makes no on-disk changes. Exit 0 on success; non-zero with `[CWF] ERROR: <message>` on parse/write failure. All log output uses `[CWF] ` prefix to match the existing `cwf-manage` / `/cwf-init` Step 1a convention.
- **Rationale**: One job; one optional dry-run flag for inspection before commit. Cheap (~5 lines) and lets `/cwf-init` users preview the merge if curious. `[CWF]` prefix is the consistent project marker.
- **Trade-offs**: Slightly larger CLI surface than zero-arg, but `--dry-run` is the only universal CLI affordance worth adding.

### KD9: Re-execution model
- **Decision**: Helper is fully idempotent. Re-running after new helpers are added (e.g. after a `cwf-manage update`) refreshes the allowlist additively. Documented in `cwf-init/SKILL.md` Step 6.
- **Rationale**: The drift between manifest changes and `.claude/settings.json` is unavoidable without an automatic refresh on update. Manual re-run is a low-friction workaround. Out of scope for this task: wiring this into `cwf-manage update` (BACKLOG candidate).
- **Trade-offs**: Users must remember to re-run after updates. Documented in CHANGELOG as a known workflow.

### KD10: Atomic write
- **Decision**: Write the merged JSON to a sibling temp file (`.claude/.settings.json.tmp.<pid>`) then `rename()` over `.claude/settings.json`. The same pattern used by `.cwf/lib/CWF/Versioning.pm` (`bump_to`, lines 119–135). On rename failure the temp file is removed and the helper exits non-zero — the existing `.claude/settings.json` is never partially overwritten.
- **Rationale**: Removes any partial-write window from concurrent `/cwf-init` invocations or kill-during-write scenarios. Cheap and idiomatic in Perl.
- **Trade-offs**: One extra file briefly exists during write; cleanup handled by the helper's exit path.

### KD11: Run order with `/cwf-init` Step 1a
- **Decision**: The helper runs **after** `/cwf-init` Step 1a (`cwf-manage fix-security`). Step 1a verifies `.cwf/security/script-hashes.json` against on-disk SHA256s before any other init step touches the manifest. By the time the helper reads the manifest, it has just been validated; the read window is bounded by the helper's own runtime (no user prompts, no shell-out) so a TOCTOU attack would have to land between `fix-security` exit and the helper's `open()`, on the same `/cwf-init` invocation.
- **Rationale**: The integrity manifest is FR4(d)-protected by Step 1a; re-validating in this helper would duplicate work without changing the trust model. The helper still parses the JSON defensively (KD7 file-type check, KD3 path validation) so a malicious manifest can't broaden the allowlist beyond `.cwf/scripts/`.
- **Trade-offs**: A determined attacker who can run code between Step 1a and Step 6 can theoretically substitute the manifest. Out of scope; CWF is not designed to defend against attackers with arbitrary code-execution on the install host.

## System Design

### Component Overview
- **`cwf-claude-settings-merge`** (new helper, Perl): one-shot CLI that reads `.cwf/security/script-hashes.json` + existing `.claude/settings.json` and writes the merged result back. ~80 lines.
- **`cwf-init/SKILL.md` Step 6** (modified): replaces inline Perl with a single `cwf-claude-settings-merge` call, after the existing `Skill(cwf-*)` registration block (which stays).
- **`t/cwf-claude-settings-merge.t`** (new): fixture-driven test covering: empty input, partial input (some entries already present), populated input with unrelated user entries, hook merge into existing `Stop` matcher.
- **`.cwf/security/script-hashes.json`** (modified): one new entry for `cwf-claude-settings-merge` itself (otherwise `validate-security-coverage.t` fails — the Task 125 guard kicks in).
- **`docs/conventions/`** (no changes): the manifest-as-source-of-truth pattern is established by Task 125.

### Data Flow
1. `/cwf-init` Step 1a runs `cwf-manage fix-security` (existing). Manifest is now trustworthy (KD11).
2. `/cwf-init` invokes `cwf-claude-settings-merge` after Step 6 (Skill registration) and Step 6c (PreToolUse rule injection) — both stay unchanged.
3. Helper validates `.claude/settings.json` is absent or a regular file (KD7).
4. Helper reads `.cwf/security/script-hashes.json`, applies KD3 partition + path validation + on-disk existence check, builds the desired allowlist + hook objects.
5. Helper reads `.claude/settings.json` (or `{}`), merges per KD5/KD7.
6. Helper writes the merged JSON to `.claude/.settings.json.tmp.<pid>` and atomically renames over `.claude/settings.json` (KD10).
7. Helper prints `[CWF] settings: added N allowlist entries, M hook entries`; exits 0.
8. `/cwf-init` continues to its next step.

### Interface
- **Helper CLI**: `cwf-claude-settings-merge` (no args).
- **Output**: stdout summary line; exit 0 on success.
- **Side effects**: writes `.claude/settings.json` (creates dir if absent).

### Data Model — derived allowlist entries
For each `scripts.<key>` entry in the manifest where `path` matches:
| Path pattern                                     | Allowlist entry shape                          |
|--------------------------------------------------|------------------------------------------------|
| `.cwf/scripts/cwf-manage`                        | `Bash(.cwf/scripts/cwf-manage:*)`              |
| `.cwf/scripts/command-helpers/<name>`            | `Bash(.cwf/scripts/command-helpers/<name>:*)`  |
| `.cwf/scripts/command-helpers/<parent>.d/<sub>`  | (skipped per KD3)                              |
| `.cwf/scripts/hooks/<name>`                      | `Bash(.cwf/scripts/hooks/<name>)` exact        |
| anything else                                    | (skipped — out of scope)                       |

## Failure Modes
- **Manifest missing or unreadable**: helper exits non-zero with `[CWF] ERROR: cannot read script-hashes.json`. Caller (`cwf-init`) propagates the error and aborts (matches Step 1a's existing model).
- **`.claude/settings.json` malformed**: helper exits non-zero with `[CWF] ERROR: cannot parse .claude/settings.json`. User must hand-fix; we do not overwrite a malformed file.
- **`.claude/settings.json` is not a regular file** (symlink, directory, fifo): helper exits non-zero with `[CWF] ERROR: .claude/settings.json must be a regular file (found <type>)`. Refuses to overwrite to protect cross-machine config setups.
- **Manifest entry missing on disk**: helper warns `[CWF] WARN: manifest entry <path> not found on disk; skipping` and continues with the entries that do exist. Does not fail the run — partial coverage is better than no coverage during mid-update windows.
- **Manifest path outside `.cwf/scripts/` or contains `..`**: helper exits non-zero with `[CWF] ERROR: refusing manifest path: <path>`. FR4(b) defence.
- **Disk write failure**: helper exits non-zero with `[CWF] ERROR: cannot write .claude/settings.json`. No partial writes (atomic temp + rename, KD10).

## Security Considerations
- **FR4(a) command-injection**: helper does not invoke any subshell. All file I/O is Perl primitives.
- **FR4(b) path traversal**: paths are read from a tracked-in-repo manifest. We refuse paths that escape `.cwf/scripts/` (defensive — should never happen given the manifest source).
- **FR4(c) prompt injection**: helper writes JSON only; no Markdown / model-readable surface.
- **FR4(d) integrity drift**: helper itself joins the integrity manifest. Tampering with it produces a sha256 violation in `cwf-manage validate`.
- **FR4(e) attack-surface introduction**: helper writes only to `.claude/settings.json`, only adds entries the manifest blesses, only registers hooks that already ship with CWF and are themselves integrity-tracked. No new exec, no new env-var read.
- **Out of scope**: validating that the user's existing settings.json is itself benign — we trust the existing file's structure.

## Constraints
- Perl 5.10+ core only (`JSON::PP`, `File::Temp`, `File::Spec`, `FindBin`).
- Must include `use utf8;` (memory rule).
- Must work whether `.claude/settings.json` is absent, empty `{}`, or fully populated.
- Output JSON: 2-space indented, canonical key order, trailing newline.

## Decomposition Check
- [ ] **Time**: >1 week? — No.
- [ ] **People**: >2 people? — No.
- [ ] **Complexity**: 3+ distinct concerns? — No, one helper + one SKILL.md edit + one test.
- [ ] **Risk**: high-risk components? — No.
- [ ] **Independence**: separable? — No, the SKILL.md edit and the helper are paired.

**Decision**: No decomposition.

## Validation
- [ ] Helper signature and CLI surface match KD8 (zero-arg + `--dry-run`).
- [ ] Manifest partition rule matches `t/validate-security-coverage.t` (single source of truth for top-level vs `.d/`).
- [ ] Allowlist entry shape matches working entries in `.claude/settings.local.json`.
- [ ] Hook merge preserves user-added Stop hooks; scans all matcher objects for CWF hook commands before appending (KD5 idempotency contract).
- [ ] Atomic write (KD10) used: temp file + rename; partial-write window closed.
- [ ] Re-running the helper produces no diff (idempotency).
- [ ] Manifest with a missing-on-disk entry produces a warning, not a failure.
- [ ] `.claude/settings.json` as symlink or directory is refused with a clear error.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
