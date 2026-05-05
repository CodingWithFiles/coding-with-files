# upgrade installs cwf-init artefacts - Implementation Plan
**Task**: 127 (feature)

## Task Reference
- **Task ID**: internal-127
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/127-upgrade-installs-cwf-init-artefacts
- **Template Version**: 2.1

## Goal
Land the design's seven new components and three integration changes with minimum churn, in an order that keeps `cwf-manage validate` green at every checkpoint and lets the test plan exercise each step independently.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary new files
- `.cwf/scripts/command-helpers/cwf-apply-artefacts` — new Perl helper. Reads `@INVENTORY`, source + installed manifests, dispatches per-strategy, prompts on conflict. ~400-500 lines. Mode 0500.
- `.cwf/lib/CWF/ArtefactHelpers.pm` — new shared module. Extracts `read_json_file`, `atomic_write_json`, `validate_path_allowlist`, `compute_file_sha256` from existing inline implementations in `cwf-claude-settings-merge` and `CWF::Validate::Security` so both `cwf-apply-artefacts` and `cwf-claude-settings-merge` use one validated path-allowlist + atomic-write code path (eliminates ~50 LoC duplication and removes the drift risk between two security-relevant validators). Mode 0444.
- `.cwf/install-manifest.json` — new data file shipped by every CWF release. Schema in c-design-plan.md §"Data Models". Mode 0644 (data file, committed to git; no secrets).
- `.cwf/templates/install/rules-inject.txt` — the canonical content for `.cwf/rules-inject.txt` (currently absent — the existing `/cwf-init` step 6c hook reads it via `cat ... 2>/dev/null || true` and tolerates absence). For now, ship an empty-but-versioned file so the upgrade path has something to install. SHA256 of this file is pinned in `install-manifest.json`'s `rules-inject` entry, so a tampered source file is rejected on apply. Mode 0644.
- `t/cwf-apply-artefacts.t` — new TAP test covering FR3, FR4, FR5, FR6, FR7, FR9, FR11, FR12 branches (per AC2/AC3/AC4/AC5/AC8).
- `t/cwf-manage-update.t` — new TAP test covering AC1 end-to-end (renamed from earlier `cwf-manage-update-artefacts.t` to match the existing `cwf-manage-<subcommand>.t` naming pattern in `t/`).

### Primary modified files
- `.cwf/scripts/cwf-manage` — `cmd_update` extended per design Data Flow §1-10. `cmd_validate` extended via `CWF::Validate::Security` (no new module — see "Validator extension" below).
- `.cwf/scripts/command-helpers/cwf-claude-settings-merge` — refactored to `use CWF::ArtefactHelpers` for `read_json_file`, `atomic_write_json`, `validate_path_allowlist`. Behaviour unchanged; covered by existing `t/cwf-claude-settings-merge.t`.
- `.cwf/lib/CWF/Validate/Security.pm` — extended with a new exported sub `validate_install_manifest($git_root)` that: parses `.cwf/install-manifest.json` (no-op silently if absent — pre-D12 install / pre-FR8 install), checks `schema_version` is supported, walks each artefact entry validating `source`/`dest` against the allowlist, and (when `cwf_install_manifest_sha` is present in `.cwf/version`) verifies the on-disk manifest SHA matches. New violations join the existing `@all_violations` flow.
- `.claude/skills/cwf-init/SKILL.md` — step 4 emits CLAUDE.md sentinels; new step inserted between current 6b and 6c invokes `cwf-apply-artefacts --bootstrap-init`; step 6c stays unchanged (PreToolUse hook owner per D7); step 8 unchanged; success criteria updated.
- `.cwf/security/script-hashes.json` — register `cwf-apply-artefacts` (mode 0500), `CWF::ArtefactHelpers` (mode 0444), `.cwf/install-manifest.json` (mode 0644), `.cwf/templates/install/rules-inject.txt` (mode 0644). Update `last_updated`.

