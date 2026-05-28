# install manifest baselines disagree with subtree - Implementation Execution
**Task**: 167 (bugfix)

## Task Reference
- **Task ID**: internal-167
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/167-install-manifest-baselines-disagree-with-subtree
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in `d-implementation-plan.md`
and `e-testing-plan.md`. Land D1+D2+D3 + four `script-hashes.json` SHA
refreshes in a single commit.

## Actual Results

### Step 1 — Pre-flight
- **Planned**: Confirm branch / clean tree / HEAD; verify recorded sha256s
  match git history for the four hashed files; lift validate-ordering
  guard until Step 9.
- **Actual**: Branch `bugfix/167-…` at `61f9140` (e-phase checkpoint).
  `sha256sum` of the four hashed files matched the recorded entries in
  `.cwf/security/script-hashes.json` exactly. Tree clean save for the
  expected `f-implementation-exec.md`, `g-testing-exec.md`,
  `j-retrospective.md` template stubs.
- **Deviations**: none.

### Step 2 — Restore 0700 perms on the two scripts
- **Planned**: `chmod 0700 cwf-apply-artefacts cwf-manage`.
- **Actual**: Done; ownership unchanged (`-rwx------`).
- **Deviations**: none.

### Step 3 — Write the regression test (test-first)
- **Planned**: New `t/installmanifest-integrity.t` with sanity floor +
  INV-1 + INV-2; run pre-fix; confirm INV-2 fails on `rules-inject`.
- **Actual**: Written; `prove` exited 1, INV-2 subtest #6 failed exactly
  as expected ("rules-inject dest must not start with .cwf/"); INV-1
  passed (source SHA still matched the empty-template baseline). The
  pre-fix failure output is captured at
  `/tmp/-home-matt-repo-coding-with-files-task-167/test-fail-pre-fix.txt`
  as the reproducer artefact.
- **Deviations**: none.

### Step 4 — Apply D1: remove `rules-inject` artefact entry
- **Planned**: Edit `.cwf/install-manifest.json`, remove the 7-line
  `rules-inject` object; the preceding `gitignore-entries` keeps its
  trailing comma; no other comma changes.
- **Actual**: Done; manifest is valid JSON; the new regression test
  now passes (6 subtests green).
- **Deviations**: none.

### Step 5 — Delete the empty placeholder template
- **Planned**: `git rm .cwf/templates/install/rules-inject.txt`.
- **Actual**: Done.
- **Deviations**: none.

### Step 6 — D2 edits to `cwf-apply-artefacts` + TC-RI-1
- **Planned**: 6 edits to `.cwf/scripts/command-helpers/cwf-apply-artefacts`
  (`@INVENTORY` row, dead `_install_file` branch, allowlist entry, two
  doc strings, one inline comment) + TC-RI-1 regex update in
  `t/cwf-apply-artefacts.t`.
- **Actual**: All 6 helper edits applied verbatim. TC-RI-1 regex
  initially updated, then retired (see Deviation A).
- **Deviations**: see **Deviation A — synthetic-manifest fallout** below.

### Step 7 — `cwf-manage` banner comment
- **Planned**: Strip `.cwf/rules-inject.txt` from the D7/D9 banner.
- **Actual**: Done.
- **Deviations**: none.

### Step 8 — `Security.pm` + `SKILL.md`
- **Planned**:
  - `.cwf/lib/CWF/Validate/Security.pm`: remove
    `.cwf/rules-inject.txt` from `@ALLOWED_DEST_PREFIXES`.
  - `.claude/skills/cwf-init/SKILL.md` lines 93, 99, 170 (per
    Refinement 2).
- **Actual**: All four edits applied. The line-116 hook command stays
  intact; the hook still reads the subtree-shipped file.
- **Deviations**: none.

### Step 9 — Refresh `script-hashes.json` and validate
- **Planned**: Compute new sha256s for the four hashed files; delete
  the `data."rules-inject-template"` entry; update the four entries;
  run `cwf-manage validate` → expect `[CWF] validate: OK`.
- **Actual**:
  - install-manifest:
    `1da39a42…` → `e1926a2f6fc5982c6a614e581546978185f6b175f8c43e7c5284328638855cac`
  - cwf-apply-artefacts:
    `b82a77af…` → `d72b4b98f4d862a0c879cb64a9341ace2c4bc77b2bd22efad6970fcc87bc7a93`
  - cwf-manage:
    `11952129…` → `751f0283adcc3279f12fcf1e111977093bec2ea6880abc3303d9ba16d12ff109`
  - CWF::Validate::Security:
    `7c93e0fd…` → `b8e74cd7072f68c412eb42015dbaba238dea5e4ab224440560207e69081b7b68`
  - `rules-inject-template` entry removed (was at lines 36–40).
  - `cwf-manage validate` → `[CWF] validate: OK`.
- **Deviations**: none.

