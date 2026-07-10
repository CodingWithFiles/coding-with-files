# Resolve tool-check hook paths from git root - Design
**Task**: 224 (bugfix)

## Task Reference
- **Task ID**: internal-224
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/224-resolve-tool-check-hook-paths-from-git-root
- **Template Version**: 2.1

## Goal
Enforce the hook-command rooting invariant at `cwf-manage validate` time, and correct the
one shipped document that still teaches the bare-relative form. See `a-task-plan.md`
§"Origin and Scope Correction" for why the originally-reported defect is already fixed.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### D1 — The invariant is "no bare `.cwf/` reference", not "command starts with the prefix"

- **Decision**: A hook `command` violates the invariant iff it contains the substring
  `.cwf/` **not** immediately preceded by the literal `${CLAUDE_PROJECT_DIR}/`.
- **Rationale**: The obvious formulation — "the command must start with
  `${CLAUDE_PROJECT_DIR}/`" — is wrong. The shipped rules-inject hook is registered as:

  ```
  cat "${CLAUDE_PROJECT_DIR}/.cwf/rules-inject.txt" 2>/dev/null || true
  ```

  The prefix is mid-string, behind `cat "`. A starts-with rule would flag a correct,
  deliberately-shaped command (`cwf-claude-settings-merge` calls this string canonical and
  warns that it must stay a literal). Anchoring on the *`.cwf/` reference* rather than on
  the command's first character is what the invariant actually means: every path CWF hands
  the harness to execute must be rooted at the project directory.
- **Trade-offs**: An absolute path (`/home/u/repo/.cwf/scripts/hooks/…`) is also flagged.
  This is deliberate — a machine-specific absolute path does not survive `git clone`, so it
  is a latent break, not a valid alternative. The `fix` text names the canonical form.
  Accepted **false-positive** surface, all advisory-fixable and none silently wrong:
  1. a user hook that merely *mentions* `.cwf/` in an argument without it being a path;
  2. an absolute path, per above;
  3. the unbraced expansion `$CLAUDE_PROJECT_DIR/.cwf/…` — correctly rooted but not the
     canonical braced form the generator emits.

  Accepted **false-negative** surface: a reference to `.cwf` *without* a trailing slash
  (`cd .cwf && …`) is not matched. Safe today — every hook command targets a file under
  `.cwf/scripts/…` — but re-audit if a future hook shape addresses the directory bare.
- **Relationship to the existing detector**: `cwf-claude-settings-merge` already carries
  `prune_stale_relative_cwf_hooks` (Task 204), which matches bare-relative commands by
  **anchored full-string equality against the known CWF command set** in order to re-link
  them. That predicate is deliberately narrow because it drives a *rewrite*: it must never
  touch a command it does not fully recognise. This validator's predicate is deliberately
  **broader** (substring lookbehind) because it drives only a *report*: it should catch
  absolutes, user-registered CWF hooks, and future command shapes the generator has never
  emitted. Narrow-to-repair, broad-to-surface. The two are not duplicates and neither
  should adopt the other's predicate.

### D2 — Scan the `hooks` tree only; never `permissions`

- **Decision**: Walk `settings.hooks` exclusively. Ignore every other top-level key.
- **Rationale**: `.claude/settings.json` and `.claude/settings.local.json` both carry
  `permissions.allow` entries of the form `Bash(.cwf/scripts/hooks/stop-stale-status-detector)`.
  Those are **match patterns against a typed command string**, not paths the harness
  executes. Prefixing them would break the match. Verified present in both files today.
  A validator that scanned the whole document would fire on ~6 legitimate entries and be
  turned off within a day.
- **Trade-offs**: A bare-relative path introduced somewhere other than `hooks` goes
  unchecked. Correct — nowhere else in the settings schema is a command executed.

### D3 — New module `CWF::Validate::Hooks`, mirroring `CWF::Validate::Agents`

- **Decision**: Add `.cwf/lib/CWF/Validate/Hooks.pm` exporting `validate($git_root)`,
  returning the established violation hashref list
  (`category, file, field, actual, expected, fix`). Wire it into `cwf-manage`'s
  `cmd_validate` alongside the eight existing validators.