### `script-hashes.json` data section (new convention)
The new files include both an executable script and three non-executable data/template files. The existing top-level layout is `lib` (Perl modules) + `scripts` (executables and Perl-based hooks) + `version` + `last_updated`. Adding non-executable data files into `scripts` would conflate code and data. Decision: introduce a new top-level section `data` for non-executable, non-library tracked files. `cwf-apply-artefacts` goes under `scripts` (precedent matches other helpers); `CWF::ArtefactHelpers` goes under `lib`; the manifest and the template go under `data`. `CWF::Validate::Security`'s file-walk already iterates every section that "looks like a file map" (per `cwf-manage` line 487-494: any hash whose values are hashes with a `path` key), so a new top-level section requires no validator-side change.

### Validator extension — extends `CWF::Validate::Security`, not a new module
Per design D12, the manifest validator is added to the existing `CWF::Validate::Security` module rather than a new `CWF::Validate::InstallManifest`. Rationale: the module already owns "verify on-disk state matches a JSON manifest of expected hashes" — the install-manifest is a sibling artefact (different schema, same intent). One module, one cohesive responsibility. The new sub `validate_install_manifest` is exported and called from `cmd_validate` alongside the existing `validate`.

### Supporting changes
- `.gitignore` — add `.cwf/.update.lock` (per D8). Also added to `install-manifest.json` `gitignore-entries` so future `cwf-manage update` invocations re-apply it.
- `BACKLOG.md`, `CHANGELOG.md` — entry for Task 127.

### NOT modified
- `.cwf/scripts/command-helpers/cwf-claude-settings-merge` — design D7 explicitly keeps this helper's scope unchanged. Re-used as a subprocess.
- `scripts/install.bash` — out of scope: install path already produces every artefact correctly; the gap is on the upgrade side. Future task may consolidate.

## Implementation Steps

Order matters: each step ends with a passing `cwf-manage validate` and (where applicable) a passing test, so any step can be a checkpoint commit.

### Step 1: Author the shared module + manifest schema + seed data
**Order matters within this step**: the validator is extended FIRST (with stub behaviour for absent files) so creating the manifest does not produce a `cwf-manage validate` violation between substeps.

- [ ] Create `.cwf/lib/CWF/ArtefactHelpers.pm` with `read_json_file`, `atomic_write_json` (same-directory temp + `rename`), `validate_path_allowlist($path, \@allowed_prefixes)` (rejects absolute paths, rejects `..` segments, rejects paths matching no allowed prefix), `compute_file_sha256` (binary-safe). Mode 0444. Tests: `t/artefacthelpers.t` covering each sub.
- [ ] Refactor `.cwf/scripts/command-helpers/cwf-claude-settings-merge` to `use CWF::ArtefactHelpers qw(read_json_file atomic_write_json validate_path_allowlist)` and remove the now-redundant inline implementations. `t/cwf-claude-settings-merge.t` must continue to pass with no test changes (behaviour unchanged).
- [ ] Extend `CWF::Validate::Security` with `validate_install_manifest($git_root)`. **Stub initial form**: returns no violations if `.cwf/install-manifest.json` is absent or if `cwf_install_manifest_sha` is not in `.cwf/version`. This makes the validator manifest-aware before the manifest exists, so the next substep's file creation does not flag a violation.
- [ ] Wire `validate_install_manifest` into `cmd_validate`'s `@all_violations` list.
- [ ] Run `cwf-manage validate` — must still pass (stub returns no violations).
- [ ] Create `.cwf/templates/install/rules-inject.txt` as an empty file. Compute its SHA256.
- [ ] Write `.cwf/install-manifest.json` with `schema_version: 1` and entries for: `claude-md-preamble` (embedded-block, SHA of canonical preamble content), `rules-inject` (file kind; `source: .cwf/templates/install/rules-inject.txt`, `dest: .cwf/rules-inject.txt`, `sha256: <computed above>`), `cwf-rules-bundle` (tree kind; per-file SHAs from `.cwf-rules/`), `gitignore-entries` (line-additive: `[".cwf/task-stack", ".cwf/.update.lock"]`).
- [ ] Register `cwf-apply-artefacts` (under `scripts`, mode 0500), `CWF::ArtefactHelpers` (under `lib`, mode 0444), `.cwf/install-manifest.json` and `.cwf/templates/install/rules-inject.txt` (under new top-level `data` section, mode 0644) in `.cwf/security/script-hashes.json`. Update `last_updated`.
- [ ] Run `cwf-manage validate` — must pass.

