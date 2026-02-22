# readme-updates - Design
**Task**: 91 (bugfix)

## Task Reference
- **Task ID**: internal-91
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/91-readme-updates
- **Template Version**: 2.1

## Goal
Specify the exact content replacement for each of the 5 README.md change areas.

---

## Change 1: Install URL (line 59)

**Old**:
```
curl -fsSL https://raw.githubusercontent.com/mattkeenan/coding-with-files/main/scripts/install.bash | bash
```
**New**:
```
curl -fsSL https://raw.githubusercontent.com/CodingWithFiles/coding-with-files/main/scripts/install.bash | bash
```

---

## Change 2: Workflow Commands section (lines 70–101)

Replace the entire `## Commands` section. Key decisions:
- Remove "v2.0" labels — v2.0 is deprecated, just call it CWF
- Add `/cwf-implementation-exec` and `/cwf-testing-exec`
- Drop "Breaking change" callouts (no longer relevant — v1.0 is the baseline)
- Describe the 10-phase v2.1 workflow accurately

**New section**:

```markdown
## Commands

### Core Commands

- `/cwf-init` - Initialise CWF system with project configuration
- `/cwf-new-task <num> <type> "description"` - Create hierarchical implementation guide
- `/cwf-subtask <parent-path> <num> <type> "description"` - Create subtask with context inheritance
- `/cwf-status [task-path]` - Show progress across implementation guide hierarchy
- `/cwf-extract <task-path> <section-name>` - Extract section from implementation guide

### Workflow Commands

Execute structured workflow phases for any task. Phases are split into planning and
execution steps — plan first, then execute separately:

- `/cwf-task-plan <task-path>` - Planning phase (goals, milestones, risks)
- `/cwf-requirements-plan <task-path>` - Requirements phase (FR/NFR, acceptance criteria)
- `/cwf-design-plan <task-path>` - Design phase (architecture, components, interfaces)
- `/cwf-implementation-plan <task-path>` - Implementation plan (files to change, steps)
- `/cwf-implementation-exec <task-path>` - Implementation execution (write the code)
- `/cwf-testing-plan <task-path>` - Testing plan (test strategy, test cases)
- `/cwf-testing-exec <task-path>` - Testing execution (run tests, record results)
- `/cwf-rollout <task-path>` - Rollout phase (deployment, monitoring, rollback plan)
- `/cwf-maintenance <task-path>` - Maintenance phase (support, optimisation)
- `/cwf-retrospective <task-path>` - Retrospective phase (variance, learnings)

### Utility Commands

- `/cwf-config [init|list|reset]` - Configure CWF system paths and settings
- `/cwf-security-check [verify|report]` - Verify file integrity and sources for CWF system
```

---

## Change 3: Task Types section (lines 104–121)

Replace with accurate v2.1 phase file lists. Authoritative source: `.cwf/templates/<type>/`.

**Phase files per type**:
- **Feature** (10 phases): a-task-plan, b-requirements-plan, c-design-plan,
  d-implementation-plan, e-testing-plan, f-implementation-exec, g-testing-exec,
  h-rollout, i-maintenance, j-retrospective
- **Bugfix** (7 phases): a-task-plan, c-design-plan, d-implementation-plan,
  e-testing-plan, f-implementation-exec, g-testing-exec, j-retrospective
- **Hotfix** (7 phases): a-task-plan, d-implementation-plan, e-testing-plan,
  f-implementation-exec, g-testing-exec, h-rollout, j-retrospective
- **Chore** (6 phases): a-task-plan, d-implementation-plan, e-testing-plan,
  f-implementation-exec, g-testing-exec, j-retrospective

**New section**:

```markdown
## Task Types

Each task type runs a subset of the 10 available workflow phases, matched to its scope.
Phases are always split into a planning step and a separate execution step.

### Feature Tasks (10 phases)
Full development lifecycle: plan → requirements → design → implementation plan →
implementation exec → testing plan → testing exec → rollout → maintenance → retrospective

### Bugfix Tasks (7 phases)
plan → design → implementation plan → implementation exec → testing plan →
testing exec → retrospective

### Hotfix Tasks (7 phases)
plan → implementation plan → implementation exec → testing plan →
testing exec → rollout → retrospective

### Chore Tasks (6 phases)
plan → implementation plan → implementation exec → testing plan →
testing exec → retrospective
```

---

## Change 4: Version Information section (lines 181–189)

**New section**:

```markdown
## Version Information

CWF uses `v{major}.{minor}.{task_num}` semver tags:
- **major**: breaking changes (wf file format, removed features, install incompatibilities)
- **minor**: new user-visible features (new skills, workflow phases, helper scripts)
- **patch**: CWF task number of the most recently completed task at time of tagging

Run `cwf-manage list-releases` to see available upgrades from the configured source.
Run `git describe --tags --always` for the current working-tree version.
```

---

## Change 5: Support section (lines 208–210)

**Old**:
```
For issues and feature requests, please use the project's issue tracking system as configured in `cwf-project.json`.
```
**New**:
```
For issues and feature requests, please open a GitHub issue:
https://github.com/CodingWithFiles/coding-with-files/issues
```

---

## Decomposition Check
No — single file, 5 targeted edits.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 91
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 5 designed changes applied. TC-3 revealed a 6th site (Features section heading) not captured here.

## Lessons Learned
Run absence-greps at design time to find all change sites before finalising the design.
