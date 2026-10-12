# Contributing

Thanks for helping improve Reagent Tooltip Enhancer.

## Reporting bugs

Before opening an issue, confirm that the addon is enabled, open the relevant profession once, and run `/rte scan` with that profession window open.

Include:

- Forever client version, build, and interface number.
- The first complete Lua error, if one appears.
- The item and profession involved.
- Steps that reproduce the problem.
- Whether it still occurs with other addons disabled.

Never upload account credentials, authentication tokens, or private server login details.

## Pull requests

1. Keep changes focused and explain the user-facing behavior they alter.
2. Preserve compatibility with WoW's Lua environment.
3. Run the syntax and smoke checks when a Lua interpreter is available:

   ```sh
   luac -p ReagentTooltipEnhancer/*.lua tests/smoke.lua
   lua tests/smoke.lua
   ```

4. Update `CHANGELOG.md` for user-facing changes.
5. Avoid adding runtime libraries unless the benefit clearly outweighs the addon size and maintenance cost.

## Style

- Use four spaces for Lua indentation.
- Prefer descriptive names over abbreviations.
- Keep tooltip text concise and consistent with the default WoW interface.
- Guard client API calls that may be absent or temporarily unavailable.
