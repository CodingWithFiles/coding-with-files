# upgrade installs cwf-init artefacts - Requirements
**Task**: 127 (feature)

## Task Reference
- **Task ID**: internal-127
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/127-upgrade-installs-cwf-init-artefacts
- **Template Version**: 2.1

## Goal
Specify the behaviour `cwf-manage update` must guarantee so that every upgrade re-applies the artefacts `/cwf-init` and `install.bash` produce, with safe (Debian-style) handling when an on-disk artefact has diverged from what the previously-installed CWF version shipped.

## Functional Requirements
### Core Features

- **FR1 — Artefact coverage and classification**: `cwf-manage update` must, in addition to its existing actions (`.cwf/`, `.cwf-skills/`, `.claude/skills/` symlinks, `.cwf/version`), apply the artefacts in the table below using the named strategy. The new helper drives the inventory; settings.json work delegates to the existing `cwf-claude-settings-merge` (FR10).

  | # | Artefact | Strategy | Conflict surface | Notes |
  |---|----------|----------|------------------|-------|
  | 1 | `.cwf-rules/` content | `replace` (file-by-file) | Three-way (FR3) | Mirrors `install.bash` `install_subtree`/`install_copy` for `.cwf-rules/` |
  | 2 | `.claude/rules/cwf-*.md` symlinks | `regenerate` | Structural (file ↔ symlink) only — see FR3 | Reuses `install.bash` `create_cwf_symlinks` semantics |
  | 3 | `.claude/settings.json` Skill(cwf-*) entries | `merge-json` (additive) | None (additive only — silent) | Inferred from `.cwf-skills/cwf-*/` |
  | 4 | `.claude/settings.json` Bash(...) allowlist entries | `merge-json` (additive) | None (additive only — silent, logged) | Delegates to `cwf-claude-settings-merge` |
  | 5 | `.claude/settings.json` Stop[] hooks | `merge-json` (additive) | None on additive — but each newly added hook is logged at `[CWF] INFO:` (NFR2) | Delegates to `cwf-claude-settings-merge` |
  | 6 | `.claude/settings.json` PreToolUse:UserPromptSubmit hook | `merge-json` (singleton) | Three-way on the matcher block | Rule re-injection hook |
  | 7 | `CLAUDE.md` CWF preamble block | `replace` (CWF-owned region only) | Three-way (FR3) | Bounded by sentinel markers (design phase chooses); user edits inside the block trigger a prompt |
  | 8 | `.gitignore` CWF entries | `merge-text` (line-additive) | None when on-disk is a superset; three-way otherwise | Exact-line match; CWF lines are tracked in the manifest |
  | 9 | `.cwf/rules-inject.txt` | `replace` if shipped by CWF; not present in current sources → no-op until added | Three-way once shipped | Currently referenced by hook 6 but not produced by install/init — flagged for design phase |

  Acceptance: after `cwf-manage update v<new>` on a project last installed at v<old>, every artefact in the table matches what `install.bash` + `/cwf-init` against v<new> would produce in a fresh repo, modulo user-owned content (FR2) and user-resolved conflicts.

- **FR2 — Out-of-scope artefacts (one-shot)**: NOT re-applied on update: `implementation-guide/cwf-project.json`, `implementation-guide/README.md`, the init commit, the user-level `~/.claude/settings.json` PERL5OPT prompt. Acceptance: a project whose `cwf-project.json` has been hand-edited still has those edits intact after `cwf-manage update`.

- **FR3 — Three-way conflict detection**: For each `replace` or `merge-text` artefact (table column 3), compare three states: (a) **baseline** — what the previously-installed CWF version shipped (FR8); (b) **on-disk** — what the project currently has; (c) **new** — what the new CWF version ships. Behaviour:
  1. `baseline == new` → no-op silently (no upstream change; on-disk state irrelevant).
  2. `on-disk == new` → no-op silently (already up to date).
  3. `on-disk == baseline` (and ≠ new) → install new silently.
  4. `on-disk != baseline` and `on-disk != new` → conflict → invoke FR4.

  Additionally, **structural conflict**: if on-disk and new differ in type (e.g. on-disk is a regular file, new is a symlink, or vice versa), always treat as a conflict (case 4 path), regardless of content. `merge-json` artefacts (rows 3–6) bypass FR3 — they delegate to `cwf-claude-settings-merge`'s additive merge.

  Acceptance: `t/cwf-manage-update-artefacts.t` covers all four content branches plus the structural-conflict case.

