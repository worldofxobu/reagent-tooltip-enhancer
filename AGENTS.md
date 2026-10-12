# Repository guidance

- Read `CONTRIBUTING.md` before changing code or release configuration. Keep changes focused on the request and preserve unrelated work.
- Preserve the addon's supported WoW Forever client and Lua compatibility. Guard unavailable client APIs, keep saved data compatible, and avoid new runtime dependencies unless clearly justified.
- Follow existing code style and native WoW UI conventions. Keep tooltips compact and routine addon behavior quiet.
- Keep `README.md` focused on installing, configuring, and using the addon. Put contributor and release procedures in `CONTRIBUTING.md`; keep agent instructions here. Public addon documentation should contain no conversation history, agent commentary, or internal workflow notes.
- Keep documentation accurate to implemented behavior. Record user-facing addon changes under `Unreleased` in `CHANGELOG.md`; do not rewrite published release history or add routine repository housekeeping to the changelog.
- For Lua changes, run syntax checks and both smoke tests listed in `CONTRIBUTING.md`. For documentation changes, review accuracy, links, and `git diff --check`. Report what was verified and any checks that could not run; do not claim in-game testing without performing it.
- Review the diff before committing. Use focused commits and clear messages. Commit and push when requested or already authorized; do not overwrite unrelated changes or rewrite shared history.
- Change versions, create tags, or publish releases only when requested. Follow the release procedure and verify the installable ZIP layout when changing packaging. Exclude tests, contributor docs, and agent instructions from addon packages.
- Keep credentials and tokens out of repository files, logs, and public documentation.
