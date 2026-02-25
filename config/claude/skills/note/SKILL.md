---
name: note
description: Save conversation insights as an Obsidian note
disable-model-invocation: true
argument-hint: "[topic]"
allowed-tools: Read, Glob, Grep, Write, WebSearch, WebFetch
---

## Obsidian Note: $ARGUMENTS

### Instructions

1. Analyze the conversation to identify key insights, learnings, and decisions
2. If `$ARGUMENTS` provides specific direction (e.g., "TypeScriptの型パターンについて"), focus on that topic
3. If `$ARGUMENTS` is vague (e.g., "まとめて"), synthesize the most valuable takeaways

### Output

**File path:** `/Users/mackay/Google Drive/My Drive/ObsidianVault/memory/YYMMDD_タイトル.md`
- `YYMMDD` = today's date (e.g., 260225)
- タイトル = concise Japanese or English title

**Body:**
- Write in Japanese
- Use headings (`##`) and bullet points
- Be concise but capture essential knowledge
- Include code snippets where relevant
- Focus on actionable insights, not conversation play-by-play

### Rules

- One note per invocation
- If a similar note exists in the memory directory, ask whether to update or create new
- Keep notes focused -- split into multiple invocations if topics are unrelated
