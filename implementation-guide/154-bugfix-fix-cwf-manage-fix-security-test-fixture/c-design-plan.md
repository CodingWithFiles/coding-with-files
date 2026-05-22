# fix cwf-manage-fix-security test fixture - Design
**Task**: 154 (bugfix)

## Task Reference
- **Task ID**: internal-154
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/154-fix-cwf-manage-fix-security-test-fixture
- **Template Version**: 2.1

## Goal
Decide *how* `build_fixture` provisions the manifest-tracked paths that live outside `.cwf/`, so `cmd_validate`/`cmd_fix_security` stop seeing them as missing — without hard-coding `.claude/agents/` and without polluting the fixture with untracked siblings.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Background (verified this task)
- The manifest (`.cwf/security/script-hashes.json`) tracks 5 paths outside `.cwf/`: `.claude/agents/*.md` (recorded perms `0444`). `build_fixture` (`t/cwf-manage-fix-security.t:52-61`) copies only `$REPO_ROOT/.cwf`.
- `cmd_validate` (`cwf-manage:632`) and `cmd_fix_security` (`cwf-manage:688`) iterate every manifest entry and resolve `"$git_root/$rel"` (`cwf-manage:743`). Fixture git root is `$tmp`, so `$tmp/.claude/agents/*.md` are missing → `existence` violations → TC-1/2/7 red.
- **Perm check is a floor, not an exact match**: both `cmd_validate` (`Security.pm:117`) and `cmd_fix_security` (`cwf-manage:776`) test `($actual & $recorded) != $recorded` — recorded perms (`0444`/`0500`/`0700`) are *minimums*. A fresh-clone `0644`/`0755` still satisfies them (`0644 & 0444 == 0444`), so the perm axis is robust to a fresh clone (an earlier draft wrongly flagged this as a limitation). What `cp -p` buys is **umask-independence**: a copy *without* `-p` under a restrictive umask (077) yields `0600`, which fails the `0444` floor (missing group/other read). Preserving the source's working-tree perms (at or above the floor) sidesteps that — same reason the existing `cp -rp .cwf` uses `-p` (comment at lines 54-56).
- **Three checks per entry**: once a file exists, the validator also checks SHA256 (`Security.pm:130`) and the perm floor. So the fixture must provide each extra path with (a) existence, (b) byte-identical content, (c) perms ≥ floor. A `cp -p` from `$REPO_ROOT` satisfies all three (byte-identical content → SHA passes; preserved perms → floor passes).
- `JSON::PP::decode_json` is already imported and used in this test (`_read_recorded_perms`, line 18/25).

## Key Decisions

### Decision 1 — Derive the extra paths from the manifest; do not hard-code `.claude/agents/`
- **Decision**: After copying `.cwf/`, parse the manifest, collect every tracked `path`, and copy each path whose **first segment is not `.cwf`** into the fixture.
- **Rationale**: Directly satisfies the "don't silently re-break" criterion — a future task that tracks a new non-`.cwf/` path (e.g. `.claude/hooks/foo`) is picked up automatically with no test edit. The manifest is the single source of truth for "what validate checks", so deriving the copy set from it keeps fixture-contents and validate-expectations in lockstep.
- **Trade-offs**: One manifest parse in `build_fixture` (cheap; the file is already read elsewhere in the test). Rejected: hard-coding `.claude/agents/` (re-breaks on the next tracked root — the exact bug class we are fixing).