- **Rationale**: `CWF::Validate::Agents` is the precedent and near-exact analogue — it
  exists to catch one *fail-open* Claude Code footgun (`allowed-tools:` silently ignored in
  an agent file, leaving the full tool set). This task's defect is the same species: a
  misregistered hook silently never fires. One module per fail-open footgun keeps each
  self-documenting; folding it into `Consistency` would bury it. Consistency with an
  existing pattern beats novelty (Integration beats perfection).
- **Trade-offs**: A ninth validator module. Cheap: the pattern is established, the file is
  small, and `cmd_validate` composes them as a flat list.

### D4 — Surface, never repair

- **Decision**: The check reports the offending event, command, and file. It offers no
  `--fix` and is **not** wired into `cwf-manage fix-security`.
- **Rationale**: `.cwf/docs/conventions/hash-updates.md` — a silently-repaired guard is
  indistinguishable from a guard that was never broken. Regenerating the registration is
  already possible (`cwf-claude-settings-merge` prunes and re-links stale bare-relative
  commands); the operator should invoke it knowingly. The `fix` field names that command.
- **Trade-offs**: One manual step on breach. That friction is the feature.

### D5 — Do not touch the generator

- **Decision**: `cwf-claude-settings-merge` is left unmodified. The prefix literal is
  defined independently in the validator, and **TC-9** asserts the generator's source still
  contains that same literal.
- **Rationale**: The generator is correct and hash-tracked. Extracting a shared constant
  into `CWF::Common` would edit a second hashed file to remove a two-site duplication of a
  string fixed by Claude Code's own contract — below the Rule of Three, and net-negative on
  risk. The binding is enforced where it matters (a test), not by coupling.
- **Trade-offs**: The literal `${CLAUDE_PROJECT_DIR}/` appears in the generator, the
  validator, and the doc — three sites, one test each: **TC-9** (generator source carries
  the literal), **TC-7** (a tree generated in the canonical form validates clean), and
  **TC-8** (the doc shows no bare-relative hook command).

  *Correction applied at plan review*: an earlier draft claimed TC-3 enforced
  generator↔validator agreement. It does not — TC-3 asserts a hardcoded command *shape*
  passes the predicate, and would keep passing if the generator changed its literal
  tomorrow. TC-9 exists because that claim was wrong.

## System Design

### Component Overview
- **`CWF::Validate::Hooks`** *(new)*: Reads the settings file(s), walks the `hooks` tree,
  applies the D1 predicate to each `command`, returns violations. No I/O beyond reading.
- **`cwf-manage cmd_validate`** *(edit, hashed)*: Adds one call to the composed list.
- **`.cwf/docs/workflow/stop-hooks-framework.md`** *(edit)*: The JSON example at line 164
  gains the `${CLAUDE_PROJECT_DIR}/` prefix.
- **`t/validate-hooks.t`** *(new)*: Unit-tests the predicate and the doc/generator agreement.

### Scan Targets
Both files, each optional (absent → contributes nothing):

| Path | Provenance | Rationale |
|------|-----------|-----------|
| `.claude/settings.json` | checked-in, CWF-generated | The file the generator writes |
| `.claude/settings.local.json` | user-owned, gitignored | A hook registered here fails open identically |

### Data Flow
1. `cwf-manage validate` → `CWF::Validate::Hooks::validate($git_root)`
2. For each scan target present: read → `JSON::PP` decode
3. **Any** failure to turn a present file into a decoded hashref — `open` failure,
   unreadable, symlink, non-regular, or malformed JSON — yields one violation
   (`field => 'json-parse'`) and **never** a die
4. Walk `hooks` → *event* → group → `hooks[]` → each entry's `command`
5. Apply the D1 predicate; on breach emit one violation per offending command
6. Violations flow into `cmd_validate`'s existing aggregation and exit-code logic

**Step 3 covers the whole failure class, not just decode.** The precedent
`CWF::Validate::Agents` *dies* on `open` failure. Copying that here would reintroduce, via
the `open`, exactly the abort this step exists to prevent: `settings.local.json` is
user-owned with machine-specific permissions, so a present-but-unreadable file would kill
the other eight validators. Guard the read and the decode alike.

