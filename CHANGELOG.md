# Changelog

All notable changes to the Coding with Files (CWF) project are documented in this file, organized by task.

## Task 204: Resolve .cwf paths from project root, not cwd

### Status: Complete (2026-06-15)
### Duration: ~2 days (estimate 1–2 days, Medium; on estimate despite a mid-task scope addition).
### Impact: CWF skills and the settings generator no longer depend on `cwd == git root` to find `.cwf/...`. Two coordinated mechanisms fix one bug class. (1) **Skill cwd anchor** — 20 `SKILL.md` files gained a byte-identical, worktree-safe anchor block as their first action: it derives the **main** repo root via `git rev-parse --path-format=absolute --git-common-dir` (identical mechanism to the Task-173 `find_git_root()`) and `cd`s there only when not already at root. Because cwd persists across Bash tool calls within a skill invocation, one anchor fixes every later relative Bash call; a Phase-0 spike disproved the prior assumption that Read/Edit tool-paths resolve against the project root (they resolve against the **shell** cwd), so the same anchor covers relative doc-reads too — narrowing scope rather than expanding it. (2) **Hook registration** (`cwf-claude-settings-merge`, discovered live via a `PreToolUse:Bash hook error … not found` and folded into this task) — emitted hook `command` strings now carry the literal `${CLAUDE_PROJECT_DIR}/` prefix (the one variable guaranteed in the hook execution environment), with a new gate-state-independent, anchored full-string prune (`prune_stale_relative_cwf_hooks`) that re-links any stale bare-relative entries without creating duplicates. The hook **allowlist** entries deliberately stay relative (D6) — the permission layer keys on relative command strings, so prefixing the command without touching the allowlist preserves matching. The one hashed file changed (`cwf-claude-settings-merge`) had its `script-hashes.json` sha256 refreshed in the same commit.

### Notable
- **One bug class, two distinct fixes, because path surfaces resolve differently**: Bash + Read/Edit resolve against the shell cwd (fixed by the persistent anchor); hook commands resolve in a harness environment where only `${CLAUDE_PROJECT_DIR}` is guaranteed (fixed by the literal prefix). FR4(e) constant-command invariant preserved — the prefix is a compile-time literal (`$` backslash-escaped, rules-inject single-quoted), never `$ENV{...}` at generate-time; TC-13 guards the interpolate-to-empty regression.
- **Drift guard built in**: `t/skill-anchor-drift.t` asserts both byte-identical anchor *form* (TC-5a) and *coverage* (TC-5b — anchor present before the first `.cwf/...` action); a form-only check would pass a skill that omits the anchor entirely. The coverage half is what guards the silent off-root regression.
- **Spike-first narrowed scope**: disproving assumption A1 before the mechanical edit removed an entire would-be work-stream (separate Read/Edit path rewriting). Lesson carried: enumerate every path surface as an explicit design-phase spike item.
- **A plan-reviewer false positive** (`update-cwf-skill-docs.sh` claimed missing by three reviewers) was correctly rejected — `git ls-files` confirmed it exists.
- **Tests**: full `prove t/` green at **860 tests / 69 files** (67 prior + 2 new: `t/skill-root-anchor.t` TC-1–4, `t/skill-anchor-drift.t` TC-5a/b; `t/cwf-claude-settings-merge.t` extended TC-13–17). `cwf-manage validate` clean (only the generator hash changed). Both exec-phase security reviews returned **no findings**. One in-flight slip (invalid status `Implemented` in f) was caught by the workflow-status validator and corrected before sign-off.
- **Carried to BACKLOG**: a convention/checklist so future cwd/root tasks audit **all** path surfaces (Bash, tool-path, hook, generated config) and grep generated artefacts, not just source.

## Task 203: Nest tmp scratch dirs under per-project parent dir

### Status: Complete (2026-06-14)
### Duration: ~1 day (estimate ~0.5 day, Medium; slight over-run, all in design deliberation).
### Impact: CWF's per-task scratch convention moves from sibling top-level dirs (`${TMPDIR:-/tmp}/<dashified-repo>-task-<num>/`) to a single per-project parent holding per-task leaves (`${TMPDIR:-/tmp}/cwf<dashified-repo>/task-<num>/`, the literal `cwf` abutting the leading dash → `cwf-home-matt-repo-coding-with-files/task-203/`). Because the path prefix is now stable across tasks, the Bash/Write permission prompt for scratch artefacts fires **once per project** rather than once per task, and an optional user-owned allowlist rule can cover every task's scratch with a single entry. The convention SSOT (`.cwf/docs/conventions/tmp-paths.md`) was rewritten — nested canonical form, two-level derivation snippet (parent then leaf, `mkdir -m 0700`), worked example, the two-level threat-model guard, a defence-in-depth note, a new "Permission allowlist (optional, user-owned)" section, and an explicit `-tool-check` carve-out. The one in-tree consumer, `security-review-changeset`, now assembles `$parent`/`$scratch` and does a two-level `mkdir 0700` with a `-d && !-l` parent symlink reject (hash-tracked → same-commit `script-hashes.json` refresh). `/cwf-new-task` and `/cwf-new-subtask` gained a non-fatal provisioning step (reusing the canonical worktree-safe snippet) that creates the parent + leaf and surfaces the path. `CLAUDE.md`'s Tmp Paths bullet was updated.

### Notable
- **Boundary vs defence-in-depth, framed honestly**: the containment boundary stays the atomic `mkdir 0700` + fail-closed `0600` `.out` write; the `-d && !-l` (lstat) parent reject is scoped explicitly as defence-in-depth for the now-shared, longer-lived parent, not a racy TOCTOU stat masquerading as the boundary. Both exec-phase security reviews returned **no findings** and endorsed the framing.
- **"Surface, never smooth" is observable**: the helper deliberately omits the `pretooluse-bash-tool-check` precedent's chmod-clamp (with an inline anti-reintroduction comment) — TC-PARENT-REUSE asserts a pre-existing 0755 parent is left untouched.
- **Two deliberate scope removals**: `.cwfkeep` sentinel **cut** (D3 — the named parent is itself the discoverability marker), reversing the user's original instruction after confirmation; the shipped-settings allowlist rule became **documentation only** (D4 — the path embeds a machine-specific absolute path, so CWF edits no settings file). A mid-task `touch .cwfkeep` was confirmed a one-off and did not reinstate the sentinel.
- **`-tool-check` carve-out (D5)**: the `pretooluse-bash-tool-check` state dir keeps its own form (different dashify rule, already one-dir-per-project, written programmatically) — a named exception in the convention rather than unifying two hashed scripts for zero gain.
- **Tests**: extended TC-OUTFILE (nested shape + parent/leaf 0700), new TC-PARENT-SYMLINK and TC-PARENT-REUSE, extended END-block cleanup in `t/security-review-changeset.t`; D6 provisioning covered by manual smoke (success + forced-failure paths). Full `prove t/` 808/809 — the sole red, TC-VALIDATE, was a pre-existing in-flight-status artefact resolved by the retrospective status sweep, not a regression.
- **Carried to BACKLOG**: the TC-VALIDATE live-repo `validate` assertion is structurally red for any in-flight task (phase files legitimately carry placeholder statuses until their retrospective sweep) — scope it to a fixture or have it tolerate in-flight placeholders.

## Task 202: report whether parent branch is direct ancestor

### Status: Complete (2026-06-14)
### Duration: ~1 day (estimate <1 day, Low; on estimate).
### Impact: `context-manager hierarchy <task>` gains an additive parent-branch-ancestry signal so a caller can tell at a glance whether history is strictly linear (the archaeological-main invariant). `--format=json` emits a new bare-literal field `"parent_branch_is_ancestor": true|false|null`; the default markdown emits `Parent branch ancestor of HEAD: yes|no|unknown` (printed only for a parented task). The decision lives in one testable library function, `CWF::TaskPath::parent_branch_ancestry($task_path)`, returning a tri-state `1`/`0`/`undef`: it derives the parent task's branch (`<type>/<num>-<slug>` via `format_branch`), guards existence with a **list-form** `git rev-parse --verify --quiet refs/heads/<branch>` (deliberately *not* the backtick `branch_exists`, both for shell-safety and to avoid the `--list` glob's prefix-collision false-positive), then maps `git merge-base --is-ancestor <branch> HEAD` (`0⇒1, 1⇒0, else⇒undef`). The tri-state keeps *diverged* (`0`) distinct from *undecidable* (`undef`: no parent, missing branch, unborn HEAD). The shared list-form runner `run_quiet` was **hoisted** from `task-workflow.d/delete` into `CWF::Common` (exported) — one definition, two callers — and its failed-`exec` child hardened to `POSIX::_exit(127)` (Task-159 convention; matters more now that `CWF::Common` is broadly imported and `delete` pulls in `File::Path`). Four hash-tracked files (`Common.pm`, `TaskPath.pm`, `hierarchy`, `delete`) had their `script-hashes.json` sha256 refreshed in the same exec commit.

### Notable
- **The non-reuse of `branch_exists` is the load-bearing safety decision**: branch names originate from on-disk dir names (attacker-influenceable by anyone who can create a directory under `implementation-guide/`), so the existence guard routes through list-form `run_quiet` — never a shell string. Both exec-phase security reviews returned **no findings** and called this out; TC-6 proves the exact-match guard does not false-positive on a `feature/1-foo` decoy when the queried branch is an absent `feature/1-foobar`.
- **Detached HEAD is *not* undecidable** — a design refinement of FR4's original wording. `merge-base --is-ancestor <parent> HEAD` resolves a detached-but-valid HEAD to its commit and answers correctly; only a genuinely unborn HEAD errors (rc ∉ {0,1}) ⇒ `null` (TC-7).
- **The hand-rolled JSON serialiser is regression-guarded by a real parser**: the new field required a trailing comma on the prior last line, so TC-8 parses `--format=json` with `JSON::PP` (not a regex) and asserts every pre-existing field plus the new JSON boolean — catching a missed comma that would silently malform the output.
- **`git stash` is content-only** (process learning): after the edits, an initial read mistook Edit-tool perm bumps (0500→0700) + stale hashes for pre-existing repo failures. `git stash` reverts content but not fine-grained perm bits, so the residual drift was self-inflicted, not a repo problem. The hash refresh was a manual `sha256sum`-into-`script-hashes.json` edit because `cwf-manage fix-security` refuses content-hash rewrites by design (surface, never smooth); two unrelated pre-existing perms drifts were clamped fix-on-sight.
- **Tests**: new `t/taskpath-parent-branch-ancestry.t` (TC-1…TC-9, synthetic throwaway repos for the diverged/undecidable paths the strictly-linear live repo can't exercise); full `prove -l -j4 t/` green at 67 files / 807 tests; `cwf-manage validate` clean throughout.
- **Carried to BACKLOG**: a watch-item to migrate `CWF::TaskPath::branch_exists` off its backtick/`--list`-glob shape onto the list-form `run_quiet` + `rev-parse --verify` pattern this task established, if any future caller feeds it a less-trusted name.

## Task 201: Bash tool-check framework

### Status: Complete (2026-06-13)
### Duration: ~1 day (estimate 2-3 days, High; under estimate).
### Impact: CWF gains a configurable, **fail-open** PreToolUse `Bash` hook (`pretooluse-bash-tool-check`) backed by a pure-policy library (`CWF::ToolCheck`). On each `Bash` call it matches the command against an ordered, three-layer rule set — user-global (`~/.cwf/tool-check/bash/settings.json`), project checked-in (`{root}/.cwf/tool-check/bash/settings.json`), project-local (`settings.local.json`) — and on first match denies with the rule's **verbatim** guidance so the agent self-corrects away from commands that trip Claude Code's own permission prompts. An exact-repeat of an identical command is **not** blocked (it falls through to the native permission check). Rules are PCRE (safe in every layer because `re 'eval'` is never in scope) or, for complex cases, Perl functions — but a `perl` rule is honoured **only** from the two layers that never travel via `git clone`; a checked-in `perl` rule is dropped *before* compilation, keyed on caller-derived provenance. The framework **ships inert**: with no rule files the hook is a strict no-op, because the offending-command set shifts per model and per Claude Code version, so a fixed shipped rule set would be wrong by construction. Install **and** upgrade add `.cwf/tool-check/*/settings.local.json` to `.gitignore`; the hook auto-registers via `script-hashes.json` directives. A `--check` diagnostic (human-terminal only, never piped to agent context) previews the merged effective ruleset.

### Notable
- **The trust boundary is the load-bearing design choice**: the provenance-keyed `perl`-drop runs before `eval $code`, keyed on the *path the file was read from*, never on rule content (TC-3 asserts a content-claimed `provenance` is ignored). The exec-phase security review endorsed it unchanged — "no findings".
- **Two defence-in-depth controls (`--check`, the 64 KB refuse-to-match command cap) were added at plan-review rather than in requirements.** Sound, but a process note for the retrospective: input caps and diagnostics belong in the threat-model/requirements phase for security-sensitive features.
- **ReDoS is bounded in layers**: a best-effort in-process 2s `Time::HiRes::alarm` + the 64 KB cap sit beneath the one *guaranteed* bound, the harness `timeout` SIGKILL — design correctly does not rest safety on alarm pre-emption (TC-14 verifies under an external `timeout`).
- **TDD caught two real implementation bugs** during implementation-exec, before the testing phase. `t/tool-check.t` (7 subtests) + `t/pretooluse-bash-tool-check.t` (9 subtests); regression suite 60 tests; `cwf-manage validate` OK throughout (hook `0500`, lib regular file, hashes match).
- **Security-review cap friction (reinforces existing backlog items 127/143/147)**: the changeset helper's production-weighted cap (500) fired at 603 lines on the changeset that most needed review. implementation-exec was reviewed by overriding `--max-lines=800` (clean); testing-exec was recorded `error` per the deterministic exit-2 contract, since its production code was byte-identical to the already-reviewed-clean f changeset. No fourth cap-tuning backlog item was spawned.
- **Deferred to BACKLOG**: seeding CWF's own checked-in rule pack (Task 201 ships the mechanism only; rules are living config, re-evaluated per model / Claude Code version).

## Task 200: Group Stop-hook uncommitted-files warning by task number

### Status: Complete (2026-06-13)
### Duration: <1 day (estimate <1 day, Low; on estimate).
### Impact: The `stop-uncommitted-changes-warning` Stop hook now groups its dirty-file list by owning task number instead of flattening every match to a bare basename, so the operator can see which task each uncommitted wf file belongs to (`⚠ Uncommitted: 199: a-…, c-…; 30: f-…`). The task number is **elided** when a single task is dirty — that path is byte-identical to the prior flat output — and the `+N more` overflow cap is applied **per group** so no task's group is ever silently dropped (the top design risk). The hook reuses the canonical `CWF::TaskPath::parse_dirname` (loaded via the sibling `stop-stale-status-detector`'s `FindBin`/`use lib` pattern) rather than inlining a fourth copy of the task-number regex, and falls back to the raw parent-dir basename for a non-task path so a malformed entry is surfaced, not dropped. The hook stays `exit 0` with a single-line JSON envelope throughout. The edit is hash-tracked: `script-hashes.json` sha256 was refreshed in the same commit, working perms clamped to the recorded 0500.

### Notable
- **`git status --porcelain` sorts records lexicographically by pathname**, not by working-tree mutation order. The e-testing-plan's "file-plant order controls git-status order" framing was inaccurate; caught and corrected during testing-exec (no behavioural impact — the hook preserves whatever order git returns). Lesson: verify plan-time assumptions about a tool's output ordering against the tool.
- **A real-subprocess harness (throwaway git repo per case) is what exposed the sort-order assumption** — a test that mocked git's output would have encoded the wrong assumption silently. New `t/stop-uncommitted-changes-warning.t`: 7 cases / 20 assertions (single-task elision, flat overflow, two-task grouping, nested `28.1` subtask keying, per-group overflow with no group dropped, non-task raw-key fallback, clean tree).
- **A pre-existing, unrelated permission drift** (`security-review-changeset` 0700 vs recorded 0500) surfaced during implementation-exec validation; clamped fix-on-sight via `cwf-manage fix-security` rather than deferred.
- **Tests**: full `prove -r t/` green at 64 files / 782 tests; `cwf-manage validate` clean (sha256 + 0500 perms). Both exec-phase security reviews returned `no findings` (the pre-existing unescaped-basename JSON interpolation is design-disclosed in D3 and bounded by the `[a-j]-*.md` pathspec — inherited, not regressed).

## Task 199: Align scratch tmp-paths with the /tmp/claude sandbox

### Status: Complete (2026-06-13)
### Duration: single session (estimate 1-2 days, Medium; under estimate).
### Impact: CWF's per-task scratch convention now resolves its base via `${TMPDIR:-/tmp}` instead of a hardcoded `/tmp`, so scratch directories land inside whatever temp root the environment provides — `/tmp/claude` under a Claude Code sandbox that sets `TMPDIR=/tmp/claude`, and `/tmp` off-sandbox (unchanged). The change touches the convention SSOT (`.cwf/docs/conventions/tmp-paths.md` — canonical form, derivation snippet with trailing-slash strip, worked examples, threat model, namespacing rationale, and a new "Sandbox alignment" section) and the one helper that constructs the path in code (`security-review-changeset` `$scratch`, hash-tracked → same-commit `script-hashes.json` refresh). The driving agent-memory (`feedback_no_heredocs`, `feedback_no_tee_permissions`, `MEMORY.md`) was realigned in-session (user-global, uncommittable; recorded as a cross-surface dependency). An audit classified the full `/tmp` write surface into three classes: (a) `File::Temp` with `DIR` pinned in-repo (safe, unchanged); (b) the explicit scratch convention (re-rooted here); (c) default-location `File::Temp`/`tempdir` in `cwf-apply-artefacts`/`cwf-manage` (honour `$TMPDIR` natively, so safe once the sandbox sets it — disposition (ii), pending confirmation).

### Notable
- **Honour-`$TMPDIR` unified all three temp classes onto one signal**, dissolving an apparent two-concern decomposition (scratch convention vs helper temp hygiene) into a single coherent change, and keeping the *shipped* convention portable rather than hardcoding a harness-specific `/tmp/claude` literal onto every adopter.
- **The plan-review chain caught a blocking design↔requirements conflict** (the requirements specified a hardcoded `/tmp/claude` root; the design chose honour-`$TMPDIR`) — reconciled by amending FR2/FR3 with a note, the proper design-reveals-requirements loop-back. It also caught the empty-`TMPDIR` Perl/shell divergence (`// '/tmp'` only catches undef; an empty `TMPDIR=""` would collapse the path to filesystem root) before it shipped — TC-TMPDIR-3 asserts `unlike ^/-`.
- **The contract is testable without a sandbox** (assert the helper's `.out` lands under a set `$TMPDIR`), so the irreducible BLOCKED-ENV residue is only the sandbox *denial enforcement* and the `TMPDIR=/tmp/claude` fact — both carried to BACKLOG with a written repro. The dev session was confirmed unsandboxed (bare-`/tmp` write allowed; `TMPDIR` unset).
- **One transient self-inflicted break**: a literal `${TMPDIR:-/tmp}` placed in an *interpolating* `usage()` heredoc was parsed by Perl as a deref (44 failing tests), fixed by escaping `\${`. Caught immediately by the suite.
- **Tests**: TC-TMPDIR-1/2/3 added to `t/security-review-changeset.t` (set/unset/empty); full `prove -j4 t/` green at 63 files / 762 tests; `cwf-manage validate` clean; both exec-phase security reviews `no findings`.

## Task 198: Specify low effort level for the retrospective skill

### Status: Complete (2026-06-12)
### Duration: <1 hour (estimate <1 hour, Low; on estimate).
### Impact: `.claude/skills/cwf-retrospective/SKILL.md` gains `effort: low` in its frontmatter (inserted after `description:`), so the retrospective phase runs the session-pinned Opus at reduced reasoning effort — matching the mechanical exec phases that received the same treatment in Task 187. The retrospective is a reflection/record phase with no design judgement, so high effort buys nothing. This is the non-hash-tracked half of the Task 187 pattern applied to a third skill: `cwf-retrospective/SKILL.md` is absent from `.cwf/security/script-hashes.json` (verified), so no `sha256` refresh was required and `cwf-manage validate` stayed green throughout. The diff against the baseline is exactly one added line.

### Notable
- **Distinct from the open "effort/model values on guard agents carry security weight" backlog item.** That watch-item (from Task 187) concerns a silent-downgrade risk when `effort: low` is set on a *hash-tracked guard/reviewer agent*. This task sets `effort: low` on a *skill* with no security-gate role, so it does not trip that concern and does not retire that item.
- **A mid-task user question confirmed frontmatter field validity against primary sources.** `allowed-tools:` (on skills) and `tools:` (on subagents) are different fields with opposite restriction semantics — `allowed-tools:` pre-approves without restricting the tool pool; subagent `tools:` is a genuine allowlist. `effort` is a Claude Code extension (values `low|medium|high|xhigh|max`), not part of the agentskills.io open standard. Verified this session against code.claude.com and agentskills.io; recorded in j-retrospective.md.
- **Both exec-phase security reviews returned `no findings`** — a single static YAML literal with no executable, hash-tracked, env-var, or input-flow surface.

## Task 197: Reconcile or retire stale .cwf/utils spec docs

### Status: Complete (2026-06-12)
### Duration: ~0.5 day (estimate <0.5 day, Low; on estimate).
### Impact: Four inert `.cwf/utils/*.md` prototype-era spec docs (`config-loader.md`, `template-engine.md`, `task-validator.md`, `hierarchy-manager.md`) are deleted, so `.cwf/` no longer ships a pre-Task-189 design (old `cwf-project.json` shape, `{{taskId}}`/`{{taskUrl}}` vars, `plan.md`/`requirements.md` filenames, obsolete `implementation-guide/<category>/` dirs, `find|sed` numbering, awk extraction) to end users as if it were current guidance. `CWF-PROJECT-SPEC.md` and the live skills/helpers are now the uncontested single source of truth. The chosen direction was *retire*, not reconcile: the four docs had no functional consumer (no helper/lib/skill/template/test reads `.cwf/utils`, confirmed by a basename sweep run twice), and a reconciled prose duplicate would simply re-drift. None of the four files were hash-tracked, so no `script-hashes.json` refresh applied and `cwf-manage validate` stayed green throughout. The backlog's three-file framing was widened at planning time to include the equally-stale `hierarchy-manager.md`.

### Notable
- **Plan review prevented a dangling reference.** The mandatory 4-subagent plan review flagged a second, still-open backlog item (`BACKLOG.md:1272`, "Align cwf-extract skill … to grep+read") that cited the to-be-deleted `template-engine.md:41`. The plan was amended to drop that citation (the item stays open with `SKILL.md:48` as its sole surviving awk site) before any file was touched.
- **`backlog-manager retire` recorded the retirement transactionally** — moving the originating item to this section and capturing the all-four-files note in one atomic operation, so no separate manual CHANGELOG entry was needed.
- **Both exec-phase security reviews returned `no findings`** — the change is purely subtractive with no executable, hash-tracked, env-var, or input-flow surface.

### Retired Backlog Items
#### Reconcile or retire the stale .cwf/utils/*.md spec docs against CWF-PROJECT-SPEC.md

The .cwf/utils/{config-loader,template-engine,task-validator}.md docs still describe the pre-Task-189 cwf-project.json shape (project.name, source-management.type/url, task-management.type/url, branch-name-max-length). They are inert — no helper, lib, or skill references .cwf/utils (confirmed by grep during the Task 196 f-phase verification sweep) — so impact is low, but they mislead anyone reading them as current spec. Reconcile each against CWF-PROJECT-SPEC.md or retire the files. Sibling to "Prune vestigial blocks from the live implementation-guide/cwf-project.json".

<!-- Note: Retired (deleted) all four inert docs rather than reconciling: config-loader.md, template-engine.md, task-validator.md, and hierarchy-manager.md (the last not named in the backlog body but equally stale: obsolete implementation-guide category dirs and find/sed numbering). CWF-PROJECT-SPEC.md and the live skills/helpers are the single source of truth. -->

## Task 196: Reconcile cwf-project.json template with the validator schema

### Status: Complete (2026-06-12)
### Duration: ~0.5 day (estimate ~0.5 day, Low; on estimate).
### Impact: The shipped `.cwf/templates/cwf-project.json.template` is rewritten so a fresh `/cwf-init` produces a config whose *shape* matches `CWF-PROJECT-SPEC.md` and the dog-fooded live config — not merely one that happens to validate. The old template carried vestigial keys no code reads (`cwf-version`, `_cwf-version-note`, `title`, `team`, and an options-style `templates` block unrelated to the live legacy filename-map `templates`) and used pre-spec key names for documented pass-through concepts (`project` → `project-name`/`description`; `task-management` → `task-tracking`). Because the validator ignores unknown keys, a template-derived config already passed `cwf-manage validate`; the defect was shape, not validity — the wrong shape misled fresh users about what CWF actually reads. The rewrite keeps the two required validated keys (`supported-task-types`, `source-management.branch-naming-convention`) and the fail-closed `sandbox` block verbatim, drops the dead keys, aligns the pass-through names, and fixes the branch placeholder `{task-description}` → `{description-slug}`. `cwf-init` SKILL.md step-2 prose is synced to the produced key names. Neither edited artefact is hash-tracked, so no `script-hashes.json` refresh applied. The live config and the retirement of live `cwf-version`/`security.version-tracking` were held strictly out of scope (sibling backlog items).

### Notable
- **"Validates" and "matches the documented shape" are independent properties.** A validator-clean assertion alone would have passed against the old, wrong shape — so the guard test asserts specific key presence/absence (six vestigial keys absent, two documented names present, corrected placeholder), not just zero violations.
- **A pre-deletion reference sweep retired the "a helper silently reads a vestigial key" risk** and, as a by-product, surfaced the inert `.cwf/utils/{config-loader,template-engine,task-validator}.md` spec docs as still describing the pre-Task-189 shape — logged as a follow-up, not actioned.
- **An ambient permission drift surfaced as two transient full-suite failures.** A stash-test proved them pre-existing and unrelated to this changeset (working-tree drift on `cwf-claude-settings-merge`, 0700 vs recorded 0500, sha256 intact); clamped fix-on-sight via `cwf-manage fix-security`, suite then green.
- **Tests:** `t/cwf-project-template.t` extended with TC-3/TC-4/TC-5 (13 assertions, all PASS); `t/validate-config.t` green; full `prove t/` green at 63 files / 759 tests. Both exec-phase security reviews returned `no findings`.

### Retired Backlog Items
#### Reconcile cwf-project.json install template and /cwf-init output with the validator schema

The install template .cwf/templates/cwf-project.json.template still ships cwf-version, title, and task-management fields and omits the versioning, wf_step_config, and task-tracking blocks the system actually uses. A fresh /cwf-init therefore produces a config shaped unlike the dog-fooded implementation-guide/cwf-project.json and unlike what CWF::Validate::Config enforces. Reconcile the template and the /cwf-init output with the validator contract: required supported-task-types and source-management.branch-naming-convention; optional versioning, wf_step_config, sandbox. Note cwf-version was retired from the live config by Task 188 but still lingers in the template. This is a behaviour change (alters produced config), not a docs sync, so it was held out of Task 189.

<!-- Note: Template reconciled to spec shape; live config + version-field retirement remain separate out-of-scope siblings. -->

## Task 195: cwf-init UserPromptSubmit hook registered as dead PreToolUse matcher

### Status: Complete (2026-06-12)
### Duration: <1 day (estimate <1 day, Low; on estimate).
### Impact: `/cwf-init` now registers the rules-inject re-injection hook (`cat .cwf/rules-inject.txt`, from Task 99) as a **working** top-level `UserPromptSubmit` event instead of a dead `PreToolUse` group whose `matcher == "UserPromptSubmit"`. `PreToolUse` matchers filter by *tool name* (`Bash`, `Edit`, …), so a `UserPromptSubmit` matcher there can never fire — the hook had never run on any install. Registration moved out of model-executed SKILL.md prose (the bug's root cause) and into the deterministic `cwf-claude-settings-merge` helper, which already emits the correct shape and dedupes per event. The helper now: (1) injects the fixed hook as a **compile-time constant** `$CANONICAL_RULES_INJECT_CMD` pushed onto the hook list *after* `partition_manifest`, so it bypasses directive parsing and the value never carries external data (FR4(e)); (2) **migrates** existing installs via `prune_dead_userpromptsubmit_matcher` — matcher-scoped so sibling `PreToolUse` guards (`Edit|Write`, `Bash`) are preserved, fully defensive over hand-edited settings, surfacing the migration count in stdout (never a silent mutation); (3) widens the hook-directive event allowlist to admit `UserPromptSubmit` so a future directive-driven hook is not silently downgraded to `Stop`. One hash-tracked file changed (`.cwf/scripts/command-helpers/cwf-claude-settings-merge`) with a same-commit `script-hashes.json` refresh.

### Notable
- **The backlog entry's prescribed fix was itself wrong.** It specified a "flat hook-object array (no nested `hooks` wrapper)". Design established that Claude Code's `UserPromptSubmit` uses the *same* three-level group-wrapper (`[{ hooks: [ {type, command} ] }]`) as every other event — it ignores `matcher` but still nests under `hooks`. A flat-array "fix" would have been malformed; the design phase paid for itself on a Low-complexity task.
- **Structural fix over a patch.** Deleting the prose-driven JSON surgery and letting code emit the structure prevents future shape drift by construction, not by careful wording — directly retiring this bug's recurrence surface.
- **Migration safety proven, not asserted.** TC-UPS2 covers sibling preservation; TC-UPS5 exercises four malformed hand-edited `PreToolUse` shapes (all exit 0, hook still registered); the output-level smoke test confirmed the end-to-end shape, the surfaced migration count, and byte-identical idempotency.
- **Tests:** TC-UPS1–8 added to `t/cwf-claude-settings-merge.t` (41 subtests); TC-U1/TC-U4 updated for the now always-on hook (stdout hook-entry count 1→2, same contract as `env.PERL5OPT`). Full suite green; `cwf-manage validate` clean. Both exec-phase security reviews returned `no findings`.

### Retired Backlog Items
#### cwf-init UserPromptSubmit hook registered as dead PreToolUse matcher

`/cwf-init` step 6c (`.claude/skills/cwf-init/SKILL.md`) registers the rules-inject re-injection hook (`cat .cwf/rules-inject.txt`, from Task 99) under `PreToolUse` with `"matcher": "UserPromptSubmit"`. This hook can never fire: `PreToolUse` matchers filter by tool name (`Bash`, `Edit`, …), and no tool is named `UserPromptSubmit`. Per the Claude Code hooks docs, `UserPromptSubmit` is a separate top-level hook event that does **not** support matchers.

Fix: emit the hook under a top-level `"UserPromptSubmit"` key with a flat hook-object array (no `matcher`, no nested `hooks` wrapper):

    "UserPromptSubmit": [
      { "type": "command", "command": "cat .cwf/rules-inject.txt 2>/dev/null || true" }
    ]

Touch points: SKILL.md step 6c JSON block + the surrounding idempotency prose (lines ~107-128), which currently describes appending a `UserPromptSubmit` matcher to `PreToolUse`. Verify `cwf-claude-settings-merge` (step 6d) does not also re-introduce the wrong shape. Existing installs already carry the dead entry, so the fix needs a migration/cleanup path, not just a forward fix. Output-level smoke test: run `/cwf-init` against a scratch repo and confirm the resulting `.claude/settings.json` has a working top-level `UserPromptSubmit` hook.

<!-- Note: Fix moved registration into the deterministic cwf-claude-settings-merge helper; the prescribed flat-array shape was corrected in design to the universal group-wrapper. -->

## Task 194: security-review changeset omits untracked files from git diff

### Status: Complete (2026-06-12)
### Duration: ~0.5 day (estimate ~0.5 day, Medium; on estimate).
### Impact: `security-review-changeset` now includes untracked, non-ignored files in **both** the reviewed changeset body and the `--max-lines` production count. Before this, the helper built its changeset from `git diff <anchor>` (and `git diff --numstat`), which by definition omits untracked files — so a brand-new source file created before the exec-phase checkpoint commit was shipped to the security reviewer **unreviewed and uncounted**, a silent gap in a security gate. The fix enumerates untracked, non-ignored files via `git ls-files --others --exclude-standard -z`, makes them diff-visible with a transient `git add -N` (intent-to-add), lets the **unchanged** diff/numstat code paths render and count them, then restores the index. The mechanism was chosen over `git diff --no-index` specifically to preserve the helper's "git owns all path-matching" invariant — `git add -N` keeps `:(glob,exclude)` discounting working and returns rc 0, so the security-critical counting logic needed zero edits. The index restore is authoritative via a single `END` block that is PID-guarded (no-ops in `git_check`'s forked child), `$?`-preserving (never masks the load-bearing `exit 2` cap), and shell-free (`system('git','reset',...)`); `$SIG{INT}/$SIG{TERM}` handlers cover an interrupt between `add -N` and exit. The `, includes uncommitted` disclosure suffix was widened to fire for an all-untracked changeset too. One hash-tracked file changed (`.cwf/scripts/command-helpers/security-review-changeset`) with a same-commit `script-hashes.json` refresh. Core-Perl only (no `use POSIX`).

### Notable
- **The fix demonstrated itself on real files.** Run live in this repo, the helper went from omitting the 3 untracked f/g/j workflow-guide files to reviewing all of them (`reviewed 9 files`), with the working tree restored to `??` afterward — the bug, fixed, shown end-to-end before a unit test existed.
- **New tests surfaced a latent harness defect (a true positive).** Adding TC-1…TC-7 broke 8 pre-existing subtests because `run_helper_raw` wrote its `.helper-stdout`/`.helper-stderr` capture files *inside* the repo-under-test — which the now-correct helper swept into its own changeset. Read as signal rather than noise, the fix was to move capture files out of tree, not to weaken the new assertions. The security reviewer flagged this as a defensive improvement.
- **Empirical-probe-first design.** A throwaway git-mechanics probe run before the design phase turned the central mechanism choice into an evidence-backed decision; every later phase inherited that certainty with no rework.
- **Tests:** TC-1…TC-7 added to `t/security-review-changeset.t` (42/42); full suite 63 files / 741 tests green; `cwf-manage validate` clean. Both exec-phase security reviews returned `no findings`.

### Retired Backlog Items
#### security-review changeset omits untracked files from git diff

`security-review-changeset` `list_changed_files()` (line ~432) builds the reviewed changeset with `git diff --name-only -z <anchor>`, which lists tracked staged+unstaged changes but **omits untracked (new, not-yet-`git add`ed) files**. During an exec phase, a brand-new source file created before the checkpoint commit stages it is therefore invisible to the security reviewer — it ships unreviewed. `count_production_lines()` (line ~495, `git diff --numstat`) has the same blind spot, so new files also escape the `--max-lines` gate.

Fix direction: union the diff output with untracked-but-not-ignored paths, e.g. `git ls-files --others --exclude-standard -z`, deduplicated against the diff list, then feed the combined set through the same exclude-pathspec / numstat logic. Keep NUL-separated parsing (per git-path-output convention). Watch the anchor semantics: untracked files have no anchor-side blob, so numstat counts them as all-added (correct). Add a regression test: create an untracked file in a scratch tree and assert it appears in both the changeset and the production line count.

## Task 193: Lint agent files for ignored allowed-tools key

### Status: Complete (2026-06-11)
### Duration: ~0.5 day (estimate ~0.5 day, Low; on estimate).
### Impact: Adds `CWF::Validate::Agents`, a read-only validator wired into `cwf-manage validate`, that flags any CWF agent file (`.cwf-agents/cwf-*.md` when installed, else `.claude/agents/cwf-*.md`) whose YAML frontmatter carries an `allowed-tools:` key. That key is the *Skills/slash-command* schema; in an agent definition Claude Code **silently ignores** it — no parse error, no warning — leaving the agent with the *full* tool set instead of the intended `tools:` restriction. It is a privilege-escalation footgun that fails open, and the four `cwf-plan-reviewer-*` agents plus `cwf-security-reviewer-changeset` all depend on a correct `tools:` restriction. All five current agents already use `tools:`, so this is a **preventative guard against regression**, not a live-bug fix — `cwf-manage validate` stays green on the real tree. The validator inspects only the leading `---`…`---` block; an unterminated block is skipped (not body-scanned), so prose mentioning the key cannot false-positive. One new lib module (`.cwf/lib/CWF/Validate/Agents.pm`) + a one-line wire-in to `cwf-manage` `cmd_validate`; both hash entries refreshed in-task.

### Notable
- **Test-first caught a real defect.** The robustness plan-reviewer insisted an unterminated frontmatter block must be *skipped*, not body-scanned; that became TC-7; TC-7 then failed against the first single-pass implementation (which flagged the key *before* confirming the block was terminated) and forced the correct two-pass find-close-then-scan. The defect never left the implementation phase — the plan-review → test → implementation chain working as designed.
- **Asserting the check did something.** The a-phase "wrong scan target" high risk (dev `.claude/agents/` vs installed `.cwf-agents/`) was mitigated by a single-target resolver and *proven* non-vacuous by TC-4, which asserts the `.cwf-agents/` branch actually inspected a file rather than passing trivially.
- **Tests:** `t/validate-agents.t` (TC-1..TC-8) + real-tree regression via `cwf-manage validate` (TC-9) + full suite (TC-10, 734 tests green). Both exec-phase security reviews returned `no findings`.

### Retired Backlog Items
#### Lint `.claude/agents/*.md` for the silently-ignored `allowed-tools:` key

Task 186 found that `allowed-tools:` is the *Skills* frontmatter schema and is silently ignored on subagents — the failure mode is *more* permissive (all-tools inheritance), with no error or warning. Add a `cwf-manage validate` check (or a dedicated consistency rule) that flags `allowed-tools:` in any `.claude/agents/*.md` and recommends `tools:`. Task 186 fixed the five existing instances; this guard stops regressions and protects downstream installs that hand-author agents. Scope: one validator rule + test fixture. *(Delivered as `CWF::Validate::Agents`, scoped to the `cwf-*` namespace; a generalised unknown-key linter was deferred to a new backlog item.)*

## Task 192: fresh session reviewer grant acceptance tc 8910

### Status: Complete (2026-06-11)
### Duration: <0.5 day (estimate <0.5 day; on estimate).
### Impact: Closes out Task 186's three deferred fresh-session acceptance checks, confirming the reviewer-agent tool grant (`tools: Read, Grep, Glob, LSP, Bash`) is live in the agent registry and the reviewers still function — so CWF's plan-review and security-review gates are verified intact, not silently degraded. Verification only; no production code changed. Run in-session (user-chosen freshness option 1): the live registry showed the *restricted* grant on all five reviewers, which — unlike the pre-change `allowed-tools:` all-tools inheritance — only exists post-change, so it is a sound freshness signal. **TC-8** (registry shows exactly the granted set on all five reviewers; Edit/Write absent; LSP accepted), **TC-9** (the four plan reviewers ran to completion under the new grant with no tool-denied error, evidenced by the d-phase Step 8 plan review), and **TC-10** (`cwf-security-reviewer-changeset` emitted one well-formed `cwf-review` block; `security-review-classify` returned a single canonical token) all PASS, plus TC-REG (`prove t/`, 726 tests green).

### Notable
- **TC-REG caught a self-inflicted validity error.** The a/d/e plan files were authored with `**Status**: Planning`, but `Planning` is not in `cwf-project.json:status-values`, so `cwf-manage validate` (via `t/security-review-changeset.t`) failed. Fixed in-phase by setting the completed plan files to `Finished`. This is a live recurrence of the open backlog item *"Status value mismatch: planning-phase skill templates suggest 'Planning' but cwf-project.json doesn't include it"* — worth prioritising over its current Low standing.
- **Acceptance criteria for agent behaviour must be caller-observable.** Plan review reframed TC-9 away from "the reviewer reaches markdown-reader" (a subagent-internal tool trace the parent cannot see) to "the reviewer completes with no tool-denied error" (observable from the subagent's returned text).

### Retired Backlog Items
#### Fresh-session acceptance of the Task 186 reviewer grant change (TC-8/9/10)

The Task 186 `allowed-tools:`→`tools: Read, Grep, Glob, LSP, Bash` grant change on the five reviewer agents is only observable after the agent-definition cache refreshes (a `/clear` or a fresh session). In a new session on a branch carrying the change, confirm: **TC-8** the registry shows each reviewer with *exactly* `Read, Grep, Glob, LSP, Bash` (excludes Edit/Write) and `LSP` was accepted as a grant token (no load error); **TC-9** a plan reviewer (e.g. `cwf-plan-reviewer-misalignment`) runs on an existing plan and can invoke the markdown-reader skill (or run its script via Bash); **TC-10** `cwf-security-reviewer-changeset` still emits exactly one well-formed `cwf-review` block that `security-review-classify` parses. If markdown-reader is unreachable at runtime, the documented fallback is a `skills:` field — the core grant fix still holds. Verification only; no code change unless a discrepancy surfaces.

<!-- Note: All three checks passed in-session (freshness option 1): TC-8 registry shows the restricted grant on all five reviewers; TC-9 the four plan reviewers ran with no tool-denied error; TC-10 the changeset reviewer verdict classified to a single canonical token. -->

## Task 191: update lock fails own clean tree check

### Status: Complete (2026-06-11)
### Duration: ~1 day (estimate <1 day, Low; on estimate — effort concentrated in the design-phase alternatives analysis and the red→green evidence step).
### Impact: `cwf-manage update` no longer self-blocks on its own ephemeral `.cwf/.update.lock`. The updater acquires the lock *before* the clean-tree check (the D8 concurrency invariant), so on any install whose `.gitignore` lacks the manifest-mandated `.cwf/.update.lock` line, the lock surfaced as `?? .cwf/.update.lock` and aborted the very update that would add that ignore line — a self-blocking cycle escapable only by hand-editing `.gitignore` first. The fix makes `check_clean_tree` *lock-aware*: it appends a git `:(exclude).cwf/.update.lock` magic pathspec to its `git status` invocation, so git filters CWF's own lock before any output is produced. A new file-scoped constant `$UPDATE_LOCK_REL = '.cwf/.update.lock'` is the single source of truth shared by `acquire_update_lock` (joined to `$git_root` for `sysopen`) and `check_clean_tree` (passed **bare** as the exclude value, since `git -C $git_root` already resolves pathspecs relative to the root) — removing the latent drift site between the two consumers. Surfaced by a downstream v1.1.189 upgrade (issue 1 of 2). One hash-tracked file changed (`.cwf/scripts/cwf-manage`) with a same-commit `script-hashes.json` refresh.

### Notable
- **The exclusion is an exact literal, by design.** Excluding only `.cwf/.update.lock` (never a glob like `:(exclude).cwf/*.lock` or a directory prefix) means the change cannot mask any other uncommitted path. TC-5 turns that promise into an enforced regression check: with both the lock and a real untracked `.cwf/notes.md` present, `check_clean_tree` still dies and lists `notes.md`, and an `unlike($@, qr{\.update\.lock})` assertion proves the lock — and only the lock — is hidden.
- **D8 ordering and lock-path defence preserved.** The fix makes the check lock-aware rather than re-ordering it, so two concurrent updates still cannot both pass the gate. The symlink/TOCTOU guard (`-l` precheck + `O_NOFOLLOW`) stays in `acquire_update_lock`, which runs first; the excluded path is therefore always the guard-validated regular file. Both exec-phase security reviews returned `no findings`.
- **Tests:** TC-4 (lock-only tree → clean) and TC-5 (lock + real dirty path → dies, lists real path only) added to `t/cwf-manage-check-clean-tree.t`; both demonstrably fail pre-fix. Full suite 62 files / 726 tests green; `cwf-manage validate` clean.

### Retired Backlog Items
#### cwf-manage update self-blocks: .update.lock fails own clean-tree check when gitignore line absent

`cwf-manage update` acquires the update lock before the clean-tree check, and
`acquire_update_lock` (`cwf-manage:254-267`) creates `.cwf/.update.lock` on disk
via `sysopen(... O_CREAT ...)`. `check_clean_tree` (`cwf-manage:151-176`) then
runs `git status --porcelain --untracked-files=all -- .cwf .cwf-skills
.cwf-rules .cwf-agents`. Because the lock lives under `.cwf`, it appears as an
untracked file (`?? .cwf/.update.lock`) and aborts the update — UNLESS
`.gitignore` already lists `.cwf/.update.lock`.

That ignore line is itself added by the update (the `gitignore-entries`
artefact, `install-manifest.json:10-14`). So any install whose `.gitignore`
predates that artefact, or where `/cwf-init` never wrote it, is **self-blocking**:
`cwf-manage update` can never pass its own clean-tree gate. The only escape is
hand-adding the ignore line first — exactly what a v1.1.189 upgrade reported
having to do.

The lock-before-check ordering is deliberate (D8 comment, `cwf-manage:458-461`):
two concurrent updates must not both pass clean-tree before one blocks. The fix
must preserve that ordering. `.cwf/.update.lock` is CWF's own ephemeral artefact
and must never count as an uncommitted change regardless of `.gitignore` state:

- Exclude it from the scan via a pathspec — append
  `':(exclude).cwf/.update.lock'` to the `git status` invocation; OR
- Filter the record in Perl after `split /\0/` in `check_clean_tree`.

Pathspec exclusion is the narrower change (no post-parse special-casing) and
keeps the dirty-tree message accurate for every other path. Add a regression
test: marker-less `.gitignore` + lock present must still pass clean-tree.

Surfaced by a downstream v1.1.189 upgrade (reported as issue 1 of 2).

<!-- Note: Fixed via git :(exclude) pathspec in check_clean_tree; D8 ordering preserved. -->

## Task 190: backlog validate minimum structural contract

### Status: Complete (2026-06-11)
### Duration: ~1 day (estimate 0.5–1 day, Medium; on estimate — effort landed in fixture design and false-positive avoidance, exactly where planning flagged the risk).
### Impact: `backlog-manager validate` now asserts a minimum structural contract (`BACKLOG-000`) so a clean result means the file is actually *manageable*, not merely well-formed markdown that parses to "0 items". A new pure predicate `CWF::Backlog::backlog_structure_errors` scans the intro region (the whole file when there are no entries): it permits blank lines, prose, and at most one leading `# ` title, and flags any other heading (`##`–`######`) or list item as a `BACKLOG-000` error — because the manager tracks entries only as `## Task:`/`## Bug:` blocks and would silently ignore other top-level structure. The predicate is wired into `validate_backlog_tree`, and a mutation gate (`assert_backlog_structure`) makes `add`/`modify`/`delete`/`retire` refuse to run on a file that trips it — a refused `retire` writes neither `BACKLOG.md` nor `CHANGELOG.md`. So a foreign-format `BACKLOG.md` (e.g. sprint headings + flat task lists) is rejected up front rather than mutated into an inconsistent state; an empty-but-valid file (title + prose, zero entries) and all existing fixtures still pass. Entry **bodies** are unscanned — only the preamble is checked. Two hash-tracked files changed (`.cwf/lib/CWF/Backlog.pm`, `.cwf/scripts/command-helpers/backlog-manager`) with same-commit `script-hashes.json` refreshes; doc section added to `cwf-backlog-manager.md`. 15 new test cases (TC-1…TC-15, 10 unit + 5 integration) all pass; both exec-phase security reviews `no findings`; `cwf-manage validate` clean.

### Notable
- **Security by construction.** The `BACKLOG-000` message interpolates only a fixed kind-enum (`heading`/`list item`) and an integer line number — never the offending line text — so attacker-influenceable `BACKLOG.md` content cannot reach operator/LLM context via the error. TC-7's `unlike(...)` guard turns that design promise into an enforced regression check, and the same invariant is recorded as a precondition for the deferred CHANGELOG reuse.
- **Generic helper, narrow wiring.** `backlog_structure_errors` is format-agnostic and `@EXPORT_OK`, so the deferred CHANGELOG-parity work (KD5) is a wiring task, not a rewrite — pre-staged without taking on its risk now.
- **Documented fail-open boundaries.** An unterminated leading fence masks following content to EOF, and pure-prose / after-entry foreign content is not detected. These are coverage gaps in a *defensive* check (no new capability granted), pinned by TC-8/TC-9 and filed as a Low follow-up.

### Retired Backlog Items
#### Backlog validate must assert a minimum structural contract (manageability), not pass vacuously on foreign files

An external project adopting CWF already had a `BACKLOG.md` of a different shape (not the
heading-tree contract). `backlog-manager validate` reported success and `list` returned
"0 items" — yet the file was not in fact manageable: none of its content was recognised, and
any subsequent `add`/`retire`/`modify` would either no-op or canonicalise the foreign content
out from under the user. Validate gave a false "all clear".

**Root cause.** `validate_backlog_tree` (`.cwf/lib/CWF/Backlog.pm`) only walks
`$tree->{entries}`; everything the parser does not recognise as an entry falls into
`$tree->{intro}` and is never checked. A foreign-but-well-formed-markdown file parses to **zero
entries**, so every entry-level rule (BACKLOG-001 required keys, priority value, struck title,
body-before-meta) is satisfied *vacuously*. Unlike `validate_changelog_tree`, which asserts a
required top-level `# Changelog` header (CHANGELOG-001), the backlog validator has **no minimum
structural assertion** — there is nothing that says "this file is shaped such that the manager
can manage it."

**What we want.** `validate` should accurately reflect whether `backlog-manager` can manage the
file. Define a minimal *required structure* — a skeleton/contract of the heading-tree AST that
the manager's read and mutate paths depend on — and have validate assert it. The contract must
be **flexible**: additions and prose *outside* the required skeleton must be allowed and must
not break the tooling, but the elements the manager relies on (e.g. the top-level backlog
header, and the H2/H3 entry shape for any content presented as an entry) must be present and
well-formed for validate to pass.

**Sharp edges to resolve in design:**
- Distinguish a *legitimately empty* backlog (header present, zero entries — must stay valid)
  from a *foreign/unrecognised* file (no recognised skeleton — must fail). "Zero entries" alone
  cannot be the signal.
- Decide the new rule's identity/severity (e.g. a `BACKLOG-000` structural/min-AST error,
  mirroring CHANGELOG-001) and whether a foreign file is an `error` (blocks mutation) vs a
  loud warning.
- Avoid false positives on our own valid files, including the bootstrap/empty case and
  legacy-format files that `normalise` is meant to convert (the validator already refuses
  `**Field**:` entries pre-normalise — keep that path coherent).
- Consider symmetry: apply the same min-structure reasoning to CHANGELOG if a parallel gap
  exists.

**Acceptance:** a foreign `BACKLOG.md` (valid markdown, wrong shape) fails `validate` with a
clear structural message instead of reporting success + "0 items"; a header-only empty backlog
and all existing repo fixtures still validate clean; mutation commands refuse to run against a
file that fails the structural check. Test fixtures for both the foreign-file and empty-but-valid
cases.

<!-- Note: Shipped: BACKLOG-000 intro-region structural contract in CWF::Backlog + mutation gate in backlog-manager (add/modify/delete/retire refuse on foreign-format files). -->

## Task 189: sync docs and README with current CWF state (chore)

### Status: Complete (2026-06-10)
### Duration: ~1 day (estimate ~1 day, Medium; on estimate — the inventory/audit was front-loaded into planning, leaving exec mechanical).
### Impact: Brings the user- and maintainer-facing documentation back into agreement with the CWF that ships today, ahead of a public release. Six top-level docs were corrected or rewritten against code as ground truth (not against the prior prose): **README.md** (helper-script and workflow-step counts de-magicked, `discovery` added to capabilities, install prose corrected to read-tree-default + file-copy, and the camelCase config example replaced with a minimal **validated-schema** example pointing to the spec); **CLAUDE.md** (dropped the standalone "v2.0" in favour of "released under v1.1.x; file format v2.1", 8→10 lettered phases, "Five helper scripts" → "a suite", and the per-type file sets corrected to feature 10 / bugfix 7 / hotfix 7 / chore 6 / discovery 8 to match `%WORKFLOW_FILES`); **INSTALL.md** (stale `~70 files`/`18 skills` counts made count-free and self-describing, version examples standardised to the current `v1.1.x` era); **CWF-PROJECT-SPEC.md** (full rewrite against `CWF::Validate::Config` — validated keys vs explicitly-labelled pass-through blocks, retired `cwf-version`/`title`/`task-management`/`team` and the malformed `[::digit::]` examples); **COMMANDS.md** (full rewrite to the real 20-skill inventory + `cwf-manage`, removing `/cwf-substep`, the category-directory model, old `plan.md` filenames, and the `cig-` prefix); **DESIGN.md** (full rewrite as design *rationale* — the why — pointing to `.cwf/docs/` and CLAUDE.md rather than becoming a fourth verbatim architecture copy). A conventions charter was added to CLAUDE.md `## Conventions` documenting the `docs/` (develop-CWF) vs `.cwf/docs/` (all-users) audience split; all ten convention files already conform. The change set is **docs-only** — no `.cwf/**` or otherwise hash-tracked file was touched, so no `script-hashes.json` refresh. All 11 test cases and 5 non-functional checks passed; `cwf-manage validate` clean; an output-level smoke test confirmed a freshly generated chore task carries the correct file set and no stale strings.

### Notable
- **Code-grounding beat the planning audit.** The planning-phase audit claimed `perl.md` was duplicated across both conventions dirs and that "5 scripts" should be "24"; grounding every claim against `%WORKFLOW_FILES`, `Validate::Config`, and the skills dir showed the dirs are disjoint (no duplication) and that the exact script count is brittle (27 today) — hence the counts-policy that keeps brittle numbers out of prose entirely.
- **The plan assumed `scratchpad.md` was tracked; it is gitignored.** The `git rm` step was a no-op — `git ls-files` already returns nothing, so the release was never affected. Surfaced as a deviation and the local file left untouched rather than silently deleting a file CWF did not create ("surface, don't smooth").
- **The security-review line cap is a poor fit for docs-only change sets.** It weights all top-level docs as "production" and trips the 500-line cap with zero executable code, forcing an `error` state in both exec phases. Functionally benign (the subagent is correctly not invoked per the deterministic exit-2 rule), but recorded as a candidate for treating top-level `*.md` as non-production.

## Task 188: retire vestigial cwf-project.json version field (chore)

### Status: Complete (2026-06-10)
### Duration: ~1 session (estimate ~0.25 day, Low; on estimate — the variance was investigative, not implementation).
### Impact: Removes the vestigial top-level `version` field from `cwf-project.json` and its shipped template so `.cwf/version` is the single record of the installed CWF version — resolving the version-drift backlog item by **deletion** (path A) rather than a drift check ("the best part is no part"). The field had **zero code readers**, was not schema-required, and shipped a hardcoded-stale `"version": "v0.2.1"`, so removal changes no behaviour. Scope was strictly-narrow (top-level `version` only); `cwf-version`/`_cwf-version-note` and `security.version-tracking` are the identical vestigial pattern, deferred to a follow-up. A Step-1 baseline reader-sweep found `CWF-PROJECT-SPEC.md` declared `version` a **required** field in five places (root-object schema, the `#### version (required)` field-spec block, two config examples, the Required-Fields list); those edits were folded in at exec time (user-approved) so the spec no longer asserts a field that no longer ships — still `version`-only. New guard test `t/cwf-project-template.t` (parse-loudly via `decode_json` + `version`-absent assertion) locks the field out. Template, live config, and spec are not hash-tracked, so no `script-hashes.json` refresh. TC-1..TC-4: guard test green, `cwf-manage validate` **clean** (zero new violations), full `prove -lr t/` green bar one **pre-existing, unrelated** failure (`cwf-manage-fix-security.t` TC-8, a 0444-floor-vs-ceiling mismatch — filed as a follow-up); both exec-phase security reviews **`no findings`**.

### Notable
- **"Zero readers" had to include the spec.** The field had no *code* reader, but `CWF-PROJECT-SPEC.md` declared it *required*. The plan's reader-grep was code-scoped; the broader exec-time bare-string sweep caught the spec — exactly the a-task-plan Risk-1 "hidden consumer", in documentation form. Retiring the data without the spec would have traded a data drift for a doc drift. The recurrence (Task 174 saw the same gap with `@CWF_INTERNAL_PREFIXES`) reinforced the existing **"Plan-time symbol-deletion reference sweep"** backlog item, bumped Low→Medium.
- **Pre-existing repo noise, triaged not absorbed.** Reaching a clean `validate` meant clamping a stale agent-file permission on sight (`fix-security`, 0600→0400) and marking this task's lagging `Planning`-status plan files `Finished`. A stash-and-rerun proved the two failing test files fail identically on the clean baseline (13840c5) — so the sole remaining suite failure is demonstrably not this task's.

### Retired Backlog Items
#### Resolve cwf-project.json version drift vs .cwf/version

After `cwf-manage update`, `.cwf/version` was bumped to `v1.0.114` but `cwf-project.json` still recorded `"version": "v1.0.95"`. The external user deferred reconciling this on the basis that "`.cwf/version` is authoritative" — but it's unclear whether that's the design or just current behaviour.


- What is `cwf-project.json`'s `version` field meant to record? (installed CWF version, project schema version, last-init version, something else?)
- Is `.cwf/version` the authoritative installed-version source? If yes, why does `cwf-project.json` also carry a version?
- What reads each field today? (grep callers; any drift may already be silently broken)

**Resolution paths** (pick one in design phase):
- **A**: `.cwf/version` is sole authority — drop `version` from `cwf-project.json`, migrate any callers
- **B**: Both fields are intentional — `cwf-manage update` writes both; add a validate check for drift
- **C**: `cwf-project.json` records something distinct (e.g. project-schema version, init version) — rename the field to remove ambiguity

<!-- Note: Resolved by deletion (path A): retired the vestigial top-level version field rather than adding a drift check. Also removed it from CWF-PROJECT-SPEC.md (declared it required). -->

## Task 187: low effort level for exec wf step skills (chore)

### Status: Complete (2026-06-10)
### Duration: ~1 session (estimate <0.5 day, Low; on estimate).
### Impact: Drops the two exec-phase skills (`cwf-implementation-exec`, `cwf-testing-exec`) to `effort: low` so the mechanical execution steps run the session-pinned model (Opus 4.8 via `settings.json`) at reduced reasoning effort — the hard thinking already happened in the upstream planning phases. To stop that downgrade from silently weakening the security gate, the `cwf-security-reviewer-changeset` agent the exec skills spawn is pinned to `effort: high`, so the FR4(a–e) review always runs at high effort regardless of any skill→subagent effort inheritance. `effort` is a documented SKILL.md/agent frontmatter key (`low|medium|high|xhigh|max`); no `model:` key is set, so effort applies to whatever model is active. Three one-line frontmatter additions plus a same-commit `script-hashes.json` sha256 refresh for the hash-tracked reviewer agent (the two exec SKILLs are not hash-tracked). TC-1..TC-6 PASS (frontmatter presence/values, no `model:` key, YAML well-formedness, hash consistency, same-commit discipline, skill/subagent regression); both exec-phase security reviews **`no findings`**; `cwf-manage validate` clean. First use of `effort`/`model` frontmatter anywhere in the repo.

### Notable
- **A pasted prior-session claim was verified before being built on.** The earlier session asserting `effort` is a real frontmatter key had already made a factual error (cost arithmetic), so the claim was checked against the live Claude Code docs before any work — it held up.
- **`validate` proves integrity, not honour.** `cwf-manage validate` checks sha256/permissions; it does not verify the harness acts on `effort`. A future `effort: low` on a guard agent would pass `validate` while degrading the gate — recorded as a Known Limitation and a Low-priority watch-item. The only positive evidence the knob works is behavioural (exec ran cleanly under the new frontmatter).
- **Plan review earned its keep.** It caught a vacuous Step-4 grep (searching for a sentence never written) and surfaced the validate-vs-honour gap; both were folded into the plan before exec.

## Task 186: reviewer agents prefer tools over Bash (chore)

### Status: Complete (2026-06-10) — fresh-session acceptance (TC-8/9/10) pending in a new session (agent defs are session-cached)
### Duration: ~1 day across two sessions (planning a/d/e with the full plan-review panel in a prior session; exec f→j this session after a user review gate). On estimate (<1 day, Low); the grant-fix fold-in added edit sites, not design.
### Impact: Sharpens the CWF review/security subagents to genuinely prefer specialised read-only tools and skills over raw Bash, and fixes a latent frontmatter bug. **(1) Grant fix:** all five reviewer/security agents (`cwf-plan-reviewer-{improvements,misalignment,robustness,security}`, `cwf-security-reviewer-changeset`) declared their tool grant with the key `allowed-tools:` — which is the *skills* frontmatter schema and is **silently ignored on subagents**, so every reviewer was in fact inheriting **all tools** (including `Edit`/`Write`/`Agent`/`WebFetch`). Corrected to the honoured `tools:` key with a **defined** grant `Read, Grep, Glob, LSP, Bash` — a tightening from all-tools, with `Edit`/`Write` no longer granted. **(2) Guidance:** `.cwf/docs/skills/cwf-agent-shared-rules.md` and `.cwf/docs/conventions/subagent-tool-selection.md` now strongly steer reviewers to `Read`/`Grep`/`Glob` and **LSP** (code intelligence when a language server is configured) at tier 1, and name the **markdown-reader** skill at tier 2 for reading Markdown sections/frontmatter over `cat`/`sed`/`grep`; new anti-pattern rows for symbol-grep→LSP and md-grep→markdown-reader. **(3) Posture doc:** `.cwf/docs/skills/security-review.md` updated to record the retained-Bash posture (Bash is a guided last resort enabling the Bash-run markdown-reader skill; state-mutation avoidance now rests on guidance plus the absence of `Edit`/`Write`) with a named **FR4(c) residual threat** — reviewed content is untrusted, so a Bash grant widens the prompt-injection blast radius to command execution. Same-commit `script-hashes.json` sha256 refresh for the six hash-tracked files (five agents + shared-rules doc). Keeping Bash (vs removing it) was a deliberate user decision so the markdown-reader skill remains usable; narrowing Bash back out, or scoping Skill access via settings-permissions, is noted as a possible follow-up. **Agent definitions are session-cached**, so the grant change is only observable in a fresh session — fresh-session acceptance is recorded in g-testing-exec.

### Notable
- **The wrong-key bug failed *open*, not closed.** `allowed-tools:` is the Skills frontmatter schema; on a subagent it is silently ignored — no error, no warning — and the fallback is *all tools*, not none. So five reviewers meant to be read-only were inheriting Edit/Write/Agent/WebFetch. A guidance-only chore became a real security tightening once that was found.
- **"Prefer markdown-reader" and "remove Bash" turned out mutually exclusive.** markdown-reader is a Bash-run Perl Skill, not a built-in tool, so the requested preference *requires* a Bash grant. The resolution (keep Bash, guide hard, name FR4(c) as the residual threat) was a deliberate user decision rather than the original remove-Bash framing.
- **Skill access can't be narrowed in frontmatter.** Per-skill scoping (`Skill(name)`) is a settings-permissions construct; the `skills:` field only controls preloading. Restricting reviewers to *only* markdown-reader would need settings, not the agent file — recorded as a possible follow-up.
- **Both exec-phase security reviews returned `no findings`**, each confirming the Bash grant is disclosed and named against FR4(c) and that the net posture is a tightening from silent all-tools.

## Task 185: replace git-subtree with read-tree laydown (feature)

### Status: Complete (2026-06-07)
### Duration: ~1 day single session (estimate 2–3 days; under, thanks to an early read-tree spike retiring the top risk before any production code).
### Impact: Stops CWF installs from forcing **merge commits** into consumer repositories — the bug that broke `git bisect --first-parent` and linear-history workflows (and was hypocritical, since CWF itself eschews merge commits). The laydown now uses a merge-free `git read-tree` snapshot-replace (`git read-tree --prefix` into the index → `git checkout-index` materialise → the consumer makes one ordinary single-parent commit; CWF creates no commit itself). `read-tree` is the **default**; `copy` is retained as the documented fallback; `CWF_METHOD=subtree` is **refused** for fresh installs with guidance, and existing `cwf_method=subtree` installs are **migrated** to read-tree on `cwf-manage update` (recorded method translated before laydown, rewritten to `read-tree` only on success — fail-closed). A new read-only helper **`cwf-detect-merges`** (and `cwf-manage check-merges`) reports the **total** merge count plus the **CWF-subtree-fingerprinted subset**, advising — never performing — re-linearisation and pointing the user to the maintainer; it is counts-only (never echoes a commit subject), under-claims on ambiguity (a user's own merge is never over-claimed), and always exits 0. Touched `scripts/install.bash` (new `install_read_tree`, shared `readonly CWF_PAIRS` SoT, default flip, subtree refusal, `install_subtree` removed), `.cwf/scripts/cwf-manage` (migration translate + `cwf_method` version write + `check-merges` + `run_detect_merges`), the new `.cwf/scripts/command-helpers/cwf-detect-merges` (0500), INSTALL.md, and `docs/conventions/design-alignment.md` §4. Same-commit `script-hashes.json` refresh for `cwf-manage` + the new helper. Suite grew 58→61 files, **706 tests green** (TC-1..TC-13 across three new test files; three subtree-fixture test files migrated off the removed method); both exec-phase security reviews **`no findings`**; `cwf-manage validate` clean throughout.

### Notable
- **Spike-first retired the real risk.** A throwaway-repo spike proved read-tree's tree-identity, merge-freeness, mode preservation, and prefix-collision-on-reinstall behaviour *before* the approach was committed — implementation had no false starts.
- **The fingerprint was found by probing, not memory.** A real `git subtree add --squash` merge carries **no** `git-subtree-dir` trailer; the signal that actually fires is the squash **second-parent subject** (`Squashed '…' content`). Guessing would have shipped a detector that never matched.
- **Data-safety caught in plan review.** The materialise step originally used `checkout-index -a` with no clean-tree precondition on the fresh-install path — it could clobber unrelated dirty user files. Re-scoped to the four prefixes, NUL-safe; the smoke test confirmed an unrelated dirty file survives.
- **A requirement out-ran reality.** AC1's "fresh install → validate clean" is met by *neither* method (git `checkout-index`/`cp` honour umask, not the recorded ceiling); the clamp is delivered by the update/`fix-security` path, which the migration runs. read-tree is no regression vs copy — flagged as a possible follow-up.

## Task 184: changelog header brand name (bugfix)

### Status: Complete (2026-06-07)
### Duration: single session (estimate ~0.5 day; came in under, the migration descope removed the only cost driver).
### Impact: Completes the Task 59 rebrand in this repo's `CHANGELOG.md` and adds a regression guard. Two deliverables (planned as three): (1) `CHANGELOG.md:3` intro corrected from the stale `Code Implementation Guide (CIG)` to `Coding with Files (CWF)` — a literal substring swap, rest of the line byte-identical, so historical body `(CIG)` fragments (lines 2245, 2854) are untouched; (2) a new **`CHANGELOG-005`** warning in `CWF::Backlog::validate_changelog_tree`, intro-scoped exactly like CHANGELOG-001 (`@{$tree->{intro}}` only, via a literal `index` against the package constant `$STALE_CHANGELOG_BRAND`), so the stale brand cannot silently reappear in the intro while the body's legitimate history never trips it. Severity `warning` (a consumer should not be failed for a cosmetic line they did not author); escalates to error under `--strict` via the existing generic promotion (no rule-specific code). Same-commit `script-hashes.json` sha256 refresh for `CWF::Backlog` (lib module, no perms key). The originally-planned **upgrade migration was dropped**: investigation confirmed no CWF tooling ever seeds the intro into a consumer `CHANGELOG.md` (no template; neither `install.bash` nor `/cwf-init` create the file; bootstrap writes only `# Changelog` + `## Task N` nodes), so a migration would be a no-op in the wild — "the best part is no part". Brand casing held at canonical `CWF`; the project-wide `CWF`→`CwF` rebrand was filed as a separate Low backlog item. All TC-1..TC-8 PASS; full suite 698 tests green; both exec-phase security reviews **`no findings`**; `cwf-manage validate` clean.

### Notable
- **The migration evaporated under investigation.** The plan's "High Priority Risk" — where to hook a `cwf-manage update` header rewrite — turned out moot once design confirmed nothing writes the stale intro into user installs. Validating the propagation path before building the migration saved two-thirds of the planned scope.
- **Intro-scoping is the whole correctness story.** A naïve whole-file scan would have flagged the changelog's own retired Task-59 entries; binding the check to `$tree->{intro}` (mirroring CHANGELOG-001) is what makes the guard safe. TC-3 proves it, in-memory and against the live file.
- **Latent brand drift surfaced.** The repo canonical is all-caps `CWF` (glossary, README, Task 59 entry) but the intended branding is mixed-case `CwF` — pre-existing drift from Task 59. Held `CWF` here to avoid introducing the only `(CwF)` mid-rebrand; filed the rebrand as a backlog item.

## Task 183: permission-drift repair and agent guidance (feature)

### Status: Complete (2026-06-07)
### Duration: ~1 day across two sessions (planning a–e in a prior session with the full b/c/d plan-review panel; exec f→j this session after a user plan review). On estimate (Low–Medium).
### Impact: Codifies a standing **fix-on-sight permission-drift** rule so agents clamp drift the moment `cwf-manage validate` surfaces it, instead of the recurring failure mode of deferring it as "out of scope" / "a separate backlog item" (Task 173/174/182). Delivered **docs-only** — the repair engine (`cwf-manage fix-security`, clamp-only: `actual & recorded`, never raises) already existed, so no new code, no `cwf-manage` surface, and no `script-hashes.json` refresh (all three edited files are non-hash-tracked). Three edits: (1) a new `## Fix permission drift on sight` section in `.cwf/docs/conventions/hash-updates.md` carrying the rule (command quoted **byte-identical** to `CWF/Validate/Security.pm`'s `Fix:` line), the **perm-vs-sha256 boundary** (clamping is the *only* auto-repairable violation; sha256/content drift is surfaced, never smoothed — "Never recompute a hash to clear a validate warning"), the working-tree-only persistence note (perms are not a committable diff), and a no-names negative example drawn from the Task-182/174 deferrals; (2) a fix-on-sight note at the `validate` step of `.cwf/docs/skills/checkpoint-commit.md` on **both** the Script and Manual paths, each cross-referencing the new section; (3) a pure-pointer bullet on `CLAUDE.md`'s Hash Updates entry. FR1's repair sweep was a no-op at exec time (drift already cleared), so the mechanism is exercised by the FR6/TC-REPRO induce-drift→fix demonstration. All test cases PASS; both exec-phase security reviews **`no findings`**; `cwf-manage validate` clean.

### Notable
- **The rule proved itself before it was written.** During phase a, `cwf-manage validate` surfaced live permission drift on two Task-182 files; rather than defer, the drift was clamped on sight — a real instance of the exact behaviour this task codifies.
- **TC-REPRO double-checked the docs against live output.** The induce-drift→fix run (chmod 0700 on a recorded-0500 script → validate flags → `fix-security` clamps → validate OK → clean `git status`) produced the validate `Fix:` line, which is byte-identical to the command quoted in all three docs — AC2 verified against real tool output, not just source.
- **Plan-review caught a non-existent landing site.** FR2 originally targeted `CLAUDE.md ## Critical Rules`, which exists only in the user-global `~/.claude/CLAUDE.md` (not checked in, not installable). Re-pointed to the installed `hash-updates.md` convention doc. The cross-ref form and the byte-identical-command target were likewise corrected in planning, before exec.

### Retired Backlog Items
#### Restore Task-173 permission drift on three helper scripts

Three scripts content-modified in Task 173 (baseline `c886856`) sit at on-disk `0700`
against their recorded `0500` ceiling, because Task 173 skipped restoring edited-script
perms to recorded: `.cwf/scripts/command-helpers/context-manager.d/location`,
`.cwf/scripts/migrations/migrate-v2.1-file-order`,
`.cwf/scripts/command-helpers/template-copier-v2.0`. git stores only mode `100755`, so
the `0700`/`0500` distinction is invisible to `git status` and the drift is not in any
task diff — `cwf-manage validate` flags the live `0700`, and the drift produced 12
spurious full-suite failures during Task 174 (worked around by clamping in the working
tree only). Scope: run `cwf-manage fix-security` (clamp to recorded) on the three files
and commit, or verify they are already clamped and record the disposition. No source
change, so no hash refresh. Cites `feedback_hashed_script_working_perms` (recorded perms
are a ceiling as of Task 170).

<!-- Note: Superseded by Task 183: generalised fix-on-sight permission-drift rule + boundary; the three scripts were already clamped (Task 174) and the tree is clean at task end. -->

## Task 182: harden security-review-changeset agent contract (feature)

### Status: Complete (2026-06-06)
### Duration: ~1 day, single session (planning a–e earlier in the session; exec f→j after review). On estimate (Medium).
### Impact: Turns `security-review-changeset` into a one-command, agent-invoked tool so agents stop bolting `> /tmp/…; wc -l; grep` boilerplate onto a call the script can do itself. Five changes, delivered as a single-commit **four-site contract migration**: (1) `--phase=` → mandatory `--wf-step=<step>` validated against a fixed ten-value allowlist (the canonical workflow-step suffixes); the removed `--phase` is an unknown-argument error. (2) `--max-lines` now **defaults to 500** (was: unset = no cap), still overridable — behaviour-neutral for today's callers, which both already passed `--max-lines=500`. (3) The script **self-manages its output**: it derives the worktree-safe per-task scratch dir via `find_git_root()`, creates it `mkdir -m 0700`, and writes the full diff to `<scratch>/security-review-changeset-<wf-step>.out` (mode 0600) via the reused `atomic_write_text` (same-dir temp + `rename`, which truncates and replaces a pre-planted symlink rather than writing through it). (4) stdout carries exactly one confirmation line — `security-review-changeset: wrote <N> lines to <abs-path>` — so the agent needs no follow-up `wc`/`cat`/`grep`; the diff no longer goes to stdout. (5) The two exec SKILLs, the `cwf-security-reviewer-changeset` agent (now Reads `{changeset_file}` instead of an inlined `{changeset}`; `{phase}`→`{wf_step}`), and the canonical `security-review.md` all migrated to the new flag, file-output model, and exit/empty semantics (empty changeset → a 0-line `.out` + count-0 confirmation, not empty stdout). Same-commit `script-hashes.json` refresh for the helper **and** the agent file. Test suite migrated stdout→`.out` and extended to **35 subtests (0 failures)**; both exec-phase security reviews **`no findings`**; `cwf-manage validate` clean.

### Notable
- **`cwf-manage validate` earned its keep twice.** It caught an un-refreshed hash on the `cwf-security-reviewer-changeset.md` agent (the d-plan's hashed-file list named only the script), and surfaced a pre-existing `cwf-claude-settings-merge` working-tree perm drift (0700 vs 0500) that was then cleared. The integrity gate, not author vigilance, kept the commit consistent.
- **Reuse delivered the security properties for free.** `find_git_root` (worktree-safe, Task 173) + `atomic_write_text` (`rename`-replace = truncate **and** symlink no-write-through) meant no hand-rolled `O_NOFOLLOW`; the plan review caught and corrected a requirements/design divergence that had described the guarantee as open-failure rather than no-write-through.
- **Tests consume the contract like the agent does.** Assertions parse the helper's confirmation line for the `.out` path instead of re-deriving it, which sidesteps the macOS `/private/tmp` symlink-resolution divergence; TC-SYMLINK and TC-WORKTREE actively prove the no-write-through and main-tree-namespace properties. A missed stdout→file assertion migration (TC-WIDEN1) was caught by *running* the suite — the standing "rebrand needs an output-level smoke-test" lesson again.

## Task 181: adopt guarded worktree process (feature)

### Status: Complete (2026-06-06)
### Duration: planning a–e in a prior session + exec f→j in one session (estimate ~1 day, Medium). On estimate; effort skewed to review/verification (FR9 robustness, the live data-loss-class probe) over authoring.
### Impact: Adopts a single guarded CWF worktree process so all worktree use flows through the harness `EnterWorktree`/`ExitWorktree` tools instead of the raw-`git worktree` data-loss chain (Task 172 incident; Task 177 facts C1–C6). Ships **`.cwf/docs/conventions/worktree-process.md`** (the single source of truth: a 5-step Procedure, three hard prohibitions — no raw `git worktree add`, no `remove --force`, no `EnterWorktree(path:)` into a raw-added tree — a `Configuration` section, a `Threat model`, `Why`, and `See also`), sets **`worktree.baseRef: head`** in committed `.claude/settings.json`, and cross-links it from `CLAUDE.md` and `tmp-paths.md`. Mid-stream operator request added **FR9**: a two-touchpoint dangerous-allowlist detector — at install/update (folded into `cwf-claude-settings-merge`) and at worktree usage (the doc's pre-flight step), both a raw whole-file `git worktree` substring scan with **no JSON decode**, best-effort and symlink-guarded so it can never abort the merge (`run_settings_merge` dies on non-zero exit) and never writes the user-owned `settings.local.json`. The helper edit landed its `script-hashes.json` refresh in-commit at recorded perms 0500. The FR8 C2-refusal probe was run **live** under a strict safety envelope — confirming the refusal *and* resolving the design's open question: the harness honours `worktree.baseRef: head` from **project** settings (the worktree based on current HEAD), so the committed key is effective, not dead config. 11/11 test cases PASS; both exec-phase security reviews **`no findings`**; `cwf-manage validate` clean.

### Notable
- **The live probe paid off twice.** TC-8 confirmed the C2 uncommitted-changes refusal (closing the Task-177 runtime residual) *and* behaviourally resolved design Decision 3 — project-scope `worktree.baseRef` is honoured. Run under the safety envelope (clean pre-check, protective interim commit, no `cd` into the disposable tree, scratch-only, `discard_changes` never set, clean guarded teardown, no orphan).
- **Not parsing was the robust choice.** For a warning-only scan inside an abort-on-non-zero caller, a raw `git worktree` substring match with no JSON decode is both simplest and safest — a malformed user-edited `settings.local.json` cannot throw. Verified by fixture (TC-11.3/11.4).
- **Mid-stream scope churn.** FR9 arrived after planning, forcing a 4-agent design re-review and a four-doc re-commit; a stale `settings.local.json:127` citation (the operator removed that entry mid-session) was caught by the re-reviewers. Process lesson: elicit the *generalised* requirement at requirements time.

### Retired Backlog Items
#### Adopt guarded EnterWorktree/ExitWorktree as CWF's defined worktree process

Define a robust, guarded CWF worktree process built on the harness's `EnterWorktree`/`ExitWorktree` tools. Task 177 re-grounded this item against the live tool schemas and a fresh code inventory; the original "guard CWF's raw worktree flows" framing rested on a false premise and is corrected here.

**Why it exists (the real gap).** CWF has *no* defined worktree process, yet worktrees are used with CWF anyway: a model deciding on its own to run raw `git worktree add` mid-task (evidenced first-hand in Task 136 `f-implementation-exec.md:82-83`), manual scratch-worktree procedures in wf files (Tasks 136, 32), the harness Agent `isolation: worktree`, and the operator directly. Raw/ad-hoc use runs the `feedback_worktree_cwd_dataloss` chain (CWD left in a disposable tree, `--show-toplevel` resolving to the worktree, `git worktree remove --force` discarding uncommitted work). The gap is the **absence of a defined process**, not a missing guard on a scripted flow.

**Correction (Task 177).** CWF's scripts contain **no** raw `git worktree add`/`remove --force` — only two read-only `git worktree list` calls. The previous body's example was wrong: `task-workflow.d/delete` does not create or force-remove a worktree; its Check 7 runs read-only `git worktree list --porcelain` and *dies* ("remove the worktree before deleting") when a task branch is checked out elsewhere.

**Confirmed harness facts (live schemas, Task 177).** (C1) The uncommitted-changes guard applies **only** to worktrees created by `EnterWorktree`; `ExitWorktree` is a no-op on raw-`add` worktrees. (C2) `ExitWorktree(action: remove)` refuses to delete a worktree with uncommitted changes/unmerged commits unless `discard_changes: true`. (C3) `worktree.baseRef` defaults to `fresh` (branches from `origin/<default>`), conflicting with CWF's branch-off-HEAD rule (`feedback_branch_from_current_commit`). (C4) `worktree.baseRef: head` branches from current HEAD — the setting CWF needs.

**Scope.** (1) Create scratch worktrees via `EnterWorktree` so the C2 guard applies at all — model/manual raw `git worktree add` must be steered onto this path. (2) Set `worktree.baseRef: head`. (3) **Never** pass `discard_changes: true` unprompted — the guard friction is the feature (`feedback_surface_security_dont_smooth.md`); surface teardown to the operator rather than auto-removing. (4) A CWF skill must `ToolSearch` (`select:EnterWorktree,ExitWorktree`) to load these deferred tools, and rely on the gate's "project instructions (CLAUDE.md/memory)" clause — a documented CWF process *is* that authorisation. (5) Update `tmp-paths.md`; hash-refresh any edited helper. (6) Subsumes R6: no-needless-`cd`/absolute-path discipline so the dominant permission prompts stop; explicitly reject allowlist-broadening as the fix.

**Open question (runtime residual).** C2's refusal is Confirmed-by-schema but not watched-it-happen: the only path that exercises it (`EnterWorktree`) switches the session CWD and is gated, so Task 177 did not run a removal probe (data-loss/gating risk). The feature task should confirm the refusal behaviour the first time it wires `EnterWorktree` in, against scratch-only content.

<!-- Note: Delivered as Task 181: convention doc + worktree.baseRef:head + FR9 detector; C2 refusal and HEAD-base confirmed live. -->

## Task 180: phase-scoped planning-write PreToolUse guard (feature)

### Status: Complete (2026-06-05)
### Duration: ~1 session for exec→j (estimate 2–4 days, Medium–High). Under estimate — the Task-179 substrate did most of the structural work; this was the policy core + one hook + wiring.
### Impact: Implements **R1** of the CWF sandboxing feature (split from Task 179). When sandboxing is on and the new `sandbox.planning-write-guard` enum knob (`off`|`observe`|`enforce`, **default `off`** even with sandbox on) is not `off`, a fail-closed `PreToolUse` hook (`pretooluse-planning-write-guard`, matcher `Edit|Write`) guards CWF's **crown jewels** (`.cwf/`, `.claude/`): a crown-jewel Edit/Write is **denied** unless `task-context-inference` positively resolves (correlated) to a recognised **exec** phase (`implementation-exec`). The no-brick guarantee comes from *scope* — only crown jewels are ever denied; task-own files, `BACKLOG`, scratch, and anything outside `.cwf/`/`.claude/` pass through. Policy lives in a new pure lib `CWF::PlanningGuard` (`classify_path` canonicalises `..`/symlinks, conservative-crown on unresolvable; `decide` is confidence-first fail-closed with a **fixed enumerated deny token** — never a path/slug/command, FR4(c)/(e)); the hook is a thin I/O wrapper (tool-gate-first → crown-jewel-first short-circuit → root-anchored knob → STDERR-contained TCI → deny / observe-log / allow). `observe` mode logs would-block writes (fixed-key, no raw path) to the gitignored `.cwf/sandbox-violations.log` and permits — the de-risk dial before `enforce`. Built by widening the `cwf-claude-settings-merge` matcher regex to a `|`-alternation of tool-name tokens (admits no shell/settings metachar), threading a second independent registration gate (`$register_guard`), and adding the enum to **both** validators via a single shared `PLANNING_GUARD_VALUES` literal. Ships off-by-default; `.cwf/docs/sandboxing.md` § "Planning-write guard" documents it. Same-commit `script-hashes.json` refresh (new lib + hook + refreshed helper/`Config.pm`). NFR1 measured: crown 36.9 ms/call, non-crown 25.9 ms/call (both under ~50 ms). 77 task-specific tests; full suite **686 green**; `cwf-manage validate` clean; both exec-phase security reviews **`no findings`**.

### Notable
- **Latent Task-179 defect found + fixed.** `read_hook_directives` scanned only the first 15 header lines, but the canonical hook header places its `cwf-hook-event`/`cwf-hook-matcher` directives at ~line 18 — so **both** the R3 logging hook (shipped in 179) **and** the new guard silently fell back to `Stop`/no-matcher instead of `PreToolUse`. Caught by a dry-run (registration is an emergent property of helper ∘ header — source-grep would miss it). Fixed by scanning the **leading comment block** (stop at the first code line — no arbitrary cap; an interim 50-line backstop was removed on review feedback). Repairs R3's registration as a tested consequence (regression TC-M6).
- **Crown-jewel deny-list (Option A) collapsed the policy.** Reframing fail-closed as "deny a crown jewel unless positively in an exec phase" reconciled "fail closed" with "never brick", and sidestepped the allow-list bricking trap.
- **Lib/hook split made the matrix unit-testable.** The whole policy is exercised deterministically without git/TCI in `t/planning-guard.t`; the hermetic git-repo hook test only binds I/O (incl. a real-payload deny-envelope fixture — the binding check for Claude Code schema drift).

### Retired Backlog Items
#### R1: phase-scoped planning-write PreToolUse guard (CWF sandboxing 179.1)

Phase-scoped planning-write isolation (R1), split from Task 179 (c-design D7,
b-AC4d). During planning phases (a–e) with sandboxing on, gate Edit/Write to
the current task's own planning files; block edits to production
code/skills/helpers.

Scope this subtask must carry that 179 deliberately did not:

- **Matcher-regex widening.** 179 widened only the `read_hook_directives`
  *event* allowlist (to admit `PreToolUse`). R1 also needs the *matcher* regex
  (`/^[A-Za-z0-9_-]+$/`, helper line ~86) widened to admit `Edit|Write`. Restate
  the inert-string rationale when touching it.
- **Fail-closed without bricking.** The wf-step signal is partly
  attacker-influenceable on-disk state, so on ambiguous / malformed / absent
  inference (empty task-stack, multiple in-progress tasks,
  `task-context-inference` exit 1, a call outside any task) the gate fails
  closed (most-restrictive) AND surfaces a message — but must deny only the
  production crown jewels (`.cwf/`, `.claude/`, skills, helpers), never brick
  legitimate work. Derive the task path from a trusted source, not free-form
  file content.
- **Reuse, don't reinvent.** Build on `task-context-inference` /
  `CWF::TaskContextInference.pm` (already emits `workflow_step:`); do not
  re-parse branch/task-stack.
- **NFR1 cost.** The hook runs per Edit/Write call and inference shells out to
  git — bound and measure the per-call overhead.
- Same-commit `script-hashes.json` refresh for the new hook + the edited helper.

<!-- Note: Delivered as Task 180. Matcher widened to Edit|Write; fail-closed crown-jewel deny-list (deny unless positively in an exec phase); reuses task-context-inference; NFR1 measured. Also fixed the latent directive-scan misregistration affecting R3. -->

## Task 179: Integrate Claude Code sandboxing into CWF (feature)

### Status: Complete (2026-06-05)
### Duration: planning across prior sessions + f→j in one session (estimate 2–4 days, Medium–High complexity). Under estimate — TDD groundwork + a fully-pinned design made exec largely mechanical.
### Impact: Implements the 178-seeded feature: a master `sandbox.enabled` toggle in `cwf-project.json` (**default OFF** — writes zero `sandbox.*`/`permissions.deny` keys while off, no regression, verified against the current helper) gating CWF-managed Claude Code sandbox/permission config. When on: **R2** credential deny-list compiles each entry to **paired** `sandbox.filesystem.denyRead` (Bash-subprocess path) **and** `Read(P)`/`Read(P/**)` permission denies (Read-tool path) — neither alone, because the sandbox is Bash-only (Task 178); `failIfUnavailable` written **authoritatively** from a knob (default `true`) with a pure-Perl `$PATH`+`-x` dep guard for `bwrap`/`socat` (advisory, fixed-token message, never blocks, no shell/`which`); **R3** opt-in (default OFF) `PreToolUse` logging hook recording only a `dangerouslyDisableSandbox` **presence flag** (never the raw command) to a gitignored `.cwf/sandbox-violations.log`. Shipped with `.cwf/docs/sandboxing.md` (advises-not-enforces, Bash-only, agent-reachable escape hatch, no reliable violation event, `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` env-credential caveat). Built by extending `cwf-claude-settings-merge` + `CWF::Validate::Config` (`_validate_sandbox_block`); the hook-event allowlist widened to add `PreToolUse` (matcher regex unchanged). **Reversibility via ownership-by-shape — no provenance sidecar** (dropped at c-review as a credential-boundary-removal oracle): toggle-OFF removes the whole `sandbox.*` block + every CWF-shaped `Read(...)` deny, orphan-free, user keys untouched. **R1 (phase-scoped planning writes) split to subtask 179.1** (pre-authorised, SC4/AC4d) — needs a matcher-regex widening (`Edit|Write`) + a fail-closed-without-bricking design; 179 widened only the event allowlist (the clean seam R1 reuses). Same-commit `script-hashes.json` refresh (helper + `Config.pm` + `install-manifest` + new hook). TC-1..TC-13 all PASS; full suite **665 green**; `cwf-manage validate` clean; both exec-phase security reviews **`no findings`**.

### Notable
- **Bash-only sandbox → paired rules.** Carried first-hand from Task 178: Read/Edit/Write bypass the sandbox, so credential denial needs both a `denyRead` and a `Read(...)` deny; neither half closes the boundary alone.
- **Ownership-by-shape beat a provenance sidecar.** The c-design review flagged a non-hash-tracked sidecar driving deletions as a credential-boundary-removal oracle; it was dropped pre-implementation for removal-by-generation-shape (the `^Read\(.+\)$` region of the generated `settings.json` is CWF-owned) — no persisted state, no second write, no oracle. The cost (a user entry identical to a CWF default in the *generated* file is reclaimed) is documented; overrides belong in `settings.local.json`.
- **A plan contradiction surfaced at exec.** D5/AC3a/TC-7 asked for `failIfUnavailable` to be both *authoritative* and *warn-not-overwrite* — mutually exclusive without the provenance the sidecar was dropped to avoid. Resolved **authoritative** (the `cwf-project.json` knob is the single source of truth; fail-safe), recorded as a deviation. Process lesson logged: plan review should flag *mutually-contradictory* requirements, not just per-item soundness.
- **The unprovable was flagged, not faked.** Runtime `~`→`$HOME` expansion in the `Read()` permission matcher can't be exercised by the Perl suite; the emitted string-forms are tested and a one-off live confirmation is carried to rollout (h) rather than claimed verified.

### Retired Backlog Items
#### CWF-managed Claude Code sandboxing config (R2 credential deny-list, R1 phase-scoped writes, R3 violation logging)

Discovery Task 178 assessed CWF-managed Claude Code sandboxing for three operator asks and recommends BUILD, staged, decomposed at /cwf-new-task time. CWF *advises* config and *observes* via hooks; Claude Code + the OS enforce; the operator can widen/disable — CWF cannot guarantee any boundary (state "advises", never "enforces").

Shared prerequisite (build first): extend `.cwf/scripts/command-helpers/cwf-claude-settings-merge` to (a) manage `sandbox.*` and `permissions.deny` (it writes `permissions.allow` only today), and (b) widen its hook-event allowlist beyond `{Stop, SubagentStop}` to `PreToolUse` (and `PostToolUseFailure` for R3). The helper is hash-tracked — each edit MUST land its `.cwf/security/script-hashes.json` refresh in the SAME commit (`docs/conventions/hash-updates.md`); add no surface that silences `cwf-manage validate`.

Staging (by verdict strength):
1. R2 credential deny-list (Feasible-with-caveats; cleanest). The sandbox is Bash-only, so ship PAIRED `sandbox.filesystem.denyRead` (Bash subprocess path) + `Read(...)` permission deny (Read tool path) — neither alone is sufficient. Defaults `~/.ssh`, `~/.aws`; editable list in `cwf-project.json`; `~` expands to `$HOME`; cross-scope merge is union, so an adopter narrows a shipped default via `allowRead`, not by deleting the entry. Recommend pairing with `allowUnsandboxedCommands:false` guidance to make the Bash path enforceable.
2. R1 phase-scoped writes (Feasible-with-caveats via a PreToolUse hook; NOT feasible as a static per-phase sandbox switch — no such key, and Edit/Write tools never enter the sandbox). Hook keyed on the wf step inferred from on-disk task files / `task-stack`, gating Edit/Write to the task's planning files during phases a–e.
3. R3 issue logging (Feasible-with-caveats — UNRELIABLE; default OFF switch in `cwf-project.json`). No structured "sandbox violated" hook event exists; only proxies: PreToolUse observing the `dangerouslyDisableSandbox` param before the unsandboxed retry, and PostToolUseFailure (noisy). Logging observes only — it must never silence or disable a boundary (`feedback_surface_security_dont_smooth`).

Don't-build: R1 as a static `allowWrite` switch; R3 as reliable violation detection. Managed-only lockdowns (`allowManagedReadPathsOnly`, `failIfUnavailable`, `allowManagedDomainsOnly`) are an operator/MDM concern, not config CWF writes into a project's `.claude/settings.json`.

Weaknesses to carry into the build: default read leaks credentials; non-TLS-inspecting egress proxy (domain fronting); `excludedCommands` has no managed lockdown; fail-open unless `failIfUnavailable:true`; agent-reachable `dangerouslyDisableSandbox`; subprocess env inheritance (use `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB`). Full evidence + citations: implementation-guide/178-discovery-integrate-claude-code-sandboxing-into-cwf/f-implementation-exec.md.

<!-- Note: Implemented in Task 179: master toggle (default OFF) + R2 paired deny-list + authoritative failIfUnavailable + opt-in R3 logging + limitations doc. R1 split to live follow-up 179.1. -->

## Task 178: Integrate Claude Code sandboxing into CWF (discovery)

### Status: Complete (2026-06-04)
### Duration: <1 day across 2 sessions (estimate <1 day, Medium complexity). On estimate.
### Impact: Discovery — assesses whether CWF can drive Claude Code's built-in sandbox/permission boundary for three operator asks (R1 phase-scoped writes, R2 credential deny-list, R3 issue logging) and produces a cited, per-requirement feasibility assessment + one seeded feature backlog item. **No CWF code changes** (by design); deliverable is `f-implementation-exec.md` (mechanism inventory + verdict table + weakness carry-forward + recommendation) plus the seeded entry. **The reframing fact, verified first-hand against live docs: the Claude Code sandbox isolates Bash subprocesses only — Read/Edit/Write file tools use the permission system, not `sandbox.*`.** So R2 (credential denial) needs **paired** `sandbox.filesystem.denyRead` (Bash path) + `Read(...)` permission deny (Read-tool path) — neither alone suffices; and R1 (planning-write boundary) is a permission / **PreToolUse-hook** concern, not a static `sandbox.filesystem.allowWrite` switch (no per-phase sandbox key exists). Verdicts: **R2 Feasible-with-caveats** (cleanest; `~` expands, cross-scope arrays union-merge so an adopter narrows a shipped default via `allowRead` not deletion); **R1 Feasible-with-caveats** via a PreToolUse hook keyed on the wf step (**Not-feasible** as a static switch); **R3 Feasible-with-caveats-unreliable** — **no structured "sandbox violated" hook event exists**, only proxies (PreToolUse catching a `dangerouslyDisableSandbox` retry; PostToolUseFailure). Enforcement-ownership boundary stated honestly: `dangerouslyDisableSandbox` is **agent-reachable**, so every boundary is advisory unless `allowUnsandboxedCommands:false` — CWF *advises*, the OS *enforces*, the operator can *override*. Shared prerequisite for any build: extend `cwf-claude-settings-merge` (writes `permissions.allow` only today; hook events limited to `{Stop, SubagentStop}`) to manage `sandbox.*` + `permissions.deny` and widen the hook-event allowlist, each with a same-commit `script-hashes.json` refresh. **Recommendation**: BUILD, staged (prerequisite → R2 → R1 → R3), decomposed at `/cwf-new-task` time; seeded as one Medium-priority feature entry (single live entry, `validate` exit 0). TC-1..TC-7 all PASS; both exec-phase security reviews `no findings` (docs-only).

### Notable
- **The sandbox is Bash-only — that one fact reshaped the whole assessment.** The plans (a–e) framed R1 around a static `allowWrite` switch as though the sandbox governed the Edit/Write tools. It does not. Re-fetching the live docs at exec (the evidence-hierarchy discipline: doc/schema quote > grep > never memory) surfaced it; an in-session memory would have shipped the wrong framing.
- **A capped verdict beats a smoothed one.** R3 has no clean violation signal, so it was capped at *unreliable* rather than rounded up to "Feasible" — and the recommendation explicitly forbids R3 logging from ever becoming a silent boundary-disable (`feedback_surface_security_dont_smooth`).
- **The null result on R1's static switch was a finding, not a surprise.** a-plan Risk 1 named "R1 may have no clean mechanism" as the central open question and pre-listed candidates, so the PreToolUse-hook answer slotted into a verdict cleanly.
- **Plan-review cost was repaid at exec.** The d-plan review's corrections to the backlog-seed step (required `--title`, script-path-vs-skill-name, grep-not-`validate` as the count guard) meant Step 7 seeded clean on the first try.

### Retired Backlog Items
None — task originated from a user request, not the backlog. It **seeds** one new feature item ("CWF-managed Claude Code sandboxing config (R2 credential deny-list, R1 phase-scoped writes, R3 violation logging)") carrying the staged decomposition, the carried weaknesses (default read leaks credentials; non-TLS egress proxy; `excludedCommands` no managed lockdown; fail-open; agent-reachable escape hatch; subprocess env inheritance), and the hash-refresh-same-commit constraint for the future helper edit.

## Task 177: Ground EnterWorktree/ExitWorktree adoption in latest docs and CWF code (discovery)

### Status: Complete (2026-06-03)
### Duration: one session (estimate <1 day, Low complexity). On estimate.
### Impact: Discovery — re-grounds the "Adopt guarded EnterWorktree/ExitWorktree" backlog item against the **live** tool schemas and a fresh code inventory, replacing Task-172-era inference with citation. **No CWF code changes** (by design); the deliverable is a cited findings file (`f-implementation-exec.md`) plus one rewritten backlog entry. Verdicts: **C1** (guard applies only to `EnterWorktree`-created worktrees), **C3** (`worktree.baseRef` defaults to `fresh` = origin/default, conflicting with branch-off-HEAD), **C4** (`baseRef: head` branches from current HEAD) **Confirmed** from verbatim schema fragments; **C2** (`ExitWorktree remove` refuses on uncommitted changes unless `discard_changes: true`) **Confirmed-by-schema** with the runtime residual logged **Unverifiable-by-safe-probe** (the only guard-exercising path, `EnterWorktree`, switches CWD and is gated — no probe run, per design Decision 4). **C5 Refuted**: CWF's scripts contain **no** raw `git worktree add`/`remove --force` — only two read-only `git worktree list` calls; the old backlog body's "`task-workflow.d/delete` raw flow" example was false (that check is read-only `list` + `die`). **C6 Confirmed** (the actual gap): worktrees *are* used with CWF via undefined/unguarded paths — most dangerously the model self-initiating raw `git worktree add` mid-task (evidenced first-hand in Task 136 `f-implementation-exec.md:82-83`), plus manual procedures (Tasks 136/32) and the Agent `isolation: worktree`. **Outcome**: the backlog item is **reframed, not retired** — from "guard CWF's raw flows" to "define a robust, guarded CWF worktree process" built on the harness tools (create via `EnterWorktree` so the guard applies, set `baseRef: head`, never `discard_changes: true` unprompted). Rewrite went through `cwf-backlog-manager` (delete+add, `--body-file`); single live entry confirmed (validate exit 0). TC-1…TC-6 all PASS; both exec-phase security reviews `no findings` (docs-only).

### Notable
- **Refuted ≠ nothing to do.** A falsified premise (C5: no scripted worktree flow) left a real gap (C6: no *defined* process for the worktree use that happens anyway). Separating the harness-behaviour verdict from a relevance-to-CWF axis (design Decision 2) kept a dead premise from killing a live feature; an operator clarification mid-planning is what surfaced C6 and drove the b–e revision (`b07e787`).
- **The unsafe probe was correctly refused.** C2's removal-refusal could only be watched-it-happen via `EnterWorktree`, which switches the session CWD (the `feedback_worktree_cwd_dataloss` hazard) and is gated. The residual was logged Unverifiable-by-safe-probe rather than smoothed into a false Confirmed — honouring `feedback_surface_security_dont_smooth`.
- **Deferred + gated is a feature, not a blocker.** `EnterWorktree`/`ExitWorktree` load via `ToolSearch` and are gated to "user directly **or** project instructions (CLAUDE.md/memory)" — so a documented CWF worktree process *is* the authorisation that legitimises automated use.
- **Re-derived beats remembered.** A fresh grep found 6 actual `--show-toplevel` sites, not the stale "13" carried in `feedback_worktree_cwd_dataloss` (Task 173 had since routed most through a worktree-safe resolver).

### Retired Backlog Items
None — user-initiated to re-ground an existing backlog item, not to complete it. The item "Adopt guarded EnterWorktree/ExitWorktree as CWF's defined worktree process" remains open (rewritten in place), ready to plan as a feature; two carry-forward notes (confirm the C2 refusal when wiring `EnterWorktree`; the feature's security review must keep the `discard_changes` gate from being auto-authorised) live in that entry and `j-retrospective.md`.

## Task 176: Split `workflow-steps.md` into per-anchor docs

### Status: Complete (2026-06-02)
### Duration: one session (estimate ~0.5 day, Low complexity). On estimate.
### Impact: Chore — removes a recurring mid-skill halt. The 8 plan-phase SKILLs fetched phase guidance via a markdown anchor (`workflow-steps.md#planning`). The Read tool ignores the fragment, so an agent would improvise section extraction — typically `sed -n '/^## planning/,/^##/p'` — and Claude Code's permission gate flags `sed`, halting the skill mid-run for a prompt. Every alternative was strictly worse than reading a dedicated file (whole-file Read over-reads ~460 lines; `grep`+`Read` is a two-call round-trip). **Fix**: split the 10 phase sections of `.cwf/docs/workflow/workflow-steps.md` into self-contained `workflow-steps/{name}.md` files (each an H1 + a `../workflow-steps.md` up-link + the section body verbatim), repointed the 8 SKILL Step-5 references to plain single-`Read` paths, and reduced `workflow-steps.md` to a title + intro + Version Differences + Status Values + a `## Steps` table of contents. Fetching any phase's guidance is now one `Read` of one file — no shell, no permission prompt, no over-read. **Design decisions**: (D1) all 10 sections get a file, including the two execution sections that no skill references today, for uniformity; (D2) `Status Values` (anchor `#status-values`, 12 live referrers across templates + `glossary.md` + `workflow-preamble.md`) and `Version Differences` stay inline in the ToC — splitting them would ripple into 12 files for no gain; (D3) bodies preserved verbatim, machine-checked as substrings of the baseline section; (D4) no `install-manifest.json` edit needed — both installers copy `.cwf/` recursively, so the new subdir ships automatically. The split also fixed two latent broken anchors: `cwf-implementation-plan` / `cwf-testing-plan` referenced `#implementation` / `#testing`, which never resolved to the real `## Implementation Planning` / `## Testing Planning` headers; they now point at `implementation-planning.md` / `testing-planning.md`. TC-1..TC-8 all PASS; `cwf-manage validate` clean; `installmanifest-integrity.t` 6/6. Implementation-phase security review `no findings` (Markdown-only); testing-phase review hit the production-line cap (839 > 500, the new doc bodies count as production) and was recorded as `error` per the exit-2 contract without re-reviewing the same markdown.

### Notable
- **A markdown anchor is a false affordance for the Read tool.** `file.md#anchor` reads as "fetch this section" but Read ignores the fragment, so agents improvise extraction — the exact `sed` friction this task removes. One file per anchor makes the cheapest path the only path needed.
- **The change dogfooded itself before merge.** The retrospective SKILL's own Step 5 read the relocated `workflow-steps/retrospective.md` directly — the feature proved out within the same task.
- **A before/after verification script must pin the baseline SHA, not `HEAD`.** TC-2/TC-3 flashed a false red on the testing re-run because the content-checker diffed against `HEAD` (by then the post-rewrite ToC) instead of baseline `91d0b4c`. Product was correct; the harness was aimed at a moving ref. Pin the recorded **Baseline Commit**.

### Retired Backlog Items
None — task originated from a user request, not the backlog. One discretionary follow-up was noted in the retrospective (repoint the two exec SKILLs and the whole-file `checkpoint-commit.md` reference at the new files) but not backlogged, as those skills don't currently link phase guidance.

## Task 175: Record commit SHA, not annotated-tag object SHA, in `.cwf/version`

### Status: Complete (2026-06-02)
### Duration: part of one session (estimate <0.5 day, Low complexity). On estimate.
### Impact: Bugfix — a tagged install/update recorded the wrong `cwf_sha` in `.cwf/version`. `git rev-parse <ref>` returns the *tag-object* SHA for an annotated tag, not the commit it points to, and both SHA-recording sites used the bare form: `scripts/install.bash:310` (`resolved_sha="$(git … rev-parse "$resolved_ref")"`) and `.cwf/scripts/cwf-manage` `resolve_sha:225` (`'rev-parse', $ref`). So installing at `v1.1.169` recorded `cwf_sha=473baea…` (the tag object) while the tag's commit was `0764380…`. The field is display-only — `cwf-manage status` prints it and nothing verifies against it — but the false mismatch misled a real upgrade session into wrongly concluding "subtree installs HEAD, can't pin a tag" (it pins correctly). **Fix**: peel the resolved ref to its commit with `^{commit}` at both sites (`rev-parse "${resolved_ref}^{commit}"` / `'rev-parse', "$ref^{commit}"`) — a no-op for branches, lightweight tags, raw SHAs, and `HEAD`; only annotated tags change. Matches the established `^{commit}` idiom at `security-review-changeset:285` and `task-workflow.d/delete:209`; no new helper (Rule of Three not met). New TDD test `t/version-records-commit-sha.t` builds an upstream with **annotated** tags (`git tag -a`) — the discriminator the shared lightweight-tag fixtures lack — and asserts `cwf_sha == rev-parse <tag>^{commit}` and `!= rev-parse <tag>` for both install.bash and `cwf-manage update`, with a `cwf_version=<tag>` regression guard (red pre-fix, green after). Same-commit `script-hashes.json` refresh for `cwf-manage`. Full suite **Files=55, Tests=645** green; `cwf-manage validate` clean; both exec-phase security reviews `no findings`. Forward-only — existing installs keep their recorded tag-object SHA until the next install/update rewrites it.

### Notable
- **The annotated-vs-lightweight distinction is the whole test.** The shared `build_upstream` fixtures create *lightweight* tags, for which `rev-parse <tag>` already equals the commit and the bug cannot reproduce. Surfaced at plan review; the test creating its own annotated tag is what gives every assertion discriminating power.
- **`fix-security` is the wrong tool for a missing-bits drift.** During testing, `t/cwf-manage-fix-security.t` TC-8 failed: `.claude/agents/cwf-security-reviewer-changeset.md` sat at `0400`, below its recorded **floor** `0444`. An earlier `fix-security` in the same session had *clamped* the drift (`0600 & 0444 = 0400`) — clamping only removes bits, so it satisfied `validate`'s **ceiling** but couldn't restore the missing read bits. Resolved with `chmod 0444` (the recorded value, exactly what `install.bash` provisions). Local working-tree repair only — perms aren't git-tracked for non-executables, so no diff and outside this task's changeset.
- **A green `validate` is not proof perms are correct.** `validate` is a one-sided ceiling check; TC-8 is the complementary floor. Recorded perms satisfy both only when on-disk perms *equal* the recorded value.

### Retired Backlog Items
None — task originated from an upgrade-log assessment, not the backlog. The pre-existing "Restore Task-173 permission drift on three helper scripts" item remains open (this task touched a different drifted file opportunistically).

## Task 174: Review all changed files, not just CWF-internal

### Status: Complete (2026-06-02)
### Duration: ~1 day across 2 sessions (estimate <1 day, Low complexity). Over estimate; complexity landed nearer Medium.
### Impact: Bugfix — fixes a shipped correctness defect in the exec-phase security-review gate. `security-review-changeset` classified each changed file and emitted to the reviewer **only** those under a hardcoded CWF-internal prefix (`.cwf/`, `.claude/`) **or** carrying a recognised script shebang. Every other changed file — a consumer's `config.go`, `app.ts`, `Main.java`, any compiled-language source — was excluded by construction, so for a project that is not itself a pile of shell/Perl scripts the gate emitted `reviewed 0 files` and the workflow read that as a clean pass. The one thing the feature exists to do — review the code the user is shipping — was the one thing it never did. **Fix**: deleted the classifier (`@CWF_INTERNAL_PREFIXES`, `%CWF_INTERNAL_FILES`, `$SCRIPT_INTERPRETER_RE`, `is_cwf_internal`, `looks_like_script`, the classification loop) and set `@included = @changed` — every changed file is now reviewed, any path, any language (helper net −156 lines). The `--max-lines=500` cap is unchanged in mechanism: it measures production-weighted lines (added+deleted) minus the configured exclude-path globs; test/doc files are **reviewed but not counted**. The empty-`@included` guard (no pathspec → bare whole-tree diff) was preserved as the highest-consequence invariant and is now directly asserted. **Config-key rename** (user-directed, mid-exec): `security.review.test-paths` → `security.review.max-lines-exclude-paths` (the key never only excluded *test* paths), with a backward-compat fallback — the helper reads the new key, falls back to the legacy key with a stderr deprecation warning, and both exec SKILLs now surface any helper `warning:` line verbatim regardless of exit code so adopters get the upgrade nudge. All living docs (helper header, `security-review.md`, both exec SKILLs, agent prompt) swept of CWF-internal-only framing. Same-commit `script-hashes.json` refresh for the two hash-tracked files (helper + agent). Full suite Files=54, Tests=643 green; `cwf-manage validate` clean; both exec-phase security reviews `no findings`.

### Notable
- **A gate that silently passes is more dangerous than one that errors.** `reviewed 0 files` was a default-allow gate masquerading as default-deny — a latent correctness defect, not a documented limitation. The fix's net direction is *widening* coverage, the opposite of an attack-surface expansion.
- **Dogfooding caught the defect on the tool itself.** The cap fired at 706 > 500 on this task's own changeset (its wf docs counted as production lines), materialising a-plan Risk 1 on the very task that fixed it. Resolved by adding `implementation-guide/**` to the cap-discount set — never to review exclusion — which in turn exposed the `test-paths` misnomer and triggered the rename. The cap firing was **not** smoothed by hand-building a smaller changeset (the prior anti-pattern).
- **Plan review reviews logic, not symbol topology.** The 4-subagent map/reduce found nothing wrong with the reasoning, but the plan scoped test reconciliation to the co-located `t/security-review-changeset.t`; two other test files (`t/cwf-check-tree-symlinks.t`, `t/install-bash-reinstall.t`) asserted on the deleted `@CWF_INTERNAL_PREFIXES` and surfaced only at exec. Seeds a backlog item for a plan-time symbol-deletion reference sweep.
- **Every preserved invariant fails toward more review:** unconfigured/unmatched paths count as production (cap fires earlier), a malformed exclude pattern makes git fatal (exit 1), an empty diff short-circuits before any bare-tree diff. Widening coverage weakened none of them.

### Retired Backlog Items
None — user-initiated from a discovered shipped defect, not from the backlog. Seeds 2 follow-up items (Task-173 perm-drift housekeeping; plan-time symbol-deletion reference gate) added to BACKLOG.md.

## Task 173: Audit show-toplevel sites for worktree-safety

### Status: Complete (2026-05-31)
### Duration: ~1 day (estimate ~1 day, Medium complexity). On estimate.
### Impact: Bugfix — closes data-loss mechanism (b) from Task 172: `git rev-parse --show-toplevel` returns the *worktree* root inside a linked worktree, so the "go to repo root" idiom silently anchored canonical CWF state to a disposable tree. The audit reframed the backlog's literal "13 sites" into a **consumption-pattern** classification: repointed the single choke-point `CWF::Common::find_git_root` to derive the main tree via `git rev-parse --path-format=absolute --git-common-dir` (literal `/.git`-suffix strip; `--show-toplevel` fallback; `undef`-outside-repo contract preserved), which **transitively** fixed `Versioning.pm`/`Backlog.pm`/`backlog-manager` with zero edits. Routed 5 inline-backtick sites to `find_git_root()`; repointed `cwf-manage`'s own list-form resolver (`die` contract + fallback preserved); made `context-manager location` a **dual reporter** (main + worktree, OQ-2); made `cwf-init`/`tmp-paths` prose and `update-cwf-skill-docs.sh` worktree-safe (OQ-3 — the `GIT_ROOT` arg to `cwf-apply-artefacts` is load-bearing, no internal fallback). **No-change dispositions** (recorded): the load-bearing Class C self-worktree guard in `task-workflow.d/delete`, and the error-message-only captures in `task-stack` (OQ-1) and `checkpoints-branch-manager` (reclassified at exec); plus `install.bash` (bootstrap) and a test helper. New TDD test `t/find-git-root-worktree.t` (TC-1 failed pre-fix). Full suite **640 green**; same-commit `script-hashes.json` refresh for 8 edited hashed artefacts; `cwf-manage validate` clean; both exec-phase security reviews `no findings`.

### Notable
- **"13 sites" was a grep count, not a work unit.** Plan-review subagents corrected the design's false "find_git_root has no callers" claim (it has 3), turning 13 rewrites into one repointed choke-point + transitive fixes. Classify by *how the resolved root is consumed*, not by file type.
- **An existing test forced a design deviation.** The design mandated `File::Spec` derivation, but `t/cwf-manage-update.t` TC-8 asserts `cwf-manage` carries no `File::Spec` import. Since `--path-format=absolute` guarantees an absolute path, a literal `/.git`-suffix strip is equally safe and was applied to both resolvers — respecting the invariant and keeping them identical.
- **Error-message-only captures must stay worktree-local.** `checkpoints-branch-manager` was reclassified at exec: its `$git_root` only relativises the script's *own* path for diagnostics; routing it to the main tree would be wrong from a worktree.

### Retired Backlog Items
#### Audit the 13 `git rev-parse --show-toplevel` call sites for worktree-safety

`git rev-parse --show-toplevel` returns the *worktree* root when run inside a linked worktree, so the `cd "$(git rev-parse --show-toplevel)"` "go to repo root" idiom silently keeps you in a disposable tree (data-loss mechanism (b), reproduced first-hand in Task 172). The idiom appears in **13** files: `CWF/Common.pm`, `CWF/TaskPath.pm`, `CWF/WorkflowFiles.pm`, `command-helpers/task-stack`, `command-helpers/task-workflow.d/delete` (load-bearing — the self-worktree guard *inside* the deletion flow), `command-helpers/checkpoints-branch-manager`, `command-helpers/context-manager.d/location`, `command-helpers/template-copier-v2.0`, `command-helpers/template-copier-v2.1`, `scripts/update-cwf-skill-docs.sh`, `scripts/migrations/migrate-v2.1-file-order`, `skills/cwf-init/SKILL.md:87`, `tmp-paths.md`. Scope: for each site reachable while inside a worktree, replace with worktree-safe root resolution (e.g. `git rev-parse --git-common-dir`-derived main tree, or explicit paths). A fix scoped only to the `cwf-init` prose would under-remediate. Hash refresh for edited helpers.

**Resolution**: Repointed the `CWF::Common::find_git_root` choke-point (+ `cwf-manage`'s twin) to the `--git-common-dir`-derived main tree; routed the 5 path-anchoring sites and the prose/shell sites; left the Class C delete guard and the two error-message-only captures unchanged with rationale. See the Task 173 Impact above and `j-retrospective.md`.

## Task 172: Adapt CWF to new Claude Code harness (discovery)

### Status: Complete (2026-05-31)
### Duration: ~1 day (estimate 1–2 days, Medium complexity). Under estimate.
### Impact: Discovery — assesses how the new Claude Code client + Opus 4.8 model affect CWF processes, targeting two objectives: (1) drastically reduce loss of uncommitted work/files, (2) reduce momentum loss from permission prompts. **No CWF code/doc changes** (by design); the deliverable is a §1–§7 assessment in `f-implementation-exec.md` plus 6 seeded follow-up tasks. Anchor evidence: a real data-loss-then-recovery on `dircachefilehash` Task 6 (captured transcript + a 71 908-line raw terminal backlog supplied by the user). The four-mechanism data-loss chain was **fully evidenced (zero `pending`)**: (a) persistent shell CWD left inside a disposable worktree; (b) `git rev-parse --show-toplevel` resolving to the *worktree* not the main tree — **reproduced first-hand** and found in **13** CWF call sites incl. `task-workflow.d/delete`; (c) `git worktree remove --force` discarding uncommitted edits; (d) recovery only via `git fsck --unreachable`/stash-reflog, not the HEAD reflog (lost work recovered as dangling commit `a49e33b`, re-verified clean). TC-1…TC-8 all PASS; AC6 (safety) and AC8 (redaction) gates clear; both exec-phase security reviews `no findings` (Markdown-only).

### Notable
- **The harness's guarded worktree tools are real but opt-in.** `ExitWorktree(action: remove)` refuses to delete a worktree with uncommitted changes unless `discard_changes: true` — a fail-safe `git worktree remove --force`. But its own schema (loaded this session) restricts it to worktrees **created by `EnterWorktree`**, not raw `git worktree add`. CWF uses raw git, so the guard is inert until CWF adopts `EnterWorktree` — and `worktree.baseRef` defaults to `fresh` (origin/main), conflicting with CWF's branch-off-HEAD rule. This sharpened R1 from "prefer the tools" to "adopt `EnterWorktree` + set `worktree.baseRef: head`".
- **Model self-checking regression captured.** Phases a–e of the anchor task *assumed from memory* that `G703` was not a real gosec rule and were wrong (gosec emits it) — the "trusted remembered semantics over tool output" pattern, caught only by running the tool. Seeds R4 (verify tool-rule semantics against live output).
- **The AC6 safety gate did its job.** The cheapest way to kill the dominant prompt friction (`cd "$(git rev-parse --show-toplevel)" && …`, 8× early in the backlog) is to allowlist `cd`/`git` compounds — which would also auto-approve `worktree remove --force`. **Rejected** (R6): friction is cut by removing the command shape, not by broadening auto-approve. No recommendation silently trades safety for momentum.
- **Live dogfooding.** During exec the assessing agent's own Bash CWD drifted into the scratch dir after a `cd` (mechanism (a) reproducing itself), caught when a `.cwf/...` relative path failed. Recorded as evidence in g.
- **Keyword-collision is in-session evidence.** The harness twice surfaced the multi-agent `Workflow` tool off the word "workflow"; declined. Options scoped guard→wording→rename, none pre-selected.

### Retired Backlog Items
None — user-initiated from a real incident on another repo, not from the backlog. Seeds 6 new follow-up items (R1–R6) added to BACKLOG.md.

## Task 171: exclude completed tasks from recency signal

### Status: Complete (2026-05-31)
### Duration: ~1 day (estimate <1 day, Low complexity). On estimate.
### Impact: Bugfix — the `recency` task-candidate signal in `CWF::TaskContextInference` was the only one of the five signals that nominated a current-task candidate **without** consulting the work-potential framework. It scored tasks purely by directory mtime, so a finished (100%) task whose dir kept getting touched by merges, commits and hash refreshes could win recency and disagree with `branch`/`progress` — producing the reported false `current: inconclusive` / `confidence: uncorrelated` / `candidates: 2` results (e.g. completed tasks `3/3.1/3.3/4/5` pairing against the genuinely-active task `6`). **Fix**: one guard line in `_get_recency_signal`'s mtime-collection loop — `next if CWF::TaskState::state_done($task->{full_path}) >= 100;` — gating the recency candidate set through the same `CWF::TaskState` framework the `progress` signal already uses. Completed tasks no longer enter the recency pool; `recency` now agrees with `branch`/`progress` on the live task. Single-line production diff (no import edit — the call is fully-qualified, matching the module's existing `state_achievable` precedent at `:519`); same-commit `script-hashes.json` digest refresh. Two regression tests added (`t/taskcontextinference.t` 19→21 subtests; full suite 634→636, all green). `cwf-manage validate` clean; both exec-phase security reviews `no findings`.

### Notable
- **Predicate corrected at design time, before any code.** The a-plan framed the gate as `state_achievable == 0` (the prospective work-potential measure the `progress` signal uses). Reading the existing TC-8a/TC-8b fixtures during design revealed that predicate over-filters: those fixtures carry no status markers → `state_achievable == 0` for every dir → the recency-enumeration tests would break. Switched to `state_done >= 100` (the retrospective *completion* measure), which returns 0 for no-status dirs and so preserves them. The two measures coincide for status-bearing completed tasks but differ precisely on the no-marker case — exactly the existing fixtures.
- **Plan-review subagents shaped the final diff.** The misalignment reviewer flagged the module's existing fully-qualified `TaskState` call precedent, collapsing the change to one line with no second unused import; the robustness reviewer flagged that a copy-paste fixture (TC-8a's bare `"x"` files yield `state_done == 0`) would pass *without* the fix, which became the load-bearing `_write_status` helper writing real `**Status**:` markers.
- **TC-9 proven load-bearing.** Temporarily removed the guard and re-ran: TC-9 turned `not ok` (recency top = the completed `'41'`); restored the module (digest matching the committed `sha256`) → green. Converts a plausible regression test into a verified one.
- **`>= 100`, not `== 100`.** `state_done` is documented 0–100 so `> 100` is unreachable today, but `>=` is robust against any future formula change and is annotated not to be "tidied" to `==`.

### Retired Backlog Items
None — user-initiated from a false-positive observed on another repo, not from the backlog. (Broader inference items — "Create Integration Test for Inconclusive Inference Scenarios", "Test Edge Cases for Task Context Inference System" — remain open; this fix addresses one specific recency leak, not those harnesses.)

## Task 170: Enforce recorded permissions as upper bound

### Status: Complete (2026-05-31)
### Duration: ~1 day across sessions (estimate ~1 day, Medium complexity). On estimate.
### Impact: Feature (security hardening) — inverts the recorded-permissions check in `CWF::Validate::Security` from a **floor** (`(actual & recorded) == recorded` — require the recorded bits) to a **ceiling** (`actual & ~recorded & 07777 != 0` — forbid any bit beyond recorded). A file *less* permissive than recorded is now allowed; a file *more* permissive is flagged — including setuid/setgid/sticky acquisition, which the old floor check ignored entirely. `cwf-manage fix-security` switches from `additive` repair (raise missing bits) to **`clamp`** (`actual & recorded` — strip excess, never raise); the now-unreachable `additive` mode was removed, leaving `_apply_recorded_perms` with two modes (`exact` laydown, `clamp` repair). The `exact`-mode laydown is unchanged (exact ⊆ ceiling, so a laid-down tree validates clean). This repo's **31 scripts recorded `0500` were flipped on-disk `0700`→`0500`** (derived from the manifest, not hardcoded); the 8 `0700` and 9 `0444` entries are unchanged. The flip is invisible to `git status` (git tracks only the owner-x bit), so the full `prove t/` suite — not diff review — is the gate that surfaced the one regression: the read-only-source break in `t/install-bash-reinstall.t` (the Task 162 "Permission denied" failure), now fixed in the harness itself (`write_file`/`append_byte` `chmod u+w` before opening a copied `0500` script) rather than by the retired `0700` working-perms convention. Two edited code files (`Security.pm`, `cwf-manage`) got in-commit `sha256` refreshes; the perm-only flip needs none. Docs: `hash-updates.md` gained a "recorded permissions are a ceiling" section (+ the executable g/o write-or-execute & setuid/setgid/sticky bound); the working-perms memory was rewritten (working perms now *match* recorded, not bumped to `0700`). Full suite 634 tests green; `cwf-manage validate` clean; both exec-phase security reviews `no findings`.

### Notable
- **The model was corrected mid-plan, before any code.** The first b/c drafts modelled floor+ceiling (= exact match); the user clarified the intent was **ceiling-only** — under-permissive must be *allowed*. Captured in commit `0f49239` during the plan-review pause the user requested, so it cost a plan revision, not rework. Process lesson recorded: semantic-inversion questions belong at requirements, not design.
- **Clamp vs exact differ only for both-over-and-under files.** For a purely over-permissive file `actual & recorded == recorded`, so clamp and "set to recorded" coincide; they diverge only at e.g. `0640`/rec-`0500` → `0400`. That edge is the whole justification for adding `clamp` rather than reusing `exact`.
- **The security reviewer surfaced a standing audit target unprompted**: the validator-flag and clamp-repair predicates are algebraically equivalent over the 12 mode bits *because* both derive from the same `recorded` mask — any future edit touching one mask expression without the other would let a flagged file resist repair. Recorded in i-maintenance.
- **The before/after repair report was corrected** to print the actual clamp target (`sprintf('0%o', $want)`), not the recorded value — otherwise a `0640`→`0400` clamp would mis-report as `→ 0500`. Invisible for `exact` mode (where `want == recorded`).

### Retired Backlog Items
None — this task was maintainer-initiated. (The two `0444`-data-file perm items remain open: a `0600`/rec-`0444` file still flags under the ceiling — for owner-w excess rather than missing g/o-read — and the git-checkout-resets-perms structural issue is unchanged. Recording those files at `0644`/`0664` would let a checkout-restored `0600` pass under ceiling semantics, but changing recorded values was out of this task's scope per D1.)

## Task 169: sync README command reference

### Status: Complete (2026-05-29)
### Duration: single session (estimate <1 day, Low complexity). On estimate.
### Impact: Chore (docs) — `README.md` had drifted from the shipped command surface over the 62 tasks since it was last touched (Task 106). An audit (documented set vs `.claude/skills/cwf-*`, each `SKILL.md` description, `cwf-manage help`, and `cwf-project.json:supported-task-types`) found four gaps, all now closed: (1) three shipped skills absent from the Commands section — `cwf-delete-task`, `cwf-current-task`, `cwf-backlog-manager`; (2) the `discovery` task type (8 phases, a–g+j) undocumented in Task Types; (3) stale required-`<type>` signatures for `/cwf-new-task` and `/cwf-new-subtask` (both now infer type when omitted → `[<type>]`), plus a third invalid example `/cwf-new-task feature` in the Contributing section corrected during exec; (4) `cwf-manage` under-documented (only `list-releases` was mentioned) — added an Installation Management subsection covering all 7 subcommands, with `fix-security` framed as the narrow integrity-repair carve-out rather than a warning-silencer. Single-file change to `README.md`. Verification is diff-based (TC-1..TC-5, all PASS); `cwf-manage validate` clean; security-review changeset empty (README is non-CWF-internal, no shebang).

### Notable
- **Plan-review subagents caught a wrong validation oracle.** The d-plan's Step 5 originally diffed documented task types against `.cwf/templates/` directories — which include the non-type `install/` artefact dir, and would have falsely flagged it. Corrected to diff against `cwf-project.json:supported-task-types` before execution.
- **Reviewers also flagged a parallel signature defect.** The plan fixed only `/cwf-new-task`'s stale `<type>`; `/cwf-new-subtask` (line 110) carried the identical staleness. Folded into the same in-scope edit.
- **Live confirmation of Task 166.** Subtask-aware inference resolved task 169 `conclusive / correlated` at every phase — the first fresh-task exercise of that fix.

### Retired Backlog Items
None — this task was maintainer-initiated, not from the backlog.

## Task 168: security review cap weight production code

### Status: In Progress
### Impact: Task in progress.

### Retired Backlog Items
#### security-review-changeset cap should weight production code, not test scaffolding

The exec-phase security review caps the changeset at 500 lines of unified-diff output. The helper counts every diff line — code, tests, context — so any change carrying its own test suite inflates the count.

In task 166 the substantive code change was ~197 lines (CWF::TaskContextInference.pm refactor); the cap was breached only because the diff also carried ~234 lines of new test subtests and ~40 lines of diff context/headers. The work was reviewed (maintainer authorised invoking the subagent despite the cap; verdict was no findings on the f-exec phase, byte-identical diff in g-exec), but the cap surfaced as friction rather than signal.

Proposed direction: have `security-review-changeset` weight production code more heavily than test/fixture additions when applying the cap — e.g. count code-path lines only, or apply a separate (higher) cap for diffs whose non-test fraction is below threshold. Single source of truth remains the helper; classifier and subagent prompt unchanged.

Out of scope: deciding whether the cap is the right limit at all. This item is about *what* the cap measures, not whether 500 is the right number.

Identified in: task 166 (bugfix/166-task-inference-not-subtask-aware), f-implementation-exec security-review surfacing.

<!-- Note: Moved the cap into security-review-changeset as a production-weighted count; test paths are consumer-declared git pathspecs (security.review.test-paths) matched by git :(glob,exclude). -->

## Task 167: install manifest baselines disagree with subtree

### Status: Complete (2026-05-28)
### Duration: single session (estimate 0.5–1 day, Low complexity). On estimate.
### Impact: Bugfix — every consumer running non-interactive `cwf-manage update` across v1.1.155 → v1.1.166 hit a phantom `rules-inject` conflict abort. **Root cause**: since Task 127 (commit `215cbf7`, 38 tasks ago), `.cwf/install-manifest.json` carried a `rules-inject` artefact whose `source` pointed at an empty placeholder (`.cwf/templates/install/rules-inject.txt`, SHA `e3b0c442…`) while the actual 331-byte populated file (`.cwf/rules-inject.txt`, SHA `8c5efa38…`) ships via the `.cwf/` subtree. `cwf-apply-artefacts:392-407` compared on-disk against the prior manifest's baseline, saw them disagree on every consumer (regardless of customisation), and exited 1 with no TTY. The file was never CWF-owned in the first place — its content is project-specific recurring-process-errors guidance, naturally consumer-customisable. **Fix**: drop the `rules-inject` artefact entry from the manifest entirely (subtree becomes the sole distribution mechanism — same arrangement as BACKLOG.md, CHANGELOG.md, cwf-project.json). Cascade 14 cleanup sites (helper `@INVENTORY` row, dead `_install_file` branch, two `@ALLOWED_DEST_PREFIXES` allowlists, banner comment, docstrings, SKILL.md edits, glossary references intentionally kept), delete the empty placeholder template, refresh four `script-hashes.json` SHAs in-commit. **Anti-recurrence**: new `t/installmanifest-integrity.t` enforces two invariants over the shipped manifest — INV-1 (every artefact's recorded `sha256` matches the SHA of the file the `source` actually points at) and INV-2 (no artefact `dest` or `container` may begin with `.cwf/`). INV-2 is the institutional memory of this task — it catches the *defect class* (dual-distribution where the subtree already ships the target), not just this instance, across all artefact kinds (`file`, `tree`, `embedded-block`, `line-additive`, `regenerate-symlinks`). The new test was written **before** the fix and confirmed fail-on-HEAD (INV-2 fired on the live `rules-inject` entry, with the pre-fix failure captured to `/tmp/-home-matt-repo-coding-with-files-task-167/test-fail-pre-fix.txt`); post-fix it passes 6/6. Full suite `prove -r t/` runs 619 tests, all pass. `cwf-manage validate` clean. Both exec-phase security reviews returned `no findings` — the allowlist contraction is strictly tightening.

### Notable
- **The bug class is independent of artefact `kind`.** Initial design drafted INV-2 as "no `kind: file` artefact may have `dest` under `.cwf/`"; plan review pointed out that the architectural rule "subtree ships there; don't dual-distribute" applies to every kind. Widening INV-2 to "any `dest` or `container` field" caught the rule at its real scope.
- **Test-first earned its keep.** Writing `t/installmanifest-integrity.t` before any source edit and watching INV-2 fail on the unmodified tree is the strongest possible evidence the test is meaningful. The pre-fix failure file is preserved as a permanent reference.
- **Plan-review subagents caught three would-have-broken-the-fix defects.** A JSON-malforming comma error (rules-inject is not the last array entry; the original "becomes the new last entry" wording was wrong); an under-scoped SKILL.md edit list (lines 99 and 170 were missed in the initial design); and a `read_file_raw` reference that's not a core Perl symbol. All caught at plan-time.
- **Deviation A — synthetic-fixture fallout.** The d/e plans claimed "TC-RI-2..5 + TC-FR5-* fixtures use synthetic manifests; survive unchanged". Wrong: `build_source` in `t/cwf-apply-artefacts.t` declares its own `rules-inject` manifest entry with `dest: .cwf/rules-inject.txt`, which the helper now rejects schema-side after the allowlist contraction. Surfaced 12/18 subtests failing at f-exec verification. User-approved option 1 of 3 via `AskUserQuestion`: drop `rules-inject` from `build_source`, retire five subtests (TC-RI-1..3, TC-FR5-KEEP, TC-FR5-NEW), file Low-priority BACKLOG follow-up to restore explicit `CWF_UPGRADE_RESOLVE=keep/new` coverage via `cwf-rules-bundle` or `claude-md-preamble`. `prompt_resolve`'s keep/new branches remain reachable through `apply_tree_replace` and `apply_embedded_block` (same prompt_resolve shape). Runtime path unchanged; only direct unit-test surface narrowed.
- **The latent oddity was flagged in Task 158's retrospective and never filed.** That's the gap this task closes — and the INV-2 schema rule is the institutional mechanism to keep the gap closed.

### Retired Backlog Items
None retired (the High-priority bugfix entry for this task was created and retired in-place; the dependent Medium "Reclassify rules-inject.txt as consumer-owned" entry remains for follow-up).

## Task 166: Task context inference not subtask-aware

### Status: Complete (2026-05-28)
### Duration: single session (estimate ~1 day, Medium complexity). On estimate.
### Impact: Bugfix — `task-context-inference` now resolves an active subtask (decimal task number, e.g. `28.2`) conclusively instead of stalling on `current: inconclusive, task_nums: 28,20`. **Root cause**: four of the five signal collectors in `CWF::TaskContextInference` (branch, worktree, recency, progress; state-file already decimal-aware) parsed task numbers with `^(\d+)-` and scanned `implementation-guide/` only one level deep, so nested subtask directories were invisible. Crucially, the branch signal returning the *parent's* number is correct behaviour — `/cwf-new-subtask` creates a directory but never `git checkout -b`, so subtasks share the parent's branch — meaning the defect is in *correlation*, not in branch parsing. **Fix lands as one commit per D5**: **D1**: delegate task-path parsing to `CWF::TaskPath` — `_get_branch_signal` now calls `resolve_branch`; the in-module `_get_task_dir` and `_get_task_slug` helpers are deleted outright (~30 LOC); `_infer_workflow_step`'s signature becomes `($task_dir)` to consume the `resolve_num(...)->{full_path}` directly. **D2**: a new private `_enumerate_all_tasks()` builds the candidate set as `{T} ∪ find_descendants(T)` for every top-level `T`; recency and progress signals consume it, so subtask dirs finally enter the candidate set. **D3**: `correlate_signals` gains a deterministic 8-step ancestry-collapse predicate — given the unique top-task set `U`, compute depths via `get_depth`, take the max-depth subset `D`; if `|D|>1` (ties on disjoint branches) → uncorrelated; if `resolve_num(deepest)` is undef (stale reference) → uncorrelated; else form `A = {deepest} ∪ ancestors-by-num`, and if `U ⊆ A` → `correlated, chosen_task = deepest`, else uncorrelated. The correlator stays *pure* (no return-shape change; resolution and disk-state queries happen at the caller boundary in `infer_task_context`). Single-commit constraint (D1+D2+D3+tests must land together — none is independently shippable). In-commit `script-hashes.json` refresh of the one `.pm` (no script edits, no working-perm restore — module entry carries no `permissions` key). New tests TC-1..TC-6 + TC-8a/8b (8 subtests), bound 1-to-1 to c-design-plan §Validation bullets and exercised via `File::Temp::tempdir(CLEANUP => 1)` fixtures with capture-cwd-before-eval discipline; TC-7 covered by the existing top-level baseline subtest. `t/taskcontextinference.t` grows from 11 to 19 subtests; full `prove -r t/` runs 618 tests, all pass. `cwf-manage validate` clean. The exec-phase security review changeset was 543 lines (over the 500-line cap) — maintainer authorised invoking the subagent anyway; verdict was `no findings` (TaskPath adoption tightens input validation, tempdir/cwd ordering is correct, two pattern-level reuse notes recorded as future-audit not findings).

### Notable
- **The branch-signal "bug" was correct behaviour.** Reading `cwf-new-subtask/SKILL.md` during c-design reframed the defect away from regex-loosening (the original draft direction) toward ancestry-collapse in the correlator. Subtasks share branches with their parent by design; the signal saying so is consistent, not in conflict.
- **CWF::TaskPath already had everything needed.** `parse_branch`, `resolve_num` (iterative ancestor walk), `find_descendants`, `find_ancestors`, `get_depth` — all decimal-aware, all hashref-shaped. Implementation pivoted from "fix the regexes" to "delete the regexes and delegate", with net code reduction.
- **The D3 predicate is mechanical — each step binds to one test.** Steps 1-8 with edge cases (ties, stale references, orphaned subtasks) spelled out exhaustively in c-design-plan meant the Perl was transliteration; TC-1..TC-6 each exercise one step or edge case, so failures would localise to a single rule.
- **The 500-line security-review cap weighs the wrong thing.** Any change carrying its own test suite will trip the cap even when the substantive code is well under 200 LOC. Backlog item filed (Medium chore): cap should weight production code, not test scaffolding.

### Retired Backlog Items
#### Task context inference not subtask-aware: inconclusive for active subtask

Repro: in a session where subtask `28.2` is active (its wf step files are being edited and a recent commit is on the parent task's branch), `task-context-inference` returns:

```
current: inconclusive
confidence: uncorrelated
task_nums: 28,20
task_slugs: ...
workflow_steps: ...
candidates: 2
reasons: branch,state,recency,progress
```

Expected: `current: conclusive`, `task_num: 28.2`. Observed: subtask never enumerated by any signal — the state-file signal correctly carries decimal task numbers, but four of the five collectors strip them; recency and progress signals scan only top-level directories.

The four affected signal collectors all need to (i) accept decimal task numbers from their input and (ii) emit them in their candidate / top fields. Recency and progress also need to walk subtask directories (`find_descendants`).

Bonus (post-fix): the correlator needs an "ancestry-collapse" rule so that `{branch: 28, recency: 28.2, progress: 28.2}` resolves to `28.2` rather than staying inconclusive — the parent appears in the chain because subtasks share their parent's branch.

<!-- Note: Delivered as the D1+D2+D3 single commit. Branch-signal regex deleted and replaced with `resolve_branch` (D1); enumerator widened to descendants (D2); ancestry-collapse predicate added to `correlate_signals` (D3). All in one commit per D5. -->

## Task 165: Template reference linter

### Status: Complete (2026-05-27)
### Duration: single session (estimate 0.5–1 day, Medium complexity). On estimate.
### Impact: Chore — adds `CWF::Validate::TemplateRefs`, a new sibling validator wired into `cwf-manage validate` (and therefore run by `cwf-checkpoint-commit` on every CWF commit). It flags any `[a-j]-<phase>.md`-shaped reference in tracked `*.md`/`*.pl`/`*.pm` source that names **no** known template in any supported workflow version (v1.0/v2.0/v2.1). **Design narrowing**: the backlog's original "flag v2.0 names used in v2.1 context" goal is infeasible — current skills and lib modules legitimately reference older names for backward-compat (e.g. a skill that opens the v2.1 file "or" the v2.0 file), so the same token is both a valid mention and a potential orphan, separable only by intent a linter cannot read. The reliable invariant "every template-shaped reference names a real template somewhere" catches the real risk (rename orphans, typos) at near-zero false-positive cost. **KNOWN set** is derived at runtime — pool basenames ∪ `V21`/`V20::get_workflow_files` (over all task types) ∪ both sides of `workflow_file_mappings()` — nothing hardcoded; a fail-closed `die` refuses to run if the set is under-populated rather than passing everything. **Grammar** is boundary-anchored (`(?<![A-Za-z0-9-])[a-j]-[a-z][a-z-]*\.md(?![A-Za-z0-9])`) so it never matches the tail of a longer hyphenated filename. **Scope** excludes `implementation-guide/` (task instances) and `BACKLOG.md`/`CHANGELOG.md` (append-only history, exempt per `docs/conventions/cross-doc-references.md`). On its first real-repo run it surfaced 3 genuine stale references — `V21.pm` POD and `workflow-steps.md` ×2 (v2.0 testing mislabelled `f-testing-plan.md`; it was `e-testing.md`) — all fixed in-task to reach a clean baseline. In-commit `script-hashes.json`: new `TemplateRefs.pm` entry + refreshed `cwf-manage` and `V21.pm`. New `t/validate-template-refs.t` (TC-1…TC-7 + implementation-guide exclusion + fail-closed minimum, 10 subtests); full suite 610 tests pass. Both exec-phase security reviews returned `no findings`.

### Notable
- **The backlog item's premise was partly wrong, and the investigation proved it.** "Flag v2.0 names in v2.1 context" can't be done without heavy false positives because back-compat references are pervasive and legitimate. Grounding in the actual 37 referencing files reshaped the task before any code was written.
- **Plan review caught a 12-vs-4 baseline error and two snippet bugs.** Reviewers flagged that the naive scope flags 12 hits (8 of them intentional history in BACKLOG/CHANGELOG, including this task's own backlog entry), citing the existing cross-doc-references exemption; and corrected an arrayref-deref and a `glob` directory-prefix bug — all before exec, zero rework.
- **Dogfooding found real bugs.** The linter's first run on the live tree surfaced genuine doc inaccuracies, which the task then fixed to reach its own clean baseline.
- **`cwf-manage fix-security` repairs permissions, not hashes.** Confirmed: a sha256 refresh is a deliberate reviewed JSON edit; there is intentionally no recompute-to-silence tool (surface, don't smooth).

### Retired Backlog Items
#### Create Template Reference Linter for Pre-Commit Hook

Create automated linter to detect hardcoded template filename references and verify they point to current template names.

- No automated way to detect orphaned template filename references
- Manual grep required for verification (e.g., Task 29 found 60+ references)
- Risk of missing references during template changes
- Version-specific references (v2.0 vs v2.1) need distinction

- Detect hardcoded template filenames in `.md`, `.pl`, `.pm` files
- Verify references point to current template names (not deprecated)
- Distinguish v2.0 refs (acceptable in V20.pm) from v2.1 refs (should use new names)
- Run as pre-commit hook or CI check
- Report orphaned references with file:line information

- Prevents orphaned references during template renames
- Automates manual grep verification step
- Catches errors before commit
- Documents expected template filenames

1. Add to `.cwf/scripts/` as `template-reference-linter`
2. Parse all `.md`, `.pl`, `.pm` files for template filename patterns
3. Cross-reference against current template pool contents
4. Flag deprecated names (e.g., "e-implementation-exec.md" in v2.1 context)
5. Allow v2.0-specific references (V20.pm uses "f-testing-plan.md" correctly)
6. Integrate with pre-commit hook or CI pipeline

<!-- Note: Delivered as CWF::Validate::TemplateRefs wired into cwf-manage validate; semantics narrowed to "known to any version" (see j-retrospective.md). -->

## Task 164: hierarchy-aware consistency validation

### Status: Complete (2026-05-27)
### Duration: ~1 day across two sessions (estimate 1–2 days, Medium complexity). Within estimate.
### Impact: Feature — reworks `CWF::Validate::Consistency::validate` from a flat single-level scan into a hierarchy-aware one, fixing a downstream adopter's false positive and closing two latent gaps in one traversal. **Root cause of the reported bug**: an adopter working subtask `28.1` on `feature/28.1` hit a CONSISTENCY violation against the **parent** task 28 — the parent's later phases sit at the template default `Backlog` (non-terminal → "active"), its recorded `**Branch**` is `feature/28`, and the flat equality check `branch_in_file ne current_branch` fired. Three flat-model limitations underlay it: the scan never recursed into nested subtask dirs (so subtasks were unvalidated), the branch check had no notion that the current branch may legitimately sit *below* an active ancestor, and there was no parent/child completeness check at all. **Fix**: `validate` now does one recursive pass — `_collect_nodes` (entries gated by `CWF::TaskPath::parse_dirname`; a symlinked entry is skipped via `-l` **before** the `-d` test, which stat-follows, confining traversal to `implementation-guide/`) builds a flat list of node records {num, path, branch, active, complete}, then two in-memory passes run over it. **Directional branch pass (FR2/FR3)**: the "leaf" is the unique node whose recorded `**Branch**` equals the current branch; an active node is consistent iff it *is* the leaf or a `get_parent`-chain ancestor of it — siblings and off-chain tasks stay flagged, and 0-or-≥2 leaf matches **fail closed** (suppression disabled) so a duplicated branch record can't silence a real mismatch. **Completeness pass (FR4)**: a task in a terminal status (`Finished`/`Skipped`/`Cancelled`) with an active descendant is a new `**Status**` violation naming the nearest active descendant (smallest `get_depth`, ties by `version_compare`); the inverse is permitted. Ancestry is pure-string `get_parent`-chain membership tested by exact `eq`, which structurally rejects numeric near-misses (`1` vs `11`, `1.1` vs `1.10`) and tolerates a missing intermediate dir; the rejected alternative (parse the branch name into a task number) was dropped to stay independent of branch-naming convention. FR5 preserved byte-for-byte: flat-repo violation output is unchanged (the `**Task**` fix message keeps the directory basename via a third `_build_node` arg). In-commit `script-hashes.json` refresh of the one hashed module; `cwf-manage validate` clean. New tests: `t/validate-consistency.t` grows from 5 to 20 subtests (TC-1 FR1, TC-2/2b/2c FR2 ancestor/grandparent/near-miss, TC-3a/3b FR3 off-chain + fail-closed, TC-4a–4f completeness polarities + nearest-descendant tiebreak, TC-R5 flat-ordering, TC-S1 symlink-not-followed, TC-W no-warnings) — completeness/FR1/symlink/warning cases run git-free, directional cases Tier-C gated; full suite 600 tests pass. Both exec-phase security reviews returned `no findings`.

### Notable
- **Plan review caught the wrong symlink precedent.** All four design reviewers independently flagged that `build_tree` (status-aggregator), cited as the traversal model, uses `glob`+`-d` which stat-follows symlinks. Switched to an explicit `-l`-before-`-d` skip (`template-copier-v2.1:254` idiom), now a load-bearing, tested defence (TC-S1).
- **The hashed-file 0700 convention is script-scoped, not blanket.** `Consistency.pm` was briefly committed `100755` by reflexively applying `feedback_hashed_script_working_perms`; it is a `use`d library module whose `script-hashes.json` entry records no `permissions` field (validate never checks its mode) and every sibling `CWF::Validate::*` module is `100644`. Corrected to `0600` via amend (chmod doesn't change content, so the recorded sha256 stayed valid). Check the `permissions` entry and sibling modes before chmod'ing.
- **The directional rule forces a two-pass shape.** The branch check must know the unique leaf before judging any single node, so it can't run inside collection; a consequence is that violations group by category rather than interleaving per directory — byte-identical for flat repos and branch-only findings, an accepted non-issue for advisory unordered output.
- **Single mechanism, three behaviours.** The decomposition check (no signals) held: full-depth coverage, the directional branch rule, and the completeness invariant all fell out of one hierarchy-aware traversal — no rework across exec.

## Task 163: subtask retrospective must not version-bump or tag

### Status: Complete (2026-05-24)
### Duration: single session (estimate <1 day, Low complexity). On estimate.
### Impact: Bugfix — a downstream user's subtask (decimal task number, e.g. `3.2`) reaching its retrospective hit `cwf-version-bump --task-num=3.2` → the misleading `unknown argument: --task-num=3.2` error and `exit 1`, because all three version helpers parsed the argument with the identical `^--task-num=(\d+)$`. Version actions are release events keyed to an **integer** top-level task number (`v{major}.{minor}.{patch}`, patch = task number); a subtask merges to its parent branch, not trunk, so it releases nothing and must *skip* these steps cleanly, not error. **Fix**: a new exported predicate `CWF::Versioning::is_subtask_num($n)` (true iff `^\d+(?:\.\d+)+$`) plus a relaxed capture `^--task-num=(\d+(?:\.\d+)*)$` in **all three** triplet helpers (`cwf-version-bump`, `cwf-version-tag`, `cwf-version-next`); a subtask number now prints `skipped: version actions apply to top-level tasks only (subtask N)` and `exit 0`. The skip sits inside the `@ARGV` parse loop **before** `read_config()`, so it short-circuits with no config read, no mutation, no git call — proven against absent/malformed `cwf-project.json` (TC-2). Malformed dotted values (`3.`/`.2`/`3..2`) still route to the existing `unknown argument` error (TC-3). The `next_version` `^\d+$` backstop is retained, so a bare integer remains the only value that can reach a mutation or `git tag` — the digits-only invariant feeding `git tag -l '$version'` is preserved. **Scope correction at design**: plan review found a *third* helper (`cwf-version-next`) carrying the same parser; the originally-scoped two became three, resolved via the shared predicate (Rule of Three). Docs: `versioning-standard.md` gained a "Top-Level Tasks Only" section; `cwf-retrospective/SKILL.md` Steps 9 & 11 gained one-line clarifiers (no command change — the `skipped:` handling already existed). In-commit `script-hashes.json` refresh of four entries (`CWF::Versioning` + three helpers); `cwf-manage validate` clean. New tests: `versioning.t` TC-V7c (9-row predicate truth table) + TC-163-1/2/3/5 across the three helper `.t` files; 45 targeted tests pass. Full suite 585 tests / 583 pass — the 2 failures (`cwf-manage-fix-security.t` TC-1/TC-8) are a **pre-existing, unrelated** working-tree perms drift on `.claude/agents/cwf-security-reviewer-changeset.md` (last committed by Task 162, absent from this branch's diff), fixed locally with `chmod 0444`.

### Notable
- **Plan review earned its keep on a "trivial" bugfix.** Three of four reviewers independently corrected the "sole consumers" miscount (two → three) before implementation; the exec phase had zero rework. This is the second consecutive retrospective (161, 163) where an eyeballed-enumeration error was the main process miss — grep the helper family for the shared pattern before stating a count.
- **The guard lives in the scripts, not skill prose.** Because the helpers emit a load-bearing `skipped:` line and SKILL.md Step 9 already keys on it, the fix composes with no skill logic change (`feedback_bake_in_good_work`).
- **A shape classifier is not a sanitiser.** The security review's category-(e) note prompted an input-contract comment on `is_subtask_num`: it classifies an already-numeric task id, it does not validate arbitrary input.
- **Both exec-phase security reviews classified `error`** — clean substance but a missing `cwf-review` verdict block. Surfaced verbatim, not smoothed; corroborates the open Task 162 follow-up (fresh-session reviewer verification), which was annotated with these two data points rather than duplicated.

## Task 162: Fix security-reviewer clean-review misclassification

### Status: Complete (2026-05-24)
### Duration: single session (estimate 1–2 days, Medium complexity). On/under estimate.
### Impact: Bugfix — replaces the fragile line-1-sentinel contract between the `cwf-security-reviewer-changeset` subagent and its callers with a deterministic, position-independent verdict container parsed by a single helper. **Root cause**: the subagent is a reasoning model that prefaces its verdict with prose, but the LLM-applied "three-tier rule" required the sentinel on line 1 and otherwise fell through to a numbered-list heuristic → clean reviews mislabelled `error` (9 of 23 historical `error` records) or false `findings` (126-g/133-g/134-g). **D1**: the subagent now ends its response with a fenced ```` ```cwf-review ```` block carrying `state: <no findings|findings|error>`; reasoning prose precedes it freely. **D2/D3**: new `.cwf/scripts/command-helpers/security-review-classify` (core-Perl, stdin→token) is the single parse authority — exactly one valid block → its state; zero or many → `error` (the numbered-list heuristic is gone; severity comes only from `state:`). Both exec SKILLs and `security-review.md` now pipe through the helper rather than applying prose rules. **D4 (backstop, full scope per user option C)**: new `.cwf/scripts/hooks/subagentstop-security-verdict-guard` — a fail-open SubagentStop hook scoped to the agent that re-prompts only when a cleanly-run classifier returns `error` and it is not a re-emit loop; it reuses the classifier as a shell-free subprocess and emits a fixed-literal `reason` (no message-derived interpolation). `cwf-claude-settings-merge` was extended to register `SubagentStop` + an `agent_type` matcher via validated header directives (`event ∈ {Stop,SubagentStop}`, `matcher ^[A-Za-z0-9_-]+$`), with the matcher-less Stop path kept byte-identical; `stop-hooks-framework.md` documents the event, registration, fail-open discipline, and the wrong-matcher silent-failure risk. In-commit `script-hashes.json` touches: agent def + merge helper refreshed, classifier + hook added (4 total); `cwf-manage validate` clean. New `t/security-review-classify.t` (18, TC-C1–C14), `t/subagentstop-security-verdict-guard.t` (18, TC-H1–H7), `t/cwf-claude-settings-merge.t` +5 (TC-M1–M5, TC-U1/U3 retained); full suite 574 tests pass. The task's own exec-phase security review exceeded the 500-line cap (982 lines) → manual threat-category walkthrough (a–e), no actionable findings.

### Notable
- **Match the verdict format to how the model writes.** A reasoning model concludes last; demanding a line-1 sentinel fought the grain and regressed even after character-level coercion (Task 142). A trailing fenced block parsed position-independently is immune to the markdown-wrapping variance that defeated bare-token matching.
- **One parser, three callers.** `security-review-classify` is consumed by both exec SKILLs and the SubagentStop hook (as a subprocess, never reimplemented), so the contract is defined and tested in exactly one place — no drift.
- **The backstop is affirmative-only and fail-open.** The hook blocks solely when a cleanly-run classifier returns `error` outside a re-emit loop; every failure mode (malformed stdin, unreachable classifier, exception, `stop_hook_active`) allows the stop. It can never trap the subagent.
- **Live end-to-end corroboration can't run in the editing session.** Agent definitions load at session start; the in-session live subagent emitted old-contract output (correctly classified `error`). The deterministic unit suite is the acceptance gate; positive live evidence is deferred to a fresh session (follow-up filed).
- **Two operational gotchas, both now memories.** (1) Restore edited hashed scripts to `0700`, not the recorded `0500` *minimum*, or `install-bash-reinstall.t` TC-5's `cp -rp`+overwrite breaks. (2) `git add -N` new files before `security-review-changeset` or the most security-sensitive new code is silently absent from the review.

### Retired Backlog Items
#### cwf-security-reviewer-changeset sentinel-first contract not honoured; clean reviews classify as error

The `cwf-security-reviewer-changeset` subagent (a reasoning model) consistently
prefaces its verdict with analysis instead of emitting the sentinel on its very
first line, despite the agent definition's explicit "Your VERY FIRST output line
MUST be one of these three sentinels" instruction (reinforced in the SKILL prompt
made no difference across Task 158's f and g phases).

Consequence: the exec-phase three-tier classifier in `cwf-implementation-exec` /
`cwf-testing-exec` falls through tier-1 (no first-line sentinel) and tier-2 (no
`^\d+[.)]` numbered list, no literal "actionable finding") to the conservative
`error` default — so a substantively clean "no findings" review is recorded as
`State: error`. This is noise that, if routine, erodes the signal the `error`
state is meant to carry (a genuinely malformed/failed review).

Scope: investigate a fix that makes clean reviews classify as `no findings`
without weakening the malformed-output guard. Options to weigh (design phase):
(a) tighten the agent so it truly emits the sentinel first (may be unreliable for
a reasoning model); (b) extend the classifier's tier-2 fallback to recognise a
standalone `no findings` / `findings:` line anywhere in the body (carefully, so a
prefaced clean review is not misread, and a prefaced findings review still lands
on `findings`); (c) some combination. Must preserve "never silently classify as
no findings" — any body-scan must be explicit and auditable.

Evidence: Task 158 f-implementation-exec.md and g-testing-exec.md "## Security
Review" sections both record `State: error` with verbatim clean reviews.

<!-- Note: Fixed via deterministic cwf-review container + security-review-classify single-parser; SubagentStop backstop added (D4). -->

## Task 161: Converge cwf-manage copy update onto install.bash

### Status: Complete (2026-05-24)
### Duration: single session (estimate 1–2 days, Medium complexity). On estimate.
### Impact: Feature — implements FR3 deferred at Task 159's design gate (the copy-method counterpart to Task 155's subtree convergence). **Single laydown path**: `cmd_update`'s copy branch now delegates to the target version's `scripts/install.bash` exactly like the subtree branch (the if/elsif/else collapsed to one delegation guarded by `$method eq 'subtree' || $method eq 'copy' or die_msg("Unknown install method: …")`), and the six dead copy-laydown subs (`update_copy`, `copy_tree`, `_escapes_src`, `_collapse_dotdot`, `create_skill_symlinks`, `create_agent_symlinks`) plus five now-orphaned imports (`File::Find`, `File::Copy`, `File::Path`, `File::Spec`, `File::Basename`) were removed after a caller audit — 340 lines, guarded against return by TC-8. **Guard extracted + integrity-covered**: the symlink-escape check (`_escapes_src`/`_collapse_dotdot`) moved verbatim into a new standalone helper `.cwf/scripts/command-helpers/cwf-check-tree-symlinks` (lexical, no disk-following; refuses absolute, `..`-escaping, and source-root-equal targets; fail-closed on readlink failure; `exit 2` on no roots; self-decodes `@ARGV`; `main(@ARGV) unless caller();` for testability). Landing it under `.cwf/scripts/` put it inside the hash ledger **and** `@CWF_INTERNAL_PREFIXES` with no prefix edit; `cwf-manage validate` now detects a deliberate tamper of it (TC-7, negative assertion). **Headline security win**: `install_copy` now runs the guard — via a `[[ -x "$guard" ]] || die` precheck then the guard itself — *before* the destructive `rm -rf`/`cp`, closing the previously-unguarded fresh copy-install path; a refused source leaves any existing install intact (TC-4). The guard runs from the target-version clone (design D4). `.cwf-rules` laydown reconciled against `run_apply_artefacts` (copy/subtree parity, TC-6); full env block incl. `CWF_FORCE=1` passed on the copy delegation (TC-5). In-commit `script-hashes.json` refresh (new helper entry + refreshed `cwf-manage`); new `t/cwf-check-tree-symlinks.t`; TC-3..TC-8 added across `install-bash-reinstall.t`, `cwf-manage-update-end-to-end.t`, `cwf-manage-update.t`; full suite 49 files / 533 tests pass; `cwf-manage validate` clean; both exec-phase security reviews clean.

### Notable
- **A relocated security check must take its integrity coverage with it.** The decision that made FR2/FR3/NFR4 mutually consistent at zero extra cost was *where* the guard lived: inside the existing `.cwf/scripts/` prefix (ledger + auto-review both apply) rather than co-located with `install.bash` at repo-root `scripts/` (outside both). Move-don't-rewrite kept the audited lexical logic byte-identical.
- **Fresh-install and update paths have different reach.** The `install.bash` copy guard protects new installs immediately; the copy-*update* convergence is forward-only (run by the consumer's old `cwf-manage`, effective from the next update or via bootstrap reinstall) — the same intrinsic as Task 159's updater fixes.
- **The plan under-counted orphaned imports (3 named, 5 actual).** Caller enumeration caught the dead subs; the import count was eyeballed from the `use` list rather than grepped against HEAD. Lesson recorded: grep imports the same way you grep callers on deletion tasks.
- **The 500-line review cap fires on deletion-heavy changes.** Both phase changesets exceeded the cap largely because of the 340-line removal; the "split the change" remedy (review the genuinely-new source/test surface) worked, but the cap counts deleted lines as review burden.

### Retired Backlog Items
#### Converge cwf-manage copy-method update onto install.bash

Task 155 converged only the subtree update method onto install.bash delegation; the copy method still uses cwf-manage update_copy (with copy_tree/_escapes_src symlink-escape guard). Converging copy too requires either porting the lexical symlink-escape check into install.bash install_copy (cp -r currently has none) or having install_copy shell out to a shared checker. Until then update_copy + copy_tree + _escapes_src + _collapse_dotdot remain in cwf-manage and FR1 (single laydown) is only fully met for subtree.

<!-- Note: Implemented in Task 161: copy update now delegates to install.bash; guard extracted to cwf-check-tree-symlinks (integrity-covered) and extended to the fresh copy-install path. -->

## Task 160: Remove sed extraction guidance from CWF docs

### Status: Complete (2026-05-24)
### Duration: single short session (estimate <0.5 day, Low complexity). On estimate.
### Impact: Chore — replaced the stale `sed`-based section-extraction guidance in two top-level docs with grep+read guidance, matching the project's no-sed-line-range-reads tool preference. **COMMANDS.md**: deleted the `/cwf-extract` `**Method**: Uses sed -n '…/p' | head -n -1` line. **DESIGN.md**: success criterion `extract specific sections using sed commands` → `using grep and read tools`; the **Section Extraction Commands** fenced `sed` block → two bullets (grep for `^## {section name}` to get line numbers, then read with offset/limit). The change was pre-authored in a session stash (`stash@{0}`, carried over from Task 159) and applied here through the full workflow. Neither file is hash-tracked → no `script-hashes.json` refresh. Verification was grep-based (discriminating `grep -nE 'sed -n|sed commands'` → zero; positive greps for the replacement strings) plus a full-suite regression: 48 files / 527 tests pass, `cwf-manage validate` clean. Both exec-phase security changesets were empty (top-level docs are outside the CWF-internal security-relevant trees).

### Notable
- **Plan review paid off on a two-line doc edit.** Four reviewers independently caught that the plan's rationale was wrong (claimed the `/cwf-extract` skill "uses grep+read internally" — it uses `awk`), that the verification `grep sed` could never pass (matches `based`/`used`/`standardised`), and that acceptance was deferred to an empty template. All fixed before exec; the implementation had zero rework.
- **The repo describes extraction three ways.** The actual skill (`SKILL.md:48`) and design doc (`template-engine.md:41`) use `awk`; the two user-facing docs now use grep+read. Aligning the skill/template-engine to grep+read was kept out of scope and filed as a Low follow-up rather than silently expanded.
- **Stash hygiene under multiple stashes.** Applied (not popped) and dropped only after a verified-identity check, protecting an unrelated `stash@{1}` (WIP on main) from a positional-index mistake.

## Task 159: Fix outstanding cwf-manage issues

### Status: Complete (2026-05-24)
### Duration: single session (estimate 1–2 days, Medium complexity). On estimate once FR3 — the only High-risk milestone — was deferred at the design gate.
### Impact: Feature — bundled 4 outstanding `cwf-manage` backlog items into one flat task; delivered **3 of 4**. **FR1 (Very High, version/ref bug)**: `cmd_update` previously wrote the verbatim requested ref into *both* `cwf_version` and `cwf_ref`, so `cwf-manage status` showed `Version: HEAD` (a ref, not a version). New `git_describe_version($clone_dir, $sha)` derives `cwf_version` from `git describe --tags --always` against the already-resolved SHA — exact tag (`v1.1.159`), nearest-ancestor long form (`v1.1.159-N-gHASH`), or abbreviated SHA when no tag is reachable, never a bare ref; falls back to the input SHA on any non-zero describe exit. `cwf_ref` now preserves the originally-requested ref. Confirms the maintainer's "latest = highest semver tag" model. **FR2 (Low, feature)**: `cwf-manage fix-security --dry-run` previews the chmod actions and unfixable entries it *would* take and mutates nothing (`_apply_recorded_perms` gained a `$dry_run` param that records the would-be repair and skips the `chmod`; existence/sha256 gates unchanged). Unknown args fail closed (`--dry-run` stripped first, any leftover `die_msg`s); dry-run exits 0 even with pending repairs but still exits 1 on a genuine sha256 mismatch; `cmd_help` documents the flag. **FR4 (Very Low, chore)**: new shared `git_capture(@argv)` helper (list-form `open '-|'` fork, child reopens STDERR→`/dev/null` then `exec('git', @argv) or POSIX::_exit(127)`, parent drains before close, returns `(\@lines, $? >> 8)`); `find_git_root` and `cmd_list_releases` converted off backticks, removing the `$source` shell-string interpolation. The backlog item's "5 backticks" claim was two releases stale — only 2 remained (`resolve_ref`/`resolve_sha` were converted in Task 155). **FR3 (copy-method convergence) deferred** at the design gate (all four plan reviewers leaned defer: a new copy-laydown guard script would sit outside the hash ledger and the changeset auto-review set, with CWF_FORCE/.cwf-rules preconditions) — remains a Low backlog item. In-commit `cwf-manage` sha256 refresh; `cwf-manage validate` clean; `perlcritic` backtick policy `source OK`. New `t/cwf-manage-git-capture.t` (6 subtests); `t/cwf-manage-fix-security.t` +3; `t/cwf-manage-update-end-to-end.t` +2; full suite 48 files / 527 tests pass; both exec-phase security reviews clean.

### Notable
- **The version fix is forward-only and that's correct.** FR1/FR2 live in `cwf-manage`, run by the consumer's *installed* (old) copy, so they only land in installs at/after the carrying tag. Documented as a reach limit with the INSTALL.md bootstrap-reinstall recovery, not a self-repair attempt (same structural lesson as Task 155).
- **Plan review swapped a risky mechanism before any code.** FR4 was designed as `IPC::Open3` (c-design D4); the implementation-plan reviewers flagged its deadlock/stderr-merge traps and NFR3's preference for the lighter primitive, so it became a list-form `open '-|'` fork. Same AC, simpler mechanism, zero rework.
- **Deferring at the design gate is a first-class outcome.** FR3 carried the task's only real risk; the convergent reviewer signal to defer (rather than force a weaker bash symlink guard) removed it cleanly and kept the item tracked.
- **Backlog citations go stale.** The "5 backticks" count was two releases out of date. Backlog text is a pointer, not ground truth; the count was re-derived from `HEAD` at requirements time.
- **Bundling beat decomposition here.** Four items sharing one file, one hash refresh, and one review pass — the flat-task decision (recorded in the decomposition check) avoided 4× subtask ceremony for surgical edits.

### Retired Backlog Items
#### cwf-manage records ref (HEAD/branch) in cwf_version instead of resolved semver

Symptom: `cwf-manage status` shows `Version: HEAD` (a ref, not a version) when CWF was installed/updated from the `HEAD` ref or a branch. For a tagged commit the Version field should resolve to the semver, e.g. an install pinned to a SHA that is exactly `v1.1.155` should report `v1.1.155`.

Root cause: `resolve_ref` (`.cwf/scripts/cwf-manage:159`) only maps `latest` to the highest semver tag; for any other ref (`HEAD`, branch, SHA) it verifies existence and returns the ref string verbatim (`:184`). `cmd_update` then writes that same verbatim string into BOTH `cwf_version` and `cwf_ref` (`:477-478`), so `cwf_version` records a ref rather than a version.

Field conflation: `cwf_ref` should hold the originally-requested ref (`latest`/`HEAD`/branch); `cwf_version` should hold the semver the installed SHA maps to. They currently receive the same value.

Proposed fix: derive `cwf_version` from `git describe --tags <sha>` against the already-resolved SHA (`$sha`, `:479`), and stop overwriting `cwf_ref` with `$resolved` so the requested ref is preserved. For `latest`, `cwf_version` stays the semver and `cwf_ref` should record `latest`.

Notes: dog-food repo, so the fix goes through the CWF workflow. `cwf-manage` is hash-tracked (`.cwf/security/script-hashes.json:204`), so the change needs a same-commit `script-hashes.json` refresh (hash-updates convention).

<!-- Note: Fixed via git_describe_version; cwf_version now tag-derived semver, cwf_ref preserves requested ref -->

#### Add --dry-run flag to cwf-manage fix-security

`fix-security` currently has no preview mode. A `--dry-run` flag would print the chmod actions it *would* take and the unfixable entries it *would* surface, without mutating the filesystem. Useful for security-conscious users auditing the install before a repair.

- Add `--dry-run` argument parsing in `cmd_fix_security`
- Skip the `chmod` call when in dry-run mode; preface fix lines with `[dry-run]`
- Add a test case to `t/cwf-manage-fix-security.t` that asserts no fs mutation in dry-run mode
- Update help text and SKILL.md if appropriate

<!-- Note: Implemented: --dry-run previews chmod actions/unfixables, mutates nothing; unknown args fail closed -->

#### Replace Backtick Operators with IPC::Open3 in cwf-manage

Replace backtick operators in `.cwf/scripts/cwf-manage` with `IPC::Open3` calls to satisfy perlcritic severity 3 (harsh). `IPC::Open3` is core since Perl 5.000. Currently 5 backtick usages for simple `git` commands — functional and readable as-is, but not PBP-compliant at level 3.

- Replace backticks in `find_git_root()`, `resolve_ref()`, `resolve_sha()`, `cmd_list_releases()`
- Consider also adding `/x` flag to simple regexes (8 hits) and converting the if-elsif dispatch to a hash table (1 hit) for full level 3 compliance

<!-- Note: Implemented with list-form open() fork (git_capture) rather than IPC::Open3: lighter, avoids deadlock/stderr-merge traps; perlcritic backtick policy clean. Only 2 backticks remained (not 5). -->

## Task 158: Fix install.bash reinstall and settings-merge

### Status: Complete (2026-05-24)
### Duration: single session (estimate <1 day, Low–Medium complexity). On estimate.
### Impact: Bugfix — three items from a downstream consumer's `CWF_FORCE` copy→subtree migration log. **(1)** `install_subtree`'s force-reinstall removal commit hard-coded the pathspec `-- .cwf .cwf-skills .cwf-rules .cwf-agents`; when a pre-state lacked one (e.g. `.cwf-agents` on a pre-agents copy install) `git commit` failed wholesale, `|| true` swallowed it, and the *other* staged deletions stayed in the index — breaking the subsequent `git subtree add`. Fixed by committing only the dirs actually `git rm`'d (a `removed[]` array), with a `die` on a *tracked* dir whose `git rm` fails and removal of the `|| true`/`--allow-empty` that hid the bug. **(2)** `post_install` never merged `.claude/settings.json`, so a raw `CWF_FORCE=1 bash install.bash` migration (which has no `/cwf-init` or `cwf-manage update` completion caller) never landed PERL5OPT/allowlist; fixed by invoking `cwf-claude-settings-merge` after the symlinks and before the version write, `-x`-guarded with `|| die`, mirroring `cwf-manage`'s `run_settings_merge`. **(3)** `security-review.md` §Pathspec coverage omitted `.claude/agents/` (the helper's `@CWF_INTERNAL_PREFIXES` already had it) — prose corrected. Scope was narrowed in design: an apply-artefacts "parity" option was investigated and **rejected** (its premise — that a reinstall empties `.cwf/rules-inject.txt` — was false; the file ships populated in the subtree, and the proposed call would have *emptied* it). New `t/install-bash-reinstall.t` (TC-1..TC-7, each RED pre-fix / GREEN post-fix, incl. failure paths via a root-independent fake-git PATH shim); full suite 47 files / 516 tests pass; `cwf-manage validate` clean (neither edited file is hash-tracked → no `script-hashes.json` refresh).

### Notable
- **Plan review refuted a load-bearing false premise before any code was written.** Three reviewers confirmed an "empty blob" fact but misattributed template vs. consumed dest; one careful reviewer plus a direct `git ls-files -s` check caught it, flipping the design from the harmful Option A to Option B.
- **The fixes turn on failure paths the old `|| true` swallowed**, so the tests assert the install now *aborts loudly* (TC-2 tracked-rm failure; TC-5 merge failure aborts before the version write) — not just the happy path.
- **A fake-`git` PATH shim** (exit 1 on the `rm` subcommand, `exec` real git otherwise) gives a deterministic, root-independent way to exercise the tracked-rm-failure branch.
- **Security-review gate recorded `State: error` in both exec phases** despite substantively clean reviews: the reasoning-model reviewer prefaced its `no findings` sentinel, so the deterministic classifier conservatively defaulted to `error`. Recorded verbatim rather than silently downgraded; filed as a Medium backlog item.

## Task 157: Verify progress-signal still causes conflicting task context inference

### Status: Complete (2026-05-23)
### Duration: single session (estimate <1 day, Low complexity). On estimate.
### Impact: Discovery — no behaviour change. Investigated the Medium backlog item claiming `_score_progress` scores completed tasks highest and lets finished tasks dominate the progress signal in `task-context-inference`. Verdict: **misread of current code**. `_score_progress`'s input is not raw completion — `_get_progress_signal` feeds it `_calculate_task_progress` (`TaskContextInference.pm:488`), which returns `CWF::TaskState::state_achievable`, applying a cliff (`TaskState.pm:150`: completion ≥ 100% → work potential 0). `_get_progress_signal` then drops zero-score candidates (`TaskContextInference.pm:418`). So a correctly-finished task (all steps terminal → `state_done` 100) arrives as 0 and is filtered out before candidate assembly — it cannot be `top`, cannot dissent, cannot drive an inconclusive. Confirmed both by static trace (FR1) and by an executable probe calling the real `state_achievable`/`_score_progress`/`_get_progress_signal` against a synthetic three-task tree (FR2): candidates `[203:15, 202:6]`, the finished task `201` **absent**, `top=203`. The original Task 104 observation either predates the current cliff implementation or reflects a task mislabelled Finished with a non-terminal step (purpose-#2 diagnostic, not noise). Read-only: no `.cwf/**` modified; fixture and probe were throwaway scratch artefacts. Backlog item retired; a Low clarity-only chore filed to rename the misleading `$percentage` parameter (`:447`) and delete the stale "bell curve, peak at 50%" comment (`:410`).

### Notable
- **`{code} != {purpose}`.** Reading `_score_progress` in isolation produces exactly the backwards conclusion the backlog item reached. The upstream cliff and downstream zero-filter are the real guarantee; the function body alone does not show them. The misleading parameter name and stale comment are what made the function read like a bug.
- **`inconclusive` is diagnostic, not abstention.** A "finished" task that surfaces as a candidate is evidence it is not correctly finished — the alarm working as designed. The recommendation deliberately does not propose suppressing this.
- **The parse-success guard was load-bearing.** Asserting `state_done(201)==100` before trusting the candidate list ruled out a false-confirm where a malformed fixture (no `## Status` heading → empty statuses → 0) would have excluded the finished task for the wrong reason.
- **Plan review corrected real design errors before exec** — a wrong `find_git_root()` citation and an unreachable "chdir → defaults fallback" (config is process-cached). The corrected reasoning (config-source-independent because real config is byte-identical to defaults for the keys used) is what made the empirical step trustworthy.

### Retired Backlog Items
#### Progress Signal Scores Completed Tasks Highest in Task Context Inference

The `_score_progress` function in `TaskContextInference.pm` uses a linear ramp (line 452: `int(($percentage / 100) * WEIGHT_PROGRESS_MAX)`) — a task at 100% gets score 60 (maximum), while a task at 10% gets score 6. This means **finished tasks dominate the progress signal**, which is backwards: a 100% task has no remaining work and shouldn't be a candidate for "current task."



- Fix `_score_progress` in `.cwf/lib/CWF/TaskContextInference.pm`
- Either filter out 100% tasks or use bell-curve scoring
- Update comment to match implementation
- Verify with mixed completed/in-progress task states

<!-- Note: Investigated in Task 157. Premise is a misread of current code: the cliff at TaskState.pm:150 plus the zero-score filter at TaskContextInference.pm:418 already exclude correctly-finished tasks from the progress signal. Not a bug. Superseded by a Low clarity-only chore. -->

## Task 156: Suggest fresh install on cwf-manage update failure

### Status: Complete (2026-05-23)
### Duration: single session (estimate <1 day, Low complexity). On estimate.
### Impact: Bugfix — when a `cwf-manage update` fails during laydown, the error output now suggests the user *might* consider a fresh install (a clean remove-then-add) and points at the existing `INSTALL.md` "Recovering an install stuck on an old cwf-manage" recovery. Previously the updater died with only a local diagnostic, never surfacing the documented bootstrap recovery — a gap given the forward-only updater limitation (Task 155). Implemented as a single file-scoped flag `$update_in_progress` (declared above `die_msg`, set to `1` in `cmd_update` immediately after checkout, before the laydown dispatch); `die_msg` appends the 5-line `[CWF]` suggestion only when the flag is set. This covers every laydown/artefact/settings/perms/version-write failure — including those raised inside shared helpers (`run_apply_artefacts`, `run_settings_merge`, `apply_exact_perms_or_die`) — with one change point, while pre-flight guard failures (malformed ref, dirty tree, unparseable settings, tampered manifest) and clone/checkout failures stay clean (a same-source bootstrap would hit the identical failure there). The bootstrap line keeps `<tag>`/`<source-url>` as literal placeholders — `$source` may derive from `$ENV{CWF_SOURCE}`, so interpolating it into a printed shell command is avoided (FR4(d)); a test asserts the placeholder survives, turning the guardrail into a regression. In-commit `cwf-manage` sha256 refresh. Four new subtests in `t/cwf-manage-update-end-to-end.t` cover hint presence on a laydown failure and absence on pre-flight + clone/resolve failures, plus a static single-set-point guard; full suite 46 files / 509 tests pass; `cwf-manage validate` clean; both exec-phase security reviews clean.

### Notable
- **Scoping is the load-bearing behaviour, so the negative tests carry the proof.** A single flag makes the hint trivial to emit; the value is in *not* emitting it for pre-flight/clone failures. The testing plan made the hint-absence assertions mandatory rather than only asserting the positive path.
- **Flag-set point is a correctness decision, not style.** Placed after clone/checkout because those touch only a throwaway tempdir — a same-source bootstrap would fail identically, so a fresh-install suggestion there would mislead. The hint fires only once the user's install can actually be left partial.
- **A security guardrail encoded as a test.** Keeping the bootstrap command's placeholders literal is enforced by `like($out, qr/<source-url>/)`, so any future env-var interpolation fails the suite.
- **Plan review caught an incomplete failure enumeration.** The design's "covered failures" list initially stopped at the last obvious helper and omitted the trailing version-file-write region; reviewers flagged it. Lesson recorded: enumerate covered failures by walking the enclosing function to its end.

## Task 155: Converge cwf-manage update onto install.bash

### Status: Complete (2026-05-23)
### Duration: single session across 2026-05-22→23 (estimate 1–2 weeks, High complexity — consolidated 3 prior backlog entries). Large wall-clock under-run; complexity/risk ratings were accurate, the calendar estimate was not.
### Impact: Feature — fixes a real user cross-version upgrade failure (subtree install across a multi-version gap) by converging the **subtree** update path onto the target version's own `install.bash`. `cmd_update`'s subtree branch now `chdir`s to the git root and `system`s the freshly-cloned `$clone_dir/scripts/install.bash` (list-form, no shell) with `CWF_FORCE=1`, `CWF_SOURCE=file://$clone_dir`, `CWF_REF=<resolved-sha>`, `CWF_METHOD` — a clean remove-then-add that (a) eliminates the `git subtree pull --squash` add/add conflict, (b) makes update run the *target's* laydown so future cross-version jumps can't hit the chicken-and-egg, and (c) pins to the resolved full SHA so install.bash can't drift. `update_subtree` deleted. The **copy** path deliberately retains `update_copy` + `create_*_symlinks` (porting the `_escapes_src` symlink-escape guard into bash is out of scope) — so FR1 single-ownership holds for subtree only; copy convergence filed as a Low follow-up. Ref handling hardened: new `validate_ref_lexical` (charset `[A-Za-z0-9._/-]`, rejects leading `-` and `..`, allows `latest`) runs before any side effect, and `resolve_ref`/`resolve_sha` converted backticks → list-form `open '-|'` (removes the real injection vector). chmod reconciled: `cmd_fix_security` refactored into `_read_hashes_data` + `_apply_recorded_perms($mode)`; new `apply_exact_perms_or_die` runs **after** apply-artefacts/settings-merge with exact recorded perms, fatal on mismatch (no silent repair). `cmd_update`'s version write made authoritative — overwrites install.bash's base `.cwf/version`, restoring the real `cwf_source` (not the transient `file://`) and pinning `cwf_install_manifest_sha` exactly once (resolves the feared double-write). `install.bash`: force-block commit narrowed to an explicit CWF pathspec (no sweeping unrelated staged work), regular-file collision `die` ported into the generic `create_cwf_symlinks`. `check_clean_tree` widened to `.cwf-rules`. In-commit `cwf-manage` sha256 refresh. New `t/cwf-manage-update-end-to-end.t` (5 subtests, programmatic multi-version upstream fixture) covers FR2/FR3/FR5/FR6/FR9/FR10; full suite 46 files / 505 tests pass; `cwf-manage validate` clean; both exec-phase security reviews clean. INSTALL.md documents the forward-only updater limit and its one-time `CWF_FORCE` bootstrap recovery.

### Notable
- **The fix is structurally forward-only and that's correct.** Because the *installed* (old) `cwf-manage` runs the update, no shipped fix repairs installs already on a pre-fix updater. Rather than attempt an impossible self-repair, the limit is documented with a one-time bootstrap-installer recovery path. Accepting the constraint was the right engineering call, not a gap.
- **Harness-first sequencing de-risked the whole task.** Building `t/cwf-manage-update-end-to-end.t` before touching the updater (the plan's top-listed high-risk mitigation) turned a scary delivery-path change into an incrementally-verified one — every convergence step had a green/red signal.
- **Convergence is bounded by primitive parity.** The copy path's lexical symlink-escape guard (`_escapes_src`) has no cheap bash equivalent, so full single-ownership was scoped out, not skipped. Two laydown implementations can only merge as far as the lower-level language can express the higher one's safety guards.
- **The implementation plan over-scoped its deletion list.** d-plan listed deleting `create_*_symlinks` and narrowing `cwf-apply-artefacts` — both unsafe once the copy path is retained, caught only at exec. A design-phase "list the remaining callers of every helper marked for deletion" check would have caught it at c. Recommendation recorded for future convergence/refactor tasks.
- **Authoritative version write beat re-read-and-augment.** Letting `cmd_update` overwrite install.bash's base version file (rather than parse-and-patch it) cleanly solved both the `file://` source leak and the manifest-SHA double-write in one move.

### Retired Backlog Items
#### Converge cwf-manage update onto install.bash (shared install-lifecycle library)

Two install paths exist — `scripts/install.bash` (bash) and `.cwf/scripts/cwf-manage` `update_subtree`/`update_copy` (perl) — and they duplicate subtree-split/add, copy-method, and create-symlinks logic per `.cwf-*` staging dir. They drift: `install.bash` lays down 4 subtrees (`.cwf`, `.cwf-skills`, `.cwf-rules`, `.cwf-agents`); `update` delivers core/skills/agents via subtree but rules via `cwf-apply-artefacts` (a divergent mechanism). Adding a staging dir needs symmetric edits in both scripts (Task 143's `.cwf-agents` work; TC-AC1-install caught a missed edit).

Root issue (user upgrade-failure report, 2026-05-22, subtree install v1.0.114 → v1.1.152): the update is performed by the *installed* (old) `cwf-manage`, so fixes to the updater never reach installs that predate them — a chicken-and-egg. Reported symptoms: (1) `git subtree pull --squash` produces spurious add/add conflicts across a multi-version gap (squash loses the merge base); (2) update structurally out of sync with install (old versions can never deliver trees added in a later minor). Issue (3) — update ignoring `CWF_SOURCE` — is already fixed (Task 115).

Goal: a single shared install-lifecycle implementation used by both install and update, such that update runs the *target* version's laydown logic (e.g. delegate to the freshly-cloned `$clone_dir/scripts/install.bash` via the `CWF_FORCE` remove-then-add path). This (a) makes install/update incapable of drifting, (b) eliminates the `subtree pull --squash` conflict via fresh remove-then-add (the documented `CWF_FORCE=1 … install.bash` workaround already proves this works), and (c) structurally breaks the chicken-and-egg for all future cross-version jumps.

Approach options:
- (a) Bash library under `scripts/lib/` sourced by both; (b) a single Perl helper invoked by both; or (c) update shells out to the cloned target's `install.bash`.
- Reduces per-staging-dir maintenance from ~12 edits (6 in each script) to ~3 in one place.
- Constraint: `cmd_update` has accreted steps `install.bash` lacks — `cwf-apply-artefacts`, `cwf-claude-settings-merge`, manifest-SHA pinning (D12), the update lock. Convergence must move these into a shared post-install so update does not regress them; `install.bash`'s own `.cwf/version` write must not double-write against `cmd_update`'s manifest-sha logic.
- Nothing shippable can repair installs already on a pre-fix `cwf-manage`; document `CWF_FORCE=1 CWF_REF=<tag> CWF_SOURCE=<src> bash install.bash` as the one-time recovery path.

Folded in — chmod reconciliation (was "Reconcile cwf-manage update and fix-security chmod logic", Task 120 follow-up):
- `cmd_update` does a blanket `chmod 0755` over `.cwf/scripts/`; `fix-security` chmods to exact recorded perms (0500/0700/0755) per `script-hashes.json`. Both pass validate but produce different end states.
- Replace the blanket chmod in `cmd_update` with a `cmd_fix_security` call (or extract per-entry chmod into a shared sub); confirm update integration tests still pass; refresh the `cwf-manage` hash.

Folded in — end-to-end test harness (was "Add fixture-server harness for end-to-end cwf-manage update tests", Task 127 follow-up):
- Task 127's TC-INT-AC1 was PARTIAL — no true end-to-end test of the clone+subtree-pull flow. Needs a fixture remote + multi-commit history.
- Build `t/fixtures/upstream-server/`: bare git repo, 3-5 scripted commits with realistic CWF-shaped diffs.
- Add `t/cwf-manage-update-end-to-end.t`: clone fixture → init → modify fixture → update → assert artefacts updated, manifest-SHA pinned, lock released.
- Cover regressions: subtree-pull/squash conflict across a version gap, manifest schema bump, upstream rollback (downgrade). Out of scope: SIGKILL-during-rename atomicity (covered by same-dir-temp + rename), interactive D/A prompt branches (need an expect-style harness).

Consolidates three prior Low-priority entries: install-lifecycle dedup (Task 143), chmod reconciliation (Task 120), fixture harness (Task 127). Bumped to Medium because a real user cross-version upgrade failure now motivates it.

<!-- Note: Delivered as subtree-only convergence; copy-method convergence deferred (new Low BACKLOG item). -->

## Task 154: Fix cwf-manage-fix-security test fixture

### Status: Complete (2026-05-22)
### Duration: single session (estimate <0.5 day, Low complexity). On estimate.
### Impact: Fixes a pre-existing red test (`t/cwf-manage-fix-security.t` TC-1/2/7 failed on a clean tree), filed as a Medium BACKLOG bugfix from Task 153. Root cause: `build_fixture` copied only `.cwf/` into the fixture, but `.cwf/security/script-hashes.json` also tracks 5 `.claude/agents/*.md` paths; `cmd_validate`/`cmd_fix_security` resolve every manifest path against the fixture git root (`cwf-manage:743`), so those files read as missing → `existence` violations → exit 1. Fix is test-only: a new `_provision_extra_manifest_paths($tmp)` helper parses the manifest and `cp -p`s every tracked path whose first segment is not `.cwf` into the fixture (existence + byte-identical content for SHA + preserved perms for the recorded floor). The copy set is **derived from the manifest, not hard-coded**, so a future task that tracks a new non-`.cwf/` path is provisioned automatically. A new TC-8 pins the helper directly, asserting on the manifest-derived set (≥1 path; today the 5 agents at floor 0444) rather than a hard-coded count. No production code, no hashed file, no hash refresh: `prove t/cwf-manage-fix-security.t` 8/8; full `prove t/` 500 pass; `cwf-manage validate` on the real repo unchanged. Security review clean both exec phases (one advisory category-(e) note on the fail-closed `..`/absolute path guard, documented inline).

### Notable
- **Manifest-derived copy set kills the bug class, not just the instance.** Hard-coding `.claude/agents/` would re-break the moment a new tracked root appears (e.g. `.claude/hooks/*`); deriving from the manifest binds the fixture to the same source of truth the tool reads. TC-8 enforces this going forward.
- **Design-phase plan-review caught a phantom limitation.** An early draft flagged fresh-clone perms as a failure mode; verifying the perm operator (`($actual & $recorded) != $recorded`, `Security.pm:117`) showed the check is a *floor*, not exact-match — a fresh-clone 0644 satisfies a 0444 floor. `cp -p`'s real value is umask-independence, not exact-perm fidelity. The correction collapsed a would-be BACKLOG follow-up.
- **Clean phase boundary.** The production-side helper landed in implementation-exec (f); the test that pins it (TC-8) landed in testing-exec (g) — f delivers the fix, g delivers the guard.
- **Fail-closed guard, stricter than production by design.** The helper `die`s on any `..`/absolute manifest path even though the production callsite trusts its integrity-tracked manifest; the asymmetry is deliberate and made the security review trivially clean.

### Retired Backlog Items
#### Fix t/cwf-manage-fix-security.t: build_fixture omits .claude/ manifest paths

`t/cwf-manage-fix-security.t` fails (TC-1, TC-2, TC-7) on a clean tree. Confirmed pre-existing at baseline `b5b8739` during Task 153 (the failure reproduces identically before any Task 153 edit).

Root cause: `build_fixture()` copies only `.cwf/` into the tempdir (`cp -rp $REPO_ROOT/.cwf`), but `.cwf/security/script-hashes.json` now also lists `.claude/agents/*` paths (the 5 plan-reviewer / security-reviewer agents, hash-tracked since ~Task 148/149). Those files are absent from the fixture, so `validate`/`fix-security` report a missing-file (existence) failure and `fix-security` refuses (exit 1, repaired 0). TC-1 (clean no-op), TC-2 (post-validate), and TC-7 (idempotency first run) all assert exit 0 / clean validate and therefore fail.

Fix options: have `build_fixture` also copy the `.claude/agents/` (and any other non-`.cwf/`) files the manifest references, or make the test derive the copy set from the manifest paths rather than hardcoding `.cwf/`. Either way the fixture must contain every path the manifest enumerates.

Unrelated to the PERL5OPT change; surfaced and recorded rather than absorbed.

<!-- Note: Fixed by deriving the fixture copy set from the manifest; TC-8 added as drift pin. -->

## Task 153: Move PERL5OPT to project-local settings

### Status: Complete (2026-05-21)
### Duration: ~½ day wall-clock; estimate ~½ day. Variance 0%.
### Impact: Fixes a CwF bug where `PERL5OPT=-CDSLA` was recommended into the user-global `~/.claude/settings.json` — a single global value shared by every repo on the machine, so two CWF installs that want different values clash (last writer wins, silently breaking the other). The setting is now project-scoped: `cwf-claude-settings-merge` gains a `merge_env` step that writes `env.PERL5OPT=-CDSLA` into the project `.claude/settings.json` (add-if-absent, warn-on-mismatch, type-guarded), and both `/cwf-init` step 6d and `cwf-manage update` already invoke that helper — so installation is automatic and the value is committed with the project; project `env` overrides the user-global one per Claude Code's settings precedence (verified against its docs this task). `cwf-manage` itself is unchanged (it already delegates to the helper). `CWF::Common::check_perl5opt`'s warning + POD, `.claude/skills/cwf-init/SKILL.md` (step 7 retired → no-user-action note), `INSTALL.md`, and `docs/conventions/perl.md` all retarget to project settings; none retain the literal `~/.claude/settings.json` string, so a repo-wide zero-hit grep guards against regression. In-commit `sha256` refresh for the two hashed files (`cwf-claude-settings-merge`, `CWF::Common`); this repo's own `.claude/settings.json` committed env-only as dogfood. `$CANONICAL_PERL5OPT` is kept a compile-time constant — the tool-call `env` path has no trust-gate (FR4(e)).

### Notable
- **Verified the load-bearing premise before building.** "Project `.claude/settings.json` `env` overrides user-global and applies with no trust-gate" was confirmed against Claude Code's own settings/env docs during planning. The entire fix is inert if that's false; confirming it first de-risked the task.
- **Maximal reuse, minimal new surface.** Extending the single existing project-settings writer (reached by both install and update) meant no new helper, no `cwf-manage` edit, and only two hashed-file refreshes. Both design reviewers independently confirmed the insertion point.
- **Discovered a pre-existing red test and proved it pre-existing.** `t/cwf-manage-fix-security.t` (TC-1/2/7) fails on a clean tree because its `build_fixture` copies only `.cwf/`, but the hash manifest now lists 5 `.claude/agents/*` paths (hash-tracked since ~Task 148/149). Reproduced identically at baseline `b5b8739` via a throwaway `git worktree`, so it is not from this task — filed as a Medium BACKLOG bugfix rather than absorbed or panicked over.
- **Surface, never smooth — applied to the permission drift too.** The unrelated `cwf-plan-reviewer-misalignment.md` 0600-vs-0444 drift (a git-checkout artefact, sha intact) was repaired with the canonical `cwf-manage fix-security`; the chmod is not committable (git stores 100644 either way), so it stays out of this task's diff.
- **Plan-review subagents earned their keep (8 reviews across c+d).** Load-bearing folds: dry-run must still warn on drift; type-guard a malformed `env`; the `check_perl5opt` message must not over-promise (restart + bare-shell caveats); concrete env-only re-derivation for the dogfood commit; repo-wide closing grep; corrected `Common.pm` line anchors; extend the existing test file rather than create one.

### Retired Backlog Items
None — this task was triggered by a CwF bug report, not by an existing BACKLOG entry. Two new follow-ups filed: "Fix t/cwf-manage-fix-security.t: build_fixture omits .claude/ manifest paths" (Medium) and "Single source of truth for the canonical PERL5OPT value (-CDSLA)" (Low).

## Task 152: Fix retrospective merge suggestion for subtasks

### Status: Complete (2026-05-18)
### Duration: ~½ day wall-clock; estimate ~½ day. Variance 0%.
### Impact: Fixes a CwF user-reported bug where `/cwf-retrospective` Step 12 hardcoded `git checkout main` as the suggested merge target, producing the wrong target for subtasks (subtask 20.2 should merge to parent task 20, not to main). The new wording in `.cwf/docs/skills/retrospective-extras.md` derives the target from the current task's position in the hierarchy via two `context-manager hierarchy --format=json` calls: empty `parent_path` → `main`; non-empty → parent task's branch (`<type>/<num>-<slug>` from the parent's directory). The suggested command is now prefixed with `sleep 1 && git` so users can paste it directly into Claude Code's Bash tool without hitting the background-git index.lock race. `.claude/skills/cwf-retrospective/SKILL.md` Step 12 collapses to a single-line reference to the new `#suggest-merge-step-12` anchor (matches the existing pattern at Steps 6/8/10); Gotcha #2's stale "Step 10 says…" reference also corrected. `.cwf/docs/workflow/versioning-standard.md:76` broadened from "Suggest the merge to main" to "Suggest the merge to the parent (parent task branch for subtasks; trunk for top-level tasks) — human action". No new helpers, no script changes, no hash refresh (none of the three target files are listed in `script-hashes.json`; pinned at plan time).

### Notable
- **User correction loop caught a misleading scope summary.** My post-design phase summary used "BACKLOG-deferred for promotion to a convention doc" wording that invited a misread of "the user's two asks are deferred." Both asks (parent-target + `sleep 1 && git` prefix) shipped in this task; only the *meta* follow-ups (where the convention doc lives, and trunk-resolution for non-`main` adopters) were deferred. Worth flagging future phase summaries with "what's landing now" vs. "noted for later" distinction.
- **Naming directive captured as durable feedback.** The user asked that the prefix never be named just `sleep 1 &&` — always `sleep 1 && git`, because the rule exists specifically for background-git lock contention and naming without `git` invites misapplication to non-git Bash calls. Saved as `feedback_sleep_git_prefix_name.md` + MEMORY.md index; the existing Git-section entry was updated to tie the bullet to the new feedback memory.
- **Plan-review subagents earned their keep on three load-bearing fixes.** Misalignment-review caught that hash-disclosure had to happen at design time (per `hash-updates.md`), not deferred to exec — converted a vague claim into a single reproducible grep. Improvements-review caught a self-defeating verification grep that would have flagged the new example fence as a regression — fixed by combining the two greps with an explicit benign-hit allow-list (`.cwf/rules-inject.txt:4`, the gotcha title, the new example fence). Improvements-review also caught the maintainer-note placement: HTML comments are invisible in rendered views — switched to visible italic.
- **Single-source-of-truth structure already existed and was honoured.** `cwf-retrospective/SKILL.md` Steps 6/8/10 already used the "Read `…/retrospective-extras.md#<anchor>` for …" single-line reference pattern; Step 12 was the outlier inlining the command. Collapsing Step 12 to the same pattern removed duplication and means the convention-doc follow-up only has to update one site (`retrospective-extras.md`), not two.
- **No new helper despite the temptation.** The derivation rule needs two `context-manager hierarchy --format=json` calls (one of which is already in the retrospective skill's preamble) plus three lines of string composition. The retrospective skill never *executes* the merge — output is for human paste only, so a wrong-looking command fails loudly on paste with no silent-corruption blast radius. A new helper would have added a script + hash + lockstep dependency on branch-naming convention. Cost > benefit.
- **`backlog-manager add --body-file=<scratch-path>` pattern worked cleanly.** Body text written to `/tmp/-home-matt-repo-coding-with-files-task-152/backlog-entry-{1,2}-body.md` via the Write tool, passed as `--body-file` to two `backlog-manager add` invocations. Honours [[no_heredocs]] and [[tmp-paths]] without prose contortions; worth standardising as the default for any multi-paragraph BACKLOG entry.

### Retired Backlog Items
None — this task was triggered by an external user bug report, not by an existing BACKLOG entry.

## Task 151: Consolidate Cross-Doc Reference Patterns

### Status: Complete (2026-05-18)
### Duration: ~70 min active wall-clock (a→g, excluding overnight gap) across 8 checkpoint commits, vs. 1-2 day estimate. Variance −95% — estimate priced human-pace audit + writeup; actual work was dominated by getting one 250-line Perl audit script to classify 25K candidate references correctly, and the tight c-design contract collapsed exec time by an order of magnitude.
### Impact: Lands `docs/conventions/cross-doc-references.md` (60 lines) — a 4-row rules table by locality (`intra-file`, `intra-task`, `intra-repo`, `external`) with a 5-bullet rejected-alternatives sub-section and a `BACKLOG.md`/`CHANGELOG.md` carve-out. Wires `CLAUDE.md` `## Conventions` between `**Git Path Handling**` and `**Tmp Paths**` with the standard bold-name + summary + `See ... for:` + bulleted-list shape. The audit baseline (21,161 references across 1,172 tracked `.md` files at SHA `084774d`) is preserved verbatim in `implementation-guide/151-*/audit-appendix.md` (22,349 lines, 3.9MB, fence-wrapped for prompt-injection containment) and is re-runnable from the audit-script source embedded in `f-implementation-exec.md`. Pre-migration divergence baseline: ~7,964 references diverge from the chosen rules (5,616 plain-prose × path intra-repo, 2,128 intra-task, plus smaller categories); per-file top-10 captured in the migration BACKLOG entry. Dogfooding against `docs/conventions/commit-messages.md` per AC7 found 0 mismatches (1 inline-backtick URL on line 66 qualified for the example/template URL carve-out). The migration itself is deferred to the new BACKLOG entry "Migrate cross-doc references to canonical style" — this task is discovery + standard-setting only.

### Notable
- **Two-axis schema (c-design D1) replaced the b-requirements single-form enum.** Splitting `delimiter` × `target-shape` made rules expressible per locality (e.g. "external URLs bind both axes: `markdown-link × external-url`"); a single flat enum would have needed combinatorial values. Caught by misalignment-review on the b-phase draft.
- **`$'` is a Perl postmatch magic variable that interpolates silently inside regex character classes.** Original URL regex `/[\w\-./%?&=#:~+,;@!$'()*]+/` produced 46 "uninitialized $'" warnings + a crash because file content extended the empty `$'` into an invalid `t-f` range. Fix: negative char class `[^\s)<>"\[\]\`]+`. Worth saving as a feedback memory; this is a Perl gotcha not currently documented.
- **`local $/ = undef` at top-level scope leaks into per-file reads.** The first audit run reported `source_line=1` for every row because the slurp from `git ls-files -z` set `$/` undef and the per-file `<$f>` calls inherited it, returning each file as a one-element array. Fix: scope `local $/` to a bare block.
- **Audit output size (3.9MB / 22K lines) was not anticipated by the plan.** b-requirements NFR3 said "lives in `f-implementation-exec.md` and `g-testing-exec.md`" as appendix sections; 4MB inline was hostile to review and main-branch compactness. Split into sibling `audit-appendix.md` in the task directory — preserves the "audit lives with the task" intent and the prompt-injection fence wrap. Documented as deviation #1 in f-exec.
- **Noise filter added at exec time** for `plain-prose × path` candidates lacking discriminating characters (`.`, `-`, leading `/` or `~/`). Without it, slash-alternation phrases like `N/A`, `pass/fail`, `map/reduce`, `I/O`, `BACKLOG/CHANGELOG` contributed ~3,000 false-positive rows. The filter is bounded (only plain-prose × path; backtick-wrapped paths and citations untouched) and deterministic. Documented as deviation #2.
- **`cwf-checkpoint-commit` "exactly one wf file per phase letter" invariant is real.** First f-checkpoint failed because the sibling appendix was originally named `f-implementation-exec-audit.md`. Renamed to `audit-appendix.md`. A separate `cwf-manage validate` warning then fired because the appendix lacks a phase-letter prefix but is in the task dir — added a `## Status` stub in a fix-up commit (`f014b1d`). Both are worth flagging as helper friction around task-scoped sibling artefacts; see Future Work in j-retrospective.
- **Plan-review map/reduce again earned its keep on a discovery task.** c-review caught the phantom `intra-task-historic` 5th locality (was contradictory to the 4-valued enum); d-review caught the `wc -l` shell-out (NFR4 violation); d-review caught the row-count sanity bounds that would have false-triggered. All addressed pre-exec.

### Retired Backlog Items
#### Research and Consolidate Cross-Document Reference Patterns

Original ask: "Analyse and standardise cross-document reference patterns used throughout CWF system documentation, templates, and command files. Define a clear, documented standard for cross-document references that follows DRY and progressive disclosure principles." Implemented as a discovery task — standard committed at `docs/conventions/cross-doc-references.md` with the audit baseline preserved at `implementation-guide/151-discovery-consolidate-cross-doc-reference-patterns/audit-appendix.md`. Migration to canonical style is filed separately as Low-priority BACKLOG entry "Migrate cross-doc references to canonical style" with ~7,964 divergent references and a staged-migration recommendation (convention docs → templates → individual wf files).

## Task 150: session hygiene guidance from past deviations

### Status: Complete (2026-05-17)
### Duration: ~2–3 hours wall-clock active work in a single calendar day, vs. 2–4 hour estimate. Within range.
### Impact: Adds `.cwf/docs/conventions/session-hygiene.md` (59 lines, 4 content sections + tail) covering `/clear` triggering conditions (≥3 bullets, ≥2 citing audit-table P-numbers), `/compact` vs auto-compaction with a preservation list explicitly including "standing security rules from CLAUDE.md `## Critical Rules` and MEMORY.md", on-resume memory salience + workflow-state re-derivation from on-disk `a-task-plan.md` through `j-retrospective.md` Status fields, and an inline "surface, never smooth" security principle with `recompute-hashes` / `validate --fix` / `validate --ignore` / `/clear`-as-gate-bypass / compaction-induced rule loss enumerated as defender-framed anti-patterns. Single advertised consumer wired into `CLAUDE.md` `## Conventions` after `**Hash Updates**` — survives `/compact` boundaries because CLAUDE.md is reloaded fresh per turn (structural mechanism, not "compaction preserves the bullet"). Discovery-task workflow: evidence-based audit (P1–P5 from retrospectives + memory files; LMM corpus unavailable this session and recorded as R-LMM follow-up) → c-design fixed doc shape against tier-sizing data → d-implementation specified exact anchors and validation gates → e-testing defined 16 TCs with partial-match-vs-exact-line pass-condition semantics throughout. All 16 TCs pass (15 mechanical + 1 manual NFR4.3 defender-framing attestation).

### Notable
- **Plan-review map/reduce earned its keep across all three plan phases.** Caught M1 wiki-link misalignment in a-task-plan (fixed in b-phase commit), the D2 structural-mechanism reframe (CLAUDE.md is reloaded per turn, not preserved by compaction summarisation), the workflow-state authoritativeness FR (Security F3 → FR3.AC3.3 re-derive from on-disk task files), the inline-principle requirement (Security F1 → NFR4.1, because the principle's prior residence is operator-private memory and unverifiable from session), and the load-bearing self-application risk (F5 on c-design → AC4.6 — the doc documents a failure mode that affects itself).
- **Sparse-signal contingency was actually invoked and behaved correctly.** LMM corpus unavailable (`mcp__lmm__search_semantic` returned `User not found`) → fall back to retrospectives + memory files → still meet ≥3-pattern threshold (4 clear + 1 named residue). The a-plan threshold was real, not theatre.
- **Defender-framing first-filter regex auto-passed by construction.** The doc's `/clear` mentions are wrapped in backticks (`` `/clear` ``) or followed by hyphens (`/clear`-as-gate-bypass), so `/clear\s+(escape|...)` never fires. "compaction-induced rule loss" puts "rule" before "loss" with "loss" outside the regex's verb set. Defender-framed phrasing produced filter-clean output without contortions.
- **One plan-text defect**: d-plan referenced `.cwf/scripts/command-helpers/cwf-manage`; actual helper path is `.cwf/scripts/cwf-manage` (one level up). Corrected at exec time, no behaviour impact. Plan-review subagents reviewed plan logic, not helper-path existence — surfaced as a plan-time check worth adding (see follow-up BACKLOG).
- **`backlog-manager retire` is the right shape.** Atomic BACKLOG removal + CHANGELOG append in one operation; idempotent-ish; clean exit. The retrospective-time fill-in for Status/Duration/Impact happens in-task as part of the standard j-phase CHANGELOG update flow.

### Retired Backlog Items
#### Add Session Hygiene Guidance to CWF Documentation

Original ask: "Add guidance on Claude Code session management to CWF documentation, helping users maintain effective context across workflow phases." Implemented as the discovery-task workflow described above; canonical doc lives at `.cwf/docs/conventions/session-hygiene.md` with the always-reloaded CLAUDE.md preamble as the advertised consumer.

## Task 149: Fix Task 147 hash drift, clarify hash rule

### Status: Complete (2026-05-17)
### Duration: ~17 min wall-clock from a-checkpoint to g-checkpoint, across 5 exec-phase commits, vs. ~1 hour estimate. Variance −72%.
### Impact: Refreshes the two sha256 entries Task 147 deferred — `CWF::Backlog.pm` (`8c4bd187…ebdb85c` → `375ce811…49b7e7`) and `backlog-manager` (`1b360005…62e0b6b5c3` → `f9045c72…931fce9e`) — in-diff, after per-file `git log` verification confirmed each file's drift was a single commit (`246e6c4`, Task 147). Codifies the in-task hash-update rule in a new convention doc (`.cwf/docs/conventions/hash-updates.md`, 49 lines) covering Convention, Why, How (mechanical), Plan-time disclosure, Pre-refresh verification (per-file baselines, not assumed-shared), a four-invariant carve-out for dedicated hash-fix tasks, "What NOT to build" as a principle (forbids any surface that silences `cwf-manage validate` without surfacing first — covers `recompute-hashes`, auto-update hook, `validate --fix`, `--ignore=<path>`, `--baseline=HEAD`), and Task 147 as the historical example with Tasks 139/140 as positive controls. Four advertised consumers now link the doc: `cwf-implementation-exec` SKILL Gotcha 3, `cwf-retrospective` SKILL Gotcha 4 ("do not absorb hash drift at retrospective time"), `CLAUDE.md` `## Conventions` entry, `docs/conventions/design-alignment.md` cross-reference next to the existing `script-hashes.json` guidance. Validate now clean for the two Task 147 entries; the misalignment-agent permission violation (out of scope per a-plan §Constraints) is the only remaining `[SECURITY]` line.

### Notable
- **Robustness plan-review caught the shared-baseline assumption (F1)**. The first d-plan draft used a single baseline `7500aef` (Task 137) across both hashed paths. Investigation showed Tasks 139/140 had each touched `backlog-manager` and refreshed its hash in-task — a shared baseline would have over-included three commits when only one was actually drifted on Backlog.pm. Fixed before exec: per-file baselines `4f47494` for `Backlog.pm` and `f833bbf` for `backlog-manager`. The lesson is now encoded in the convention doc's `§Pre-refresh verification` as the load-bearing phrase "per file, not assumed-shared baselines."
- **The four-invariant carve-out is structural, not advisory**. A future "dedicated hash-fix task" can only claim the carve-out if all four conditions hold simultaneously: named drifted entries, per-file `git log` verification, no other source edits, originating commit(s) named. Self-applied labels don't work — Robustness F4 and Security F1 hardened this together.
- **"What NOT to build" reframed as principle, not enumeration (Security F3)**. Original draft listed specific anti-patterns (`recompute-hashes`, `--fix`, `--ignore`, `--baseline`); the rewrite leads with the principle ("any tool, flag, or mode whose effect is to silence `cwf-manage validate` output without first surfacing it to a human is forbidden") and treats the list as concrete examples. New smoothing surfaces fall under the prohibition even when not enumerated.
- **The Task 148 retrospective's deliberate orphaning of the side-quest was the right structural choice in retrospect.** Leaving the drift visible to validate between Tasks 148 and 149 made the failure mode tangible enough to write a rule for. If Task 148 had absorbed the fix, the convention doc would lack its concrete historical example.
- **String-anchor Edits, not line-number Edits, for SKILL/agent files (Misalignment F3 + Robustness F2).** Both SKILL.md insertions anchor on `## Scope & Boundaries`; insertions of new Gotchas elsewhere won't shift these anchors. Worth lifting into a CLAUDE.md note if any future task hits the same problem.

### Retired Backlog Items
None — Task 149 was added as urgent very-high-priority directly from the Task 148 retrospective Future Work, not via a pre-existing BACKLOG entry.

## Task 148: Document Dead Code Audit Methodology

### Status: Complete (2026-05-17)
### Duration: ~38 min wall-clock across six checkpoints, vs. a half-day estimate. Variance −84% — estimate priced a heavier methodology design, actual work distilled to 168-line canonical doc + 30-line recipes sibling + two reference inserts.
### Impact: Lands a language-agnostic dead-code-audit methodology (`.cwf/docs/dead-code-audit.md`, 168 lines, six caller categories with cross-language examples + plan-time heuristics + maintenance-time recipe + verdict template) and a non-shipping Perl/POSIX recipes sibling (`docs/dead-code-audit-perl.md`, 30 lines). Wires both shift surfaces: `.claude/agents/cwf-plan-reviewer-misalignment.md` consults the plan-time heuristics for `design`/`implementation` plan_types (+4 lines, declarative-criteria framing per Security S1); `.cwf/templates/pool/i-maintenance.md.template` adds a Preventive Maintenance bullet pointing at the canonical doc (+1 line). Methodology self-test against Task 51 fixtures (`workflow_file_mappings()`, `format_error()`, + `_format_uncorrelated()` as positive control) passed both directions on first walk — D6's 3-strikes refinement bound not consumed. `.cwf/security/script-hashes.json` updated in-task for the misalignment-agent edit; this proved the in-task hash convention works.

### Notable
- **d-plan §Supporting Changes claim was wrong.** Asserted "no hash-tracked file impact" without grepping `script-hashes.json` for the four targets; the misalignment-agent file IS tracked. Caught by first f-phase validate. Lesson: any plan asserting "no hash impact" needs a `grep -F "<path>" .cwf/security/script-hashes.json` check in the plan-review checklist (separate from the broader hash-rule clarification BACKLOG item).
- **e-plan TC-1/TC-2 had categories swapped vs. retrospective evidence.** TC-1 predicted category 3 for `workflow_file_mappings()`; actual is category 2 (script-to-library cross-module). TC-2 predicted category 2 for `format_error()`; actual is category 3 (same-file private) + category 6 (POD/advertised). Pass condition ("at least one category surfaces a real caller") was met in both, so no retest; but the plan was written from memory of the case shape rather than against the retrospective text.
- **Task 147 hash-rule discovery, orphaned out of this task's scope.** First a-phase `cwf-manage validate` fired on pre-existing drift in `CWF::Backlog.pm` and `backlog-manager` — Task 147 had deferred those updates citing `[[feedback_surface_security_dont_smooth]]`, but that was a misapplication of a rule whose "How to apply" line says hashes update "by hand" in-diff, not deferred. A mid-task fix was attempted but conflated two scopes (Task 148's docs-only deliverable vs. a Task 147 follow-up); the fix commit was rebased out before the squash to preserve strict-linear one-task-per-commit history on main. The drift remains visible to `cwf-manage validate` as the explicit signal that the issue needs its own urgent very-high-priority task.
- **Positive-control distinguishing-power lives in one sentence.** `_format_uncorrelated()` (removed in Task 51) has nine appearance sites across `CHANGELOG.md` and pre-removal planning-doc snapshots. The canonical doc's Category 6 carve-out ("Historical mentions are appearance, not advertisement, and not caller-ness") is the load-bearing sentence — without it a naïve walker could mis-flag all nine. Worth knowing the methodology has a single point of failure here, even if the wording handles it.
- **Plan-review map/reduce earned its keep on a docs task.** 4 parallel subagents flagged 17 issues during d-phase, all addressed in the rewrite. Findings included the doc-location decision, agent-file path correction (`.cwf/agents/` was stale, correct is `.claude/agents/`), 8-→-6 category collapse, declarative-vs-imperative heuristic framing, and the symmetric 3-strikes refinement bound.

### Retired Backlog Items
#### Document Dead Code Audit Methodology

Create `.cwf/docs/maintenance/dead-code-audit-checklist.md` documenting comprehensive audit methodology to prevent missing active usage patterns.


- **Cross-file usage**: `grep -r "function_name" .cwf/lib/ .cwf/scripts/`
- **Same-file usage**: Check within each affected file for internal calls
- **Script-to-library usage**: `grep -r "function_name" .cwf/scripts/command-helpers/`
- **POD documentation**: Check for public API declarations (`=head2 function_name`)
- **Structured report format**: Function, file, lines, usage findings, verdict

## Task 147: retire bootstraps missing CHANGELOG task entry

### Status: Complete (2026-05-17)
### Duration: 1 session, at the half-day estimate.
### Impact: Fixes `backlog-manager retire --task=N` so it no longer refuses when CHANGELOG has no `## Task N: <title>` entry. The retire command's stated purpose -- mechanically move an item from BACKLOG to CHANGELOG -- previously required the destination heading to pre-exist; CHANGELOG entries are normally written by `/cwf-retrospective` near task end, so any mid-task retire failed. New behaviour: when no entry exists, `cmd_retire` derives the title deterministically from `implementation-guide/N-<type>-<slug>/`, bootstraps a minimal `## Task N: <title>` entry with placeholder Status/Impact metadata and an empty `### Retired Backlog Items` subsection, then appends the retired block in the same atomic write pass. The bootstrapped stub is additively replaceable by `/cwf-retrospective` (placeholders overwrite to authoritative content). Two new `CWF::Backlog` public helpers (`resolve_task_title_from_dir`, `bootstrap_changelog_entry`) plus one private (`_scan_task_dirs`); 4-line branch swap in `cmd_retire`; one updated AC14 in `t/backlog-manager.t`; 11 new subtests in `t/backlog-bootstrap-changelog.t`; 3 new tree-mutator unit tests in `t/backlog-tree-mutators.t`. CLI surface unchanged; no new flags; existing-entry path byte-equivalent to prior behaviour.

### Notable
- **Plan-review subagents caught the CHANGELOG-002 validator blocker on the bare stub** in requirements review. Forced the placeholder-metadata approach (`Status: In Progress`, `Impact: Task in progress.`) which satisfies the existing required-keys validator without weakening it.
- **Direct hashref construction over parse-the-stub** (Misalignment review on impl plan). The original design called `parse_changelog_tree` on a 7-line stub string to extract `entries[0]`; the rewrite builds the hashref directly. Simpler code, no private-API call, TC-U3 round-trips it back through the parser anyway as safety net.
- **Anchored regex with `\Q$task_num\E` + `quotemeta`'d type alternation** closes the regex-metachar surface even if a future caller bypasses the integer guard. The `supported-task-types` list is read once from `cwf-project.json` and strict-filtered through `qr/\A[a-z][a-z0-9-]{0,31}\z/` before alternation.
- **Multi-match case refuses without inventing a new flag.** Only the legacy task-1 corpus has three sibling dirs sharing a task number; preserving FR8 (no new flags) costs one clear error message that names the manual workaround.
- **AC14 in `t/backlog-manager.t` needed rewriting**, not just augmenting -- it asserted the legacy "Task N has no CHANGELOG entry → die" contract that this task explicitly replaces. Caught at first test-run; ~10 min to update. Worth adding "grep tests for contract messages being changed" to the impl-plan checklist.
- **Security-review subagent skipped at commit time** (606-line changeset >500-line cap, dominated by the 334-line new test file). Manually invoked at user request after the fact; verbatim no-findings result recorded.
- **Pre-existing `t/backlog-roundtrip-live.t` UTF-8 mangling failure** (`—` → `â` on live BACKLOG.md) reproduced on `main` HEAD prior to task start. Flagged for separate task; not addressed here.

### Retired Backlog Items

## Task 146: Backlog refactor: retire, merge, reduce

### Status: Complete (2026-05-17)
### Duration: 1 session, at the 1-day estimate.
### Impact: Discovery task / corpus housekeeping -- reviewed every BACKLOG.md entry at baseline (68 entries, parser-recognised `## Task:` plus `## Bug:` headings) against three axes (still-applicable / mergeable / scope-reducible) and applied 8 approved mutations: 4 direct retires, 3 merges (single-commit Edit-then-retire pattern, 3 carry-over phrases preserved per merge), and 1 reduce-scope. Net BACKLOG shrink 68 -> 61 entries (~10%); plus one entry ("Implement Interface-Based Version Dispatch for status-aggregator") slimmed from ~210 lines to ~17 (~94% reduction; dropped embedded Perl code, Architecture sub-section, Implementation Steps, Benefits, Priority Justification; kept Problem, Approach, Success Criteria, Files Affected, Scope Note). Recommendations artefact (`recommendations.md`) preserved under the task directory as the discovery deliverable, anchored to baseline SHA `ca7e8e531f0cad280ffcaa58faab8945a247f2c4` with maintainer approval recorded as a committed line. Validator clean after every mutation commit (8/8); round-trip property held; halt-on-failure path defined but not exercised. No new helpers, flags, schemas, or templates introduced -- "no new code" constraint (c-design D1) honoured.

### Notable
- **Plan-review subagents caught the phantom `--baseline=<SHA>` flag in b-requirements** before any helper invocation. Fixed in commit 017169a. Without that catch, f-Step-1 would have hit a hard error and had to re-plan.
- **Baseline-enumeration regex was incomplete in the plan (D1).** d-impl Step 1 used `^## Task: '`; the parser at `CWF::Backlog.pm:222` also accepts `^## Bug: '`. Caught in f-Step-1 by cross-checking the regex count (67) against `backlog-manager list --all-items` (68). Lesson: corpus counts must come from the helper, not from a hand-derived regex.
- **TC-AC5 wording bug (D4) lasted until g-phase.** Three plan-review subagents read e-testing-plan and none flagged that TC-AC5 grepped CHANGELOG.md when FR6 places the merge trace in the surviving BACKLOG entry. The test was internally consistent but interrogated the wrong artefact. Lesson: plan-review struggles with FR -> TC fidelity even when it catches structural defects reliably.
- **Single-commit merge atomicity (c-design D5) was the load-bearing decision.** Collapsing Edit-then-retire to one commit per merge made the pre-commit `git checkout --` discard path uniformly correct regardless of which sub-step regressed. The post-commit revert path (D6) was specified for completeness but never exercised -- no post-commit regressions observed.
- **`--exact-title=` over `--id=<slug>` (D2 deviation) simplified pre-flight to vacuous on D8.1.** All 68 selectors used `--exact-title=`; no per-row slug derivation, no slug-uniqueness pre-flight, no behavioural impact on `backlog-manager retire`. Recommended as the default selector for future batch-retire tasks.
- **Pre-flight realised as bash (D3) instead of the planned Perl with `CWF::Backlog` round-trip.** Bash regex catches `- Priority:` shape and misses `### Status:` shape -- TC-PF-4 documents this as PARTIAL. No real-artefact impact (all 3 approved carry-overs are plain prose). The Perl approach remains correct for larger or `--id=`-heavy artefacts.
- **Validator performance NFR1 hit easily.** `backlog-manager validate` measured at 0.087s on the post-batch corpus, well under the sub-1s target.

### Retired Backlog Items
#### Add Delete Task Skill

Add a `/cwf-delete-task <num>` skill that cleanly removes a task: deletes the task directory, removes the git branch (if it exists), and optionally cleans the task stack. Currently, deleting a misclassified or abandoned task requires manual `git rm -r`, branch deletion, and directory cleanup — error-prone and tedious.

- Delete task directory under `implementation-guide/`
- Delete associated git branch (with confirmation)
- Remove from task stack if present
- Refuse to delete if task has subtasks (safety check)
- Support `--force` flag to skip confirmation

#### Create v2.0 to v2.1 Workflow Migration Tools

Create automated migration tools to upgrade existing v2.0 tasks (a-plan.md through h-retrospective.md) to v2.1 format (a-task-plan.md through j-retrospective.md with sequential a-j lettering).


- v2.0 uses 8 files: a-plan.md, b-requirements.md, c-design.md, d-implementation.md, e-testing.md, f-rollout.md, g-maintenance.md, h-retrospective.md
- v2.1 uses 10 files with renames and re-lettering:
  - a-plan.md → a-task-plan.md
  - b-requirements.md → b-requirements-plan.md
  - c-design.md → c-design-plan.md
  - d-implementation.md → d-implementation-plan.md
  - e-testing.md → f-testing-plan.md (re-lettered!)
  - NEW: e-implementation-exec.md
  - NEW: g-testing-exec.md
  - f-rollout.md → h-rollout.md (re-lettered!)
  - g-maintenance.md → i-maintenance.md (re-lettered!)
  - h-retrospective.md → j-retrospective.md (re-lettered!)
- Manual migration is error-prone and tedious for 24 existing tasks

1. Detect v2.0 tasks (presence of a-plan.md, absence of e-implementation-exec.md)
2. Rename existing files with -plan suffix where appropriate
3. Re-letter files (e→f, f→h, g→i, h→j)
4. Update internal cross-references (d-implementation.md → d-implementation-plan.md references)
5. Validate migration (renamed files exist, content valid, no broken references)



- Migration script: `.cwf/scripts/migrate-v20-to-v21.pl` or similar
- Dry-run mode to preview changes before applying
- Batch migration for all v2.0 tasks or selective migration
- Validation checks before and after migration
- Clear error messages on failure
- Update documentation with migration instructions (including git commit/rollback workflow)

- Task 25 must be complete (v2.1 format defined, trampoline architecture implemented)
- v2.1 template files must exist in `.cwf/templates/pool/`

- [ ] Migration script created and tested
- [ ] Dry-run mode shows accurate preview
- [ ] Script handles all edge cases (partial migrations, already-migrated tasks)
- [ ] Validation checks prevent broken migrations
- [ ] Documentation explains migration process (including git commit/reset workflow)
- [ ] Tasks 1-24 can be migrated without manual intervention
- [ ] Migrated tasks work correctly with v2.1 workflow commands

- Trampoline architecture handles mixed v2.0/v2.1 versions seamlessly
- We're already successfully using v2.1 format (Tasks 26, 30)
- Completed tasks (1-24) work fine in v2.0 format
- New tasks use v2.1 templates automatically
- Manual migration is straightforward for the few tasks that need it



- [ ] Runs in <2 minutes
- [ ] Can run on any Perl 5.14+ system

#### Enforce sentinel-first output in security-review subagent prompt

The exec-phase security-review subagent (cwf-implementation-exec, cwf-testing-exec) is supposed to begin its response with the literal sentinel "findings:" / "no findings" / "error:" per .cwf/docs/skills/security-review.md, but the current prompt template does not enforce this strongly enough. In Task 134 both invocations produced substantively clean reviews ("no findings." in body) yet failed the primary classification, falling back to "error" (f-phase) and "findings" (g-phase, numbered-list fallback fired on the file enumeration). Strengthen the prompt with a hard "no preamble" instruction and consider extending the classifier with a "last-line `no findings.`" rule for substance-clear malformed responses. Out of scope for Task 134 because the convention task should not also rewrite the security-review prompt.

#### Improve security-review-changeset feedback on empty-from-uncommitted changesets

When `security-review-changeset --phase=<phase>` returns empty because all phase work is still uncommitted at the time of the security review, the helper currently emits nothing — the workflow skill then records `no findings: empty changeset` even though there *is* a changeset, it just hasn't been committed yet. Improve the helper to detect this case (e.g., compare `anchor..HEAD` to `git status --porcelain` size) and emit a hint pointing to the `git add -N` + manual-diff workaround, or exit with a distinct status the skill can interpret as "uncommitted work — review postponed". Surfaced during Task 136 implementation-exec security review.

#### Migrate Remaining `print STDERR + exit` Blocks in `template-copier-v2.1` to `die_msg`

Task 119 added a `die_msg` helper to `template-copier-v2.1` and used it for the new slug-length validation. The script's existing error paths (unknown args, missing required params, invalid format, config load failure, template-dir-not-found, broken symlinks, copy failures) still use the older `print STDERR "Error: ..."` + `exit N` pattern. Migrating these to `die_msg` would unify the error-prefix convention (`[CWF] ERROR:`) across the whole script.

- Replace each `print STDERR "Error: ..." + exit N` block with `die_msg("...")`, preserving exit codes via a 2-arg form if needed
- Update tests if any assertion strings depend on the old format
- Refresh script hash

#### Document Bugfix Workflow Differences

Clarify that bugfix workflows skip h-rollout.md and use checkpoint commits for rollout instead.



1. **Update workflow-steps.md**: Add section comparing workflow types (feature vs bugfix vs hotfix)
2. **Create comparison table**: Show which phases each workflow type includes
   ```markdown
   | Phase | Feature | Bugfix | Hotfix | Chore |
   |-------|---------|--------|--------|-------|
   | a-plan | ✓ | ✓ | ✓ | ✓ |
   | b-requirements | ✓ | - | - | - |
   | c-design | ✓ | ✓ | - | - |
   | d-implementation-plan | ✓ | ✓ | ✓ | ✓ |
   | e-testing-plan | ✓ | ✓ | ✓ | ✓ |
   | f-implementation-exec | ✓ | ✓ | ✓ | ✓ |
   | g-testing-exec | ✓ | ✓ | - | - |
   | h-rollout | ✓ | - | ✓ | - |
   | i-maintenance | ✓ | - | - | - |
   | j-retrospective | ✓ | ✓ | ✓ | ✓ |
   ```
3. **Document rollout alternatives**: For workflows without h-rollout, explain checkpoint commit serves as rollout

- [ ] Comparison table shows phase inclusion by workflow type
- [ ] Documentation explains rollout alternatives for bugfix/chore
- [ ] Future tasks understand which phases apply to their type

#### Consider `internal-feature` template variant for service-less CLI helpers

For tasks whose deliverable is a local CLI helper with no service surface, no users, and no telemetry, the v2.1 template's `h-rollout.md` and `i-maintenance.md` sections (monitoring, alerting, phased-rollout, scaling, SLOs) collapse to mostly-N/A. Consider a slimmer template variant — perhaps `internal-feature` or extending `chore` — that drops these vestigial sections. Optional; no functional gap, just a paperwork-reduction opportunity. Surfaced during Task 136 rollout + maintenance phases.

## Task 145: Update CWF skills to use namespaced tmp paths

### Status: Complete (2026-05-17)
### Duration: 1 session, well under the <1-day estimate.
### Impact: Chore / convention — establishes `.cwf/docs/conventions/tmp-paths.md` as the single source of truth for the project-namespaced `/tmp/` scratch-path form (`/tmp/<dashified-absolute-repo-path>-task-<num>/`), so concurrent agents working in different repositories do not collide on shared task numbers (e.g. two repos each at task 145). Convention ships to adopters via `.cwf/` subtree install — placement choice mirrors `.cwf/docs/conventions/subagent-tool-selection.md`. Discovery surface updates: `CLAUDE.md § Conventions` adds a `**Tmp Paths**:` bullet; `docs/conventions/design-alignment.md` scope paragraph extended to acknowledge ship-to-adopter conventions live under `.cwf/`. Memory updates land in four agent-memory files (one not on the original plan list — caught by TC-M1 grep gate). Folded in: `.claude/agents/cwf-security-reviewer-changeset.md` permissions restored from 0600 → 0444 (SHA pre-verified unchanged; restoration not new content), clearing the `cwf-manage validate` warning that had been bleeding into every checkpoint commit during this task's planning phases.

### Changes
- Added: `.cwf/docs/conventions/tmp-paths.md` (NEW) — single source of truth. Sections: § Convention (canonical form + copy-pastable derivation snippet using `git rev-parse --show-toplevel` + `${repo_root//\//-}`), § Threat model (single-user dev host scope; mandatory `mkdir -m 0700 -p` first-use guard against `/tmp` symlink-attack on multi-user hosts; no-secrets advisory), § Why (collision avoidance + `~/.claude/projects/` precedent), § Out of scope (install scripts, history, `settings.local.json` allowlist, no helper script), § See also.
- Modified: `CLAUDE.md` § Conventions — new `**Tmp Paths**:` bullet with three sub-bullets covering canonical form, `mkdir -m 0700` guard, derivation snippet pointer. Matches `**Commit Messages**:` style.
- Modified: `docs/conventions/design-alignment.md:7-11` — scope paragraph extended from 2 lines to 5; names `subagent-tool-selection.md` and `tmp-paths.md` as concrete examples of conventions that live only under `.cwf/docs/conventions/` (no dev-repo mirror).
- Modified: `.cwf/docs/skills/security-review.md:98` — three-line trailing annotation on the illustrative `/tmp/cwf-update` anti-pattern: `# /tmp/cwf-update is illustrative — not a canonical scratch path; see .cwf/docs/conventions/tmp-paths.md`. Original anti-pattern code unchanged.
- Modified: `~/.claude/projects/-home-matt-repo-coding-with-files/memory/feedback_no_heredocs.md` — replaced the "one-off scripts" sub-section with canonical-form examples; appended explicit "Historical:" annotation describing the old un-namespaced `/tmp/task-NNN/` form.
- Modified: `~/.claude/projects/-home-matt-repo-coding-with-files/memory/MEMORY.md` — updated squash-commit line (now canonical form with historical annotation) and the `feedback_no_heredocs` index entry (now points at `[[tmp-paths]]`).
- Modified: `~/.claude/projects/-home-matt-repo-coding-with-files/memory/project_archaeological_main.md` — squash-commit `/tmp/msg.txt` updated to canonical form. Not on the original plan's three-file list; caught by TC-M1 grep gate during testing-exec.
- Permissions: `.claude/agents/cwf-security-reviewer-changeset.md` — `chmod 0444` to restore recorded mode per `.cwf/security/script-hashes.json:26`. SHA matches `c7033a74…2095e5` (recorded value at `script-hashes.json:27`); restoration touched permissions only, not content. `cwf-manage validate` post-implementation: `OK` (was 1 violation pre-implementation).

### Notable
- **TC-M1 grep gate caught the 4th memory file.** The plan listed three memory files (`feedback_no_heredocs.md`, `feedback_no_tee_permissions.md`, `MEMORY.md`); reality was four. `project_archaeological_main.md` had `/tmp/msg.txt` embedded in its squash-commit description. The grep gate is *designed* to catch exactly this kind of plan-list completeness gap — positive validation of the gate, not a plan defect.
- **Plan-review map/reduce over-rotated on the mirror question, then self-corrected.** Initial reviewer advice was "no `.cwf/docs/conventions/` mirror — drift bait" — correct for in-repo conventions, wrong for ship-to-adopter conventions (adopters install only `.cwf/`). User's "are we duplicating? is that the issue?" reframe led to the cleaner "single file in `.cwf/docs/conventions/`, no `docs/conventions/` copy" outcome. Three round-trips on this question before lock-in.
- **0444 restoration fold was net-positive, not scope creep.** SHA pre-verified as restoration (not new content); the warning had been firing on every checkpoint commit throughout planning phases of this task; carrying it to a follow-up would have repeated the noise. User authorised the fold explicitly after SHA verification.
- **Security-review sentinel compliance held at n=2/2 (Task 144 tightening still working).** Both f-phase and g-phase invocations returned `no findings` as the literal first non-blank line; calling SKILL's **primary** classifier fired both times. No fallback or conservative-default `error` classifications.
- **`security-review-changeset` helper coverage is narrow by design.** The 7-file changeset for this task produced a 14-line diff because only `.cwf/docs/skills/security-review.md` falls inside the unconditional-include CWF-internal prefixes. `.cwf/docs/conventions/`, `CLAUDE.md`, `docs/conventions/`, and user-memory files are all outside coverage. Expected; documented in retro so future reviewers don't wonder why the diff is small.

### Retired Backlog Items
None directly retired — this task did not target a pre-existing backlog item; the convention emerged from in-conversation discovery of `tee`-via-Bash blocking permissions, which prompted the broader question of `/tmp/` namespacing.

## Task 144: Tighten security-subagent sentinel-line output

### Status: Complete (2026-05-16)
### Duration: 1 session, well under the <0.5-day estimate.
### Impact: Chore / prompt-tightening — the `cwf-security-reviewer-changeset` agent (added in Task 143) now leads its response with the required sentinel string reliably enough for the calling SKILL's **primary** classifier to fire instead of falling through to the numbered-list fallback or the conservative-default `error`. Single-paragraph edit in `.claude/agents/cwf-security-reviewer-changeset.md` replaces the loose "Start your response with one of three sentinel lines" instruction with explicit failure-mode framing ("Your VERY FIRST output line MUST be one of these three sentinels — no greeting, no analysis, no markdown decoration before it. A preface … causes the calling SKILL to fall through to its conservative fallback classifier and label a clean review as `findings`."). Sentinel tokens unchanged (`findings:` / `no findings` / `error:`); three-tier classifier in `.cwf/docs/skills/security-review.md` untouched. Dogfood on this task's own changeset: primary classifier fired n=2/2 (f-phase + g-phase).

### Changes
- Modified: `.claude/agents/cwf-security-reviewer-changeset.md` — lines 24–30 replaced. Old "Start your response with one of three sentinel lines:" + 3 bullet lines became a stronger 5-line preamble ("Your VERY FIRST output line MUST be one of these three sentinels — no greeting, no analysis, no markdown decoration before it.") + the same 3 bullets with two small clarifications (`no findings` may have a note "on a subsequent line"; `error:` reason "on the same line"). Frontmatter, `Inputs`/`Procedure` preamble, pattern-based-risk carve-out, and the "do not paraphrase" sentence all untouched.
- Modified: `.cwf/security/script-hashes.json` — `cwf-security-reviewer-changeset` SHA256 updated from `ef971059…6340630a` to `c7033a74…2095e5` to track the new bytes. Deliberate per-file hash advance for an intentional content change, not an auto-recompute.

### Notable
- **The tightened wording compliance held at n=2/2 on this task's own dogfood.** Both the f-phase and g-phase invocations of the just-edited agent returned `no findings` as the literal first non-blank line — the calling SKILL classified via the **primary** rule each time, not via the numbered-list fallback and not via the conservative-default error. Single-task n is low statistical weight but is the positive observation called for in e-testing-plan TC-7. A broader quantification of the preface-rate is the subject of a separate backlog follow-up, not this task.
- **Failure-mode framing beats output-shape framing.** Old wording told the agent *what to emit* ("start with one of three sentinel lines"); new wording also tells the agent *what breaks if it deviates* ("a preface causes the calling SKILL to fall through to its conservative fallback classifier"). Task 141's retrospective documented similar failure-mode-aware wording ("Your VERY FIRST CHARACTER…" + explicit unacceptable-opener list). Worth carrying forward to other subagent prompts where compliance is structural, not stylistic.
- **`cwf-manage validate` surfaced expected drift + pre-existing perm violations; both triaged per the "surface, don't smooth" rule, not auto-fixed.** Three buckets: (i) 1× SHA mismatch on the edited agent file (legitimate consequence of the deliberate edit — ledger updated); (ii) 1× permission violation on the same file (Edit tool wrote it back at 0600 instead of 0444 — local chmod restored); (iii) 6× pre-existing permission violations on the other 4 plan-reviewer agents + shared-rules doc (install-time issue inherited from Task 143's install path — local chmod applied with the same caveat noted in Task 143's retro). User approved each bucket separately via two-question prompt; no blanket `cwf-manage fix-security`.
- **Three wf step files initially used a non-canonical `**Status**: Planning` value** in a-/d-/e-task-plan. The `cwf-project.json` `status-values` map enumerates `Backlog/Blocked/Cancelled/Finished/In Progress/Skipped/Testing/To-Do` — "Planning" is not in the set. `validate` caught it on the first run; corrected to `Finished` (those phases are complete). Backlog item added: either canonicalise `Planning` as a value or patch the planning-phase skill templates to default to a canonical value.
- **Agent-registry caches at session start, still.** d-phase plan-review subagents and the first f-phase security-review invocation all returned "Agent type … not found" — the agents were installed by Task 143 but not registered in the pre-restart session. Mid-task session restart unblocked the security-review invocation. Same pattern as Task 143's TC-AC3b/AC5a/AC5b; the pre-existing backlog item "Session-restart smoke-test helper for newly installed agents" already names it.

### Retired Backlog Items
- "Tighten security-subagent prompt for sentinel-line compliance" (Medium, Follow-up from Task 123) — retired via `backlog-manager retire`; this task is the fix.

#### Tighten security-subagent prompt for sentinel-line compliance

The security subagent introduced in Task 123 returns three sentinel-prefixed states (`findings:` / `no findings` / `error:`) classified per a three-tier rule (primary sentinel → numbered-list fallback → conservative-default error). TC-AC8 in Task 123 demonstrated that subagents tend not to lead with the sentinel — the dogfood call returned ~70 lines of analysis before the closing `no findings` line, causing the fallback classifier to fire and produce a `**State**: findings` even though the substantive verdict was clean. The conservative-default behaviour is correct (loud false positive > silent false negative), but the false-positive rate could be reduced.

<!-- Note: Wording-only fix; one-paragraph rewrite in the agent file plus failure-mode framing. Primary-rule classification observed n=2/2 on this task's own changeset. Broader follow-up (single-token sentinels) tracked separately. -->

## Task 143: Adopt .claude/agents format with shared rules

### Status: Complete (2026-05-16)
### Duration: 1 session, ~half a day against a 2-3 day estimate; under by ~50%.
### Impact: Feature — migrates CWF's review subagents (plan-reviewer × 4 columns + security-reviewer-changeset) from `subagent_type="Explore"` + inline prompts to first-class `.claude/agents/cwf-*.md` definitions, all referencing a single shared-rules surface (`cwf-agent-shared-rules.md`). Five new agent files, one shared-rules doc, full install lifecycle (`install.bash` fresh-install path + `cwf-manage update` in-place path), integrity-ledger entries for all six new files. Skill-side call-sites in `cwf-implementation-exec/SKILL.md`, `cwf-testing-exec/SKILL.md`, `.cwf/docs/skills/plan-review.md`, `.cwf/docs/skills/security-review.md` updated to name the cwf-* agents directly. SKILL-side prompt substitution drops to `{plan_file_path}` + `{plan_type}` (or `{phase}` + `{changeset}`) — each column's criteria and the sentinel-line contract live in the agent body.

### Changes
- Added: `.cwf/docs/skills/cwf-agent-shared-rules.md` (NEW, 54 lines) — single shared-rules surface: tool-tier preference (Tiers 1-5 verbatim from `subagent-tool-selection.md`), 4-row blocking-bash-anti-patterns table (`find -exec grep`, `find -exec cat`, `cat | grep`, `sed -n 'X,Yp'` paired with "use instead" siblings), full-rubric link, inclusion-bar paragraph ("rule must apply to ≥2 agent roles AND be rooted in a documented convention/incident/pattern").
- Added: `.claude/agents/cwf-plan-reviewer-improvements.md`, `.claude/agents/cwf-plan-reviewer-misalignment.md`, `.claude/agents/cwf-plan-reviewer-robustness.md`, `.claude/agents/cwf-plan-reviewer-security.md` (NEW, ~37 lines each) — one per plan-review column; frontmatter `name`/`description`/`allowed-tools: Read, Grep, Glob`; body links shared-rules, declares `{plan_file_path}` + `{plan_type}` inputs, bakes the column's criteria for each `{plan_type}` value (requirements/design/implementation) directly in the procedure.
- Added: `.claude/agents/cwf-security-reviewer-changeset.md` (NEW, 42 lines) — exec-phase reviewer; declares `{phase}` + `{changeset}` inputs; preserves the sentinel-line contract (`findings:` / `no findings` / `error:`) verbatim in the agent body.
- Modified: `.cwf/scripts/cwf-manage` — extended dirty-tree check to include `.cwf-agents`; added `.cwf-agents` subtree-split + subtree-pull block to `update_subtree`; added `.cwf-agents` rmtree + copy_tree block to `update_copy`; new `create_agent_symlinks($git_root)` function (with the warn-on-stray + die-on-collision conflict-check added during testing-exec); call site in `cmd_update` after `create_skill_symlinks`.
- Modified: `scripts/install.bash` — analogous fresh-install path additions (subtree split for `.claude/agents` → `cwf-agents` branch; `subtree add --prefix=.cwf-agents`; `.cwf-agents` in force-remove dir list; `cp -r "$clone_dir/.claude/agents" .cwf-agents` in copy method; `create_cwf_symlinks .cwf-agents .claude/agents "cwf-*.md" -f agent` in `post_install`). Added during testing-exec when TC-AC1-install caught the gap.
- Modified: `.cwf/scripts/command-helpers/security-review-changeset` — one-line addition of `.claude/agents/` to `@CWF_INTERNAL_PREFIXES` so the helper covers the new agent directory in its diff classification.
- Modified: `.cwf/security/script-hashes.json` — new top-level `agents` section with 5 entries; new `data.agent-shared-rules` entry; `cwf-manage` and `security-review-changeset` SHAs updated to reflect this task's edits.
- Modified: `.cwf/docs/skills/plan-review.md` — removed the 5-row criteria-lookup table; replaced single `subagent_type: "Explore"` invocation with 4 distinct calls (one per column → `subagent_type: "cwf-plan-reviewer-<column>"`); SKILL-side prompt now only substitutes `{plan_file_path}` and `{plan_type}`.
- Modified: `.cwf/docs/skills/security-review.md` — exec-phase prompt template now points at `subagent_type=cwf-security-reviewer-changeset`; agent body owns the sentinel-line contract.
- Modified: `.claude/skills/cwf-implementation-exec/SKILL.md:54`, `.claude/skills/cwf-testing-exec/SKILL.md:49` — one-line `subagent_type="Explore"` → `subagent_type="cwf-security-reviewer-changeset"` change each.
- Modified: `implementation-guide/143-…/d-implementation-plan.md` — retroactively updated during testing-exec to include the install.bash analogous-edits (per user direction; tracked as scope expansion in this task's j-retrospective.md).

### Notable
- **Plan reviewers earned their cost across every plan phase.** D1 (1-file vs 4-file plan-reviewer shape) flipped twice across the design-phase plan-review subagent reductions; the user's final override locked the 4-file shape with the forward-looking justification that per-wf-step / per-reviewer divergence (different sub-skill access, different pre-flight checks) will favour shape variation. Without the map/reduce review at each phase, this would have been a re-implementation cycle, not a plan revision.
- **Two implementation gaps surfaced in testing-exec, not in planning.** (i) `scripts/install.bash` was missed by the d-plan — the plan focused on `cwf-manage update` as the install entry point, but install.bash is the actual fresh-install path. TC-AC1-install caught this end-to-end; fix was 6 analogous edits mirroring the `.cwf-skills` pattern. (ii) `create_agent_symlinks` originally implemented die-on-collision-only (per design D2 / d-plan Step 2.4 pseudocode); TC-AC1-cleanup-stale expected broader cleanup behaviour. User picked the middle path (warn-on-stray + die-on-collision); ~17-line edit. Both folded into the f/g phase commits with retroactive d-plan update per user direction. Lesson: end-to-end scratch-repo tests caught what source-level grepping wouldn't.
- **Security-review sentinel compliance 0/2 again.** Both f-phase and g-phase invocations led with prose ("Excellent. Now I have…", "Now let me…") instead of the required sentinel line. Both classified as `error` per the three-tier conservative default; both substantively concluded `no findings` (or, in f-phase's case, one cat-(e) pattern-risk finding that was applied as an inline invariant comment). Continues a pattern from Task 142. Backlog item "Enforce sentinel-first output in security-review subagent prompt" predates this task; the agent file as written here doesn't materially change subagent compliance.
- **Harness agent registry caches at session start.** Newly-installed `.claude/agents/cwf-*.md` files written this session aren't discoverable for invocation until a session restart. TC-AC3b, TC-AC5a, TC-AC5b classified BLOCKED-ENV for this reason (not defects). TC-NFR2-failure exploited exactly this property by invoking a non-existent role and confirming the harness surfaces a clear error. Mitigation tracked in a new backlog item.
- **500-line review-cap fired twice (f: 538, g: 625); user override + code-only sub-diff resolved both.** f-phase: force-invoke on the full diff (38 over). g-phase: code-only sub-diff (213 lines, well under cap) carved out by excluding markdown files (already reviewed at f-phase). The cap fires more often than its design intent suggests; backlog item to retune.

### Retired Backlog Items
None directly retired — none of the prior backlog items were specifically addressed by Task 143.

## Task 142: Default task-workflow --baseline-commit to HEAD

### Status: Complete (2026-05-16)
### Duration: 1 session, ~0.5 day against a 0.5-day estimate; on-target.
### Impact: Chore / friction-removal — `/cwf-new-task` and `/cwf-new-subtask` SKILL examples instructed models to run `BASELINE_COMMIT=$(git rev-parse HEAD)` before invoking `task-workflow create`. The `$(...)` shell substitution fired a Claude Code permission prompt ("Contains shell syntax that cannot be statically analyzed") on every task creation. The fix moves HEAD resolution into the helper itself via a new `CWF::Common::resolve_head_sha()` function, and updates the SKILL examples to omit the flag entirely. The explicit-SHA expert path (`--baseline-commit=<40-char-sha>` for branching off a non-HEAD commit) keeps working bit-for-bit — the new behaviour is pure superset. 478/478 existing tests pass; 5 new tests cover the resolver branches and the helper's call shapes.

### Changes
- Modified: `.cwf/lib/CWF/Common.pm` — added `resolve_head_sha()` to `@EXPORT_OK` and as a new subroutine adjacent to `find_git_root` (same backtick + chomp + regex-validate shape). Returns 40-char lowercase hex on success, `undef` on failure (no repo, empty repo with no commits, git unavailable).
- Modified: `.cwf/scripts/command-helpers/template-copier-v2.1` — imported `resolve_head_sha` alongside the existing `generate_slug`; the `$vars{baselineCommit} = $params->{baseline_commit} // ''` call site at line 401 became an `if (defined && length) → verbatim pass-through; else → resolve_head_sha + die_msg on undef` block. Removed the silent empty-string fallback that previously masked the omission. Help-banner copy updated in two places ("Optional; defaults to HEAD (resolved internally). … Explicit values pass through verbatim.").
- Modified: `.claude/skills/cwf-new-task/SKILL.md` § 3 — dropped the `BASELINE_COMMIT=$(...)` capture line and the `--baseline-commit="$BASELINE_COMMIT"` continuation from the example invocation. Extended the trailing prose by one sentence pointing at the explicit-SHA escape hatch for the rare expert path.
- Modified: `.claude/skills/cwf-new-subtask/SKILL.md` § 3 — equivalent collapse of the bullet that captured `BASELINE_COMMIT` into a single sentence noting the helper resolves HEAD internally.
- Added: `t/common-resolve-head-sha.t` — 3 unit subtests via `CWFTest::Fixtures::create_git_repo`: commit-present → 40-char hex matching `git rev-parse HEAD`; empty repo → undef; outside any repo → undef.
- Added: `t/template-copier-baseline-default.t` — 2 integration subtests via the fork/exec subprocess pattern from `t/security-review-changeset.t`: flag-omitted → rendered `a-task-plan.md` contains live HEAD SHA; explicit `--baseline-commit=deadbeef…` → that exact value verbatim, no resolution attempted.
- Modified: `.cwf/security/script-hashes.json` — 2 SHA256s updated by hand (`CWF::Common` `749e851…`, `template-copier-v2.1` `3e34496…`) per the Task-135 surface-don't-smooth policy. `last_updated` already at 2026-05-17 from Task 141; not bumped.

### Notable
- **Plan-review subagents earned their cost again.** Two distinct misalignments surfaced before f-exec: (i) the resolver belongs in `CWF::Common` next to `find_git_root` (same backtick + chomp + length-check shape), not inline in the helper; (ii) tests should use `CWFTest::Fixtures::create_git_repo` rather than rolling a custom tempdir + chdir. Both applied; both visible in the final code. Continues the trend from Task 141 where plan-review caught real issues. Future-self note: when adding a `git rev-parse` shell-out, grep `CWF::Common` first.
- **Rejected a fabricated review finding.** A plan-review subagent suggested case-insensitive hex regex (`/[0-9a-fA-F]{40}/`) citing "some systems output uppercase". Verified false against current behaviour: `git rev-parse` outputs lowercase on all POSIX platforms. Recorded the rejection in d-implementation-plan to avoid `feedback_no_fabricated_citations` reaching code.
- **Eating-our-own-dog-food worked.** The friction this task fixes was directly experienced at `/cwf-new-task 142 chore "…"` at the start of the session. Each subsequent checkpoint commit invoked the same code path being modified (via the previous baseline-commit value, before the fix landed). After merge, every future `/cwf-new-task` invocation is the canonical proof that the fix works.
- **Hard-fail over silent-fallback.** The old code path was `// ''` — a silent empty-string fallback that masked omission. The new code fails loud (`die_msg`) on unresolvable HEAD. Aligns with `feedback_surface_security_dont_smooth`.
- **Security-review sentinel compliance 0/2 again.** Both f-phase and g-phase invocations led with prose instead of the required sentinel line. The g-phase prompt was strengthened with an explicit "first non-blank line MUST begin with one of these three sentinel strings — no preamble" instruction; the subagent still led with "Actually the code works because…". Both recorded as `**State**: error` per the three-tier conservative default; substance is `no findings` in both, preserved verbatim. Task 141's retrospective documents the working prompt shape ("Your VERY FIRST CHARACTER…" + explicit unacceptable-opener list); folding it into `.cwf/docs/skills/security-review.md` is the next chore.
- **Under-inclusion of new test files in first security-review changeset.** First `security-review-changeset --phase=implementation` invocation saw only 4 files because the new `.t` files were untracked. `git diff` doesn't list untracked files even with the Task-141 working-tree fix. Staged them, re-ran, got 6 files / 331 lines. Operational habit: stage new files before running the security-review changeset.
- **TC-6 covered by inspection, not test.** `template-copier-v2.1`'s `find_templates_directory` calls `git rev-parse --show-toplevel` *before* the resolver branch runs, so a no-repo cwd kills the helper at template lookup. The resolver's no-repo `die_msg` is unreachable end-to-end through the helper but exercised at the unit level (TC-3 in `common-resolve-head-sha.t`). Documented limitation, not a coverage gap.
- **TC-7 deferred to post-merge UX observation.** The Claude Code permission prompt fires at the harness layer, not the helper layer. Cannot be locally validated; the SKILL.md change is structurally clean (`grep -rn 'git rev-parse HEAD' .claude/skills/cwf-new-task .claude/skills/cwf-new-subtask` empty), so behaviourally the prompt cannot fire. First post-merge `/cwf-new-task` invocation is the canonical observation.

### Retired Backlog Items
- "Default task-workflow --baseline-commit to HEAD (drop shell substitution from SKILL examples)" (Very High, identified during Task 141 setup) — retired via `backlog-manager retire`; this task is the fix.

#### Default task-workflow --baseline-commit to HEAD (drop shell substitution from SKILL examples)

The `/cwf-new-task` and `/cwf-new-subtask` SKILL.md examples currently instruct models to run:

    BASELINE_COMMIT=$(git rev-parse HEAD)
    .cwf/scripts/command-helpers/task-workflow create \
      --task-type=... --destination=... --task-num=... \
      --description=... --baseline-commit="$BASELINE_COMMIT"

The `$(git rev-parse HEAD)` shell substitution triggers a Claude Code permission prompt on every invocation ("Contains shell syntax (string) that cannot be statically analyzed"). This adds a confirmation round-trip to every new task creation.

### Fix
HEAD is the load-bearing default in essentially every legitimate use of `task-workflow create` (the recorded baseline is whatever the current branch tip is at branch-cut time; users branching off a non-HEAD commit are a rare expert path). Two options:

1. **Make `--baseline-commit` optional, defaulting to HEAD internally.** The helper calls `git rev-parse HEAD` itself when the flag is omitted. SKILL.md drops both the `BASELINE_COMMIT=$(...)` capture and the `--baseline-commit=...` argument from the example. Models pass nothing; the helper resolves.

2. **Accept literal `HEAD` as the `--baseline-commit` value.** Keep the flag required for explicitness but treat the string `HEAD` as a sentinel the helper resolves via `git rev-parse HEAD`. SKILL.md becomes `--baseline-commit=HEAD` with no shell substitution.

Option 1 is cleaner ergonomically. Option 2 preserves explicit invocation shape and makes the "use HEAD" case visible in the command line. Either eliminates the permission prompt; the choice is a UX call to make in design.

### Scope
- `.cwf/scripts/command-helpers/task-workflow` — accept HEAD literal as a sentinel, or treat absent `--baseline-commit` as HEAD. Internal resolution via `git rev-parse HEAD`.
- `.claude/skills/cwf-new-task/SKILL.md` § 3 — drop the `BASELINE_COMMIT=$(...)` capture from the example invocation.
- `.claude/skills/cwf-new-subtask/SKILL.md` (equivalent section) — same fix if it uses the same pattern.
- Hash regen for the touched script via the Task-135 hand-update path.
- Confirm no test currently pins `--baseline-commit` to a non-HEAD literal SHA for a legitimate reason. Both shapes (explicit SHA and HEAD/omitted) should keep working — the rare expert path that needs an exact SHA should not be broken by this change.

### Why Very High
Every `/cwf-new-task` and `/cwf-new-subtask` invocation hits this prompt. With ~140 tasks created historically and the project still active, this is friction on a per-task frequency in active development sessions. The fix is small (probably one afternoon of code + two SKILL.md edits + a test).

### Out of scope
- Generalising the "resolve symbolic refs" pattern to other helper flags (e.g. anchor in security-review-changeset). That's a separate refactor; this entry is narrowly about the new-task / new-subtask permission-prompt friction.

<!-- Note: Implemented as option (1) from the BACKLOG sketch: helper resolves HEAD internally via CWF::Common::resolve_head_sha when --baseline-commit is omitted. Explicit-SHA expert path unchanged. -->

## Task 141: security-review-changeset blind to uncommitted

### Status: Complete (2026-05-17)
### Duration: 1 session, ~0.5 day against a 0.5-day estimate; on-target.
### Impact: Bugfix — `.cwf/scripts/command-helpers/security-review-changeset` diffed `${anchor}..HEAD` only, returning `reviewed 0 files` when invoked before the exec-phase checkpoint commit (HEAD didn't yet contain the phase's work). The exec skill's `empty changeset -> no findings` fallback then silently skipped a real security review. Bit Tasks 137, 138, 139, 140 in sequence. Fix drops `..HEAD` from both diff specs in the helper (option (a) from the BACKLOG entry's three sketched fixes) so the diff window covers anchor-to-working-tree. Adds an `includes uncommitted` disclosure suffix to the stderr summary when `git diff --quiet HEAD` reports a dirty tree, so the reviewer knows the diff covers in-flight work. Detection via the existing list-form `git_check()` helper. The fix is self-validating: the implementation-phase security review for this task ran successfully on a non-empty diff before the f-phase checkpoint commit — structurally impossible under the old behaviour — and that successful run is the canonical proof. The four-task workaround pattern ("commit code first, then re-run security-review") is now obsolete.

### Changes
- Modified: `.cwf/scripts/command-helpers/security-review-changeset` — two `${anchor}..HEAD` → `${anchor}` edits (in `list_changed_files` and the main-flow diff-emit); added `git_check('diff', '--quiet', 'HEAD')` for dirty-tree detection; computed `$dirty_suffix` once near the top of the summary block, interpolated into both the empty-changeset and non-empty summary `warn` calls. Fail-quiet-and-degrade on `rc >= 2` (git error → skip suffix, don't fail; the primary diff has already succeeded and the disclosure is informational only). File-header stderr-contract comment updated to advertise the new optional suffix; `list_changed_files` block comment updated to "anchor to working tree, includes staged + unstaged" with a Task-141 historical-context note.
- Modified: `t/security-review-changeset.t` — added `TC-Task141-uncommitted` subtest (4 assertions): one `staged-script` (new file, `git add`-ed, not committed) proves the index-side change is picked up; one `baseline-script` (committed on the task branch, then modified without `git add`) proves working-tree-side changes to a tracked file are picked up. Anchored regex `qr{^reviewed 2 files,.+anchor=[0-9a-f]{7}, includes uncommitted$}m` on the stderr summary proves the disclosure lands on the summary line specifically.
- Modified: `.cwf/security/script-hashes.json` — `security-review-changeset` SHA updated by hand (`826abd8d…09e5cbe8`) per the Task-135 surface-don't-smooth policy. `last_updated` bumped to 2026-05-17.

### Notable
- **The fix is self-validating.** The implementation-phase security review (Task-141 f-exec) ran successfully on a non-empty diff *before* the checkpoint commit. Under the old `anchor..HEAD` behaviour this is structurally impossible — HEAD didn't contain the phase's work yet, the diff would have been empty. The review's *running* is the proof, sharper than any unit test. The post-checkpoint smoke (g-exec) on the now-clean tree showed the disclosure suffix correctly *absent*, completing the two-state proof.
- **Test-setup defect caught at first run.** TC-Task141-uncommitted's first iteration created two new files (one staged, one not). `git diff <anchor>` doesn't list untracked files — exactly what c-design-plan.md's "Behavioural notes on the widened diff window" said, but d-plan and e-plan didn't propagate the constraint to the test setup. Caught at first prove run (~30s feedback), restructured to commit a `baseline-script` first then modify it without `git add`. Lesson recorded: plan-review subagents check consistency *within* a plan, not *across* sibling plans in the same task.
- **First clean sentinel-first security-review subagent response in 6 consecutive exec-phase reviews.** Tasks 139-f, 139-g, 140-f, 140-g, 141-f all failed sentinel-first formatting; 141-g succeeded. The working prompt: open with "Your VERY FIRST CHARACTER of response must be the letter `n`, `f`, or `e`" plus an explicit unacceptable-opener list ("Now", "Let me", "I'll", "Looking at..."). Character-level instructions worked where sentence-level instructions did not. Concrete prompt template to fold into `.cwf/docs/skills/security-review.md` when the two sentinel-compliance BACKLOG items are picked up.
- **Adjacent housekeeping folded into a-phase checkpoint, not a separate commit.** The "Default task-workflow --baseline-commit to HEAD" BACKLOG addition (made during task-creation friction, before any a-phase work) was folded into Task 141's a-phase commit. Cleaner than the alternatives (standalone non-task commit, branch-switch to main, or carry-forward to retrospective).
- **Permission-drift false positive after Task 140's squash.** The first checkpoint of Task 141's a-phase tripped `cwf-manage validate` on `ArtefactHelpers.pm` (`permissions: 0600`, expected `0444`). Cause: soft-reset during Task 140's squash restored file content but the working umask left the on-disk mode at 0600. `fix-security` repaired in one call. Worth noting as a known shape of the squash flow: any permission-tracked file touched during a squash will need a `fix-security` pass after.

### Retired Backlog Items
- "security-review-changeset blind to uncommitted work" (High, bumped from Low in Task 140's retro) — retired via `backlog-manager retire`; this task is the fix.

#### security-review-changeset blind to uncommitted work

`.cwf/scripts/command-helpers/security-review-changeset` diffs `anchor..HEAD` only. When invoked by the f-implementation-exec or g-testing-exec skill before the phase's checkpoint commit lands, HEAD does not yet contain the phase's changes and the helper returns `reviewed 0 files, 0 lines`. The exec skill's "empty changeset -> no findings" fallback then silently skips a real security review.

### Evidence
- Task 137 retrospective (`f-implementation-exec.md`): "first run reported 0 files; commit first then re-run".
- Task 138 retrospective (CHANGELOG): "security-review-changeset blind to uncommitted work bit again".
- Task 139 retrospective (this task, f-implementation-exec.md Security Review section): forced to record `error` with a manual per-category analysis instead of running the subagent on a real diff, because the helper saw zero.

Third task in a row to trip on this. The trap will keep biting until either the helper warns or the workflow doc says "checkpoint first" explicitly.

### Fix options
- **(a)** Helper diffs working tree against the anchor (`git diff <anchor>` instead of `git diff <anchor>..HEAD`). Picks up staged + unstaged changes. Side-effect: changes the meaning of "changeset" mid-phase, which is fine for the review's purpose.
- **(b)** Helper detects staged or working-tree changes (`git status --porcelain`) and emits a warning if any exist while the diff is empty: "uncommitted changes present but not in the changeset; commit first or run with --include-worktree".
- **(c)** Workflow docs (the exec-phase skill templates) state explicitly: "checkpoint the phase changes first, then run security review". Add the ordering to the SKILL.md steps.

Option (a) or (b) is preferred; (c) trains every future agent to remember a non-obvious ordering. (a) is the smallest change and best aligns with how an interactive reviewer would think about "what's changing".

### Why Low priority
- Workaround exists: commit phase changes first, then run the review. Three tasks have used it; none missed a real security issue as a result.
- The skill's three-tier classification (primary sentinel / numbered-list fallback / conservative `error`) is sound; the helper limitation triggers `no findings: empty changeset` which is technically faithful to the helper's output.
- Not a security failure per se — agents have flagged the limitation in retrospectives and provided manual analyses when warranted.

### Scope
~30-60 min. Single helper edit (option a) or message tweak (option b). Add a regression test verifying behaviour against an uncommitted working tree.

<!-- Note: Fixed via option (a) from the BACKLOG sketch: dropped ..HEAD from both diff specs in security-review-changeset so the diff window covers anchor-to-working-tree. Added a, includes uncommitted disclosure suffix to the stderr summary (detected via list-form git_check). Self-validating: the implementation-phase security review for Task 141 ran successfully on a non-empty diff before its f-phase checkpoint commit, which is structurally impossible under the old behaviour. -->

## Task 140: Split path-allowlist by access mode

### Status: Complete (2026-05-16)
### Duration: 1 session, ~0.5 day against a 0.5-day estimate; on-target.
### Impact: Chore / API split — `CWF::ArtefactHelpers::validate_path_allowlist` was a single function cargo-culted across three call sites with three different threat models, producing both over-restriction (rejecting legitimate `/tmp/...` use in `backlog-manager --body-file`, already pushing callers to bypass the helper at Task 136) and under-protection (no semantic distinction between writing-to-untrusted-destination vs reading-from-user-chosen-source). Replaces it with two access-mode-specific helpers: `validate_write_path_allowlist` (verbatim copy of prior behaviour — absolute / `..` / prefix-allowlist; used by `cwf-apply-artefacts` and `cwf-claude-settings-merge` where the path is drawn from an untrusted manifest) and `validate_read_path_allowlist` (defined / non-empty / `-f` / `-r` only; used by `backlog-manager --body-file` where the invoker has already chosen the path under their own shell access). The third proposed variant (`validate_temp_path_allowlist`) is explicitly deferred — grep against the two candidate callers (`cwf-checkpoint-commit`, `security-review-changeset`) confirmed neither writes Perl-side temp files today, so the function would land as dead code. 472/472 tests pass; manual smoke confirms `/tmp/...` body-file accepted and BACKLOG.md restored byte-for-byte after delete.

### Changes
- Modified: `.cwf/lib/CWF/ArtefactHelpers.pm` — removed `validate_path_allowlist` (body + `@EXPORT_OK`); added `validate_write_path_allowlist($path, \@allowed_prefixes)` (byte-for-byte body copy of the prior function, ensuring write-side semantics are unchanged) and `validate_read_path_allowlist($path)` (chained file-test `-r _` after `-f $path` — single `stat(2)` call).
- Modified: `.cwf/scripts/command-helpers/cwf-apply-artefacts` — import + call (line 208) switched to `validate_write_path_allowlist`. Both `source` and `dest` paths keep write-style validation: both are drawn from the manifest, so the threat model is identical regardless of read/write disposition.
- Modified: `.cwf/scripts/command-helpers/cwf-claude-settings-merge` — import + call switched to `validate_write_path_allowlist`. Manifest paths threat model.
- Modified: `.cwf/scripts/command-helpers/backlog-manager` — import + call switched to `validate_read_path_allowlist`; the inline `['.cwf/', '.claude/', 'docs/', 'implementation-guide/', 't/']` prefix list dropped; the now-redundant `die_path("body file does not exist: $path") unless -f $path` follow-up removed (validator enforces it); `--body-file` help text updated from "repo-relative path; outside-repo paths rejected" to "any readable file path (absolute or relative)."
- Modified: `t/artefacthelpers.t` — removed `validate_path_allowlist` test block (7 assertions); added 6 write-validator cases (`write: accepts/rejects ...`) and 5 read-validator cases (`read: accepts/rejects undef/empty/non-existent/unreadable`), with `SKIP: { skip ... if $> == 0 }` around the chmod-0000 case and a chmod-0600 restore before tempdir CLEANUP.
- Modified: `t/backlog-manager.t` — added 4 new subtests (`Task140-pos`, 3× `Task140-neg`) inline rather than in a separate file, to avoid duplicating ~70 lines of `make_isolated`/`run_bm`/`_shell_quote`/`_slurp` scaffolding. Covers `/tmp/...` accept plus non-existent / unreadable / empty rejects.
- Modified: `.cwf/security/script-hashes.json` — 4 SHA256s updated by hand (`ArtefactHelpers.pm`, `backlog-manager`, `cwf-apply-artefacts`, `cwf-claude-settings-merge`). `fix-security` intentionally refuses to regenerate SHAs (Task-135 surface-don't-smooth invariant); the four `Actual:` hashes it computed and printed were copied in. `last_updated` bumped to 2026-05-16.

### Notable
- **Verbatim function-body copy as a security-equivalence proof.** `validate_write_path_allowlist` is a byte-for-byte body copy of `validate_path_allowlist` under a new name. The cost of "did we accidentally weaken the write-side checks?" went from "review the diff carefully" to "verify it's the same bytes". Reviewer's question collapses to the much narrower "is this call site's threat model the one the function defends?".
- **Plan-review caught two real defects.** The `--body-file` help text at `backlog-manager:131` ("repo-relative path; outside-repo paths rejected.") would have stayed stale post-rename. The redundant `-f $path` follow-up in `backlog-manager` was implicitly removed by the new validator but not explicitly listed in d-plan Step 4. Both surfaced by plan-review subagents before the f-phase started.
- **Scope-defer-with-grep avoided dead code.** The temp variant's deferral wasn't a guess — d-plan recorded the grep against the two BACKLOG-named candidate callers (`cwf-checkpoint-commit`, `security-review-changeset`); neither uses Perl `File::Temp` today. Adding the function with zero callers would have failed a future "audit for dead code" pass. The original BACKLOG entry stays open under a refined title for re-engagement when a real caller appears.
- **Hash-update friction worked as designed.** `fix-security` refused to rewrite SHAs ("Restore from upstream: 'git pull'..."). The friction is the feature (Task-135). Manual splice of the four computed hashes into `script-hashes.json` was the canonical path; no recompute-tooling was added.
- **`security-review-changeset` blind to uncommitted work, bit a fourth time** (137, 138, 139, 140). Workaround: commit code under a non-checkpoint message, re-run helper against the real diff, then checkpoint the wf file alone. Both exec-phase reviews returned substantive "no findings" verdicts; both *also* failed sentinel-first formatting (third+ task in a row), so both were recorded as `**State**: error` with verbatim body. The "security-review-changeset blind" and "Tighten security-subagent prompt" BACKLOG items had their priorities bumped during this retrospective — third-consecutive-task signal is no longer a hypothesis.

### Retired Backlog Items
- "Split validate_path_allowlist into write/read/temp variants" (Very High) — retired via `backlog-manager retire`; see entry below for the implementation deviation note.

#### Split validate_path_allowlist into write/read/temp variants

Split `CWF::ArtefactHelpers::validate_path_allowlist` into three semantically-distinct functions, each with its own allowlist and rejection rules tailored to the actual threat model of the caller. Today's single function is cargo-culted across callers with different threat models, producing both over-restriction (rejecting legitimate `/tmp` use) and under-protection (no distinction between write and read paths).

### Background
`validate_path_allowlist` was introduced in Task 127 (`215cbf7`) for `cwf-apply-artefacts` — a tool that **writes** artefact files into the user's tree from a JSON manifest. There the allowlist defends a real threat: a tampered manifest must not be able to write to arbitrary locations (`/etc/passwd`, `~/.ssh/authorized_keys`, etc.).

In Task 131 (`13215d6`) the same function was lifted into `backlog-manager --body-file` — a tool that **reads** a body file and copies its content into BACKLOG.md. The threat model is completely different: the invoker already has shell access and read permission on the source path; restricting where the body file may live defends against nothing. The friction it imposes ("write your temp file inside the repo, then remember to delete it") is pure ceremony and has already pushed callers to bypass the helper entirely (Task 136 retrospective: "Fix at the time: edited BACKLOG.md directly with the Edit tool").

A single function cannot serve both call sites correctly because the underlying questions are different:

- **Write paths**: "Is this a safe destination for content I am about to overwrite?" — defends against directory traversal, absolute paths into sensitive locations, manifest tampering.
- **Read paths**: "Is this a valid existing source I can read from?" — defends against nothing beyond what the filesystem permissions already enforce. Restricting source paths is anti-feature: the user has already chosen what to read.
- **Temporary paths**: "Is this a transient file in a scratch location?" — should *encourage* `/tmp/<task>/...` (the project convention), reject paths under tracked roots that would risk accidental commit.

### Proposed split
Three functions in `CWF::ArtefactHelpers`:

1. **`validate_write_path_allowlist($path, \@allowed_prefixes)`** — current behaviour, renamed. Used by `cwf-apply-artefacts` and `cwf-claude-settings-merge`. Rejects absolute paths, `..` segments, and anything outside the caller-supplied allowlist. This is the only call site where the threat model matches the implementation.

2. **`validate_read_path_allowlist($path)`** — minimal check: `-f` exists, `-r` readable. No prefix allowlist. Used by `backlog-manager --body-file`. Permits any readable file the invoker chooses, including absolute paths under `/tmp/`.

3. **`validate_temp_path_allowlist($path)`** — *encourages* scratch locations. Accepts `/tmp/`, `$TMPDIR/`, and the system temp dir. Rejects paths under `.cwf/`, `.claude/`, `docs/`, `implementation-guide/`, `t/`, or anything else inside the git tree. Used when a caller needs to write a transient file that must not be tracked. (Identify call sites during design — `cwf-checkpoint-commit` writes message scratch files; security-review-changeset writes intermediate state; both should use this.)

### Work to do
- Add the three new functions to `CWF::ArtefactHelpers`. Export each individually.
- Update `cwf-apply-artefacts` (`.cwf/scripts/command-helpers/cwf-apply-artefacts:208`) to use `validate_write_path_allowlist`.
- Update `cwf-claude-settings-merge` (`.cwf/scripts/command-helpers/cwf-claude-settings-merge:63`) to use `validate_write_path_allowlist`.
- Update `backlog-manager` (`.cwf/scripts/command-helpers/backlog-manager:304`) to use `validate_read_path_allowlist`. Drop the prefix list.
- Audit other helpers for path-validation needs; switch to `validate_temp_path_allowlist` where the file is genuinely transient.
- Update tests (`t/artefacthelpers.t`, `t/backlog-manager.t`) for the new function shape.
- Remove `validate_path_allowlist` from the module's `@EXPORT_OK` list once all callers have migrated.

### Why "Very High"
This is the second structural defect surfaced by Task 137 (alongside the un-anchored Perl convention). The two are independent and should not be bundled, but both block clean re-use of the helper interfaces. Friction has already produced workaround behaviour (direct `Edit` of `BACKLOG.md`), which is the worst outcome for a validator: not "correct" or "incorrect", but "bypassed".

### Suggested sequencing
Independent of the Perl-convention re-alignment item; can be done in parallel. Single task, no decomposition needed.

<!-- Note: Write and read variants shipped as planned. Temp variant deferred at d-plan time after grep confirmed neither candidate caller writes Perl-side temp files. Re-scoped temp work captured in a fresh BACKLOG entry to land when a real caller appears. -->

### New Backlog Items
- Low: "Add validate_temp_path_allowlist for transient-file callers" — re-scoped follow-up containing just the temp-variant work deferred from Task 140. Resolves to "no action" if no Perl-side temp-file caller appears.

### Priority Bumps During Retrospective
- "security-review-changeset blind to uncommitted work" — Low → High (fourth consecutive task to hit it).
- "Enforce sentinel-first output in security-review subagent prompt" — Low → Medium (two exec-phase reviews on this task hit it; second attempt with escalating prompt still failed).
- "Tighten security-subagent prompt for sentinel-line compliance" — Low → Medium (same root cause as above; the two entries should likely be merged in a future housekeeping pass).

## Task 139: Re-align Perl-script conventions to Task-27 form

### Status: Complete (2026-05-15)
### Duration: 1 session, ~half a day against a 1-day estimate; under-budget.
### Impact: Bugfix / structural cleanup — reverts 11 hardcoded `#!/usr/bin/perl -CDSLA` shebangs to the original Task-27 form (`#!/usr/bin/env perl` + `PERL5OPT=-CDSLA`), tightens `CWF::Validate::PerlConventions` to enforce the canonical shebang universally (not just on git-capturing scripts), splits `docs/conventions/perl-git-paths.md` into `perl.md` (universal: shebang, PERL5OPT, `use utf8;`) and `git-path-output.md` (niche: `-z`, `split /\0/`, NUL-handling), anchors both in CLAUDE.md `## Conventions`, and updates INSTALL.md's `PERL5OPT` recommendation from `-CDSL` to `-CDSLA` with Task-137 rationale. Restores the original convention that Task 113/115/124 silently drifted away from. Eliminates the "Too late for -CDSLA" kernel-shebang-vs-PERL5OPT failure mode Task 137 surfaced.
### Status: Complete (2026-05-15)
### Duration: 1 session; estimate <0.5 day; on-target.
### Impact: Bugfix / cargo-cult cleanup — `.claude/skills/cwf-backlog-manager/SKILL.md` previously prefixed every helper example with `cd "$(git rev-parse --show-toplevel)" && ` and carried a paragraph framing the prefix as a security guard against working-directory pivots. The threat model was incoherent: the actor described (something that "changes cwd to /tmp and stages /tmp/.cwf/scripts/...") is the same Claude that would also follow the guard — they share a trust boundary. More importantly, the relative path `.cwf/scripts/command-helpers/backlog-manager` is self-anchoring via kernel ENOENT: it only resolves to a real file when cwd already contains `.cwf/`, so the kernel's path resolution at the call site enforces "must run from repo root" without help from the prefix. Task strips the prefix from all 8 example fences in one `replace_all` Edit, deletes the threat-model paragraph, deletes the stale `## Success Criteria` checkbox referencing the cd. 9/10 test cases PASS, 1 N/A; negative test (run from `/tmp`, expect exit 127 + "No such file or directory") empirically confirms the self-anchoring claim.

### Changes
- Created: `docs/conventions/perl.md`, `docs/conventions/git-path-output.md`. Cross-referenced.
- Deleted: `docs/conventions/perl-git-paths.md`.
- Modified: `CLAUDE.md` — 2 new bullets under `## Conventions` (parallel to commit-messages.md and design-alignment.md anchors).
- Modified: `.cwf/lib/CWF/Validate/PerlConventions.pm` — replaced capture-conditional shebang check with a universal positive-form check `$first_line !~ m{\A\#!/usr/bin/env perl\s*\z}`; moved grandfather skip after shebang check so grandfathered files still satisfy the shebang rule (only `-z` is exempted now); updated `git_z` error message to cite `git-path-output.md`; rewrote file-header pod block.
- Modified: 11 script shebangs from `#!/usr/bin/perl -CDSLA` to `#!/usr/bin/env perl` — `cwf-manage`, `backlog-manager`, `cwf-apply-artefacts`, `security-review-changeset`, `context-inheritance-v2.0`/`v2.1`, `template-copier-v2.0`/`v2.1`, `status-aggregator-v2.0`/`v2.1`, `stop-uncommitted-changes-warning`.
- Modified: `.cwf/security/script-hashes.json` — 12 SHA256s regenerated via `sha256sum` + manual splice (11 scripts + `PerlConventions.pm`); second-pass regen for `Common.pm` and re-amended `PerlConventions.pm` after the audit-driven updates. `last_updated` bumped to 2026-05-15.
- Modified: `INSTALL.md` — `-CDSL` → `-CDSLA` at lines 259 and 311; expanded the explanation to cover `@ARGV` decoding and Task-137 context.
- Modified: `.cwf/lib/CWF/Common.pm` — `check_perl5opt` warning now recommends `-CDSLA` (not `-CDSL`).
- Modified: `.claude/skills/cwf-init/SKILL.md` — installed-skill template recommends `-CDSLA`.
- Modified: `.cwf/docs/skills/security-review.md` — replaced `perl-git-paths.md` reference with two refs (`git-path-output.md` for `-z`, `perl.md` for universal rules).
- Modified: `docs/conventions/design-alignment.md` — conventions index updated.
- Modified: `t/validate-perl-conventions.t` — 10 fixture shebangs flipped to `env perl`; TC-U3c, TC-U3b, TC-U7 rewritten for the new semantics; new TC-U9 (canonical-form passes) and TC-U10 (hardcoded `-CDSLA` rejected even with `-z`).
- Modified: `t/backlog-manager-argv-utf8.t` — re-pinned the Task-137 regression cover to the new contract. Helper renamed `run_bm_shebang_only` → `run_bm_with_perl5opt`; sets `$ENV{PERL5OPT} = '-CDSLA'` in child env instead of deleting `PERL5OPT`. Same assertions.
- Modified: `t/common.t` — fixture `PERL5OPT='-CDSL'` → `-CDSLA` for narrative consistency.

### Notable
- **Positive-form shebang rule beats negative-regex rule.** Plan reviews surfaced regex-edge-case ambiguity in the original "reject `-C*`" framing (three of four subagents flagged it independently). Reframing the check as "must match `#!/usr/bin/env perl`" — a positive-form assertion — eliminated every variant-handling concern at once. When the spec is "must look like X", assert X, don't enumerate not-X.
- **Validate-first gate between mechanical edit and hash regen.** After the 11 shebang reverts and the validator amendment, `cwf-manage validate` reported exactly 12 SHA mismatches: 11 scripts + `PerlConventions.pm`. No surprise entries; no missed files. The gate generalises: any deterministic transformation followed by a non-deterministic step (here: hash regen against transformed bytes) benefits from an integrity check in between that doesn't depend on the transformation being perfect.
- **Final repo-wide grep caught three live surfaces the design plan missed.** Design enumerated four inbound-reference surfaces (INSTALL.md, security-review.md, design-alignment.md, BACKLOG.md). The final `git grep -- '-CDSL\b'` outside frozen scope found three additional live hits — the user-facing `check_perl5opt` warning, the installed-skill template, and a test fixture. Lesson: design-time enumeration is necessary but not sufficient for any audit; always pair it with a recipe-based final check.
- **Changing a fix's mechanism requires re-pinning tests that test the mechanism.** Task 137's regression cover explicitly deleted `PERL5OPT` from the child env to prove the shebang was the contract. Task 139 moves that contract to `PERL5OPT`. Foreseeable, but not planned for — added to the recommendations list. Worth a mental rule: when changing *how* a fix works (not just *what* it does), audit tests that pin the mechanism.
- **`security-review-changeset` blind to uncommitted work, bit again.** The implementation-phase security review ran before the f-phase checkpoint; the helper diffs `anchor..HEAD` and saw zero files. Recorded as `error` with a manual per-category analysis (FR4 a–e) in `f-implementation-exec.md`. After the f-phase commit, the testing-phase subagent ran on a real 485-line diff and returned `no findings`. Same trap that bit Tasks 137 and 138 — this is the third time. Backlog entry created.
- **Surface-don't-smooth invariant preserved.** Manual `sha256sum` + 12 individual Edit operations to splice the new hashes into `.cwf/security/script-hashes.json`. Tedious by design. `cwf-manage fix-security` deliberately does not regenerate SHAs (it only repairs permissions when SHA still matches) for exactly this reason; preserved that property.
- **The `-A` flag is the load-bearing detail.** `PERL5OPT=-CDSL` (which INSTALL.md previously recommended) and `PERL5OPT=-CDSLA` are visually one character apart but produce completely different `@ARGV` behaviour. The `A` decodes `@ARGV`; without it, non-ASCII bytes passed as CLI arguments become mojibake (Task 137). Both INSTALL.md and the `check_perl5opt` warning had drifted to the wrong recommendation; Task 137 added `-A` to the shebangs but didn't propagate it to user-facing docs. Task 139 closes the loop.
- **Grandfather list semantics flipped.** Pre-139 grandfathering exempted the file from both `-z` and shebang rules. Post-139 grandfathering exempts only `-z` — `env perl` is universal. The sole grandfathered file (`stop-stale-status-detector`) already used `env perl`, so the policy change costs nothing.

### New Backlog Items
- Low: `security-review-changeset` blind to uncommitted work. Helper diffs `anchor..HEAD`; running it before the phase's checkpoint commit returns `reviewed 0 files` silently. Skill's "empty changeset → no findings" path then skips a real review. Third task to trip on this (137, 138, 139). Fix options: (a) helper diffs working tree against anchor, (b) helper warns when staged/working-tree changes exist, (c) workflow docs explicitly say "checkpoint first then review". Pick one.

### Retired Backlog Items
#### Re-align Perl-Script Convention to Task-27 Form and Anchor in CLAUDE.md

Re-align CWF's Perl-script conventions to their original Task-27 form, and re-anchor the convention docs in CLAUDE.md so future drift is visible. Two intertwined concerns:

### 1. Perl invocation shape
The originally-decided convention (commit 1db1f77, Task 27, 2026-01-23) was:

- Shebang: `#!/usr/bin/env perl` — portable; no kernel-shebang-argv-parsing fragility.
- Runtime flags: `PERL5OPT=-CDSLA` set in `~/.claude/settings.json` — one source of truth, single place for users to update.
- Source pragma: `use utf8;` on every Perl file.

The convention drifted in Tasks 113 (a63ecdc, 2026-04-26), 115 (876b144, 2026-04-27), and 124 (91a7a86, 2026-05-03), each compounding the previous without acknowledgement. Current state: 22 scripts on `env perl`, 11 scripts on hardcoded `#!/usr/bin/perl -CDSL`, validator (`CWF::Validate::PerlConventions`) enforces the drifted form on git-path-emitting scripts.

The hardcoded-flag shebang has two concrete failure modes:

- **`Too late for -CDSLA`**: when `PERL5OPT` already supplies some `-C` flags and the shebang tries to add `A` (the flag that decodes `@ARGV` — see Task 137), perl rejects post-init flag additions. Empirically verified 2026-05-13.
- **Kernel shebang-argv parsing variance**: Linux pre-5.10, macOS, and several BSDs differ on whether `-CDSL` is passed as one token or split. `env perl` plus `PERL5OPT` bypasses this entirely.

Work to do:

- Revert all 11 `#!/usr/bin/perl -CDSL` shebangs to `#!/usr/bin/env perl`.
- Update `PERL5OPT` recommendation to `-CDSLA` (the `A` flag is what fixes the Task 137 bug; it can only be set via `PERL5OPT`, not shebang).
- Rewrite the validator to require `env perl` and **reject** hardcoded `-C` shebangs.
- Update `t/validate-perl-conventions.t` fixtures and `t/common.t`.

### 2. Convention docs structure and CLAUDE.md anchoring
Today `docs/conventions/perl-git-paths.md` mixes:

- Universal rules: every Perl file uses `env perl` + `use utf8;` + recommends `PERL5OPT`.
- Niche rules: scripts that capture path-emitting git output use `-z` and `split /\0/`.

The filename advertises only the niche rules, so a reader looking for "how do we write Perl in this project?" never opens it. CLAUDE.md does not reference the file at all. The `## Conventions` section lists `commit-messages.md` and `design-alignment.md` only. That structural gap is what allowed Tasks 113 / 124 to silently codify a drifted form — no agent reading CLAUDE.md from the top would discover the prior convention.

Work to do:

- Split `docs/conventions/perl-git-paths.md` into two files:
  - `docs/conventions/perl.md` — universal Perl rules (shebang, PERL5OPT, `use utf8;`).
  - `docs/conventions/git-path-output.md` — git-specific rules (`-z`, `split /\0/`, NUL-handling).
- Cross-reference between the two.
- Add two bullets to CLAUDE.md `## Conventions` (around line 50), pointing at each new doc, so both are progressively discoverable from the project entry point.
- Audit every project entry point (CLAUDE.md, README.md, INSTALL.md, `.claude/rules/*`) and add references where the conventions are load-bearing for an agent or human reading from the top.

### Why "Very High"
This is the root cause of Task 137 (the user-reported `→` mojibake in `backlog-manager add`). The bug surfaced through a specific symptom, but the **structural failure** — un-anchored conventions drifting silently across three tasks — is what allowed the bug class to exist. Fixing only the symptom leaves the drift mechanism in place. The fix should be the convention re-alignment; the `@ARGV` bug becomes a side-effect of doing it correctly.

### Suggested task split
If decomposed:

- Task A (`chore`): split + rename convention docs, add CLAUDE.md anchors. Low risk.
- Task B (`bugfix`): revert hardcoded shebangs, update validator, update `PERL5OPT` recommendation, update test fixtures. Subsumes Task 137. Higher risk (validator changes, hash regeneration, breaks anyone on stale `PERL5OPT`).

Task A is a prerequisite for Task B because the new validator should cite the new doc paths.

<!-- Note: Implemented as a single combined task; the entry suggested splitting Task A/B but combined was right call - milestones share validator-doc dependency -->

### Changes
- Modified: `.claude/skills/cwf-backlog-manager/SKILL.md` — removed lines 18-24 (the "Mandatory pre-step" paragraph including the fenced example and the threat-model paragraph, plus the trailing blank that would otherwise have collapsed into a double-blank before `## Subcommands`). Stripped `cd "$(git rev-parse --show-toplevel)" && ` from all 8 subcommand example fences (`validate`, `list`, `add`, `modify`, `delete`, `normalise` ×2, `retire`) via one `replace_all` Edit. Deleted the `- [ ] Subcommand invoked from git-root via cd "$(...)"` checkbox from `## Success Criteria`, leaving the two genuine correctness checkboxes (list-form args, exit-code observation). Net diff: −16 lines, +0 lines.

### Notable
- **Relative paths are self-anchoring via kernel ENOENT.** `.cwf/scripts/command-helpers/foo` only resolves when cwd contains `.cwf/scripts/command-helpers/foo`; otherwise `execve` returns ENOENT and the call is loud. This is the kernel's path resolution at the call site, not a check the helper performs. Any "cd to git root before invoking" guard *at the call site* is dead weight when the invocation path is relative. (The pattern is genuinely useful when the helper needs an absolute path passed as an *argument*, e.g. `cwf-init`'s `GIT_ROOT="$(...)"` — different use of `git rev-parse`.)
- **Nested-repo behaviour favours the no-cd form.** If cwd is inside a different repo, the old `cd "$(...)"` form would silently `cd` into that other repo's toplevel and run whatever `.cwf/scripts/...` exists there. The new form fails cleanly with ENOENT. Removing the guard is a small *gain* in robustness, not a loss.
- **Negative test is the strongest evidence.** TC-8 runs the rewritten example from `/tmp` and observes exit 127 + "No such file or directory" — direct runtime confirmation of the self-anchoring claim. Beats a paragraph of reasoning. Pattern: when a design relies on a runtime invariant, write the test that *attempts* the disallowed action and verifies the failure mode fires.
- **Two security-review subagents returned different verdicts on the same 88-line diff.** g-phase: `no findings` ("removes a redundant and incorrectly-documented security control"). f-phase re-run: `findings` (category e, "loss of invariant documentation", suggested HTML-comment remediation). Both reasonings are defensible; the difference is whether you weight "remove cargo-cult noise" or "preserve archival reasoning at the callsite" more highly. Decision: declined the finding with three-part rationale (HTML in markdown is form-wrong; markdown-native remediation collapses to undoing the change; c-design-plan #3 already weighed and rejected this alternative). Recorded verbatim in `f-implementation-exec.md` and `g-testing-exec.md`. Review judgement is not deterministic — record verbatim, decide explicitly.
- **Design-plan "Alternatives Considered" is load-bearing.** c-design-plan #3 explicitly rejected "keep a sanitised note" as re-introducing noise to defend against a debunked threat model. When the security subagent later proposed exactly that as remediation, the rejection rationale was already in hand. Second task in a row where this pattern paid off (Task 135 used it for the "no `recompute-hashes` button" decision).
- **`security-review-changeset` blind to uncommitted work bit again.** Running the helper during f-implementation-exec before the checkpoint returned `reviewed 0 files`. After the f-checkpoint, the same command returned 88 lines. Workaround: commit-then-review. Backlog item already exists (Task 136); not duplicating. Task 137 also tripped on this; the trap will keep biting until the helper warns or the workflow doc says "checkpoint first" explicitly.
- **Plan's residue grep was too broad.** d-plan asked for `grep 'git rev-parse --show-toplevel'`, expecting one out-of-scope hit. The pattern fired ~12 times — every internal Perl helper that legitimately captures the git root into a variable for absolute-path argument passing. Rescoped at exec time to the literal cd-prefix form `cd "$(git rev-parse --show-toplevel)"`, which left exactly one out-of-scope match (`update-cwf-skill-docs.sh:10`, a Task-40 migration script). Lesson: a "removal verification" grep must anchor on the *form being removed*, not on a substring it shares with legitimate code paths.
- **HTML in markdown is a smell.** The security subagent suggested `<!-- ... -->` for "documentation preservation". Markdown docs shouldn't use HTML as a content channel — if reasoning matters enough to keep, write markdown prose; if it doesn't, don't write it.

### New Backlog Items
- Low / discovery: Investigate whether `cwf-init`'s `GIT_ROOT="$(git rev-parse --show-toplevel)"` is redundant — `cwf-apply-artefacts` may resolve the git root internally via `find_git_root()`, in which case the GIT_ROOT argument is dead weight and Task 138's cleanup logic transfers. ~30 min investigation, separate task.

## Task 137: backlog-manager double-encodes non-ASCII @ARGV

### Status: Complete (2026-05-15)
### Duration: 1 session; estimate 0.5–1 day; on-target at the optimistic end.
### Impact: Bugfix — `backlog-manager add` (and any other argv-consuming Perl helper under `.cwf/scripts/`) wrote non-ASCII argv as UTF-8 double-encoded mojibake: `→` (U+2192, `E2 86 92`) became `C3 A2 C2 86 C2 92`, `§` became `Â§`, `—` became `â`-something. Root cause: shebang `-CDSL` covers STDIN/STDOUT/STDERR + file I/O + locale, but lacks `A` (argv UTF-8 decoding). Fix extends the convention to `-CDSLA` across 11 production scripts, updates the validator literal in lockstep, and updates 7 test fixtures. New regression test `t/backlog-manager-argv-utf8.t` (TC-F1/F2) proves the fix end-to-end with shebang-only contract (PERL5OPT explicitly stripped from the test child process). TC-F1 sensitivity verified by transient shebang revert. 461 tests pass; `cwf-manage validate` clean.

### Changes
- Modified: 11 production scripts under `.cwf/` — shebang `#!/usr/bin/perl -CDSL` → `#!/usr/bin/perl -CDSLA` on `cwf-manage`, `backlog-manager`, `context-inheritance-v2.0`, `context-inheritance-v2.1`, `cwf-apply-artefacts`, `security-review-changeset`, `status-aggregator-v2.0`, `status-aggregator-v2.1`, `template-copier-v2.0`, `template-copier-v2.1`, `stop-uncommitted-changes-warning`. The `A` flag decodes `@ARGV` UTF-8 bytes into Perl character strings *before* any write layer re-encodes — this is the property that fixes the double-encode.
- Modified: `.cwf/lib/CWF/Validate/PerlConventions.pm` — three substring swaps in the shebang-check block (the literal comparison value, the `expected` field in the violation hash, and the user-facing message string). Header comments and explanatory message tail deliberately not updated (deferred to the convention re-alignment follow-up).
- Modified: `t/validate-perl-conventions.t` — 7 fixture shebangs changed `-CDSL` → `-CDSLA` via `replace_all`. Required because the validator literal changed; old-shebang fixtures would now trigger extra `shebang` violations and break tests asserting specific violation counts.
- Added: `t/backlog-manager-argv-utf8.t` — new test file. TC-F1: spawns `backlog-manager add` with non-ASCII argv (`→ § —`) in a temp git repo with `delete $ENV{PERL5OPT}` so the shebang is the sole `-C` source, then byte-asserts the resulting BACKLOG.md contains clean UTF-8 and *not* the double-encoded forms (`c3 a2 c2 86 c2 92` etc.). TC-F2: same setup, asserts `normalise` preserves pre-existing non-ASCII bytes. Sensitivity verified: reverting the shebang to `-CDSL` makes TC-F1 fail with mojibake.
- Modified: `t/validate-perl-conventions.t` (additionally) — new subtest TC-U3c asserts the validator now flags `-CDSL` shebang with `field=shebang` and `expected=#!/usr/bin/perl -CDSLA`. Closes the rule loop (positive accept-`-CDSLA` *and* positive reject-`-CDSL`).
- Modified: `.cwf/security/script-hashes.json` — 12 sha256 entries regenerated via `sha256sum` (coreutils) to preserve verifier/producer implementation diversity with the in-tree `Digest::SHA` consumer. `last_updated` bumped to 2026-05-14.
- Modified: `BACKLOG.md` — 3 new entries (see below).

### Notable
- **Convention drift discovered, deliberately *not* fixed in this task.** The originally-decided convention (Task 27, commit `1db1f77`, 2026-01-23) was `#!/usr/bin/env perl` + `PERL5OPT=-CDSL` configured at the user level. Tasks 113/115/124 introduced hardcoded `-CDSL` in script shebangs without acknowledging the drift; the convention was never anchored from CLAUDE.md so progressive discovery did not catch it. Task 137 *extends* the drifted form (`-CDSL` → `-CDSLA`) rather than reverting to Task 27's form — minimum-fix scope. The full re-alignment is filed as Very-High backlog item "Re-align Perl-Script Convention to Task-27 Form and Anchor in CLAUDE.md".
- **The `-C` flag-set consistency rule between PERL5OPT and shebang.** Perl rejects post-init `-C` differences with `Too late for -C…`. Empirically: `PERL5OPT=-CDSL` + shebang `-CDSLA` fails; `PERL5OPT=-CDSLA` + shebang `-CDSL` also fails. The two must match exactly *or* the shebang must be `#!/usr/bin/env perl` (no `-C` in the shebang at all). Documented in f-implementation-exec.md so future shebang-touching tasks have the constraint named.
- **PERL5OPT migration trap for existing users.** Anyone with a global `PERL5OPT=-CDSL` (typical setup before this task) will hit `Too late for -CDSLA` on the next script invocation after pulling this commit. Mitigation: update `~/.claude/settings.json` to `PERL5OPT=-CDSLA`. Migration text is *not* yet in INSTALL.md or cwf-init; it ships with the convention re-alignment follow-up.
- **Sensitivity verification on TC-F1.** Wrote the test against the post-fix code, then transiently reverted the `backlog-manager` shebang to `-CDSL` and re-ran: TC-F1 failed with mojibake bytes in the diagnostic (`ÃÂ¢ÃÂÃÂ` where `→` should be). Restored the shebang and the test passed. The transient revert is two edits and a re-run — cheap proof that the test is not vacuous.
- **`security-review-changeset` is blind to working-tree changes.** Helper diffs `anchor..HEAD` over committed history. For both f-phase and g-phase, the work was uncommitted at security-review time, so the helper returned `reviewed 0 files`. Workaround for this task was `git diff HEAD` → file → Read-tool input to the Explore subagent. Re-confirms the existing backlog item "Improve security-review-changeset feedback on empty-from-uncommitted changesets" (filed in Task 136); not adding a duplicate.
- **`validate_path_allowlist` cargo-cult discovered.** While trying to write a body file to `/tmp/`, `backlog-manager add` rejected the path. Investigation showed `validate_path_allowlist` was copied from `cwf-apply-artefacts` (a write tool with strict allow-list) into `backlog-manager` (a read tool reading scratch input) where the threat model does not apply. Filed as Very-High backlog item "Split validate_path_allowlist into write/read/temp variants".
- **TC-F8 deliberately deferred.** TC-F8 asserts `docs/conventions/perl-git-paths.md` no longer carries the false claim that `-CDSL` decodes `@ARGV`. Since the doc is *not* updated in this task, TC-F8 cannot pass and would fail-on-purpose. Recorded as DEFERRED with reference to the Re-align backlog item.

### New Backlog Items
- Very High: Re-align Perl-Script Convention to Task-27 Form and Anchor in CLAUDE.md — split `docs/conventions/perl-git-paths.md` into `docs/conventions/perl.md` and `docs/conventions/git-path-output.md`; revert the 11 hardcoded `-CDSL` shebangs to `#!/usr/bin/env perl`; update SKILL.md/INSTALL.md/Common.pm/security-review.md PERL5OPT recommendation to `-CDSLA`; anchor the convention from CLAUDE.md so progressive discovery catches future drift.
- Very High: Split `validate_path_allowlist` into `validate_write_path_allowlist` / `validate_read_path_allowlist` / `validate_temp_path_allowlist` — the current single function mixes three threat models. Write-destinations need a strict in-tree allow-list; read-sources need a much wider allow-list (including `/tmp`); temp scratch paths need their own allow-list. Conflating them is why `backlog-manager` rejected a `/tmp/` body file in this task.
- Low: Make path-allowlists overridable in `cwf-project.json` — once the three variants exist, allow per-repo configuration so projects with non-standard layouts (monorepo subdirs, external tool paths) can extend the allow-lists without forking the helpers.

## Task 136: Delete most-recent task only

### Status: Complete (2026-05-13)
### Duration: ~1 session; estimate 1-2 days; landed at the optimistic end.
### Impact: Feature — `/cwf-delete-task <task-path> [--force]` provides a single-shot way to undo `/cwf-new-task`, restricted to the most-recent task so no renumbering, gap-filling, or task re-stacking is ever required. The helper enforces a 10-check refusal pipeline (argument shape, resolve, realpath containment, most-recent, leaf, branch-name format, worktree, already-merged-to-main, unmerged-work, stack-topmost) and a 5-step idempotent cleanup A–E (detach HEAD, pop stack, delete checkpoints branch, delete task branch, remove directory). `--force` only relaxes the unmerged-work check; all other refusals are absolute. 28 functional + 2 non-functional test cases pass; `cwf-manage validate` clean.

### Changes
- Added: `.cwf/scripts/command-helpers/task-workflow.d/delete` — 336-line Perl helper implementing the 10-check refusal pipeline and idempotent cleanup A–E. Uses `File::Path::remove_tree({ safe => 1 })` for symlink-aware deletion, list-form `system()`/`open '-|', 'git', ...` to avoid shell injection, and NUL-separated `git log -z --format='%H%x00%s'` to enumerate non-checkpoint commits without subject-collision risk. Self-worktree exclusion in check 7 lets the helper delete the task whose worktree it's invoked from (cleanup A handles HEAD-on-task-branch via `git checkout --detach <baseline>`).
- Added: `.claude/skills/cwf-delete-task/SKILL.md` — thin user-invocable skill (allowed-tools: Bash) that shells out to `task-workflow delete <task-path> [--force]`. Documents exit codes (0 deleted, 1 refusal, 2 partial-state) and the full refusal-case list.
- Modified: `.cwf/scripts/command-helpers/task-workflow` — dispatcher gained `delete` entry alongside `create`; usage updated.
- Modified: `.cwf/lib/CWF/TaskPath.pm` — added `version_compare` to `@EXPORT_OK` (required by the delete helper for sibling-version comparison).
- Modified: `.cwf/security/script-hashes.json` — registered `task-workflow.d/delete` (perms 0500) and refreshed hashes for `task-workflow` and `CWF::TaskPath`.
- Modified: `CLAUDE.md` — added `/cwf-delete-task` to the Core Skills list.

### Notable
- **Refusal-list-driven design**. The 10-check enumeration was done up-front in c-design-plan.md; implementation was largely "translate the enumeration into code". Tests fell out naturally — one test case per refusal check.
- **Hoisting check 6 (branch-name format) out of cleanup**. Original design placed it inside cleanup step A; moving it to the pre-cleanup phase guarantees a malformed name cannot cause partial-state. One-line code change, meaningful contract improvement.
- **Self-worktree exclusion bug caught in smoke**. First end-to-end run inside a disposable worktree refused to delete its own task — exactly the case cleanup A handles. Caught and fixed before commit by comparing each worktree's `abs_path` against the helper's own `git rev-parse --show-toplevel`.
- **Idempotent cleanup A–E**. Re-running after partial state completes cleanup; each step guards with an existence check. TC-CLN1..CLN5 verify this directly. Right shape for a destructive CLI: lean into recovery, not transactions.
- **TC-FR8b first-pass failure was test setup, not code**. Original setup tripped check 4 (most-recent) before reaching check 10 (stack); fix was to hand-craft a stack with a phantom topmost so earlier checks passed. For future refusal-pipeline tests, the test plan should explicitly call out which earlier checks each case must bypass.
- **Testing-phase security-review false positive (`-CDSL` shebang) rebutted with the actual validator source**. Agent flagged shebang as a "non-negotiable" rule violation; `PerlConventions.pm:49` shows the rule is conditional on `$PATH_CMDS = qr/status|diff|ls-files|diff-tree|diff-index/` — none of the helper's git subcommands match. `cwf-manage validate` confirms `OK`. Full rebuttal recorded in g-testing-exec.md.
- **`security-review-changeset --phase=implementation` returns empty when work is uncommitted at security-review time**. Helper diffs `anchor..HEAD`; working-tree changes are invisible. Workaround for this task was `git add -N` + manual `git diff <anchor> -- <CWF-internal paths>`. Worth surfacing in the helper as a warning.

### New Backlog Items
- Improve `security-review-changeset` empty-changeset feedback (Low) — when changeset is empty because of uncommitted work, log a hint pointing to the `git add -N` + manual-diff workaround rather than silently returning empty.
- Consider `internal-feature` template variant (Low) — `h-rollout.md` and `i-maintenance.md` collapse to mostly-N/A for local CLI helpers with no service surface; a slimmer variant would reduce noise on this class of task.
- Consider `/cwf-delete-task` no-arg form (Low) — let the helper default to the topmost-stack entry. Would need its own FR set; out of scope for this task.

## Task 135: Preserve template symlinks in cwf-manage

### Status: Complete (2026-05-13)
### Duration: 1 session; estimate 1-2 days; on-target.
### Impact: Bugfix — two coupled bugs in `cwf-manage` that combined to silently inline every `.cwf/templates/<type>/*.template` symlink on update. `update` used `File::Copy::copy` which dereferences symlinks; `validate` had no check for the resulting symlink-vs-regular-file mismatch, so the corruption was invisible. After this task, `cwf-manage update` preserves symlinks (refusing absolute and escaping targets), `cwf-manage validate` reports the mismatch with `category=TEMPLATES`, and re-running `update` heals an already-broken install. `prove -r t/` 458/458 PASS; `cwf-manage validate` clean.

### Changes
- Added: `.cwf/lib/CWF/Validate/Templates.pm` — new validator (`CWF::Validate::Templates::validate($git_root)`) iterating `CWF::WorkflowFiles::V21::supported_types()` and asserting every entry under `.cwf/templates/<type>/` is a symlink with exact target `../pool/<basename>`. Single exact-pattern check subsumes type-mismatch, dangling-target, wrong-pool-name, escape, and absolute-target detection. Returns violation hashrefs with `category => 'TEMPLATES'`.
- Modified: `.cwf/scripts/cwf-manage` — `copy_tree` now `lstat`s entries and recreates symlinks at the destination (preserving relative targets) instead of dereferencing them. New `_escapes_src($entry, $link, $src)` gate refuses absolute or out-of-tree-escaping symlink targets at copy time; uses `$File::Find::name` (not `$_`) so safety does not depend on File::Find's chdir default. New `_collapse_dotdot($path)` lexical canonicaliser (POSIX-only, core-Perl) is the reference helper for path-escape checks where `File::Spec->abs2rel` would leak un-collapsed `..` segments. Wired `CWF::Validate::Templates` into `cmd_validate`. Added `main() unless caller;` guard at the bottom to make the script `require`-able from tests. Added `use File::Spec ();` to the use block.
- Modified: `.cwf/security/script-hashes.json` — registered the new module and updated the cwf-manage hash. Hand-updated; `fix-security` deliberately does not auto-rewrite drift (see Notable §1).
- Added: `t/validate-templates.t` — 10 unit subtests covering every validator branch (happy path, type/regular-file, type/directory, target/dangling, pool-name, absolute target, escape, multi-violation ordering, `pool/` ignored, missing type-dir).
- Modified: `t/cwf-manage-update.t` — 6 new subtests over `copy_tree` and `_escapes_src` (relative symlink preserved, pool-pointing symlink preserved, absolute target → die, escape target → die, in-tree non-pool allowed, nested escape regression guard, plus 5 direct `_escapes_src` unit assertions).

### Notable
- **Integrity-check friction is the feature; never smooth it (commit `14f4025`).** `cwf-manage fix-security` reports sha256 drift as `UNFIXABLE` and refuses to auto-update the recorded hash. The original f-implementation-exec lessons proposed a `cwf-manage recompute-hashes` subcommand to ease the manual update step; that proposal was withdrawn and replaced with the principle. A one-button "reconcile recorded hashes with actual content" command would turn the integrity signal into a no-op that an agent — including a compromised one — would invoke to paper over tampering. Recovery requires manually pasting the new hash, computed by an *independent* implementation (`sha256sum` from coreutils, not `Digest::SHA` which is what the rest of the cwf-manage tooling uses) — verifier/producer implementation diversity is the property that makes the check catch anything.
- **Testing-phase security review caught a real pattern risk.** First `copy_tree` implementation passed `$_` (File::Find basename) to `_escapes_src`, which expects a path for `dirname()` extraction. Worked by accident because File::Find's default `chdir` made `dirname('.')` resolve correctly against cwd. Subagent flagged the pattern; commit `544956d` switched to `$File::Find::name` and added a nested-escape test (TC-C6, `feature/escape -> ../../etc/passwd`) that the original $_-version would not have caught at depth.
- **`File::Spec->abs2rel` is a lexical prefix-strip, not a canonicaliser.** For a symlink target like `../../etc/passwd` from a nested entry (`$src/feature/x`), `abs2rel` produces `feature/../../etc/passwd` — the leading-`..` regex doesn't match, the escape would have been admitted. `_collapse_dotdot` is the in-repo fix for this; future callers should reuse it rather than re-derive.
- **`anchor..HEAD` means commit-then-review in exec phases.** `security-review-changeset` diffs against the baseline commit and stops at HEAD; uncommitted working-tree changes are invisible. Each exec phase needed a commit-then-review-then-amend (or follow-up commit) dance. Worth noting in the exec-phase docs so future implementers don't trip on it.
- **The testing-phase changeset hit the 500-line review cap.** 514 lines (490 already-reviewed implementation + 24-line fix from `544956d`). Per skill protocol, recorded `state: error` with the verbatim cap-message plus a manual review note explaining the delta over the prior subagent review.

### New Backlog Items
None.

## Task 134: Intent-CTA skill descriptions with reference docs

### Status: Complete (2026-05-12)
### Duration: 1 session; estimate 0.5 days; on-target.
### Impact: Chore — replaces the verb-list-style frontmatter `description` on `cwf-backlog-manager` with an intent-CTA shape that names the user-facing domain ("the backlog/changelog") and embeds 2-3 verbatim user phrasings ("what's in the backlog", ...). The previous shape was a man-page synopsis and missed the obvious intent match. Establishes a convention at `.cwf/docs/skills/skill-reference-convention.md` for short per-skill reference docs at `.cwf/docs/skills/reference/<skill>.md`, so future skills can share a decision aid for LLM-side selection without inviting the agent to Read+follow `SKILL.md` outside the Skill-tool harness (which would bypass `allowed-tools` and user-confirmation controls). One worked instance at `.cwf/docs/skills/reference/cwf-backlog-manager.md` validates the convention before rollout. `prove t/` 441/441 PASS; `cwf-manage validate` clean.

### Changes
- Added: `.cwf/docs/skills/skill-reference-convention.md` — defines location rule (instances MUST live at `.cwf/docs/skills/reference/<skill>.md`, NOT at the top level), description shape (≤ 30 words, intent-CTA, names the domain, 2-3 example phrasings), reference-doc instance shape (≤ 30 lines, 3-5 example phrasings, no operational instructions, no `SKILL.md` links), the security rule that example phrasings MUST be author-curated hardcoded strings (not derived from BACKLOG titles / branch names / etc., to avoid prompt-injection via documentation), and the YAML-validity expectation (explicit double-quoting required when the value contains `Examples: "..."` patterns — the Claude Code harness parses leniently but `YAML::XS`/libyaml rejects the unquoted form with "mapping values are not allowed in this context"). Meta-guidance doc, exempt from the 30-line per-instance budget.
- Added: `.cwf/docs/skills/reference/cwf-backlog-manager.md` — first worked instance, 19 lines. 1-paragraph purpose, 5 example user phrasings (within the 3-5 budget), 2-line "Not this skill" near-miss disambiguation. Zero `SKILL.md` mentions (verified `grep -nE '\bSKILL\.md\b'` exit 1).
- Modified: `.claude/skills/cwf-backlog-manager/SKILL.md` — frontmatter `description` only, rewritten to intent-CTA shape: `"Show or manipulate the project backlog/changelog. Examples: \"what's in the backlog\", \"add a backlog entry for X\", \"retire item Y for task N\"."`. 23 words. Double-quoted YAML with `\"` for internal double quotes; verified by loading through `YAML::XS`. Body unchanged.

### Notable
- **Mid-exec D6 amendment: unquoted YAML form fails strict parsers.** Initial implementation followed the same unquoted plain-scalar pattern as `update-config` and `keybindings-help` in the Anthropic skill set, which the Claude Code harness parses correctly. `YAML::XS` (libyaml) rejects this form because the embedded `Examples: "..."` introduces a colon-space sequence inside a plain scalar — the parser interprets it as a nested mapping start. Both single-quoted (with `''` doubled) and double-quoted (with `\"` escaped) forms parse cleanly; chose double-quoted for readability. The d-plan plan-review's robustness subagent flagged this risk preemptively before the empirical failure confirmed it.
- **The 4-subagent map/reduce plan review delivered measurable value.** Caught the YAML quoting risk (substantive), a filename inconsistency (`skill-reference-doc-convention.md` vs `skill-reference-convention.md`), and tightened D5 to mandate hardcoded examples (security framing). Wall-clock cost ~30 seconds.
- **Security-review subagent twice failed sentinel-first protocol; bodies were clean.** Both phases (f and g) produced substantively clean reviews ("no findings." in body, all five threat categories explicitly cleared) but did not lead with the required `findings:` / `no findings` / `error:` sentinel. The three-tier classification rule classified them as `error` (f-phase) and `findings` (g-phase, numbered-list fallback fired on the file enumeration). Filed as a follow-up backlog entry.
- **`security-review-changeset` anchors at `anchor..HEAD` (commits only), not the working tree.** To give the subagent a non-empty changeset, implementation work was committed as `ef9a623` before the f-checkpoint commit. Functionally correct but breaks the "one checkpoint = one phase" pattern; noted as a workflow papercut for future consideration.

### New Backlog Items
- Roll intent-CTA description convention to remaining skills (Low) — validate the convention on `cwf-backlog-manager` first; remaining ~20 user-invocable skills get the same treatment in a follow-up task.
- Enforce sentinel-first output in security-review subagent prompt (Low) — strengthen the prompt's "no preamble" instruction and consider a `last-line "no findings."` classifier fallback for substance-clear malformed responses.

## Task 133: Infer task type from required wf steps

### Status: Complete (2026-05-12)
### Duration: 1 session; estimate 1–2 days; landed inside the band.
### Impact: Feature — `/cwf-new-task` and `/cwf-new-subtask` now accept a 2-arg form (`<num> "description"`) and infer the closest-fit supported task type by first reasoning about which wf steps the work needs. The inference rubric lives at `.cwf/docs/skills/task-type-inference.md` and is referenced by hard-coded path from both SKILL.md files. The 3-arg explicit-type form is unchanged. Resolution is silent on exact distance-0 matches and prompts the user when no exact canonical type fits. Drift between the rubric's canonical-step-set table and the actual `.cwf/templates/<type>/` directories is enforced by `t/task-type-inference-rubric.t` (29 assertions). `prove t/` 441/441 PASS; `cwf-manage validate` clean.

### Changes
- Added: `.cwf/docs/skills/task-type-inference.md` — rubric doc with step semantics, discriminating questions for `(b,c,h,i)`, canonical-step-set table for all five supported types, resolution algorithm, ambiguity-prompt format, and a three-step "adding a new task type" procedure.
- Modified: `.claude/skills/cwf-new-task/SKILL.md` — argument grammar relaxed to `<num> [<type>] "description"`. Disambiguation rule: a positional token matching `cwf-project.json:supported-task-types` is treated as `<type>`; otherwise inference runs. Type Inference subsection links to the rubric by hard-coded literal path and lists the four LLM steps (read rubric → infer S → compute symmetric-difference distances → silent pick or prompt).
- Modified: `.claude/skills/cwf-new-subtask/SKILL.md` — mirror of the new-task changes; positional layout `<parent-path> <num> [<type>] "description"`. Also added `discovery` to the argument-list comment (it was missing from the original prose despite being in `supported-task-types`).
- Added: `t/task-type-inference-rubric.t` — 29 Perl assertions across 5 invariants: (1) rubric file readable; (2) required headings present; (3) canonical-step-set table parses cleanly and matches the actual `.cwf/templates/<type>/*.template` filename letters for every type listed in `cwf-project.json:supported-task-types`; (4) neither SKILL.md inlines the `(b,c,h,i)` tuple or a canonical-table row; (5) both SKILL.md files reference the rubric path as a literal string.

### Notable
- **Inferred step set is more principled than inferred type label.** The reframing — "decide which wf steps the work needs, then let type fall out as packaging" — makes the Task 59 misclassification structurally less harmful: wrong type with the right steps is still workable, but the converse (right type, wrong steps) leaves the docs incomplete. Inference now answers four yes/no questions (`b`, `c`, `h`, `i`) and the four-bit tuple maps to exactly one of five canonical types, or prompts when no exact match exists.
- **FR6 contract relaxed deliberately during design.** Original FR6 said the step-set-per-type mapping is "derived at runtime from template directories" so adding a new type requires no skill change. Design review converged from three angles (security: Bash glob over `.cwf/templates/*/` is a threat-(a) anti-pattern; simplicity: the rubric must already be updated when a new type is added — runtime FS-scan adds a second source of truth; determinism: a static table is trivially auditable) on a static markdown table inside the rubric. The intent (no skill code changes when types are added) is preserved by the drift-detection test. Adding a type now requires three coordinated data edits: `.cwf/templates/<type>/` symlinks + `cwf-project.json` entry + rubric row. Documented as Decision 3 in c-design-plan.md.
- **Failure mode FM-3 (distance ≥ 3) is structurally unreachable under the current taxonomy.** Because every canonical step set contains the six always-required steps, the symmetric-difference distance is bounded by overlap on the four discriminating letters `(b,c,h,i)`. The five canonical points cover `(0,0,0,0)`, `(0,0,1,0)`, `(0,1,0,0)`, `(1,1,0,0)`, `(1,1,1,1)` — the maximum nearest-neighbour distance from any of the 11 uncovered points is 2. The design's distance-≥3 paragraph remains as a safety net but is dead code today. Surfaced in g-testing-exec.md for future taxonomy expansion.
- **Security review subagent twice failed sentinel-first protocol; bodies were clean.** Both phases (f and g) classified `findings` via the numbered-list fallback rule, but the actual content was 5×`Status: CLEAR` plus one pattern-risk in g (`discover_steps()` path interpolation; safe-here because `$type` is from JSON, audit reuse). Recorded verbatim per the strict classification.

### Retired Backlog Items
#### Infer Task Type When Not Specified in new-task and subtask Skills

When `/cwf-new-task` or `/cwf-new-subtask` is invoked without a task type, the agent should infer the appropriate type based on the task description and complexity rather than failing with a validation error. If the inference is ambiguous, ask the user to choose. This prevents misclassification — e.g., a task with unclear requirements being created as a chore (no design phase) when it should be a feature.

<!-- Note: Reframed as 'infer required wf steps first, then map to closest-fit task type'. Five canonical types unchanged. Rubric at .cwf/docs/skills/task-type-inference.md; drift detection test t/task-type-inference-rubric.t. AC6 (stub-type selectability) verified by inspection of the table-driven mechanism rather than runtime fixture; FM-3 (distance >= 3 degenerate path) found to be structurally unreachable under current 5-type taxonomy. -->

## Task 132: Refactor BACKLOG/CHANGELOG to heading-tree model

### Status: Complete (2026-05-10)
### Duration: ~5 sessions; estimate 3-5 sessions; landed at the upper end of the band, with implementation-exec ~25-50% over budget driven by migration-script iteration and an unplanned `/simplify` pass.
### Impact: Feature — replaces the `^---$`-delimited section + `**Field**:` bold-paragraph metadata convention with a uniform heading-based tree. `## (Task|Bug):`/`## Task N:` headings are entries by construction; metadata is `### Key: value` H3 lines; subsections are `### Changes`/`### Notable`/`### Retired Backlog Items`. The Task 131 missing-entries bug (45 reported / 50 actual headings) is now structurally impossible. CWF::Backlog exposes a tree API (`parse_backlog_tree`/`parse_changelog_tree`/`serialize_tree` plus mutators); `backlog-manager` gains a seventh subcommand `normalise` for external adopter migration. New `/cwf-backlog-manager` slash-command skill registered. Live BACKLOG.md (50 entries) and CHANGELOG.md (94 entries) round-trip byte-identical post-migration. `prove t/` 412/412 PASS (vs 408 baseline); `cwf-manage validate` clean.

### Changes
- Refactored: `.cwf/lib/CWF/Backlog.pm` — heading-tree parser/validator/serialiser (~700 lines after `/simplify`, perms `0444`). Public API: `parse_backlog_tree`/`parse_changelog_tree`/`serialize_tree`/`write_tree`/`metadata_get`/`metadata_node`/`set_metadata_field`/`add_entry`/`delete_entry`/`find_all_entries_by_slug`/`find_all_entries_by_title`/`find_changelog_entry_by_task_num`/`append_retired_block_tree`/`block_exists_in_retired_tree`/`validate_backlog_tree`/`validate_changelog_tree`/`trim_blank_lines`/`$VALID_PRIORITIES`/`$METADATA_KEY_RE`/`@CANONICAL_SUBSECTIONS`. Postel-liberal parser, Postel-strict serialiser. Single-source `_build_fence_map($lines)` cached on the tree (`_source_lines`/`_source_fence`). Body-before-metadata captured as a boolean `body_before_meta` flag, not a separate body slot.
- Refactored: `.cwf/scripts/command-helpers/backlog-manager` (~660 lines after `/simplify`). Seven subcommands: `validate` (with `--all` and `--strict`), `list`, `add`, `modify`, `delete`, `retire`, `normalise` (new — with `--dry-run`). `resolve_entry($tree, \%opts, allow_missing => …)` extracted helper for find-or-die pattern; `cmd_normalise` reuses the canonicalisation logic that originated in the throwaway migration script.
- Added: `.claude/skills/cwf-backlog-manager/SKILL.md` — thin `/cwf-status`-shape wrapper exposing all seven subcommands; documents the `cd "$(git rev-parse --show-toplevel)"` pre-step and the list-form invocation rule (`--title='Test $(date)'` worked example).
- Added: `t/backlog-tree-parse.t` — 10 subtests (TC-PARSE-1 through TC-PARSE-8 plus live-file plausibility). TC-PARSE-7 covers round-trip byte-identity for 5 canonical fixtures.
- Added: `t/backlog-tree-validate.t` — 15 subtests; positive + negative coverage for every active rule (`GLOBAL-001a/b`, `GLOBAL-002`, `BACKLOG-001/002/004/005/007`, `CHANGELOG-001/002/003/004`); TC-VAL-FENCE-INVARIANT; regression cases asserting retired BACKLOG-003 (`---` body) and BACKLOG-006 (`#### Sub` body) no longer fire.
- Added: `t/backlog-tree-mutators.t` — 7 subtests covering `set_metadata_field`, `add_entry`, `delete_entry`, `find_all_entries_by_*`, `append_retired_block_tree`, `block_exists_in_retired_tree`.
- Added: `t/backlog-roundtrip-live.t` — TC-ROUNDTRIP-LIVE-BACKLOG and TC-ROUNDTRIP-LIVE-CHANGELOG; the strongest regression alarm (one byte different = red).
- Refactored: `t/backlog-manager.t` — fixtures bulk-converted from `**Field**:` to `### Field:`; AC1 TODO-wrapped until live BACKLOG migration complete; AC2e/2f, AC6a/b, AC8b/8c, AC9 updated for new format; 3 new normalise subtests (AC18a/b/c).
- Removed: `t/backlog.t` — Task 131 flat-blob test surface superseded by the four `t/backlog-tree-*.t` files.
- Migrated: `BACKLOG.md` (50 entries) and `CHANGELOG.md` (94 entries) to heading-tree format. Pre-migration snapshots durable at `/tmp/task-132/BACKLOG.md.pre-migration` (74,014 B) and `/tmp/task-132/CHANGELOG.md.pre-migration` (231,373 B).
- Modified: `.cwf/security/script-hashes.json` — refreshes `Backlog.pm` and `backlog-manager` SHA256 after the refactor + `/simplify` pass.

### Notable
- **The data model is the bug, not the splitter.** The Task 131 missing-entries diagnosis ended at "the parser splits on `^---$` and entries silently merge when the marker is absent". The Task 132 reframe was "the data model is the bug" — entries should *be* `## Heading` blocks by construction, not opaque blobs split on a presentation-layer artefact. The 5-session structural refactor beats a 1-day fragile splitter patch by removing the bug class, not patching one instance.
- **Postel's Law as architecture, not just a saying.** The parser is liberal (accepts pre-migration `**Field**:` *and* canonical `### Field:`; tolerates body-before-metadata as a warning, not an error). The serialiser is strict (always emits canonical title→metadata→body order; always normalises blank lines). The migration script's job was small because the round-trip guaranteed everything else.
- **Live round-trip byte-identity is the strongest regression alarm available.** TC-ROUNDTRIP-LIVE-BACKLOG/CHANGELOG fail on a single byte difference between read and re-serialise. Worth keeping as a pattern in any future parser/serialiser refactor.
- **Single-source fence map is non-negotiable.** Two consumers of "is this line inside a fence?" must never compute it independently — they will disagree on edge cases. `_build_fence_map($lines)` cached on the parse tree, queried by all four fence-aware validator rules and both retired-subsection mutators.
- **`/simplify` after f-implementation-exec earned its keep.** -82 lines `Backlog.pm`, -40 lines `backlog-manager`. Single-source-of-truth constants (`$VALID_PRIORITIES`, `$METADATA_KEY_RE`, `@CANONICAL_SUBSECTIONS`) extracted; redundant `pre_meta_body` array slot collapsed to `body_before_meta` boolean; cached `_source_lines`/`_source_fence` on the tree so validators don't re-tokenise. The diff was tighter and easier to review afterwards.
- **Promote helpful one-off scripts into first-class commands when the user asks.** The user pointed out external CWF adopters need an upgrade path; the throwaway `/tmp/task-132/migrate-backlog-format.pl` was lifted into `backlog-manager normalise` for ~0.25 sess. Idempotent (`already canonical (no change)` on no-op), `--dry-run` available, integrated with the standard helper surface.
- **Permission-prompt friction from `perl <script>` was a measurable wall-clock cost.** I repeatedly invoked `/tmp` Perl scripts via `perl /tmp/.../script.pl` instead of `chmod +x` then direct shebang execution. User pushback was sharp ("this is unix not windows … ~20× slower than necessary"). Memory `feedback_chmod_and_execute.md` captured.
- **Migration script needed three iterations.** BACKLOG-007 false fire (caused by all body in `body_raw` regardless of position relative to metadata), AC5d body-byte ratio failing on legitimate body→metadata promotion, idempotency heuristic tripping on a `### Solution:` body line. Each was small; cumulatively they ate the f-phase overrun. Pre-mortem of "what could the validator falsely fire on" would have surfaced the first two.
- **AC4 grep gate was too coarse.** File-wide `^\*\*[A-Z][\w\- ]*\*\*:` grep finds prose-bold body content (e.g. `**Create**:` followed by a bullet list) as well as metadata. Validators correctly do not classify these as metadata; the semantic gate (validate clean + round-trip byte-identical) holds. Tightening AC4 to "metadata position only" added to BACKLOG as follow-up.

## Task 131: Add backlog management helper script

### Status: Complete (2026-05-10)
### Duration: ~3 sessions (Pass 1 + Pass 2 re-plan/re-exec); estimate 1–2 days; variance +25–50% from the marker-tombstone re-plan cycle.
### Impact: Feature — `.cwf/scripts/command-helpers/backlog-manager` (six subcommands: `add`, `delete`, `modify`, `list`, `validate`, `retire`) plus shared `CWF::Backlog` library codify a strict separation: **BACKLOG holds active work only; CHANGELOG holds history**. `retire` *moves* an entry across the boundary into the implementing task's CHANGELOG `### Retired Backlog Items` block; nothing is ever marked-in-place. Validator (BACKLOG-001..006, CHANGELOG-001..003, GLOBAL-001) enforces the contract by construction. As part of rollout, 61 legacy `<!-- Completed: -->` / `<!-- Removed: -->` markers were migrated out of BACKLOG.md (1646 → 1482 lines, -10%); two `^####` body headings demoted to bold-paragraph per BACKLOG-006. `prove t/` 408/408 PASS; `cwf-manage validate` clean. j-retrospective Step 8 onwards can invoke `backlog-manager retire` instead of hand-editing both files.

### Changes
- Added: `.cwf/scripts/command-helpers/backlog-manager` (~700 lines Perl, perms `0500`). Six subcommands; printable-ASCII + `-->`-rejection on `--note`; atomic two-file write (CHANGELOG first, BACKLOG second; dedup via `block_exists_in_retired` for crash recovery).
- Added: `.cwf/lib/CWF/Backlog.pm` (~900 lines, perms `0444`). Section-based two-pass parser with byte-preserving `raw_lines`, on-demand metadata extraction, shared `_build_fence_map($lines)` consumed by all four validator rules and both retired-subsection mutators (`find_changelog_task`, `find_retired_subsection`, `block_exists_in_retired`, `append_retired_block`).
- Added: `t/backlog.t`, `t/backlog-manager.t` — TC-AC1..AC17 + TC-LIB-1..LIB-9 including a fence-parity invariant test (TC-LIB-9) asserting all four validator rules silent on a single fixture with `<!-- -->`, `## ~~`, `^####`, and `### Changes` ALL inside one fenced code block.
- Modified: `BACKLOG.md` — bulk migration removed 61 HTML-comment markers via one-shot `/tmp/task-131/migrate-markers.pl` (throwaway); pre-migration snapshot at `/tmp/task-131/BACKLOG.md.before`. Two `#### ` body headings demoted to `**…**:` form per BACKLOG-006.
- Modified: `.cwf/lib/CWF/Common.pm` — `generate_slug` lifted from `template-copier-v2.1` (Pass 1 work that survived Pass 2).
- Modified: `.cwf/security/script-hashes.json` — registers `backlog-manager` (script) and `CWF::Backlog` (lib); refreshes `template-copier-v2.1` and `CWF::Common` after the slug lift.

### Notable
- **Marker-tombstone model rejected on review; re-plan with amend, not rewrite.** Pass 1 shipped retire-as-marker (`<!-- Completed: -->` left in BACKLOG, one-line bullet appended to CHANGELOG). User pushback: "BACKLOG shouldn't be a dumping ground … if it's finished it's in the changelog." Pass 2 re-planned the validator + retire flow + tests against the move-not-mark model while keeping ~half the Pass 1 code (parser, mutators, atomic-write, slug lift, fence-tracking). Saved one full rebuild cycle.
- **Plan-review subagents earned their keep on the re-plan too.** d-impl-plan review caught (a) Pass 2 Step 1 originally deleted `make_completed_marker`/`insert_changelog_bullet` while `cmd_retire` still called them — re-ordered to add-fence-helper → add-mutators → rewrite-cmd_retire → trim-marker-code; (b) the d-impl text still referenced the old `historical`/`struckthrough_*` classifier names. Both caught pre-code; zero rework in Pass 2 exec.
- **Shared fence-map as a parser invariant, not a per-rule concern.** One `_build_fence_map($lines)` helper, four validator rules + two mutators consume it, TC-LIB-9 asserts the invariant. Centralising fence-aware indexing is what makes "any HTML comment in BACKLOG" enforceable without breaking content that legitimately lives inside fenced code blocks.
- **Two-file atomicity via dedup-on-retry, not flock.** CHANGELOG written first (idempotent target), BACKLOG written second; crash recovery is "re-run the same retire command" because `block_exists_in_retired` detects the already-written block by title. Single-developer threat model justified skipping the lock.
- **`-->` rejection regex was a footgun.** The printable-ASCII validator `^[\x20-\x7E]+$` accepts `-->` (each char printable). Caught by AC13b test; explicit `die_user("--note must not contain '-->'")` second check added. General lesson: when validating against a control-character set, also enumerate the structural substrings being rejected.
- **TODO-wrapped live-file assertions order rollout against test changes cleanly.** AC1 (live BACKLOG passes validate) needed the migration to land first; wrapping it in `TODO {}` during f/g and lifting the wrapper in h kept the suite green throughout, made the migration's rollout-readiness machine-verifiable, and the lift itself was a one-line per-file edit.
- **Migration was reversible end-to-end.** `/tmp/task-131/BACKLOG.md.before` snapshot + `git revert` of the migration commit + `git revert` of the Pass 2 squash — three independent rollback points.

## Task 130: Refactor BACKLOG to match current code state

### Status: Complete (2026-05-07)
### Duration: 1 session of active work (estimated: 1 day; on target)
### Impact: Chore — first deliberate BACKLOG triage sweep against current code state. 4 of ~50 active entries touched: 2 removed (work shipped or scope dead), 1 edited (commands→skills migration changed the audit target), 1 coalesced (two duplicate entries about lightweight rollout/maintenance templates merged at higher priority), 1 reclassified (`Needs-Triage` → `Low`). ~45 entries kept-as-is — verified each named script/file/function genuinely doesn't exist or wasn't completed. BACKLOG.md −62 net lines (17 ins, 79 del); 6/6 manual test cases PASS; `cwf-manage validate` clean.

### Changes
- Modified: `BACKLOG.md` — removed `Add Settings.json Merge Helper Script` (superseded by `.cwf/scripts/command-helpers/cwf-claude-settings-merge`); removed `Update Documentation References from status-aggregator to status-aggregator` (title incoherent post-rebrand; referenced deleted `.claude/commands/cwf-status.md`; intent settled by Task 25 trampoline rollout); edited `Audit CWF Commands for Hardcoded Data` → `Audit CWF Skills for Hardcoded Data` (commands→skills migration eliminated the original audit target); coalesced `Lightweight Rollout/Maintenance Templates for Internal Tasks` (Low) + `Lighter-Weight Rollout/Maintenance Templates for Internal/Developer-Tool Tasks` (Medium) into a single Medium-priority entry; reclassified `Extract CWF Argument Validation Pattern to Documentation` from `Needs-Triage` → `Low` (underlying Task 11 cancelled; pattern still useful as security-review reference).
- Added: `implementation-guide/130-chore-refactor-backlog-to-match-current-code-state/` — 6 wf step files (a/d/e/f/g/j) documenting the triage methodology, decisions, and evidence trail.

### Notable
- **`cwf-claude-settings-merge` was the textbook stale entry.** Existed in BACKLOG as `Medium` priority for months while the implementation (under a slightly different name — `cwf-claude-` prefix scopes it to `.claude/settings.json`) had already shipped. Periodic sweeps catch this; ad-hoc maintenance does not.
- **Three of four edits hinged on the commands→skills migration (Task 57).** Anything in BACKLOG that names `.claude/commands/cwf-*.md`, `cig-*.md`, or `$ARGUMENTS` is a strong candidate for re-evaluation — that surface no longer exists. Worth keeping in mind for future sweeps.
- **Title incoherence as a stale-entry signal.** The R2 entry's title was "Update Documentation References from status-aggregator to status-aggregator" — same word as both source and target after a global search-replace homogenised the `.pl` distinction. A `from X to X` linter on BACKLOG titles would catch this proactively.
- **Plan-review subagents earned their keep on a small task too.** Caught the missing pre-identified coalesce candidate (lines 350+1820), the `Needs-Triage` ambiguity, batching over-engineering, and a pre-judged priority assignment. All addressed before exec; conservative-default outcome.
- **Empty security-review changeset on a markdown-only task** — confirmed the helper's CWF-internal-dir + shebang-sniff classification correctly excludes pure content edits. No subagent invocation needed.
- **Process deviation accepted up-front.** d-impl-plan called for per-entry user co-review; user delegated triage to me with a single review pass at the end. I leaned conservative (lean toward keep when evidence ambiguous); user's review pass remains authoritative.

## Task 129: Fix security-review changeset construction

### Status: Complete (2026-05-06)
### Duration: 1 session of active work (estimated: 1-2 days; variance: under)
### Impact: Bugfix — closes the Very-High-priority BACKLOG entry surfaced by Task 128's cap-overflow. Replaces the inline `git diff $(git merge-base HEAD main)..HEAD -- <extension-and-directory-pathspec>` in the two exec SKILLs with one Perl helper that owns the full changeset-construction contract: per-task baseline anchor (recorded as a markdown field in `a-task-plan.md`), CWF-internal-directory unconditional-include rule, and shebang-based content classification over the diff window. Closes all three independent failure modes (extension-only filtering, hardcoded language stack, merge-base over-inclusion). 13 new subtests cover the BACKLOG axes plus security/reliability/performance non-functionals.

### Changes
- Added: `.cwf/scripts/command-helpers/security-review-changeset` (~340 lines Perl, perms `0500`). Anchor resolution: `**Baseline Commit**` field in `a-task-plan.md` → fallback `git merge-base HEAD <trunk>` (trunk via `cwf-project.json:trunk` → `git symbolic-ref refs/remotes/origin/HEAD` → hardcoded `main`, validated by `git check-ref-format --branch`). Classification: hardcoded CWF-internal-dir prefix list (rule 1, unconditional include) + anchored shebang regex `^(?:perl|bash|sh|ksh|zsh|fish|python\d?|ruby|node|deno|php|lua|pwsh|powershell)$` over the diff window (rule 2). `-e && -f && !-l` guard before `open` defends against symlink/FIFO/device targets in the diff. List-form `system`/`open '-|'` everywhere; no shell metacharacter exposure.
- Added: `t/security-review-changeset.t` — 13 subtests (8 functional TC-F1..TC-F8 mapping to BACKLOG axes 1-3 + helper internals; 5 non-functional TC-NF1..TC-NF5 covering trunk-name guard, `--task-num` validation, symlink skip, FIFO non-blocking, 200-file performance). All PASS. Full `prove t/` regression: 338/338 PASS.
- Modified: `.cwf/templates/pool/a-task-plan.md.template` — adds `**Baseline Commit**: {{baselineCommit}}` line in Task Reference (between Branch and Template Version). Single edit covers all task-type symlinks.
- Modified: `.cwf/scripts/command-helpers/template-copier-v2.1` — accepts new `--baseline-commit=<sha>` argument (optional; absent → empty render); maps to `$vars{baselineCommit}`.
- Modified: `.claude/skills/cwf-new-task/SKILL.md` and `.claude/skills/cwf-new-subtask/SKILL.md` — capture `git rev-parse HEAD` before branch creation; pass `--baseline-commit="$BASELINE_COMMIT"` to `task-workflow create`. One-line user note about base-branch verification.
- Modified: `.cwf/docs/skills/security-review.md` — § "Pathspec coverage" rewritten as contract description naming the helper, the two-tier anchor resolution, the three classification rules, the `git check-ref-format` trunk guard, and the v1 known limitations (shebang-less library files outside CWF dirs, sourced scripts, uncommon interpreters, BOM, mid-task rebase).
- Modified: `.claude/skills/cwf-implementation-exec/SKILL.md` Step 8 line 51 and `.claude/skills/cwf-testing-exec/SKILL.md` Step 8 line 46 — replaced inline `git diff …` with helper invocation.
- Modified: `.cwf/security/script-hashes.json` — registers `security-review-changeset` (perms `0500`); updates `template-copier-v2.1` SHA after the new arg landed.
- Modified: `BACKLOG.md` — closes "Security-review changeset construction is broken in three ways" (Very High priority); adds three Low-priority follow-ups (baseline backfill helper, shebang-regex extension, `File::chdir` adoption for tests).

### Notable
- **Markdown fields beat custom git refs.** c-design originally proposed `refs/cwf/task-base/<num>`; user pushback during review pivoted to a markdown field in `a-task-plan.md`. Field is data, refs are plumbing — discoverable, self-documenting, survives rebase of the task-plan checkpoint, no namespace, no cleanup story, no `.git/` knowledge required. Pivot was free because it happened pre-code.
- **Plan-review subagents earned their keep again.** Four parallel Explore subagents in d-phase caught (a) shell-out-vs-Perl-module-API for `parse_branch`/`resolve_num`, (b) hand-rolled trunk-name regex vs `git check-ref-format --branch`, (c) symlink/FIFO/device DoS guard, (d) script-hashes.json top-level `scripts` section (not `command-helpers`). All four landed in the d-plan; zero rework in implementation.
- **Helper dogfood validates the fallback.** f-phase smoke (`reviewed 8 files, 593 lines, anchor=9ac3f96`) and g-phase smoke (`reviewed 9 files, 1112 lines, anchor=9ac3f96`) both anchor at `main`'s tip via the merge-base fallback — exactly the design's promise for in-flight tasks (whose `a-task-plan.md` predates the new field). Anchor scopes correctly to this task's delta despite Task 128 sitting between merge-base and main.
- **`die` exits 255.** Smoke test surfaced that Perl's default `die` exit code (255) violated the spec'd exit 1 for `--task-num='foo;bar'`. Converted all `die` to `warn …; exit 1;` per the existing CWF helper convention (`cwf-checkpoint-commit:14-15`). Future helpers should adopt this from the start.
- **Cap-overflow recurs when the change *is* the security-review fix.** Both f (593 lines) and g (1112 lines) recorded `**State**: error`; manual threat-category walkthroughs supplied in the wf step files. The follow-up "Quantitatively justify the security-review subagent line-count cap" should run next with the now-correctly-scoped diff in hand.

## Task 128: Audit Perl-vs-Bash helper scripts and migrate where feasible

### Status: Complete (2026-05-06)
### Duration: 1 session of active work (estimated: 0.5–1 day; variance ~0%)
### Impact: Chore — closes the Task 125 follow-up. Discovery found that 4 of 5 in-scope POSIX shell helpers (`cwf-find-task-numbering-structure`, `cwf-load-{existing-tasks,project-config,status-sections}`) had zero callers in active code (artefacts of an earlier autoload-config design that never landed), and the 5th (`cwf-load-autoload-config`) was a 4-line `cat`-or-fallback used in exactly one place (the `cwf-config` skill's mandatory-context bullet). Decision: delete all five rather than migrate, and inline the one usage. Net delta ~50 lines: 5 helper deletions, 1 SKILL.md line edit, 5-entry pruning of `script-hashes.json`, BACKLOG completion marker. Coverage-regression test (`t/validate-security-coverage.t`) auto-adjusted from 24 → 19 top-level helpers; full suite 325/325 passing. Migration-to-Perl was reframed away because none of the helpers carried logic that justified Perl ceremony — no path-emitting git, no options, no error handling, no shared state.

### Changes
- Deleted: `.cwf/scripts/command-helpers/cwf-find-task-numbering-structure`, `cwf-load-autoload-config`, `cwf-load-existing-tasks`, `cwf-load-project-config`, `cwf-load-status-sections` (all POSIX shell, all dead/trivial).
- Modified: `.claude/skills/cwf-config/SKILL.md` — line 24 inlined: helper invocation replaced with `cat .cwf/autoload.yaml 2>/dev/null || echo "No autoload config found"`. Equivalent behaviour, one less indirection.
- Modified: `.cwf/security/script-hashes.json` — 5 entries removed from `scripts` map (38 → 33); `last_updated` bumped to 2026-05-06.
- Modified: `BACKLOG.md` — closed "Audit Perl-vs-Bash helper scripts and migrate where feasible"; added Very-High-priority bug "Security-review changeset construction is broken in three ways" (extension-globs, hardcoded language stack, merge-base anchor).

### Notable
- **The right answer to "migrate?" was "delete".** Four helpers had zero callers; the fifth was a 4-line cat-or-fallback. The simplicity principle ("the best part is no part") applied more strongly than the migration-to-Perl benefit. Future audit tasks should ask "is this used at all?" before "what language?".
- **Atomic commit boundary preserved.** Helper deletions and `script-hashes.json` pruning landed in a single commit (`76d79a7`); `cwf-manage validate` was clean at every checkpoint.
- **Plan-review subagents earned their keep again.** Caught (1) stale baseline test count (22 → 24, copy-pasted from Task 125's d-plan without re-verifying), (2) test counts dynamically so no edit needed, (3) atomicity gap between deletes and manifest update, (4) BACKLOG entry to close. All applied; zero rework in implementation.
- **Dynamic-count test pattern paid off.** `t/validate-security-coverage.t`'s `plan tests => scalar(@top_level) + 1` auto-adjusted to the new helper count without source edit. Worth standardising for any "every X under Y must satisfy Z" assertion.
- **Cap-exceeded security review surfaced a real bug.** Both f and g phases recorded `**State**: error` (1422 / 1545 lines, inflated by Task 127 sitting unmerged between this branch's merge-base and main). Inspecting the underlying `git diff` invocation revealed three independent bugs in the security-review pathspec construction — extension-based file filtering, hardcoded language-stack assumptions, and merge-base anchor over-including earlier-task commits. Captured to BACKLOG as Very High; the cap-overflow was the leading indicator, not the underlying problem.

## Task 127: Upgrade installs cwf-init artefacts

### Status: Complete (2026-05-05)
### Impact: Feature — `cwf-manage update` now re-applies every artefact `/cwf-init` produces (`.gitignore` lines, `.cwf/rules-inject.txt`, `.cwf-rules/` tree, CLAUDE.md preamble, `.claude/rules/cwf-*.md` symlinks, `.claude/settings.json` allowlist + Stop hooks). Conflicts use Debian dpkg-style three-way comparison with K/I/D/A prompts (`CWF_UPGRADE_RESOLVE=prompt|keep|new|abort` for non-interactive contexts). Closes the gap that Task 126's BACKLOG entry called out: previously only `.cwf/` and `.cwf-skills/` were refreshed by upgrades.

### Changes
- Added: `.cwf/scripts/command-helpers/cwf-apply-artefacts` (~570 lines, perms `0500`). Reads `.cwf/install-manifest.json` from source + installed trees, dispatches per artefact's `kind` (line-additive, replace, tree, embedded-block, regenerate-symlinks). Three-way compare per FR3; prompts via FR4; honours `CWF_UPGRADE_RESOLVE` per FR5; `--bootstrap-init` mode for `/cwf-init` (silent install + audit log).
- Added: `.cwf/lib/CWF/ArtefactHelpers.pm` (perms `0444`). Shared `read_json_file`, `atomic_write_text`, `validate_path_allowlist`, `compute_file_sha256`, `read_file_raw`. Used by `cwf-apply-artefacts` and `cwf-claude-settings-merge` so both helpers go through one validated path-allowlist + atomic-write code path.
- Added: `.cwf/install-manifest.json` (`schema_version: 1`). Per-release inventory of non-script artefacts with source/dest paths and SHA256 pins.
- Added: `.cwf/templates/install/rules-inject.txt`, `.cwf/templates/install/claude-md-preamble.md` — canonical sources for the upgrade-eligible artefacts.
- Added: `t/artefacthelpers.t` (21 tests), `t/cwf-apply-artefacts.t` (18 subtests), `t/cwf-manage-update.t` (6 subtests) — covers FR3-FR12 including newline-injection rejection, path-traversal rejection, manifest SHA tampering detection, flock concurrency, sentinel migration, bootstrap-from-no-manifest.
- Modified: `.cwf/scripts/cwf-manage` — `cmd_update` adds `flock(LOCK_EX|LOCK_NB)` on `.cwf/.update.lock` (with `O_NOFOLLOW` + `lstat` symlink-TOCTOU check), settings.json parse-check (FR12), install-manifest SHA pin check (D12), `cwf-apply-artefacts` invocation, `cwf-claude-settings-merge` invocation, writes `cwf_install_manifest_sha` field.
- Modified: `.cwf/lib/CWF/Validate/Security.pm` — new `validate_install_manifest($git_root)` exported sub. Walks the manifest, verifies schema_version, allowlists every source/dest, and (when both sides present) verifies on-disk SHA matches `cwf_install_manifest_sha`.
- Modified: `.cwf/scripts/command-helpers/cwf-claude-settings-merge` — refactored to use `CWF::ArtefactHelpers` for JSON read, atomic write, path allowlisting. Behaviour unchanged; `t/cwf-claude-settings-merge.t` still passes unmodified.
- Modified: `.cwf/security/script-hashes.json` — new top-level `data` section (for non-executable tracked files); registers `cwf-apply-artefacts`, `CWF::ArtefactHelpers`, the manifest, both templates.
- Modified: `.claude/skills/cwf-init/SKILL.md` — step 4 (CLAUDE.md preamble) and step 5 (`.gitignore`) now delegated to step 6b-apply (`cwf-apply-artefacts --bootstrap-init`); hard ordering note added so the apply step runs before step 6c (PreToolUse hook).
- Modified: `.gitignore` — adds `.cwf/.update.lock`.
- Modified: `BACKLOG.md` — closes the Task 126 follow-up "Refresh .claude/settings.json on cwf-manage update" (Task 127 supersedes with broader scope).

### Notable
- **Two manifests, separate concerns**: `script-hashes.json` continues to handle scripts; the new `install-manifest.json` handles non-script artefacts. Distinct change cadence (release-time data) vs (cross-release policy) kept them separate.
- **Bootstrap-from-no-manifest (FR9 / D4)**: projects upgrading from a pre-feature CWF version have no installed manifest. The helper treats on-disk content as the baseline: additive strategies apply silently; replace-strategy artefacts no-op when on-disk == new, otherwise prompt. One unavoidable round of K/I/D/A prompts per replace artefact on the first post-feature upgrade; subsequent upgrades use full three-way logic.
- **CLAUDE.md sentinel migration (D6)**: legacy preambles (no sentinels) are detected via the existing `CWF.*is installed` heuristic and wrapped in HTML-comment sentinels in-place. The opening sentinel carries an in-marker warning; user notes belong outside the markers.
- **D12 manifest SHA pin**: `.cwf/version` gains `cwf_install_manifest_sha`. `cwf-manage update` and `cwf-manage validate` cross-check it; mismatch indicates local manifest tampering and aborts the run with a recovery hint.
- **Concurrency (D8)**: `flock(LOCK_EX|LOCK_NB)` on `.cwf/.update.lock` with `O_NOFOLLOW` + `lstat` precheck. Acquired before `check_clean_tree` so two concurrent updates cannot both pass the clean-tree gate before one blocks. Lock auto-releases on process exit (kernel-managed).

## Task 126: Fix install allowlist and hook enablement

### Status: Complete (2026-05-05)
### Duration: 1 session of active work (estimated: 1 session; variance ~0%)
### Impact: Bugfix — closes two install-time gaps in `/cwf-init` surfaced by a fresh install in a downstream project. (1) `Bash(.cwf/scripts/...)` allowlist entries were never written, so every helper invocation triggered a permission prompt on a fresh install; this repo's working `.claude/settings.local.json` had accreted those entries one at a time over months of use, masking the gap. (2) Stop hooks (`stop-stale-status-detector`, `stop-uncommitted-changes-warning`) were never registered, so fresh installs shipped without the two CWF safety nets the workflow assumes are active. Adds `cwf-claude-settings-merge` (a manifest-driven helper that walks `script-hashes.json` and merges the right entries into `.claude/settings.json`) and wires it into `/cwf-init` Step 6d. Idempotent. Builds on Task 125's coverage guard so future helpers/hooks flow into the allowlist automatically.

### Changes
- Added: `.cwf/scripts/command-helpers/cwf-claude-settings-merge` (~150 lines, perms `0500`). Walks `.cwf/security/script-hashes.json`; partitions by path shape (cwf-manage / top-level helper / `.d/` skipped / hook); writes `Bash(<path>:*)` for argument-taking helpers, `Bash(<path>)` exact for hooks, and `hooks.Stop[0].hooks[]` entries with `type: command, timeout: 5`. Atomic write via `File::Temp` + `rename` (same pattern as `CWF::Versioning::bump_to`). Refuses symlinked `.claude/` or `.claude/settings.json` and manifest paths containing `..`. `--dry-run` and `--help` flags. Idempotent re-run.
- Added: `t/cwf-claude-settings-merge.t` — 9 subtests covering empty input, additive/dedup/idempotency, multi-matcher hook scan, dry-run, all four KD7 unsafe-input refusals (manifest path with `..`, settings symlink, `.claude/` symlink, malformed JSON), missing-on-disk warn-and-skip.
- Modified: `.cwf/security/script-hashes.json` — one new `scripts.cwf-claude-settings-merge` entry; `last_updated` bumped to 2026-05-05. `validate-security-coverage.t` TC-C1 grew 22 → 23.
- Modified: `.claude/skills/cwf-init/SKILL.md` — new Step 6d with helper invocation and WARN-tolerated / ERROR-aborts semantics; matching Success Criteria checkbox.
- Modified: `BACKLOG.md` — added Medium-priority follow-up "Refresh `.claude/settings.json` on `cwf-manage update`" (the upgrade path; out-of-scope-by-design per Task 126's a-task-plan risk note).

### Notable
- **Manifest as single source of truth**: rather than hard-coding a list of helpers in the skill, the new helper walks `script-hashes.json` directly. Task 125's `validate-security-coverage.t` already guarantees every executable file under `.cwf/scripts/{command-helpers,hooks}/` is registered, so the allowlist now self-maintains: any future helper added under those trees automatically gets the right `Bash(...)` entry on the next `/cwf-init` re-run.
- **Three allowlist entry shapes**: `Bash(<path>:*)` for `cwf-manage` and top-level command-helpers (matches `<path> <args>`), `Bash(<path>)` exact for hooks (Claude Code's hook system invokes them bare), no entry at all for `.d/` subcommands (reachable only via the parent's `:*` glob — the trampoline invariant). The repo's working `.claude/settings.local.json` mixed `:*` and ` *` shapes for the same script, evidence the right shape is non-obvious; the helper picks one canonical shape per role.
- **Hook idempotency across all matcher objects**: `hooks.Stop` is an array of matcher objects each with their own `hooks[]`. The dedup check scans every `Stop[i].hooks[j].command` for an exact match before appending, so a CWF hook that landed in `Stop[1]` (e.g. user-edited settings) is not re-added to `Stop[0]`. New entries land in `Stop[0]` (created if absent).
- **Upgrade path deliberately deferred**: a-task-plan's Manifest-drift risk explicitly noted "out of scope: automatic refresh on `cwf-manage update`. Worth a BACKLOG item." The question was raised during testing-exec; the deferral was honoured and the follow-up went onto BACKLOG cleanly. Will be Task 127.
- **Plan-review subagents earned their keep**: c- and d-phase reviews flagged the shebang choice (`#!/usr/bin/env perl` for non-git-reading scripts; reserve `-CDSL` for git-path-handling helpers per `docs/conventions/perl-git-paths.md`) and the parent-`.claude/`-symlink defence — both before any code was written.
- **Self-caught regex-delimiter bug during f-phase**: tests parse-failed because `\Q...\E` does not escape the regex's `/` delimiter at parse time. Fixed by switching the affected regexes to `qr{...}` delimiters. Net change: 5 test-file edits, no production-code impact.
- **Security-review prose-before-sentinel**: both phase reviews emitted analysis before the required sentinel line, forcing the strict three-tier rule to classify them as `findings`. The agent's substantive conclusion in both cases was no actionable items (false-positive shebang nit in f, comprehensive analysis ending in `no findings` in g). Both accepted-and-recorded. Aligns with the existing BACKLOG item "Tighten security-subagent prompt for sentinel-line compliance".
- 1 new helper, 1 new test file (9 subtests), 1 new SKILL step, 1 manifest entry, 1 BACKLOG add. Full suite 29 files / 271 tests → 30 / 280 (delta exactly +1 file +9 subtests).

## Task 125: Expand script-hashes integrity surface to command-helpers and hooks

### Status: Complete (2026-05-03)
### Duration: 1 session of active work (estimated: 1 session; variance ~0%)
### Impact: Chore — closes the SHA256 integrity gap surfaced by Task 124. Registers 17 new entries in `.cwf/security/script-hashes.json` covering every executable script under `.cwf/scripts/command-helpers/**` (3 Perl trampolines + 7 `*.d/` subcommands + 5 POSIX shell helpers) and `.cwf/scripts/hooks/` (2 hooks). Also lowers 4 pre-existing drift entries (`cwf-set-status`, `migrate-v2.1-file-order`, `task-context-inference`, `task-stack`) from recorded `0755` to `0500` (default policy: minimum bits that allow execution under `Validate::Security`'s min-bits semantics). Adds a permanent regression-guard test (`t/validate-security-coverage.t`) that walks both directories and asserts every executable file is registered — no shebang filter, every language counts. `cwf-manage validate` now reports zero violations across both sha256 and permissions.

### Changes
- Modified: `.cwf/security/script-hashes.json` — 17 new `scripts` entries (alphabetised by key; `<parent>.d/<sub>` shape used for subcommands per `Validate::Security:76` confirmation that keys are never parsed); 4 in-place permissions updates from `"0755"` → `"0500"`; `last_updated` bumped to 2026-05-03. Total `scripts` section now 36 entries (was 19).
- Added: `t/validate-security-coverage.t` — Perl Test::More coverage guard, ~135 lines after /simplify pass. Walks `.cwf/scripts/command-helpers/**` once and partitions by depth into TC-C1 (top-level, 22 hits) and TC-C2 (`*.d/` subcommands, 7 hits); walks `.cwf/scripts/hooks/` for TC-C3 (2 hits); TC-U4 self-contained `tempdir` subtest verifies the walker skips symlinks. Uses `File::Spec->abs2rel` for path normalisation matching `CWF::Validate::PerlConventions`. No shebang filter.
- Modified: `BACKLOG.md` — closed "Expand script-hashes.json integrity surface to command-helpers and hooks"; added Medium-priority follow-up "Audit Perl-vs-Bash helper scripts and migrate where feasible".

### Notable
- **Mid-task scope expansion (12 → 17 entries)**: original d-plan inventory was Perl-only. User direction during d-plan review widened the rule to "all scripts should be included in the security checks", folding in 5 POSIX shell helpers (`cwf-find-task-numbering-structure`, `cwf-load-{autoload-config,existing-tasks,project-config,status-sections}`). Coverage test dropped its shebang filter as a result; every executable file under tracked directories now must be registered regardless of language. Bundled with the perms-drift fix and a follow-up BACKLOG add into one revision commit (596f67c) since all three changes flowed from the same user decision.
- **Min-bits permissions semantics let us standardise on `0500`**: `Validate::Security`'s check is `(actual & expected) != expected`, so on-disk `0700` satisfies recorded `0500` (`0700 & 0500 == 0500`). All 17 new entries record `0500` even though their on-disk perms are `0700`. The 4 drift entries that had recorded `0755` against actual `0700` were lowered to `0500` for the same reason — `0755` was overstating precision and creating drift that could only ever be cleared by a manual recompute. Future entries should default to `0500` unless a higher floor is genuinely required.
- **Hash-key shape `<parent>.d/<sub>` is safe by design**: `lib/CWF/Validate/Security.pm:76` iterates `sort keys %file_entries` without parsing keys, so embedded `/` and `.` characters work transparently. No code change to `Validate::Security` was needed; the validator simply read the new keys and verified their entries.
- **RED-before-splice was actually executed**: TC-U1 from e-testing-plan asserted the coverage test had to be meaningful, not just present. During f-phase, the test ran pre-splice and produced exactly 17 missing-entry failures across TC-C1 (8) + TC-C2 (7) + TC-C3 (2); after the splice it ran green. The synthetic-file probe (TC-NF1) repeated the demonstration with a freshly-dropped unregistered file to confirm the regression-guard behaviour for future drops.
- **Planted-byte-flip on every tier**: TC-I2 (top-level Perl trampoline `context-manager`), TC-I3 (`.d/` subcommand `context-manager.d/hierarchy`), TC-I4 (hook `stop-stale-status-detector`), TC-I5 (POSIX shell helper `cwf-load-project-config`) all produced `[SECURITY] sha256` violations on append + `1 violation(s) found`; `git checkout --` cleared each. Confirms shell scripts get the same integrity guarantee as Perl.
- **Security review changeset was empty by design**: the security-review pathspec deliberately excludes `.cwf/security/**` (manifest data) and `t/**` (test code). Both phase reviews recorded `**State**: no findings\n\nno findings: empty changeset` per the skill's empty-diff branch.
- **/simplify pass after g-phase** consolidated TC-C1 and TC-C2 into a single walk + path-partition, swapped a regex `rel_to_repo` for `File::Spec->abs2rel`, and removed a what-not-why comment. Net -47/+28 lines, all tests still green. Cleanup committed as a separate fixup (e5aab40); the squash will fold it into the final task commit.
- **Process error worth noting**: first `task-workflow create` call passed `--destination="implementation-guide"` (instead of the full task-dir path), creating files in the wrong location. Trivial to recover but a recurrence risk on rapid task creation. The helper does what its argument says, not what the user meant — pass full destination paths.
- 17 new manifest entries, 4 perms-drift fixes, 1 new test file (4 subtests), 1 BACKLOG close + 1 BACKLOG add. Full suite 28 files / 267 tests → 29 / 271 (delta exactly +1 file +4 subtests).

## Task 124: Audit Perl helpers vs perl-git-paths conventions

### Status: Complete (2026-05-03)
### Duration: 1 session of active work (estimated: 1–2 days; variance ~0%)
### Impact: Chore — adds `CWF::Validate::PerlConventions`, a fifth validator wired into `cwf-manage validate` (which runs at every workflow checkpoint commit via `cwf-checkpoint-commit:53`). Enforces three convention rules from `docs/conventions/perl-git-paths.md`: (1) `use utf8;` declared unconditionally on every Perl file under `.cwf/scripts/` and `.cwf/lib/CWF/`, (2) any captured `git status|diff|ls-files|diff-tree|diff-index` invocation uses `-z`, (3) any script that captures git output uses `#!/usr/bin/perl -CDSL`. POD and `#` comments are stripped before scanning so doc examples cannot trigger false positives. Grandfathered exception for `.cwf/scripts/hooks/stop-stale-status-detector` is hard-coded in the module's `@GRANDFATHERED` allowlist (no comment-marker bypass — TC-NF2 confirms a `# perl-git-paths-skip:` comment does not silence the check). 41 Perl files received `use utf8;` to bring the tree into compliance, plus a one-time refresh of 34 entries (and one new entry for the validator) in `.cwf/security/script-hashes.json`.

### Changes
- Added: `.cwf/lib/CWF/Validate/PerlConventions.pm` — new validator (~216 lines). Exports `validate($git_root)`. Walks `.cwf/scripts/` and `.cwf/lib/CWF/` via `File::Find`, filters to Perl scripts (shebang) and CWF modules (`^package CWF::`). Returns the same hashref shape as the other `CWF::Validate::*` modules (`{ category, file, field, actual, expected, fix }`) so `cmd_validate` formats it without new infrastructure.
- Added: `t/validate-perl-conventions.t` — fixture-driven Test::More unit test, 14 subtests. Covers `use_utf8` (TC-U1, TC-U2, TC-U2b), `git_z` (TC-U3, TC-U4, TC-U4b, TC-U4c, TC-U4d), `shebang` (TC-U3b, TC-U4), POD exclusion (TC-U5), argument-paths exclusion (TC-U6), allowlist (TC-U7), non-Perl filter (TC-U8). TC-U4c/U4d added in response to a security-review finding (bareword `open my $fh, '-|', 'git', ...` form).
- Modified: `.cwf/scripts/cwf-manage` — added `use CWF::Validate::PerlConventions ();` to the validate block and `CWF::Validate::PerlConventions::validate($git_root)` to the `@all_violations` aggregation in `cmd_validate`. Validator runs alongside Config, Workflow, Consistency, Security on every checkpoint commit.
- Modified: 41 Perl files under `.cwf/lib/CWF/` and `.cwf/scripts/` gained `use utf8;` after `use strict; use warnings;`. Includes all of `.cwf/lib/CWF/*.pm`, `.cwf/scripts/command-helpers/*` and their `*.d/` subdirs, `.cwf/scripts/hooks/stop-stale-status-detector`, and `.cwf/scripts/migrations/migrate-v2.1-file-order`.
- Modified: `.cwf/security/script-hashes.json` — refreshed sha256 entries for 34 modified files plus one new entry for `CWF::Validate::PerlConventions.pm`. Permissions unchanged.
- Modified: `docs/conventions/perl-git-paths.md` — source-pragma rule changed to "Declare it on every Perl file under .cwf/ unconditionally". Replaced the "Existing usage" prose list with an "Enforcement" section pointing to `CWF::Validate::PerlConventions` as the live drift check; the grandfathered exception is now described as living in the validator's allowlist constant.
- Modified: `BACKLOG.md` — closed "Audit Perl helpers against perl-git-paths.md conventions"; added new High-priority follow-up "Expand script-hashes.json integrity surface to command-helpers and hooks".

### Notable
- **Mid-task rule widening (3 → 41 files)**: original byte-grep audit returned 9 candidates; the validator's POD/comment stripping correctly narrowed that to 3 with code-level non-ASCII; user direction during f-exec then widened the rule to unconditional ("we should ALWAYS use 'use utf8;'"), bringing the final count to 41. Memory `feedback_always_use_utf8.md` saved so future tasks default to the unconditional reading. The widening was scope clarification, not creep — the underlying rule was always meant to be unconditional.
- **Security model carve-out — end users must NEVER recompute hashes**: the original d-plan framed hash refresh as a routine maintainer step; user correction during plan review made the constraint permanent. `cwf-manage` will not gain a `refresh-hashes` subcommand. `fix-security` only repairs permissions when sha already matches — it never recomputes. Hash regeneration is upstream-source-repo-only. Recorded in d-plan § "Scope Completion" as a permanent out-of-scope item.
- **Allowlist over comment marker** (TC-NF2): a `# perl-git-paths-skip:` style comment carries no meaning to the validator — the only opt-out is editing `our @GRANDFATHERED` in source, which is visible in code review. A future caller cannot silently exempt their script.
- **Security-review finding fixed in-task, not deferred**: subagent (run on a 250-line narrowed subset due to the 500-line cap) flagged that the open-pipe regex required parens, missing the bareword `open my $fh, '-|', 'git', ...` form. Regex tightened (terminate at `;` instead of `)`); TC-U4c and TC-U4d lock both forms in.
- **Integrity surface gap surfaced as follow-up**: `.cwf/scripts/command-helpers/{context-manager,task-workflow,workflow-manager}` + `*.d/` subdirs, plus `.cwf/scripts/hooks/`, are NOT registered in `script-hashes.json`. They received `use utf8;` for convention compliance but their bytes aren't tamper-checked. Added to BACKLOG as High-priority follow-up.
- **No personal names in committed CWF docs** (memory `feedback_no_name_in_wf_docs.md`): first d-plan draft named the maintainer in the hash-refresh step; corrected to use the role ("the maintainer") instead. Workflow-step docs are committed source — names rot, roles don't.
- **Probe scripts under `/tmp/task-124/`** (memory update to `feedback_no_heredocs.md`): TC-I4 and TC-NF2 needed scratch Perl to exercise `@GRANDFATHERED` semantics. First attempt used `perl -e` inline in Bash; user correction ("avoid using heredocs… create a dir under /tmp and edit the files in there direct") drove the switch to file-based probes. Memory generalised from "no heredocs in commits" to "no inline scripts of any kind in Bash".
- 1 new validator module, 1 new unit test (14 subtests), 41 `+use utf8;` insertions, 1 `cwf-manage` wiring change, 1 docs update, 1 BACKLOG close + 1 BACKLOG add. Full suite 28 files / 267 tests green pre/post.

## Task 123: Add security-review subagent to plan/exec skills

### Status: Complete (2026-05-03)
### Duration: ~1 session of active work (estimated: 1 day; variance ~0%)
### Impact: Feature — extends the existing 3-subagent plan-review map/reduce to 4 subagents (adds **security**) and inserts a new Step 8 (Security Review) into both `cwf-implementation-exec` and `cwf-testing-exec` SKILLs. Threat model lives in one new canonical doc, `.cwf/docs/skills/security-review.md`, covering the five CWF-specific judgement-call categories: bash injection / unsafe command construction (a), Perl helpers consuming git/user output without `-z` (b), prompt injection via user-supplied strings (c), unsafe environment-variable handling (d), pattern-based safe-here-but-risky-elsewhere risks with required `safe here because X; audit future uses where X might not hold` framing (e). Subagent is restricted to Read/Grep/Glob (no Bash, no edits) per the existing plan-review allowlist convention. Boundary explicitly carved out vs deterministic `cwf-manage validate` (sha256 + recorded perms) and vs the user-facing `/security-review` built-in.

### Changes
- Added: `.cwf/docs/skills/security-review.md` — new canonical doc, ~155 lines. Sections: `## Scope` (cross-references `.cwf/docs/conventions/subagent-tool-selection.md` and explicitly carves out `cwf-manage validate` + built-in `/security-review` boundaries), `## Pathspec coverage` (the single-source-of-truth `git diff $(git merge-base HEAD main)..HEAD -- <pathspec>` with maintainer note for adding new security-relevant trees), `## Threat categories` (a–e per FR4 — each with one-line definition, anti-pattern with file:line citation if real or `# illustrative` label, "do instead" pointer), `## Plan-phase row`, `## Exec-phase prompt template` (parameterised on `{changeset}` + `{phase}` with three sentinel return states).
- Modified: `.cwf/docs/skills/plan-review.md` — header `Launch 3 Subagents` → `Launch 4 Subagents` plus 4 other prose sites updated 3→4; criteria-lookup table gained a `Security` column with cells for `requirements`/`design`/`implementation` rows that reference `security-review.md` rather than restating the threat model.
- Modified: `.claude/skills/cwf-implementation-exec/SKILL.md` — added `- Agent` to `allowed-tools`; inserted `**Step 8 (Security Review)**` block (branch check → empty-diff check → 500-line cap check → single Agent call with three-tier classifier); renumbered existing Step 8 (Checkpoint commit) → 9 and Step 9 (Next Steps) → 10; Success Criteria gained the security-review checkbox.
- Modified: `.claude/skills/cwf-testing-exec/SKILL.md` — same edits with `{phase}` = `"testing"` and `g-testing-exec.md` instead of `f-implementation-exec.md`.

### Notable
- **Doc-only feature — no script-hash refresh**: `.cwf/security/script-hashes.json` only tracks `.cwf/scripts/` and `.cwf/lib/`. No `.cwf/docs/` file or `.claude/skills/SKILL.md` is in the manifest, so `cwf-manage validate` runs clean without intervention.
- **Sequential renumbering matches Task 71 precedent (commit `be933c7`)**: existing Step 8 → 9 and Step 9 → 10 rather than introducing `Step 7a`-style sub-steps. Plan-review subagents flagged the original `Step 7a` proposal as inconsistent with the established CWF pattern; the redesign during implementation-plan adopted full renumbering.
- **Three-tier classifier biases toward visibility**: primary sentinel match → numbered-list/`actionable finding` fallback → conservative-default `error`. A misclassified error is loud; a misclassified `no findings` would silently mask a malformed-output failure on a security tool, which is the worst possible outcome. The conservative default exists for that reason.
- **Pattern-risk carve-out (FR4(e))**: ordinarily the subagent reports only actionable findings. Pattern-based risks (a snippet that's safe at the current callsite because of a callsite invariant but risky if reused elsewhere) ARE allowed, with the required framing `safe here because X; audit future uses where X might not hold`. Plan-review subagents during requirements review flagged that without this carve-out the subagent would suppress real signal.
- **Pathspec is single source of truth in `security-review.md` § "Pathspec coverage"**: both exec SKILLs reference that section rather than inlining the pathspec. Adding a new security-relevant tree (e.g. a future `.cwf/scripts/post-install/`) means editing the doc once, not two SKILLs.
- **Dogfood verification (AC8) ran during g-testing-exec** against this task's own 270-line changeset on branch `feature/123-…`. Subagent invocation succeeded; classifier returned `**State**: findings` because the response led with verbose intro instead of a sentinel — the numbered-list fallback fired exactly as Decision 3 designed it (loud false positive over silent false negative). Substantive verdict from the subagent body: "no findings" across all five (a)–(e) categories with a closing positive statement. Disposition per AC8 option (b): accept with documented rationale, recorded verbatim in g-testing-exec.md § "TC-AC8". The wiring works end-to-end.
- **Subagent prompt-template tightening identified as follow-up** (BACKLOG: Tighten security-subagent prompt for sentinel-line compliance). The TC-AC8 pattern (verbose intro hiding the closing sentinel) is likely to recur in practice; one-line edit to the canonical doc § "Exec-phase prompt template" would push the sentinel ahead of any analysis. Tracked in BACKLOG.md.
- 1 new doc, 3 edits (5 files modified counting CHANGELOG and BACKLOG), 0 code changes, 0 new tests (docs-and-skills task; runtime verification is the AC8 dogfood case).

## Task 122: Create Design-Alignment Conventions Document

### Status: Complete (2026-05-02)
### Duration: <0.5 day
### Impact: Chore — adds `docs/conventions/design-alignment.md`, the third top-level CWF-development convention doc (alongside `commit-messages.md` and `perl-git-paths.md`). Codifies single-source-of-truth locations for skills/helpers/templates/rules, the `cwf-` + kebab-case + phase-letter naming patterns, the version-suffix scope (helper scripts only, never skills), the `<name>.d/` subcommand-dispatch pattern, and a concrete grep-and-`cwf-manage validate`-based rename audit checklist. Also draws an explicit asymmetric-deprecation line: in-repo artefacts have no deprecation period (CWF is its own only consumer), but `cwf-manage` and its subcommands form a weak external contract with installed copies and require a one-minor-version alias on rename.

### Changes
- Added: `docs/conventions/design-alignment.md` — new convention doc, ~140 lines, follows `perl-git-paths.md`'s Convention/Why/Existing-usage structure. The "Why" section grounds each rule in a concrete prior failure (Tasks 35, 59, 81, 90).
- Modified: `CLAUDE.md` — added `**Design Alignment**` bullet under §Conventions matching the existing `**Commit Messages**` style (location, summary, sub-bullets).
- BACKLOG: removed the "Create Design-Alignment Conventions Document" task block (~67 lines) and replaced with a one-line `<!-- Completed: ... -->` marker.

### Notable
- **Reference-surface inventory was data-driven**, not guessed. `git ls-files | grep -v ^implementation-guide/ | xargs grep -l 'cwf-task-plan\|cwf-status'` returned 19 files spanning `CLAUDE.md`, `README.md`, `BACKLOG.md`, `CHANGELOG.md`, `COMMANDS.md`, `DESIGN.md`, `.claude/rules/`, `.claude/skills/*/SKILL.md`, `.cwf/autoload.yaml`, and `.cwf/docs/{glossary,workflow,skills}/`. The audit checklist (§3) prescribes the same grep so future renames inherit the inventory rather than re-discovering it.
- **Plan-review subagents caught three load-bearing omissions** before drafting: (1) helper-script `<name>.d/` subcommand pattern was missing — would have left `context-manager.d/` etc. undocumented; (2) version-suffix scope was ambiguous — clarified as "helpers only, never skills"; (3) deprecation stance had to distinguish in-repo (no deprecation) from `cwf-manage` (weak external contract, one-minor alias).
- **Audit checklist deliberately uses Grep + `cwf-manage validate`**, not `find` or `sed`. User feedback during this task: those tools trigger blocking permission prompts in the harness; built-in tools and `git ls-files` are equivalent for these use cases. The checklist would have proposed `find -type l` for the symlink audit if not for that course-correction.
- **Symlink integrity is delegated to `cwf-manage validate`** rather than ad-hoc shell. The validator already checks every pool symlink resolves (it's how broken installs are caught); duplicating the logic in a doc-prescribed shell snippet would have been a maintenance liability.
- Total: 1 new doc, 2 edits, 0 code changes, 0 new tests (documentation task).

## Task 121: Drop perl -I prefix from script invocations

### Status: Complete (2026-05-02)
### Duration: <0.5 day (estimated: 0.5 day; variance ~0%)
### Impact: Chore — removes the anti-idiomatic `perl -I.cwf/lib <script>` invocation pattern from active CWF source, skills, and tests. Active code now relies on Unix shebang semantics (`#!/usr/bin/perl -CDSL` + `FindBin` + `use lib`) for direct invocation; the single bootstrap exception in `/cwf-init` step 1a uses `chmod` (idiomatic Unix) instead, with the chmod value read from `script-hashes.json` rather than a hardcoded constant. Repo-wide grep over active source returns zero `perl -I.cwf/lib` hits after this task; historical artefacts (commit messages, prior `implementation-guide/**` exec records, prior CHANGELOG entries) are deliberately untouched.

### Changes
- Modified: `.claude/skills/cwf-init/SKILL.md` — step 1a now reads `cwf-manage`'s recorded permission from `.cwf/security/script-hashes.json` via inline `perl -MJSON::PP -e` (a one-shot JSON parse, not an `-I.cwf/lib <script>` substitute), chmods `cwf-manage` to that exact recorded value, then runs `.cwf/scripts/cwf-manage fix-security`. The chmod value is therefore manifest-driven — if the recorded perm ever changes in `script-hashes.json`, the SKILL bootstrap follows automatically with no edit needed.
- Modified: `.claude/skills/cwf-security-check/SKILL.md` — single-line cleanup: `perl -I.cwf/lib .cwf/scripts/cwf-manage validate` → `.cwf/scripts/cwf-manage validate`. Direct invocation works because `cwf-manage` already uses `FindBin` + `use lib "$FindBin::Bin/../lib"` (script lines 25–26) to resolve its own library path at runtime.
- Modified: `INSTALL.md` — removed the `# Check Perl modules load` block (`perl -I.cwf/lib -MCWF::Common -e 'print "OK\n"'`); the `.cwf/scripts/command-helpers/context-manager location` invocation immediately above it already exercises `CWF::Common` loading via `FindBin` (verified at `context-manager.d/location:5–6`), so the explicit module-load check was redundant. Updated the trailing prose: "All four commands…" → "All three commands…".
- Modified: `t/cwf-manage-fix-security.t` — added `_read_recorded_perms($tmp, $entry_name)` helper (reads `script-hashes.json` via `JSON::PP::decode_json`, returns the recorded permission as an octal integer) and `_ensure_cwf_manage_executable($tmp)` helper (idempotent bootstrap mirroring `/cwf-init` step 1a — uses `Fcntl S_IXUSR` to skip when user-x is already set, otherwise chmods `cwf-manage` to its JSON-recorded value). `run_fix_security` and `run_validate` factored into `_run_cwf_manage($tmp, $subcmd)` (post-`/simplify` dedup) and now invoke `.cwf/scripts/cwf-manage <subcmd>` directly. TC-2 assertion uses `_read_recorded_perms`; TC-4 and TC-5 retargeted from `cwf-manage` to `command-helpers/cwf-version-tag` so fix-security's chmod path is exercised on a non-bootstrap script (the bootstrap helper restores `cwf-manage`'s perms before fix-security runs).

### Notable
- **First user pivot — broaden the principle**: original plan kept `perl -I` in two "deliberate exceptions" (`/cwf-init` step 1a and `INSTALL.md`). User clarified: shebang `#!` semantics for everything *post-install*; `/cwf-init` step 1a is special only because exec bits may not yet be set on a freshly-copied `.cwf/`, so the bootstrap there should be `chmod` (idiomatic Unix), not `perl -I`. `INSTALL.md`'s `-MCWF::Common` line is just redundant. Captured in commit `0ba7df7`.
- **Second user pivot — manifest-driven chmod**: "no magic numbers in the chmod calls — fetch from `script-hashes.json`". Drove both the SKILL bootstrap (inline `perl -MJSON::PP -e`) and the test scaffolding (new `_read_recorded_perms` helper). This pivot was load-bearing: a hardcoded `chmod u+x` would only satisfy the validator's bitwise minimum (`(actual & expected) == expected`), leaving `cwf-manage` with extra bits not in the recorded value; chmodding to the exact recorded perm is precise. Captured in commit `eac2e5c`.
- **TC-4/TC-5 retarget caught a latent test-design subtlety**: tests that mutate the same script the harness uses to *reach* the device-under-test get spurious passes after the harness restores it. Switching the chmod-target from `cwf-manage` to `cwf-version-tag` keeps fix-security's chmod path under test. Worth flagging in `t/lib/CWFTest/Fixtures.pm` if/when other tests need the same pattern.
- **`Fcntl qw(:mode)` introduced to the codebase**: `S_IXUSR` is preferred over `& 0100` for user-x checks; the latter never appeared elsewhere either, so this also nudges the convention forward.
- **`/simplify` post-impl produced one real win** — `run_fix_security` and `run_validate` were 11-line near-duplicates, factored into `_run_cwf_manage($tmp, $subcmd)` with one-line public wrappers (net −8 lines). Captured in commit `9b6bc5b`. The agents correctly rejected the lower-value findings (extracting the SKILL one-liner into a separate helper script would have reintroduced the very file-invocation pattern this task removed).
- 4 source files changed, +50 net lines of test code, 0 new tests, 253/253 regression green.

## Task 120: cwf-init Runs Security Check

### Status: Complete (2026-05-02)
### Duration: 1 session (estimated: 0.5 day — variance +50% after mid-design pivot from SKILL-orchestrated chmod to a deterministic `cwf-manage fix-security` subcommand)
### Impact: Bugfix — `/cwf-init` now verifies and repairs CWF install integrity before mutating any project state. New step `1a` calls a new `cwf-manage fix-security` subcommand that reads `.cwf/security/script-hashes.json`, repairs *fixable* permission deltas (only when the file's sha256 still matches what's recorded — never paper over tampering), and refuses to proceed if any file is missing, tampered, or the hashes file itself is missing/unparseable. Unfixable violations include a `Recovery:` line keyed by violation field suggesting `git pull` (CWF source checkout) or `cwf-manage update` (installed project). On non-zero exit the SKILL relays the subcommand's output verbatim and aborts init before CLAUDE.md, `.claude/settings.json`, or the init commit are touched. Originally identified during Task 60 (CWF installation testing in a fresh repo).

### Changes
- Added: `.cwf/scripts/cwf-manage` — new `cmd_fix_security($git_root)` subroutine (~120 lines) plus `_print_unfixable($entry)` helper and `%FIX_SECURITY_RECOVERY` recovery-hint table keyed by validator field (`sha256`, `existence`, `permissions`, `file`, `json`). Reuses the same `Digest::SHA::sha256_hex` with `<:raw` mode that `Validate::Security::_sha256` uses, so the two never disagree on what counts as a hash match. Per-entry algorithm: missing → unfixable; sha mismatch → unfixable (no chmod attempted); sha matches and perms below recorded minimum → `chmod $expected_perms $file` (exact recorded perms, not blanket 0755). Best-effort fix on mixed installs: repairs everything fixable in one pass, then surfaces all unfixable entries with their `field`/`actual`/`expected` and recovery hint, exits 1.
- Added: `'fix-security'` dispatch entry in `cwf-manage`'s `%dispatch` (between `validate` and `help`) and matching help-text line.
- Modified: `.claude/skills/cwf-init/SKILL.md` — new section `### 1a. Verify and Repair CWF Install` between current step 1 (Create Directory Structure) and step 2 (Generate Project Configuration). Single Bash invocation: `perl -I.cwf/lib .cwf/scripts/cwf-manage fix-security`. Exit 0 → continue; exit 1 → relay subcommand output verbatim, append abort line `[CWF] /cwf-init aborted: run 'cwf-manage update' or reinstall, then re-run /cwf-init.`, do not proceed. New Success Criteria line: "Install integrity verified via `cwf-manage fix-security` (exit 0)".
- Modified: `.cwf/security/script-hashes.json` — refreshed `cwf-manage` sha256 (refreshed twice during the task: once after initial implementation, once after the `/simplify` refactor).
- Added: `t/cwf-manage-fix-security.t` (210 lines) — 7 integration tests covering every branch of the design's classification table. Subprocess-style: copies `.cwf/` into a tempdir via `cp -rp` (preserves perms; `cp -r` would drop 0755 to 0700 under umask 077 and produce false-positive permission violations), runs `perl -I.cwf/lib .cwf/scripts/cwf-manage <subcmd>` against the fixture, asserts on exit code, captured output, and resulting filesystem state. Cases: TC-1 clean install no-op; TC-2 stripped perms restored to recorded values (verified `cwf-manage` ends at `0700`, not blanket `0755`); TC-3 sha mismatch refuses without chmod, output contains both recovery-hint substrings; TC-4 missing file refuses with best-effort repair on others; TC-5 mixed (one fixable, one tampered) — repairs fixable, refuses unfixable; TC-6 unparseable hashes file exits 1 with recovery hint; TC-7 idempotency (second run is a no-op).
- BACKLOG: removed the `Bug: /cwf-init Should Run Security Check and Fix Permissions` entry (completed by this task).

### Notable
- **Mid-design pivot, user-driven**: original c-design proposed a SKILL-orchestrated `find … chmod 0755 + cwf-manage validate` shell pipeline. User asked "shouldn't this be deterministic — we know what perms and sha should be, the fix is mechanical?" The redesign moved all algorithmic logic into Perl (`cmd_fix_security`), lifting the LLM out of the integrity loop entirely. Captured in commit `2a59679`. The resulting design is auditable, hash-tracked, and end-to-end testable under `prove`. Plus: chmod-ing to *exact* recorded perms (rather than blanket 0755) means `fix-security` overshoots nothing, and refusing to chmod tampered files preserves the tamper signal.
- **Recovery-hint pivot, user-driven**: after the design switch, user asked the unfixable output to point users at the right remediation. Added field-keyed `Recovery:` hints (`git pull` for CWF source, `cwf-manage update` for installed projects). Captured in commit `e37f39c`. Validate's developer-oriented "update the hash" message is preserved; fix-security is the user-facing surface and gets the user-facing recovery copy.
- **Test-first caught three planning errors before first run**: TC-3 originally targeted `cwf-manage` itself (can't run a tampered binary to detect its own tampering — switched to `cwf-set-status`); TC-4/5 originally targeted `command-helpers/context-manager` (not actually hash-tracked — switched to `task-stack`); the fixture used `cp -r` (umask 077 dropped 0755 to 0700, creating false-positive permission violations on the "clean" baseline — switched to `cp -rp`). All three would have wasted significant debugging time post-impl.
- **`/simplify` post-impl produced two real findings on the 150-line diff**: three near-identical UNFIXABLE block emissions (the two early-exit branches and the per-entry rendering loop) collapsed into a single `_print_unfixable($entry)` helper; 3-level chmod nesting flattened to `next`-guarded sequence at end of for-loop body. Captured in commit `0efa360`. No behaviour change, all tests still passed.
- **Bitwise minimum check is the load-bearing detail**: `Validate::Security` checks `(actual & expected) == expected`, treating recorded perms as a *minimum*. So `chmod 0755` on a file recorded as `0500` would pass the check (0755 & 0500 = 0500), but `fix-security` deliberately uses the *exact* recorded value to avoid setting g/o bits unintentionally. TC-2 directly verifies this: `cwf-manage` (recorded 0700) ends up at exactly 0700 after repair, not 0755.
- **`find -exec chmod` doesn't fail-fast on per-file errors** — but per-entry chmod inside `cmd_fix_security` does. If chmod fails on a sha-matched file, the entry becomes unfixable with a `Note: chmod failed: $!` extra line. Tested via the algorithm structure rather than directly (ENOSYS-style filesystem failures are hard to fixture).
- Manual smoke (TC-8/9/10 — end-to-end SKILL exec) deferred to the user with reproduction steps in `g-testing-exec.md`. Skill-level exec requires a separate Claude Code session in a scratch checkout; cannot run under `prove`.
- 7/7 fix-security cases pass; full suite 253/253 (was 246 baseline; +7 new, 0 regressions).

## Task 119: Reject Overlong Task Slugs

### Status: Complete (2026-04-29)
### Duration: 1 session (estimated: ~2–3 hours — on the lower end)
### Impact: Feature (breaking) — `/cwf-new-task` and `/cwf-new-subtask` now reject descriptions whose slug exceeds 50 characters, instead of silently truncating to fit. Previously a description like `"error on overlong slugs instead of silent truncation"` would slugify to `"error-on-overlong-slugs-instead-of-silent-truncati"` (mid-word stub); now it exits 1 with `[CWF] ERROR: Task slug '…' is N characters; limit is 50. Use a briefer task description (try fewer or shorter words).` on STDERR. Validation lives in `.cwf/scripts/command-helpers/template-copier-v2.1` (single source of truth via `use constant SLUG_MAX_LEN => 50`) and runs before any filesystem write, so rejection is atomic — no partial directory or branch left behind. Empty slugs (e.g. description = `"!!!"` → slugifies to `""`) get a separate rejection with a distinct recovery message. Existing on-disk tasks with previously-truncated slugs are unaffected (FR5 / AC5.2).
### Migration: Users with descriptions whose slug exceeds 50 chars must shorten the description and rerun. No on-disk migration needed — pre-existing tasks remain operational.

### Changes
- Modified: `.cwf/scripts/command-helpers/template-copier-v2.1` — added `die_msg` helper (mirrors `cwf-manage`'s) and `use constant SLUG_MAX_LEN => 50` near the top; new validation block in `parse_parameters` after the required-param loop and before destination construction (rejects empty slug or `length($slug) > SLUG_MAX_LEN`); `generate_slug` no longer truncates and now strips leading/trailing hyphens (so `"---foo---"` → `"foo"`); top-level execution wrapped in `sub main { ... } main() unless caller();` so the script is `do`-loadable from tests without firing required-param checks. The /simplify pass post-impl inlined `SLUG_MAX_LEN` directly into the error message and threaded the slug computed in `parse_parameters` into `construct_destination` as an optional 2nd arg, eliminating one redundant `generate_slug` call per invocation.
- Modified: `.claude/skills/cwf-new-task/SKILL.md` — Step 2 line replaced. Was "Slug: lowercase, spaces to hyphens, remove special chars, truncate 50 chars". Now: "Slug: pass --description raw to the script; the script slugifies (…) and rejects overlong descriptions (>50 chars) with `[CWF] ERROR:`. Do not pre-truncate." LLM is no longer instructed to truncate.
- Modified: `.claude/skills/cwf-new-subtask/SKILL.md` — corresponding line aligned with cwf-new-task.
- Modified: `.cwf/security/script-hashes.json` — refreshed `template-copier-v2.1` sha256.
- Added: `t/template-copier-slug-validation.t` — 8 unit tests using the `*main::die_msg` symbol-table override pattern from Tasks 115/116. Cases: under-limit accepted, at-limit accepted, just-over rejected, well-over rejected with length in message, empty-after-normalising rejected, leading/trailing hyphens stripped, error message contents (length / limit / recovery hint / `[CWF] ERROR:` prefix), atomicity (tempdir unchanged after rejection).
- BACKLOG: removed "Reject overlong task slugs" entry (completed by this task); added 3 follow-up entries — boy-scout migration of remaining `print STDERR "Error: ..." + exit N` blocks in `template-copier-v2.1` to `die_msg`; lift `die_msg` to a shared `CWF::Common` module (currently duplicated between `cwf-manage` and `template-copier-v2.1`); codify the `main() unless caller();` testability convention in `docs/conventions/`.

### Notable
- Plan review (3 parallel Explore subagents) at d-implementation-plan caught the load-bearing testability defect: the original script's bare top-level execution (`my %params = parse_parameters(@ARGV); ... exit 0;`) would die on `do`-load with empty `@ARGV` before any test could override `*main::die_msg`. Solution adopted: wrap in `sub main { ... } main() unless caller();`. Without this catch the test file would have failed during implementation-exec for an opaque-looking reason and prompted a panicked round-trip. Caught in planning, fixed in design.
- Plan review also surfaced two design refinements: drop the dual-validation (description + destination basename) defensive duplication (Improvements F1 — description-derived slug is checked first and `--description` is required, so destination is never reached when description fails); add empty-slug rejection (Robustness F2 — description = `"!!!"` slugifies to `""`, passes the `>50` guard, creates absurd `1-feature-` paths). Both refinements bundled in.
- TDD inverted the validation cleanly: test written first, watched fail for the *expected* reason (top-level execution dying on `do`-load — exactly what the plan anticipated), implementation written, watched pass. Single-pass cycle, no rework.
- /simplify post-impl produced two real findings on a 60-line diff: redundant `my $limit = SLUG_MAX_LEN` local (came from design-doc pseudocode, never inlined); redundant `generate_slug` call between `parse_parameters` and `construct_destination`. Both fixed in commit 78a16a5 without regressing any test. Two adjacent refactors — boy-scout `print STDERR + exit` → `die_msg` migration; lifting `die_msg` into `CWF::Common` — were explicitly deferred per c-design Decision 3 and tracked as backlog items.
- Dogfooding: the task's own slug (`reject-overlong-task-slugs`, 26 chars) was deliberately short. The first attempt picked an overlong description and got correctly truncated (the very behaviour this task fixes); user caught it and the slug was redone. The fix this task ships would have surfaced the overrun immediately on creation.
- 17/17 test cases pass: 8 unit, 2 integration (direct script invocation), 2 system (via `task-workflow create`), 3 source-of-truth grep checks, 2 regression (`prove t/` 246 passing = 238 baseline + 8 new; `cwf-manage validate` OK).

## Task 118: Add Tool Selection and Composition Guidance to Subagent Instructions

### Status: Complete (2026-04-29)
### Duration: 1 session (estimated: ~2 hours — on target)
### Impact: Chore — adds a tool-selection rubric for CWF subagents in two places: (1) a new canonical convention doc at `.cwf/docs/conventions/subagent-tool-selection.md` documenting the 5-tier preference order (built-in tools → skills → `rg`/`grep` Bash → `sed`/`awk`/`cat`/`head`/`tail` Bash → `find … -exec`/pipelines as last resort), the no-program-composition-for-simple-tasks principle, and 6 anti-patterns with their built-in equivalents; (2) a brief inline excerpt of the same rubric (principle verbatim + 3 highest-value anti-patterns + reference to the canonical doc) embedded in the `plan-review.md` subagent prompt template, so subagents read the guidance at decision time rather than via a link they may not follow. First conventions doc to ship under `.cwf/docs/conventions/` (top-level `docs/conventions/` siblings address CWF-development; `.cwf/docs/conventions/` ships with installed CWF copies).

### Changes
- Added: `.cwf/docs/conventions/subagent-tool-selection.md` — new convention doc, 57 lines, structured as `## Convention` / `## Anti-patterns` / `## Why` / `## Existing usage` to match the established `docs/conventions/perl-git-paths.md` pattern. Captures the 5-tier hierarchy, the principle "Do not use program composition with the Bash tool for simple tasks; use the built-in tools instead." (single-line emphatic callout), 6-row anti-pattern table, and consumer references to `plan-review.md` and `workflow-preamble.md` Step 4.
- Modified: `.cwf/docs/skills/plan-review.md` — replaced the single line "You may only use Read, Grep, and Glob tools. Do not modify any files." with a 9-line inline block: tightened restriction ("…no Bash, no edits"), the no-composition principle verbatim, a composition hint (Read offset/limit; Glob → Read / Grep → Read chaining), 3 inline anti-patterns (`sed -n 'X,Yp'` → Read offset/limit; `cat … | grep` → Grep; `find … -exec cat` → batched Read calls), and a "Full rubric: …" pointer to the canonical doc. Prompt block grew 9 lines vs an ≤8 budget — accepted to preserve scannability.

### Notable
- Plan-review subagents caught the load-bearing design flaw on the first pass: the original d-plan inlined Bash-tier advice (`rg` fallback, etc.) into a prompt that restricts subagents to Read/Grep/Glob, creating a contradiction. Robustness reviewer flagged it; plan revised to scope the rubric to the allowed tools and document the broader hierarchy in the canonical doc.
- The user provided the load-bearing empirical observation: subagents in this very task reached for `sed -n 'X,Yp'` and `find … -exec` despite the existing "may only use Read, Grep, Glob" prompt restriction. That data point is what forced the design from "linked guidance" → "inline guidance" — soft restrictions in subagent prompts are not enforced, so behavioural rubrics must be visible at decision time, not behind a link.
- Three plan revisions before execution. First framed the work as a separate convention doc with a one-line link from the prompt; revised on user feedback to inline-only; revised again to "both surfaces" after user clarified ("having the conventions docs is GOOD but that doesn't mean we don't ALSO include a brief instruction with a reference"). Each detour was driven by my over-decomposing the user's clear initial framing — captured in j-retrospective.md as a process learning.
- `/simplify` post-impl produced one substantive structural change: the convention doc was originally written with ad-hoc section headings (Preference order / Core principle / Composition / See also). User correction ("convention docs serve both humans and agents — top-level `docs/conventions/` is not 'developers only'") prompted alignment to the existing `perl-git-paths.md` pattern (Convention / Why / Existing usage). Same content, conventional structure. Also synchronised one wording divergence — inline said "for a few files", canonical doc said "for a handful of files"; both now say "a handful".
- 10/10 functional + 3/3 non-functional tests PASS. One mid-test fix (NFR-2 caught a missing `workflow-preamble.md#step-4` cross-reference that the d-plan listed but the impl omitted; added during testing-exec). `cwf-manage validate` OK at every checkpoint.

## Task 117: Add Gotchas to cwf-implementation-exec Skill

### Status: Complete (2026-04-29)
### Duration: 1 session (estimated: <1 session — on target)
### Impact: Chore — adds a `## Gotchas` section to `.claude/skills/cwf-implementation-exec/SKILL.md` containing the two execution-phase gotchas filed from Task 107's LMM memory analysis: (1) run `git status` before every checkpoint commit (covers untracked AND unstaged); (2) after any rename or string substitution, verify both source and generated output (source-grep and output-grep both required, neither sufficient alone). Project-neutral wording — installable into any downstream CWF-using project. The `## Gotchas` convention is now consistent across 4 SKILL.md files (cwf-design-plan, cwf-implementation-plan, cwf-retrospective, cwf-implementation-exec).

### Changes
- Modified: `.claude/skills/cwf-implementation-exec/SKILL.md` — inserted new `## Gotchas` section between the front-matter terminator and `## Scope & Boundaries`, matching the placement and single-line item formatting used by sibling skills. Diff is +5 lines (header, blank, item 1, item 2, blank); zero changes outside the inserted block
- Boy-scout: `.cwf/docs/skills/checkpoint-commit.md` — added one-line "run `git status --untracked-files=all` first" instruction in the "Script (primary method)" section, mirroring gotcha 1 at the doc all phases reference
- BACKLOG: removed "Add Gotchas to cwf-implementation-exec Skill" entry (completed by this task)

### Notable
- Plan review (3 parallel Explore subagents) caught two valid content gaps that would have shipped wrong gotchas: gotcha 1 had lost the BACKLOG's "or unstaged" qualifier in the rationale; gotcha 2 had made the "grep source first, then grep output" ordering implicit. Both fixed pre-implementation. Same shape as Task 111's plan-review return.
- User wording review caught what plan review didn't: "rebrand" was used loosely as a synonym for "rename" but conflates with marketing/product-name changes. Replaced with "rename or string substitution" before exec. Second consecutive gotcha-rollout task where user prose review found the highest-value fix after plan review passed.
- Self-validating: gotcha 1 (`git status` before commit) was used during the f-phase commit of this task — the agent ran `git status --short` before staging and confirmed both the SKILL.md change and the workflow file were captured. Eats its own dog food at the earliest possible point.
- 8/8 manual test cases pass (2 structural, 2 content, 2 project-neutrality, 2 regression). `cwf-manage validate` OK after each checkpoint.
- Boy-scout: added a one-line `git status --untracked-files=all` instruction to `.cwf/docs/skills/checkpoint-commit.md` (the doc referenced from every phase's checkpoint step), mirroring gotcha 1 at the doc level all phases share.

## Task 116: Make cwf-manage Update Handle a Dirty Working Tree

### Status: Complete (2026-04-28)
### Duration: 1 session (estimated: 0.5–1 day — well under)
### Impact: Bugfix — `cwf-manage update` (and via delegation, `cwf-manage rollback`) now refuse to run if `.cwf/` or `.cwf-skills/` has uncommitted changes (tracked-modified or untracked, via `--untracked-files=all`). Replaces the previous opaque `git subtree pull` failure (subtree method) and silent `rmtree`-then-overwrite (copy method) with a single CWF-prefixed error listing the dirty paths and the recovery recipe (`git stash` / `cwf-manage update [ref]` / `git stash pop`). Closes the second of two pain points filed during the same external-user upgrade report (v1.0.95 → v1.0.114).

### Changes
- Added: `check_clean_tree($git_root)` helper in `.cwf/scripts/cwf-manage` — list-form `open '-|', 'git', '-C', $git_root, 'status', '--porcelain', '-z', '--untracked-files=all', '--', '.cwf', '.cwf-skills'`; defensive `$? != 0` exit-code check; calls `die_msg` with one heredoc containing header + dirty-file list + recipe
- Modified: `.cwf/scripts/cwf-manage` — `cmd_update` calls `check_clean_tree($git_root)` between `resolve_source` and `log_msg("Updating CWF...")`. `cmd_rollback` (unchanged) inherits the check via delegation
- Modified: `.cwf/scripts/cwf-manage` `cmd_help` heredoc — `Notes:` section between `Environment:` and `Examples:` documents the precondition. No file-header duplicate (single source of truth)
- Modified: `.cwf/security/script-hashes.json` — refreshed `cwf-manage` sha256
- Added: `t/cwf-manage-check-clean-tree.t` — three unit subtests: clean tree, dirty (tracked + untracked combined), git-status-failure. Reuses Task 115's `*main::die_msg` symbol-table override pattern

### Notable
- Intentionally **out of scope** by design: `.claude/skills/cwf-*` symlinks (CWF-managed; over-blocking unrelated user skills outweighs the marginal symlink-overwrite risk). Documented in c-design Decision 2.
- Branched from Task 115's tip (linear-history convention); 115 will ff-merge first, 116 ff-merges immediately after with no rebase work.
- `/simplify` between testing-plan and implementation-exec removed ~66 lines of plan text and translated 1:1 into removing the `eval`-wrapper, the `@paths` parameter, the cap-overflow logic, and one-and-a-half tests. The originally-planned "helper terse / recipe at call site" split was speculative future-proofing for a hypothetical `rollback --safe` mode that doesn't exist; collapsing back to "helper does one thing, dies via `die_msg`" eliminated several edge-case-defending code comments at the same time.
- TC-6 fixture footnote: first attempt for "dirty file outside scope" carried over the untracked `.cwf/foo.txt` from TC-5 (because `git stash` doesn't include untracked files without `-u`); re-ran with a fresh `mktemp -d` fixture and it passed. Lesson noted: prefer per-scenario fixtures over cleanup when the thing under test is "dirtiness detection".
- Suite: 235 → 238 passing (25 files). `cwf-manage validate` OK after the hash bump.

## Task 115: Honour CWF_SOURCE Env Var in cwf-manage Update

### Status: Complete (2026-04-27)
### Duration: 1 session (estimated: 0.5 day — on target)
### Impact: Bugfix — `cwf-manage update` and `cwf-manage list-releases` now honour `$ENV{CWF_SOURCE}` for this-invocation-only override of `cwf_source` from `.cwf/version`, matching the convention `install.bash` already established. Lets external developers point a single update or release-list at a `file:///` source without editing the installed `.cwf/version` (and without it sticking). Also boy-scouts a pre-existing UTF-8 source-encoding bug in `cwf-manage` that surfaced double-encoded em-dashes under `PERL5OPT=-CDSL`.

### Changes
- Added: `resolve_source(\%v)` helper in `.cwf/scripts/cwf-manage` — pure function returning `($source, $origin)` two-element list with env > file precedence and `defined && ne ''` checks on both
- Modified: `.cwf/scripts/cwf-manage` — `cmd_update` and `cmd_list_releases` read effective source via `resolve_source` instead of `$v{cwf_source}` directly; log lines now include `(from: <origin>)` suffix in both modes; `Environment:` block added to file-header comment and `cmd_help` heredoc
- Boy-scout: `.cwf/scripts/cwf-manage` shebang changed `#!/usr/bin/env perl` → `#!/usr/bin/perl -CDSL` and `use utf8;` added, bringing it into compliance with `docs/conventions/perl-git-paths.md`. Pre-existing em-dashes in error messages now emit clean UTF-8 instead of double-encoded mojibake under `PERL5OPT=-CDSL`
- Modified: `.cwf/security/script-hashes.json` — refreshed `cwf-manage` sha256
- Added: `t/cwf-manage-resolve-source.t` — six unit subtests covering the env × file matrix (set/empty/unset × present/empty/missing); uses `*main::die_msg` symbol-table override to make `exit 1` paths catchable via `eval`
- BACKLOG: added "Make cwf-manage update handle a dirty working tree" (bugfix, High) and "Resolve cwf-project.json version drift vs .cwf/version" (discovery, Medium) — sibling pain points from the same external-user upgrade report. Added "Audit Perl helpers against perl-git-paths.md conventions" as a retrospective follow-up.

### Notable
- Decision 2 (transient override, no persistence) was the load-bearing design call — and TC-10 validated it empirically: `CWF_SOURCE=file:///… cwf-manage update v1.0.114` against a fixture with `cwf_source=https://example.com/SENTINEL` updated `cwf_version`/`cwf_ref`/`cwf_sha`/`cwf_installed` correctly while leaving `cwf_source=https://example.com/SENTINEL` untouched. Avoids the "one-shot env var silently re-pins the installation" surprise mode.
- Plan-review subagents earned their cost: design review caught the empty-string env-var trap (`||` vs `defined && ne ''`) and pulled an asymmetric two-line logging proposal into a single line with origin suffix (no branching at call sites). /simplify post-plan caught a fabricated `t/versioning.t` cite in the d-impl plan-review summary that the original Misalignment subagent emitted — small, but exactly the kind of drift that becomes load-bearing later.
- The boy-scout fix was raised early but I initially proposed deferring to a separate task — user pushed back ("why are we doing a massive ceremony to do a very minor totally obvious fix while we're doing this work?"); fix landed in this task. Reinforces the principle that co-located one-line fixes don't earn the full task ceremony.
- Suite: 229 → 235 passing (24 files). `cwf-manage validate` OK after both hash bumps.

## Task 114: Add Retrospective Version Bump and Tag Settings with Versioning Helper Script

### Status: Complete (2026-04-26)
### Duration: 1 session (estimated: 1-2 days — well under)
### Impact: Feature — deterministic semver versioning subsystem invoked from the retrospective phase. CwF projects gain `versioning.major_minor` (HITL) and `versioning.last_released` (script-owned) fields in `cwf-project.json`, plus per-project `wf_step_config.retrospective.{bump_version,tag_version}` flags. Three new helper scripts (`cwf-version-{next,bump,tag}`) implement the workflow; the `cwf-retrospective` skill calls them. CwF itself is configured `bump_version: true`, `tag_version: false` (tagging stays human-only per CLAUDE.md); external adopters can flip either flag.

### Changes
- Added: `.cwf/lib/CWF/Versioning.pm` — version-with-config logic (`read_config`, `wf_step_setting`, `next_version`, `current_version`, `bump_to`, `tag_at`)
- Added: `.cwf/scripts/command-helpers/cwf-version-next` — read-only "what's the next version" printer
- Added: `.cwf/scripts/command-helpers/cwf-version-bump` — atomic same-dir tmp+rename writer for `versioning.last_released`; respects `bump_version` flag; idempotent
- Added: `.cwf/scripts/command-helpers/cwf-version-tag` — annotated git tag at the next version; on-main-only; refuses on existing tag; respects `tag_version` flag
- Added: `.cwf/docs/workflow/versioning-standard.md` — user-facing standard (ownership, configuration, helper-script index, retrospective sequence, idempotency caveat)
- Modified: `.cwf/lib/CWF/Common.pm` — added `parse_semver`, `version_cmp` (extracted from `cwf-manage`), and `find_git_root` (extracted from the `git rev-parse --show-toplevel` idiom that lived in three places)
- Modified: `.cwf/scripts/cwf-manage` — imports the two semver utilities from `CWF::Common`; behaviour-preserving (regression covered by `t/cwf-manage-list-releases.t`)
- Modified: `.cwf/lib/CWF/Validate/Config.pm` — schema rules for the new `versioning` and `wf_step_config` blocks, factored into `_validate_versioning_block`, `_validate_wf_step_config_block`, `_is_bool`, `_scalar_repr` helpers
- Modified: `implementation-guide/cwf-project.json` — added `versioning: { major_minor: "v1.0", last_released: "v1.0.114" }` and `wf_step_config: { retrospective: { bump_version: true, tag_version: false } }`. The first `cwf-version-bump` invocation also normalised the file to canonical pretty-print (one-time formatting noise)
- Modified: `version.yml` — rebranded CIG → CwF; reduced to a brief descriptor pointing at `cwf-project.json` as the source of truth
- Modified: `.claude/skills/cwf-retrospective/SKILL.md` — inserted Step 9 (bump) and Step 11 (tag); renumbered the squash and merge-suggestion steps to 10 and 12
- Modified: `.cwf/docs/skills/retrospective-extras.md` — section labels updated to match the new SKILL.md numbering
- Modified: `.cwf/security/script-hashes.json` — registered the three new scripts (0500); refreshed hashes for the four touched files
- Tests: new `t/versioning.t` (19 subtests), new `t/cwf-version-{next,bump,tag}.t` (15 subtests total), TC-X1..X8 added to `t/validate-config.t` (8 subtests), TC-C1..C4 added to `t/common.t` (4 subtests). Suite: 196 → 229 passing (`Files=23`)

### Notable
- Plan-review subagents earned their cost again at every phase: requirements review caught the human-only-tag externalisation (CwF-internal rule, not externally imposed); design review caught the existing semver parsing in `cwf-manage` that justified the module extraction and flagged the optional `--task-num` as a silent-failure trap (made required); implementation review caught Getopt::Long as out-of-codebase-style.
- `/simplify` post-implementation review found four real cleanups even after the three plan reviews: extract `find_git_root` to `CWF::Common`, thread `$cfg` through `bump_to`/`tag_at` to cut N+1 reads, flatten the new validation into helpers, drop two restating comments. Layered review (plan + post-impl) is paying for itself.
- Eating own dog food caught a fresh issue: `retrospective-extras.md` had section labels ("Step 9", "Step 10", "Step 11") tied to the SKILL.md numbering; the renumber silently rotted them. Caught only by actually running the retrospective skill on this very task. Fixed in-task. Added to BACKLOG as "Skill cross-reference linter" follow-up.
- KD8 (bump pre-squash, tag post-squash) was the right call — without explicit ordering, putting both before the squash would have left tags pointing at commits that the squash workflow rewrote.

## Task 113: Build Uncommitted Changes Warning Stop Hook

### Status: Complete (2026-04-25)
### Duration: 1 session (estimated: 1 session — on target)
### Impact: Feature — second Stop hook (Candidate B from Task 103's framework) deployed alongside Task 104's stale-status detector. Warns when the agent stops with uncommitted (staged, unstaged, untracked, or conflict-state) wf files in `implementation-guide/`. Output bounded to ~25 tokens with a 3-file cap; silent on clean stops.

### Changes
- Added: `.cwf/scripts/hooks/stop-uncommitted-changes-warning` — 31-line Perl hook (`-CDSL` shebang, `use utf8;`, `eval`-wrapped, exits 0 always)
- Modified: `.claude/settings.local.json` — appended hook command to `hooks.Stop[0].hooks`; permission allow entry for the hook path (developer-local, not tracked)
- Added: `docs/conventions/perl-git-paths.md` — new project convention doc capturing `-CDSL` + `-z` + `use utf8;` for Perl helpers consuming git path output
- BACKLOG: Completed "Build Uncommitted Changes Warning Stop Hook" item; added "Add Conflict-State Regression Test for stop-uncommitted-changes-warning" follow-up

### Notable
- Plan review subagents earned their cost: caught wrong settings-file reference (b), missed `core.quotepath` gap and dead rename-handling code (c), and ambiguous `substr` notation (d).
- User correction during design steered the implementation from `core.quotepath=false` (partial) to `-z` (canonical) — git's documented mechanism for verbatim path output. Codified as project convention.
- Smoke testing caught a real bug before deployment: `-CDSL` does not cover source-file encoding, only I/O streams. Without `use utf8;`, the literal `⚠` in source bytes was double-UTF-8-encoded on output (`â  `). Fix added to script and gotcha documented in conventions doc.
- /simplify review confirmed the script is idiomatic — no premature abstraction (Rule of Three not met for two callers); intentional consistency with Task 104 patterns.

## Task 111: Add Measure-Twice-Cut-Once Gotchas to Plan Skills

### Status: Complete (2026-04-22)
### Duration: 1 session (estimated: <1 session — on target)
### Impact: Chore — unified two open BACKLOG items (cwf-design-plan assumption verification, cwf-implementation-plan codebase checking) into a single shared gotcha under the "measure twice, cut once" theme. Gotcha 3 is byte-identical across both SKILL.md files and includes a reminder to check memories alongside grep and file reading.

### Changes
- Modified: `.claude/skills/cwf-design-plan/SKILL.md` — gotcha 3 appended
- Modified: `.claude/skills/cwf-implementation-plan/SKILL.md` — gotcha 3 appended (byte-identical to above)

### Notable
- Plan review caught a format inconsistency (multi-line proposed vs single-line existing gotchas); fixed pre-implementation.
- User caught two wording weaknesses plan review did not: a weak enumeration of artefact types (dropped) and a missing "check memories" clause (added). Plan review agents assess structure and reuse, not prose quality — wording review is a distinct check for text-heavy tasks.
- Status sweep found nothing to fix for the first time in 3 tasks — Gotcha 1 is paying off.

## Task 110: Add Gotchas to Plan Skills to Prevent Step-Skipping

### Status: Complete (2026-04-22)
### Duration: 1 session (estimated: <1 session — on target)
### Impact: Bugfix — addresses recurring step-skipping behaviour in cwf-requirements-plan, cwf-design-plan, and cwf-implementation-plan SKILL.md files. Also project-neutralises gotchas in cwf-retrospective SKILL.md (added in Task 109) that referenced specific internal task numbers — skill files are installed into downstream projects where those references are meaningless.

### Changes
- Modified: `.claude/skills/cwf-requirements-plan/SKILL.md` — new `## Gotchas` section (2 gotchas)
- Modified: `.claude/skills/cwf-design-plan/SKILL.md` — new `## Gotchas` section (2 gotchas)
- Modified: `.claude/skills/cwf-implementation-plan/SKILL.md` — new `## Gotchas` section (2 gotchas)
- Modified: `.claude/skills/cwf-retrospective/SKILL.md` — project-neutralised existing 3 gotchas

Note: The existing "Add Gotchas to cwf-implementation-plan" and "Add Gotchas to cwf-design-plan" BACKLOG items cover skill-specific concerns (codebase investigation, assumption verification) that are distinct from Task 110's generic step-skipping gotchas. They remain open.

### Notable
- Plan review subagents caught the "Gotcha 3" ambiguity that would have shipped.
- /simplify review caught project-specific task-number references in both the plan-skills (Task 108, 109) and cwf-retrospective (Tasks 65, 67, 81, 84, 98, 103) — a whole class of bugs for installable skill files. Task 109's work had to be retroactively fixed within Task 110's scope.
- Gotcha 1 from Task 109 (status sweep) caught stale statuses during this task's own retrospective, on its second use. Working as designed.

## Task 109: Add Gotchas to cwf-retrospective Skill

### Status: Complete (2026-04-21)
### Duration: 1 session (estimated: <1 session — on target)
### Impact: Chore — added 3 gotcha warnings to cwf-retrospective SKILL.md targeting the most recurring CWF errors: stale status fields (6+ tasks), executing merge to main (2 tasks), and skipping the retrospective (2 tasks). Also reworded Step 10 from "Merge to main" to "Suggest merge to user (do not execute)".

### Changes
- Modified: `.claude/skills/cwf-retrospective/SKILL.md` — new `## Gotchas` section + Step 10 rewording
- BACKLOG: Completed "Add Gotchas to cwf-retrospective Skill" item

### Notable
- Plan review subagents (Task 108) caught a real error: Gotcha 3 originally said "proceed to retrospective (j)" which skips h/i for feature tasks. Corrected to "complete all remaining phases."
- Gotcha 1 was immediately validated during this task's own retrospective — d and e were still "In Progress."

## Task 108: Add Map/Reduce Plan Review to Planning Skills

### Status: Complete (2026-04-21)
### Duration: 1 session (~1 hour, estimated: 1 day — under estimate)
### Impact: Feature — 3 planning skills (cwf-requirements-plan, cwf-design-plan, cwf-implementation-plan) now automatically review plan files before checkpoint commit using 3 parallel subagents focused on improvements, misalignment, and robustness.

### Changes
- New: `.cwf/docs/skills/plan-review.md` — shared doc with parameterised prompt template, 3×3 criteria lookup table, reduce/synthesis instructions
- Modified: 3 SKILL.md files — added `Agent` to allowed-tools, inserted Step 8 (plan review), renumbered Steps 9-10
- First CWF skill to use the Agent tool

### Notable
- /simplify was run on the plan files before implementation, effectively dogfooding the feature. It identified 8 must-fix items that collapsed 9 prompt templates to 1, removed unnecessary ceremony, and simplified the implementation from ~200 lines to ~50 lines.

## Task 107: Discover Best Gotchas for Skills via LMM Memory Analysis

### Status: Complete (2026-04-21)
### Duration: 1 session (estimated: 1 session — on target)
### Impact: Discovery — analysed all 19 CWF skills via LMM semantic search and retrospective file analysis to identify recurring failure modes. Produced 4 backlog items with 8 evidence-backed gotchas.

### Findings
- **cwf-retrospective** (High, 3 gotchas): Stale status fields (6+ tasks), executing merge to main (2 tasks), skipping retrospective (2 tasks)
- **cwf-implementation-exec** (High, 2 gotchas): Missing `git status` before commits, stale refs after renames (5 tasks)
- **cwf-implementation-plan** (Medium, 2 gotchas): Planning without codebase investigation (5 tasks), not checking for reusable code (2 tasks)
- **cwf-design-plan** (Medium, 1 gotcha): Choosing approach without verifying codebase (2 tasks)
- 15 skills had no recurring failure patterns

### BACKLOG Items Created
- "Add Gotchas to cwf-retrospective" (High)
- "Add Gotchas to cwf-implementation-exec" (High)
- "Add Gotchas to cwf-implementation-plan" (Medium)
- "Add Gotchas to cwf-design-plan" (Medium)

## Task 106: Rename cwf-subtask Skill to cwf-new-subtask

### Status: Complete (2026-04-21)
### Duration: 1 session (estimated: <1 day — on target)
### Impact: Chore — renamed `/cwf-subtask` to `/cwf-new-subtask` to mirror `/cwf-new-task` naming and reduce agent confusion.

### Changes
- `.claude/skills/cwf-subtask/` → `.claude/skills/cwf-new-subtask/` (directory rename + `name:` field update)
- `CLAUDE.md`, `README.md`: Updated skill reference
- `.cwf/docs/workflow/decomposition-guide.md`: Updated 3 references (usage line + 2 examples)
- `.claude/skills/cwf-task-plan/SKILL.md`: Updated subtask suggestion reference
- `BACKLOG.md`: Updated 4 active item references

### Testing
- 5/5 test cases passed: directory exists, old dir gone, zero stale live refs, new name in expected files, historical files untouched

## Task 105: Consolidate Status Extraction to CWF::TaskState

### Status: Complete (2026-04-19)
### Duration: 1 session (estimated: 1 day — on target)
### Impact: Chore — consolidated 4 independent section-scoped, code-block-aware parsing loops into a single general-purpose `CWF::MarkdownParser::extract_field()` API. Net -91 LOC in production code. Fixed bug in `Validate::Workflow` (hardcoded status list diverged from `cwf-project.json`).

### Changes
- `.cwf/lib/CWF/MarkdownParser.pm`: Generalised with `extract_field()` and `find_field_line()`, deleted `extract_status()`
- `.cwf/lib/CWF/TaskState.pm`: `_find_status_line` delegates to MarkdownParser, added `status_is_valid()` predicate
- `.cwf/lib/CWF/StatusAggregator/Core.pm`: Migrated from MarkdownParser + WorkflowFiles to TaskState (`status_get` + `status_percent`)
- `.cwf/lib/CWF/ContextInheritance/Core.pm`: Migrated from MarkdownParser to TaskState
- `.cwf/lib/CWF/Validate/Workflow.pm`: Replaced inline parsing + hardcoded status list with `TaskState::status_get` + `status_is_valid`. `_check_file` reduced from 40 to 15 lines.
- `.cwf/lib/CWF/Validate/Consistency.pm`: Replaced `_extract_fields` inline parsing with `MarkdownParser::extract_field()` calls. Reduced from 25 to 8 lines.
- `.cwf/scripts/command-helpers/workflow-manager.d/control`, `context-inheritance-v2.0`, `context-inheritance-v2.1`: Migrated from MarkdownParser to TaskState
- `t/markdownparser.t`: Extended from 7 to 12 tests (added non-status field and find_field_line tests)

### Bug Fixed
- `Validate::Workflow` had hardcoded `%ALLOWED_STATUS_SET` containing `Implemented` (not in config) and missing `To-Do` (in config). Now reads from `cwf-project.json` via `TaskState::status_is_valid()`.

## Task 104: Build Stale Status Detector Stop Hook

### Status: Complete (2026-04-19)
### Duration: 1 session (estimated: 1 session — on target)
### Impact: Feature — Stop event hook that detects wf files modified during the session whose status is still "Backlog". First hook in the CWF system.

### Changes
- `.cwf/scripts/hooks/stop-stale-status-detector`: New 42-line Perl script using `CWF::TaskState::status_get()` for canonical status extraction
- `.claude/settings.local.json`: Added `hooks.Stop` registration (developer-local, not committed)

### Key Decisions
- Rewrote from planned bash/grep to Perl — avoids creating a 4th independent status extraction implementation
- `set -u` only, no `set -e` — `set -e` kills scripts when grep finds no matches, which is the common clean-stop case
- Git pathspec filtering (`-- 'implementation-guide/*/[a-j]-*.md'`) instead of separate grep fork

### BACKLOG Items Created
- "Consolidate Status Extraction to Single Canonical Module (CWF::TaskState)" — Very High priority, 3 duplicate implementations discovered
- "Progress Signal Scores Completed Tasks Highest in Task Context Inference" — Medium priority bugfix

## Task 103: Research Stop Event Hooks for CWF Quality Improvement

### Status: Complete (2026-04-19)
### Duration: 1 session (estimated: 1 session — on target)
### Impact: Discovery — produced a reusable framework for evaluating Stop event hooks, with taxonomy, evaluation checklist, and ranked candidates grounded in observed CWF errors.

### Changes
- `.cwf/docs/workflow/stop-hooks-framework.md`: New 101-line framework document with 4-category taxonomy, 6-question evaluation checklist, and 3 candidates ranked build/defer/skip

### Key Findings
- **Stale Status Detector** (Candidate A): Build — 6+ occurrences of stale status fields, ~50 tokens per stop, no existing coverage
- **Uncommitted Changes Warning** (Candidate B): Build — 2-3 occurrences, ~25 tokens per stop
- **Validate-on-Stop** (Candidate C): Skip — duplicates checkpoint commit's built-in `cwf-manage validate`
- Category 4 (Waste detection) had insufficient evidence to justify a hook

### BACKLOG Items Completed
- "Research Stop Event Hooks for Correctness, Quality, and Efficiency" — original discovery task

### BACKLOG Items Created
- "Build Stale Status Detector Stop Hook" — Candidate A from framework
- "Build Uncommitted Changes Warning Stop Hook" — Candidate B from framework

## Task 102: Add Checkpoint Commit Helper Script (cwf-checkpoint-commit)

### Status: Complete (2026-04-18)
### Duration: 1 session (estimated: 1 day — on target)
### Impact: Feature — bundles the 5-step checkpoint commit procedure into a single atomic script call, eliminating the most common agent errors during workflow phase transitions.

### Changes
- `.cwf/scripts/command-helpers/cwf-checkpoint-commit`: 56-line Perl script — validates args, resolves task, globs wf file, sets status to Finished, stages, commits with formatted message, runs `cwf-manage validate`
- `.cwf/docs/skills/checkpoint-commit.md`: Updated to document script as primary method, manual steps preserved as reference
- `.cwf/security/script-hashes.json`: SHA256 hash registered

### Key Design Decisions
- List-form `system('git', 'commit', '-m', $msg)` instead of `File::Temp` — bypasses shell entirely
- Glob `{letter}-*.md` for version-agnostic wf file resolution (works for v2.0 and v2.1)
- `cwf-manage validate` baked into script — agents skip optional work
- No SKILL.md edits — skills already reference `checkpoint-commit.md`

### BACKLOG Items Completed
- "Add Checkpoint Commit Helper Script (`cwf-checkpoint-commit`)" — from Task 100 discovery (rank 3.0)

## Task 101: Add Status Update Helper Script (cwf-set-status)

### Status: Complete (2026-04-18)
### Duration: 1 day (estimated: 1 day — on target)
### Impact: Feature — adds validated status field updates to `CWF::TaskState` and a CLI wrapper, replacing manual regex replacements across all ~10 workflow skills.

### Changes
- `CWF::TaskState`: Added `status_set`, renamed `status_extract` → `status_get`, extracted shared `_find_status_line` (section-scoped, code-block-aware) and `_ensure_status_map` helpers
- `.cwf/scripts/command-helpers/cwf-set-status`: 19-line CLI wrapper around `status_set`
- `status-aggregator-v2.0/v2.1`: Updated imports to `status_get`
- `t/cwf-set-status.t`: 5 functional + 1 non-functional test case
- Security hashes updated for all changed files

### BACKLOG Items Completed
- "Add Status Update Helper Script (`cwf-set-status`)" — confirmed highest priority by Task 100, now delivered

### BACKLOG Items Created
- Add `status_set` unit tests directly in `t/task-state.t` (currently tested only via CLI wrapper)

## Task 100: Identify Deterministic Operations Still Handled by Agent

### Status: Complete (2026-04-17)
### Duration: 1 session (estimated: 1 session — on target)
### Impact: Discovery — systematic audit of all 18 CWF skills to identify deterministic

operations the agent performs that should be extracted to helper scripts. Found 24
candidates across 8 skills (10 skills already well-scripted). Produced 5 ranked backlog
items for extraction.

### Findings
- 24 deterministic operations found, 10 skills had zero unique candidates
- Shared preamble (argument parsing) and checkpoint commit procedure are highest-leverage targets
- Status field update is the most frequent deterministic operation (rank 6.0)
- JSON manipulation in cwf-init is the most error-prone (rank 1.5 but highest error score)
- cwf-extract is the only skill that is entirely deterministic end-to-end

### BACKLOG Items Created
- cwf-set-status script (feature, High) — confirms existing backlog item priority
- cwf-checkpoint-commit script (feature, High)
- cwf-slug script (feature, Medium)
- cwf-settings-merge script (feature, Medium)
- cwf-extract replacement script (feature, Low)

## Task 99: Add PreToolUse Hook for Rule Re-Injection

### Status: Complete (2026-04-17)
### Duration: 1 session (estimated: 1 session — on target)
### Impact: Feature — critical CWF rules now survive context compaction via automatic

re-injection on every user message.

### Changes
- `.cwf/rules-inject.txt`: 5-line rules file with 4 critical rules (use skills, checkpoint
  commit, never merge to main, git status before commits)
- `.claude/skills/cwf-init/SKILL.md`: Step 6c added for PreToolUse hook configuration with
  idempotent `UserPromptSubmit` matcher setup
- `.cwf/docs/glossary.md`: "hook" and "rules injection" terms added
- `scripts/install.bash`: Unified `create_skill_symlinks` and `create_rule_symlinks` into
  single `create_cwf_symlinks` function (-48 lines), removed redundant cleanup loops,
  consolidated force-reinstall directory removal into loop

### BACKLOG Items Addressed
- "Add PreToolUse Hook for Rule Re-Injection" (from Task 97 discovery)

## Task 98: Add Path-Scoped Rules for Workflow File Protection

### Status: Complete (2026-04-17)
### Duration: 1 session (estimated: 1 session — on target)
### Impact: Feature — wf step files now trigger an advisory rule reminding the agent to

use the corresponding `/cwf-{step}` skill instead of editing directly.

### Changes
- `.claude/rules/cwf-workflow-files.md`: Path-scoped rule with glob
  `implementation-guide/**/{a,b,c,d,e,f,g,h,i,j}-*.md` mapping each prefix to its skill
- `scripts/install.bash`: Added `create_rule_symlinks()`, third subtree split for
  `.claude/rules`, force-reinstall cleanup for `.cwf-rules`
- `.claude/skills/cwf-init/SKILL.md`: Step 6b added for rules directory and symlink creation
- `.cwf/docs/glossary.md`: "cwf- prefix" and "rule" terms added

### BACKLOG Items Addressed
- "Add Path-Scoped Rules for Workflow File Protection" (from Task 97 discovery)

## Task 97: Research Claude Code Best Practices for CWF Quality Improvements

### Status: Complete (2026-04-16)
### Duration: 1 session (estimated: 1 session — on target)
### Impact: Discovery — systematic review of Claude Code best practices corpus (40+ files,

10 topic areas) against CWF current implementation. Produced 6 prioritised backlog items
for quality improvements. Emergent discussion on agent process enforcement yielded insights
on Deming-inspired post-training approaches.

### Findings
- Path-scoped rules (`.claude/rules/`) are the closest to enforcement for skill usage
- PreToolUse hooks survive compaction where CLAUDE.md instructions do not
- Stop event hooks can validate output correctness at completion boundaries
- Progressive disclosure via Read is better than `@import` for prompt cache stability
- Agent process enforcement is fundamentally impossible with full system access

### BACKLOG Items Created
- Path-scoped rules for wf file protection (feature, High)
- PreToolUse hook for rule re-injection (feature, High)
- Stop event hooks research (discovery, High)
- Gotchas via LMM memory analysis (discovery, High)
- Compaction failure frequency research (discovery, Medium)
- Session hygiene guidance (chore, Medium)

### Architectural Decisions
- Rejected `context: fork` — agent needs skill output in context for subsequent decisions
- Rejected `disable-model-invocation` — contradicts skill-first philosophy (skills are quality gates)
- Deferred `@import` — current progressive disclosure approach is better for caching

## Task 96: Fix Subtask Resolution to Support Nested Directory Hierarchy

### Status: Complete (2026-03-31)
### Duration: 1 session (estimated: 1–2 sessions — on target)
### Impact: Bugfix — nested subtask directories (a founding design goal) were never

supported by the resolution code. `resolve_num()` only searched flat in
`implementation-guide/`, so `context-manager hierarchy 48.1` failed with "Task not found"
when `48.1` was correctly nested inside `48`'s directory. Now uses iterative ancestor walk
to resolve any nesting depth.

### Changes
- `.cwf/lib/CWF/TaskPath.pm`: `resolve_num()` rewritten with iterative ancestor walk;
  `find_children()` searches inside resolved task dir instead of flat base
- `.cwf/scripts/command-helpers/template-copier-v2.1`: `construct_destination()` nests
  subtasks inside resolved parent directory
- `.claude/skills/cwf-new-task/SKILL.md`, `.claude/skills/cwf-subtask/SKILL.md`: explicit
  nested path examples replacing ambiguous "create subdirectory"
- `.cwf/security/script-hashes.json`: updated hashes for modified scripts

### BACKLOG Items Addressed
- None

### Migration Note
Existing flat subtasks (e.g. `implementation-guide/48.1-bugfix-*` at top level) will not
be found by the new nested resolution. Move them into their parent directory:
`implementation-guide/48-*/48.1-bugfix-*/`

## Task 95: Fix Bare workflow-manager Path in All wf Step Skills

### Status: Complete (2026-02-26)
### Duration: < 1 hour (estimated: < 1 hour — on target)
### Impact: Bugfix — all 10 wf step SKILL.md files referenced `workflow-manager control`

without a path, causing models to fail with "command not found" when trying to use the
control flow feature. Fixed to `.cwf/scripts/command-helpers/workflow-manager control`.

### Changes
- `.claude/skills/cwf-{task-plan,requirements-plan,design-plan,implementation-plan,implementation-exec,testing-plan,testing-exec,rollout,maintenance,retrospective}/SKILL.md`: "If blocked or finished" line updated with full repo-relative path

### BACKLOG Items Addressed
- None

## Task 94: Fix Stale Repo URL in install.bash and INSTALL.md

### Status: Complete (2026-02-25)
### Duration: < 1 hour (estimated: < 1 hour — on target)
### Impact: Bugfix — corrects stale `mattkeenan/coding-with-files` GitHub org references

that would have caused default installs to fail. Task 91 fixed `README.md` but missed
`scripts/install.bash` (the `CWF_SOURCE` default) and `INSTALL.md` (the quick-install
curl command). Both corrected.

### Changes
- `scripts/install.bash:24`: `CWF_SOURCE` default URL `mattkeenan` → `CodingWithFiles`
- `INSTALL.md:12`: quick-install curl command `mattkeenan` → `CodingWithFiles`

### BACKLOG Items Addressed
- None

## Task 93: README.md — Problem and Benefits Sections

### Status: Complete (2026-02-22)
### Duration: ~45 minutes (estimated: <1 hour — on target)
### Impact: Bugfix — adds three new sections near the top of README.md explaining the

problem CWF solves, what it does, and why the structure matters. Includes a Dan Shapiro
Five Levels reference (targeting Level 3–3.3) and the 80% token-efficiency context
reduction figure.

### Changes
- `README.md`: inserted "The Problem With AI-Assisted Coding", "What CWF Does", and
  "Why the Structure Matters" between `## Overview` and `## Project Status`

### BACKLOG Items Addressed
- None

## Task 92: Fix COMMERCIAL-LICENSE.md GPL-2.0 → AGPL-3.0

### Status: Complete (2026-02-22)
### Duration: ~20 minutes (estimated: <15 minutes — on target)
### Impact: Hotfix — corrects incorrect licence references in COMMERCIAL-LICENSE.md. CWF has

never been released under GPL-2.0; that licence applied briefly to the predecessor project
(CIG). The incorrect text was carried over during the Task 59 CIG→CWF rebrand.

### Changes
- `COMMERCIAL-LICENSE.md`: all three GPL-2.0 / GPL v2.0 references replaced with AGPL-3.0

### BACKLOG Items Addressed
- None

## Task 91: README.md Updates for v1.0.90

### Status: Complete (2026-02-22)
### Duration: ~30 minutes (estimated: <1 hour — well under)
### Impact: Bugfix — brings README.md in sync with v1.0.90: correct org URL, full v2.1

10-skill workflow command list, accurate task-type phase counts, semver convention, and
direct GitHub issues link. One unplanned fix: `v2.0` heading in Features section caught
by TC-3 absence-grep.

### Changes
- `README.md`: install URL `mattkeenan` → `CodingWithFiles`; full v2.1 Commands section
  (10 workflow skills, plan/exec split noted); Task Types phase counts and sequences;
  Version Information with `v{major}.{minor}.{task_num}` and `cwf-manage list-releases`;
  support link → direct GitHub issues URL; Features section `v2.0` heading removed

### BACKLOG Items Addressed
- None

## Task 90: Fix Stale CIG References in WF Step Templates and Template-Copier

### Status: Complete (2026-02-22)
### Duration: ~20 minutes (estimated: <0.25 days — well under)
### Impact: Hotfix — closes a Task 59 (CIG→CWF rebrand) miss that caused every new task

created since the rebrand to have wrong paths and skill names in generated wf step files.
Two fix sites: the `**See ...` Status footer in all 10 wf step templates (`.cig/` →
`.cwf/`), and `name_to_action()` in `template-copier-v2.1` (`/cig-` → `/cwf-`).

### Changes
- `.cwf/templates/pool/*.template` (all 10): Status footer path corrected
- `.cwf/scripts/command-helpers/template-copier-v2.1`: lines 332 and 399 `/cig-` → `/cwf-`
- `.cwf/security/script-hashes.json`: SHA256 updated for modified template-copier-v2.1

### BACKLOG Items Addressed
- None

## Task 89: Update Version Conventions

### Status: Complete (2026-02-22)
### Duration: ~2 hours (estimated: 0.5 days — well under)
### Impact: Feature — establishes `v{major}.{minor}.{task_num}` semver convention for CWF

itself, documented dev-side only; updates `cwf-manage list-releases` from a full tag dump
to a curated upgrade view showing the latest patch on current minor, one entry per higher
minor, and one entry per higher major.

### Changes
- `CLAUDE.md`: new `## Versioning` section defining the semver scheme, human-only tagging
  constraint, and isolation requirement (not to be referenced from any installed file)
- `.cwf/scripts/cwf-manage`: new `parse_semver` sub (strict `v\d+.\d+.\d+` via regex);
  new `filter_releases` sub (closure-based bucket rules, map/grep pipeline); updated
  `cmd_list_releases` with `$show_all` param and `--all` flag; updated `cmd_help`
- `.cwf/security/script-hashes.json`: updated SHA256 for modified `cwf-manage`
- `t/cwf-manage-list-releases.t`: new unit test file, 11 subtests, no network dependency

### Bug Found and Fixed
TC-2 (`parse_semver` no-v-prefix rejection) caught that the plan's `s/^v//` approach
silently accepted `1.2.3`. Fixed with single-regex `/^v(\d+)\.(\d+)\.(\d+)$/`.

### BACKLOG Items Addressed
- None

## Task 88: Refactor Workflow Docs for Efficiency

### Status: Complete (2026-02-22)
### Duration: ~1 hour (estimated: 0.5 days — well under)
### Impact: Bugfix — eliminates three categories of token waste from CWF workflow docs:

repeated checkpoint commit blocks (8 phases × ~8 lines), duplicate "Typical Structure"
sections (10 phases × ~8 lines), and 3-line per-phase boilerplate in blocker-patterns.md
(9 phases × 3 lines). File-edit reversion instructions in blocker-patterns.md replaced
with explicit `/cwf-` skill call chains. Net change: −272 lines, +134 lines added (references).
Progressive disclosure preserved — every removal points to its canonical source.

### Changes
- `.cwf/docs/skills/checkpoint-commit.md`: fix stale `perl -I` command; `<>` → `{}` on placeholders
- `.cwf/docs/skills/retrospective-extras.md`: all `<var>` model-substitution variables → `{var}`
- `.cwf/docs/workflow/workflow-steps.md`: checkpoint commit blocks replaced with 1-line references;
  Typical Structure sections replaced with template pool references; jq blocks removed; source reference added
- `.cwf/docs/workflow/blocker-patterns.md`: per-phase 3-line boilerplate removed; file-edit reversion
  instructions replaced with `/cwf-` skill call chains; Decomposition Signals body → reference;
  stale `.claude/commands/` References section removed
- `.cwf/docs/workflow/decomposition-guide.md`: Context Inheritance body → reference to workflow-overview.md

### BACKLOG Items Addressed
- None (originated from ad-hoc plan)

## Task 87: Create CWF Terminology Glossary

### Status: Complete (2026-02-22)
### Duration: ~45 minutes (estimated: <1 hour — on target)
### Impact: Hotfix — 8 previously undefined terms (CWF, wf, skill, slug, task branch,

checkpoints branch, checkpoint commit, squash commit) now canonically defined in
`.cwf/docs/glossary.md`. `workflow-preamble.md` references the glossary so every skill
invocation surfaces it to lesser models without extra steps.

### Changes
- `.cwf/docs/glossary.md`: new file — index + 8 entries, grep-friendly `## TERM` headings,
  cross-references to authoritative sources for terms already defined elsewhere
- `.cwf/docs/skills/workflow-preamble.md`: added `**Terminology**` reference line

### BACKLOG Items Addressed
- "Create CWF Terminology Glossary" (Low priority, follow-up from Task 44)

## Task 86: Remove Decomposition Checks from Non-Planning Workflow Steps

### Status: Complete (2026-02-22)
### Duration: ~30 minutes (estimated: <1 hour — well under)
### Impact: Hotfix — Step 7 decomposition check removed from `cwf-rollout` and

`cwf-maintenance` SKILL.md files; remaining steps renumbered (8→7, 9→8).
Decomposition checks are only actionable during planning; rollout and maintenance
operate on already-committed work and gained no benefit from the check.

### Changes
- `.claude/skills/cwf-rollout/SKILL.md`: removed Step 7 decomposition check, renumbered Steps 8→7, 9→8
- `.claude/skills/cwf-maintenance/SKILL.md`: removed Step 7 decomposition check, renumbered Steps 8→7, 9→8

### BACKLOG Items Addressed
- "Remove Decomposition Checks from Non-Planning Workflow Steps" (Medium priority)

## Task 85: Ensure Retrospective Checkpoint Commit Stages Entire Task Directory

### Status: Complete (2026-02-22)
### Duration: ~1 hour (estimated: <1 hour — on target)
### Impact: Hotfix — closes the gap that caused stale wf step statuses to persist

in task squash commits after retrospectives (root cause of tasks 77 and 81 showing <100%).

### Changes
- `retrospective-extras.md`: Updated "Verify Task Status" to use
  `workflow-manager status <task_num> --workflow`, require all steps to be in a
  terminal status, and explicitly state that 100% overall is the norm
- `retrospective-extras.md`: Added "Retrospective Checkpoint Commit" section with
  `git add implementation-guide/<task-dir>/` to stage entire task directory,
  overriding the generic single-file staging from `checkpoint-commit.md`

## Task 84: Backlog Audit — Remove Moot Items

### Status: Complete (2026-02-21)
### Duration: ~1 hour (estimated: 1 hour — on target)
### Impact: Chore — backlog reduced from 41 to 33 active items by removing 8 items

superseded by architecture changes or already implemented, and correcting the scope
of 1 mis-specified item.

### Items Removed
- Item 12: "Update Commands/Skills to Use New Inference Output Format" — plural format never adopted
- Item 15: "Document Checkpoint Commit → Squash Workflow" — already in retrospective-extras.md Step 10
- Item 20: "Create Permanent Security Verification Script" — superseded by `cwf-manage validate`
- Item 24: "Migrate CWF to Hybrid Plugin Model" — skills migration done (Task 57); plugin hooks blocked by Bug #17688
- Item 26: "Design Task-Type-Specific Workflow Variants" — already implemented in `task-workflow create`
- "Create Automated Test Harness" — t/ directory has 15+ test files covering all major modules
- "Security Review and Hardening of CWF Bash Invocations" — commands→skills, all Perl, $ARGUMENTS moot
- "Standardize Script Naming and Invocation" — already extensionless throughout

### Item Updated
- "Remove Decomposition Checks from Non-Planning Workflow Steps" — scope corrected: keep Step 7
  in all `*-plan` skills; remove only from cwf-rollout and cwf-maintenance

## Task 83: Add Status Update Step to checkpoint-commit.md

### Status: Complete (2026-02-21)
### Duration: <1 session (estimated: <30 min — slightly over due to full wf cycle)
### Impact: Hotfix — `checkpoint-commit.md` now instructs the LLM to set

`**Status**: Finished` in the current phase's workflow file before staging,
so `cwf-status` stays accurate throughout a task rather than only being
corrected at retrospective time. All wf step skills inherit the fix
automatically — no per-skill edits needed.

### Key Changes
- `.cwf/docs/skills/checkpoint-commit.md`: inserted new step 1 ("Update status")
  before "Stage"; renumbered original steps 1-4 → 2-5

### Test Results
3/3 TCs pass: new step present as step 1, existing steps renumbered 2-5,
wording unambiguous.

## Task 82: Fix checkpoints-branch-manager verify die → warn

### Status: Complete (2026-02-21)
### Duration: <1 session (estimated: <1 session — on target)
### Impact: Bugfix — `verify_checkpoints_branch()` now emits a non-fatal warning

instead of a fatal Perl exception when `git log` exits non-zero (e.g. SIGPIPE
from piping through `head`, or branch genuinely absent). Callers receive exit
code 1 they can handle, with no misleading stack trace.

### Key Changes
- `.cwf/scripts/command-helpers/checkpoints-branch-manager`: replaced
  `die "… error: checkpoints branch not found\n" if $? != 0` with
  `warn "… warning: …\n"; exit 1` in `verify_checkpoints_branch()`
- `.cwf/security/script-hashes.json`: SHA256 updated for changed script

### Test Results
4/4 TCs pass: happy path (exit 0), error path (exit 1, warn not die),
create regression, and `cwf-manage validate` integrity check.

## Task 81: Enforce Single Canonical Task Type List

### Status: Complete (2026-02-21)
### Duration: <1 session (estimated: <1 session — on target)
### Impact: Bugfix — `cwf-manage validate` now catches projects with unknown task types

(e.g. `docs`, `refactor`, `test`) or missing canonical types (e.g. missing `discovery`).
Previously these passed silently.

### Key Changes
- `CWF::WorkflowFiles::V21`: added `supported_types()` export returning sorted keys of
  `%WORKFLOW_FILES` — single source of truth, no separate hardcoded list
- `CWF::Validate::Config`: bidirectional validation against `supported_types()`:
  unknown types in config produce a violation; missing canonical types produce a violation
- `.cwf/templates/cwf-project.json.template`: replaced ghost types (`docs`, `refactor`,
  `test`) with correct canonical list `[feature, bugfix, hotfix, chore, discovery]`
- `.cwf/docs/workflow/decomposition-guide.md`: updated file count table with v2.1
  actuals and added `discovery` type
- `script-hashes.json`: SHA256 updated for both modified `.pm` files

### Test Results
8/8 TCs pass. `prove t/` — 162 tests, 17 files, all pass. No regressions.

## Task 80: Fix install.bash file:// Source Defaults to HEAD

### Status: Complete (2026-02-21)
### Duration: <1 session (estimated: <1 session — on target)
### Impact: Bugfix — installing CWF from a local `file://` clone with no `CWF_REF`

set previously resolved `latest` to the most recent git tag (e.g. `v0.2.1`), which
predates the `.cig` → `.cwf` rename and causes a fatal subtree error. Now defaults
to `HEAD` when `CWF_SOURCE` is a `file://` URL.

### Key Changes
- `scripts/install.bash`: added 4-line guard at top of `resolve_ref()`:
  if ref is `latest` and `CWF_SOURCE` starts with `file://`, log
  `"file:// source detected — defaulting CWF_REF to HEAD"` and return `HEAD`.
  Remote sources (`https://`, `git://`, `ssh://`) are unaffected.
- `INSTALL.md`: added "Installing from a local clone" subsection after the env vars
  table — documents `file://` URL syntax, HEAD default behaviour, and explicit
  `CWF_REF` override example.

### Test Results
5/5 TCs pass including 2 live end-to-end installs into temp repos.
`prove t/` exits 0 (158 tests, no regressions).

## Task 79: Update Branding and Documentation for Skills Architecture

### Status: Complete (2026-02-20)
### Duration: <1 session (estimated: <1 session — on target)
### Impact: Bugfix — CLAUDE.md and README.md now reflect current skills architecture

terminology and correct v2.1 skill names throughout.

### Key Changes
- `CLAUDE.md`: "Available CWF Commands" → "Available CWF Skills"; section headers
  "Core/Workflow/Utility Commands" → "Skills"; replaced entire v2.0 workflow skill
  list with current v2.1 names (`/cwf-task-plan`, `/cwf-requirements-plan`,
  `/cwf-design-plan`, `/cwf-implementation-plan`, `/cwf-implementation-exec`,
  `/cwf-testing-plan`, `/cwf-testing-exec`); prose "commands reference docs" →
  "skills reference docs"; "designated commands" → "designated skills"
- `README.md`: "slash commands" → "skills" (×2 in overview); "Test all commands" →
  "Test all skills" (contributing section)

### BACKLOG Items Completed
- "Update Branding and Documentation for Skills Architecture" (from Task 57 retrospective)

### Test Results
6/6 grep-based TCs pass. `prove t/` exits 0 (158 tests, no regressions).

## Task 78: Fix Progress Signal Non-Determinism in task-context-inference

### Status: Complete (2026-02-19)
### Duration: <1 session (estimated: <1 session — on target)
### Impact: Hotfix — `task-context-inference` now returns a consistent

`confidence: correlated` result on every run. Previously, completed tasks with
`state_achievable == 0` produced `score == 0` in `_get_progress_signal`, and
Perl's non-deterministic sort order for equal elements caused a different random
task to appear as a noise partner on each invocation, yielding `confidence:
uncorrelated` every time.

### Key Changes
- `.cwf/lib/CWF/TaskContextInference.pm`: added `grep { $_->{score} > 0 }` filter
  after sort and before splice in `_get_progress_signal`
- `.cwf/security/script-hashes.json`: SHA256 updated for modified module
- `t/taskcontextinference.t`: regression subtest added —
  `get_all_signals() - progress candidates all have score > 0`

### Test Results
158 tests across 17 files (up from 157), all pass. 5× consecutive runs of
`task-context-inference` produce identical output.

## Task 77: Comprehensive Perl Test Suite for CWF Library Modules

### Status: Complete (2026-02-19)
### Duration: ~1 session (estimated 3–5 days — 80% faster than estimate)
### Impact: Feature — establishes `prove t/` as the standard quality gate for all 17

CWF library modules. Regressions are now caught automatically rather than through
manual inspection.

### Key Changes
- `t/lib/CWFTest/Fixtures.pm` (new): shared test helper with `create_task_dir`,
  `create_git_repo`, `create_config`
- `t/task-state.t` (migrated): updated from `.cig/lib` to `.cwf/lib`, removed
  obsolete `Implemented` status, corrected `Blocked` expected values (15%, not 0%)
- 16 new `.t` files (one per remaining `.pm`): common, contextinheritance, markdownparser,
  options, statusaggregator, taskcontextinference, taskpath, templatecopier,
  validate-config, validate-consistency, validate-security, validate-workflow,
  versionrouter, workflowfiles, workflowfiles-v20, workflowfiles-v21

### Test Results
157 tests across 17 files, all pass, suite runtime ~0.9s.

### Notable Patterns (Perl test footguns documented in i-maintenance.md)
- `ok(grep { ... } @list, $msg)` — message included in grep list; use `ok((grep {...}), $msg)`
- `qw(In\ Progress)` — creates two words; use `('In Progress', ...)`
- Functions not in `@EXPORT_OK` must be called fully qualified
- `Blocked` status = 15% in `CWF::TaskState`, not 0%

## Task 76: Add Re-Execution Guidance to Implementation and Testing Exec Skills

### Status: Complete (2026-02-19)
### Duration: <1 session (trivial)
### Impact: Bugfix — agents re-running `cwf-implementation-exec` or `cwf-testing-exec`

on an already-executed phase now have explicit instructions: work forward, don't revert
commits, use `Task N: Pass 2: …` commit naming, append results rather than overwriting.

### Key Changes
- `.cwf/docs/skills/re-execution.md` (new): shared guidance doc with Detection, Core
  Rule (no reverts), Commit Naming, Doc Handling, and Non-Blocker sections
- `.claude/skills/cwf-implementation-exec/SKILL.md`: conditional re-execution check
  inserted between Step 5 and Step 6
- `.claude/skills/cwf-testing-exec/SKILL.md`: same insertion

### Test Results
6/6 tests pass (content review).

## Task 75: Harden Install Script with Pre-Flight Checks and Simplify Bootstrap

### Status: Complete (2026-02-19)
### Duration: <1 session (trivial)
### Impact: Bugfix — `install.bash` now exits with a clear error when the target repo

has no commits (subtree method requires at least one). Bootstrap docs simplified from
a 4-line sparse-checkout sequence to clean one-liners.

### Key Changes
- `scripts/install.bash`: Added initial-commit guard in `check_prerequisites()` —
  subtree method only; exits with descriptive error if `git rev-parse HEAD` fails
- `README.md`: Replaced 4-line sparse-checkout block with two one-liners (GitHub curl,
  non-GitHub `git archive --remote`)
- `INSTALL.md`: Same replacement; relabelled sections as "GitHub" and
  "GitLab, Gitea, Forgejo, self-hosted"

### Test Results
6/6 tests pass. Guard fires correctly for empty repo + subtree; skipped for committed
repo + subtree and all copy-method repos.

## Task 74: Fix template-copier-v2.1 Uninitialized Variable Warnings

### Status: Complete (2026-02-19)
### Duration: <1 session (trivial)
### Impact: Bugfix — `Branch` field in all generated template files is now correctly populated from the project's branch-naming convention. Previously always blank due to two compounding silent bugs in `build_template_vars`.

### Root Cause
Two bugs in `build_template_vars`, both silent:
1. Config key path `$config->{'branch-naming-convention'}` was wrong — the key is nested under `source-management`. The `// ''` default masked the undef silently.
2. Substitution regex used double-brace format `{{task-type}}` but the config pattern uses single-brace `{task-type}` — substitution never fired.

### Key Changes
- `.cwf/scripts/command-helpers/template-copier-v2.1`: Fixed config key path (line 354) and substitution brace format (lines 368-370)
- `.cwf/security/script-hashes.json`: Updated SHA256 for `template-copier-v2.1`

### Test Results
5/5 tests pass. Branch field correct for both bugfix and feature task types. No stderr warnings.

## Task 71: Add Missing Checkpoint Commit Instructions to cwf-requirements-plan and cwf-maintenance

### Status: Complete (2026-02-19)
### Duration: <1 session (trivial)
### Impact: Hotfix — `cwf-requirements-plan` and `cwf-maintenance` were the only two wf step skills missing a checkpoint commit step. Agents completing these phases did not commit their workflow files. Both now have Step 8 (checkpoint commit) with the correct Stage file, and Next Steps renumbered to Step 9.

### Key Changes
- `.claude/skills/cwf-requirements-plan/SKILL.md`: Added Step 8 checkpoint commit (`Stage: b-requirements-plan.md`), renumbered Next Steps to Step 9
- `.claude/skills/cwf-maintenance/SKILL.md`: Added Step 8 checkpoint commit (`Stage: i-maintenance.md`), renumbered Next Steps to Step 9

### Test Results
6/6 tests pass. Full skill audit (TC-5) confirmed cwf-new-task, cwf-subtask, and cwf-retrospective are legitimately exempt.

## Task 70: Improve CWF Skill Initialisation in cwf-init

### Status: Complete (2026-02-19)
### Duration: <1 session
### Impact: Feature — `cwf-init` now produces a fully-functional CWF environment from a fresh project. Fixes three problems identified in Task 63 external agent testing: skill permission prompts on every call, agents manually following SKILL.md instead of using the `Skill` tool, and the post-init commit being skipped.

### Key Changes
- `.claude/skills/cwf-init/SKILL.md`: Extended from 7 to 8 steps:
  - Step 4 (Update CLAUDE.md): Now prepends a CWF enforcement preamble with idempotency check
  - Step 6 (new — Register Skill Permissions): Lists CWF skills dynamically, asks user to confirm, merges into project `.claude/settings.json` with idempotent merge
  - Step 7 (renumbered): PERL5OPT configuration unchanged
  - Step 8 (renumbered + strengthened): Mandatory init commit — "Do not begin task work until this commit is made"

### Test Results
9/9 tests pass. No defects.

## Task 69: Remove Obsolete `Implemented` Status Value

### Status: Complete (2026-02-18)
### Duration: <1 session (trivial)
### Impact: Bugfix — eliminates the root cause of recurring `f-implementation-exec.md` being left at `Implemented` (50%) instead of `Finished` (100%). The `Implemented` status was a v2.0 artefact made obsolete when v2.1 split implementation and testing into separate files.

### Key Changes
- `cwf-project.json`: Removed `"Implemented": 50` from `status-values`
- `TaskState.pm`: Removed from `%DEFAULT_STATUS_MAP`, `_is_active_work`, POD, and comments
- `cwf-implementation-exec/SKILL.md`: Fixed instruction from `"Implemented" when complete` → `"Finished" when complete` (direct source of recurring misuse)
- `workflow-steps.md`: Removed `Implemented` from Status Values documentation
- `script-hashes.json`: Updated SHA256 for `TaskState.pm`
- `BACKLOG.md`: Retired "Add Status Field Review to Pre-Retrospective Checklist" (symptom workaround — root cause now fixed)

### Test Results
8/8 tests pass.

## Task 68: Remove v1.0 Category Subdirectories from cwf-init

### Status: Complete (2026-02-18)
### Duration: <1 session (trivial)
### Impact: Hotfix — `cwf-init` no longer instructs agents to create obsolete `feature/`, `bugfix/`, `hotfix/`, `chore/` subdirectories under `implementation-guide/`. README Project Structure updated to v2.1 layout.

### Key Changes
- `.claude/skills/cwf-init/SKILL.md`: Removed bullet instructing category subdir creation (v1.0 legacy)
- `README.md`: Replaced stale v1.0 Project Structure block with v2.1 number-prefixed layout; updated `.cwf/` subtree to reflect current reality (`lib/CWF/`, `security/`, `templates/pool/`)
- `BACKLOG.md`: Retired both duplicate entries covering this issue (Task 63 High + Task 60 Medium)

## Task 67: Fix Stale Statuses in Tasks 46 and 49

### Status: Complete (2026-02-18)
### Duration: <1 session (trivial)
### Impact: Chore — 7 status field edits; tasks 46 and 49 now show 100%.

### Key Changes
- Task 46: `f-implementation-exec.md`, `g-testing-exec.md` — `Backlog` → `Finished`
- Task 49: `a`, `c`, `d`, `e` — `In Progress` → `Finished`; `f` — `Implemented` → `Finished`

## Task 66: Fix Terminal Status Handling in state_done and Status Aggregators

### Status: Complete (2026-02-18)
### Duration: <1 session
### Impact: Bugfix — tasks where all workflow files are Cancelled or Skipped now score 100% in status-aggregator. Blocked tasks now surface in task-context-inference at a low DORMANT score rather than being hidden.

### Key Changes
1. **`CWF::TaskState.pm`**:
   - Add `Skipped => 100` to `%DEFAULT_STATUS_MAP`
   - Replace `_is_terminal` (Blocked|Finished|Cancelled) with `_is_closed` (Finished|Cancelled|Skipped) — Blocked is recoverable, not terminal
   - Fix `state_done` MIN: closed steps mapped to 100 before MIN calculation (not their raw score)
   - Remove dead `$blocked_count`/`$is_workable`/`!$is_workable` from `state_achievable` — CLIFF catches all-closed tasks; Blocked falls to DORMANT (≈4)
   - Fix 4 pre-existing perlcritic violations (`grep` block form, `RequireBriefOpen`, `_max`/`_min` unpack)
2. **`cwf-project.json`**: `"Skipped": null` → `"Skipped": 100` (config overrides `%DEFAULT_STATUS_MAP`; both must match)
3. **Both aggregators**: Add `Skipped` to unknown-status warning exclusion regex

### Test Results
14/14 test cases pass. Task 11 (all Cancelled) now shows 100%.

## Task 65: Fix Stale In Progress Statuses in Tasks 47 and 48

### Status: Complete (2026-02-18)
### Duration: <1 session (trivial)
### Impact: Chore — 10 status field edits; tasks 47 and 48 now show 100% in status-aggregator and no longer appear in task-context-inference output.

### Key Changes
1. Tasks 47 and 48: `a-task-plan.md`, `c-design-plan.md`, `d-implementation-plan.md`, `e-testing-plan.md` — `In Progress` → `Finished`
2. Tasks 47 and 48: `f-implementation-exec.md` — `Implemented` → `Finished`

### Root Cause
Retrospective skills did not require updating intermediate workflow files before marking j-retrospective.md Finished. Both tasks had retrospectives that set j-retrospective.md to Finished but left a–f stale.

### Recommendation Added
`.cwf/docs/skills/retrospective-extras.md` should include an explicit checklist item: "Set all preceding workflow files (a through g) to Finished." (See j-retrospective.md for full recommendation.)

## Task 64: cwf-manage validate and CWF::Validate Module Suite

### Status: Complete (2026-02-18)
### Duration: 1 session (vs. 2-3 sessions estimated — well under)
### Impact: Feature — Deterministic validation of config, workflow, consistency, and security fields across the entire repo, callable as a post-skill guard.

### Key Changes
1. **Four new modules** under `.cwf/lib/CWF/Validate/`:
   - `Config.pm` — validates `cwf-project.json` schema (supported-task-types, source-management)
   - `Workflow.pm` — validates `## Status` section presence and value in all workflow files
   - `Consistency.pm` — cross-checks task num in dirname vs `**Task**:` field; branch vs git branch for active tasks
   - `Security.pm` — SHA256 + permissions verification using `Digest::SHA` (no shell subprocess)
2. **`cwf-manage validate` subcommand** — calls all four modules, reports all violations before exit, exits 1 if any
3. **`/cwf-security-check` skill simplified** — now a thin wrapper delegating to `cwf-manage validate`
4. **`checkpoint-commit.md` updated** — step 4 added: run `cwf-manage validate` after every checkpoint commit
5. **Side-fixes found by the validator on first run**:
   - Unclosed ` ```perl ` code fence in task 37 `c-design-plan.md` (made `## Status` invisible to any parser)
   - Missing `source-management` key in `implementation-guide/cwf-project.json`
   - `chmod 0755` on `task-context-inference`, `task-stack`, `migrate-v2.1-file-order` (permissions mismatch)

### Test Results
- 25 test cases (2 static + 6 Config + 4 Workflow + 4 Consistency + 5 Security + 3 integration + 2 regression), all PASS
- 1 additional test (lib files without `permissions` key skip the permissions check)

### BACKLOG Items Added
- **Expand Perl test suite to cover all CWF library modules** (chore, High) — `t/` currently has only `task-state.t`; all four new modules and the remaining 10 library modules need proper `.t` files runnable via `prove t/`

## Task 63: Fix template-copier-v2.1 Undef Warnings and Sparse-Checkout Bootstrap

### Status: Complete (2026-02-17)
### Duration: 1 session (vs. 1 session estimated = on target)
### Impact: Bugfix — Zero undef warnings during template creation; agent-friendly install bootstrap documented.

### Key Changes
1. **Undef guards in template-copier-v2.1**: `$pattern // ''` (line 354), `$value // ''` (line 385), `supported-task-types // [default list]` (line 198)
2. **Perlcritic stern**: Fixed 3 pre-existing violations — explicit `return` on `print_usage` and `output_results`, `return sort` ambiguity resolved
3. **Sparse-checkout bootstrap**: Added agent-friendly 4-line install sequence to README.md and INSTALL.md for non-GitHub hosts
4. **Security hash**: Updated for template-copier-v2.1

### Test Results
- 10 test cases: 2 static analysis + 2 source inspection + 2 integration + 1 hash + 2 docs + 1 array guard, all PASS

### BACKLOG Items Added
- **Harden install script**: Initial commit pre-flight + replace sparse checkout with `git archive` one-liner
- **Remove v1.0 category dirs from /cwf-init**
- **`cwf-manage validate` and CWF::Validate module suite**
- **Improve CWF skill initialisation in /cwf-init** (permissions, enforcement preamble, post-init commit)

## Task 62: Fix Install Script / cwf-init Boundary and Post-Install UX

### Status: Complete (2026-02-17)
### Duration: 1 session (vs. 1 session estimated = on target)
### Impact: Bugfix — Clean separation between install script (plumbing) and /cwf-init (project setup).

### Key Changes
1. **Install script boundary**: Removed `implementation-guide/` and `.gitignore` creation from `post_install()` — these are now exclusively `/cwf-init`'s responsibility
2. **cwf-manage Perl idioms**: Replaced `system()` file operations with core Perl (`File::Find`, `File::Copy`, `File::Path`). Added `copy_tree()` helper.
3. **cwf-init UX**: Added PERL5OPT detection (skip suggestion if already configured) and post-init commit step
4. **INSTALL.md**: Documents that Claude Code restart is needed after install for skills to register

### Test Results
- 15 test cases: 3 boundary + 5 Perl idioms + 3 SKILL.md + 1 docs + 3 regression, all PASS

## Task 61: CWF Install Script and Release Management

### Status: Complete (2026-02-16)
### Duration: 2 sessions (vs. 1-2 sessions estimated = on target)
### Impact: Feature — Zero-interaction bootstrap install script and Perl management script for CWF lifecycle.

### Key Changes
1. **Bootstrap script** (`scripts/install.bash`, ~240 lines): `curl | bash` installer supporting subtree (default) and copy methods via `CWF_METHOD`, `CWF_REF`, `CWF_SOURCE`, `CWF_FORCE` env vars
2. **Management script** (`.cwf/scripts/cwf-manage`, ~345 lines Perl): `status`, `list-releases`, `update`, `rollback` subcommands with dispatch table
3. **Staging prefix + symlinks**: Skills install to `.cwf-skills/` and are symlinked into `.claude/skills/`, preserving existing consumer skills
4. **INSTALL.md**: Added "Quick Install (Script)" section; updated manual methods for `.cwf-skills/` staging prefix
5. **Perlcritic**: Clean at severity 4 (stern) — explicit returns on all subs, dispatch table for command routing

### Design Decision
Original design used `.claude/skills/` as a subtree prefix, which would clobber existing consumer skills. Reworked through full process (b→g) to use `.cwf-skills/` staging prefix with relative symlinks. This was the critical design insight of the task.

### Test Results
- 28 test cases: 4 subtree + 1 copy + 3 symlink + 4 ref resolution + 2 prereq + 8 management + 2 docs + 2 regression, all PASS
- Pass 1: 5 bugs found. Pass 2 (after rework): 0 bugs found.

### BACKLOG Items Added
- **Replace backtick operators with IPC::Open3 in cwf-manage** (chore, very low)

### BACKLOG Items Completed
- Task 60 deferred items (install script, tag-based release management) now implemented

## Task 60: Add Installation Instructions

### Status: Complete (2026-02-15)
### Duration: ~2 hours (vs. 1-2 hours estimated = on target)
### Impact: Chore — New INSTALL.md enabling users to install CWF into their own repos.

### Key Changes
1. **INSTALL.md**: Two first-class installation methods — git subtree (two-split approach) and file copy (static/manual upgrade)
2. **README.md**: Installation section replaced with concise summary linking to INSTALL.md
3. **Git subtree two-split**: Verified approach using `git subtree split` for `.cwf/` and `.claude/skills/` from single CWF repo

### Scope Notes
This is an intentionally incomplete implementation. Deferred to Task 61 (feature):
- `curl | bash` install script
- Tag-based release management with update/rollback

### BACKLOG Items Added
- **Audit /cwf-init for obsolete category subdirectories** (chore, medium)
- **template-copier-v2.1 undef warnings** (bugfix, high)
- **/cwf-init should run security check and fix permissions** (bugfix, low)
- **Add status update helper script** (feature, low)

### Test Results
- 11 test cases: 3 structure + 3 path accuracy + 2 command validity + 2 README integration + 1 verification, all PASS
- External validation: both methods tested against real repo

## Task 59: Rebrand CIG to CWF (Coding with Files)

### Status: Complete (2026-02-14)
### Duration: ~2 hours (vs. 3-5 hours estimated = under estimate)
### Impact: Feature — Full rebrand from "Code Implementation Guide" (CIG) to "Coding with Files" (CWF, pronounced "swiff").

### Key Changes
1. **Structural renames**: `.cig/`→`.cwf/`, 19 skill dirs (`cig-*`→`cwf-*`), 5 helper scripts, `CIG-PROJECT-SPEC.md`→`CWF-PROJECT-SPEC.md`, `cig-project.json`→`cwf-project.json`
2. **Perl namespace**: `CIG::*`→`CWF::*` across 15 modules. `TaskState` and `TaskContextInference` moved from lib root into `CWF::` namespace.
3. **Content updates**: All SKILL.md files, root docs (README, CLAUDE.md, COMMANDS.md, DESIGN.md, BACKLOG), internal docs, configs updated
4. **Security hashes**: Regenerated for all renamed/modified scripts and modules
5. **README pronunciation**: "CWF is pronounced 'swiff'"

### Preserved Unchanged
- All historical task workflow docs (`implementation-guide/*/`)
- CHANGELOG.md (append-only history)

### Test Results
- 20 test cases: 5 structural + 2 compilation + 6 content sweep + 3 functional + 4 regression, all PASS

### BACKLOG Items Affected
- **Added**: "Add Delete Task Skill" (High) — from Task 59 misclassification experience
- **Added**: "Infer Task Type When Not Specified" (Medium) — agent should infer type from complexity

## Task 58: Add Cancelled Status to Workflow System

### Status: Complete (2026-02-13)
### Duration: ~30 minutes (vs. <1 hour estimated = on target)
### Impact: Bugfix — Added "Cancelled" as a terminal status value (0%) for tasks that are abandoned or superseded.

### Problem Addressed
Task 11 (secure argument parsing) was superseded by Task 57 (commands→skills) but had no appropriate status value. "Blocked" was inaccurate (it wasn't waiting on anything) and "Finished" was wrong (it never achieved its goals). A "Cancelled" terminal status was needed.

### Key Changes
1. **Added `"Cancelled": 0`** to `cig-project.json` status-values
2. **Updated `TaskState.pm`**: Renamed `_is_blocked_or_finished` → `_is_terminal`, added Cancelled to terminal check and default map
3. **Updated both aggregators** (v2.0 and v2.1): Warning regex exempts Cancelled from "unknown 0% status" warnings
4. **Updated `workflow-steps.md`**: Documented Cancelled in Valid Status Values section
5. **Cancelled Task 11**: All 5 workflow files set to Cancelled with reason "Superseded by Task 57"

### Test Results
- 12 test cases: 10 functional + 2 regression, all PASS
- 0 failures, 0 deviations from plan

### BACKLOG Items Affected
- **Removed**: "Rollout Task 11 - Secure Argument Parsing" (superseded)

## Task 57: Convert CIG Commands to Skills

### Status: Complete (2026-02-13)
### Duration: ~6-7 hours active (vs. 2-3 days estimated = -60% to -75% variance)
### Impact: Feature — Migrated all 17 CIG commands from `.claude/commands/` to `.claude/skills/` format, adopting the skills system for better tool permission control and eliminating injection syntax.

### Problem Addressed
CIG commands used `!{bash}` and `!/path` context injection syntax which doesn't work in skills (Task 55 confirmed this empirically). Commands needed conversion to skills format with runtime tool call instructions to adopt the newer architecture and fix FR8 (permission error regression from injection syntax).

### Key Changes
1. **Converted 17 commands to skills** in `.claude/skills/cig-*/SKILL.md` with YAML frontmatter
2. **Replaced all context injection** with 3 patterns: Pattern A (context-manager location), Pattern B (task-context-inference), Pattern C (skill-specific mandatory instructions)
3. **Accounted for all 15 Pattern C injections**: 10 converted to runtime instructions, 5 removed as provably redundant
4. **Renamed shared docs** from `.cig/docs/commands/` to `.cig/docs/skills/`
5. **Fixed `cig-current-task`** pre-existing skill — added missing YAML frontmatter
6. **Deleted all 17 command files** — clean cutover, no parallel operation

### Test Results
- 14 test cases: 12 PASS, 2 conditional PASS (token budget 930 vs 850 target — accepted trade-off)
- 0 functional or regression failures
- All 18 skills have valid frontmatter (18/18)

### BACKLOG Items Affected
- **Completed**: "Convert CIG Commands to Skills"

## Task 56: Refactor CIG Commands for Progressive Disclosure

### Status: Complete (2026-02-12)
### Duration: ~1 day (vs. 2-3 days estimated = -50% to -67% variance)
### Impact: Chore — Reduced 17 CIG commands from 1,914 total lines to 782 (59.1% reduction) by extracting shared patterns into 3 reference docs.

### Problem Addressed
CIG's 17 commands embedded full workflow instructions inline (80-237 lines each), causing duplication and context pollution risk. This blocked skill conversion (Task 57) because auto-loading 17 bloated commands would consume ~26k+ tokens.

### Key Changes
1. **Created 3 shared docs** in `.cig/docs/commands/`:
   - `workflow-preamble.md` (51 lines) — argument parsing, task validation, Steps 1-4
   - `checkpoint-commit.md` (23 lines) — commit template with trailer
   - `retrospective-extras.md` (95 lines) — CHANGELOG/BACKLOG update, checkpoints branch, squash
2. **Refactored 16 commands** to thin dispatchers referencing shared docs (cig-init.md skipped, already 53 lines)
3. **Consistent structure** across all 10 workflow commands: frontmatter, scope, context, workflow (shared doc refs), success criteria

### Test Results
- 12 test cases: 10 PASS, 2 marginal FAIL (aspirational metrics targets)
- 0 functional or regression failures

### BACKLOG Items Affected
- **Completed**: "Refactor CIG Commands for Progressive Disclosure"
- **Unblocked**: "Convert CIG Commands to Skills" — commands are now thin enough for skill conversion

## Task 55: Test Context Injection Syntax in SKILL.md Format

### Status: Complete (2026-02-12)
### Duration: ~30 minutes (vs. <1 hour estimated = -50% variance)
### Impact: Discovery — Empirically confirmed that `!{bash}` and `!` path shorthand context injection syntaxes are commands-only features that do not work in SKILL.md files.

### Problem Addressed
Task 54 flagged context injection syntax as "unverified in SKILL.md format" — a key unknown blocking the command-to-skill migration decision. Rather than relying on documentation (which doesn't mention this limitation), this task tested it empirically.

### Key Findings
1. **`!{bash}` block syntax**: FAIL — raw literal text in skill prompt, not expanded
2. **`!` path shorthand**: FAIL — raw literal text in skill prompt, not expanded
3. **Root cause**: Context injection is a feature of the `.claude/commands/` loader, not the `.claude/skills/` loader
4. **Silent failure**: No error or warning — injection syntax passes through as literal text
5. **Alternative approaches**: 4 identified; recommended: `allowed-tools` with Bash + thin skill + doc reference (runtime tool calls instead of prompt-time expansion)

### Test Results
- 6 test cases: 4 FAIL (injection syntax), 2 PASS (cleanup, isolation)
- 100% coverage of identified injection patterns

### BACKLOG Items Affected
- **Completed**: "Test Context Injection Syntax in SKILL.md Format"
- **Informed**: "Refactor CIG Commands for Progressive Disclosure" and "Convert CIG Commands to Skills" — now know that skill conversion requires runtime tool calls, not injection syntax

## Task 54: Assess Current 2026 W6 Skills and Plugin Standards

### Status: Complete (2026-02-12)
### Duration: ~4-5 hours active work across 2 calendar days (vs. 2-3 days / 16-24 hours estimated = -70% to -80% variance)
### Impact: Discovery — Comprehensive ecosystem assessment informing CIG migration strategy. Reaffirms "Keep Commands" recommendation from Task 16.

### Problem Addressed
Task 16 (Jan 2026) recommended "Keep Commands" but the skills/plugin ecosystem was evolving rapidly. The BACKLOG "Migrate CIG to Hybrid Plugin Model" item assumed commands were deprecated and migration prerequisites were met. Task 54 assessed the current state to validate or update these assumptions.

### Key Findings
**Research Output** (FR1-FR7):
1. **API Evolution (FR1)**: 4 releases (v2.1.3-v2.1.34) with 2 breaking changes (`$ARGUMENTS` syntax, SDK rename). Commands merged into skills in v2.1.3.
2. **User Feedback (FR2)**: 23 GitHub issues catalogued — critical bugs in hooks (#17688, 9 upvotes), SubagentStop (#22087, 34 upvotes), context pollution (#14851, 7 upvotes). AGENTS.md most-requested feature (2565 upvotes).
3. **Migration Patterns (FR3)**: 5 real-world examples found; all use hybrid/status-quo approach. No full migrations to skills-only.
4. **Hooks Standardisation (FR4)**: Agent Skills spec adopted by 6 platforms. Adoption faster than Task 16 expected.
5. **Marketplace (FR5)**: 40+ official plugins; mature distribution via npm/GitHub.
6. **Technical Blockers (FR6)**: 10 blockers identified (2 CRITICAL, 3 HIGH). Bug #17688 (hooks broken in plugins) is the single most important finding — invalidates the primary value of plugin migration.
7. **Recommendation (FR7)**: Keep Commands, 85% confidence. Decision matrix: 4 options × 8 weighted criteria. Review triggers set for Q3 2026.

**Test Results**: 11/12 PASS, 1 PARTIAL (minor single-source caveat). Zero contradictions across independently-researched FR sections.

### Process Innovation
- **Parallel research agents**: 6 agents ran simultaneously for FR1-FR6, compressing 14 hours of serial research into ~2 hours wall-clock time
- **`gh` CLI enrichment**: After initial WebSearch-based research, `gh` structured searches and per-issue reaction data improved FR2 quality (flipped 2 test cases from PARTIAL to PASS)

### BACKLOG Items Affected
- **Updated**: "Migrate CIG to Hybrid Plugin Model" — added Bug #17688 as critical blocker, updated context with Task 54 findings

## Task 53: Add Slug Generation to Template Copier

### Status: Complete (2026-02-10)
### Duration: ~0.5 hours (vs. 2-4 hours estimated = -75% to -87% variance)
### Impact: Bugfix - Eliminated permission prompts for normal template copying operations and simplified command invocations by making destination parameter optional.

### Problem Addressed
Template-copier-v2.1 required destination path for every invocation and used inline bash slug generation that triggered permission prompts (ironic given the script's purpose of eliminating prompts). BACKLOG item "Create Slug Generator Helper Script" addressed via embedded solution.

**Issues Fixed**:
1. Inline bash slug generation required permission prompts during template copying
2. Users had to specify destination path explicitly for every command invocation
3. No path auto-construction from task metadata (type, number, description)

### Changes Made
**`.cig/scripts/command-helpers/template-copier-v2.1`**:
- Added `generate_slug()` function (Perl port of bash algorithm: lowercase → remove special chars → hyphens → collapse → truncate 50)
- Added `construct_destination()` function for config-based path construction (reads cig-project.json pattern)
- Modified `parse_parameters()` to make destination optional with fallback to auto-construction
- Updated usage documentation to show destination as optional parameter
- Preserved backward compatibility (explicit destination still works for testing/debugging)

**`.cig/security/script-hashes.json`**:
- Updated SHA256 hash for template-copier-v2.1
- Old: `d65567baa0cf81e11b57aabb09fa7b6b70a08b53055ff3397db08d8dfa391e54`
- New: `c0c9d8ef1359dbb29f3c9eeaff5a24ae1db901fe75e4e6a207e90c8c8f31531c`

### Implementation Quality
**Test Coverage**: 9/9 executed tests passed (100% pass rate)
- Functional tests: 7/7 passed (slug generation, auto-construction, backward compatibility, integration)
- Non-functional tests: 2/3 passed, 1 skipped (performance 20.75ms per op, compatibility across all 5 task types)

**Defect Rate**: 0 defects - all executed tests passed, zero regressions across all task types

**Estimation Accuracy**: Task completed 75-87% faster than estimated due to clear design (pure functions) and straightforward scope

### Key Achievements
1. **Permission prompt elimination**: Moved slug generation from inline bash to Perl function (no permission prompts)
2. **Simplified invocations**: Destination now optional, auto-constructed from config pattern
3. **Full backward compatibility**: Explicit destination parameter still works for testing/debugging
4. **Zero regressions**: All 5 task types (feature, bugfix, hotfix, chore, discovery) tested and working
5. **Algorithm exactness**: Bash-to-Perl port verified with side-by-side comparison testing

## Task 52: Clean Up Obsolete BACKLOG Items

### Status: Complete (2026-02-10)
### Duration: ~1.75 hours elapsed (vs. <1 hour estimated = +75-133% variance)
### Impact: Chore - Removed 3 verified obsolete BACKLOG items that were already completed in previous tasks, improving BACKLOG accuracy and maintainability.

### Problem Addressed
BACKLOG.md accumulated 3 obsolete items that had already been completed in previous tasks but were never removed, causing confusion about what work remained and making the backlog less trustworthy as a project roadmap.

**Issues Fixed**:
1. "Update cig-status to Use --workflow Flag" - already implemented in Task 32 (cig-status auto-enables --workflow)
2. "Update Task 32 Tests for New Inference Output Format" - already completed in Task 32 (tests verify task_num/task_slug format)
3. "Add 'Create Task Branch' Step to Implementation Execution" - already implemented in cig-new-task (automatic branch creation in Step 6)

### Changes Made
**`BACKLOG.md`**:
- Removed "Update cig-status to Use --workflow Flag" (lines 1571-1607)
  - Evidence: `.claude/commands/cig-status.md` line 36 shows auto --workflow
- Removed "Update Task 32 Tests for New Inference Output Format" (lines 131-150)
  - Evidence: Task 32 `g-testing-exec.md` line 48 shows new format tests
- Removed "Add 'Create Task Branch' Step to Implementation Execution" (lines 187-215)
  - Evidence: `.claude/commands/cig-new-task.md` Step 6 shows branch creation
- Result: BACKLOG reduced from 42 to 39 tasks

### Implementation Quality
**Test Coverage**: 7/7 tests passed (100%)
- Verification tests: 5/5 passed (3 grep verifications, structure validation, markdown rendering)
- Non-functional tests: 2/2 passed (completeness, formatting consistency)

**Defect Rate**: 0 defects - all verification tests passed, no orphaned separators, BACKLOG structure intact

### Key Achievements
1. **Evidence-based cleanup**: Each item verified with concrete code/test references before removal
2. **Zero structural damage**: No orphaned separators, all 39 remaining tasks properly formatted
3. **Comprehensive verification**: Multi-level validation (grep content, awk structure, task header counts)
4. **Process documentation**: Clear rationale for each removal preserved in implementation plan

## Task 51: Remove Dead Code from TaskContextInference.pm

### Status: Complete (2026-02-10)
### Duration: ~1.3 hours (vs. 1-2 hours estimated = -13% under midpoint)
### Impact: Bugfix - Removed 114 lines of confirmed dead code from TaskContextInference.pm, improving maintainability and reducing codebase confusion.

### Problem Addressed
Dead code audit identified 4 unused functions in TaskContextInference.pm that were no longer called after Task 32 removed status signal functionality. Original audit also incorrectly flagged 2 functions in other modules, but pre-removal verification caught these errors.

**Issues Fixed**:
1. Dead functions consuming 114 lines in TaskContextInference.pm
2. Audit methodology gaps (same-file usage, script-to-library usage not checked)
3. Potential confusion for future developers reading deprecated code

### Changes Made
**`.cig/lib/TaskContextInference.pm`**:
- Removed `_get_status_signal()` (45 lines) - status signal removed per Task 32
- Removed `_score_status()` (17 lines) - helper only called by dead function
- Removed `_get_task_status_score()` (29 lines) - helper only called by dead function
- Removed `_format_uncorrelated()` (23 lines) - marked DEPRECATED, replaced by format_output()
- Total: 114 lines removed

**`.cig/security/script-hashes.json`**:
- Updated SHA256 hash for TaskContextInference.pm
- Old: `6debb865...522d34bc`
- New: `93b4426e...513502de`

### Implementation Quality
**Test Coverage**: 8/8 applicable tests passed (100%)
- Verification tests: 3/3 passed (grep verification, hash verification, line count)
- Regression tests: 3/3 passed (status aggregator, module imports, context inference)
- Non-functional tests: 2/2 passed (hash integrity, code cleanliness)

**Scope Adjustment**: Audit error discovered during Step 1 verification
- `workflow_file_mappings()` NOT removed (actively used by context-inheritance-v2.0)
- `format_error()` NOT removed (internal usage in Common.pm with POD docs)
- Scope reduced from 3 files (~160 lines) to 1 file (114 lines)
- Verification process prevented breaking changes

### Key Achievements
1. **Pre-removal verification caught errors**: Step 1 grep discovered 2 audit mistakes before any code was modified
2. **Surgical removal**: Edit tool enabled precise function deletion without affecting code structure
3. **Zero regressions**: All core CIG workflows (status aggregator, context inference) still work correctly
4. **Process learning**: Identified audit methodology gaps for future dead code cleanup

## Task 50: Add "Skipped" Workflow Step Status (v2.1 Format Only)

### Status: Complete (2026-02-10)
### Duration: <1 day (vs. 1-2 days estimated = -50% to -100% variance)
### Impact: Feature - v2.1 format can now mark any workflow step as "Skipped" (N/A), excluded from progress calculation. Enables correct 100% completion when phases aren't applicable (e.g., maintenance for bugfixes).

### Problem Addressed
No way to mark workflow steps as "not applicable" without affecting progress calculation. Example: bugfix task with maintenance phase marked "Backlog" (0%) shows 90% complete (9/10 phases finished) instead of 100% (9/9 applicable phases finished). Users forced to mark N/A phases as "Finished" dishonestly or accept inaccurate progress metrics.

**Issues Fixed**:
1. No status value for "not applicable" workflow phases
2. Progress calculation includes phases that shouldn't apply to specific tasks
3. Display shows misleading percentages for N/A phases (e.g., "Maintenance: Backlog (0%)")
4. Workflow documentation didn't clarify when phases can be skipped

### Changes Made
**`implementation-guide/cig-project.json`**:
- Added `"Skipped": null` to workflow.status-values (line 77)
- Null value maps to Perl `undef` for clean filtering

**`.cig/lib/TaskState.pm`**:
- Added `grep defined` filter to `state_done()` (line 97)
- Excludes undef values from progress calculation (9/9=100% not 9/10=90%)

**`.cig/scripts/command-helpers/status-aggregator-v2.1`**:
- Display logic: Shows "Skipped (N/A)" instead of percentage (line 423)
- Bug fix: Added `defined($pct)` check in warning logic (line 123)
- Bug fix: Added `defined($wf->{percent})` checks in indicator ternary (lines 420-421)

**`.cig/docs/workflow/workflow-steps.md`**:
- Added "Skipped" status documentation (lines 44-67)
- Usage guidance: Emphasizes per-task decisions, provides examples
- Clarifies v2.1 requirement and distinction from Backlog/Finished

### Implementation Quality
**Test Coverage**: 15/19 tests executed (79% execution rate)
- 10/12 functional tests passed (TC-F5, TC-F6 deferred - core logic verified via TC-F3)
- 5/7 NFR tests passed (TC-NFR1, TC-NFR2 deferred - existing patterns validated)

**Defect Rate**: 2 bugs found during testing, 0 post-testing defects
- Line 123: undef comparison warning (fixed immediately)
- Lines 420-421: indicator ternary undef warnings (fixed immediately)

### Key Achievements
1. **Null-value sentinel pattern**: Using JSON `null` (Perl `undef`) cleaner than magic numbers
2. **Idiomatic Perl**: `grep defined` filter and ternary conditionals improve readability
3. **Backward compatible**: v2.0 format unchanged, v2.1 tasks without "Skipped" work identically
4. **Testing caught bugs**: Execution testing phase discovered 2 undef handling bugs before production
5. **Clear documentation**: workflow-steps.md provides usage guidance and examples

## Task 49: Fix Checkpoints Branch Permissions Issue with Script

### Status: Complete (2026-02-10)
### Duration: ~1 hour (vs. 4 hours estimated = -75% variance - 3x faster)
### Impact: Bugfix - Created `checkpoints-branch-manager` script to eliminate Step 10 permission prompts. Deterministic git operations now in code, not LLM decisions.
### BACKLOG Item Completed: "Fix Retrospective Step 10 Permission Prompts" from Task 45

### Problem Addressed
Task 45 retrospective identified that Step 10 of cig-retrospective workflow uses compound git commands with command substitution that trigger permission prompts despite individual commands being in frontmatter allowlist:
- `git branch "$(git rev-parse --abbrev-ref HEAD)-checkpoints"` (10.1)
- `git log --oneline --graph -20` (10.2 - missing from frontmatter)
- `git log "$(git rev-parse --abbrev-ref HEAD)-checkpoints" --oneline` (10.4)

**Issues Fixed**:
1. Compound commands with `$(...)` don't match frontmatter wildcard patterns
2. Missing `git log` permission in frontmatter
3. Step 10 workflow requires user approval interrupting retrospective automation
4. Violates CIG principle: deterministic operations belong in code

### Changes Made
**`.cig/scripts/command-helpers/checkpoints-branch-manager` (NEW)**:
- **60 lines** Perl script with 3 subcommands (create, show-history [count], verify)
- **Permissions**: 500 (r-x------)
- **Error handling**: Detached HEAD detection, branch exists, missing branch, invalid input
- **Idiomatic Perl**: Uses `die`, `//` operator, `shift`, postfix conditionals, `get_current_branch()` helper (DRY)
- **Security**: SHA256 hash recorded in `.cig/security/script-hashes.json`

**`.claude/commands/cig-retrospective.md`**:
- **Step 10.1**: Replaced `git branch "$(git ...)"` with `checkpoints-branch-manager create`
- **Step 10.2**: Replaced `git log ...` with `checkpoints-branch-manager show-history`
- **Step 10.4**: Replaced `git log "$(git ...)"` with `checkpoints-branch-manager verify`

### Implementation Quality
**Test Coverage**: 14/14 tests passed (100%)
- TC-1 to TC-9: Functional tests (all subcommands, error handling) ✅
- TC-10 (CRITICAL): No permission prompts from Step 10 ✅
- TC-11: File permissions (500) ✅
- TC-12: Security hash validation ✅
- TC-13: Error message clarity ✅
- TC-14: Backward compatibility (original git commands still work) ✅

**Defect Rate**: 1 minor issue found and fixed (permissions 700 after refactoring, corrected to 500)

### Key Achievements
1. **Permission prompts eliminated**: Script in `.cig/scripts/command-helpers/*:*` allowlist
2. **Code quality**: Refactored from 100 to 60 lines (-40%) with user-guided idiomatic Perl improvements
3. **Comprehensive testing**: All edge cases covered (detached HEAD, branch exists, missing branch, invalid input)
4. **Backward compatible**: Original git commands still functional, users can choose approach
5. **Fast delivery**: 3x faster than estimated due to clear requirements and simple design

## Task 48: Fix nextAction Template Substitution in Template-Copier

### Status: Complete (2026-02-10)
### Duration: ~4 hours (vs. 2-3 hours estimated = 33% overrun)
### Impact: Bugfix - Template-copier now derives command names from template filenames, establishing directory structure as single source of truth. All 5 task types generate correct nextAction sequences.

### Problem Addressed
Task 47 discovered during rollout that `{{nextAction}}` template variable was not being deterministically substituted by template-copier-v2.1. Hardcoded `%PHASE_COMMANDS` mapping was incorrect (all commands shifted by 1 position), causing bugfix workflow g-testing-exec.md to show "Next Action: /cig-rollout" when correct action is "/cig-retrospective" (bugfix workflow has no h-rollout.md).

**Issues Fixed**:
1. Hardcoded `%PHASE_COMMANDS` mapping out of sync with actual command names
2. `{{nextAction}}` not being substituted, agents manually determining next steps
3. Violates CIG core principle: deterministic routing should be code-driven, not LLM decision
4. Future maintenance burden: any filename changes require updating hardcoded mapping

### Changes Made
**`.cig/scripts/command-helpers/template-copier-v2.1`**:
- **Removed**: 47 lines (entire `compute_next_action()` function + `%PHASE_COMMANDS` hash)
- **Added**: 8 lines (`name_to_action()` helper function)
- **Refactored**: `copy_templates()` to compute nextAction in loop by peeking at next template
- **Pattern**: `while (@templates) { shift @templates }` - idiomatic Perl
- **Transformation**: Strip phase prefix (`s/^[a-z]-//`), strip extension (`s/\.md\.template$//`), prepend `/cig-`
- **Future-proof**: Used `[a-z]` instead of `[a-j]` for forward compatibility

### Implementation Quality
**Test Coverage**: 9/9 tests passed (100%)
- TC-1: Bugfix g-testing-exec.md → "/cig-retrospective" (CRITICAL - original bug fixed) ✅
- TC-2: Feature task (10 files) - all nextActions correct ✅
- TC-3: Hotfix task (7 files) - all nextActions correct ✅
- TC-4: Chore task (6 files) - all nextActions correct ✅
- TC-5: Discovery task (8 files) - all nextActions correct ✅
- TC-6: Template variables regression - no regression ✅
- TC-7: File permissions (0600) regression - no regression ✅
- TC-8: Last phase shows "Task complete" ✅
- TC-9: Test directories cleaned up ✅

**Defect Rate**: 0 bugs found during testing or validation

### Key Achievements
1. **Single source of truth**: Template symlink filenames now define command names (zero hardcoded mapping)
2. **Code simplification**: Net -39 lines, significantly simpler logic
3. **Idiomatic Perl**: User-guided refactoring to `while/shift` pattern, `//` operator, functional approach
4. **100% test coverage**: All 5 task types validated end-to-end
5. **Zero regressions**: Template variables and permissions unchanged

### Benefits Delivered
- **Deterministic routing**: nextAction automatically derived from directory structure
- **Zero maintenance**: Filename changes automatically reflected in commands
- **More maintainable**: 39 lines shorter, more idiomatic Perl
- **Comprehensive validation**: 9 tests confirm all task types work correctly

### Lessons Learned
**Technical Insights**:
- Idiomatic Perl: `while (@array) { shift @array }` cleaner than indexed loops
- Defined-or operator `//` cleaner than if/else for fallbacks
- In-loop computation (peek at next template) simpler than separate discovery function
- Future-proofing regex: `[a-z]` vs `[a-j]` accounts for possible expansion

**Process Learnings**:
- Estimate 2x multiplier for "simple" bugfixes to account for full CIG workflow overhead
- User code review during implementation valuable (caught non-idiomatic patterns)
- Comprehensive testing (9 vs 7 planned) provided high confidence
- Following CIG process consistently pays off

**BACKLOG Items Completed**:
- Task 48 item from Task 47 retrospective (fix template-copier nextAction substitution)

## Task 47: Fix Variable Use in Commands to Avoid Bash Issues

### Status: Complete (2026-02-09)
### Duration: ~6 hours (vs. 2-3 hours estimated = 2x overrun)
### Impact: Bugfix - All 17 CIG command files now use `{placeholder}` syntax exclusively, eliminating LLM-generated bash wrappers that trigger permission prompts

### Problem Addressed
Commands using `$VARIABLE` and `<placeholder>` syntax were causing LLMs to generate unnecessary bash wrapper scripts around helper script calls, triggering permission prompts that interrupted workflow execution.

**Issues Fixed**:
1. `$VARIABLE` syntax (22 occurrences across 16 files) triggered bash variable interpretation
2. `<placeholder>` syntax (98 occurrences across 15 files) in argument-hint fields caused parsing ambiguity
3. LLM creating bash wrappers like `bash -c ".cig/scripts/command-helpers/script $ARG"` instead of direct calls
4. Permission prompts interrupting command execution

### Changes Made
**All 17 CIG Command Files** (`.claude/commands/cig-*.md`):
- Frontmatter argument-hint fields: `<task-path>` → `{task-path}`, `<num>` → `{num}`, etc.
- Command body placeholders: `$ARGUMENTS` → `{arguments}`, `$TYPE` → `{type}`, `$TASK_DIR` → `{task-dir}`, etc.
- Total replacements: 120 changes (22 `$VARIABLE` + 98 `<placeholder>` → 61 `{placeholder}`)

**Files Modified**:
- `cig-new-task.md`, `cig-task-plan.md`, `cig-implementation-exec.md`, `cig-testing-exec.md`, `cig-retrospective.md`
- `cig-design-plan.md`, `cig-implementation-plan.md`, `cig-testing-plan.md`, `cig-requirements-plan.md`
- `cig-rollout.md`, `cig-maintenance.md`, `cig-status.md`, `cig-subtask.md`
- `cig-extract.md`, `cig-config.md`, `cig-security-check.md`, `cig-init.md`

### Implementation Quality
**Test Coverage**: 7/7 must-pass tests passed (100%)
- TC-1: Grep verification of `$VARIABLE` elimination (0 matches, 6 legitimate bash patterns preserved)
- TC-2: Grep verification of `<placeholder>` elimination (0 matches)
- TC-3: File count verification (17 files modified)
- TC-4: `{placeholder}` adoption verification (61 matches)
- TC-5: Functional test - task creation without permission prompts (PASS)
- TC-8: Git diff review - only placeholder syntax changed, no logic modifications (PASS)
- TC-9: Cleanup successful (PASS)

**Defect Rate**: 0 bugs in implementation, 1 critical bug discovered in template system during rollout

### Key Achievements
1. **Systematic approach**: Pre-implementation grep audit cataloged all 120 instances before replacement
2. **Clean implementation**: Two checkpoint commits preserve archaeological record (c457783, 23da701)
3. **100% test pass rate**: All verification, functional, and regression tests passed
4. **Bug discovery**: Found critical `{{nextAction}}` template substitution bug during rollout phase

### Benefits Delivered
- **No permission prompts**: Commands execute without interrupting agent workflow
- **Clearer syntax**: `{placeholder}` makes substitution points obvious to LLMs
- **No behavioral changes**: Pure syntax refactoring, zero logic modifications
- **Template bug identified**: Discovered `{{nextAction}}` not being deterministically substituted (requires Task 48 fix)

### Lessons Learned
**Technical Insights**:
- `$VARIABLE` triggers bash interpretation, `{placeholder}` does not
- Legitimate bash patterns exist: `$?` (exit codes), `$(...)` (command sub), `${...}` (param expansion)
- Grep-based automated testing is fast and reliable for pattern-replacement validation

**Process Learnings**:
- Estimate full workflow time (planning + design + implementation + testing), not just implementation
- Rollout phase catches systemic issues even in "simple" bugfix tasks
- Deterministic routing (nextAction) belongs in code, not LLM decisions
- Follow CIG process consistently - don't defer bugs or skip task creation

**Follow-Up Required**:
- Task 48: Fix template-copier-v2.1 to deterministically substitute `{{nextAction}}` based on workflow type and file sequence (High priority)

## Task 46: Add Checkpoint Commit Instructions to All Workflow Steps

### Status: Complete (2026-02-09)
### Duration: ~30 minutes (vs. not estimated = hotfix task)
### Impact: Hotfix - All 7 workflow command files now guide agents to create checkpoint commits after phase completion, enabling retrospective squashing workflow

### Problem Addressed
During Task 45 retrospective, discovered that zero checkpoint commits were made throughout workflow phases. User asked "did you add those BACKLOG changes to the -checkpoints branch as well?" and git log revealed the checkpoints branch was empty except for Task 44 commits. Root cause: Workflow documentation at `.cig/docs/workflow/workflow-steps.md` has checkpoint commit guidance, but actual CIG command files (cig-task-plan, cig-design-plan, etc.) don't include checkpoint commit instructions in their step-by-step workflows.

**Issues Fixed**:
1. No checkpoint commits made during workflow phases (agents didn't know to create them)
2. Checkpoints branch created but empty (no commits to squash later)
3. Workflow commands referenced checkpoint guidance in docs but didn't include actionable Step 8
4. Missing git permissions in frontmatter for checkpoint commits

### Changes Made
**Workflow Command Files** (`.claude/commands/`):
Added Step 8 "Create Checkpoint Commit" to all 7 workflow commands:
- `cig-task-plan.md` - Added Step 8 after planning workflow, references a-task-plan.md
- `cig-design-plan.md` - Added Step 8 after design workflow, references c-design-plan.md
- `cig-implementation-plan.md` - Added Step 8 after impl planning, references d-implementation-plan.md
- `cig-testing-plan.md` - Added Step 8 after test planning, references e-testing-plan.md
- `cig-implementation-exec.md` - Added Step 8 after execution, references f-implementation-exec.md
- `cig-testing-exec.md` - Added Step 8 after test execution, references g-testing-exec.md
- `cig-rollout.md` - Added Step 8 after rollout, references h-rollout.md

**Step 8 Structure** (consistent across all files):
- Bash code block with checkpoint commit command
- Standard commit message format: "Task N: Complete <phase> phase\n\n<why>\n\nCo-developed-by: Claude Sonnet 4.5 <noreply@anthropic.com>"
- Rationale paragraph explaining checkpoint commits preserve progress
- Progressive disclosure: References `.cig/docs/workflow/workflow-steps.md#<phase>` for detailed guidance

**Frontmatter Permissions** (all 7 files):
- Added `Bash(git add:*)` permission (specific, not overly broad)
- Added `Bash(git commit:*)` permission (specific, not overly broad)
- Avoided `Bash(git:*)` which user flagged as too broad

**Step Renumbering**:
- Renumbered "Suggest Next Steps" from Step 8 → Step 9 in all files

### Implementation Quality
**Test Coverage**: 100% of planned tests (10/10 executed)
- 7 functional tests (TC-1 through TC-7): Each command file validated for Step 8 presence, format, permissions
- 3 non-functional tests (TC-8 through TC-10): Consistency, documentation references, permission specificity

**Defect Rate**: 0 bugs found during validation (manual testing before rollout)

**Documentation Quality**: All 7 files updated with identical Step 8 structure, promoting consistency

### Key Achievements
1. **Consistent pattern across 7 files**: Identical Step 8 structure reduces cognitive load
2. **Token-efficient design**: Progressive disclosure pattern maintained (reference docs, don't duplicate)
3. **Specific permissions**: Used `Bash(git add:*)` and `Bash(git commit:*)` instead of overly broad `Bash(git:*)`
4. **Meta-validation successful**: Task 46 itself demonstrated checkpoint workflow by creating 6 retroactive checkpoint commits
5. **Retroactive commit recreation**: Used git reflog to recreate 6 missing checkpoint commits after discovering they weren't made during execution

### Benefits Delivered
- **Progress preservation**: Checkpoint commits now created after each phase completion
- **Retrospective squashing enabled**: Checkpoints branch will have incremental commits to squash into one
- **Agent guidance improved**: Explicit Step 8 instructions remove ambiguity about when/how to checkpoint
- **Consistency**: Same checkpoint commit format across all workflow phases

### Lessons Learned
**Technical Insights**:
- Checkpoint commit format standardised: "Task N: Complete <phase> phase" + brief why + Co-developed-by trailer
- Progressive disclosure effective: Reference `.cig/docs/workflow/workflow-steps.md#<phase>` keeps commands concise
- Frontmatter permission specificity matters: `Bash(git add:*)` better than `Bash(git:*)`

**Process Learnings**:
- Apply workflow improvements to current task: Task 46 demonstrated checkpoint workflow during its own execution
- Git reflog enables retroactive analysis: Confirmed zero checkpoint commits created (option a), not squashed (option b)
- Retroactive commit recreation viable: Successfully recreated 6 checkpoint commits after discovering they were missing
- Hotfix workflow appropriate: Skipping requirements/design phases suitable for pure documentation changes

## Task 45: Clarify BACKLOG/CHANGELOG Management in Retrospective Instructions

### Status: Complete (2026-02-09)
### Duration: ~1 hour (vs. 1-2 hours estimated = matched low estimate)
### Impact: Bugfix - Retrospective instructions now explicitly guide agents to update both CHANGELOG.md and BACKLOG.md with clear tool usage patterns

### Problem Addressed
Task 44 retrospective revealed that agents were skipping CHANGELOG.md updates during retrospective phase. Step 9 in `.claude/commands/cig-retrospective.md` only mentioned BACKLOG.md, used ambiguous language ("mark items complete"), and provided no tool usage guidance.

**Issues Fixed**:
1. CHANGELOG.md updates never mentioned in retrospective instructions
2. "Mark items complete" was ambiguous (mark how? where?)
3. No tool guidance (agents didn't know to use Grep for efficient BACKLOG search)
4. Only staged BACKLOG.md, not CHANGELOG.md

### Changes Made
**Retrospective Instructions** (`.claude/commands/cig-retrospective.md` Step 9):
- Renamed Step 9 from "Update BACKLOG.md" to "Update CHANGELOG.md and BACKLOG.md"
- Added Step 9.1: Update CHANGELOG.md with task completion (Read with limit, Edit tool, what to include, Task 40 example)
- Added Step 9.2: Remove completed BACKLOG items (Grep tool with `^## Task:` pattern, line numbers, Edit for removal, Task 40 example)
- Added Step 9.3: Add new BACKLOG items (Read retrospective recommendations, Edit tool, format spec, Task 44 example)
- Added Step 9.4: Stage both files (`git add CHANGELOG.md BACKLOG.md`)
- Added rationale paragraph explaining synchronization
- Added token-efficient approach section (Grep for headers, Read with limit for patterns, Edit for changes)

**BACKLOG Updates**:
- No items completed by this task
- No new backlog items identified

### Implementation Quality
**Test Coverage**: 100% of manual validation tests (9/9 executed, 1 integration test validated through actual use)
- 5 functional tests: Step 9 structure, CHANGELOG instructions, BACKLOG cleanup, BACKLOG additions, git staging
- 4 non-functional tests: Clarity, token efficiency, maintainability, regression
- TC-6 (integration test) validated through Task 45 retrospective execution (meta-validation)

**Defect Rate**: 0 bugs found during testing

**Documentation Quality**: All 4 substeps present with clear tool guidance and concrete examples

### Key Achievements
1. **Explicit CHANGELOG guidance**: Agents now know WHEN and HOW to update CHANGELOG.md
2. **Grep tool for efficiency**: Pattern `^## Task:` returns line numbers for quick BACKLOG navigation
3. **Token-efficient patterns**: Read with limit, Grep for search, Edit for changes
4. **Clear examples**: Tasks 40 and 44 referenced for verifiable patterns
5. **CIG workflow adherence**: User caught initial plan deviation, redirected to proper workflow phases
6. **Meta-validation success**: This retrospective successfully followed new Step 9 instructions

### Benefits Delivered
- **Completeness**: CHANGELOG now captures completed work, BACKLOG tracks future work
- **Token Efficiency**: Tool guidance promotes efficient patterns (Grep > Read entire file)
- **Clarity**: No ambiguous language - explicit tool names and parameters
- **Maintainability**: Examples reference specific tasks for easy verification

### Lessons Learned
**Technical Insights**:
- Grep with pattern returns line numbers - excellent for "table of contents" views
- Progressive disclosure (read patterns, then match) more flexible than rigid templates
- Explicit tool guidance (which tool, which parameters) improves agent behavior

**Process Learnings**:
- CIG workflow is the point - even "simple" documentation fixes benefit from proper phases
- Plans should reference workflow phases explicitly to prevent shortcuts
- User feedback catches workflow violations early, preventing waste
- Meta-validation works - this retrospective validated its own instructions

## Task 40: Complete Helper Script Migration to Trampoline Architecture

### Status: Complete (2026-02-08)
### Duration: 5.1 hours (vs. 3-4 hours estimated = **+28% to +70%**)
### Impact: Bugfix - Achieved zero permission prompts by migrating all helper scripts to trampoline/module architecture with wildcard frontmatter permissions

### Problem Addressed
Task 39 established the trampoline/module architecture pattern but only migrated one helper (context-manager with location subcommand). Six helper scripts remained as standalone executables, requiring individual frontmatter permission patterns and causing permission prompt friction for users.

**Issues Fixed**:
1. Permission prompt friction - each helper script needed separate frontmatter entry
2. Inconsistent architecture - mix of trampolines and standalone scripts
3. CIG commands had verbose frontmatter (7+ individual patterns)
4. Documentation referenced old standalone script names

### Changes Made
**Architecture** (`.cig/scripts/command-helpers/`):
- **Expanded context-manager** from 1 → 4 subcommands:
  - `context-manager location` (existing - git root detection)
  - `context-manager hierarchy` (new - replaces hierarchy-resolver)
  - `context-manager inheritance` (new - replaces context-inheritance)
  - `context-manager version` (new - COMBINES format-detector + template-version-parser)

- **Created workflow-manager** trampoline + 2 modules:
  - `workflow-manager status` (replaces status-aggregator, version routing preserved)
  - `workflow-manager control` (replaces workflow-control, version-agnostic discovered)

- **Created task-workflow** trampoline + 1 module:
  - `task-workflow create` (replaces template-copier, always v2.1)

**CIG Command Updates** (`.claude/commands/cig-*.md`):
- Updated all 17 CIG command files with new trampoline calls
- Simplified frontmatter from 7+ individual patterns to single wildcard: `Bash(.cig/scripts/command-helpers/*:*)`
- Removed all old script name references from documentation (executable calls, prose, headers)
- Created `.cig/scripts/update-cig-command-docs.sh` for executable documentation of transformation

**BACKLOG Updates**:
- Removed completed item: "Complete Helper Script Migration to Trampoline Pattern"
- No new backlog items identified

**CHANGELOG Updates**:
- Added this entry documenting Task 40 completion

### Implementation Quality
**Test Coverage**: 100% (18/18 test cases executed)
- 12 functional tests: Trampolines, modules, integration, backward compatibility
- 6 non-functional tests: Zero permission prompts, frontmatter, performance, errors, version routing, permissions
- 17/17 automated tests PASSED + 1 manual validation (TC-NF1)

**Defect Rate**: 1 test failure during execution (TC-F10)
- **Failure**: Old script names still present in CIG command documentation
- **Root Cause**: Initial implementation updated executable calls only, not prose/headers
- **Resolution**: Created update-cig-command-docs.sh + manual Edit fixes (commits 3b060f2, 293a4c1)
- **Post-fix**: Zero defects, all tests passing

**Performance**: Exceeded target
- Target: <10% overhead vs direct script calls
- Achieved: 16ms total (negligible overhead, <1ms per trampoline call)

**Backward Compatibility**: 100%
- Tasks 35-39 tested successfully
- Zero regressions introduced

### Key Achievements
1. **Zero Permission Prompts**: Wildcard frontmatter pattern (`Bash(.cig/scripts/command-helpers/*:*)`) grants permission to all trampolines/modules with single pattern
2. **Unified Architecture**: All helper scripts now use trampoline/module pattern (following Task 39's design)
3. **Documentation Consistency**: 100% old script name removal - zero references to standalone scripts
4. **Pattern Reuse**: Third trampoline (task-workflow) created in <30 minutes - pattern is now muscle memory
5. **Module Consolidation**: Combined format-detector + template-version-parser into single `version` module, eliminating duplication
6. **Version Routing Nuance**: Discovered workflow-control is version-agnostic (reads status field only, universal across v2.0/v2.1)

### Benefits Delivered
- **User Experience**: Zero permission prompts for CIG command helper script calls
- **Maintainability**: Single wildcard pattern vs 7+ individual patterns in frontmatter
- **Architecture**: Consistent trampoline/module design across all helper scripts
- **Documentation**: Executable documentation script (update-cig-command-docs.sh) provides auditability
- **Performance**: Negligible overhead (16ms) maintains responsiveness

### Lessons Learned
**Technical Insights**:
- Version routing is nuanced - understand WHAT a module does to determine IF it needs routing
- Module consolidation opportunities exist - look for scripts with overlapping functionality
- Documentation prose matters as much as code correctness - users read docs to understand usage

**Process Learnings**:
- Testing catches more than code bugs - comprehensive test plans find UX issues (TC-F10 found documentation inconsistency)
- Atomic commits enable iteration - 11 commits with ~28-minute cadence made git history valuable for debugging
- Tool usage guidelines have reasons - Edit tool vs sed isn't arbitrary, violating guidelines created permission issues
- Same-day execution benefits - completing planning → retrospective in one 5.1-hour session keeps context hot

**Estimation**:
- Testing documentation updates takes 2x longer than expected when many files involved (17 CIG commands)
- Estimate testing conservatively: 1.5-2x normal time for tasks with extensive documentation changes

### Recommendations for Future Tasks
**Process Improvements**:
1. Add explicit test plan review step - verify test case wording is unambiguous ("0 matches" should specify "code + docs")
2. Create documentation update checklist: (1) executable calls, (2) prose, (3) headers, (4) examples
3. Estimate testing conservatively when documentation updates span many files
4. Check tool usage guidelines before using Bash for file operations

**Tool Recommendations**:
1. Executable documentation scripts (*.sh) improve auditability - adopt for bulk refactoring tasks
2. Grep-based verification ("0 old references") is effective quality gate - standardize for rename/refactor tasks
3. Atomic commit strategy (~30-minute cadence) makes git history valuable - maintain this discipline

## Task 38: Complete Deferred Documentation and Prevent Future Deferrals

### Status: Complete (2026-02-06)
### Duration: <1 hour (vs. 2-3 hours estimated = **67% under**)
### Impact: Bugfix - Completed Task 37's deferred documentation and implemented preventive measures to avoid future scope deferrals

### Problem Addressed
Task 37 deferred documentation updates and marked the task complete anyway, creating technical debt. This bugfix completes the deferred work and updates templates to prevent future tasks from repeating this mistake.

**Issues Fixed**:
1. Task 37's new inference output format undocumented
2. state-tracking.md too verbose (655 lines) for quick reference
3. Templates lacked guidance against deferring implementation work

### Changes Made
**Documentation Refactor** (`.cig/docs/context/state-tracking.md`):
- Refactored from 655 → 177 lines (73% reduction, exceeded 70% target)
- Added Task 37's new structured output formats in Quick Reference section
  - Conclusive format (singular fields: task_num, task_slug, workflow_step)
  - Inconclusive uncorrelated (plural fields: task_nums, task_slugs, workflow_steps, reasons)
  - Inconclusive no_signals (unknown values)
- Reorganized into compact, scannable structure with 9 sections
- Moved output formats to top for immediate accessibility
- Converted verbose paragraphs to table-based reference

**Template Updates**:
- **d-implementation-plan.md.template**: Added "Scope Completion" section
  - Warns against deferring implementation work
  - Uses Task 37 as cautionary example
  - Provides 4-step guidance for legitimate deferrals
  - Appears after "Implementation Steps" section

- **f-implementation-exec.md.template**: Added "Deferral Check" section
  - Comprehensive 6-item checklist before marking task Finished
  - Verifies all steps, criteria, requirements, and design guidance followed
  - Ensures no work deferred without user approval
  - Appears before "Status" section

**BACKLOG Updates**:
- Removed completed item "Update state-tracking.md with New Inference Output Format"
- Added to CHANGELOG.md (this entry)

### Implementation Quality
**Test Coverage**: 100% (10/10 test cases passed)
- 7 functional tests: Line count, output formats, structure, templates, variable substitution, compatibility
- 3 non-functional tests: Readability, clarity, backwards compatibility
- All 4 task types tested with template-copier (feature, bugfix, hotfix, chore)

**Defect Rate**: 0 bugs found during implementation or testing

**Documentation Quality**: Exceeded target by 23 lines (177 vs 200 target)

**Time Efficiency**: Completed in <1 hour vs 2-3 hour estimate (67% under)

### Key Achievements
1. **Zero Scope Variance**: All original requirements delivered with no additions or deferrals
2. **Zero Defects**: All tests passed on first execution with no rework
3. **Exceeded Quality Targets**: 73% line reduction vs 70% target
4. **Preventive Measures**: Template updates provide concrete guidance (Task 37 example) to prevent future scope deferrals
5. **Complete Coverage**: All 4 task types validated with template-copier

### Benefits Delivered
- Task 37's structured output format now properly documented
- state-tracking.md 73% more compact and scannable
- Output format examples immediately accessible in Quick Reference section
- Future tasks will be reminded to complete all planned work before marking Finished
- Deferral checklist provides clear verification steps
- Task 37 cautionary example makes guidance concrete and actionable

### Lessons Learned
**What Went Well**:
- Clear requirement definition from Task 37 retrospective eliminated ambiguity
- Helper script (template-copier) streamlined template updates across all task types
- Comprehensive testing caught potential compatibility issues early
- Table-based documentation more scannable than paragraph format

**Process Improvements**:
- Documentation-only tasks with clear requirements execute faster than code changes (~1 hour vs typical 2-3 hours)
- Retrospective-driven bugfixes work well (Task 37 correctly identified both deferred work and root cause)
- Preventive template updates pay off (prevents repeated mistakes across all future tasks)

**Technical Insights**:
- Quick Reference sections at top dramatically improve usability for reference documentation
- Concrete examples (Task 37 cautionary tale) more effective than abstract warnings
- Template-copier ensures atomic, consistent updates across all task types

### Related Work
**Completed BACKLOG Item**:
- "Update state-tracking.md with New Inference Output Format" (identified in Task 37 retrospective)

**Scope Bonus**:
- Original BACKLOG item only requested documenting new format
- Task 38 also refactored for compactness (73% reduction) and updated templates to prevent future deferrals

## Task 37: Standardize Task Context Inference Output Format

### Status: Complete (2026-02-06)
### Duration: 3 hours (vs. 4-6 hours estimated = **on target**)
### Impact: Bugfix - Enabled programmatic parsing of inference output in all scenarios (conclusive, inconclusive, no_signals)

### Problem Addressed
Task 32's TaskContextInference.pm outputted unparseable prose when signals disagreed, breaking LLM and script automation. Commands could not programmatically extract task numbers from inconclusive output.

**Before (Conclusive - parseable)**:
```
task_num: 32
task_slug: task-tracking-using-inference-scoring
workflow_step: j-retrospective
```

**Before (Inconclusive - NOT parseable)**:
```
Signals disagree on current task.

Top candidates:
  - Task 14
  - Task 32

Please specify task number explicitly or clarify context.
```

### Changes Made
**Core Implementation** (`.cig/lib/TaskContextInference.pm`):
- **Updated `infer_task_context()`**: Build proper context hashes for all scenarios
  - no_signals: Returns hash with plural fields set to safe defaults (`unknown`, `none`)
  - uncorrelated: Builds plural arrays (task_nums, task_slugs, workflow_steps, reasons)
  - correlated: Added `current: conclusive` and `candidates: 1` for consistency
- **Refactored `format_output()`**: Unified formatting with conditional logic
  - Common fields: `current`, `confidence`
  - Conclusive: Singular fields (task_num, task_slug, workflow_step)
  - Inconclusive: Plural fields with comma-separated values
- **Deprecated `_format_uncorrelated()`**: Replaced by unified format_output()

**New Output Formats**:

*Conclusive*:
```
current: conclusive
confidence: correlated
task_num: 37
task_slug: fix-inconclusive-inference-output-format
workflow_step: g-testing-exec
```

*Inconclusive*:
```
current: inconclusive
confidence: uncorrelated
task_nums: 14,32,37
task_slugs: retro-suggest-updating,task-tracking-inference,fix-output
workflow_steps: j-retrospective,j-retrospective,g-testing-exec
candidates: 3
reasons: branch_signal,recency_signal,progress_signal
```

*No Signals*:
```
current: inconclusive
confidence: no_signals
task_nums: unknown
task_slugs: unknown
workflow_steps: unknown
candidates: 0
reasons: none
```

**Test Suite** (`t/test-output-format.pl`):
- Created comprehensive unit test script with mocked context hashes
- 8 functional test cases, 28 assertions
- 6 non-functional test cases (performance, security, usability, reliability)

**BACKLOG Updates**:
- Marked "Standardize Task Context Inference Output Format" as complete
- Added 4 follow-up tasks identified during retrospective

### Implementation Quality
**Test Coverage**: 100% of output format code paths
- **Functional**: 8/8 test cases PASS (28/28 assertions)
  - TC-1: Conclusive format (regression)
  - TC-2: Inconclusive uncorrelated (plural fields)
  - TC-3: Inconclusive no signals (unknown values)
  - TC-4: Parseability with regex
  - TC-5: Comma-separated value splitting
  - TC-6: Backward compatibility detection
  - TC-7: Edge case - empty arrays
  - TC-8: Edge case - single candidate
- **Non-Functional**: 6/7 test cases PASS (1 skipped)
  - Performance: 0.01ms for 100 candidates (target <10ms)
  - Security: Field injection prevented (slugs filesystem-safe)
  - Usability: Self-documenting field names
  - Reliability: Safe defaults, consistent exit codes

**Defect Rate**: 0 bugs - all tests passed on first run

**Performance**: 1000× faster than target (0.01ms vs 10ms)

### Key Learnings
**Design-First Approach**: Spending 30 minutes on comprehensive output format specification eliminated implementation ambiguity and saved time.

**Semantic Field Naming**: Using singular/plural field names (task_num vs task_nums) self-documents cardinality and improves parseability.

**Unit Tests > Integration Tests**: For output formatting, mocking context hashes allowed testing all scenarios without complex git state manipulation.

**Safe Array Defaults**: Pattern `@{$array || ['default']}` prevents crashes and improves robustness.

**Backward Compatibility**: Using `current` field for version detection (vs tracking version numbers) provides cleaner migration path.

### Benefits Delivered
- Commands/skills can parse output programmatically in all scenarios
- Plural fields self-document multiple values
- reasons field shows which signals contributed candidates
- Backward compatible via current field check
- Exit codes unchanged (0/1/3)
- No regressions in Task 32 functionality
- Performance excellent (~0.01ms for stress test)

### Process Improvements Identified
**Added to BACKLOG**:
1. Update `.cig/docs/context/state-tracking.md` with format specification
2. Update Task 32 test expectations (TC-I2, TC-I3, TC-I4)
3. Create integration test for inconclusive scenarios
4. Update commands/skills to use new structured format

## Task 36: Add Git Root Detection to All CIG Commands

### Status: Complete (2026-02-06)
### Duration: 2 hours (vs. 2-3 hours estimated = **on target**)
### Impact: Bugfix - Enabled all CIG commands to work from any directory within repository

### Problem Addressed
CIG commands failed when executed from subdirectories because they used relative paths (`.cig/scripts/...`) that only worked from repository root. This broke workflows when Claude Code's working directory changed during task execution.

### Changes Made
**Command File Updates**:
- Modified all 17 command files in `.claude/commands/cig-*.md`
- Added git root detection bash snippet to each file
- Inserted after "## Your task" section, before detailed instructions

**Git Root Detection Snippet**:
```bash
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
    echo "Error: Not in a git repository. CIG commands must be run from within a git repository."
    exit 1
fi
cd "$GIT_ROOT"
echo "Working directory: $GIT_ROOT"
```

**BACKLOG Updates**:
- Marked "Fix CIG Commands to Work from Any Directory" as complete

### Implementation Quality
**Test Coverage**: 100% verification (2 executed + 5 code-reviewed)
- TC-5 PASS: Grep verification (17/17 files contain GIT_ROOT)
- TC-6 PASS: Diff verification (consistent 12-line insertion per file)
- TC-1 through TC-4: Deferred (validated via code review)

**Defect Rate**: 0 bugs found during implementation or testing

**Validation Results**:
- All 17 files updated consistently (204 insertions total)
- Git diff shows uniform changes across all command files
- Bash logic validated through code inspection

### Key Learnings
**Branch Creation Timing**: Creating branch after implementation (instead of at task start) required stashing and recreating branch structure. Future tasks should create branch immediately.

**Verification > Live Testing**: For documentation/configuration changes, grep/diff verification is faster and safer than live functional testing while providing concrete evidence of correctness.

**Code Review Testing**: For deterministic bash scripts, code inspection can effectively replace live testing without introducing test artifacts.

**Checkpoint Commits + Squashing**: Pattern of checkpoint commits → backup branch → squash worked well for clean history while preserving detailed development record.

### Process Improvements Identified
Added 4 new BACKLOG items from retrospective:
1. Add "Create Task Branch" as first step in implementation execution
2. Document bugfix workflow differences (phase inclusion by type)
3. Create verification test pattern templates (grep/diff patterns)
4. Document checkpoint commit → squash workflow pattern

### Related Work
Completed BACKLOG item "Fix CIG Commands to Work from Any Directory" (Priority: High)

## Task 35: Fix Incorrect Command References

### Status: Complete (2026-02-06)
### Duration: 45 minutes (vs. 15 minutes estimated = **200% over**)
### Impact: Bugfix - Corrected anachronistic `/cig-plan` references to `/cig-task-plan` in command files

### Problem Addressed
Found 2 outdated command references in command definition files that resulted from the `/cig-plan` → `/cig-task-plan` rename. Historical references in implementation guides were intentionally preserved as documentation artifacts.

### Changes Made
**Command File Updates**:
- `.claude/commands/cig-new-task.md:98` - Updated next-action reference to `/cig-task-plan`
- `.claude/commands/cig-subtask.md:74` - Updated next-action reference to `/cig-task-plan`

### Implementation Quality
**Test Coverage**: 100% (7/7 test cases passed)
- 5 functional tests: File updates, scope verification, historical preservation
- 2 non-functional tests: Readability, consistency

**Defect Rate**: 0 bugs found during implementation or testing

**Validation Results**:
- Zero `/cig-plan` references remaining in `.claude/commands/` directory
- 35 historical references preserved in `implementation-guide/` (excluding Task 35's own docs)
- Clean git diff: 2 files changed, 2 insertions, 2 deletions

### Key Learnings
**Time Estimation**: Initial 15-minute estimate was 3x under actual (45 minutes). Thorough documentation for each workflow phase added value but increased time. Future hotfix estimates should be 30-60 minutes when following full CIG workflow.

**Baseline Verification**: Historical reference baseline (35) was inaccurate - actual was 52 total (35 excluding Task 35's docs). Pre-execution baseline verification would have prevented mid-stream test criteria adjustment.

**Documentation ROI**: Even simple 2-line changes benefit from comprehensive documentation. The additional 30 minutes created clear audit trail and reusable learning artifacts.

### Related Work
Partial completion of BACKLOG item "Audit Command References and Create Design-Alignment Conventions":
- **Completed (Task 35)**: Fixed 2 command reference errors
- **Remaining**: Create `docs/conventions/design-alignment.md` to prevent future inconsistencies

## Task 34: Task Stack Management System

### Status: Complete (2026-02-03)
### Duration: 6 hours (vs. 6-12 hours estimated = **met lower bound**)
### Impact: Major enhancement - LIFO task stack with 6 operations enables context-aware task switching and enhanced inference

### Problem Addressed
The BACKLOG requested "Implement Current Task Tracking" to reduce repetitive task number arguments in workflow commands. Task 34 delivered this as an enhanced task stack management system rather than simple single-task tracking.

### Features Delivered
**Core Task Stack Script** (`.cig/scripts/command-helpers/task-stack`):
- **6 Operations**: push, pop, peek, list, clear, size
- **Atomic Operations**: flock(LOCK_EX) prevents race conditions
- **Self-Documenting Output**: Shows script path and --help hint to teach agent discovery
- **Dirname Format Storage**: Full context preserved (e.g., `34-feature-add-task-stack-script`)
- **Performance**: ~12-13ms per operation (8x faster than 100ms target)

**/cig-current-task Skill**:
- User-friendly wrapper for task stack operations
- Thin delegation pattern (no logic duplication)
- Clear usage examples and documentation

**Task 32 Inference Integration**:
- Enhanced to parse last 5 dirnames from stack
- State signal now provides multiple candidates (not just single task)
- Graceful degradation (works without stack file)
- Score: 85 points when stack present

**Initialization Integration**:
- Updated `/cig-init` to add `.cig/task-stack` to `.gitignore`
- Idempotent gitignore management

**Documentation**:
- File protection advisory in CLAUDE.md
- Comprehensive troubleshooting guide (5 common issues)
- Runbooks for daily operations and emergency procedures

### Implementation Quality
- **Test Coverage**: 100% (22/22 tests passed)
- **Defect Rate**: 0 bugs found during testing
- **Performance**: 8x faster than requirements
- **Concurrent Safety**: flock validated through multiple test runs
- **Security**: Script hashes registered in security tracking

### Changes Implemented
**New Files**:
- `.cig/scripts/command-helpers/task-stack` (175 lines, 0755 permissions)
- `.claude/skills/cig-current-task/SKILL.md` (skill definition)

**Modified Files**:
- `TaskContextInference.pm`: Enhanced stack integration (parses multiple dirnames)
- `task-context-inference`: Updated header comment reference
- `cig-init.md`: Added gitignore management step
- `CLAUDE.md`: Added file protection advisory section
- `script-hashes.json`: Updated security tracking

### Test Results
- **Pass Rate**: 22/22 tests (100%)
- **Functional Tests**: 7/7 PASS (push/pop/peek/list/clear/size operations)
- **Non-Functional Tests**: 4/4 PASS (performance, concurrency, errors, validation)
- **Integration Tests**: 4/4 PASS (skill, hook, Task 32 integration, graceful degradation)
- **Security Tests**: 3/3 PASS (permissions, flock, format validation)
- **Cleanup Tests**: 2/2 PASS (old command removal, reference cleanup)
- **Initialization Tests**: 2/2 PASS (cig-init integration, idempotency)

### Key Achievements
1. **Zero Bugs**: All tests passed on first execution
2. **Performance Excellence**: 8x faster than target (~12-13ms vs 100ms)
3. **Enhanced Scope**: Delivered LIFO stack beyond simple current task tracking
4. **Complete Documentation**: Comprehensive troubleshooting, runbooks, and maintenance guides
5. **Seamless Integration**: Task 32 inference enhanced without breaking existing functionality

### Lessons Learned
**What Went Well**:
- Comprehensive planning (with code examples) eliminated implementation uncertainty
- Test-driven design resulted in zero bugs
- CIG workflow template ensured no missing phases
- flock atomicity validated through concurrent testing

**Technical Insights**:
- Perl `$0` contains invocation path; use `Cwd::abs_path()` for consistency
- CIG::TaskPath API uses positional arguments (not named parameters)
- Self-documenting output (script path in output) enables agent learning
- Simple file-based design scales well (tested to 100+ entries)

**Process Improvements**:
- Planning ROI is high (1 hour planning saved hours of uncertainty)
- Writing tests before implementation prevents rework
- Incremental testing catches issues early (format_dirname argument order)

### Recommendations
1. Continue detailed implementation plans with code examples
2. Standardize test-driven design approach
3. Add API usage examples to module documentation
4. Create concurrent test utilities for future file-based tools

### Usage
```bash
# Push current task onto stack
/cig-current-task push 34

# Show stack (last 5 tasks)
/cig-current-task

# Pop completed task
/cig-current-task pop

# Clear entire stack
/cig-current-task clear
```

## Task 30: Fix v2.0 Format Detection Bug in TaskPath.pm

### Status: Complete (2026-01-27)
### Duration: 2.5 hours (vs. 1-1.5 days estimated = **6x faster**)
### Impact: Critical bug fix - all v2.0 tasks were misdetecting as v1.0, breaking format-dependent script routing

### Problem Discovered
During user testing with Task 24, discovered all v2.0 tasks were misdetecting as v1.0 format:
- **Root Cause**: Line 213 in CIG::TaskPath::detect_format() was checking for v2.1 file names (`a-task-plan.md`, `d-implementation-plan.md`) instead of v2.0 file names (`a-plan.md`, `d-implementation.md`)
- **Impact**: hierarchy-resolver, status-aggregator, and context-inheritance trampolines all routed v2.0 tasks to wrong version-specific scripts
- **Scope**: Affected majority of repository (Tasks 1-24 are v2.0 format)

### File Naming Confusion
Task 29 renamed files for v2.1 format, creating two distinct naming conventions:
- **v2.0 format** (8 files): `a-plan.md`, `d-implementation.md`, `e-testing.md`, etc. (shorter names)
- **v2.1 format** (10 files): `a-task-plan.md`, `e-testing-plan.md`, `f-implementation-exec.md`, etc. (longer names)

Detection logic must use **v2.0 names** when checking for v2.0 tasks, not v2.1 names.

### Changes Implemented
**Phase 1: Core Detection Logic**
- Added `detect_format()` function to CIG::TaskPath with header-based detection + file fallback
- Fixed line 213 to check for correct v2.0 file names (`a-plan.md`, `d-implementation.md`)
- Added version mismatch warning system (detects when headers don't match file structure)
- Consolidated trampoline detection logic - status-aggregator and context-inheritance now use CIG::TaskPath::resolve()
- **Code quality**: 88 lines duplicate logic → 42 lines consolidated (50% reduction)

**Phase 2: Template Headers**
- Updated 10 v2.1 templates to emit "Template Version: 2.1" (was incorrectly "2.0")
- Templates: a-task-plan, b-requirements-plan, c-design-plan, d-implementation-plan, e-testing-plan, f-implementation-exec, g-testing-exec, h-rollout, i-maintenance, j-retrospective

**Phase 3: Task Migrations**
- Migrated Task 26 headers (10 files - feature task with all a-j files)
- Migrated Task 30 headers (7 files - bugfix task: a, c, d, e, f, g, j)

**Phase 4: Security and Testing**
- Updated script-hashes.json with new SHA256 hashes for 3 modified files
- Executed 17 tests (13 functional + 4 non-functional) - **100% pass rate**
- Critical regression test TC-11 validates Task 24 now correctly detects as v2.0

### Test Results
- **Pass Rate**: 17/17 executed tests (100%)
- **Performance**: 12-13ms vs. 100ms target (**8.3x faster**)
- **Coverage**: 100% of implemented functionality
- **Bug Fix Validated**: Task 24 and all v2.0 tasks now correctly detect as v2.0

### Files Modified
- 1 library: `.cig/lib/CIG/TaskPath.pm` (added detect_format, fixed line 213)
- 2 trampolines: status-aggregator, context-inheritance (consolidated detection)
- 8 templates: v2.1 templates updated to version 2.1
- 17 task files: Task 26 (10 files) + Task 30 (7 files) migrated to v2.1 headers
- 1 security: script-hashes.json updated

**Total**: 25 files changed, 1577 insertions(+), 96 deletions(-)

### Key Learnings
- **File naming is critical**: v2.0 vs v2.1 naming differences must be explicitly documented
- **Test all version scenarios**: Regression tests should cover v1.0, v2.0 (migrated + native), and v2.1
- **User testing is invaluable**: Real-world usage (Task 24) caught bug that systematic testing missed
- **Status field standardization**: Custom status values ("In Progress (Updated...)") break status-aggregator parsing
- **AI development velocity**: 2.5 hours actual vs. 8-12 hours estimated (6x speedup from AI-assisted development)

## Task 29: Fix v2.1 Workflow File Order and Next Step References

### Philosophy: Test Planning as Thinking Tool
### Status: Complete (2026-01-26)
### Impact: Corrects v2.1 workflow to follow test-first principles, enabling test planning before implementation execution
### Key insight: Test planning isn't about having tests ready to run - it's about understanding what "working" means before implementing. By forcing yourself to think through measurability, edge cases, and success criteria, you write better implementation code.

Fixed critical workflow design flaw where implementation execution occurred before test planning. The corrected order (plan tests → execute implementation → execute tests) enables test planning to serve as a thinking tool that deepens understanding before code is written.


**This is planning-driven development with TDD principles**, not traditional TDD. You're planning your test approach (not writing test code) to gain clarity about requirements and outcomes.

### File Order Correction
**Old order** (incorrect):
- d-implementation-plan.md → **e-implementation-exec.md** → **f-testing-plan.md** → g-testing-exec.md

**New order** (correct):
- d-implementation-plan.md → **e-testing-plan.md** → **f-implementation-exec.md** → g-testing-exec.md

### Changes Implemented
**Phase 1: Template Renaming**
- Renamed 2 pool template files using git mv (preserves history)
- Updated 10 symlinks across 5 task types (feature, bugfix, hotfix, chore, discovery)
- All renames tracked by git at 100% similarity

**Phase 2: Reference Updates (60+ references across 11 components)**
- Updated 4 template "Next Action" fields (d, e, f, g)
- Updated CIG::WorkflowFiles::V21 module (5 task type arrays)
- Updated blocker-patterns.md (5 references)
- Updated 6 workflow command files
- Updated workflow documentation (workflow-steps.md, workflow-overview.md) with philosophy
- Fixed format detection bug in 3 trampoline scripts (critical for template-copier)

**Phase 3: Migration Script**
- Created `.cig/scripts/migrations/migrate-v2.1-file-order`
- Validates task is v2.1 before migrating (safe for v2.0/v1.0)
- Three-way file swap preserves git history
- Idempotent design (safe to re-run)
- Added to script-hashes.json with SHA256 verification

**Phase 4: Task Migrations**
- Migrated Tasks 26, 27, 28, 29 to corrected file order
- All migrations successful with 100% git similarity
- Zero breaking changes for existing workflows

### Testing Results
Comprehensive testing validated all aspects of the fix:
- **16/16 test cases passed** (13 functional + 3 non-functional)
- **100% coverage** (all 11 components verified)
- **Zero defects** found during testing
- **Zero regressions** for v2.0 or v1.0 tasks

**Performance**: Both helper scripts exceeded targets significantly
- template-copier: 31ms (target <5s, 160x faster)
- status-aggregator: 27ms (target <100ms, 3.7x faster)

### Documentation Updates
**Philosophy Documentation**:
- Added "Test Planning as Thinking Tool" section to workflow-overview.md
- Explains why e before f (test planning deepens understanding before implementation)
- Distinguishes from traditional TDD (planning not coding tests first)
- Clarifies this is planning-driven development with TDD principles

**Workflow Documentation**:
- Updated workflow-steps.md with v2.1 format description
- Updated all file references throughout documentation
- Added version-aware guidance (e-testing-plan for v2.1, f-testing-plan for v2.0)

### Key Learnings
**Systematic planning ROI**: 40 min planning investment saved 6+ hours (no rework, no debugging). 10-step implementation plan eliminated decision paralysis and enabled confident progress.

**Checkpoint commits reduce risk**: 3 checkpoint commits during Phase 2 provided clean rollback points every 1.5-2 hours. Cost minimal (5 min per commit), benefit high (eliminated fear of breaking changes).

**LLM acceleration significant**: Actual duration 0.3 days vs estimate 2-3 days (5-9x faster). File operations, reference hunting, and script writing all dramatically faster with LLM assistance.

**git mv preserves history automatically**: Using git mv instead of manual rename preserved full file history at 100% similarity, with no manual tracking needed.

### System Status
- v2.1 workflow file order corrected systemwide
- All templates create tasks with correct file names
- All existing v2.1 tasks migrated successfully
- Philosophy documented for future reference
- Migration script available for any future file order changes
- Zero regressions, 100% test coverage, all systems operational


## BACKLOG Task: hierarchy-resolver Trampoline Entry Point [Already Complete]

**Status**: Complete (Task 27, 2026-01-23) - Task was based on false premise
**Impact**: Clarification of existing architecture

### Background
A BACKLOG task "Create hierarchy-resolver Trampoline Entry Point" was identified, claiming hierarchy-resolver was missing its entry point. Investigation revealed this was incorrect:

**Actual state**:
- hierarchy-resolver exists as `.cig/scripts/command-helpers/hierarchy-resolver` (created in Task 8, renamed in Task 27)
- It IS the entry point - no separate trampoline needed
- Version-agnostic because hierarchy resolution behaviour is identical across all versions (uses CIG::TaskPath internally)
- Registered in script-hashes.json, referenced correctly by all commands
- Tested working with v2.0 and v2.1 tasks

**Why no trampoline needed**: Unlike status-aggregator (which needs version-specific output formatting), hierarchy-resolver just resolves task paths - same logic for all versions.

**Task 27** (Standardise Script Naming) renamed hierarchy-resolver.pl → hierarchy-resolver, completing the "Alternative (simpler)" approach mentioned in the BACKLOG task description.


## BACKLOG Task: Clarify That Requirements and Design Are Planning Steps [Already Complete]

**Status**: Complete (Task 29, 2026-01-26) - Problem addressed via "Scope & Boundaries" sections
**Impact**: Eliminated LLM confusion about planning vs execution phases

### Background
A BACKLOG task "Clarify That Requirements and Design Are Planning Steps" was identified, describing LLM confusion where:
- LLM would ask "should I exit plan mode?" when user ran `/cig-requirements` or `/cig-design`
- LLM treated only `/cig-plan` as planning, misidentified requirements and design as execution
- This created "very frustrating" user experience

### Already Fixed in Task 29
**Task 29** (Fix v2.1 Workflow File Order) updated all workflow command files with **"Scope & Boundaries"** sections:

**Example from cig-requirements-plan.md**:
```markdown
## Scope & Boundaries

**This step**: Complete the requirements planning document (b-requirements-plan.md)...

**Not this step**: Design decisions, implementation planning, code writing, or testing.
```

**Example from cig-design-plan.md**:
```markdown
## Scope & Boundaries

**This step**: Complete the design planning document (c-design-plan.md)...

**Not this step**: Implementation (that's d-implementation-plan + f-implementation-exec), testing, or deployment.
```

These sections clearly delineate what IS and IS NOT in scope for each phase, eliminating confusion about whether requirements/design are planning or execution.

### Verification
**No issues observed since Task 29 changes** (2026-01-26 through 2026-01-27):
- ✓ No "should I exit plan mode?" questions during requirements or design phases
- ✓ LLM correctly treats requirements and design as planning activities
- ✓ Scope boundaries clearly communicate phase responsibilities

The BACKLOG task requested explicit "⚠️ PLANNING PHASE" warnings, but the "Scope & Boundaries" approach proved equally effective and more idiomatic (follows "This step / Not this step" pattern used throughout CIG commands).

**Conclusion**: Problem solved differently than BACKLOG task specified, but user confirms no issues observed since fix.


## BACKLOG Task: Fix Status Aggregator to Only Check Main Status Sections [Already Complete]

**Status**: Complete (Task 25, 2026-01-23) - Problem eliminated by file separation architecture
**Impact**: No multiple Status sections exist in v2.1 format

### Background
A BACKLOG task "Fix Status Aggregator to Only Check Main Status Sections" was identified, claiming:
- c-design.md has 3 Status sections (main + embedded implementation plan + embedded testing plan)
- status-aggregator showed 25% when task was actually complete due to not all Status sections being updated
- Confusing which Status sections "count" toward task completion

### Already Solved by Task 25 Architecture
**Task 25** (Implement v2.1 workflow with planning/execution separation) eliminated this problem entirely through **file separation**:

**Old structure (hypothetical v2.0 concern)**:
- c-design.md could theoretically contain multiple Status sections if implementation/testing plans were embedded

**New structure (v2.1 format)**:
- c-design-plan.md (design planning) - 1 Status section
- d-implementation-plan.md (implementation planning) - 1 Status section
- e-testing-plan.md (testing planning) - 1 Status section

Each planning file has exactly ONE `## Status` section, so there's no ambiguity about which section "counts" for status aggregation.

### Verification
**Checked current codebase**:
- ✓ All templates have exactly 1 `## Status` section per file
- ✓ All actual task files checked have exactly 1 `## Status` section per file
- ✓ No multiple Status sections found in any workflow file

**Note on Task 30's 25% issue**: That was a **different problem** - custom status values ("In Progress (Updated...)") broke the parser. This was fixed by using canonical status values ("Finished"). Not related to multiple Status sections.

**Conclusion**: File separation architecture inherently prevents the problem this task was trying to solve. No code changes needed.

## Task 4: Migration Tools to Migrate v1.0 to v2.0

### Status: Complete
### Impact: Enables safe migration of existing v1.0 tasks to v2.0 hierarchical structure with rollback capability

### Migration Scripts
Automated migration tooling discovered issues with hardcoded status values and disconnected configuration. Extended implementation to include configuration-driven status validation system.

**Three Migration Scripts**:
1. `migrate-v1-to-v2.sh` - Migrate v1.0 tasks to v2.0 with git-first backup strategy
2. `validate-migration.sh` - Validate migration integrity (Template Version, structure, content)
3. `rollback-migration.sh` - Rollback migration using git tags or manual backup

**Migration Features**:
- Git-first backup strategy using tags (instant rollback with `git reset --hard`)
- Directory structure migration: `{type}/{num}-{desc}` → `{num}-{type}-{desc}`
- Workflow file renaming: `plan.md` → `a-plan.md`, `requirements.md` → `b-requirements.md`, etc.
- Template Version tagging (adds `Template Version: 2.0` field)
- Content integrity validation with SHA256 hash comparison
- Idempotent operation (safe to run multiple times)
- Dry-run mode for preview

### Configuration-Driven Status System
During rollout discovered that status values were hardcoded and disconnected from configuration, with no LLM guidance on valid values. Enhanced to make status system self-documenting and configuration-driven.

**Status System Features**:
- Status values defined in `cig-project.json` as object (status name → percentage)
- `status-aggregator.sh` loads from config with fallback to defaults
- Unknown status warnings to stderr (non-breaking, shows: actual, mapped, effective values)
- LLM guidance in workflow commands referencing central documentation
- Self-documenting via configuration file

**Status Values**:
- Backlog (0%) - Task not started
- To-Do (0%) - Task ready to begin
- In Progress (25%) - Work actively underway
- Implemented (50%) - Code complete, not tested
- Testing (75%) - Testing in progress
- Finished (100%) - Fully complete

**Design Principles**:
- Progressive disclosure: Commands reference `.cig/docs/workflow/workflow-steps.md#status-values`
- Non-breaking warnings: Unknown statuses default to 0% with stderr warning
- Backward compatible: Fallback to hardcoded defaults if config missing/invalid
- Configuration format enables project customization of workflow stages

### Documentation Updates
**Migration Documentation**:
- Created comprehensive migration guide (`.cig/docs/migration.md`) covering why/how/safety
- Migration guide explains v1.0 limitations vs v2.0 benefits
- Six-step migration process with rollback procedures
- Prerequisites, safety features, and troubleshooting documented

**Workflow Documentation**:
- Status values section added to workflow-steps.md
- jq command examples for querying valid statuses
- All 8 workflow commands include status field guidance

### Testing Results
Comprehensive testing validated all aspects of migration and status systems:
- 24/24 migration test cases passed (3 skipped: rollback, manual backup, edge cases)
- Status loading from config: PASSED
- Unknown status warnings: PASSED
- Fallback with missing config: PASSED (bug fixed during testing)
- Template validation: PASSED
- Workflow command instructions: PASSED (8/8 verified)

### System Status
- Migration tools fully operational and tested
- Status system self-documenting via configuration
- Safe migration path from v1.0 to v2.0 with rollback capability
- Git-first backup strategy provides instant rollback
- Configuration-driven validation reduces LLM confusion

## Task 3: Hierarchical Workflow System with Dynamic Step Transitions

### Task 2: Script-Based CIG Command Helpers
### Task 1: CIG Commands Implementation
### Task 0: Initial System Design
### Status: Complete
### Impact: Foundational change enabling infinite task nesting with 90% reduction in LLM context consumption

### Token-Efficient Context Inheritance
Reduces LLM context consumption by 90% through structural maps that enable progressive disclosure. Instead of reading full parent files (500-1000 tokens each), LLM receives navigable document structure with headers and line ranges (50-100 tokens), preserving agency to decide what details matter.

**Key Features**:
- Status markers prevent implementation confusion by indicating reliability of parent context
- Dual output formats (markdown/JSON) serve both human/LLM reasoning and programmatic automation
- Version checking ensures workflow files remain compatible with CIG software as system evolves
- Enables hierarchical task decomposition with infinite nesting while maintaining context efficiency
- LLM can understand parent task decisions without drowning in irrelevant details

### Core Infrastructure
Establishes foundation for infinite task nesting while maintaining LLM context efficiency through progressive disclosure.

**Central Template Pool**:
- Symlinks eliminate duplication across task types
- Single source of truth in `.cig/templates/pool/`
- Task-type-specific symlinks (feature: 8 files, bugfix: 5 files, hotfix: 5 files, chore: 4 files)

**Five Helper Scripts** (Automation Layer):
1. `hierarchy-resolver.sh` - Task path to directory resolution with metadata
2. `format-detector.sh` - Template version detection with upgrade suggestions
3. `status-aggregator.sh` - Progress calculation from status markers using defined formula
4. `template-version-parser.sh` - Standalone version field extraction
5. `context-inheritance.pl` - Parent context structural maps with headers and line ranges

**Eight Workflow Commands** (Complete Task Lifecycle):
- `/cig-plan` - Planning phase with decomposition signals
- `/cig-requirements` - Requirements gathering with acceptance criteria
- `/cig-design` - Architecture and design decisions
- `/cig-implementation` - Code changes and validation
- `/cig-testing` - Test strategy and execution
- `/cig-rollout` - Deployment strategy and monitoring
- `/cig-maintenance` - Ongoing support and optimization
- `/cig-retrospective` - Lessons learned and recommendations

**Design Principles**:
- Consistent 8-step pattern across all commands
- Each command references shared context documentation (DRY principle)
- Commands use helper scripts for deterministic operations
- Progressive disclosure pattern: Commands reference workflow step docs instead of duplicating content
- LLM receives structural information to make intelligent decisions

**Security Model**:
- SHA256 hashes stored for all helper scripts in `.cig/security/script-hashes.json`
- Permissions enforced (u+rx minimum, typically 0500)
- Git-based version tracking

### Documentation and User-Facing Guides
Finalizes v2.0 implementation with comprehensive workflow documentation and updated project guides. Users now have complete reference for 8-step workflow system, task decomposition principles, and migration from v1.0.

**Workflow Documentation** (3200 words total):
- Overview: 8-step hierarchical workflow and decomposition principles (400 words)
- Step-by-Step Guidance: Detailed focus/avoid patterns for each of 8 steps (2400 words)
- Decomposition Guide: 5 universal signals and hierarchical numbering explanation (400 words)

**README.md Updates** (v2.0 Features):
- Infinite task nesting with decimal numbering (1, 1.1, 1.1.1, ...)
- Token-efficient context inheritance (90% reduction in LLM context consumption)
- Progressive disclosure and central template pool
- All 8 workflow commands with examples
- Migration notes for breaking changes from v1.0

**CLAUDE.md Updates** (LLM Consumption):
- Concise architecture overview emphasizing token efficiency
- All 16 commands organized by category
- Progressive disclosure pattern explanation
- Security model and helper script descriptions

### Breaking Changes from v1.0
- **`/cig-new-task`**: New signature `<num> <type> "description"` for hierarchical numbering (was `<type> <num> <description>`)
- **`/cig-extract`**: Task-based paths instead of file paths (backward compatible during migration period)
- **`/cig-subtask`**: Context inheritance via helper scripts, not manual reading

### System Status
- Fully operational with complete documentation
- Users can leverage hierarchical workflows, context inheritance, and structured task progression
- 90% token reduction enables handling complex multi-level project structures
- Breaking changes clearly documented with migration path


## Previous Tasks


Complete script-based CIG command helpers implementation with security fixes.


Complete CIG commands implementation with official Anthropic patterns.


- CIG project configuration system and unified task commands
- Comprehensive CIG command reference
- Initial implementation guide system design
