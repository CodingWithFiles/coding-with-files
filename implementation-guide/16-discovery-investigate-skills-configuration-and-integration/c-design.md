# investigate skills configuration and integration - Design

## Task Reference
- **Task ID**: internal-16
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/16-investigate-skills-configuration-and-integration
- **Template Version**: 2.0

## Goal
Design the Phase 7 decision framework for evaluating 4 integration options (Plugin, Skills-Only, Commands, Hybrid) with 6 weighted criteria reflecting findings from RQ1-RQ8.

**Note**: This is a discovery task. Design focuses on investigation architecture. Components 1-2-4 (Test Skill, Integration Testing, Research Documentation) completed in Phases 1-6. Phase 7 requires updated Component 3 (Decision Framework) reflecting RQ6-RQ8 findings.

## Design Priorities
1. **Testability** - Test skill must be easily testable and reproducible
2. **Readability** - Documentation must be clear and evidence-based
3. **Consistency** - Follow SKILL.md patterns from reference implementations
4. **Simplicity** - Minimal viable test skill, avoid over-engineering
5. **Reversibility** - All changes easily undoable without breaking CIG

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Investigation Architecture

### Component 1: Test Skill Structure
**Purpose**: Validate understanding of SKILL.md format and hooks system (RQ1, RQ2, RQ5)

**Directory Structure**:
```
.claude/skills/test-cig-skill/
├── SKILL.md                    # Minimal skill definition
├── scripts/
│   ├── session-init.sh         # SessionStart hook test
│   ├── pre-tool-check.sh       # PreToolUse hook test
│   ├── post-tool-notify.sh     # PostToolUse hook test
│   └── stop-cleanup.sh         # Stop hook test
└── references/
    └── hook-observations.md    # Document hook trigger behavior
```

**Rationale**:
- Follows observed patterns from existing skills implementations
- Each hook type gets dedicated script for isolated testing
- Observations file captures empirical evidence
- No templates/ directory initially (add only if needed)

**Trade-offs**:
- ✅ Pros: Simple, observable, self-documenting through hook-observations.md
- ✅ Pros: Tests all 4 hook types independently
- ✅ Pros: Uses validated ${CLAUDE_PLUGIN_ROOT} pattern
- ⚠️ Cons: Doesn't test complex hook interactions (acceptable for discovery)
- ⚠️ Cons: Relies on user observing echo output (acceptable for manual testing)

### Component 2: Integration Testing Framework
**Purpose**: Test skills/commands coexistence (RQ4)

**Directory Structure**:
```
.claude/skills/cig-status/
├── SKILL.md                    # Minimal skill for conflict testing
└── (no scripts - minimal skill)
```

**Testing Protocol**:
1. Keep existing `.claude/commands/cig-status.md` unchanged
2. Create `.claude/skills/cig-status/SKILL.md`
3. Invoke `/cig-status` and observe which executes
4. Document precedence behavior
5. Remove test skill after observation

**Rationale**:
- Direct empirical test of precedence (evidence-based)
- Uses existing CIG command (known behavior baseline)
- Non-destructive (removal is simple)
- Clear pass/fail criteria (which system responds)

**Trade-offs**:
- ✅ Pros: Definitive answer to precedence question
- ✅ Pros: Uses real CIG command for realistic test
- ⚠️ Cons: Temporarily creates naming conflict (acceptable for controlled test)
- ⚠️ Cons: Requires manual invocation by user (acceptable for discovery)

### Component 3: Decision Framework (Updated for Phase 7)
**Purpose**: Evaluate 4 integration approaches systematically with findings from RQ1-RQ8

**4 Integration Options** (Expanded from 3 based on RQ6-RQ8 findings):

| Option | Description | Hooks | Portability | CIG Impact |
|--------|-------------|-------|-------------|------------|
| **1. Convert to Plugin** | Full migration to `.claude/plugins/cig/` | ✅ Yes (full infrastructure) | ❌ Claude-only | High (15+ commands) |
| **2. Convert to Skills-Only** | Migration to Agent Skills standard | ❌ No (until standardization) | ✅ Agent-neutral | High (15+ commands) |
| **3. Keep Commands** | Status quo `.claude/commands/` | ❌ No | ❌ Claude-only | None |
| **4. Hybrid Plugin** | Plugin + commands coexist | ✅ Yes (selective) | ⚠️ Partial | Medium (5-10 commands) |

**Key Insight**: RQ6 revealed plugin vs skill-only distinction - hooks only work in `.claude/plugins/` mode, not `.claude/skills/` mode.

**6 Weighted Evaluation Criteria** (Updated from 5):

