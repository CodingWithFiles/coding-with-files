# Refactor BACKLOG/CHANGELOG to heading-tree model - Maintenance
**Task**: 132 (feature)

## Task Reference
- **Task ID**: internal-132
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/132-refactor-backlog-changelog-to-heading-tree-model
- **Template Version**: 2.1

## Goal
Define the ongoing maintenance posture for the heading-tree
parser/validator/serialiser, the `backlog-manager` helper, and the
`cwf-backlog-manager` skill.

CWF is a self-contained git-tracked toolset, not a long-running service:
no uptime, latency, or business KPIs apply. Maintenance for this task
means three things — keeping the validator + parser honest, surfacing
adopter pain promptly, and protecting the round-trip property.

## Monitoring Requirements

### Build / Test Health
- **`prove t/`** — must stay green. Any regression in the 412-test
  baseline (or its successor) is a maintenance event. Watched
  implicitly via the project's pre-commit and `cwf-manage validate`
  gates.
- **`cwf-manage validate`** — must stay clean. The post-commit guard
  in `cwf-checkpoint-commit` catches drift inside CWF's own repo.
- **`backlog-manager validate`** — must exit 0 on the live `BACKLOG.md`
  and `CHANGELOG.md` after every task's retrospective phase. Drift
  shows up as new validator findings on a clean checkout.
- **`backlog-manager normalise --dry-run`** — must report
  `already canonical (no change)` on the live files between tasks.
  A non-no-op result means something has serialised non-canonical
  content (regression — see Common Issues).

### Round-trip Property
- The live-file round-trip tests (`t/backlog-roundtrip-live.t`,
  TC-ROUNDTRIP-LIVE-BACKLOG/CHANGELOG) are the canonical regression
  alarm. Any future parser/serialiser change that breaks
  byte-identity on the live files will fail these tests in CI.

### Performance
- Pre-refactor parse+validate baselines (Task 132): BACKLOG 2.19ms,
  CHANGELOG 3.97ms median (n=10). Post-refactor: 4.02ms / 7.49ms.
- NFR1 budget: ≤ 5× pre-refactor baseline (i.e. BACKLOG ≤ 10.95ms,
  CHANGELOG ≤ 19.85ms).
- No standing perf monitoring — re-measure only if a future task
  edits `CWF::Backlog` parser/validator paths or if a user reports
  noticeable delay on `backlog-manager` invocations.

### Alerting
Not applicable in the runtime sense. Functional equivalents:
- **Critical**: `prove t/` red on `main`, or live `validate` fails on
  `main` — block further work, root-cause immediately.
- **Warning**: a new task introduces a `backlog-manager` validator
  warning that wasn't there before — investigate at retrospective.
- **Info**: `normalise --dry-run` reports a change on a live file —
  some other tooling has rewritten the file non-canonically; track
  down the offender.

## Maintenance Tasks

### Per-task (every CWF task touching BACKLOG/CHANGELOG)
- After `/cwf-retrospective` updates the live files: run
  `.cwf/scripts/command-helpers/backlog-manager validate` once and
  confirm clean exit. (The skill workflow already does this implicitly
  via `cwf-manage validate`, but a focused run catches narrower
  regressions.)
- If the task added new validator rules, extend `t/backlog-tree-validate.t`
  with positive + negative coverage for each new rule. Maintain the
  100%-rule-coverage invariant set in Task 132.

### Ad-hoc
- If the parser changes shape (new entry slot, new subsection field):
  update `serialize_tree` symmetrically and add a new round-trip
  fixture under `t/fixtures/backlog-manager/heading-tree/`.
- If a new metadata key becomes canonical (e.g. another required
  field beyond `Task-Type`/`Priority`): update `BACKLOG-001`'s
  required-keys list, the canonicaliser in `cmd_normalise`, and the
  `@CANONICAL_SUBSECTIONS` constant if it's a subsection.
- External adopter upgrade: when a new release bumps the heading-tree
  schema (unlikely in the near term), document the diff in the
  release notes and ensure `normalise` handles the migration path.

### Not needed
- No database / index / cache to tune.
- No log rotation, backup validation, or capacity planning — files
  are git-tracked and adopter-owned.
