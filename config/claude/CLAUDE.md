See @~/.config/agents/AGENTS.md for global instructions.

## Effort

Claude Code only; the rules above are shared with Codex and don't cover this.

Effort controls how much you think, not how much you say. To shorten output, the Voice and Communication rules do that -- lowering effort does not. Session default is `high` (`effortLevel` in settings.json).

- Routine work -- single-file edits, mechanical batches, straightforward questions: `medium` or `low`. These are the primary control for cost and latency, not a last resort
- Demanding work -- multi-file features, large refactors, wide investigations, long agentic runs: `xhigh`
- `max`: only when the task justifies unbounded token spend. Session-only, set with `/effort max`; it is not accepted in settings.json
- When the current level looks wrong for what I asked, say so and say which way. I change it with `/effort`