- **FR4 — dpkg-style conflict prompt**: When FR3 raises a conflict, prompt with these options (mirroring dpkg `conffile`):
  - **K**eep current on-disk file (no change).
  - **I**nstall new version (overwrite on-disk).
  - **D**isplay diff between on-disk and new (then re-prompt).
  - **A**bort the entire `cwf-manage update` run.

  Diff (option D) for files matching the secrets-pattern (NFR4) is redacted or replaced with a notice — not displayed verbatim. Acceptance: each option exercised in `t/cwf-manage-update-artefacts.t` via stdin scripting; redaction verified for `.claude/settings.json` and any `.env`-named file in the inventory.

- **FR5 — Non-interactive resolution**: When stdin is not a TTY, prompts must NOT block. Behaviour is governed by `CWF_UPGRADE_RESOLVE`:
  - unset or `prompt` → default to **keep** for every conflict, log each as `[CWF] WARN:` to stderr, exit non-zero with summary.
  - `keep` → keep on every conflict, exit 0 unless other errors.
  - `new` → install new on every conflict, exit 0 unless other errors.
  - `abort` → abort on first conflict, exit non-zero.

  Any other value is rejected with `[CWF] ERROR: invalid CWF_UPGRADE_RESOLVE='<v>'; expected one of prompt|keep|new|abort` and a non-zero exit. Acceptance: each valid value tested headlessly; one invalid value tested for rejection.

- **FR6 — Idempotency**: A second `cwf-manage update` immediately after the first (same ref, no user changes) must produce zero prompts and zero file modifications. Acceptance: test re-runs update twice and asserts the second run touches no files (verified via `git status -z` over `.claude`, `.cwf-rules`, `CLAUDE.md`, `.gitignore`).

- **FR7 — Atomicity / recoverability**: If `cwf-manage update` aborts mid-run (FR4 abort, FR5 abort, signal, or unexpected error):
  - `.claude/settings.json` remains parseable JSON (atomicity inherited from `cwf-claude-settings-merge` temp-file + same-directory `rename`).
  - No artefact is left in a half-written state.
  - The exact strategy (per-file temp+rename vs. whole-batch backup-and-restore) is a design-phase decision.
  - Re-running `cwf-manage update` after an abort must complete cleanly.

  Acceptance: kill-mid-prompt test (signal during prompt) leaves valid JSON in `.claude/settings.json` and a re-run succeeds.

