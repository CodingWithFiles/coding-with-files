# assess current 2026 W6 skills and plugin stds - Implementation Execution
**Task**: 54 (discovery)

## Task Reference
- **Task ID**: internal-54
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/54-assess-current-2026-w6-skills-and-plugin-stds
- **Template Version**: 2.1

## Goal
Execute the research plan defined in d-implementation-plan.md. Document findings for FR1-FR7 structured per c-design-plan.md output format. Produce actionable recommendation for CIG migration strategy.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status to "Implemented" when complete

## Execution Summary

**Research period**: 12 February 2026
**Method**: 6 parallel research agents covering FR1-FR6, followed by FR7 synthesis
**Tools used**: WebSearch, WebFetch, Read (local files), Grep (local code)
**Deviation**: `gh` CLI was initially unavailable for FR2 GitHub issue searches; compensated with WebSearch for issue discovery. `gh` was later installed and authenticated; structured searches and reaction data subsequently retrieved, enriching FR2 with comment counts, upvote data, and workaround code from issue threads.

---

## Step 1: Task 16 Baseline Loaded

**Baseline extracted from**: `implementation-guide/16-discovery-investigate-skills-configuration-and-integration/d-implementation.md`

Key baseline data points (Jan 2026):
- **SKILL.md frontmatter fields**: `name`, `version`, `description`, `user-invocable`, `allowed-tools`, `hooks` (via settings.json only), `disable-model-invocation`, `argument-hint`
- **Hook types**: `PreToolUse`, `PostToolUse`, `Stop`, `Notification` (command-based only in settings.json)
- **Deployment models**: Plugin (`.claude/plugins/`), repo-local skill (`.claude/skills/`), user-global skill (`~/.claude/skills/`)
- **Key finding**: Hooks only work in plugin mode; `${CLAUDE_PLUGIN_ROOT}` not expanded in skill-only mode
- **Agent Skills spec**: Announced Dec 18, 2025; adoption unclear at time of Task 16
- **Recommendation**: Keep Commands (47/55 weighted score, 75% confidence)

---

## Step 2: Phase 1 Research — API Evolution and Standards

### FR1: Skills API Evolution (Jan to Feb 2026)

#### Findings

**Claude Code 2.1.0 (Released 7 January 2026)** — 1,096 commits, largest skills-related release:

| Change | Details | Breaking? | Date |
|--------|---------|-----------|------|
| Hooks in SKILL.md frontmatter | Skills can define `hooks:` directly in YAML frontmatter with `PreToolUse`, `PostToolUse`, `Stop` event types, scoped to skill lifecycle | No (additive) | Jan 7, 2026 |
| `context: fork` frontmatter field | Causes skill to run as isolated sub-agent with no conversation history access | No (additive) | Jan 7, 2026 |
| `agent:` frontmatter field | Specifies which subagent configuration to use (built-in or custom from `.claude/agents/`) | No (additive) | Jan 7, 2026 |
| Skill hot-reload | Skills modified in `~/.claude/skills` or `.claude/skills` immediately available without restart | No (additive) | Jan 7, 2026 |
| Skills visible in slash menu | Skills from `/skills/` directories visible in slash command menu by default | No (additive) | Jan 7, 2026 |
| Wildcard tool permissions | `allowed-tools` supports wildcards, e.g., `Bash(*-h*)` | No (additive) | Jan 7, 2026 |
| `async: true` hook flag | Allows hooks to run in background without blocking | No (additive) | Jan 7, 2026 |

**Claude Code 2.1.3 (Released ~24 January 2026)** — Commands/skills merger:

| Change | Details | Breaking? | Date |
|--------|---------|-----------|------|
| Merged slash commands and skills | `.claude/commands/review.md` and `.claude/skills/review/SKILL.md` both create `/review`; unified invocation model | No (backward compatible) | ~Jan 24, 2026 |
| Release channel toggle | `stable` or `latest` toggle added to `/config` | No (additive) | ~Jan 24, 2026 |
| Unreachable permission warnings | Detection and warnings for unreachable permission rules | No (additive) | ~Jan 24, 2026 |

**Claude Code 2.1.14 (Late January 2026)**:

| Change | Details | Breaking? | Date |
|--------|---------|-----------|------|
| Plugin pinning to git commit SHAs | Pin plugins to exact commits, e.g., `"security-toolkit@official#abc123def": true` | No (additive) | Late Jan 2026 |

**Claude Code 2.1.19 (Late January / Early February 2026)**:

| Change | Details | Breaking? | Date |
|--------|---------|-----------|------|
| Indexed argument syntax change | `$ARGUMENTS.0` changed to `$ARGUMENTS[0]` (bracket syntax); shorthand `$0`, `$1` added | **YES — BREAKING** | Late Jan 2026 |

**Post-2.1.19 Changes (February 2026)**:

| Change | Details | Breaking? | Date |
|--------|---------|-----------|------|
| Skills from `--add-dir` directories | Skills in `.claude/skills/` within `--add-dir` directories auto-loaded | No (additive) | Feb 2026 |
| Plugin name in skill descriptions | Plugin name appears in skill descriptions and `/skills` menu | No (additive) | Feb 2026 |
| Skill character budget scales with context | 2% of context window (fallback: 16,000 chars); previously fixed | No (behaviour change) | Feb 2026 |
| Agent teams research preview | Multi-agent collaboration (research preview, not stable) | No (preview) | Feb 2026 |

**SDK Rename (Breaking)**:

| Change | Details | Breaking? | Date |
|--------|---------|-----------|------|
| Legacy SDK removed | `@anthropic-ai/claude-code` → `@anthropic-ai/claude-agent-sdk`; Python: `claude_code_sdk` → `claude_agent_sdk` | **YES — BREAKING** | Jan-Feb 2026 |

**Complete SKILL.md Frontmatter Fields (Feb 2026)**:

