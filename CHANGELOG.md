# Changelog

All notable changes to this project will be documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1] - 2026-10-12

### Added

- CurseForge project link and release instructions in the README.
- CurseForge packaging configuration for the installable addon folder, changelog, and license.

### Fixed

- Recipe scans only announce newly added recipes and report the number added. Repeated scans, including manual scans, stay quiet when no recipes are added.

## [0.2.0] - 2026-10-12

### Added

- Per-character profession filters in the addon settings.
- Include-all and exclude-all shortcuts for discovered professions.

## [0.1.0] - 2026-10-12

### Added

- Initial WoW Forever `1.60.1` support.
- Item tooltip lookup for known recipes.
- Profession grouping, profession skill, recipe difficulty, and reagent quantities.
- Compact recipe and food-effect descriptions.
- Per-character recipe caching and automatic profession scanning.
- Native options panel and `/rte` commands.
- Standalone scanner-to-tooltip smoke test.

[Unreleased]: https://github.com/worldofxobu/reagent-tooltip-enhancer/compare/v0.2.1...HEAD
[0.2.1]: https://github.com/worldofxobu/reagent-tooltip-enhancer/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/worldofxobu/reagent-tooltip-enhancer/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/worldofxobu/reagent-tooltip-enhancer/releases/tag/v0.1.0