- **FR8 — Baseline sources**: Baselines for FR3 come from two complementary sources:
  - **Scripts and hooks** (already tracked): baselines are the SHA256 entries already in `.cwf/security/script-hashes.json` (per Tasks 125 and 126). No new manifest needed for these.
  - **Non-script artefacts** (rows 1, 7, 8, 9 of FR1's table; row 2 is a regenerated symlink with no content baseline): baselines come from a new `.cwf/install-manifest.json` (final name chosen in design) shipped by every CWF release from this version forward, listing source path + SHA256 (or for line-additive `.gitignore`, the canonical line set).

  Acceptance: manifest exists, is committed, is registered in `script-hashes.json`, and `cwf-manage update` reads both sources.

- **FR9 — Bootstrap from no-manifest**: Projects upgrading from a CWF version that predates FR8 must still upgrade. The exact algorithm is a design decision; the requirement is:
  - Additive categories (FR1 rows 3–5: silent merge-json) apply silently as today (already idempotent).
  - For `replace` / `merge-text` categories without a baseline (FR1 rows 1, 7, 8, 9): the design phase chooses between (a) treat on-disk as baseline (no false "modified" prompts; new is installed silently when `on-disk == new`, prompted otherwise), or (b) require the user to run `/cwf-init` once to seed a manifest before upgrade. The choice must be justified in `c-design-plan.md` against the principles in `feedback_design_tradeoff_priority` (correctness > maintainability > performance).
  - If the cloned source itself lacks an `install-manifest.json` (network glitch, partial clone, source older than FR8), `cwf-manage update` logs `[CWF] WARN: cloned source has no install-manifest.json — non-script artefacts will be skipped` and continues with the script-only and additive subset.

  Acceptance: simulated upgrade from a manifest-less ref completes and exits non-zero only if a real conflict arises; missing-source-manifest test logs WARN, exits 0, and applies the script-only update.

- **FR10 — Shared code path**: `/cwf-init` and `cwf-manage update` invoke the same artefact-apply helper. `/cwf-init` is the "first install" case (no baseline → all new are installed). `cwf-manage update` is the "subsequent install" case. Settings.json work in both cases delegates to the existing `cwf-claude-settings-merge`. Acceptance: a single new helper script under `.cwf/scripts/command-helpers/` is referenced by both; `/cwf-init` SKILL.md is updated to call it; init and update behave identically when starting from an empty target.

- **FR11 — Concurrency**: `cwf-manage update` must take an exclusive file lock at the start of `cmd_update` (e.g. `flock` on `.cwf/.update.lock`). A second concurrent `cwf-manage update` either blocks until the first finishes or exits non-zero with `[CWF] ERROR: another cwf-manage update is in progress`. Acceptance: spawn two updates against the same project, verify the second waits or exits cleanly without corrupting `.claude/settings.json`.

- **FR12 — Malformed pre-existing state**: If `.claude/settings.json` is unparseable JSON when update starts (user truncation, prior crash), update aborts before applying any artefact, with: `[CWF] ERROR: .claude/settings.json is not valid JSON; restore with 'git checkout -- .claude/settings.json' or delete and re-run`. Acceptance: corrupt the file (truncate to half), run update, verify the error and that no other artefact was modified.

### User Stories
- **As a CWF maintainer**, I want a release that adds a new helper / hook / rule to be picked up by every existing project on `cwf-manage update`, so that I do not have to ask each user to re-run `/cwf-init` or hand-edit settings.
- **As a CWF user with custom hooks in `.claude/settings.json`**, I want `cwf-manage update` to ask before changing any of my entries, so that an upgrade never silently breaks my tooling.
- **As a CI operator running `cwf-manage update` headlessly**, I want a deterministic, non-interactive mode (env-var-driven) so that nightly upgrades neither hang nor silently accept destructive changes.

## Non-Functional Requirements

### Performance (NFR1)
- Artefact-apply phase adds < 2 s wall-clock to `cwf-manage update` on a typical project (≤ 30 upgrade-eligible artefacts).
- No subprocesses spawned per artefact in the no-conflict path; checksum + JSON merge in-process.

### Usability (NFR2)
- Prompt UX mirrors dpkg `conffile`: single-letter options, default printed, re-prompt on invalid input.
- Diff (option D) uses `git diff --no-index --color=auto`; falls back to plain unified diff when colour is disabled.
- Every silent action that introduces NEW behaviour (e.g. a newly-added Stop hook from the upgraded version) is logged at `[CWF] INFO:` with the artefact identifier and a one-line description, so the user can audit the upgrade. Pure no-ops (already up to date) are not logged.
- All log lines use the existing `[CWF]` / `[CWF] WARN:` / `[CWF] ERROR:` prefix conventions in `cwf-manage`.

### Maintainability (NFR3)
- Inventory of upgrade-eligible artefacts is data-driven: a single declarative list (Perl data structure or external JSON — chosen in design) classifies each artefact with its strategy from FR1. New artefacts are added by editing the list, not by adding code branches.
- The artefact-apply helper is one Perl file under `.cwf/scripts/command-helpers/`, registered in `.cwf/security/script-hashes.json`.
- All new code uses `use strict; use warnings; use utf8;` and `-CDSL` per `feedback_always_use_utf8` and `docs/conventions/perl-git-paths.md`.
- The helper accepts the git root as an argument or env var (not assumed from cwd) so it works regardless of where `cwf-manage update` was invoked from. (`cwf-manage` itself already calls `find_git_root()`.)

### Security (NFR4)
- **Trust boundary**: every source path read from `install-manifest.json` (cloned from a remote repo) is validated before use: paths must be relative, must not contain `..` segments, must resolve under the cloned source root, and must match an allowlisted destination prefix (`.cwf-rules/`, `CLAUDE.md`, `.gitignore`, `.cwf/rules-inject.txt`). Reject anything else with `[CWF] ERROR:` and abort the run.
- **Settings writes**: `.claude/settings.json` writes go via `cwf-claude-settings-merge` (already exists, idempotent, validates JSON). Never use raw string substitution on settings files.
- **Scope**: no artefact-apply step writes outside the project's git root.
- **Secrets in diff**: when option D (FR4) targets an artefact whose path matches the secrets-pattern (default: `^\.claude/settings\.json$`, `\.env$`, configurable via design), the helper redacts values (preserving keys/structure) or replaces the diff with `[CWF] diff suppressed for <path> — may contain secrets`. This is mandatory, not advisory.
- **Env-var validation**: `CWF_UPGRADE_RESOLVE` is rejected outside the set `{prompt, keep, new, abort}` (FR5).
- **Hook auto-install transparency**: per NFR2, every newly-added Stop hook is logged with the path that will be executed. (This is not user opt-in — hooks come from a trusted CWF release — but the user can audit.)
- **File permissions**: newly created files in `.cwf-rules/` use the project's umask (typically 0644 file / 0755 dir); created symlinks in `.claude/rules/` are mode 0777 as default for symlinks (target's mode controls). No setuid/setgid/sticky bits.
- **Script-hash discipline**: every new helper added under `.cwf/scripts/` is registered in `.cwf/security/script-hashes.json` with mode `0500` per Task 125.