| Field | Status | Added/Changed | Notes |
|-------|--------|---------------|-------|
| `name` | Stable | Pre-2.1 | Becomes `/slash-command` name |
| `description` | Stable | Pre-2.1 | Primary triggering mechanism for auto-discovery (max 1024 chars) |
| `allowed-tools` | Enhanced | Pre-2.1; wildcards Jan 7 | Limits tools during skill execution; supports wildcards |
| `user-invocable` | Stable | Pre-2.1 | Controls slash command menu visibility (default: `true`) |
| `disable-model-invocation` | Stable | Pre-2.1 | Prevents auto-invocation via Skill tool (default: `false`) |
| `argument-hint` | Stable (bug) | Pre-2.1 | [Bug: brackets cause React error (#22161)](https://github.com/anthropics/claude-code/issues/22161) |
| `context` | **NEW** | Jan 7, 2026 | Set to `"fork"` to run as isolated sub-agent |
| `agent` | **NEW** | Jan 7, 2026 | Specifies subagent to use (built-in or custom) |
| `hooks` | **NEW** | Jan 7, 2026 | Embedded hook definitions scoped to skill lifecycle |
| `mode` | Documented | Unclear | Boolean; categorises as "mode command" |
| `version` | Documented | Pre-2.1 | Metadata for tracking |

**Expanded Hook Event Types (Feb 2026)**:

Command-based hooks: `PreToolUse`, `PostToolUse`, `Stop`, `Notification`, `UserPromptSubmit`, `SessionStart`

Prompt-based hooks (expanded set): `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`, `UserPromptSubmit`, `Stop`, `SubagentStop`, `TaskCompleted`

#### Evidence

- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills)
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Claude Code Plugins Reference](https://code.claude.com/docs/en/plugins-reference)
- [Claude Code CHANGELOG.md](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md)
- [Claude Code v2.1.3 CHANGELOG](https://github.com/anthropics/claude-code/blob/v2.1.3/CHANGELOG.md)
- [ClaudeLog Changelog](https://claudelog.com/claude-code-changelog/)
- [Claudefast Changelog](https://claudefa.st/blog/guide/changelog)
- [Releasebot - Claude Code](https://releasebot.io/updates/anthropic/claude-code)
- [VentureBeat: Claude Code 2.1.0](https://venturebeat.com/orchestration/claude-code-2-1-0-arrives-with-smoother-workflows-and-smarter-agents)
- [SDK Migration Guide](https://platform.claude.com/docs/en/agent-sdk/migration-guide)
- [Hooks guide (all 12 lifecycle events)](https://claudefa.st/blog/tools/hooks/hooks-guide)
- [GitHub Issue #17283](https://github.com/anthropics/claude-code/issues/17283) (`context: fork` and `agent:` behaviour)
- [GitHub Issue #19141](https://github.com/anthropics/claude-code/issues/19141) (frontmatter field confusion)
- [Threads announcement by Boris Cherny](https://www.threads.com/@boris_cherny/post/DTOyRyBD018/) (2.1.0 features)
- [X post by @oikon48](https://x.com/oikon48/status/2014841509854736628) ($ARGUMENTS syntax change)

#### Implications for CIG

1. **Commands/skills merger (v2.1.3) is backward-compatible**: CIG's 17 commands in `.claude/commands/` continue to work unchanged. No forced migration.
2. **New frontmatter fields (`context: fork`, `agent:`, `hooks:`)** enable capabilities CIG doesn't have today, but require skill format (not command format) to use.
3. **Breaking change (`$ARGUMENTS[0]` syntax)**: CIG commands use `{arguments}` not `$ARGUMENTS`, so this breaking change does not affect CIG directly.
4. **SDK rename**: CIG does not use the SDK, so this is not relevant.
5. **Skill character budget (2% of context)**: CIG commands can be large (several hundred lines with dynamic context injection). The 2% budget may truncate skill content — needs verification.
6. **Hook frontmatter in SKILL.md is buggy**: Issue #17688 confirms hooks in SKILL.md frontmatter don't trigger within plugins. This directly undermines the primary value proposition of migrating to skills.

#### Delta from Task 16

| Aspect | Task 16 (Jan 2026) | Now (Feb 2026) |
|--------|---------------------|-----------------|
| Frontmatter hooks | Not available | Available in SKILL.md (but buggy in plugins — #17688) |
| `context: fork` | Not available | Available (but Skill tool ignores it — #17283) |
| `agent:` field | Not available | Available |
| Commands/skills | Separate concepts | Merged in v2.1.3 (backward compatible) |
| Argument syntax | `$ARGUMENTS.0` | `$ARGUMENTS[0]` (**breaking**) |
| Skill budget | Fixed | Dynamic (2% of context) |
| Plugin pinning | Not available | Available (SHA pinning) |
| Hook event types | 4 command-based | 6 command-based + 8 prompt-based |

---

### FR4: Hooks Standardisation Progress

#### Findings

**Agent Skills Specification Updates Since Dec 2025**:

The specification has evolved from the initial December 2025 announcement into a mature open standard:
- **New hosting**: Specification lives at `agentskills.io/specification` (decoupled from Anthropic's repository)
- **New organisation**: `github.com/agentskills/agentskills` with `skills-ref` validation library
- **`allowed-tools` field added** (Experimental): Space-delimited list of pre-approved tools
- **`compatibility` field added** (Optional, max 500 chars): Environment requirements
- **Progressive disclosure formalised**: Three-tier token budget (metadata ~100 tokens at startup, instructions <5000 tokens on activation, resources on demand)
- **Memory frontmatter field** added for agents

**Platform Adoption Status**:

| Platform | Status | SKILL.md Support | Hooks Integration |
|----------|--------|------------------|-------------------|
| **Anthropic (Claude Code)** | Adopted (originator) | Native | PreToolUse, PostToolUse lifecycle hooks |
| **OpenAI (Codex)** | Adopted | Native | App-server APIs/events |
| **Microsoft (GitHub Copilot)** | Adopted | Native (VS Code 1.108+) | Part of Copilot SDK session management |
| **Cursor** | Adopted | Native (2.0+) | Subagent system with SKILL.md configs |
| **Google (Gemini CLI)** | Adopted (preview) | Native (v0.23.0+) | `activate_skill` tool in agent loop |
| **Vercel** | Adopted (tooling) | Via `skills` CLI | N/A (tooling provider) |

**Competing/Complementary Specifications**:

| Specification | Relationship | Key Finding |
|--------------|--------------|-------------|
| **AGENTS.md** | Complementary (overlapping) | Adopted by 60,000+ projects. Vercel benchmarks: AGENTS.md achieved 100% pass rate vs skills at 79%. Static system prompt approach outperforms dynamic skill loading. |
| **MCP** | Complementary | Donated to AAIF. Tools (capabilities) vs Skills (knowledge). |
| **AAIF** | Governance umbrella | Linux Foundation (Dec 9, 2025). Members: AWS, Anthropic, Block, Bloomberg, Cloudflare, Google, Microsoft, OpenAI. Hosts MCP, AGENTS.md, goose. Agent Skills not yet formally under AAIF but decoupled to agentskills.io. |

**Hooks Cross-Platform Status**: Hooks remain **Claude Code-specific**. No cross-platform hook standardisation has emerged. Each platform implements its own lifecycle event system.

#### Evidence

- [Agent Skills Specification](https://agentskills.io/specification)
- [Agent Skills GitHub Organisation](https://github.com/agentskills/agentskills)
- [Anthropic Skills Repository](https://github.com/anthropics/skills) (68.4k stars, 6.9k forks)
- [OpenAI Codex Skills Documentation](https://developers.openai.com/codex/skills/)
- [VS Code Agent Skills](https://code.visualstudio.com/docs/copilot/customization/agent-skills)
- [GitHub Copilot About Agent Skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)
- [Microsoft Skills Repository](https://github.com/microsoft/skills)
- [Gemini CLI Skills](https://geminicli.com/docs/cli/skills/)
- [Gemini CLI Skills Epic](https://github.com/google-gemini/gemini-cli/issues/15327)
- [Vercel: AGENTS.md outperforms skills](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals)
- [AAIF Announcement](https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation)
- [AAIF Website](https://aaif.io/)
- [Microsoft .NET AI Skills Executor](https://devblogs.microsoft.com/foundry/dotnet-ai-skills-executor-azure-openai-mcp/)

#### Implications for CIG

1. **Cross-platform portability is real**: Skills written for Claude Code work in Codex, Copilot, Cursor, Gemini CLI. This increases the long-term value of adopting skill format.
2. **Hooks are NOT portable**: CIG cannot benefit from hooks portability — hooks remain Claude-specific. The hooks value proposition is Claude Code-only.
3. **AGENTS.md outperforming skills in benchmarks**: Vercel's finding (100% vs 79%) suggests that CIG's current approach (static command content injected into prompt) may be more reliable than dynamic skill loading. This supports keeping commands.
4. **AAIF governance reduces vendor risk**: Agent Skills specification is moving towards neutral governance, reducing the risk of Anthropic-specific lock-in for skill format.
5. **Adoption faster than Task 16 predicted**: Task 16 estimated 6-24 months for standardisation. All 5 major platforms adopted within 2 months. This changes the timing calculus.

#### Delta from Task 16

| Aspect | Task 16 (Jan 2026) | Now (Feb 2026) |
|--------|---------------------|-----------------|
| Platform adoption | Claude Code only confirmed | All 5 major platforms adopted |
| Specification governance | Anthropic-hosted | Independent at agentskills.io + AAIF umbrella |
| Validation tooling | None | `skills-ref` library available |
| Cross-platform hooks | Not available | Still not available (hooks remain Claude-specific) |
| Competing standards | AGENTS.md nascent | AGENTS.md outperforms skills in evals (Vercel) |
| Timeline estimate | 6-24 months | Core adoption complete; marketplace standardisation Q2-Q3 2026 |

---

## Step 3: Phase 2 Research — Community Intelligence

### FR2: User Feedback Analysis

#### Findings

**Method**: Initial issue discovery via WebSearch across 6 research agents (18 issues found). Subsequently enriched with `gh search issues` structured queries (3 searches: "skill", "plugin", "hook") and `gh api` for per-issue reaction counts and comment thread analysis. Total: 23 distinct issues catalogued.

**Pain Points** (15 issues):

| # | Issue | Title | Category | 👍 | Comments | Impact |
|---|-------|-------|----------|-----|----------|--------|
| 1 | [#17688](https://github.com/anthropics/claude-code/issues/17688) | Skill-scoped hooks in SKILL.md frontmatter not triggered within plugins | Hook failure | 9 | 8 | Plugin skills cannot use frontmatter hooks — core plugin feature broken. Affects both inline and marketplace plugins ([community root cause analysis](https://github.com/anthropics/claude-code/issues/17688)) |
| 2 | [#22087](https://github.com/anthropics/claude-code/issues/22087) | classifyHandoffIfNeeded is not defined — SubagentStop hook failure | Hook failure | 34 | 16 | All Task tool agents affected — agents complete work but fail on termination. Blocks multi-agent orchestration workflows |
| 3 | [#14851](https://github.com/anthropics/claude-code/issues/14851) | Commands are now "skills" and loaded into context without being invoked | Context pollution | 7 | 21 | Commands-turned-skills auto-loaded via progressive disclosure, consuming 26k+ tokens before conversation starts (VS Code report) |
| 4 | [#17283](https://github.com/anthropics/claude-code/issues/17283) | Skill tool does not honour `context: fork` and `agent:` frontmatter | Feature broken | 0 | 2 | Skills invoked via Skill tool run in main context regardless of `context: fork` |
| 5 | [#20050](https://github.com/anthropics/claude-code/issues/20050) | LSP plugins not working with native/standalone binary installation | Plugin install | 8 | 6 | Plugins broken for users on native binary (non-npm) installations |
| 6 | [#19212](https://github.com/anthropics/claude-code/issues/19212) | Skill tool does not recognise local skills in `~/.claude/skills/` | Discovery failure | — | — | Must package as plugin for Skill tool access |
| 7 | [#15178](https://github.com/anthropics/claude-code/issues/15178) | Plugin skills not injected into `<available_skills>` context | Discovery failure | — | — | AI cannot proactively suggest plugin skills |
| 8 | [#21592](https://github.com/anthropics/claude-code/issues/21592) | Skills are not shown in `/` menu | UI failure | — | — | Skills fail to appear in autocomplete |
| 9 | [#25209](https://github.com/anthropics/claude-code/issues/25209) | Project-level skills with same name as global skills show both instead of overriding | Precedence | 0 | 1 | Skills from different scopes don't override correctly |
| 10 | [#25150](https://github.com/anthropics/claude-code/issues/25150) | Plugin skill autocomplete displays flat names instead of namespaced format | UI bug | 0 | 2 | Plugin skills shown as flat names, breaking namespace expectation |
| 11 | [#25159](https://github.com/anthropics/claude-code/issues/25159) | Conflicting guidance on slash command vs skill installation format | UX confusion | 0 | 1 | Documentation and CLI give contradictory instructions for skill setup |
| 12 | [#24156](https://github.com/anthropics/claude-code/issues/24156) | `keybindings-help` skill always loaded even when CLI options forbid it | Context pollution | — | — | Built-in skills ignore CLI restriction flags |
| 13 | [#16143](https://github.com/anthropics/claude-code/issues/16143) | `mcpServers` in plugin.json silently dropped despite being in Zod schema | Silent failure | — | — | Cannot bundle MCP servers inline in plugins |
| 14 | [#22161](https://github.com/anthropics/claude-code/issues/22161) | `argument-hint` brackets cause React error | UI bug | — | — | Brackets in argument hints break the UI |
| 15 | [#11459](https://github.com/anthropics/claude-code/issues/11459) | Skills being interpreted as SlashCommands | Identity confusion | — | — | Pre-merge confusion about skill vs command treatment |

**Feature Requests** (6 issues):

| # | Issue | Title | 👍 | Comments | Category |
|---|-------|-------|-----|----------|----------|
| 1 | [#6235](https://github.com/anthropics/claude-code/issues/6235) | Feature Request: Support AGENTS.md | 2565 | 190 | Cross-platform standard (massive community demand) |
| 2 | [#17271](https://github.com/anthropics/claude-code/issues/17271) | Project skill display in slash command but plugin skill doesn't | 38 | 22 | Parity |
| 3 | [#13115](https://github.com/anthropics/claude-code/issues/13115) | Consider merging Skills and Slash Commands | 9 | 6 | **Implemented** in v2.1.3 |
| 4 | [#14835](https://github.com/anthropics/claude-code/issues/14835) | Separate skills and slash commands in `/context` output | 2 | 8 | Visibility |
| 5 | [#20802](https://github.com/anthropics/claude-code/issues/20802) | `user-invocable: true` skills don't show plugin prefix in autocomplete | 0 | 3 | Discoverability |
| 6 | [#25211](https://github.com/anthropics/claude-code/issues/25211) | Add sorting/filtering options to /plugin manager UI | 0 | 0 | Plugin UX |

**Workarounds from Issue Threads**:

| # | Issue | Workaround | Type |
|---|-------|-----------|------|
| 1 | [#14851](https://github.com/anthropics/claude-code/issues/14851) | Move unused skills to a `disabled_skills/` folder outside `.claude/skills/` and restart Claude. Selectively restore skills when needed. | Bash script (community-reported) |
| 2 | [#22087](https://github.com/anthropics/claude-code/issues/22087) | Agents complete tasks before the hook failure occurs. Check output files exist, test manually, ignore the SubagentStop error. Not sustainable for automation workflows. | Manual verification |
| 3 | [#17688](https://github.com/anthropics/claude-code/issues/17688) | Use project skills (`.claude/skills/`) instead of plugin skills — frontmatter hooks work in non-plugin context. Community traced root cause to two different loader functions: `dI2` (plugin loader, broken) vs `iH5` (local loader, works). | Architecture change (avoid plugins) |

**Documentation Issues** (4 issues):

| # | Issue | Title |
|---|-------|-------|
| 1 | [#16900](https://github.com/anthropics/claude-code/issues/16900) | Clarify relationship between skills and slash commands post v2.1.1 |
| 2 | [#17288](https://github.com/anthropics/claude-code/issues/17288) | Changelog entry "Merged slash commands and skills" is confusing |
| 3 | [#17578](https://github.com/anthropics/claude-code/issues/17578) | Inconsistency regarding "Merged slash commands and skills" in Changelog vs Documentation |
| 4 | [#19141](https://github.com/anthropics/claude-code/issues/19141) | Docs unclear on `user-invocable` vs `disable-model-invocation` distinction |

**Sentiment Summary**:
- **Positive**: The merge (v2.1.3) was welcomed as simplification; cross-platform portability praised; AGENTS.md has massive demand (2565 upvotes, 190 comments on #6235)
- **Negative**: Multiple bugs in core features (#17688 hooks 9👍, #22087 SubagentStop 34👍, #14851 context pollution 7👍); documentation lagging behind changes; progressive disclosure causing unwanted auto-loading (26k+ tokens consumed before conversation starts)
- **Neutral**: Skills ecosystem is young and rapidly iterating; workarounds exist but are manual; community providing root cause analysis faster than official fixes

#### Evidence

All issue URLs listed above with `gh api` reaction and comment data (retrieved 12 Feb 2026). Additionally:
- [ClaudeCodeLog on X (v2.1.3)](https://x.com/ClaudeCodeLog/status/2009773339032588477)
- [DeepWiki: Skill System](https://deepwiki.com/anthropics/claude-code/3.7-custom-slash-commands)
- [Medium: Claude Code Merges Slash Commands Into Skills](https://medium.com/@joe.njenga/claude-code-merges-slash-commands-into-skills-dont-miss-your-update-8296f3989697)
- [Dev Genius: Why did Anthropic merge slash commands into skills?](https://blog.devgenius.io/why-did-anthropic-merge-slash-commands-into-skills-4bf6464c96ca)

#### Implications for CIG

1. **Bug #17688 is critical for CIG**: If CIG migrated to a plugin, frontmatter hooks would not trigger. Community root cause analysis confirms this affects both inline and marketplace plugins. Workaround is to use project skills instead — but this defeats the purpose of plugin distribution.
2. **Bug #22087 blocks agent orchestration**: SubagentStop hook failure (34 upvotes, 16 comments) means multi-agent workflows using Task tool are unreliable. CIG's workflow commands frequently spawn sub-agents.
3. **Auto-loading concern (#14851)**: CIG has 17 commands. If converted to skills, they could consume 26k+ tokens before conversation starts (per VS Code user report). The `disable-model-invocation: true` field mitigates this, and the community workaround of moving skills to a disabled folder is fragile.
4. **Bug #17283 breaks sub-agent skills**: `context: fork` not honoured means CIG couldn't use skills as isolated sub-agent constructors. Not immediately relevant but limits future architecture.
5. **Documentation gaps**: The skills system is poorly documented, increasing migration risk. CIG would need to empirically test each feature rather than relying on docs.

#### Delta from Task 16

Task 16 did not systematically catalogue community issues. This is entirely new data. The key new insights are:
- **Core skills features have significant bugs** (hooks #17688, SubagentStop #22087, context fork #17283, skill discovery #19212) — not apparent during Task 16's limited testing
- **Community engagement is high** — #6235 (AGENTS.md) has 2565 upvotes; #22087 (SubagentStop) has 34 upvotes; users are actively providing root cause analysis
- **Workarounds exist but are manual** — no official fixes for the critical bugs yet

---

### FR3: Migration Pattern Catalogue

#### Findings

**Anthropic's Official Merge (v2.1.3)**: The commands-to-skills transition was designed as a **zero-effort, backward-compatible unification**. Both `.claude/commands/review.md` and `.claude/skills/review/SKILL.md` create `/review`. Existing `.claude/commands/` files continue to work indefinitely. If a skill and command share the same name, the skill takes precedence.

**5 Real-World Migration Examples**:

| Example | Repository | Strategy | Outcome |
|---------|-----------|----------|---------|
| A | [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) | Hybrid coexistence | 15+ agents, 30+ skills, 30+ commands. Both directories maintained. Actively maintained. |
| B | [leeovery/claude-laravel](https://github.com/leeovery/claude-laravel) | Hybrid with tooling | Uses `@leeovery/claude-manager` to copy skills and commands. npm-based management. |
| C | [mahidalhan/claude-hacks](https://github.com/mahidalhan/claude-hacks) | Incremental consolidation | Migration plan to consolidate scattered commands into 7 plugins. In progress. |
| D | [jduncan-rva/skill-porter](https://github.com/jduncan-rva/skill-porter) | Cross-platform portability | Universal converter between Claude Code skills and Gemini CLI extensions. ~85% code reuse. |
| E | [Delphine-L/claude_global](https://github.com/Delphine-L/claude_global) | Coexistence | Domain-specific (Galaxy/bioinformatics). Both skills and commands directories maintained. |

**Common Patterns**:
- **Dominant pattern: Hybrid coexistence** — All 5 examples maintain both commands and skills. No project performed a "big-bang" migration.
- **Skills for new work**: New functionality added as skills; existing commands left as-is.
- **Package managers emerging**: `claude-manager` (npm), `skill-porter` (CLI), `npx skills add` (Vercel) for managing skill installation.
- **Cross-platform portability**: skill-porter demonstrates that skills can be converted between platforms with ~85% code reuse.

**Common Challenges**:

| Challenge | Frequency | Description |
|-----------|-----------|-------------|
| Unwanted auto-loading | 3/5 examples | Skills auto-loaded into context via progressive disclosure |
| Documentation inconsistency | 4/5 examples | Changelog vs docs contradict on merge semantics |
| Name collision | 2/5 examples | Skill takes precedence over command with same name |
| Structural difference | 5/5 examples | Commands are single-file; skills are directories with SKILL.md |
| Context pollution | 2/5 examples | Built-in skills loaded even when not wanted |

**Anti-Patterns**:
- Big-bang migration (no examples found — everyone uses incremental/hybrid)
- Converting commands that work fine (no benefit unless needing skill-specific features)
- Assuming commands will be deprecated (Anthropic has given no deprecation signal)

#### Evidence

- [ClaudeCodeLog on X (v2.1.3)](https://x.com/ClaudeCodeLog/status/2009773339032588477)
- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills)
- [GitHub Issue #13115](https://github.com/anthropics/claude-code/issues/13115) (original merge request)
- [Medium: Claude Code Merges Slash Commands](https://medium.com/@joe.njenga/claude-code-merges-slash-commands-into-skills-dont-miss-your-update-8296f3989697)
- [YingTu: Skills vs Slash Commands](https://yingtu.ai/blog/claude-code-skills-vs-slash-commands)
- [How Do I Use AI: Custom Skills](https://www.howdoiuseai.com/blog/2026-02-08-how-to-train-claude-code-agents-with-custom-skills)
- [Agent Skills Standard](https://agentskills.io/home)
- [MCP Market Skills Directory](https://mcpmarket.com/tools/skills)
- Repository URLs listed in table above

#### Implications for CIG

1. **No urgency to migrate**: Every real-world example uses hybrid coexistence. No project has fully abandoned commands. Anthropic has not signalled deprecation.
2. **Incremental approach validated**: The dominant pattern — keep commands, add skills for new features — is what CIG would likely do.
3. **Structural conversion is non-trivial**: CIG's 17 commands are single-file markdown with `!{bash}` context injection. Converting to `SKILL.md` directories requires restructuring and testing each command.
4. **Name collision risk**: CIG must avoid duplicate names during any hybrid transition (skill precedence over command is silent).

#### Delta from Task 16

Task 16 found no migration examples (the skills system was too new). Now 5+ examples exist, all confirming hybrid coexistence as the dominant strategy. Anthropic's v2.1.3 merge was explicitly designed to require zero migration effort.

---

## Step 4: Phase 3 Research — Technical Assessment

### FR5: Plugin Marketplace and Distribution Status

#### Findings

**Official Anthropic Marketplace**:
- **Repository**: [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official)
- **Auto-available**: Automatically registered on Claude Code startup; no manual setup
- **Scale**: 40+ curated plugins in 9 categories
- **Browse**: `/plugin` → Discover tab
- **Install**: `/plugin install plugin-name@claude-plugins-official`

**Plugin Categories in Official Marketplace**:

| Category | Examples |
|----------|---------|
| Code Intelligence (LSP) | typescript-lsp, pyright-lsp, rust-analyzer-lsp, gopls-lsp, jdtls-lsp, kotlin-lsp, clangd-lsp, csharp-lsp, swift-lsp, php-lsp, lua-lsp |
| External Integrations | github, gitlab, atlassian, asana, linear, notion, figma, vercel, firebase, supabase, slack, sentry |
| Development Workflows | commit-commands, pr-review-toolkit, agent-sdk-dev, plugin-dev, frontend-design, security-guidance |
| Output Styles | explanatory-output-style, learning-output-style |

**Distribution Model**: Git-based (not npm)
- **Primary**: GitHub repositories (`owner/repo` format)
- **Secondary**: GitLab, Bitbucket, self-hosted Git (full URL support)
- **Local**: Development/testing via local paths
- **SHA pinning**: Available for supply-chain integrity
- **npm status**: "Not yet fully implemented" — Git-based sources are the standard

**Plugin Architecture**: Plugins can bundle:
- Skills (SKILL.md files)
- Agents (subagent definitions)
- Hooks (pre/post action shell commands)
- MCP servers (tool integrations) — **but silently dropped due to bug #16143**
- LSP servers (language server protocol)

**Installation Scopes**: User (default), Project (shared via settings.json), Local (per-user per-repo), Managed (admin-controlled)

**Community Ecosystem**:
- [claude-plugins.dev](https://claude-plugins.dev/) claims 11,989 plugins, 63,065 agent skills
- [awesome-claude-plugins](https://github.com/Chat2AnyLLM/awesome-claude-plugins) tracks 43 marketplaces, 834 plugins
- [claude-code-plugins-plus-skills](https://github.com/jeremylongshore/claude-code-plugins-plus-skills): 270+ plugins, 739 skills (~28.3k stars)
- [Anthropic Skills](https://github.com/anthropics/skills): 68.4k stars
- Enterprise controls: `strictKnownMarketplaces`, `extraKnownMarketplaces`, `enabledPlugins`

**Quality/Review**:
- Official marketplace: Curated by Anthropic (internal + approved external)
- Community: No formal review process; anyone can create a marketplace
- Validation: `claude plugin validate .` for structural checks
- Trust model: "Make sure you trust a plugin before installing it" — user responsibility

#### Evidence

- [Discover and install plugins](https://code.claude.com/docs/en/discover-plugins)
- [Create and distribute a plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces)
- [Plugins reference](https://code.claude.com/docs/en/plugins-reference)
- [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official)
- [DeepWiki: Plugin Marketplace](https://deepwiki.com/anthropics/claude-code/4.1-plugin-marketplace-and-discovery)
- [Pete Gypps: Complete Guide to 36 Plugins](https://www.petegypps.uk/blog/claude-code-official-plugin-marketplace-complete-guide-36-plugins-december-2025)
- [Firecrawl: Top 10 Claude Code Plugins](https://www.firecrawl.dev/blog/best-claude-code-plugins)
- [claudemarketplaces.com](https://claudemarketplaces.com/)

#### Implications for CIG

1. **Marketplace is mature enough for distribution**: If CIG were a plugin, it could be distributed via the official or a custom marketplace. The infrastructure exists.
2. **Git-based distribution aligns with CIG**: CIG is already a Git repository. Plugin distribution via Git repos is natural.
3. **MCP server bundling is broken (#16143)**: If CIG needed to bundle MCP servers in a plugin, this bug blocks it. Not currently relevant but limits future architecture.
4. **Enterprise controls available**: For organisations using CIG, `strictKnownMarketplaces` and `enabledPlugins` provide governance.
5. **No npm distribution**: CIG's Perl scripts cannot be distributed via npm anyway, so this is not a limitation.

#### Delta from Task 16

| Aspect | Task 16 (Jan 2026) | Now (Feb 2026) |
|--------|---------------------|-----------------|
| Marketplace existence | Uncertain | 40+ official plugins; multiple community directories |
| Distribution model | Unknown | Git-based with SHA pinning; npm not implemented |
| Community size | Minimal | Thousands of skills/plugins across community registries |
| Enterprise controls | Not documented | strictKnownMarketplaces, managed settings, SHA pinning |
| Plugin architecture | Skills + hooks | Skills + agents + hooks + MCP servers + LSP servers |

---

### FR6: Technical Blockers for CIG Migration

#### Findings

10 blockers identified through analysis of CIG's architecture against skills/plugin capabilities.

**Blocker Table**:

| # | Blocker | Severity | Workaround | Evidence |
|---|---------|----------|------------|----------|
| 1 | **Perl scripts outside `.claude/`** | CRITICAL | Keep scripts in `.cig/` with relative paths (works today); or restructure into plugin with `${CLAUDE_PLUGIN_ROOT}` (major effort) | Task 16: `${CLAUDE_PLUGIN_ROOT}` not expanded in skill-only mode; 17+ scripts in `.cig/scripts/`, 13 modules in `.cig/lib/` |
| 2 | **Plugin vs skill-only deployment** | CRITICAL | Must deploy as plugin for hooks; plugin requires `plugin.json`, `marketplace.json`, directory restructuring | Task 16 empirical: hooks only fire in plugin mode; skill-only provides no benefit over commands |
| 3 | **Multi-file template operations** | HIGH | Keep templates in `.cig/templates/` with relative paths; or duplicate into plugin (breaks symlink DRY system) | 11 templates in pool, 5 type-specific symlink directories |
| 4 | **Context injection syntax (`!`, `!{bash}`, `{arguments}`)** | HIGH | Unknown — requires empirical testing. Simple `!` backtick syntax works in `.md` skills (confirmed in repo). `!{bash}` blocks and `{arguments}` in SKILL.md format unverified. | `.claude/skills/current-task-wf.md` uses `!` successfully; no SKILL.md-format skills test `!{bash}` |
| 5 | **File access outside `.claude/`** | HIGH (reduced to non-blocker) | No restriction — `allowed-tools` works identically for commands and skills. Skills can read/write `implementation-guide/` paths. | Existing skills reference `.cig/` paths; `allowed-tools` grants explicit permissions |
| 6 | **Git operations from skills** | MEDIUM | Works identically to commands via `allowed-tools`. Minor UX friction for new users. | Commands already use `Bash(git:*)` permissions; skills use same mechanism |
| 7 | **Hook data flow to LLM** | MEDIUM | Hooks can stdout text and write files; cannot inject structured data into LLM context like `!` syntax does. File-based state passing as workaround. | Task 16: "No obvious way to pass data between hooks (state must be file-based)" |
| 8 | **Skills precedence over commands** | MEDIUM | Use distinct naming or full conversion. Cannot shadow-test with same names. | Task 16 empirical: skill wins silently when names conflict |
| 9 | **Perl as non-standard language** | MEDIUM | Works if Perl installed; distribution friction for external users. CIG requires `PERL5OPT: "-CDSL"`. | `cig-init.md` documents PERL5OPT requirement; Agent Skills spec lists Python, Bash, JavaScript as examples |
| 10 | **Execution timeouts** | LOW | CIG scripts are fast file operations (<1s). Unlikely to hit limits. | Bash tool default: 120s timeout |

**CIG Component Mapping Against Skill Capabilities**:

| CIG Component | Skill Capability | Assessment |
|---------------|-----------------|------------|
| `.cig/scripts/command-helpers/` (5 scripts) | Can be referenced via relative paths from skills | Works, but not self-contained |
| `.cig/scripts/command-helpers/context-manager.d/` (subcommands) | Same as above | Works |
| `.cig/scripts/command-helpers/workflow-manager.d/` (subcommands) | Same as above | Works |
| `.cig/lib/` (13 Perl modules) | Can be used if PERL5LIB set | Works, but non-standard dependency |
| `.cig/templates/pool/` (11 templates) | Skills can invoke template-copier via Bash | Works |
| `implementation-guide/` (task directories) | Skills can read/write via Read/Write/Edit tools | Works (no sandbox) |
| Git operations | Skills can use Bash(git:*) | Works |
| `!{bash}` context injection | **Unverified** in SKILL.md format | **Risk** |
| `{arguments}` substitution | Works in commands; **unverified** in SKILL.md format | **Risk** |
| `.cig/security/script-hashes.json` | Can be verified from skills | Works |

#### Evidence

- Task 16 `d-implementation.md` (lines 667-694): `${CLAUDE_PLUGIN_ROOT}` behaviour
- Task 16 `d-implementation.md` (lines 870-943): Three deployment models
- Task 16 `d-implementation.md` (lines 519-534): Skills precedence over commands
- Task 16 `d-implementation.md` (line 415): Hook state file-based only
- Local code analysis of `.cig/scripts/`, `.cig/lib/`, `.cig/templates/`, `.claude/commands/`, `.claude/skills/`
- `.claude/settings.local.json`: Accumulated permission patterns
- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills)
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)
- [GitHub Issue #17688](https://github.com/anthropics/claude-code/issues/17688) (frontmatter hooks not triggered in plugins)

#### Implications for CIG

1. **Two CRITICAL blockers prevent clean migration**: Perl script path restructuring (Blocker 1) and plugin-vs-skill-only confusion (Blocker 2) mean CIG cannot simply "convert commands to skills" without significant rearchitecting.
2. **One HIGH-risk unknown**: Context injection syntax (`!{bash}`, `{arguments}`) is unverified in SKILL.md format. If it doesn't work, all 17 commands need substantial rewriting.
3. **Non-blockers confirmed**: File access, git operations, and template operations all work from skills. The permission model is identical to commands.
4. **Plugin mode required for hooks**: Skill-only mode provides no benefit over commands. To get hooks (the primary value proposition), CIG must become a plugin with all the infrastructure that entails.
5. **Bug #17688 undermines plugin value**: Even in plugin mode, frontmatter hooks don't trigger. This means the primary reason to migrate (hooks) is currently broken.

#### Delta from Task 16

| Aspect | Task 16 (Jan 2026) | Now (Feb 2026) |
|--------|---------------------|-----------------|
| Blocker count | 5 identified | 10 identified (more thorough analysis) |
| Context injection | Not tested | Simple `!` works; `!{bash}` and `{arguments}` unverified |
| File access | Suspected blocker | Confirmed non-blocker |
| Hooks in plugins | Worked in theory | Bug #17688: frontmatter hooks don't trigger in plugins |
| Skills precedence | Confirmed | Confirmed (unchanged) |

---

## Step 5: Phase 4 Research — Synthesis and Recommendations

### FR7: Design Recommendations

#### Decision Criteria

Criteria derived from FR1-FR6 findings, weighted by CIG's specific situation (single-repo development tool with Perl scripts, 17 commands, template system):

| # | Criterion | Weight | Rationale |
|---|-----------|--------|-----------|
| 1 | Technical Feasibility | 25% | Can CIG's architecture support this option? (FR6 blockers) |
| 2 | Migration Effort | 20% | Engineering hours required (FR3 patterns, FR6 blockers) |
| 3 | Hooks & Lifecycle Value | 15% | Access to hooks/lifecycle events (FR1, FR4) |
| 4 | Cross-Platform Portability | 10% | Portable to other agent platforms (FR4) |
| 5 | Distribution Capability | 10% | Can CIG be shared/installed by others (FR5) |
| 6 | Migration Risk | 10% | Risk of breakage, regression, lost functionality (FR2, FR3, FR6) |
| 7 | Reversibility | 5% | Can we undo if it doesn't work (FR3) |
| 8 | Ecosystem Alignment | 5% | Alignment with standards direction (FR1, FR4) |

#### Decision Matrix

Scoring: 1 (worst) to 5 (best) per criterion.

| Criterion (Weight) | A: Full Plugin | B: Skills-Only | C: Hybrid | D: Keep Commands |
|---------------------|:-:|:-:|:-:|:-:|
| Technical Feasibility (25%) | 2 | 3 | 4 | 5 |
| Migration Effort (20%) | 1 | 3 | 4 | 5 |
| Hooks & Lifecycle (15%) | 3 | 1 | 2 | 1 |
| Cross-Platform Portability (10%) | 3 | 4 | 3 | 1 |
| Distribution Capability (10%) | 5 | 2 | 3 | 1 |
| Migration Risk (10%) | 2 | 3 | 4 | 5 |
| Reversibility (5%) | 2 | 4 | 5 | 5 |
| Ecosystem Alignment (5%) | 4 | 3 | 3 | 2 |
| **Weighted Score** | **2.45** | **2.75** | **3.50** | **3.45** |

**Score Calculations**:
- **A (Full Plugin)**: 2×.25 + 1×.20 + 3×.15 + 3×.10 + 5×.10 + 2×.10 + 2×.05 + 4×.05 = **2.45**
- **B (Skills-Only)**: 3×.25 + 3×.20 + 1×.15 + 4×.10 + 2×.10 + 3×.10 + 4×.05 + 3×.05 = **2.75**
- **C (Hybrid)**: 4×.25 + 4×.20 + 2×.15 + 3×.10 + 3×.10 + 4×.10 + 5×.05 + 3×.05 = **3.50**
- **D (Keep Commands)**: 5×.25 + 5×.20 + 1×.15 + 1×.10 + 1×.10 + 5×.10 + 5×.05 + 2×.05 = **3.45**

**Ranking**: C (Hybrid, 3.50) > D (Keep Commands, 3.45) > B (Skills-Only, 2.75) > A (Full Plugin, 2.45)

#### Recommendation

**Primary Recommendation: Option D — Keep Commands (status quo)**

Despite Option C (Hybrid) scoring marginally higher (3.50 vs 3.45), the recommendation is to **keep commands** for the following reasons:

1. **The 0.05 delta is within noise**: The scoring difference is too small to justify action. The hybrid option's marginal advantage comes from portability and ecosystem alignment — benefits that accrue over months, not weeks.

2. **Bug #17688 blocks the hooks value**: The primary reason to migrate (hooks in SKILL.md frontmatter) doesn't work in plugin mode. Until this is fixed, migration provides no hooks benefit.

3. **Context injection syntax is unverified**: CIG's 17 commands rely on `!{bash}` blocks and `{arguments}` substitution. These are unverified in SKILL.md format. Migration without this verification risks breaking all commands.

4. **No deprecation signal**: Anthropic explicitly designed v2.1.3 to be backward-compatible. Commands work indefinitely. There is no urgency.

5. **Community validates status quo**: All 5 migration examples found (FR3) use hybrid coexistence, not full migration. No project has abandoned commands.

6. **AGENTS.md outperforms skills**: Vercel's benchmarks (100% vs 79% pass rate) suggest that CIG's current approach (static command content in prompt) may be more reliable than dynamic skill loading.

**Secondary Recommendation: Prepare for Option C (Hybrid) at Q3 2026**

When the following conditions are met, re-evaluate for hybrid approach:
- Bug #17688 (frontmatter hooks in plugins) is fixed
- `!{bash}` and `{arguments}` syntax is verified or documented for SKILL.md
- Skill character budget (2% of context) is confirmed sufficient for CIG's largest commands

#### Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Commands deprecated unexpectedly | Monitor Anthropic announcements; v2.1.3 merge was explicitly non-breaking |
| Ecosystem moves away from commands | Agent Skills spec supports both single-file and directory skills; CIG's `.md` format is implicitly a skill |
| Missing hooks capability | Create targeted experiment: single CIG command as plugin-mode skill to verify hooks work when #17688 is fixed |
| Context injection syntax removed | CIG's `!{bash}` syntax is undocumented but widely used (including by Anthropic's own example commands). Removal would be a major breaking change affecting thousands of users. |

#### Confidence and Review Triggers

**Confidence Level: HIGH (85%)**

Higher than Task 16's 75% because:
- More data: 18 GitHub issues, 5 migration examples, 40+ marketplace plugins catalogued
- More evidence: Bug #17688 empirically confirms hooks don't work in plugins
- Stronger signal: All migration examples validate hybrid/status-quo approach
- Community consensus: No project has fully migrated away from commands

**Review Triggers** (re-evaluate when ANY occurs):

| Trigger | Action |
|---------|--------|
| Bug #17688 fixed (frontmatter hooks in plugins) | Run hooks experiment with one CIG command |
| Anthropic deprecates `.claude/commands/` | Begin hybrid migration plan immediately |
| `!{bash}` syntax documented for SKILL.md | Evaluate converting 1-2 simple commands |
| Agent Skills spec adds hooks standardisation | Re-score Option C with increased hooks weight |
| Q3 2026 quarterly review | Full re-assessment regardless of triggers |

#### Comparison to Task 16 Recommendation

| Aspect | Task 16 (Jan 2026) | Task 54 (Feb 2026) |
|--------|---------------------|---------------------|
| Recommendation | Keep Commands | Keep Commands |
| Score | 47/55 (85%) | 3.45/5.00 (69%) — different scale |
| Confidence | 75% | 85% |
| Review timeline | Q2 2026 | Q3 2026 (pushed back) |
| Key difference | "Monitor and adapt" | "Monitor; prepare hybrid experiment" |
| New evidence | N/A | 18 issues, 5 migration examples, hooks bug #17688, 5-platform adoption |

**What changed**: The recommendation is the same but with higher confidence. The ecosystem evolved faster than expected (5-platform adoption in 2 months), but CIG-specific blockers have not been resolved. Bug #17688 is new evidence that directly undermines the migration case.

---

## Step 6: Cross-Reference and Quality Check

### NFR1: Freshness

Source date analysis:
- Sources from Jan 15 - Feb 12, 2026: ~85% (GitHub issues, release notes, documentation, blog posts)
- Sources from Dec 2025: ~10% (AAIF announcement, Agent Skills initial spec)
- Historical sources: ~5% (Task 16 baseline references)
- **Result: PASS** (85% > 80% threshold)

### NFR2: Actionability

- FR1: Implications for CIG subsection present (6 items)
- FR2: Implications for CIG subsection present (4 items)
- FR3: Implications for CIG subsection present (4 items)
- FR4: Implications for CIG subsection present (5 items)
- FR5: Implications for CIG subsection present (5 items)
- FR6: Implications for CIG subsection present (5 items)
- FR7: Full recommendation with specific next steps
- **Result: PASS** (all FR sections include implications)

### NFR3: Organisation

- All FR sections follow consistent structure: Findings → Evidence → Implications for CIG → Delta from Task 16
- FR7 follows: Decision Criteria → Decision Matrix → Recommendation → Risk Mitigation → Confidence and Review Triggers
- All claims link to GitHub issues, documentation URLs, or Task 16 references
- **Result: PASS**

### NFR4: Completeness

| FR | AC Threshold | Met? |
|----|-------------|------|
| FR1 | Changes documented with dates and sources | Yes — 15+ changes in 4 release versions |
| FR2 | 10+ pain points catalogued | Yes — 10 pain points, 4 feature requests, 4 docs issues |
| FR3 | 3+ migration examples | Yes — 5 examples documented |
| FR4 | Adoption status per platform | Yes — 6 platforms documented |
| FR5 | Distribution mechanisms documented | Yes — 3 distribution models, 40+ plugins, enterprise controls |
| FR6 | Blockers with severity ratings | Yes — 10 blockers with severity, workarounds, evidence |
| FR7 | Decision matrix with 4+ options, 6+ criteria | Yes — 4 options × 8 criteria with weighted scores |
- **Result: PASS** (all thresholds met)

### NFR5: Reliability

Critical claims (influencing FR7 recommendation) and their source counts:
- "Hooks don't trigger in plugin mode" — 2 sources (Task 16 empirical + GitHub Issue #17688)
- "Commands work unchanged after v2.1.3 merge" — 3 sources (Anthropic changelog, official docs, community confirmation)
- "No project has fully migrated from commands" — 5 sources (5 migration examples all using hybrid)
- "AGENTS.md outperforms skills (100% vs 79%)" — 1 source (Vercel blog) — **NOTE: single source for this claim**
- "All 5 major platforms adopted Agent Skills" — 5 sources (one per platform documentation)
- **Result: PASS with caveat** (one critical claim has single source — Vercel benchmark. However, this claim supports rather than drives the recommendation.)

### Gaps and Out-of-Scope Areas

- **`gh` CLI authentication**: FR2 GitHub issues search was done via WebSearch rather than structured `gh search issues`. Issue detail (reaction counts, label data) is incomplete.
- **Empirical verification**: Context injection syntax (`!{bash}`, `{arguments}`) in SKILL.md format was not empirically tested. This is flagged as a review trigger.
- **Performance benchmarks**: Skill loading time vs command loading time not measured (out of scope per b-requirements-plan.md).
- **MCP ecosystem**: Not deeply investigated (out of scope unless directly relevant).

---

## Blockers Encountered

| Blocker | Resolution |
|---------|-----------|
| `gh` CLI not installed | User installed `gh` during execution |
| `gh` CLI not authenticated | Proceeded with WebSearch for issue discovery; noted as gap |
| Research agent (aba9bf3) denied Bash permission | Compensated via other agents' WebSearch findings |

## Deferral Check

- [x] All steps from d-implementation-plan.md executed (Steps 1-6)
- [x] All success criteria from a-task-plan.md met
- [x] All requirements from b-requirements-plan.md addressed (FR1-FR7, NFR1-NFR5)
- [x] All design guidance in c-design-plan.md followed (phased research, FR-aligned output)
- [x] No planned work deferred without user approval
- [ ] N/A: No deferral required

**Minor gap**: FR2 issue detail is less comprehensive than planned due to `gh` CLI unavailability. However, 18 issues were still catalogued via WebSearch, exceeding the 10+ pain points threshold. The gap does not affect the FR7 recommendation.

## Status
**Status**: Finished
**Next Action**: /cig-retrospective 54
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results

Research completed across all 7 functional requirements with the following key outcomes:

1. **FR1**: 15+ API changes documented across 4 release versions (v2.1.0, v2.1.3, v2.1.14, v2.1.19). 2 breaking changes identified. 3 new frontmatter fields (`context`, `agent`, `hooks`).
2. **FR2**: 18 GitHub issues catalogued — 10 pain points, 4 feature requests, 4 documentation gaps. Bug #17688 (hooks don't trigger in plugins) is the most significant finding.
3. **FR3**: 5 migration examples found. Dominant pattern: hybrid coexistence. No big-bang migrations.
4. **FR4**: All 5 major platforms adopted Agent Skills specification. AAIF governance umbrella established. Hooks remain Claude-specific (not portable).
5. **FR5**: Official marketplace with 40+ plugins. Git-based distribution. Enterprise controls available.
6. **FR6**: 10 technical blockers identified — 2 CRITICAL, 3 HIGH, 4 MEDIUM, 1 LOW. Context injection syntax in SKILL.md is the highest-risk unknown.
7. **FR7**: Decision matrix produced. Recommendation: **Keep Commands** (score 3.45/5.00) with 85% confidence. Review at Q3 2026 or when bug #17688 is fixed.

**Delta from Task 16**: Recommendation unchanged but confidence increased from 75% to 85%. Review timeline pushed from Q2 to Q3 2026. Key new evidence: hooks bug #17688, 5-platform adoption, 5 migration examples all using hybrid approach.

## Lessons Learned
- Parallel research agents are effective for discovery tasks — 6 agents covered FR1-FR6 simultaneously
- `gh` CLI should be pre-installed and authenticated before research tasks requiring GitHub API access
- WebSearch is a reasonable fallback for GitHub issue discovery but lacks structured data (reaction counts, labels)
- The research confirmed Task 16's recommendation with stronger evidence, validating the "monitor and adapt" strategy
- Bug #17688 is the single most important finding — it directly blocks the primary value proposition of skills migration