### Decision 2 — Per-file copy with `mkdir -p` + `cp -p`, mirroring the existing `cp -rp` perm rationale
- **Decision**: For each extra path, create its parent dir (`system("mkdir","-p",…)`) then `system("cp","-p",$src,$dst)`. Preserve perms via `-p`.
- **Rationale**: Mirrors the file's existing idiom — it already shells out to `cp -rp`, `git`, `find` rather than using `File::Copy`/`File::Path`. Consistency (priority 3) favours the same style over introducing core-module imports that do the same job. `-p` gives umask-independence (a no-`-p` copy under umask 077 would land at `0600` and fail the `0444` floor) — the same reason `-rp` is used on `.cwf/` per the comment at lines 54-56. Combined with the byte-identical content `cp` produces, this satisfies all three per-entry checks (existence/SHA/perm-floor; see Background).
- **Trade-offs**: Per-file `cp` (5 invocations today) vs one subtree copy. Negligible at this scale and strictly more precise. Rejected: `cp -rp $REPO_ROOT/.claude $tmp/.claude` (wholesale) — drags in untracked, machine-specific files (`settings.local.json`, the dogfood `settings.json`, skills/hooks) the manifest does not track, bloating the fixture and risking unrelated validate noise.

### Decision 3 — Keep the `.cwf/` wholesale copy unchanged; the new copy is purely additive
- **Decision**: Leave `cp -rp $REPO_ROOT/.cwf $tmp/.cwf` exactly as-is. Add the manifest-derived copy as a second step.
- **Rationale**: The two copies serve different needs and must not be unified. `.cwf/` is copied wholesale because `cwf-manage` needs its full **runtime** tree (lib/, scripts/, docs/) — most of which is *not* in the manifest. The extra paths are copied because they are **manifest-tracked** and must merely exist (and carry matching perms) for validate. Conflating them would either under-copy the runtime tree or over-copy untracked `.claude/` siblings.

### Decision 4 — One helper, `_provision_extra_manifest_paths($tmp)`, reusing the manifest-read pattern already in the test
- **Decision**: A single helper `_provision_extra_manifest_paths($tmp)` reads `$REPO_ROOT/.cwf/security/script-hashes.json`, walks the same file-map sections `cmd_fix_security` walks (any section whose values are hashes with a `path` key), and for each non-`.cwf/` `path` does `mkdir -p` + `cp -p` into `$tmp`. One function does both derive and copy — no derive/copy split (no second caller; Rule of Three not met). `build_fixture` calls it after the `.cwf` copy + `git init`.
- **Rationale**: Mirrors `_read_recorded_perms`'s decode-the-manifest approach and `_ensure_cwf_manage_executable($tmp)`'s "(takes `$tmp`) → side-effect → die-on-error" shape (readability/consistency). It deliberately **re-decodes** the manifest (rather than threading a parsed structure through `build_fixture`) to keep `build_fixture`'s signature unchanged — the ~4 duplicated decode lines do not justify a shared decode helper at two call sites. Reading from `$REPO_ROOT` (source of truth) keeps it independent of copy ordering; the just-copied `$tmp` manifest is byte-identical, so either source is correct — a one-line comment will note this so a future reader does not "align" it with `_read_recorded_perms`'s `$tmp` read. Walking "any section that is a file-map" matches `cmd_fix_security`'s own traversal (`cwf-manage:729-740`) and `Validate::Security::_looks_like_file_map` (`Security.pm:280-284`), so the test cannot drift from the tool's notion of a tracked path.
- **Failure & trust**: `die` on any `mkdir`/`cp` failure, naming the offending path (e.g. `die "cp <path> into fixture failed (rc=$rc)"`), mirroring the existing `die "cp .cwf failed (rc=$rc)"`. The manifest `path`s are repo-controlled, integrity-tracked, repo-relative strings (no `..`, no absolute paths) — the same trust `cmd_fix_security` places in them at `cwf-manage:743` (`"$git_root/$rel"`). A one-line inline comment will record this inherited invariant so nobody later repoints the helper at an untrusted manifest without noticing.

## System Design

### Component Overview
- **`build_fixture` (modified)**: after `cp -rp .cwf` + `git init`, invoke the new provisioning step for non-`.cwf/` manifest paths. Single added call; existing behaviour untouched.
- **`_provision_extra_manifest_paths($tmp)` (new helper)**: parse manifest → for each tracked `path` with first segment ≠ `.cwf`, `mkdir -p` the dest parent under `$tmp` and `cp -p` the source file. `die` (naming the path) on any `cp`/`mkdir` failure (fixtures must be sound — fail loud, like the existing `die "cp .cwf failed"`).