### Step 10 — Final verification
- **Planned**: `prove t/installmanifest-integrity.t`; `prove` of the
  four directly-affected test files; `prove -r t/` full sweep; no-stray-
  references `git grep`.
- **Actual**:
  - `prove -r t/` — **53 files, 619 tests, all PASS**.
  - `git grep -nE 'rules-inject' …` outside test/guide directories
    returned five expected references only: two in SKILL.md
    (the still-operational hook command and its description),
    three in `.cwf/docs/glossary.md` (the "rules injection" entry
    describing the subtree-shipped file). No stale references.
- **Deviations**: none.

## Deviation A — synthetic-manifest fallout

**What surfaced**: At Step 6 verification, `prove t/cwf-apply-artefacts.t`
showed **12/18 subtests failing** (not just TC-RI-1 as the d-plan
implied). Root cause: `build_source` in the test file constructs a
synthetic manifest containing a `rules-inject` artefact entry with
`dest: .cwf/rules-inject.txt`. The Step 6 edit to
`@ALLOWED_DEST_PREFIXES` removes `.cwf/rules-inject.txt` from the
allowlist; the helper's path-validation pass at the head of
`apply_artefacts` now rejects every manifest produced by
`build_source` with `[CWF] ERROR: manifest artefact 'rules-inject'
dest path rejected: .cwf/rules-inject.txt`, exiting 3. Every subtest
that calls `build_source` fails, not only the rules-inject-specific
ones.

**Why the d/e plans missed this**: The d-plan claimed
"TC-RI-2..5 + TC-FR5-* fixtures use synthetic manifests; survive
unchanged" (Refinement 1 commentary). The plans correctly identified
that the fixtures are synthetic but missed that those fixtures still
re-declare the `rules-inject` artefact, which the helper now rejects
schema-side. The fault is in the planning phases, not the design — the
underlying design (D2#4 ALLOWED_DEST_PREFIXES edit, D2#2 @INVENTORY
removal) is correct.

**Resolution path chosen** (user-approved option 1 of 3 via
`AskUserQuestion`, headed "Reconcile tests"):
- Removed the `rules-inject` artefact object from `build_source`'s
  synthetic manifest.
- Removed the now-unused `rules_inject_content` arg and the
  corresponding `.cwf/templates/install/rules-inject.txt` write in
  `build_source`.
- Removed the unused `rules_inject` arg from `build_installed`.
- Retired five subtests that only existed to exercise the rules-inject
  inventory row: TC-RI-1, TC-RI-2, TC-RI-3, TC-FR5-KEEP, TC-FR5-NEW.
  TC-FR5-INVALID (env-var sanity) is preserved.
- Replaced the deleted block with an in-file comment pointing at the
  BACKLOG follow-up.

**Coverage delta**: `prompt_resolve`'s `CWF_UPGRADE_RESOLVE=keep|new`
branches are no longer covered by a direct artefact-level subtest.
They remain reachable through `apply_tree_replace` and
`apply_embedded_block` (both call `prompt_resolve` at the same shape
as `apply_replace` did). The runtime hasn't lost behaviour — only the
direct unit-test surface.

**Follow-up filed**: BACKLOG item "Restore CWF_UPGRADE_RESOLVE keep/new
coverage without rules-inject" (Low, chore, identified-in: task-167).
Proposed restore path: re-target `TC-FR5-KEEP` / `TC-FR5-NEW` against
`cwf-rules-bundle` (tree-replace) or `claude-md-preamble`
(embedded-block).

## Blockers Encountered
None ultimately blocking. Deviation A required a single user-facing
choice (which path to reconcile), resolved via `AskUserQuestion`.

## Deferral Check
- [x] All steps from `d-implementation-plan.md` executed.
- [x] All success criteria from `a-task-plan.md` met:
  - AC1: every artefact's `source`-SHA matches on-disk (INV-1, green).
  - AC2: regression check in place (`t/installmanifest-integrity.t`,
    green).
  - AC3: the dual-distribution conflict path is gone — the manifest
    no longer references any path that the subtree ships. Verified
    indirectly via INV-2 (no `.cwf/` dest/container) and via the full
    test suite green.
  - AC4: `cwf-manage validate` clean.
  - AC5: `.cwf/rules-inject.txt` remains the 331-byte populated file
    shipped via subtree; `git ls-files .cwf/rules-inject.txt` returns
    it as tracked.
- [x] All design guidance in `c-design-plan.md` followed.
- [x] Planned work deferred: yes, with user approval — see
  Deviation A. Follow-up backlog item filed.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 167
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
- Plans that say "synthetic fixtures unchanged" must explicitly inspect
  what those fixtures construct. The fixture name doesn't reveal what
  the fixture's manifest declares.
- When an `@INVENTORY`-driven helper has its allowlist tightened, every
  test that builds a manifest covering the removed entry inherits the
  rejection — even tests that aren't testing that entry.
