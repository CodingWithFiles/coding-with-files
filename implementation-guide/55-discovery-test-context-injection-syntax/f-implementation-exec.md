# Test context injection syntax - Implementation Execution
**Task**: 55 (discovery)

## Task Reference
- **Task ID**: internal-55
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/55-test-context-injection-syntax
- **Template Version**: 2.1

## Goal
Execute the context injection syntax experiment and record results.

## Execution Checklist
- [x] Read d-implementation-plan.md thoroughly
- [x] Create test skill for `!{bash}` block syntax (Step 1)
- [x] Create test skill for `!` path syntax (Step 2)
- [x] Invoke both test skills and observe results (Step 3)
- [x] Record results (Step 4)
- [ ] Clean up test skills (Step 5)

## Experiment Results

### Step 1: Test Skill `cig-test-bash-block` Created

File: `.claude/skills/cig-test-bash-block/SKILL.md`
- Frontmatter: name, description, user-invocable, allowed-tools
- Body: Two `!{bash}` blocks (echo marker and context-manager call)
- Skill detected immediately by Claude Code (appeared in available skills list)

### Step 2: Test Skill `cig-test-inline-inject` Created

File: `.claude/skills/cig-test-inline-inject/SKILL.md`
- Frontmatter: name, description, user-invocable, allowed-tools
- Body: Two `!/current-task-wf` references (standalone and inline)
- Skill detected immediately by Claude Code

### Step 3: Experiment Execution

#### FR1: `!{bash}` Block Syntax — FAIL

| Test | Expected | Observed | Verdict |
|------|----------|----------|---------|
| Simple echo (`echo "INJECTION_TEST_MARKER_1234"`) | Expanded prompt contains "INJECTION_TEST_MARKER_1234" | Raw literal: `!{bash}\necho "INJECTION_TEST_MARKER_1234"` visible as plain text | **FAIL** |
| CIG helper script (`context-manager location`) | Expanded prompt contains "Git repo root: ..." | Raw literal: `!{bash}\n.cig/scripts/command-helpers/context-manager location` visible as plain text | **FAIL** |

**Conclusion**: The `!{bash}` context injection syntax is **not processed** in SKILL.md files. It works in `.claude/commands/*.md` files but is treated as literal markdown in `.claude/skills/*/SKILL.md` files.

#### FR2: `!` Path Shorthand — FAIL

| Test | Expected | Observed | Verdict |
|------|----------|----------|---------|
| Standalone (`!/current-task-wf`) | Expanded prompt contains task context output | Raw literal: `!/current-task-wf` visible as plain text | **FAIL** |
| Inline (`Before: !/current-task-wf :After`) | "Before:" + task context + ":After" | Raw literal: `Before: !/current-task-wf :After` | **FAIL** |

**Conclusion**: The `!` path shorthand syntax is **not processed** in SKILL.md files. Same as `!{bash}` — works in commands, not in skills.

#### Observations

1. **Skills ARE detected**: Both test skills appeared in the available skills list immediately after creation. The SKILL.md frontmatter is parsed correctly.
2. **Skill prompt IS delivered**: The full body of SKILL.md (below the frontmatter) is delivered to the LLM as the skill prompt. Claude Code adds a `Base directory for this skill:` header.
3. **Context injection is commands-only**: The `!{bash}` and `!` syntaxes are a feature of the `.claude/commands/` loader, not a general markdown processing feature. The skills loader does not process these directives.
4. **No error is raised**: The syntax silently passes through as literal text. No warning, no error — it just doesn't do anything.

### FR3: Alternative Approaches

Since both syntaxes fail, CIG command-to-skill conversion needs alternative approaches for dynamic context:

| Approach | How It Works | Pros | Cons |
|----------|-------------|------|------|
| **1. Use `allowed-tools` with Bash** | Skill body instructs LLM to call Bash tool to run the command. LLM executes it as a tool call, not pre-injection. | Works today; no special syntax needed; skill body is just instructions | Context loaded at runtime (extra tool call), not at prompt expansion time; requires LLM to follow instructions |
| **2. Thin skill + doc reference** | Skill body references a `.cig/docs/` file via Read tool. LLM reads the doc at runtime. | Clean separation; docs can be shared across skills; progressive disclosure | Two-step load (skill prompt → Read tool → doc content); slightly more tokens |
| **3. `context:` frontmatter field** | SKILL.md frontmatter has `context:` options (e.g., `context: fork`). May support context file references. | Native to skills system; no tool call overhead | Unverified whether `context:` supports custom file injection; currently documented only for `fork` mode |
| **4. Hybrid: commands for context-heavy, skills for simple** | Keep commands that need `!{bash}` as commands; convert simple commands to skills | Preserves working patterns; incremental migration | Split architecture; maintenance burden of two systems |

**Recommended approach**: Option 1 (allowed-tools with Bash) combined with Option 2 (thin skill + doc reference). The skill body instructs the LLM to run context-loading commands via Bash, and references shared docs for workflow instructions. This is functionally equivalent to `!{bash}` but happens at runtime instead of prompt expansion.

**Key difference from commands**: Commands pre-inject context into the prompt before the LLM sees it. Skills deliver static text and the LLM must use tool calls to load dynamic context. This adds 1-2 tool call round trips but is otherwise equivalent.

## Status
**Status**: Finished
**Next Action**: /cig-retrospective 55
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Both context injection syntaxes (`!{bash}` block and `!` path shorthand) FAIL in SKILL.md format. They are features of the commands loader, not the skills loader. Alternative approaches identified — runtime tool calls (Bash + Read) can achieve equivalent functionality.

## Lessons Learned
- Context injection is a commands-only feature, not documented as such anywhere
- Skills deliver their body as static text; dynamic content requires LLM tool calls
- The failure is silent (no error, no warning) — easy to miss without explicit testing
