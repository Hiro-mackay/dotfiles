## Effort

Claude Code only; the rules above are shared with Codex and don't cover this.

Effort controls how much you think, not how much you say. To shorten output, the Communication rules and the output style do that -- lowering effort does not. Session default is `medium` (`modelSettings.<model>.effortLevel` in settings.json; the top-level `effortLevel` only covers models up to Opus 5).

- Balance usage with completion time and avoiding rework. Keep the configured model and `medium` default; do not require manual model switching for routine work
- Reserve `low` for bounded mechanical work; do not lower effort merely to shorten the response
- Demanding work -- ambiguous design, difficult debugging, or changes with costly failures: suggest `high`. Reserve `xhigh` for tasks that need deeper reasoning
- `max`: only when the task justifies unbounded token spend. Session-only, set with `/effort max`; it is not accepted in settings.json
- Suggest an effort change only when it materially affects the requested work. I change it with `/effort`; continue authorized work at the current setting otherwise

## Auto memory: the user

When the user's way of thinking shows in a conversation, save it as a `user` memory: their values, a judgment and its reason, or what energized or frustrated them.

- Quote the user's words that support it, verbatim, with the date and session.
- Never translate the user's words.