- No security patching schedule beyond the project's general
  practice (no third-party dependencies were added).

## Incident Response

### Common Issues

- **Issue: `backlog-manager validate` reports a new error after a
  commit on `main`**
  - **Symptoms**: clean checkout, fresh `validate` invocation, fires
    one of the `BACKLOG-*` / `CHANGELOG-*` rules.
  - **Diagnosis**: `git log -p BACKLOG.md CHANGELOG.md` since the
    last clean commit; identify which task wrote the offending
    content.
  - **Resolution**: hand-fix the offending entry to canonical shape,
    then re-validate. If the offending writer is a CWF skill, file
    a bugfix task against that skill.

- **Issue: `normalise --dry-run` reports a non-no-op change**
  - **Symptoms**: the dry-run output names entries it would rewrite.
  - **Diagnosis**: inspect each named entry — typically a metadata
    key arrived in a non-canonical position (e.g. an interactive
    edit dropped a `### Status:` line *after* body content), or
    legacy `**Field**:` survived from an external import.
  - **Resolution**: run `backlog-manager normalise` (no `--dry-run`)
    to canonicalise, commit the result, and check whether the
    upstream writer needs fixing.

- **Issue: round-trip live test goes red**
  - **Symptoms**: `t/backlog-roundtrip-live.t` fails; bytes differ
    between read and `serialize_tree(parse_tree(read))`.
  - **Diagnosis**: this is Postel-strict-serialiser breaking. Either
    the parser captured something the serialiser doesn't emit
    symmetrically, or someone hand-edited the live file with a
    non-canonical detail (trailing whitespace, missing blank line)
    that the parser tolerates but the serialiser normalises away.
  - **Resolution**: if the live file is the offender, run `normalise`.
    If the parser/serialiser is the offender, fix the symmetry —
    either teach the parser to ignore the diff or teach the
    serialiser to preserve it.

### Escalation
Not applicable — single-maintainer project. The owner triages.

## Performance Optimisation

No standing optimisation work. The post-refactor numbers
(4.02ms / 7.49ms median) sit well inside the 5× NFR1 budget. If a
future task crosses the budget, candidate levers in priority order:
1. cache `_build_fence_map` per file rather than per validator (already
   done in Task 132 via the `_source_lines` / `_source_fence` slots);
2. skip serialisation in `validate_*_tree` when source bytes are
   already cached (already done);
3. defer subsection parsing to first-access in `metadata_node` /
   subsection getters.

No scaling strategy — synchronous single-process Perl tool.

## Documentation

### Runbooks
- `.claude/skills/cwf-backlog-manager/SKILL.md` — invocation reference
  for the seven subcommands plus the `cd $(git rev-parse --show-toplevel)`
  pre-step.
- `docs/conventions/perl-git-paths.md` — Perl + git path-handling
  conventions (`use utf8`, `-CDSL`, `git ... -z`).

### Knowledge base
- This task directory (`132-feature-refactor-backlog-changelog-to-heading-tree-model/`) — full design, implementation, and testing trail; preserved on the checkpoints branch by the retrospective phase.

## Success Criteria
- [ ] `prove t/` green and `cwf-manage validate` clean on every commit to `main`.
- [ ] `backlog-manager normalise --dry-run` reports `already canonical (no change)` on live files at the start of every new task.
- [ ] Validator rule coverage stays at 100% (every active rule has positive + negative tests).
- [ ] Round-trip live tests stay green.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results

- Maintenance posture: passive — no monitoring infrastructure, all signals piggyback on the existing test suite + `cwf-manage validate` + `backlog-manager validate`/`normalise --dry-run`.
- No follow-up tasks identified at this stage. AC4 grep tightening (file-wide → metadata-position-only) noted in g-testing-exec is a candidate for a small chore task but not blocking.

## Lessons Learned
- The maintenance posture for this kind of toolset is inverted vs the template's assumption: signals are "test suite stays green + `validate` stays clean + `normalise --dry-run` stays no-op", not uptime/latency/error-rate. Worth explicit in the template.
- `backlog-manager normalise --dry-run` is the right canary for non-canonical drift introduced by other tooling — quick to run, idempotency-checking, no-op when healthy.
