# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [0.2.0] — 2026-09-11

### Added
- MCP server (`contextburn mcp`, also installed as `contextburn-mcp`) with `run_efficiency` and
  `spend_breakdown` tools, so an agent can read its own run efficiency.
- `contextburn --efficiency [hours]` prints run efficiency as JSON.

### Changed
- The efficiency calculation is a single function shared by the report, the JSON output and the
  MCP server.

## [0.1.1] — 2026-09-11

### Added
- `CHANGELOG.md` and `CONTRIBUTING.md`.

### Notes
- First release archived on Zenodo with a DOI. Release 0.1.0 was published before the Zenodo
  integration was enabled, so it has no DOI of its own; the code is the same.

## [0.1.0] — 2026-09-11

### Added
- Run efficiency: the share of paid tokens that became model output, reported by tokens and
  cost-weighted by per-model prices.
- English interface by default; Russian via `CONTEXTBURN_LANG=ru` or `~/.config/contextburn/lang`.
- `CITATION.cff` and `codemeta.json` citation metadata.
- `pyproject.toml` for packaging the script.

### Changed
- Renamed from `tokmon` to `contextburn`. `TOKMON_*` environment variables still work.
