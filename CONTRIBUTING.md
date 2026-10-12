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
   luac -p ReagentTooltipEnhancer/*.lua tests/*.lua
   lua tests/smoke.lua
   lua tests/options_smoke.lua
   ```

4. Update `CHANGELOG.md` for user-facing changes.
5. Avoid adding runtime libraries unless the benefit clearly outweighs the addon size and maintenance cost.

## Style

- Use four spaces for Lua indentation.
- Prefer descriptive names over abbreviations.
- Keep tooltip text concise and consistent with the default WoW interface.
- Guard client API calls that may be absent or temporarily unavailable.

## Development

The addon has no runtime dependencies. Run the scanner-to-tooltip and options smoke tests with a standalone Lua interpreter:

```sh
lua tests/smoke.lua
lua tests/options_smoke.lua
```

The code is written for WoW's Lua environment. A standalone Lua interpreter is useful for these smoke tests but cannot reproduce every client API behavior.

## Releasing

Update the version in `ReagentTooltipEnhancer/ReagentTooltipEnhancer.toc` and add a dated entry to `CHANGELOG.md` before tagging a release. Run both smoke tests and Lua syntax checks, then push the release commit and its matching tag (for example, `v0.2.1`) to GitHub and publish a GitHub release with the installable addon ZIP.

CurseForge is configured to package tagged commits. An active GitHub push webhook pointing to the project's CurseForge packaging endpoint is also required, as described in [Automatic Packaging](https://support.curseforge.com/support/solutions/articles/9000197281-automatic-packaging). Keep its token in the webhook configuration, outside the repository. Pushing a stable tag triggers packaging as a release; tags containing `alpha` or `beta` select those release types. Publishing a GitHub release alone does not replace the tag push.

The root `.pkgmeta` sets the addon folder name, moves the repository's addon subdirectory into the installable ZIP root, excludes tests and contributor documentation, and supplies the changelog and license. Check the webhook delivery and the [CurseForge files page](https://www.curseforge.com/wow/addons/reagent-tooltip-enhancer/files) after pushing a tag to verify that packaging completed.
