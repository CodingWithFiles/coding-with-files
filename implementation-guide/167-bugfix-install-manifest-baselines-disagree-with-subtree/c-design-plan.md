# install manifest baselines disagree with subtree - Design
**Task**: 167 (bugfix)

## Task Reference
- **Task ID**: internal-167
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/167-install-manifest-baselines-disagree-with-subtree
- **Template Version**: 2.1

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

The fix is a configuration edit (one removed manifest entry) plus a regression test. The simplicity priority dominates: smallest possible change that addresses the acute defect without pre-empting the `seed-once` redesign already filed in BACKLOG. **Reversibility** is load-bearing on D1 (a single revert of one commit restores the prior state; no schema migration, no data transformation).

## Verified Assumptions

A pre-design audit of the actual files surfaced facts that reshape the fix:

| # | Assumption | Verification | Status |
|---|---|---|---|
| 1 | Manifest source SHAs disagree with their source files | Computed SHA of every `source` and `files{*}` path; all match the manifest verbatim | **Refuted** — the manifest is internally consistent on `source`/SHA pairs |
| 2 | The defect is "manifest SHA is wrong" | The real defect is "the `rules-inject.source` field points at the wrong file" (empty placeholder template) — not "the recorded SHA is wrong" | **Reframed** |
| 3 | Other artefact entries may also have drift | Manually checked `claude-md-preamble` (SHA `c72927c7…` matches `.cwf/templates/install/claude-md-preamble.md`), `cwf-rules-bundle` per-file SHA (`05d3e1e7…` matches `.claude/rules/cwf-workflow-files.md`), `gitignore-entries` (line-additive, no SHA), `claude-rules-symlinks` (derived, no SHA) | **No drift in other entries** |
| 4 | The defect also breaks fresh installs, not only updates | Traced `/cwf-init` → `cwf-apply-artefacts --bootstrap-init`. In bootstrap mode `installed_entry` is undef, so `baseline := on-disk`. The `on_disk == baseline` branch then fires `_install_file`, which **writes the empty source over the populated subtree-shipped dest**. Fresh installs currently empty `.cwf/rules-inject.txt`. | **Confirmed broken on two paths, not one** |
| 5 | Removing the manifest entry breaks production code | `cwf-apply-artefacts:748-758`: when an `@INVENTORY` row's id is absent from the manifest, the helper logs `[CWF] WARN: <id>: not found in source manifest; skipping` and continues. No functional break — but every update would log noise. Removing the `@INVENTORY` row in tandem avoids the warning. | **Safe with the cascade cleanup below** |
| 6 | All four test files referencing `rules-inject` survive the manifest edit | Confirmed: `t/cwf-apply-artefacts.t` (TC-RI-1..5 + helpers), `t/cwf-manage-update.t:88-95`, `t/cwf-manage-update-end-to-end.t:146` (comment only), `t/install-bash-reinstall.t:171-174` (Task 158 subtree-population sanity check, depends on subtree shipping populated content — still true). All four construct synthetic manifests; none reads the real `.cwf/install-manifest.json`. | **All four tests preserved unchanged** |
| 7 | `.claude/skills/cwf-init/SKILL.md` is hash-tracked | Inspected `.cwf/security/script-hashes.json`; the file is **not** tracked. SKILL.md edits do not trigger a hash refresh. | **Simplifies the in-commit hash refresh list** |
| 8 | Consumer-already-broken recovery path | A consumer who previously ran `/cwf-init` against the broken manifest has `.cwf/rules-inject.txt` emptied. On `cwf-manage update` to the post-fix version: install.bash does `git rm -rf .cwf` then `git subtree add` which lays down the populated 331-byte file from the new version's subtree. Apply-artefacts then sees no `rules-inject` row (removed in D1+D2) and skips it. Recovery is automatic; no manual remediation required. | **Self-healing on update** |

## Key Decisions

### D1 — Fix shape: drop the `rules-inject` entry from `install-manifest.json`

**Decision**: Delete the `rules-inject` artefact entry from `.cwf/install-manifest.json`. Do not "fix the SHA"; do not "change the source to the populated file".