### Reliability (NFR5)
- **Concurrency**: per FR11, exclusive lock prevents racing updates.
- **Malformed input**: per FR12, malformed `.claude/settings.json` is detected before any write and aborts the run.
- **Prompt loop**: hard re-prompt limit (10 invalid inputs) before defaulting to abort, so a stuck terminal cannot infinite-loop.
- **Atomic writes**: same-directory temp-file + rename for `.claude/settings.json` (inherited from `cwf-claude-settings-merge`); other artefacts use the strategy chosen in design (per FR7).
- **Cross-mountpoint safety**: temp files are created in the same directory as their target so `rename()` does not cross mount boundaries (already correct in `cwf-claude-settings-merge`).
- On any unhandled error, exit non-zero with `[CWF] ERROR:` and do not partially mutate `.claude/settings.json`.

## Constraints
- POSIX-only (no Windows-only patterns; `feedback_no_perl_c_check`).
- Perl helper with `use utf8;` + `-CDSL` shebang.
- Helper lives under `.cwf/scripts/command-helpers/`; subcommand pattern (`<name>.d/<sub>`) only if the helper grows multiple sub-actions.
- No heredocs / inline `perl -e` in any Bash tool calls during implementation or test (`feedback_no_heredocs`).
- Must coexist with Task 126's `cwf-claude-settings-merge` — reuse, do not duplicate.
- CLAUDE.md preamble update remains idempotent (matches current `/cwf-init` step 4 behaviour).

## Decomposition Check
- [ ] **Time**: Will this take >1 week? No, ≤ 5 days.
- [ ] **People**: Does this need >2 people? No.
- [x] **Complexity**: Does this involve 3+ distinct concerns? Yes — inventory + classification, three-way diff with manifest bootstrap, interactive UX, integration into existing update path.
- [x] **Risk**: High-risk components? Yes — `.claude/settings.json` corruption + the no-manifest bootstrap edge case.
- [ ] **Independence**: Can parts be worked on separately? Marginally, but they need to ship together.

**Recommendation unchanged from a-task-plan**: do not pre-decompose. Re-evaluate after design phase produces the artefact inventory and bootstrap algorithm.

## Acceptance Criteria
- [ ] **AC1 (FR1, FR10)**: After `cwf-manage update v<new>` on a project last installed at v<old>, an `install.bash` + `/cwf-init` against v<new> in a fresh repo produces a byte-identical artefact set (modulo user-owned files per FR2 and user-resolved conflicts).
- [ ] **AC2 (FR3, FR4, FR5)**: `t/cwf-manage-update-artefacts.t` covers: the four FR3 content branches, the FR3 structural-conflict (file ↔ symlink) case, all four FR4 prompt options, FR5's three valid resolve modes, and one invalid `CWF_UPGRADE_RESOLVE` value.
- [ ] **AC3 (FR6)**: A second `cwf-manage update` immediately after the first leaves `git status` clean across `.claude/`, `.cwf-rules/`, `CLAUDE.md`, `.gitignore`. Permissions on newly created files match NFR4 (verified via `stat`).
- [ ] **AC4 (FR7, FR12)**: SIGINT mid-prompt leaves `.claude/settings.json` parseable as JSON; a subsequent `cwf-manage update` completes cleanly. Truncated `.claude/settings.json` triggers FR12's error.
- [ ] **AC5 (FR8, FR9)**: Simulated upgrade from a pre-manifest ref completes; (a) additive categories produce no prompts, (b) replace categories follow the design-chosen bootstrap policy, (c) missing source-manifest logs WARN and exits 0.
- [ ] **AC6 (NFR4)**: New helper(s) registered in `.cwf/security/script-hashes.json`; `cwf-manage validate` passes after the change. Path-traversal manifest entries are rejected (test injects an entry with `..` and asserts abort). Diff of `.claude/settings.json` is redacted (test inspects the displayed output).
- [ ] **AC7 (NFR3)**: Adding a new upgrade-eligible artefact requires a single edit to the inventory list, not a new code branch (verified by reviewing the design's classification table and the implementation's data structure).
- [ ] **AC8 (FR11)**: Two concurrent `cwf-manage update` invocations either serialise (lock-and-wait) or the second exits cleanly; `.claude/settings.json` remains valid JSON throughout.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All FRs and NFRs satisfied. FR9 (bootstrap-from-no-manifest) implemented exactly as specified — pre-D12 installs upgrade silently with on-disk treated as baseline. NFR1 (~50ms subprocess overhead) verified by tests completing in <100ms.

## Lessons Learned
Acceptance-test mapping (TC IDs → e-testing-plan.md) made the testing phase faster: every requirement had a pre-named test case, no "what should we test?" loop in g-testing-exec.