**Uniform treatment of `settings.local.json` is deliberate.** The generator's
`warn_on_worktree_allowlist` treats that file best-effort (never fails on it), so uniform
hard-violation treatment here is a considered divergence, not an oversight. Rationale:
Claude Code applies a strict schema to `settings.local.json` and rejects the *whole file* on
malformed JSON. An unparseable local file therefore means the user's settings — including
any hook registrations — are not loading at all. That is precisely the "guard is off, no
signal" condition this task exists to surface. Warning on it would smooth the signal.

### Traversal Robustness
The `hooks` tree is user-editable, so every level is type-checked before descent
(`ref eq 'HASH'` / `'ARRAY'`, `defined && !ref` on the command scalar). A malformed level is
skipped, not fatal. This mirrors the defensive shape of `cwf-claude-settings-merge`'s own
`merge_hooks`.

## Interface Design

### Module contract
```
CWF::Validate::Hooks::validate($git_root)   -> @violations   # does file I/O
CWF::Validate::Hooks::command_is_rooted($c) -> bool          # pure; the D1 predicate
```
`command_is_rooted` is factored out as a named, separately-callable sub so the predicate can
be unit-tested as a pure string function. Testability leads the design priorities, and
`validate($git_root)` alone would force every string case (TC-1/2/3/5) to build a temp-file
and git-root scaffold to assert one boolean. Both are `@EXPORT_OK` (export by request,
matching the precedent); `cmd_validate` calls `validate` fully-qualified.

Each violation:
```
{ category => 'HOOKS',
  file     => '.claude/settings.json',      # repo-relative
  field    => 'hook-command',               # or 'json-parse'
  actual   => '<the offending command string>',
  expected => '${CLAUDE_PROJECT_DIR}/-rooted .cwf path',
  fix      => 'Re-run .cwf/scripts/command-helpers/cwf-claude-settings-merge to re-link …' }
```

