# cwf-init dead UserPromptSubmit hook matcher - Implementation Plan
**Task**: 195 (bugfix)

## Task Reference
- **Task ID**: internal-195
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/195-cwf-init-dead-userpromptsubmit-hook-matcher
- **Template Version**: 2.1

## Goal
Implement cwf-init dead UserPromptSubmit hook matcher following the approved design and requirements.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cwf/scripts/command-helpers/cwf-claude-settings-merge` (**security-hashed**) — register
  the rules-inject hook + migrate the dead entry:
  - Add constant `$CANONICAL_RULES_INJECT_CMD = 'cat .cwf/rules-inject.txt 2>/dev/null || true'`
    next to `$CANONICAL_PERL5OPT` (~line 297), **with the same compile-time-constant banner
    comment** as `$CANONICAL_PERL5OPT` (lines 293-297) — this string is a settings.json hook
    `command` that Claude Code executes on every prompt; it must never carry interpolated
    data (FR4(e)).
  - Add `sub prune_dead_userpromptsubmit_matcher($settings)` — defensive filter (see
    Code Changes) returning the count pruned.
  - In `main`: call the prune on `$settings` *after* `read_settings()` (current line 526)
    and *immediately before* the `merge_hooks` call (current line 528); push the synthetic
    `UserPromptSubmit` entry onto `$hook_entries` in the same window. **Capture the prune
    count and surface it in the stdout summary** (lines 546/552) — e.g. append
    "migrated N legacy hook entr…" — so a silent settings mutation never happens
    ([[feedback_surface_security_dont_smooth]]).
  - D4 (**optional consistency-hardening — separable from the fix**): widen the
    `read_hook_directives` event regex (line 106) from `/^(?:Stop|SubagentStop|PreToolUse)$/`
    to add `UserPromptSubmit`, and update the leading-comment enumeration (lines 13-16) and
    `usage()` (lines 41-43) — adding `UserPromptSubmit` **and** the already-missing
    `PreToolUse`. The synthetic entry is injected post-`partition_manifest` and does not pass
    through `read_hook_directives`, so this is trap-prevention for a hypothetical future
    directive-driven UserPromptSubmit hook, not required for this bug. Reviewers split on
    keep-vs-defer; carry the decision to the exec/review checkpoint. If deferred, capture as
    a one-line backlog note.
- `.claude/skills/cwf-init/SKILL.md` (step 6c, lines 107-128) — replace the hand-written
  JSON block + PreToolUse idempotency prose with a one-line pointer noting that step 6d
  (`cwf-claude-settings-merge`) now registers the rules-inject `UserPromptSubmit` hook and
  migrates any legacy dead entry. Preserve the step-6b-before-6d hard-ordering note
  (lines 99-102) and the 6c heading.

### Supporting Changes
- `.cwf/security/script-hashes.json` — **mandatory same-commit sha256 refresh** for
  `cwf-claude-settings-merge` ([[hash-updates]]): `sha256sum` the edited file, replace its
  `sha256` entry. Pre-refresh, run `git log <last-hash-commit>..HEAD -- <path>` to confirm
  no unrelated drift. (Confirm at f-exec that no *other* hashed path is touched — grep
  `script-hashes.json` for both modified paths; SKILL.md lives under `.claude/`, outside the
  `.cwf/scripts/` manifest prefix, so it is expected to be unhashed — verify.)
- `t/cwf-claude-settings-merge.t` — new subtests (see Test Coverage).

## Implementation Steps
### Step 1: Setup
- [ ] On branch `bugfix/195-...`; re-read c-design-plan D1–D5 and confirm D5 resolution
      (keep-and-fix vs prune-only) with the user before coding.
- [ ] `grep` `.cwf/security/script-hashes.json` for `cwf-claude-settings-merge` and
      `cwf-init` to confirm exactly which paths need a hash refresh.

### Step 2: Core Implementation (helper)
- [ ] Add `$CANONICAL_RULES_INJECT_CMD` constant.
- [ ] Widen `read_hook_directives` event allowlist to include `UserPromptSubmit`; update
      header comment + `usage()` enumerations (doc-surface, per robustness review).
- [ ] Add `prune_dead_userpromptsubmit_matcher` with full defensive guards.
- [ ] Wire prune-before-merge and synthetic-entry injection into `main`.

### Step 3: Testing (see e-testing-plan.md for the full matrix)
- [ ] Add unit subtests mirroring TC-M1/M3/U3 patterns (fresh-add, migration, idempotent
      re-run, defensive malformed-settings, shape interaction).
- [ ] `prove -v t/cwf-claude-settings-merge.t` green; run the full `t/` suite for regressions.
- [ ] Output-level smoke test: run `cwf-claude-settings-merge` in a scratch dir seeded with
      the dead entry; assert the resulting `settings.json` shape by eye.

### Step 4: SKILL.md + docs
- [ ] Rewrite step 6c to the 6d pointer; verify ordering note + success-criteria line
      (SKILL.md line 173 "Rule re-injection hook configured") still read correctly.

### Step 5: Validation
- [ ] Restore helper working perms to the **recorded** value (0500, not 0700) after edit
      ([[feedback_hashed_script_working_perms]]).
- [ ] Refresh `script-hashes.json` sha256 in the same commit; `cwf-manage validate` clean.
- [ ] `cwf-manage fix-security --dry-run` reports no permission drift.

## Code Changes
### `prune_dead_userpromptsubmit_matcher` (new sub — defensive, never dies)
```perl
# Migrate away the dead PreToolUse/UserPromptSubmit entry that pre-fix /cwf-init
# wrote (a matcher group under PreToolUse whose matcher == 'UserPromptSubmit' can
# never fire). Matcher-scoped: every other PreToolUse group is preserved. Best-
# effort over hand-edited settings — tolerate any malformed shape, never die.
sub prune_dead_userpromptsubmit_matcher {
    my ($settings) = @_;
    return 0 unless ref $settings->{hooks} eq 'HASH';
    my $groups = $settings->{hooks}{PreToolUse};
    return 0 unless ref $groups eq 'ARRAY';
    my $before = scalar @$groups;
    @$groups = grep {
        !( ref($_) eq 'HASH'
           && defined $_->{matcher} && !ref $_->{matcher}
           && $_->{matcher} eq 'UserPromptSubmit' )
    } @$groups;
    delete $settings->{hooks}{PreToolUse} unless @$groups;
    return $before - scalar @$groups;
}
```

### `main` wiring (after `read_settings()` line 526, immediately before `merge_hooks` line 528)
```perl
my $pruned = prune_dead_userpromptsubmit_matcher($settings);   # migrate legacy dead entry
push @$hook_entries, {                               # D1/D3 fixed rules-inject hook
    entry   => { type => 'command', command => $CANONICAL_RULES_INJECT_CMD },
    event   => 'UserPromptSubmit',
    matcher => undef,
};
my $hook_added = merge_hooks($settings, $hook_entries);
# ... and fold $pruned into the stdout summary lines (546/552) so the migration is visible.
```
(`merge_hooks` + `find_or_make_group(undef)` then emit the correct group-wrapper shape
`"UserPromptSubmit": [ { "hooks": [ { type, command } ] } ]` and dedupe per-event.)

### If D5 resolves to prune-only (contingency)
Drop `$CANONICAL_RULES_INJECT_CMD` and the synthetic-entry `push`; keep only
`prune_dead_userpromptsubmit_matcher` + its summary line; SKILL.md step 6c becomes a plain
deletion note (no hook is registered). D4 and the hash/perms/test work are unchanged.

### SKILL.md step 6c (after)
```markdown
### 6c. Rule Re-Injection Hook (registered by step 6d)
The rules-inject `UserPromptSubmit` hook (`cat .cwf/rules-inject.txt …`) is registered
automatically by `cwf-claude-settings-merge` in step 6d, which also migrates away the
legacy dead `PreToolUse`/`UserPromptSubmit` entry from earlier installs. No manual JSON
edit here. (Step 6b must run first so `.cwf/rules-inject.txt` is in place — see above.)
```

## Test Coverage
**See e-testing-plan.md for complete test plan** — summary: fresh-add creates
`hooks.UserPromptSubmit` group-wrapper (assert the exact shape, not just command presence);
dead-entry migration removes the PreToolUse group while preserving a sibling `Edit|Write`
group **and** surfaces the pruned count in stdout; idempotent re-run adds 0; malformed
`PreToolUse` (non-array / non-hash group / missing matcher) does not die; index-0
matcher-bearing UserPromptSubmit group interaction **asserts the resulting shape + dedupe**
(not merely "doesn't crash"); `--dry-run` writes nothing.

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None — D5 resolved keep-and-fix, D4 resolved keep-in-task (user 2026-06-12).
The prune-only contingency does not apply; D4 allowlist widening + TC-UPS8 are in scope.

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned steps executed (keep-and-fix + keep-D4): `$CANONICAL_RULES_INJECT_CMD` with
FR4(e) banner, event-allowlist widening + header/usage docs, `prune_dead_userpromptsubmit_matcher`,
prune-before-merge wiring, synthetic-entry injection, prune count surfaced in stdout, same-commit
sha256 refresh. One unplanned-but-expected fixture change: TC-U1/TC-U4 hook-entry count 1→2
(direct consequence of the now always-on hook). No deviations.

## Lessons Learned
Naming the top-risk mitigation as a concrete test in the plan (scope the prune to the exact
dead group + a sibling-preservation regression) made it un-skippable — TC-UPS2 implemented it
verbatim. Plan-time hash-refresh disclosure ([[hash-updates]]) kept the integrity step from
being deferred.