### Step 2: Write `cwf-apply-artefacts` skeleton (no FR3 logic yet)
- [ ] Create `.cwf/scripts/command-helpers/cwf-apply-artefacts` with `#!/usr/bin/perl -CDSL`, `use strict; use warnings; use utf8;`, `use CWF::ArtefactHelpers qw(read_json_file atomic_write_json validate_path_allowlist compute_file_sha256);`.
- [ ] Implement: argument parsing (`<git_root> <source_root> [--bootstrap-init] [--dry-run]`), `--help` output (including the note from D9 that `source_root == git_root` is valid in `--bootstrap-init` mode for the fresh-install case), env-var validation for `CWF_UPGRADE_RESOLVE` (reject any value outside `{prompt,keep,new,abort}` with exit 1), exit-code constants (0/1/2/3/4 per design Interface).
- [ ] Implement local helper subroutines (NOT duplicating shared module): `log_info`/`log_warn`/`log_error`, `prompt_resolve($id, $on_disk, $new, $is_secret)`, dispatcher.
- [ ] Implement the `@INVENTORY` policy table at the top.
- [ ] Wire `main()` to: parse args → load manifests → iterate `@INVENTORY` → call `apply_$strategy($git_root, $source_root, $entry, $manifests)` (each is a stub that returns 0 / "ok"). Log a per-artefact line.
- [ ] `chmod 0500`.
- [ ] Run `cwf-manage validate` — must pass.

### Step 3: Implement strategies one at a time
For each strategy below: implement the apply function + the FR3 three-way comparison + the FR4 prompt (shared subroutine) + tests covering FR3 cases 1-4 and structural conflict. Stop after each, run the new tests.

