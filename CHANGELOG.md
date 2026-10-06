# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Fixed
- Usage records are now deduplicated by message id, keeping the element-wise maximum, as the
  README describes. Claude Code writes one model call as several lines (a streaming snapshot and
  one line per content block), and each line carries the same usage; earlier versions counted
  every line, so token totals and turn counts were inflated (about 1.9x on the last 72 hours of
  transcripts on one machine).

## [0.2.1] — 2026-09-11

### Changed
- MCP Registry name is now `ai.arsentev/contextburn`, verified through the author's domain.
- README and citation metadata point to the concept DOI, which always resolves to the latest
  version: 10.5281/zenodo.22712985.

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
