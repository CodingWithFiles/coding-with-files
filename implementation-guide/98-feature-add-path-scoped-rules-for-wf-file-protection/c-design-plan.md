# Add path-scoped rules for wf file protection - Design
**Task**: 98 (feature)

## Task Reference
- **Task ID**: internal-98
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/98-add-path-scoped-rules-for-wf-file-protection
- **Template Version**: 2.1

## Goal
Design the rule file format, glob pattern, install integration, and rule content.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### Rule File Location and Format
- **Decision**: Single file at `.claude/rules/workflow-files.md` with YAML frontmatter
- **Rationale**: Claude Code loads rules from `.claude/rules/*.md` automatically. One file per concern keeps things simple. YAML frontmatter with `globs` field controls path scoping.
- **Trade-offs**: Single file means all step mappings in one place (easy to maintain, but loads entire mapping even when agent touches only one step). Acceptable given NFR1 constraint (under 20 lines).

### Glob Pattern Design
- **Decision**: `globs: ["implementation-guide/**/{a,b,c,d,e,f,g,h,i,j}-*.md"]`
- **Rationale**: `**/` handles arbitrary nesting depth (flat and nested subtask directories). Brace expansion `{a,b,...,j}` matches all 10 step prefixes. Trailing `-*.md` avoids matching non-step files.
- **Trade-offs**: Brace expansion depends on Claude Code's glob implementation supporting it. If not, fall back to 10 separate glob patterns or a broader `**/*-*.md` with prefix filtering in rule text.
- **Fallback**: If brace expansion isn't supported, use `globs: ["implementation-guide/**/*.md"]` with `description` field to narrow scope, and handle prefix filtering in rule text.

### Rule Content Design
- **Decision**: Terse mapping table — step prefix → skill name. No explanatory prose.
- **Rationale**: NFR1 (under 20 lines). Rules load on every matching file operation. Prose wastes tokens; the agent only needs to know which skill to call.
- **Format**:
  ```
  a- → /cwf-task-plan
  b- → /cwf-requirements-plan
  c- → /cwf-design-plan
  d- → /cwf-implementation-plan
  e- → /cwf-testing-plan
  f- → /cwf-implementation-exec
  g- → /cwf-testing-exec
  h- → /cwf-rollout
  i- → /cwf-maintenance
  j- → /cwf-retrospective
  ```

### Install Pipeline Integration
- **Decision**: Store rule source files in `.cwf-rules/` (parallel to `.cwf-skills/`), symlink from `.claude/rules/` during install
- **Rationale**: Follows the established pattern — skills are stored in `.cwf-skills/` and symlinked into `.claude/skills/`. Rules follow the same convention for consistency.
- **Alternative considered**: Direct copy instead of symlink. Simpler but diverges from skills pattern. Symlinks keep the source-of-truth in `.cwf-rules/` and allow `install.bash` update to refresh rules.
- **Install steps**:
  1. `install.bash`: subtree split `.claude/rules` → copy to `.cwf-rules/`, create symlinks in `.claude/rules/`
  2. `/cwf-init`: create `.claude/rules/` directory, create symlinks to `.cwf-rules/`

### cwf-init Integration
- **Decision**: Add rules directory creation and symlink step to `/cwf-init` skill, between skills registration and PERL5OPT check
- **Rationale**: Rules should be active from first use. `/cwf-init` already creates `.claude/skills/` — adding `.claude/rules/` is a natural extension.
- **Git staging**: Add `.claude/rules/` to the init commit alongside other `.claude/` files

## Data Flow
1. `install.bash` copies rule source files to `.cwf-rules/` in target project
2. `install.bash` creates symlinks: `.claude/rules/workflow-files.md` → `../../.cwf-rules/workflow-files.md`
3. `/cwf-init` creates `.claude/rules/` if not present, ensures symlinks exist
4. Agent opens a wf step file → Claude Code detects glob match → rule auto-loads into context
5. Agent reads rule → sees skill mapping → invokes correct skill instead of editing directly

## Constraints
- Claude Code rules mechanism is the dependency — must verify glob/frontmatter format against actual behaviour
- Symlink approach requires `.cwf-rules/` to be present (install prerequisite)
- Advisory only — rule is guidance, not enforcement

## Decomposition Check
0/5 signals triggered — no decomposition needed.

## Validation
- [ ] Glob pattern matches wf step files at various nesting depths
- [ ] Rule content is under 20 lines
- [ ] Symlink structure follows skills pattern
- [ ] `/cwf-init` creates rules directory and symlinks

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 98
**Blockers**: None

## Actual Results
Design implemented as planned. Symlink-based install approach works for both `install.bash` and `cwf-init`. Force-reinstall cleanup added to handle stale symlinks.

## Lessons Learned
Third subtree split in install script needed careful ordering to avoid overwriting rules during force-reinstall. Glossary updates are easy to forget — add to checklist.
