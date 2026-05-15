# re-align Perl-script conventions to Task-27 form - Plan
**Task**: 139 (bugfix)

## Task Reference
- **Task ID**: internal-139
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/139-re-align-perl-script-conventions-to-task-27-form
- **Baseline Commit**: 4630568310e334935d50a268962731d98956b6b0
- **Template Version**: 2.1

## Goal
Revert the 11 `#!/usr/bin/perl -CDSL` shebangs to the original `#!/usr/bin/env perl` + `PERL5OPT=-CDSLA` form, invert the validator to enforce that form, and anchor the Perl conventions in CLAUDE.md so future drift is visible at the project entry point.

## Success Criteria
- [ ] All 11 hardcoded `#!/usr/bin/perl -CDSL` shebangs in `.cwf/scripts/` reverted to `#!/usr/bin/env perl`; `grep -R '^#!/usr/bin/perl' .cwf/scripts .cwf/lib` returns zero matches.
- [ ] `CWF::Validate::PerlConventions` inverted: rejects hardcoded `-C` shebangs, requires `env perl`, still enforces `use utf8;` and `-z` on path-emitting git captures. `t/validate-perl-conventions.t` and `t/common.t` pass.
- [ ] `docs/conventions/perl-git-paths.md` split into `docs/conventions/perl.md` (universal rules: shebang, PERL5OPT=-CDSLA, `use utf8;`) and `docs/conventions/git-path-output.md` (niche rules: `-z`, `split /\0/`, NUL-handling). Cross-referenced.
- [ ] CLAUDE.md `## Conventions` section anchors both new docs alongside `commit-messages.md` and `design-alignment.md`. Audit confirms no other project entry point (README.md, INSTALL.md, `.claude/rules/*`) is the right place for a load-bearing reference; if any is, references added.
- [ ] `cwf-manage validate` passes on the rebuilt tree; `.cwf/security/script-hashes.json` regenerated through the canonical procedure (not `recompute-hashes`-style smoothing) and the change is reviewable as a discrete commit.
- [ ] No inbound link in the repo points at the deleted `perl-git-paths.md` filename. Grep for `perl-git-paths` returns either zero hits or only this task's own files.

## Original Estimate
**Effort**: 1 day
**Complexity**: Medium
**Dependencies**: Task 137 closed (it is — squashed at `7500aef`). No external dependencies.

## Major Milestones
1. **Convention docs split + CLAUDE.md anchor** — Task A in the backlog entry. Independent of code; lands first because the validator's error message will cite the new doc paths.
2. **Validator inversion** — Rewrite `CWF::Validate::PerlConventions` to require `env perl`, reject hardcoded `-C`. Update fixtures.
3. **Shebang reverts + hash regeneration** — Flip the 11 scripts; regenerate `.cwf/security/script-hashes.json`. Verify `cwf-manage validate` clean.
4. **Inbound-reference audit** — Grep for `perl-git-paths`, `PERL5OPT=-CDSL[^A]`, and `#!/usr/bin/perl -CDSL` across the repo and fix every hit.

## Risk Assessment
### High Priority Risks
- **Hash regeneration as a smoothing anti-pattern**: 11 scripts changing shebangs will fail SHA256 verification. The instinct is to script "recompute all hashes"; that is exactly the surface-don't-smooth case ([[feedback_surface_security_dont_smooth]]). Hashes must be regenerated through the documented procedure as a discrete, reviewable commit at the end of the shebang-revert milestone.
  - **Mitigation**: Use the existing `cwf-manage fix-security` flow (or whatever the canonical regeneration path is — confirm during design). One commit, scoped to `.cwf/security/script-hashes.json` only, after all shebangs are flipped and tests pass.

- **Stale-PERL5OPT user environments**: Anyone whose `PERL5OPT` is still `-CDSL` (no `A`) re-introduces the Task 137 mojibake the moment they run `backlog-manager add` with non-ASCII bytes in `@ARGV`. The project recommendation needs to be visible enough that an adopter upgrading CWF actually updates their env.
  - **Mitigation**: Make `perl.md` lead with the `-CDSLA` recommendation and explain *why* the `A` matters (link Task 137). Surface the recommendation in `cwf-manage update` output if practical (defer to design phase).

### Medium Priority Risks
- **Validator-test polarity inversion**: `t/validate-perl-conventions.t` fixtures currently assert that hardcoded `-CDSL` is *valid* and `env perl` is *invalid* (for path-emitting scripts). Flipping the validator without flipping every fixture leaves a test passing on a stale assertion.
  - **Mitigation**: Read every fixture in the test before touching the validator; flip in lockstep. Add at least one new fixture explicitly asserting that `#!/usr/bin/perl -CDSL` is now rejected, with the rejection message naming the new doc path.

- **Inbound doc references**: Renaming `perl-git-paths.md` to two new files will break any link that targets it.
  - **Mitigation**: `git grep perl-git-paths` before the split; fix every hit as part of the docs-split milestone. Include `.cwf/templates/` and feedback memories in the grep scope.

### Low Priority Risks
- **Adopter upgrade surprise**: Adopters on a prior CWF version running `cwf-manage update` will see new validation errors (their scripts have the old shebang). This is the *intended* signal, not a defect — but it should be documented.
  - **Mitigation**: Note the breaking-validator change in the task's `h-rollout` equivalent (this is a bugfix template so no h-file; capture it in `j-retrospective.md` as a release-note candidate).

## Dependencies
- Task 137 (`7500aef`) — closed; this task subsumes its conceptual scope by fixing the root cause.
- No team dependencies (solo task).
- No external system dependencies.

## Constraints
- POSIX-only target — no platform-specific tooling in the regeneration procedure.
- Perl core modules only ([[feedback_perl_core_only]]) — applies to any helper or test scaffolding written here.
- Squashed-main / archaeological-branch methodology ([[project_archaeological_main]]) — checkpoint per phase, one squash commit on main at the end.

## Decomposition Check
- [ ] **Time**: ~1 day — under the 1-week threshold.
- [ ] **People**: 1 person, no parallelisation benefit.
- [ ] **Complexity**: Two concerns (docs structure, code/validator). They are tightly coupled: the validator's error message must cite the new doc path, so splitting forces an awkward intermediate state where the validator references a doc that doesn't exist yet. The backlog entry's "Task A is a prerequisite for Task B" framing maps to milestones inside this task, not separate tasks.
- [ ] **Risk**: Hash-regeneration risk is contained to one milestone; validator-inversion risk is contained to one milestone. Neither warrants isolation.
- [ ] **Independence**: Milestones are sequenced, not independent. Splitting would create coordination overhead without parallelisation benefit.

**Decision**: Single task, four sequenced milestones. No decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
