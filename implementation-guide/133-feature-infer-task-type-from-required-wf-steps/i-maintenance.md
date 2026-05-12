# Infer task type from required wf steps - Maintenance
**Task**: 133 (feature)

## Task Reference
- **Task ID**: internal-133
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/133-infer-task-type-from-required-wf-steps
- **Template Version**: 2.1

## Goal
Define the ongoing-care obligations introduced by this change. The
short version: there are very few.

## Monitoring

There is no production system, no service, no telemetry pipeline. The
"monitoring" surface is:

- **Drift alarm**: `t/task-type-inference-rubric.t`. Asserts that the
  rubric's canonical-step-set table matches the actual
  `.cwf/templates/<type>/` filenames for every type listed in
  `cwf-project.json:supported-task-types`. Runs as part of `prove t/`
  on every CWF task's testing-exec phase, so any future change that
  drops a template file or adds an unregistered type fails the suite
  before merge.
- **User-feedback signal**: in normal use, a misinference shows up as
  the user immediately re-creating a task with an explicit type after
  the 2-arg form picked the wrong one. No instrumentation; the user
  is the monitor.

## Alerting

None configured. The drift test is the only automated alarm and it
fires through the existing prove suite — there is no out-of-band
notification channel because there is no out-of-band consumer.

## Maintenance Schedule

No recurring obligations. Specifically:

- **No cron jobs.** Nothing needs to run periodically.
- **No log-rotation, no dashboard, no on-call rota.**
- **No deprecation window.** The 3-arg form continues to work
  indefinitely; the 2-arg form is additive.
- **No tracked-for-removal flag.** Nothing in this task is
  feature-flagged.

The rubric content itself may need iterative tuning if user feedback
shows the discriminating-questions text mis-classifies edge cases. That
is one-shot copyediting of `.cwf/docs/skills/task-type-inference.md`,
not a recurring maintenance task.

## Adding a New Task Type (Operational Runbook)

When a future task wants to introduce a new type (e.g. `spike`):

1. Create `.cwf/templates/<new-type>/` containing template symlinks
   into `.cwf/templates/pool/` for whichever wf steps the type
   should require. The Always-Required Steps section of the rubric
   lists `a, d, e, f, g, j` as the minimum.
2. Add `<new-type>` to
   `implementation-guide/cwf-project.json:supported-task-types`. The
   `template-copier-v2.1::validate_task_type` gate refuses any type
   not in this list.
3. Add a row to the canonical-step-set table in
   `.cwf/docs/skills/task-type-inference.md`: `<new-type> |
   (b,c,h,i tuple) | <comma-separated step letters>`.
4. Run `prove t/task-type-inference-rubric.t` to confirm the three
   edits agree. The drift test fails if any of the three is missing
   or mismatched.

If the new type has the same `(b,c,h,i)` tuple as an existing type
(e.g. both `spike` and `chore` are `(0,0,0,0)`), descriptions that
infer to that tuple will trigger the ambiguity prompt rather than
picking silently. This is intentional — there is no a-priori way for
the rubric to disambiguate two types with identical step sets.

## Common Issues and Resolutions

### Inference picks the wrong type silently
- **Symptom**: 2-arg invocation produces a task directory whose type
  feels off; user wants e.g. `feature` but got `chore`.
- **Cause**: the description didn't carry enough signal for `b`, `c`,
  `h`, or `i` to be marked yes. The rubric's discriminating questions
  are conservative — they require explicit cues.
- **Resolution**: re-run with the explicit 3-arg form. If the pattern
  recurs across multiple tasks, file a follow-up to refine the
  discriminating-questions prose.

### Drift test fails after adding a new task type
- **Symptom**: `prove t/task-type-inference-rubric.t` red on assertion
  3 (canonical table vs templates).
- **Cause**: one of the three coordinated edits in the runbook above
  was missed.
- **Resolution**: diff the rubric's canonical-step-set rows against
  `ls .cwf/templates/*/` output; whichever side is missing entries is
  the side to fix.

### Ambiguity prompt appears more often than expected
- **Symptom**: typical descriptions trigger the prompt every time.
- **Cause**: the rubric's discriminating questions may be too biased
  toward "include this step", or the description style at the
  invocation site is unusually terse.
- **Resolution**: edit the rubric's discriminating-questions section
  to make the "skip" criteria more inclusive. The rubric is markdown;
  no code change needed.

## Performance

No measurable performance footprint. The 2-arg form adds one Read of a
~150-line markdown file per task creation; the 3-arg form has no
overhead at all. Task creation is a once-per-day-at-most operation, so
optimisation isn't on the table.

## Security

The change introduces no new attack surface. The rubric path is a
hard-coded literal in both SKILL.md files, the inference's
type-selection gate is a finite-set lookup against the rubric's
canonical table, and no new env vars or helper scripts are added.
Threat coverage detailed in c-design-plan.md § Security Threat
Coverage and the f/g security review records.

## Follow-Up Items

Surfaced during the task; not blocking, captured here so they're not
lost when the BACKLOG entry retires:

- The design's distance-≥3 degenerate-inference branch is dead code
  under the current 5-type taxonomy. If the taxonomy ever grows to
  cover more `(b,c,h,i)` corners, this branch becomes live; until
  then, consider trimming the rubric's "Resolution Algorithm" step 6
  to a one-line "unreachable given current canonical set" footnote.
  Logged in CHANGELOG Task 133 § Notable.
- The security-review subagent failed sentinel-first protocol in both
  f and g (preamble before `findings:`/`no findings`/`error:`). This
  is a recurring pattern worth a backlog item if it shows up in
  future tasks too. Not adding a BACKLOG entry yet — pending
  second occurrence in another task before declaring a pattern.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