**Rationale**: The bug is **structural**, not a value drift. `rules-inject.txt` is shipped *by the `.cwf/` subtree*, not *by apply-artefacts*. Apply-artefacts having an entry for it was architectural mis-classification from Task 127. The minimal correction is to remove the mis-classification, leaving subtree as the sole distribution mechanism (same arrangement already used for `BACKLOG.md`, `CHANGELOG.md`, `cwf-project.json`, and the `implementation-guide/` tree).

**Trade-offs**:
- ✅ Resolves both broken paths (fresh install via `/cwf-init` no longer empties; update via `cwf-manage` no longer aborts).
- ✅ One-line removal from a config file; trivially reversible (single revert restores prior state — Reversibility priority honoured).
- ✅ Preserves the existing populated content shipped via subtree.
- ✅ Existing broken-state consumers recover automatically on next update (Verified Assumption 8).
- ⚠️ `apply_replace` strategy code becomes unused at HEAD. We intentionally leave the helper code intact (see D4) because the BACKLOG follow-up `seed-once` redesign will likely reuse `apply_replace` patterns.
- ⚠️ Does not fix the underlying ownership-model confusion (rules-inject is project-specific guidance, not universal canon). That fix is the BACKLOG follow-up; out of scope here.

**Rejected alternatives**:
- *Change `source` to `.cwf/rules-inject.txt` and SHA to `8c5efa38…`*: turns the entry into a degenerate self-reference (source == dest). `apply_replace` becomes a no-op when on-disk matches, which it does after every subtree pull. Functionally OK, but encodes the same architectural mis-classification with a fig leaf.
- *Add a `seed-once` strategy in this task*: too large; this is the BACKLOG follow-up's job. Bundling it would slow the consumer unblock and mix structural change with the regression fix.

### D2 — Cascade cleanup: remove every dangling reference

**Decision**: Removing the manifest entry leaves orphaned references that must be cleaned up in the same commit. The full list (expanded after plan review):

**Code edits (functional)**:
1. **`.cwf/install-manifest.json`** — delete the `rules-inject` artefact entry (D1).
2. **`.cwf/scripts/command-helpers/cwf-apply-artefacts:85-86`** — delete the `{ id => 'rules-inject', strategy => 'replace', baseline_source => 'install-manifest' }` row from `@INVENTORY`. Without this, every update logs `[CWF] WARN: rules-inject: not found in source manifest; skipping`.
3. **`.cwf/scripts/command-helpers/cwf-apply-artefacts:420-421`** — delete the dead `if ($id eq 'rules-inject') { log_info(...) }` branch inside `_install_file`. After step 2 the `rules-inject` id can never reach this branch; the special-case message is dead. Replace with the unconditional `log_info("$id: installed $dest_rel")` already used in the else branch.
4. **`.cwf/scripts/command-helpers/cwf-apply-artefacts:67`** — delete `'.cwf/rules-inject.txt'` from `@ALLOWED_DEST_PREFIXES`. The allowlist is *prescriptive* (a manifest entry with a non-allowed dest is rejected by `load_manifests` path validation), not advisory; retaining an entry for a path no live artefact targets is stale. Trivial two-line re-introduction when the BACKLOG `seed-once` follow-up needs it.
5. **`.cwf/lib/CWF/Validate/Security.pm:43`** — same removal in the mirror `@ALLOWED_DEST_PREFIXES`. Per the comment at `Security.pm:33`, this list "Mirrors cwf-apply-artefacts"; both must stay in sync.

**File deletions**:
6. **`.cwf/templates/install/rules-inject.txt`** — delete the 0-byte placeholder template. Sole consumer was the deleted manifest entry.

**Hash-tracking cleanup** (`.cwf/security/script-hashes.json`):
7. **Delete** the `rules-inject-template` entry (tracked the now-deleted template file).
8. **Refresh** `data.install-manifest` sha256 (file edited in step 1).
9. **Refresh** `scripts.cwf-apply-artefacts` sha256 (file edited in steps 2-4).
10. **Refresh** `lib.Validate-Security` sha256 (file edited in step 5) — exact key name verified in implementation-plan.