**`actual` is an untrusted display string.** It echoes a command verbatim from a settings
file — and `settings.local.json` is user-owned and gitignored. `cwf-manage validate` output
is human-facing and this content is already readable by anyone who can read the file, so the
risk is low, but the value must never be piped back into agent context (same rule as the
tool-check hook's `--check` output) and must never be re-executed. FR4(c): it is reflected
data, not a CWF-authored string.

### Predicate
```perl
# A .cwf/ reference must be rooted at the project dir. Fixed-width lookbehind.
$command =~ m{(?<!\$\{CLAUDE_PROJECT_DIR\}/)\.cwf/}
```

### Error-handling idiom
`JSON::PP` *throws* on malformed input, so step 3 requires a catch. `Try::Tiny` is not core
and native `try`/`catch` needs Perl 5.34+; both collide with the core-only, system-Perl
constraint. `eval` is therefore the correct realisation — used as:

- capture the decode **result** and gate on `ref $decoded eq 'HASH'`, not on the truthiness
  of `$@` (a false-but-defined error is a classic false-negative)
- assign `$@` to a lexical immediately if its text is needed, before any other call can
  clobber it

This mirrors `read_layer_file` in the tool-check hook, which already degrades a bad layer to
"contributes nothing" by exactly this shape.

### Test cases (specified here, detailed in e-testing-plan.md)
Pure-predicate cases call `command_is_rooted` directly:
- **TC-1**: bare `.cwf/scripts/hooks/x` → violation
- **TC-2**: `${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/x` → clean
- **TC-3**: the live rules-inject command shape (prefix mid-string) → clean *(guards D1)*
- **TC-5**: absolute `/abs/repo/.cwf/…` → violation *(documents the D1 trade-off)*
- **TC-5b**: unbraced `$CLAUDE_PROJECT_DIR/.cwf/…` → violation *(pins the accepted
  false positive, so a future change to it is a deliberate choice, not a surprise)*

Fixture-tree cases call `validate($fixture_root)`:
- **TC-4**: a `permissions.allow` entry `Bash(.cwf/…)` alongside a clean `hooks` tree →
  clean *(guards D2 — the whole point is that `permissions` is not scanned)*
- **TC-6**: malformed JSON → one `json-parse` violation, no die
- **TC-6b**: present-but-unreadable settings file → one `json-parse` violation, no die
- **TC-7**: a fixture tree in the canonical generated form → clean

Source-assertion cases:
- **TC-8**: `stop-hooks-framework.md` contains no bare-relative hook **command** — the grep
  must be scoped to the `"command": ".cwf/` context. The file legitimately mentions bare
  `.cwf/scripts/hooks/…` in prose (lines 115, 138) as *file-path references*; a whole-file
  grep would fail TC-8 forever, even after the fix. *(guards D5)*
- **TC-9**: `cwf-claude-settings-merge` source contains the literal `${CLAUDE_PROJECT_DIR}/`
  — fails if the generator stops emitting the canonical prefix *(guards D5)*

**TC-7 runs against a committed fixture, never the live `$git_root`.** The live tree
includes the gitignored, machine-specific `.claude/settings.local.json`; a contributor whose
local file happened to carry a bare-relative hook command would see the suite fail through
no fault of the change under test. Live-tree cleanliness is separately assured by the
`cwf-manage validate` run in the checkpoint commit — which is the real acceptance signal.

## Constraints
- Perl core only (`JSON::PP` is core); no new dependencies
- The new module and `t/validate-hooks.t` both carry `use strict; use warnings; use utf8;`
  — matching the precedent and `docs/conventions/perl.md` (the `use utf8;` pragma is
  unconditional here, a deliberate CWF convention, not gated on present non-ASCII bytes)
- `eval`, not `Try::Tiny` or native `try` — see §Error-handling idiom
- Hashed-file edits, disclosed at plan time: `.cwf/scripts/cwf-manage` (0700) and the new
  `.cwf/lib/CWF/Validate/Hooks.pm` (`100644`, no `permissions` key — it is a `use`d module,
  not an executable). Refresh `.cwf/security/script-hashes.json` in the same commit.
  `.cwf/install-manifest.json` needs no edit: it does not enumerate lib modules (the
  precedent `Agents.pm` is absent from it and ships correctly — the `.cwf/` tree installs
  wholesale).
- The hook's own fail-open posture is deliberate and untouched by this task

## Decomposition Check
- [ ] **Time**: >1 week? No
- [ ] **People**: >2 people? No
- [ ] **Complexity**: 3+ distinct concerns? No — one predicate, one wiring, one doc
- [ ] **Risk**: high-risk components needing isolation? No
- [ ] **Independence**: separable parts? Coupled by TC-8 on purpose

**Result**: 0 of 5 signals. No decomposition.

## Validation
- [x] Design review completed — 5 reviewers (improvements, misalignment, robustness,
      security, best-practice); 10 findings, all applied. Material corrections: the D5
      generator↔validator binding claim was false (TC-9 added); step 3 defended only decode
      failure, not `open` failure (whole class now covered); TC-7 was machine-dependent
      (now fixture-based); TC-8 would have over-fired on prose (now command-scoped —
      independently verified: prose at lines 115/138, command at 164); the predicate was
      not independently testable (`command_is_rooted` factored out).
- [x] Integration points verified (`cmd_validate` composition at `cwf-manage:607-615`;
      violation hashref shape matches `CWF::Validate::Agents`)
- [x] False-positive surface enumerated (D1, D2), covered by TC-3/TC-4/TC-5b
- [ ] Mechanical reference check: 0 findings

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
D1–D5 implemented as designed, unchanged. The predicate, the `hooks`-only scan scope, the
mirroring of `CWF::Validate::Agents`, the surface-never-repair posture, and the decision not to
touch the generator all survived implementation and two rounds of changeset review without
amendment. Three independent reviewers (improvements, misalignment, robustness) separately
confirmed the design's central judgements: that `read_json_file` is genuinely unsuitable (it
dies), that the degrade-not-die divergence from `Agents.pm` is correct, and that the absence
gate must stay in `validate`.

## Lessons Learned
The design phase's value was almost entirely in the two traps it identified before any code
existed. The natural invariant — "the command starts with `${CLAUDE_PROJECT_DIR}/`" — is false,
because the shipped rules-inject hook carries the prefix mid-string; a starts-with check would
have gone permanently red on a correct registration. And `permissions.allow` legitimately carries
bare `Bash(.cwf/…)` *match patterns*, so a whole-document scan would have fired on ~6 valid
entries. Either mistake would have got the validator switched off rather than fixed.

Plan review also caught a claim in this document that was simply false: that TC-3 bound the
generator and validator literals together. It does not — it tests a hardcoded string shape and
would keep passing if the generator changed. TC-9 exists because of that catch. Writing down
*why* an imprecision is accepted is what makes it reviewable; the false claim was only visible
because it had been stated explicitly.