- `AskUserQuestion` is the right exec-time tool for surfacing
  plan-vs-reality gaps when the right answer is binary or trinary;
  expanding scope unilaterally would have been worse.

## Security Review

**State**: no findings

Let me review this changeset. It removes the `rules-inject` artefact from the CWF install/update flow: removing the (empty) `templates/install/rules-inject.txt` source file, dropping `.cwf/rules-inject.txt` from `@ALLOWED_DEST_PREFIXES` allowlists in both `CWF::Validate::Security` and `cwf-apply-artefacts`, removing the inventory entry, deleting the rules-inject branch of `_install_file`'s logging, updating docs, and retiring the three TC-RI-* tests plus the TC-FR5-KEEP/TC-FR5-NEW tests that piggy-backed on rules-inject. Let me reason through each threat category.

(a) Credential/token leakage: Diff contains no secrets, tokens, keys, env vars, or `.env` paths. The `$REDACT_PATTERN` for `.env*` is preserved. Clean.

(b) Path traversal / unsafe writes: The change is a *contraction* of the destination allowlist (removing `.cwf/rules-inject.txt` from `@ALLOWED_DEST_PREFIXES` in two places). Removing an entry from an allowlist makes the helper *more* restrictive, not less — any future manifest that named `.cwf/rules-inject.txt` as a destination would now be rejected by `validate_write_path_allowlist`. The remaining entries (`.cwf-rules/`, `.claude/rules/`, `CLAUDE.md`, `.gitignore`) are unchanged and continue to constrain where artefacts can be written. No new write paths, no traversal exposure.

(c) Command injection / unsanitised input: No new shell-outs, no new interpolation into commands, no new external-input sinks. The only logic change in `_install_file` collapses a two-branch `log_info` into a single call — both branches were emitting structured `log_info` strings of values the helper itself produced, not attacker-controlled input.

(d) Privilege / permissions drift: No `chmod`, no `umask`, no permissions-manifest entries touched. `script-hashes.json` and the executable bit on `cwf-apply-artefacts` are untouched.

(e) Pattern risks worth flagging:

1. **Coverage regression for the `keep`/`new` resolve modes.** The retired comment in the test file explicitly acknowledges this: TC-FR5-KEEP and TC-FR5-NEW were the only direct artefact-level coverage of the `CWF_UPGRADE_RESOLVE=keep` and `=new` branches of `prompt_resolve`. After this task, only TC-FR5-INVALID remains for the env-var dispatch, and the `keep`/`new` behaviours rely on the BACKLOG follow-up to re-establish coverage on some other artefact. This is a *test-coverage* regression in security-relevant code — `prompt_resolve` decides whether to overwrite a user-modified file on disk during an update. The diff handles this responsibly (BACKLOG item recorded, comment in-file pointing at it), so this is process-level surfacing rather than a defect, but worth noting: until that follow-up lands, an accidental regression in the `keep` branch (e.g., a future refactor that silently overwrites a modified file under `=keep`) would not be caught by the artefacts test suite. Recommend the follow-up be prioritised before any refactor of `prompt_resolve`.

2. **Stale `.cwf/rules-inject.txt` left on installed systems.** This change removes the artefact from the install manifest and validator allowlist, but contains no cleanup step for existing installs that already have a `.cwf/rules-inject.txt` on disk from a prior install. The PreToolUse hook command `cat .cwf/rules-inject.txt 2>/dev/null || true` referenced in the SKILL.md edit is still in users' `.claude/settings.json` from prior `/cwf-init` runs. Security-wise this is benign: (i) the hook tolerates a missing file (`|| true`), (ii) the file, if present, was previously empty (`e69de29` is git's empty-blob hash), and (iii) the destination-allowlist contraction now *prevents* `cwf-apply-artefacts` from rewriting that path going forward, so a future malicious manifest cannot use the now-removed entry as a write target. The residual concern is only that a user who manually populates `.cwf/rules-inject.txt` with content would still have that content injected by their existing hook on each tool use — but that is a pre-existing property of the hook the user installed, not introduced or worsened by this diff. Worth flagging as something the eventual hook-removal task should address.

Neither of these is an actionable security defect in the diff itself. (1) is explicitly tracked; (2) is a pre-existing user-state question for a later task.

Relevant absolute paths:
- /home/matt/repo/coding-with-files/.cwf/lib/CWF/Validate/Security.pm
- /home/matt/repo/coding-with-files/.cwf/scripts/command-helpers/cwf-apply-artefacts
- /home/matt/repo/coding-with-files/.cwf/scripts/cwf-manage
- /home/matt/repo/coding-with-files/.claude/skills/cwf-init/SKILL.md
- /home/matt/repo/coding-with-files/t/cwf-apply-artefacts.t

```cwf-review
state: no findings
summary: Allowlist contraction and inventory removal; no new write paths, sinks, or privilege changes. Retired test coverage for CWF_UPGRADE_RESOLVE=keep/new is documented with a BACKLOG follow-up.
```