| Criterion | Weight | Description |
|-----------|--------|-------------|
| **Reversibility** | 3 | Can we undo without breaking CIG? |
| **Token Efficiency** | 2 | Progressive disclosure savings |
| **Hooks Value** | 3 | Automation via lifecycle events (renamed from "Feature Value") |
| **Portability** | 2 | Agent-neutral vs Claude-only (NEW - from RQ7) |
| **Migration Risk** | 3 | Conversion complexity and rollback safety |
| **Technology Maturity Risk** | 2 | Adopting emerging vs mature technology (NEW - from RQ7) |

**Total Max Score**: 75 (weights sum: 15 × max score: 5)

**Scoring Guidance per Criterion**:

**Reversibility** (Weight: 3):
- 5: No changes (Keep Commands)
- 3: Hybrid (can remove plugin, keep commands)
- 1: Full conversion (plugin or skills-only, high rollback risk)

**Token Efficiency** (Weight: 2):
- 5: Progressive disclosure enabled (Plugin, Skills-Only, Hybrid)
- 1: No progressive disclosure (Keep Commands)

**Hooks Value** (Weight: 3):
- 5: Hooks enabled (Plugin, Hybrid)
- 3: No hooks now, but coming via standardization 6-24mo (Skills-Only)
- 1: No hooks ever (Keep Commands)

**Portability** (Weight: 2):
- 5: Agent-neutral (Skills-Only - Agent Skills standard Dec 18, 2025)
- 3: Partial portability (Hybrid - some commands work everywhere)
- 1: Claude-only (Plugin, Keep Commands)

**Migration Risk** (Weight: 3):
- 5: No migration (Keep Commands)
- 3: Partial migration (Hybrid - gradual rollout)
- 1: Full migration (Plugin, Skills-Only - all 15+ commands)

