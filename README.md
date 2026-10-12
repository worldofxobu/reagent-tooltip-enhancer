# Reagent Tooltip Enhancer

Reagent Tooltip Enhancer is a lightweight addon for **World of Warcraft: Forever** that shows which of your character's known recipes use the item under the cursor.

Hover Chunk of Boar Meat to see the Cooking recipes that consume it, or hover a Copper Bar to see matching Blacksmithing and Engineering recipes—without opening every profession window.

## Features

- Adds a native-looking **Used by your recipes** section to item tooltips.
- Lists only recipes learned by the current character.
- Groups results by profession.
- Shows profession skill, recipe difficulty, and reagent quantity.
- Includes shortened food or recipe-effect text when the tooltip remains compact.
- Limits large result sets and reports how many additional recipes matched.
- Caches recipes per character and updates when recipes are learned.
- Lets each character include or exclude individual discovered professions.
- Provides configurable display options without external libraries.

## Compatibility

The current release targets:

- WoW Forever `1.60.1`
- Build `70338`
- Interface `16001`

## Installation

Download the addon from [CurseForge](https://www.curseforge.com/wow/addons/reagent-tooltip-enhancer) or [GitHub Releases](https://github.com/worldofxobu/reagent-tooltip-enhancer/releases/latest).

1. Download the latest addon ZIP and extract it.
2. Copy the `ReagentTooltipEnhancer` directory into the Forever client's `Interface/AddOns` directory.
3. Restart the client, or run `/reload` if the addon was already installed when the client started.
4. Enable **Reagent Tooltip Enhancer** on the character-selection AddOns screen.

The exact Forever game-directory name may differ during beta.

## First-time setup

Open each profession window once after installing the addon. WoW exposes the complete recipe list only while that profession is loaded, so this lets the addon build its item-to-recipe index. New recipes are detected automatically.

Scans report how many new recipes were added and stay quiet when no new recipes are found, including when you run `/rte scan` manually.

Afterward, hover a reagent used by one of your known recipes.

## Configuration

Enter `/rte` to open the addon settings. The following can be configured:

- Enable or disable tooltip additions.
- Group recipes by profession.
- Show profession skill.
- Show recipe difficulty.
- Show required reagent quantity.
- Show crafted item level when available.
- Show shortened recipe or food-effect text.
- Choose which of the current character's discovered professions are included.
- Set the maximum number of recipes and effect-text length.

Use **Include all** or **Exclude all** to toggle all discovered professions for the current character.

Effect descriptions are shown only when three or fewer recipes match, preventing common reagents from producing excessively large tooltips.

## Commands

| Command | Description |
| --- | --- |
| `/rte` | Open addon settings. |
| `/rte scan` | Rescan the currently open profession. |
| `/rte status` | Show cached recipe and profession counts. |
| `/rte clear` | Clear this character's recipe cache. |
| `/rte help` | List available commands. |

## Troubleshooting

If no recipe section appears:

1. Open the relevant profession at least once.
2. Run `/rte status` and confirm recipes are cached.
3. Keep the profession window open and run `/rte scan`.
4. Verify the addon is enabled and not marked out of date.

To capture Lua errors while testing, run:

```text
/console scriptErrors 1
/reload
```

Please include the first complete error and your client build in a [bug report](../../issues/new?template=bug-report.yml).

## Contributing

Bug reports and focused pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) before contributing.

## Author

Created and maintained by **Xobu**.

## License

Released under the [MIT License](LICENSE).

World of Warcraft and Blizzard Entertainment are trademarks or registered trademarks of Blizzard Entertainment, Inc. This project is not affiliated with or endorsed by Blizzard Entertainment.