### Data Flow (fixture build)
1. `tempdir(CLEANUP => 1)` → `$tmp`.
2. `cp -rp $REPO_ROOT/.cwf $tmp/.cwf` (unchanged).
3. `git init -q` in `$tmp` (unchanged).
4. **New**: parse manifest; for each non-`.cwf/` tracked `path`: `mkdir -p $tmp/<dir(path)>`; `cp -p $REPO_ROOT/<path> $tmp/<path>`.
5. Return `$tmp`.

**Post-condition**: every manifest entry now resolves under `$tmp` with existence + byte-identical content (SHA passes) + perms ≥ floor (perm check passes). **Other validators unaffected**: the fixture is a fresh `git init` with *nothing committed*, so the whole `.cwf/` tree is already untracked and the `cmd_validate` chain (Config/Workflow/Consistency/Templates/Security — `cwf-manage:636-642`) already runs to completion on it today (TC-3/4/5/6 reach the Security stage and pass). Adding more untracked files under `.claude/agents/` does not change what those non-Security validators scan — verified the current failure set is purely Security `existence` violations on the 5 missing paths.

## Interface Design
- `build_fixture()` → `$tmp` — signature unchanged; all 7 subtests keep calling it as-is.
- `_provision_extra_manifest_paths($tmp)` → (void; dies on failure). Internal test helper, mirrors `_ensure_cwf_manage_executable($tmp)` shape (takes `$tmp`, side-effects the fixture, dies on error).
- No production interface changes. No new module imports (uses already-imported `JSON::PP`; shells out for `mkdir`/`cp`).

## Constraints
- **Test-only**: no edits to `cwf-manage`, `CWF::Validate::*`, or any hashed file. Zero change to the integrity surface; no hash refresh.
- Core Perl, POSIX, system Perl; `#!/usr/bin/env perl` (file already conforms). No new CPAN deps.
- Preserve the perm-preserving copy rationale already documented at lines 54-56.

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2? No.
- [ ] **Complexity**: 3+ concerns? No — one helper + one call site in one test file.
- [ ] **Risk**: isolation needed? No.
- [ ] **Independence**: separable parts? No.

**Verdict**: No decomposition.

## Validation
- [x] Design review (plan-review subagents) completed — findings folded in (see Actual Results).
- [ ] User plan review before exec (per request).
- [x] Integration points verified: manifest traversal mirrors `cmd_fix_security` (`cwf-manage:729-743`); path-resolution join confirmed at `cwf-manage:743`; perm representability confirmed via `git ls-files -s`.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Design complete; 4 plan-review subagents run, findings folded in:
- **Robustness (material)**: the original "Known limitation" was wrong — the perm check is a floor (`($actual & $recorded) != $recorded`, `Security.pm:117` / `cwf-manage:776`), so a fresh-clone `0644` satisfies the `0444` recorded floor. Section removed; Background reframed; `-p`'s real value (umask-independence) and the three per-entry checks (existence/SHA/perm-floor) made explicit, with a SHA byte-identical post-condition added to Data Flow.
- **Improvements**: collapsed the two floated helper names to one (`_provision_extra_manifest_paths`); noted deliberate manifest re-decode.
- **Misalignment**: noted the `$REPO_ROOT` vs `$tmp` manifest-read asymmetry to be commented inline; confirmed the file-map traversal is production-internal (no exported util to reuse) so mirroring it is correct.
- **Security**: no blocking findings; added the repo-controlled-`path`/no-`..` inherited-trust invariant (mirrors `cwf-manage:743`) and die-names-the-path to Decision 4.
- Reproduced the failure (TC-1/2/7 red, TC-3/4/5/6 green) — purely Security `existence` violations on the 5 `.claude/agents/*.md` paths.

## Lessons Learned
The perm-floor semantics (vs assumed exact-match) was the load-bearing correction — verifying it against `Security.pm:117` collapsed a phantom BACKLOG follow-up. Full learnings in `j-retrospective.md`.