**Doc/comment edits (non-functional but worth doing for code-archaeology hygiene)**:
11. **`.cwf/scripts/command-helpers/cwf-apply-artefacts:4, 117`** — file-header docblock and usage string list `.cwf/rules-inject.txt` as a managed artefact. Remove the mentions.
12. **`.cwf/scripts/command-helpers/cwf-apply-artefacts:207`** — inline comment `# "CLAUDE.md" / ".gitignore" / ".cwf/rules-inject.txt" are exact, allow them.` Remove the `rules-inject.txt` mention.
13. **`.cwf/scripts/cwf-manage:491-492`** — banner comment listing artefacts apply-artefacts manages. Remove the `rules-inject` mention. **Note**: `cwf-manage` is hash-tracked → its sha256 must also be refreshed in step 9's spirit. Add to the refresh list.
14. **`.claude/skills/cwf-init/SKILL.md:93`** — bullet list of files apply-artefacts manages. Remove `.cwf/rules-inject.txt`. Line 99's reference to the PreToolUse hook reading `.cwf/rules-inject.txt` stays unchanged (the hook still reads the file). **Not hash-tracked** (Verified Assumption 7) — no hash refresh needed.

**Decision marker — surface not smooth** ([[feedback-surface-security-dont-smooth]]): we are not "silencing" a warning by editing the helper to suppress missing-entry logging; we are removing both the warning's *cause* (the dead INVENTORY row) and the file the entry pointed at. The integrity check (`cwf-manage validate`) still runs against the now-shrunk hash list and reports the truth.

**Updated in-commit hash-refresh list**: `.cwf/install-manifest.json`, `.cwf/scripts/command-helpers/cwf-apply-artefacts`, `.cwf/scripts/cwf-manage`, `.cwf/lib/CWF/Validate/Security.pm`, plus `.cwf/security/script-hashes.json` itself (`rules-inject-template` entry removed; four sha256s updated).

### D3 — Regression check: a new `t/installmanifest-integrity.t`

**Decision**: Add a new test file `t/installmanifest-integrity.t` that asserts two invariants on the **real shipped** `.cwf/install-manifest.json`:

- **INV-1 (source agreement)**: For every artefact with a `source` field, the file at that path exists and its SHA matches the recorded `sha256`. For tree artefacts (`files{*}`), the same applies per file.
- **INV-2 (anti-recurrence)**: For every artefact with `kind: file`, the `dest` MUST NOT begin with `.cwf/`. **Schema-level rule** — encodes the architectural lesson learned ("a `kind: file` apply-artefacts target inside the subtree creates dual-distribution and conflicts at update time"). After D1+D2 the loop body still executes (over the remaining artefacts) but the assertion is trivially satisfied because no `kind: file` entries remain at all. The invariant becomes load-bearing the moment any future `kind: file` entry is added — and surfaces the exact bug class without depending on SHA comparison.

**Rationale**: The choice of `t/` over `cwf-manage validate` extension is not "heavier vs lighter" — it's **scope of meaningfulness**. `cwf-manage validate` runs on *consumer* repos where there is no dev-side source tree to compare; INV-1's source-file existence and SHA recomputation only mean anything in the CWF dev repo where the manifest is authored. INV-2 is a schema check that *could* live in `Validate/Security.pm`, but pairing it with INV-1 in a single `t/` file keeps related invariants together and the regression check shippable as one PR. If developer feedback later wants INV-2 promoted to consumer-side validation, that's a one-line addition to `Security.pm` — independent of this task.

**Trade-offs**:
- ✅ Mechanical, fast (reads JSON, hashes a handful of files).
- ✅ INV-1 catches future "manifest SHA drifted from source file" defects.
- ✅ INV-2 catches the historical defect class (mis-classified `kind: file` artefact) by schema, no SHA work needed.
- ✅ Pure Perl, core modules only ([[feedback-perl-core-only]]).
- ✅ Lives in `t/` so `prove -r t/` exercises it; CI runs on every PR.
- ⚠️ Test must adapt if the manifest schema gains new artefact kinds. Accept — small test, infrequent schema changes.

