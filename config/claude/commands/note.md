---
allowed-tools: Read, Glob, Grep, Write, WebSearch, WebFetch
description: Save conversation insights as an Obsidian note
---

## Obsidian Note Generator

Create a structured knowledge note from the current conversation context and `$ARGUMENTS`.

### Instructions

1. Analyze the conversation to identify key insights, learnings, and decisions
2. If `$ARGUMENTS` provides specific direction (e.g., "TypeScriptの型パターンについて"), focus the note on that topic
3. If `$ARGUMENTS` is vague (e.g., "まとめて"), synthesize the most valuable takeaways from the conversation

### Output Format

**File path:** `/Users/mackay/Google Drive/My Drive/ObsidianVault/memory/YYMMDD_タイトル.md`
- `YYMMDD` = today's date (e.g., 260223)
- タイトル = concise Japanese or English title describing the content

**Frontmatter:**
```yaml
---
tags:
  - Note
  - (add 1-3 relevant topic tags)
---
```

**Body:**
- Write in Japanese
- Use headings (`##`) and bullet points for structure
- Be concise but capture the essential knowledge
- Include code snippets where relevant (with language annotation)
- Focus on actionable insights, not conversation play-by-play

### Rules

- One note per invocation
- If a note with similar content already exists in the memory directory, mention it and ask whether to update or create a new one
- Keep notes focused -- split into multiple invocations if topics are unrelated
