# upgrade installs cwf-init artefacts - Design
**Task**: 127 (feature)

## Task Reference
- **Task ID**: internal-127
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/127-upgrade-installs-cwf-init-artefacts
- **Template Version**: 2.1

## Goal
Specify the architecture, file layout, manifest schema, and integration points for the artefact-apply mechanism that closes the gap requirements b- identified between `/cwf-init` and `cwf-manage update`.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### D1 — Single Perl helper, no `.d/` subcommand split
**Decision**: A single Perl script `.cwf/scripts/command-helpers/cwf-apply-artefacts` is the only new entry point. No subcommand pattern (`<name>.d/<sub>`) — the helper has one job: read inventory, compare three states, apply or prompt.

**Rationale**: One responsibility. The subcommand pattern (`context-manager.d/`, `task-workflow.d/`, `workflow-manager.d/`) is reserved for helpers with multiple distinct verbs. Adding `.d/` here would invite future bloat (`apply-artefacts.d/diff`, `.../prompt`, `.../merge`) when those should remain internal Perl subroutines.

**Trade-offs**: Cannot independently version sub-actions; mitigated by keeping the helper small.

### D2 — Two roles: `@INVENTORY` (policy) + `install-manifest.json` (per-release data)
**Decision**: Strict separation of concerns:
- **`@INVENTORY`** (Perl array of hashrefs at the top of `cwf-apply-artefacts`) is the **policy table**: per artefact category, what strategy to apply (`replace`, `tree-replace`, `embedded-block`, `regenerate-symlinks`, `line-additive`, `merge-json`), what container if any (`CLAUDE.md` for the embedded preamble), and where the baseline comes from (`install-manifest`, `script-hashes`, `derived`). Stable across releases. Each entry: `{ id, strategy, container?, baseline_source }`.
- **`.cwf/install-manifest.json`** is the **per-release data**: for each artefact id mentioned in `@INVENTORY` whose `baseline_source` is `install-manifest`, what the source/dest paths and content checksums are at THIS release. Changes every release.

The dispatcher iterates `@INVENTORY`, looks up data for each id in the manifest if needed, and calls `apply_$strategy(...)`.

**Rationale**: The policy table changes only when CWF gains a new artefact category (rare). The manifest changes every release (common). Keeping them in different files matches their change cadence and avoids touching policy code on every release. NFR3's "data-driven" is satisfied — adding an artefact category means one new `@INVENTORY` row + one new manifest entry, no `if` branches.

**Trade-offs**: Two places to edit when adding a new artefact category. Acceptable: it's an explicit pair (policy + data) and the validate step (D12) detects mismatches.

### D3 — Per-file baselines via NEW manifest `.cwf/install-manifest.json`
**Decision**: Non-script artefact baselines live in `.cwf/install-manifest.json`, shipped by every CWF release from this version forward. Schema in §"Data Models" below. Script baselines continue to come from `.cwf/security/script-hashes.json` — unchanged.

**Rationale**: `script-hashes.json` is structured around scripts (path + sha256 + permissions); shoehorning content artefacts (CLAUDE.md preamble, gitignore lines, rule files) would distort it. A separate manifest keeps each file single-purpose.

**Trade-offs**: Two manifests must be kept in sync at release time; mitigated by `cwf-manage validate` extension (see Component Overview, D12) and by Task 125's existing hash-discipline workflow.