**Rejected alternatives**:
- *Extend `cwf-manage validate` with the same checks*: see rationale above; rejected on scope-of-meaningfulness grounds, not weight.
- *Pre-commit hook*: too heavy; runs on commits unrelated to the manifest.

### D4 — Do not refactor `cwf-apply-artefacts` strategy machinery

**Decision**: Leave `apply_replace`, `prompt_resolve`, `_install_file` body (minus the dead `rules-inject` branch removed in D2#3), and the `kind: file` strategy registration intact. Removed from this carve-out (vs the original draft): the two allowlist entries (now handled by D2#4 and D2#5), the dead `eq 'rules-inject'` branch (now handled by D2#3).

**Rationale**: The strategy *machinery* is sound — the failure was wiring it to the wrong artefact. Removing the strategy and its tests (TC-RI-1..5 + helpers) would create rework for the BACKLOG `seed-once` follow-up (a close cousin that will likely reuse the prompt/conflict machinery and the strategy registration). The `t/cwf-apply-artefacts.t` test file continues to exercise `apply_replace` directly with synthetic fixtures, so the helper code remains *exercised dead* (not unreachable dead) until the follow-up consumes it.

**Trade-offs**:
- ✅ Smallest reasonable diff to the helper itself.
- ✅ BACKLOG follow-up doesn't have to re-add strategy code we just deleted.
- ⚠️ Carries the helper logic at HEAD until the follow-up lands. Acceptable per dead-code-audit "extension point with documented consumer" heuristic.

### D5 — Single-commit scope

**Decision**: All edits in D1, D2, D3 land in one commit on the bugfix branch.

**Rationale**: None of the edits is independently shippable:
- D1 alone (manifest entry only) → noisy WARN on every update from D2#2.
- D2#3 alone (dead branch removal in helper) → fine on its own but creates a misleading partial-cleanup state without D1.
- D2#4/#5 alone (allowlist entries) → noisy with no functional impact, low-value without D1.
- D2#6 alone (template file deletion) → script-hashes.json dangles via the `rules-inject-template` entry; `cwf-manage validate` fails.
- D3 alone (regression test) → INV-2 trivially passes (no `kind: file` entries to violate it post-D1), but the test depends on D1 having removed the entry to demonstrate the schema rule.

Per [[hash-updates]] the hash refresh sits with the source edits, not in a separate "hash-fix" commit.

## System Design

### Component Overview

| File | Change | Lines (approx) |
|---|---|---|
| `.cwf/install-manifest.json` | Remove `rules-inject` artefact entry | -7 lines |
| `.cwf/templates/install/rules-inject.txt` | Delete file (0 bytes) | -1 file |
| `.cwf/security/script-hashes.json` | Remove `rules-inject-template` entry; refresh 4 sha256s | net -5 lines, 4 SHA updates |
| `.cwf/scripts/command-helpers/cwf-apply-artefacts` | Remove `@INVENTORY` row, dead branch in `_install_file`, allowlist entry, three doc/comment mentions | ~-12 lines |
| `.cwf/scripts/cwf-manage` | Remove `.cwf/rules-inject.txt` mention from banner comment | -1 line |
| `.cwf/lib/CWF/Validate/Security.pm` | Remove `.cwf/rules-inject.txt` from `@ALLOWED_DEST_PREFIXES` | -1 line |
| `.claude/skills/cwf-init/SKILL.md` | Remove `.cwf/rules-inject.txt` from apply-artefacts files bullet | -1 line |
| `t/installmanifest-integrity.t` | New test file (INV-1 + INV-2) | +~80 lines |

Net: 7 files modified, 1 file deleted, 1 file added.

### Data Flow

**Before (broken)**:
```
install.bash subtree-add → .cwf/rules-inject.txt = 331 bytes (populated)
            ↓
/cwf-init → cwf-apply-artefacts --bootstrap-init
            → reads rules-inject from manifest (source=empty template, SHA=e3b0c44…)
            → on-disk (8c5efa38…) ≠ new (e3b0c44…), baseline := on-disk
            → on-disk == baseline → _install_file → writes EMPTY over populated
            → BUG: file empties; PreToolUse hook outputs nothing

cwf-manage update v1.x → v1.y → cwf-apply-artefacts (not bootstrap)
            → reads rules-inject from source manifest (still empty template)
            → reads rules-inject from installed manifest (same empty)
            → on-disk (8c5efa38…) ≠ new (e3b0c44…); baseline (e3b0c44…) ≠ on-disk
            → conflict → prompt_resolve → no TTY → abort
            → BUG: update fails mid-flight
```

**After (fixed)**:
```
install.bash subtree-add → .cwf/rules-inject.txt = 331 bytes (populated)
            ↓
/cwf-init → cwf-apply-artefacts --bootstrap-init
            → no rules-inject row in @INVENTORY → not processed
            → file remains populated

cwf-manage update v1.x → v1.y → cwf-apply-artefacts (not bootstrap)
            → no rules-inject row in @INVENTORY → not processed
            → subtree-pull lays down new version of .cwf/ (incl. rules-inject.txt)
            → file remains populated with the new version's content
            → update completes successfully

Consumer-already-broken recovery (had empty file from prior /cwf-init):
            → install.bash subtree-remove deletes .cwf/ (incl. empty rules-inject.txt)
            → install.bash subtree-add restores .cwf/ from new upstream
              → .cwf/rules-inject.txt = 331 bytes (populated again)
            → apply-artefacts no-op for rules-inject (entry removed)
            → broken state heals automatically
```

### Interface Design

No API changes. The manifest schema is unchanged. The strategy registry is unchanged. The only interface impact: `install-manifest.json` is one artefact entry shorter. Consumers of the manifest (apply-artefacts, the new regression test, anything else that reads it) iterate the `artefacts` array — they tolerate any subset.

## Constraints

- **No new dependencies**: regression test uses `Test::More`, `Digest::SHA`, `JSON::PP` — all core, all already used by `t/cwf-apply-artefacts.t`.
- **Hash discipline** ([[hash-updates]]): all hash-tracked file edits land their `script-hashes.json` refresh in this commit. Disclosed list: install-manifest.json, cwf-apply-artefacts, cwf-manage, Validate/Security.pm + the script-hashes.json self-edit.
- **POSIX-only**: no GNU-specific tooling, no Bashisms.
- **Backwards compatibility**: consumers at v1.1.155 receive the new (shorter) manifest on update; the absence of `rules-inject` does not trigger `installed_entry` lookups to fail — `find_entry` returns undef, which is the well-defined "skip" path. The `installed_entry` lookup for the entry we removed doesn't even happen because the production INVENTORY no longer iterates rules-inject.

## Decomposition Check
- [x] **Time**: <0.5 day → **no**.
- [x] **People**: solo → **no**.
- [x] **Complexity**: one config edit + cascade cleanup + one test → **no**.
- [x] **Risk**: contained; reversible via single revert → **no**.
- [x] **Independence**: edits must land together (D5) → **no**.

**Verdict**: 0/5 signals. **No subtasks.**

## Validation
- [ ] D1 applied: `install-manifest.json` has no `rules-inject` entry.
- [ ] D2 applied: all 14 cleanups (code edits 1-5, file deletion 6, hash-tracking 7-10, doc/comment 11-14) made in one commit.
- [ ] D3 applied: `t/installmanifest-integrity.t` exists and passes; both INV-1 and INV-2 asserted on the real shipped manifest.
- [ ] D4 honoured: `apply_replace` / `prompt_resolve` / `_install_file` machinery and TC-RI-1..5 tests intact.
- [ ] D5 satisfied: single commit on the bugfix branch contains all D1+D2+D3 changes plus the hash refreshes.
- [ ] `cwf-manage validate` clean post-edit.
- [ ] `prove -r t/` green — all four pre-existing test files referencing `rules-inject` continue to pass (Verified Assumption 6).
- [ ] Reproducer/regression: simulated update from v1.1.155 fixtures completes non-interactively with `rules-inject.txt` preserved (exact form decided in e-testing-plan).

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 167
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