- [ ] **3a. `line-additive`** (`.gitignore`): simplest — append-only, no prompt path. Reads manifest's `lines` array; for each line: **reject if `$line =~ /[\r\n]/`** (newline injection guard — exit 3, log `[CWF] ERROR: manifest line contains forbidden newline character; rejecting artefact <id>`); trim trailing whitespace; if not present on-disk (exact-line match), append. Idempotent.
- [ ] **3b. `replace`** (`.cwf/rules-inject.txt` and any future single-file replace targets): full FR3 flow. Implements the dpkg-style prompt (FR4) here, since this is the first strategy that needs it. Prompt loop signature: `prompt_resolve($id, $on_disk_path, $new_path, $is_secret) → 'keep'|'new'|'abort'`. **Redaction enforcement**: when `$is_secret` is true (i.e. dest path matches `%REDACT_PATHS` or `$REDACT_PATTERN`), option D prints `[CWF] diff suppressed for <dest> — file may contain secrets; inspect manually with: git diff --no-index <on-disk> <new>` and re-prompts; the helper never echoes the file contents (or paths inside the contents) for secret artefacts. **Audit logging for `rules-inject`**: when `$id eq 'rules-inject'` and the action is `install-new`, log `[CWF] INFO: .cwf/rules-inject.txt updated (was <old-sha>, now <new-sha>)` per design's "Threat acceptance" section, so the user can audit prompt-injection-bearing changes after each upgrade.
- [ ] **3c. `tree-replace`** (`.cwf-rules/`): walk source tree's files (per manifest's `files` map), apply the `replace` strategy per file. New files in source are added; files removed in source are NOT deleted on-disk in this task (out of scope; would need a `delete` strategy and an additional confirmation). Document this in the helper's `--help`. Stale on-disk `.cwf-rules/cwf-*.md` files left over from removed-upstream rules are cleaned up at the symlink layer in 3e (broken-symlink sweep).
- [ ] **3d. `embedded-block`** (`CLAUDE.md` preamble): same as `replace` but operates on the region between sentinels. Implements wrap-in-place per D6 if sentinels missing. The region's "file" for FR3 comparison is the in-memory string between markers.
- [ ] **3e. `regenerate-symlinks`** (`.claude/rules/cwf-*.md`): no FR3, no prompt. Port `install.bash:create_cwf_symlinks` (currently shell, used by install.bash for both `.cwf-skills`→`.claude/skills` and `.cwf-rules`→`.claude/rules`) to Perl. **Scope here is rule symlinks only** (`.cwf-rules/cwf-*.md` → `.claude/rules/cwf-*.md`); skill symlinks are still handled by the existing `create_skill_symlinks` in `cwf-manage` (no overlap). Steps: (a) walk `.claude/rules/cwf-*.md`, remove any symlink whose target does not exist on disk (cleans up orphans from removed-upstream rules — addresses 3c's deferred-delete edge); (b) for each `.cwf-rules/cwf-*.md`, ensure a relative symlink at `.claude/rules/cwf-<name>.md` points to it; (c) leave non-symlink files in `.claude/rules/` alone (they are user-owned). (`merge-json` strategies are NOT implemented in `cwf-apply-artefacts` — they are handled by the existing `cwf-claude-settings-merge` invocation in `cwf-manage` per D7.)

### Step 4: Wire into `cwf-manage`
- [ ] In `cwf-manage`, add helper subs: `acquire_update_lock($git_root)` (D8 — Perl `flock` with `-l` symlink precheck and `O_NOFOLLOW` on `sysopen`; returns the open filehandle for the caller to retain), `validate_settings_parseable($git_root)` (FR12), `validate_install_manifest_sha($git_root, \%v)` (D12 — **return immediately if `$v{cwf_install_manifest_sha}` is missing OR the on-disk manifest is absent**; only mismatch when both exist and differ), `run_apply_artefacts($git_root, $clone_dir)` (subprocess `system('.cwf/scripts/command-helpers/cwf-apply-artefacts', $git_root, $clone_dir)`; on non-zero, die with the helper's exit code embedded in the error message so `cmd_update` aborts cleanly), `run_settings_merge($git_root)` (subprocess to `cwf-claude-settings-merge`; same non-zero handling), `compute_install_manifest_sha($git_root)`.
- [ ] Modify `cmd_update($git_root, $ref)` per design Data Flow §1-10. **Specific ordering**:
  1. After `read_version_file` (existing) → `my $lock_fh = acquire_update_lock($git_root);`. The variable MUST be lexically scoped at function-body level so it lives until `cmd_update` returns; closing the FH releases the lock.
  2. → `validate_settings_parseable($git_root)`.
  3. → `validate_install_manifest_sha($git_root, \%v)` (no-op silently when either side is absent).
  4. → existing `check_clean_tree($git_root)`. (Lock is acquired BEFORE `check_clean_tree` so two concurrent updates do not both pass the clean-tree check before one blocks on the lock.)
  5. → existing source-clone, ref resolution, `update_subtree`/`update_copy`, `create_skill_symlinks`.
  6. → `run_apply_artefacts($git_root, $clone_dir)`.
  7. → `run_settings_merge($git_root)` — `or die` if non-zero (settings.json may be partially updated; the user is told to re-run after resolving the underlying error).
  8. → `$v{cwf_install_manifest_sha} = compute_install_manifest_sha($git_root);` — note: the on-disk manifest at this point is the freshly-installed one (refreshed by `update_subtree`/`update_copy` in step 5), so we are recording the SHA of the new release's manifest.
  9. → `write_version_file($git_root, %v)`.
- [ ] Extend `cmd_validate` to also call `CWF::Validate::Security::validate_install_manifest($git_root)` (already added in Step 1's stub form; promote the stub to full validation: schema_version supported, every `source`/`dest` passes the allowlist, on-disk SHA matches `cwf_install_manifest_sha`).
- [ ] Run all existing `t/cwf-manage-*.t` tests — must pass.
- [ ] **End-of-step smoke test**: write a short test (in `t/cwf-manage-update.t`) that creates a synthetic source repo whose manifest contains an entry with `dest: ../../etc/passwd`, runs `cwf-manage update` against it, and asserts: (a) `run_apply_artefacts` exits 3 (path validation failure), (b) `cmd_update` aborts before writing `.cwf/version`, (c) no file outside the project's git root is created. This is the integration check that the helper's exit codes correctly propagate.

### Step 5: Update `/cwf-init` SKILL.md
- [ ] Step 4 (CLAUDE.md preamble): wrap the prepended block in the sentinels from D6.
- [ ] Insert new step between 6b and 6c: "Apply CWF artefacts via `cwf-apply-artefacts <git_root> <git_root> --bootstrap-init`" (source_root = git_root because /cwf-init runs against the already-installed source). Document expected output and exit codes.
- [ ] **Hard ordering note in SKILL.md**: state explicitly that `cwf-apply-artefacts --bootstrap-init` MUST run before step 6c (PreToolUse hook setup), because the hook command (`cat .cwf/rules-inject.txt 2>/dev/null || true`) reads the file written by the apply-artefacts step. Future SKILL.md edits must preserve this ordering.
- [ ] Update Success Criteria to include the new step.
- [ ] Step 6c (PreToolUse hook), 6d (cwf-claude-settings-merge), 7 (PERL5OPT), 8 (init commit) — unchanged. The new step's writes (CLAUDE.md preamble, .gitignore, .cwf-rules/, .claude/rules/ symlinks) are picked up by step 8's `git add`.

### Step 6: Add `.gitignore` lock entry and update CHANGELOG/BACKLOG
- [ ] `.gitignore` += `.cwf/.update.lock`.
- [ ] `CHANGELOG.md` entry for Task 127.
- [ ] `BACKLOG.md` — mark Task 127 as completed (move from in-progress to done section).

### Step 7: Final integrity sweep
- [ ] **Recompute SHA256s**. Two things need refreshed hashes:
  1. **`script-hashes.json` entries** for every file touched in this task (the new helper, the new module, the new manifest, the new template). Use the same procedure Task 125 used to populate `script-hashes.json` — write a small one-shot Perl script to `/tmp/127/recompute-script-hashes.pl` that walks `script-hashes.json`, re-hashes each registered file, and writes back the updated JSON. Commit the helper if it proves reusable; otherwise keep it ephemeral.
  2. **`install-manifest.json` `sha256` fields** for each `file`/`tree` artefact entry whose source content changed (in this task: `rules-inject` is the only entry with an actual file source; `cwf-rules-bundle` files' SHAs depend on whatever is in `.cwf-rules/` at release time). Same one-shot script approach: a `/tmp/127/recompute-manifest-shas.pl` that re-hashes each entry's source file and updates the manifest in place.
- [ ] `cwf-manage validate` passes from a clean tree (verifies both manifests are internally consistent and match on-disk SHAs).
- [ ] Full `prove t/` passes locally.

## Code Changes (illustrative, not literal)

### `cwf-manage` `cmd_update` shape (additions only)

```perl
sub cmd_update {
    my ($git_root, $ref) = @_;
    $ref //= 'latest';

    my %v = read_version_file($git_root);
    my $lock_fh = acquire_update_lock($git_root);              # D8 — kept alive for the rest of this scope
    validate_settings_parseable($git_root);                     # FR12
    validate_install_manifest_sha($git_root, \%v);              # D12 (no-op if absent)

    # ... existing check_clean_tree, source resolution, clone, update_subtree/update_copy, create_skill_symlinks ...

    run_apply_artefacts($git_root, $clone_dir);                 # D7/D9
    run_settings_merge($git_root);                              # D7

    $v{cwf_install_manifest_sha} = compute_install_manifest_sha($git_root);
    # ... existing version-file fields and write_version_file ...
    return;
}
```

### `cwf-apply-artefacts` skeleton

```perl
#!/usr/bin/perl -CDSL
use strict; use warnings; use utf8;
use Fcntl qw(:DEFAULT);
use Digest::SHA qw(sha256_hex);
use JSON::PP;

my @INVENTORY = (
    { id => 'gitignore-entries',     strategy => 'line-additive',
      baseline_source => 'install-manifest' },
    { id => 'rules-inject',          strategy => 'replace',
      baseline_source => 'install-manifest' },
    { id => 'cwf-rules-bundle',      strategy => 'tree-replace',
      baseline_source => 'install-manifest' },
    { id => 'claude-md-preamble',    strategy => 'embedded-block',
      container => 'CLAUDE.md',
      baseline_source => 'install-manifest' },
    { id => 'claude-rules-symlinks', strategy => 'regenerate-symlinks',
      baseline_source => 'derived' },
);

# Allowlist for source/dest paths (NFR4 path-traversal guard)
my %ALLOWED_DEST_PREFIX = map { $_ => 1 } (
    '.cwf-rules/', '.claude/rules/', 'CLAUDE.md', '.gitignore', '.cwf/rules-inject.txt',
);

my %REDACT_PATHS = map { $_ => 1 } (
    '.claude/settings.json',
);
my $REDACT_PATTERN = qr/\.env(\..*)?$/;

# main(): parse args; load manifests; iterate @INVENTORY; dispatch.
# Strategy subs: apply_line_additive, apply_replace, apply_tree_replace,
#                apply_embedded_block, apply_regenerate_symlinks.
# Shared: prompt_resolve($id, $on_disk, $new), env-controlled per FR5.
```

### Manifest example (`.cwf/install-manifest.json`)

See c-design-plan.md §"Data Models" for the canonical schema. The actual content for v1 will be assembled in Step 1 by hashing the source files.

## Test Coverage
**See e-testing-plan.md for the complete test plan.** Brief preview:
- `t/artefacthelpers.t` — covers `read_json_file`, `atomic_write_json` (including same-directory temp + crash-mid-rename safety), `validate_path_allowlist` (rejects absolute paths, `..`, paths outside allowlist), `compute_file_sha256`.
- `t/cwf-apply-artefacts.t` — covers FR3 (4 content branches + structural), FR4 (4 prompt options + redaction enforcement for secret paths), FR5 (3 valid + 1 invalid env values), FR6 (idempotency), FR9 (no-manifest bootstrap, no-source-manifest), FR12 (malformed settings.json), D6 (sentinel detection + wrap-in-place + user-content-outside-sentinels), 3a's newline-injection rejection, 3b's `rules-inject` SHA-transition INFO log.
- `t/cwf-manage-update.t` — end-to-end: spin up a temp source repo + temp installed repo, run `cwf-manage update`, assert artefact convergence per AC1; also FR11 (concurrent lock — fork two updates, assert one wins and one exits with the lock-busy error); also Step 4's path-traversal smoke test.
- Existing `t/cwf-claude-settings-merge.t` and `t/cwf-manage-*.t` — must continue to pass after the `CWF::ArtefactHelpers` extraction (no behaviour change).
- **Test fixture hygiene**: any `.claude/settings.json` fixture used in these tests MUST contain only synthetic values (no real API keys, model names from real providers, or URLs). Use placeholder strings like `"test-permission-1"`, `"sk-test-dummy"`. Pre-commit grep guard: `grep -rE '(sk-(ant|live)|claude-[0-9]|gpt-[0-9])' t/cwf-apply-artefacts.t t/cwf-manage-update.t` must return no matches.

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results.**

Per-step gates:
- After Step 1: `cwf-manage validate` green.
- After Step 2: `cwf-manage validate` green; `cwf-apply-artefacts --help` prints usage.
- After Step 3 (each substep): the substep's tests pass.
- After Step 4: all existing `t/cwf-manage-*.t` pass; new `cmd_update` runs end-to-end on a tmp-repo smoke test.
- After Step 5: `/cwf-init` on a fresh tmp-repo produces the same artefact set as before plus the new sentinels.
- After Step 6 + 7: `cwf-manage validate` green from a clean tree; `prove t/` green.

## Decomposition Check
- [ ] **Time**: >1 week? Borderline if Step 3's strategies prove harder than expected. Mitigation: each strategy is independently testable and committable.
- [ ] **People**: >2? No.
- [x] **Complexity**: 3+ concerns? Yes (helper, manifest, integration, /cwf-init), but Step ordering keeps each touching one area at a time.
- [ ] **Risk**: Need isolation? No — each step ends with a green validate gate.
- [ ] **Independence**: Marginal.

**Recommendation unchanged**: do not decompose. The step ordering is the decomposition.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

If a strategy in Step 3 turns out to be much larger than expected (e.g. `embedded-block`'s sentinel migration edge cases), the recovery is to:
1. Stop and discuss with the user.
2. Either narrow the strategy's scope (and create a follow-up) or split Step 3 into a subtask.
Do not silently defer.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 7 implementation steps executed. One mid-flight deviation: combined Steps 2 (skeleton) and 3 (5 strategies) for `cwf-apply-artefacts` into a single helper write — they were tightly coupled and writing the skeleton then re-editing per strategy was wasted churn. Recorded in f-implementation-exec.md.

## Lessons Learned
The plan called for `/tmp/127/recompute-*.pl` one-shot scripts to update `script-hashes.json` SHAs in batches; in practice updating SHAs inline as files changed was simpler and avoided a stale-SHA validation failure. Plans for batching SHA recomputation should anticipate that "do it inline" is usually correct.