### D4 — FR9 bootstrap: treat-on-disk-as-baseline (silent additive, prompt on `replace`)
**Decision**: When upgrading from a project with no `install-manifest.json` (i.e. the currently-installed version predates this feature):
- For `merge-json` artefacts: apply silently (already idempotent — Task 126's `cwf-claude-settings-merge` only adds missing entries).
- For `merge-text` artefacts (`.gitignore`): apply silently if the new lines are absent on-disk; otherwise no-op (additive only).
- For `replace` artefacts (`.cwf-rules/` content, CLAUDE.md preamble, `.cwf/rules-inject.txt`): treat on-disk as baseline. If `on-disk == new`, no-op silently. If different, prompt (FR4) — we can't tell user-modified from "this is what we shipped last time".

**Rationale**: Justified against `feedback_design_tradeoff_priority` (correctness > maintainability > performance):
- **Correctness**: Worst case is one transient prompt per `replace` artefact on the first post-feature upgrade — user picks "I" to align with the new version, or "K" to keep their edits. No silent loss of user content; no silent override of new content. After this upgrade, the manifest exists and subsequent upgrades use the proper three-way logic.
- **Maintainability**: One bootstrap branch in the helper, not two flows. Rejected the alternative ("require user to re-run /cwf-init first") because it forks the upgrade UX and adds an explicit migration step — worse maintainability.
- **Performance**: irrelevant.

**Trade-offs**: One round of unavoidable prompts per `replace` category for users on the very first upgrade after this ships. Documented in CHANGELOG / rollout phase.

### D5 — Atomicity strategy: per-file temp+rename, no batch backup
**Decision**: Each artefact write uses same-directory temp-file + `rename`, matching `cwf-claude-settings-merge`'s pattern. No whole-batch backup-and-restore.

**Rationale**: The artefact set is small and the write order is deterministic. A mid-run abort leaves at most the artefacts processed so far in their NEW state and the rest in their OLD state — both states are valid (each file is internally consistent), and re-running `cwf-manage update` will resume cleanly because the helper is idempotent: for already-applied items, `on-disk == new` → FR3 case 2 → no-op; for unapplied items, `on-disk == baseline` → FR3 case 3 → install. This also covers `--bootstrap-init` recovery: bootstrap mode writes `on-disk = new` for each artefact in turn, so a re-run in the same mode finds `on-disk == new` for already-applied items and treats them as no-ops; alternatively, re-running in default `cwf-manage update` mode produces the same result via FR3 (the helper does not depend on which mode the prior run used). Whole-batch backup adds transient disk usage and a restore failure mode without buying meaningful safety.

**Trade-offs**: Aborted runs leave a partially-upgraded artefact set. Mitigation: clear logging of which artefacts were applied vs skipped, and FR6 idempotency guarantees a re-run finishes the job.

### D6 — CLAUDE.md preamble: sentinel markers
**Decision**: The preamble is wrapped in HTML-comment sentinels:
```
<!-- CWF-PREAMBLE-START — do not edit between markers; user notes go above or below this block -->
> **CWF (Coding with Files) is installed in this project.**
> ...
<!-- CWF-PREAMBLE-END -->
```
The helper extracts the region between sentinels and treats it as the "preamble file" for FR3 comparison. If sentinels are missing (legacy install from current `/cwf-init`), the helper detects the legacy block via the existing `grep -q "CWF.*is installed"` heuristic, wraps the matched block (and only the contiguous blockquote lines beginning with `>`) in sentinels in-place, and proceeds.

The opening sentinel itself carries the user-facing warning. If a user adds their own content **between** the markers and CWF later detects a conflict, FR4's "Install" option will overwrite that content — this is documented behaviour. User notes belong outside the markers.

**Rationale**: Sentinels make the CWF-owned region explicit and machine-locatable; the in-marker warning communicates ownership at the point of editing; the legacy detection-and-wrap path migrates existing installs without prompting the user. After this task, `/cwf-init` step 4 also writes the sentinels.

**Trade-offs**: If the user deletes the sentinels, the helper falls back to the legacy heuristic; if that also fails (no `CWF.*is installed` line found), it inserts a fresh sentinel block at the top (matching `/cwf-init` original behaviour). Wrap-in-place is conservative — it only wraps contiguous `>`-prefixed lines starting from the matched line, so user content on adjacent non-blockquote lines is left outside the sentinels.

### D7 — Settings.json: subprocess-call to `cwf-claude-settings-merge` (Skill perms, Bash allowlist, Stop hooks)
**Decision**: For the three `merge-json` rows already in the helper's scope (Skill perms, Bash allowlist, Stop hooks — table rows 3, 4, 5), `cwf-apply-artefacts` does NOT reimplement merge logic — it shells out to `.cwf/scripts/command-helpers/cwf-claude-settings-merge` using `system(@list)` form (no shell):

```perl
my $rc = system('.cwf/scripts/command-helpers/cwf-claude-settings-merge');
if ($rc != 0) {
    die "[CWF] ERROR: cwf-claude-settings-merge failed (status $rc); ".
        ".claude/settings.json may be partially updated. Re-run 'cwf-manage update' after resolving the underlying error.\n";
}
```

The PreToolUse:UserPromptSubmit hook (table row 6) stays where it is today — registered by `/cwf-init` SKILL.md step 6c. We do **not** extend `cwf-claude-settings-merge`'s scope in this task. The hook content is fixed (`cat .cwf/rules-inject.txt 2>/dev/null || true`), so once installed it does not need re-application; the file it reads (`.cwf/rules-inject.txt`) is the upgrade-eligible artefact (table row 9).

If on a future upgrade the hook command itself needs to change, that becomes a separate task: it requires extending `cwf-claude-settings-merge` to own PreToolUse and revising this design.

**Rationale**: One source of truth for the settings.json categories the existing helper already owns; minimum scope creep; reuses Task 126's path validation, atomic writes, and tests. Subprocess vs. in-process is fine — invoked once per update, not per artefact.

**Trade-offs**: Subprocess overhead (~50 ms once per update — well within NFR1). Two settings-touching paths (the helper for permissions+hooks; `/cwf-init` step 6c for PreToolUse), but each is single-purpose and idempotent.

### D8 — Concurrency: Perl `flock(LOCK_EX|LOCK_NB)` on `.cwf/.update.lock`
**Decision**: After `cmd_update` reads `.cwf/version` (so `.cwf/` is known to exist), take an exclusive non-blocking lock using Perl's built-in `flock(2)` syscall:

```perl
use Fcntl qw(:flock O_RDWR O_CREAT O_NOFOLLOW);
# Reject symlinks at the lock path to prevent symlink-TOCTOU.
if (-l '.cwf/.update.lock') {
    die "[CWF] ERROR: .cwf/.update.lock is a symlink; refusing to lock\n";
}
sysopen(my $lock_fh, '.cwf/.update.lock', O_RDWR|O_CREAT|O_NOFOLLOW, 0600)
    or die "[CWF] ERROR: cannot open .cwf/.update.lock: $!\n";
flock($lock_fh, LOCK_EX|LOCK_NB)
    or die "[CWF] ERROR: another cwf-manage update is in progress ".
           "(lock: .cwf/.update.lock); wait for it to finish or remove the ".
           "lock if stale\n";
# $lock_fh stays open for the duration of cmd_update — closing releases the lock.
```

The lock file is registered in `.gitignore` (via the `gitignore-entries` manifest row).

**Rationale**: `flock(2)` is POSIX, kernel-managed (auto-releases on process exit including SIGKILL), and zero-state. Non-blocking + clear error beats blocking-and-waiting (the latter masks runaway processes). `O_NOFOLLOW` + the `-l` precheck close the symlink-TOCTOU window: even if a malicious process creates `.cwf/.update.lock` as a symlink between the check and the open, `O_NOFOLLOW` makes `sysopen` fail rather than open the link target.

**Trade-offs**:
- Lock acquired AFTER `read_version_file()` so `.cwf/` is guaranteed to exist; if `.cwf/` is missing, the existing `read_version_file` error fires first ("No .cwf/version file found — is CWF installed?"), which is the right user-facing message.
- `O_NOFOLLOW` is POSIX (Linux, macOS, BSDs) — not available on Windows, but CWF is POSIX-only.
- SIGKILL during an in-flight `rename()` inside `cwf-claude-settings-merge` is benign: kernel rename is atomic on a single filesystem, so settings.json is either the old or new version, never partial. Stale `.settings.json.XXXXXX` temp files may remain; they are safe to delete.

### D9 — `/cwf-init` calls the same helper
**Decision**: `/cwf-init` SKILL.md gains a new step that invokes `cwf-apply-artefacts --bootstrap-init` after the existing scaffolding. In `--bootstrap-init` mode the helper still performs FR3 three-way detection per artefact, but resolves any conflict by **silently installing the new version and logging `[CWF] INFO: bootstrap-init overwrote pre-existing <id>`**. This is not a "skip detection" mode — it's an "install-policy" mode where the user has already opted in (by running `/cwf-init`) to populate a fresh project.

`cwf-claude-settings-merge` continues to be called separately by step 6d (no change there) — `cwf-apply-artefacts` only handles non-settings artefacts in `--bootstrap-init` mode to avoid double-merging settings.json.

**Rationale**: FR10's shared code path. The `--bootstrap-init` flag is a thin wrapper around the same iteration loop, switching the conflict policy to "install-and-log". Every overwrite is logged so a user reviewing the init output can see exactly which pre-existing files were replaced — this addresses the half-installed-project edge case (interrupted `install.bash`, accidental file in `.cwf-rules/`, or hostile placement) by making it visible rather than silent.

**Trade-offs**: Two related modes (`--bootstrap-init` for fresh installs, default for updates). Documented in `--help`. A user who runs `/cwf-init` over a project containing edited rule files will lose those edits; this is consistent with `/cwf-init`'s existing semantics as a fresh-install command.

### D10 — Secrets-in-diff redaction
**Decision**: Hard-coded redaction list (no user config — keep it simple): `.claude/settings.json`, files matching `\.env(\..*)?$`. For these, option D (FR4 diff) prints `[CWF] diff suppressed for <path> — file may contain secrets; inspect manually with: git diff --no-index <on-disk> <new-source>` and re-prompts. No partial redaction (no risk of incomplete masking missing a secret).

**Rationale**: Simplest correct option. The user can still see the diff outside the prompt by running the printed command. Configurable redaction adds complexity for negligible benefit at our scale.

**Trade-offs**: User must take an extra step to inspect settings diffs. Acceptable. CWF forks that add custom secret-bearing artefacts must add their paths to the hard-coded list (one-line code change).

### D11 — Manifest schema-version skew
**Decision**: Both manifests carry `"schema_version": <int>`. On update, `cwf-apply-artefacts`:
- Reads the source manifest's `schema_version`.
- Reads the installed manifest's `schema_version` (if present).
- If they differ:
  - **Source newer than installed**: proceed; this is the expected upgrade case. The helper handles only `schema_version == 1` in this task; if `source > 1`, it logs `[CWF] ERROR: source manifest schema_version=<N> not supported by this helper; upgrade cwf-manage first` and exits non-zero. (Practically unreachable until we ship a v2 schema.)
  - **Source older than installed**: rollback case. Same behaviour: log error and exit non-zero. The user should `cwf-manage rollback` to a matching ref.
  - **Source missing manifest entirely**: handled by FR9 (skip non-script artefacts, log WARN, exit 0).

**Rationale**: Conservative. We don't have a migration story yet because we're shipping v1; the policy "supported set is hard-coded per release" trades flexibility for correctness, which matches `feedback_design_tradeoff_priority`. A future task can add migration shims when v2 lands.

**Trade-offs**: A user who installed at a future v2 manifest and rolls back to a v1 helper hits the error and must rollback further. Acceptable — rollback already requires `cwf-manage rollback <ref>`, which is an explicit operation.

### D12 — Manifest integrity: pin sha alongside `cwf_sha`
**Decision**: `.cwf/version` gains a new field `cwf_install_manifest_sha` containing the SHA256 of the installed `.cwf/install-manifest.json` at install/upgrade time. On update:
1. Compute SHA256 of the **on-disk** `.cwf/install-manifest.json`.
2. Compare against `cwf_install_manifest_sha` in `.cwf/version`.
3. Mismatch → `[CWF] ERROR: .cwf/install-manifest.json content does not match .cwf/version (cwf_install_manifest_sha); the manifest may have been tampered with. Restore with 'git checkout -- .cwf/install-manifest.json' or run 'cwf-manage update' to reinstall.` Exit non-zero.

The cloned source's manifest does NOT need a separate sha pin: the source comes from a verified git ref (the `cwf_sha` field already pins the commit), so the source manifest's content is implicitly authenticated by git's SHA-1 chain.

**Rationale**: Closes the trust gap between "the upstream repo we trust" (verified via `cwf_sha`) and "the manifest on disk that we use to compute baselines for FR3" (could be tampered with locally). Without this pin, an attacker who can write to `.cwf/install-manifest.json` could shift baselines such that the helper believes the user's version is the upstream's version, suppressing legitimate conflicts.

**Trade-offs**: One extra hash field to maintain in `.cwf/version`. `cwf-manage update` writes it after each successful update. `cwf-manage validate` cross-checks it (extension to `cwf-manage validate`).

### Threat acceptance — `.cwf/rules-inject.txt` is a prompt-injection vector by design
The PreToolUse:UserPromptSubmit hook (`/cwf-init` step 6c) injects `.cwf/rules-inject.txt`'s contents into Claude's context on every prompt submission. Because this file is upgrade-eligible (table row 9), a compromise of the upstream CWF repo could ship a modified `rules-inject.txt` whose contents are then auto-injected into Claude in every CWF-using project.

**Accepted**: CWF source is treated as trusted (users explicitly choose which release ref to install/upgrade to via `CWF_REF` / `cwf-manage update <ref>`); the benefit of being able to update injected rule content fleet-wide outweighs the residual risk of a trusted-source compromise. Compensating controls:
- D12 pins the installed manifest hash, so local tampering is detected.
- The helper logs `[CWF] INFO: .cwf/rules-inject.txt updated (was <sha>, now <sha>)` whenever this artefact changes, so the user can audit it after upgrade.
- The file is committed to git on update — diff-against-history is always available.

## System Design

### Component Overview

- **`cwf-apply-artefacts`** (NEW): The artefact-apply helper. Reads inventory, reads source manifest from cloned tree, reads installed manifest from local tree, walks each entry, classifies (no-op / silent-apply / conflict), prompts (FR4), writes (D5), logs.

- **`cwf-claude-settings-merge`** (EXISTING, extended): Continues to handle Bash allowlist + Stop hooks. Extended in this task to also register the PreToolUse:UserPromptSubmit hook that `/cwf-init` step 6c currently inlines, so settings.json work has one owner.

- **`cwf-manage`** (EXISTING, modified): `cmd_update` gains: (a) `flock` acquisition (D8), (b) FR12 settings.json parse-check, (c) D12 manifest sha check, (d) `cwf-apply-artefacts` invocation after `update_subtree`/`update_copy`, (e) `cwf-claude-settings-merge` invocation, (f) write `cwf_install_manifest_sha` into `.cwf/version`. `cmd_validate` extended to verify D12's manifest sha and to walk `.cwf/install-manifest.json` for path-allowlist + sha consistency.

- **`/cwf-init` SKILL.md** (EXISTING, modified): Step 4 (CLAUDE.md preamble) emits sentinels (D6); steps 1, 5, 6b consolidated into a call to `cwf-apply-artefacts --bootstrap-init`; steps 6c, 6d remain (settings.json work, calls `cwf-claude-settings-merge`).

- **`.cwf/install-manifest.json`** (NEW data file): The non-script artefact manifest. Source-of-truth for FR3 baselines. Hand-maintained by CWF maintainers, validated at release.

- **`.cwf/security/script-hashes.json`** (EXISTING): Adds entries for `cwf-apply-artefacts` (script) and `.cwf/install-manifest.json` (data file). The latter inherits Task 125's "all files under `.cwf/` are tracked" discipline.

### Data Flow

1. User runs `cwf-manage update [ref]`.
2. `cmd_update` reads `.cwf/version` (existing).
3. `cmd_update` acquires `flock` on `.cwf/.update.lock` (D8). Aborts on failure.
4. `cmd_update` validates `.claude/settings.json` parses as JSON (FR12). Aborts with recovery hint on failure.
5. `cmd_update` validates installed `.cwf/install-manifest.json` against `cwf_install_manifest_sha` from `.cwf/version` (D12). Aborts on mismatch. Skipped if either is absent (pre-D12 install).
6. Existing `update_subtree` / `update_copy` runs (refreshes `.cwf/`, `.cwf-skills/`).
7. Existing `create_skill_symlinks` runs.
8. NEW: `cwf-apply-artefacts <git_root> <clone_dir>` runs:
   1. Read source manifest from `<clone_dir>/.cwf/install-manifest.json`. If absent → log WARN, skip non-script artefacts (FR9 source-missing branch).
   2. Read installed (baseline) manifest from `<git_root>/.cwf/install-manifest.json`. If absent → bootstrap mode (D4).
   3. Verify schema versions per D11.
   4. For each `@INVENTORY` row: locate source data in `<clone_dir>` (validated against allowlist), locate on-disk file in `<git_root>`, compute three-way state (FR3), dispatch on `strategy`.
   5. On conflict: invoke prompt (FR4), respect `CWF_UPGRADE_RESOLVE` (FR5).
   6. Write each accepted change atomically (D5). Log per artefact.
9. NEW: `cwf-claude-settings-merge` runs (settles Skill perms + Bash allowlist + Stop hooks).
10. `cmd_update` writes `.cwf/version` (existing fields + new `cwf_install_manifest_sha` per D12), releases lock (auto on exit).

### Interface Design

#### `cwf-apply-artefacts`

```
Usage:
  cwf-apply-artefacts <git_root> <source_root>            # update mode (default)
  cwf-apply-artefacts <git_root> <source_root> --bootstrap-init  # fresh install mode
  cwf-apply-artefacts --help

Positional:
  git_root      Absolute path to the project's git root.
  source_root   Absolute path to the cloned CWF source for the new version.

Flags:
  --bootstrap-init   Treat every artefact as missing on-disk; install silently with no prompts.
  --dry-run          Print intended actions without writing or prompting.
  --help             Show this message.

Environment:
  CWF_UPGRADE_RESOLVE   prompt|keep|new|abort  (FR5)
                        Validated against this exact set; any other value → exit 1.

  No other environment variables are read. CWF_SOURCE is not consulted directly —
  the helper takes the cloned source root as a positional argument, so source-URL
  resolution stays the responsibility of cwf-manage. PERL5OPT, PERLLIB, etc. may
  be inherited by perl itself; the helper does not branch on them.

Exit codes:
  0   success (all artefacts applied or already up to date)
  1   user-aborted run, or unresolved conflicts in non-TTY default mode
  2   bootstrap manifest missing (info already logged)
  3   path validation failure (NFR4)
  4   internal error
```

#### `cwf-manage` changes

`cmd_update($git_root, $ref)` body changes (additions only):

```
acquire_update_lock($git_root);                      # D8
validate_settings_parseable($git_root);              # FR12
... existing update_subtree / update_copy ...
... existing create_skill_symlinks ...
run_apply_artefacts($git_root, $clone_dir);          # D7 / D9
run_settings_merge($git_root);                       # D7
... existing version-file write ...
```

Lock auto-releases when the process exits. A separate `release_update_lock` is not needed.

### Data Models

#### `.cwf/install-manifest.json` schema

```json
{
  "schema_version": 1,
  "cwf_version": "v1.0.43",
  "generated_at": "2026-05-05T12:00:00Z",
  "artefacts": [
    {
      "id": "claude-md-preamble",
      "kind": "embedded-block",
      "container": "CLAUDE.md",
      "marker_start": "<!-- CWF-PREAMBLE-START -->",
      "marker_end":   "<!-- CWF-PREAMBLE-END -->",
      "sha256": "<sha of canonical block content between sentinels>"
    },
    {
      "id": "rules-inject",
      "kind": "file",
      "source": ".cwf/templates/install/rules-inject.txt",
      "dest":   ".cwf/rules-inject.txt",
      "sha256": "<sha of source>"
    },
    {
      "id": "cwf-rules-bundle",
      "kind": "tree",
      "source": ".cwf-rules/",
      "dest":   ".cwf-rules/",
      "files": {
        "cwf-workflow-files.md": "<sha>",
        "cwf-perl-conventions.md": "<sha>"
      }
    },
    {
      "id": "gitignore-entries",
      "kind": "line-additive",
      "dest": ".gitignore",
      "lines": [".cwf/task-stack", ".cwf/.update.lock"]
    }
  ]
}
```

Notes:
- `kind` drives strategy dispatch in `cwf-apply-artefacts`.
- `source` paths are relative to the source root (cloned tree). Validated against the allowlist regex `^\.cwf(-rules|/templates)/` (or analogous; see NFR4 in requirements).
- `dest` paths are relative to git root. Validated against the same allowlisted destination prefixes.

#### `@INVENTORY` (Perl, in `cwf-apply-artefacts`)

```perl
my @INVENTORY = (
  { id => 'claude-md-preamble', strategy => 'embedded-block',
    container => 'CLAUDE.md', baseline_source => 'install-manifest' },
  { id => 'rules-inject',       strategy => 'replace',
    baseline_source => 'install-manifest' },
  { id => 'cwf-rules-bundle',   strategy => 'tree-replace',
    baseline_source => 'install-manifest' },
  { id => 'claude-rules-symlinks', strategy => 'regenerate-symlinks',
    baseline_source => 'derived' },     # No three-way logic: symlinks are a
                                        # function of `.cwf-rules/` contents.
                                        # After `.cwf-rules/` is settled (above),
                                        # this strategy always regenerates the
                                        # `.claude/rules/cwf-*.md` symlinks
                                        # silently to match. Reuses install.bash's
                                        # `create_cwf_symlinks` semantics, ported
                                        # to Perl in this helper (no shell-out —
                                        # avoids subprocess overhead per artefact
                                        # and keeps the helper self-contained).
  { id => 'gitignore-entries',  strategy => 'line-additive',
    baseline_source => 'install-manifest' },
);
```

Dispatcher: `apply_$strategy($git_root, $source_root, $entry)` for each row.

## Constraints

- POSIX `flock`; document the (unlikely) degradation path.
- All Perl files: `use strict; use warnings; use utf8;` + `-CDSL` shebang.
- Subprocess calls (to `cwf-claude-settings-merge`) use `system(@list)` form, not shell strings — avoids injection.
- New helper registered in `.cwf/security/script-hashes.json` (mode 0500); new manifest registered in same (data file, no exec).
- Lock file (`.cwf/.update.lock`) added to `.gitignore` via the manifest's `gitignore-entries` (eats own dog food).

## Decomposition Check
- [ ] **Time**: >1 week? No, ≤ 5 days.
- [ ] **People**: >2? No.
- [x] **Complexity**: 3+ concerns? Yes (helper + manifest + integration), but each is small and well-bounded after the design above.
- [ ] **Risk**: Isolation needed? Borderline — the bootstrap path (D4) is the riskiest, but it's one branch in one helper. Not enough to warrant a subtask.
- [ ] **Independence**: Marginal.

**Recommendation**: do not decompose. The design has factored complexity into the manifest schema + a single dispatcher; further splitting would introduce coordination overhead without separating concerns.

## Validation
- [ ] Design covers every FR/NFR from b-requirements-plan.md (cross-checked against AC1-AC8).
- [ ] Manifest schema reviewed for round-trip with `cwf-claude-settings-merge`'s existing manifest patterns.
- [ ] Bootstrap (D4) walks through the upgrade-from-pre-FR8 user journey end-to-end.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Every design decision (D1-D12) implemented as specified. D2 (`CWF::ArtefactHelpers` shared module) and D12 (manifest-SHA pin in `.cwf/version`) were the highest-leverage decisions: D2 removed code from the existing `cwf-claude-settings-merge` helper at zero behaviour cost; D12 added local-tampering detection for ~50 LOC.

## Lessons Learned
Designing for reuse (D2) before the second consumer existed paid off because the second consumer (`cwf-apply-artefacts`) was committed to land in the same task. Generalises: extract shared modules ahead of consumer #2 only when consumer #2 is in the same task or imminent.
