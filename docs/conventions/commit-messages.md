# Commit Message Conventions

This document describes the commit message format used in this project, following Linux kernel conventions.

## Format Structure

```
<subject line - max 50 chars>

<body - wrap at 72 chars>

<trailers>
```

## Subject Line

- Maximum 50 characters
- Start with capital letter
- No period at the end
- Use imperative mood ("Add feature" not "Added feature")
- Prefix with component/area if applicable ("docs: Update README")

## Body

- Wrap at 72 characters
- Separate from subject with blank line
- Explain **what** and **why**, not **how**
- Use present tense ("Fix bug" not "Fixed bug")
- Can include multiple paragraphs
- Can reference issues/tickets

## Trailers

Trailers are key-value pairs at the end of the commit message following Linux kernel conventions:

### Standard Trailers

- **Signed-off-by:** Legal certification under Developer Certificate of Origin (DCO)
  - Format: `Signed-off-by: Your Name <your.email@example.com>`
  - Required: Only humans can sign off (legal certification)
  - Meaning: Certifies you have rights to submit this work

- **Co-developed-by:** Substantial contribution by another developer or AI
  - Format: `Co-developed-by: Name <email@example.com>`
  - For AI: `Co-developed-by: <AI-Model-Name> <model-id>`
  - Example: `Co-developed-by: Claude Sonnet 4.5 claude-sonnet-4-5-20250929`
  - Use when: AI substantially contributed to the code/design
  - Note: Must be followed by Signed-off-by from the human submitter

- **Reviewed-by:** Code has been reviewed
  - Format: `Reviewed-by: Reviewer Name <email@example.com>`

- **Tested-by:** Code has been tested
  - Format: `Tested-by: Tester Name <email@example.com>`

- **Reported-by:** Bug reporter credit
  - Format: `Reported-by: Reporter Name <email@example.com>`

- **Suggested-by:** Credit for suggesting the approach
  - Format: `Suggested-by: Name <email@example.com>`

- **Fixes:** References commit that this fixes
  - Format: `Fixes: <commit-hash> ("commit title")`

- **Link:** Reference to discussion/issue
  - Format: `Link: https://github.com/org/repo/issues/123`

## AI Attribution

When AI coding assistants substantially contribute to a commit:

1. Use **Co-developed-by:** trailer with AI identification
2. Human must add **Signed-off-by:** after the AI attribution
3. AI cannot sign off (Signed-off-by is a legal certification)

### Format

```
Subject line describing the change

Body explaining what and why.

Co-developed-by: <AI-Model-Name> <model-id>
Signed-off-by: Your Name <your.email@example.com>
```

### Rationale

This follows the Linux kernel RFC proposal for AI attribution:
- **Co-developed-by:** indicates substantial AI contribution
- Human **Signed-off-by:** maintains legal accountability
- Transparent about AI involvement in development

## Example Commits

### Simple commit (no AI)

```
Fix typo in README

Correct spelling of "receive" in installation section.

Signed-off-by: Matt Developer <matt@example.com>
```

### AI-assisted commit

```
Add hierarchical task status aggregation

Implement status-aggregator script that traverses task hierarchy
and calculates completion percentages based on workflow file
states. Supports both v2.0 and v2.1 template formats.

Co-developed-by: Claude Sonnet 4.5 claude-sonnet-4-5-20250929
Signed-off-by: Matt Developer <matt@example.com>
```

### Complex commit with multiple trailers

```
Fix race condition in context inheritance

Parent task status was being read without synchronization,
causing intermittent failures when parent workflows were
updated concurrently.

Add file locking to ensure consistent reads.

Reported-by: User Name <user@example.com>
Co-developed-by: Claude Sonnet 4.5 claude-sonnet-4-5-20250929
Signed-off-by: Matt Developer <matt@example.com>
Fixes: abc1234 ("Add context inheritance")
```

## References

- [Linux Kernel Submitting Patches Guide](https://docs.kernel.org/process/submitting-patches.html)
- [Linux Kernel AI Coding Assistants RFC](https://lwn.net/Articles/1031473/)
- [Developer Certificate of Origin](https://developercertificate.org/)

## Sources

- [Linux Kernel AI Coding Assistant Rules Proposal](https://ostechnix.com/linux-kernel-ai-coding-assistants-rules-proposal/)
- [Linux Kernel AI Attribution Documentation](https://lwn.net/Articles/1031473/)
- [Linux Kernel Submitting Patches](https://docs.kernel.org/process/submitting-patches.html)