**Technology Maturity Risk** (Weight: 2):
- 5: No maturity risk (Keep Commands - proven technology, no dependency on emerging features)
- 3: Moderate risk (Plugin/Hybrid - hooks ecosystem still maturing, potential for API changes as standards evolve)
- 1: High risk (Skills-Only - betting on future hooks standardization that hasn't materialized yet)

**Rationale**:
- Weighted scoring prevents gaming single criterion
- Explicit calculations show work (reviewable)
- Documentation template ensures completeness
- 4 options vs 3 provides clearer choice space (plugin vs skills-only distinction)
- Portability criterion reflects Agent Skills open standard reality (RQ7)
- Technology Maturity Risk criterion reflects hooks ecosystem maturity and standardization uncertainty (RQ7)

**Trade-offs**:
- ✅ Pros: Systematic, evidence-based, reviewable
- ✅ Pros: Weighted criteria align with CIG priorities and RQ1-RQ7 findings
- ✅ Pros: 4 options provide clearer choice space (plugin vs skills-only distinction)
- ✅ Pros: Portability criterion reflects Agent Skills open standard adoption
- ✅ Pros: Technology Maturity Risk criterion reflects hooks ecosystem maturity
- ⚠️ Cons: More complex scoring (6 criteria vs 5, 4 options vs 3)
- ⚠️ Cons: Technology Maturity Risk scoring subjective (standardization timeline uncertain)
- ⚠️ Cons: Assumes we can quantify trade-offs (mitigated by qualitative notes)

### Component 4: Research Documentation Strategy
**Purpose**: Answer RQ1-RQ3 with evidence

**Documentation Structure**:
- RQ1: SKILL.md Format Understanding (frontmatter fields, body content, bundled resources)
- RQ2: Hooks System Mechanics (4 hook types with trigger conditions and examples)
- RQ3: Progressive Disclosure Pattern (information hierarchy, token efficiency measurements)

**Rationale**:
- Evidence-based (links to actual files, observations)
- Structured (same format for each RQ)
- Quantified where possible (token counts, measurements)
- Repeatable (others can verify by reading linked evidence)

**Trade-offs**:
- ✅ Pros: High documentation quality (NFR3)
- ✅ Pros: Future reference value
- ⚠️ Cons: Time-intensive documentation (acceptable for discovery)

## Data Flow

**Phase 1: Research** (Read-only)
```
Planning-with-files (local) → Read → RQ1/RQ2/RQ3 documentation → d-implementation.md
Reference docs → WebSearch → RQ1/RQ2/RQ3 documentation → d-implementation.md
```

**Phase 2: Experimentation** (Test creation)
```
Test-cig-skill design → Write SKILL.md + scripts → User invocation → hook-observations.md
Observations → Read → RQ2/RQ5 documentation → d-implementation.md
```

**Phase 3: Integration Testing** (Coexistence)
```
Conflict skill → Write SKILL.md → User invocation → Observe precedence
Precedence results → RQ4 documentation → d-implementation.md → Decision matrix
```

**Phase 4: Analysis** (Decision)
```
All RQ documentation → Decision matrix → Scoring → Recommendation
Recommendation → Implementation roadmap → d-implementation.md
```

## Interface Design

### Test Skill SKILL.md (Frontmatter)
```yaml
name: test-cig-skill
version: "0.1.0"
description: Test skill for validating CIG understanding of skills system
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Bash
hooks:
  SessionStart:
    - hooks:
        - type: command
          command: "echo '[test-cig-skill] SessionStart triggered' && ${CLAUDE_PLUGIN_ROOT}/scripts/session-init.sh"

  PreToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/scripts/pre-tool-check.sh"

  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/scripts/post-tool-notify.sh"

  Stop:
    - hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/scripts/stop-cleanup.sh"
```

### Hook Scripts (Bash)

**session-init.sh**:
```bash
#!/usr/bin/env bash
echo "[Hook Test] SessionStart executed at $(date)"
echo "CLAUDE_PLUGIN_ROOT: ${CLAUDE_PLUGIN_ROOT}"
mkdir -p "${CLAUDE_PLUGIN_ROOT}/references"
echo "## Session Start: $(date)" >> "${CLAUDE_PLUGIN_ROOT}/references/hook-observations.md"
```

**pre-tool-check.sh**:
```bash
#!/usr/bin/env bash
echo "[Hook Test] PreToolUse triggered"
echo "Tool: $1, Args: $2"
echo "- PreToolUse: Tool=$1 at $(date)" >> "${CLAUDE_PLUGIN_ROOT}/references/hook-observations.md"
```

**post-tool-notify.sh**:
```bash
#!/usr/bin/env bash
echo "[Hook Test] PostToolUse completed"
echo "- PostToolUse: Completed at $(date)" >> "${CLAUDE_PLUGIN_ROOT}/references/hook-observations.md"
```

**stop-cleanup.sh**:
```bash
#!/usr/bin/env bash
echo "[Hook Test] Stop hook triggered"
echo "## Session End: $(date)" >> "${CLAUDE_PLUGIN_ROOT}/references/hook-observations.md"
echo "Total hook executions: $(grep -c 'Hook Test' "${CLAUDE_PLUGIN_ROOT}/references/hook-observations.md")"
```

### Conflict Test Skill SKILL.md
```yaml
name: cig-status
version: "0.1.0"
description: Test skill to observe precedence when skill name matches command name
user-invocable: true
allowed-tools:
  - Bash
hooks: {}
```

**Body**:
```markdown
# CIG Status Skill (Test)

This skill exists solely to test skills/commands precedence.

When invoked via `/cig-status`, observe:
1. Does this skill execute?
2. Does the command execute?
3. Which takes precedence?
4. Are there any error messages?

Document findings in Task 16 d-implementation.md.
```

## Constraints

**Technical Constraints**:
- ✅ Uses current Claude Code version (no upgrades needed)
- ✅ Limited to publicly available documentation and open source examples
- ✅ No Claude Code modifications (only configuration files)

**Process Constraints**:
- ✅ Discovery task (6-file template: a,b,c,d,e,h)
- ✅ Investigation before implementation (design → implementation → testing)
- ✅ Task branch commits (all work on discovery/16-*)

**Resource Constraints**:
- ✅ 2-3 day timeline (design: 0.5 day, implementation: 1 day, testing: 0.5 day, analysis: 0.5 day)
- ✅ Token-efficient (progressive disclosure reduces documentation duplication)

## Validation

### Design Validation Criteria
- [x] Test skill structure follows observed patterns from existing implementations (completed in Phases 1-2)
- [x] All 4 hook types testable independently (completed in Phases 1-2)
- [x] Integration testing protocol tests precedence empirically (completed in Phase 3)
- [x] Decision matrix updated with 4 options and 6 weighted criteria (Phase 7 design complete)
- [x] Research documentation strategy answers all RQ1-RQ7 with evidence (completed in Phases 1-7)
- [x] NFR1-NFR3 satisfied (reversibility, minimal disruption, documentation quality)

### Design Approval Checkpoints
1. **Structural validation**: Does test skill follow reference implementation patterns? ✓
2. **Coverage validation**: Do tests answer all RQs? ✓
3. **Decision validation**: Is decision framework systematic and weighted appropriately? ✓
4. **Documentation validation**: Is evidence-based research strategy clear? ✓

### Decomposition Check
- [ ] **Time**: Will this take >1 week? **No** - 2-3 days
- [ ] **People**: Does this need >2 people? **No** - single developer
- [ ] **Complexity**: 3+ distinct concerns? **No** - 4 sequential phases
- [ ] **Risk**: High-risk components needing isolation? **No** - low risk, reversible
- [ ] **Independence**: Can parts be worked separately? **No** - sequential phases

**Decomposition Decision**: No decomposition needed

## Status
**Status**: Finished
**Completion Date**: 2026-01-14
**Next Action**: Phase 7 decision framework complete, moved to retrospective
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
