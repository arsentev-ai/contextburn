# tokmon

**How much of what your coding agent spends is actually work.**

Token counters answer *"how much did I spend?"* — there are plenty of them. `tokmon` answers a
different question: **what share of the paid tokens became model output, and what share was the
agent re-reading context it had already sent?** That share is a normalised number, so it can be
compared across sessions, models, tools and ways of working. An absolute counter cannot do that.

```
$ tokmon detail 24
=== SPEND BREAKDOWN, 24.0h · 11.09 19:10 ===

TOTAL 3.1kkk tokens

=== RUN EFFICIENCY ===
  useful work (model output)          0.18% of tokens
  context re-reading                  98.4% of tokens
  useful work, cost-weighted           6.7%
  one useful token costs               555 paid tokens
```

## Why two efficiency numbers

They are reported separately on purpose, because they measure different things.

- **By tokens** the share barely moves. It is a property of how agents work: every step resends
  the accumulated context, so re-reading dominates whatever you do.
- **Cost-weighted** the share does move, because cached reads are priced far below fresh input
  and output. It depends on how you run sessions — and that part is under your control.

In a controlled comparison of the same 12 programming tasks run as one long session versus twelve
short ones (3 runs each, all tests passing), token efficiency was **1.11 % vs 1.12 %** — no
difference — while cost-weighted efficiency was **31.6 % vs 24.6 %**. The token share describes the
agent; the cost share describes the operator. A plain counter shows neither.

The underlying experiment, with dataset and analysis scripts:
[Clear Every Third Task: A Measured U-Curve in the Context Economy of Coding Agents](https://doi.org/10.5281/zenodo.22699668).

## What it reads

Local Claude Code transcripts (`~/.claude/projects/**/*.jsonl`) — the files the CLI already writes
on your own machine. **Nothing leaves the machine: `tokmon` makes no network calls at all.**

Usage records are deduplicated by message id and reconciled with an element-wise maximum, because a
streaming runtime writes an early snapshot and a final record for the same model call: counting both
double-counts the call, and keeping only the first halves the output.

## Install

```bash
cp bin/tokmon ~/bin/tokmon && chmod +x ~/bin/tokmon   # python3 only, no dependencies
tokmon
```

## Usage

| command | what it shows |
|---|---|
| `tokmon` | what is burning tokens right now |
| `tokmon detail [hours]` | run efficiency, sessions, and what specifically inflated the context |
| `tokmon window` | the current 5-hour subscription window |
| `tokmon --json` | machine-readable state (used by the menu-bar app) |
| `tokmon --probe <hours>` | raw JSON dump of the parsed sessions |

### Configuration

| setting | default | meaning |
|---|---|---|
| `TOKMON_LANG` or `~/.config/tokmon/lang` | `en` | interface language: `en` or `ru` |
| `TOKMON_DAY_START` | `6` | hour your day starts — the daily total resets here, not at midnight |
| `TOKMON_WARN` | `30000000` | tokens/hour that turns the menu-bar counter yellow |
| `TOKMON_ALARM` | `90000000` | tokens/hour that turns it red |

The language file exists because the menu-bar app is launched from Finder, where environment
variables never reach it. `echo ru > ~/.config/tokmon/lang` switches both the app and the CLI.
Russian command aliases (`разбор`, `окно`) also work.

## Menu-bar app (macOS)

`app/main.swift` is a small status-bar app: it polls `tokmon --json` once a minute and shows the
current burn rate in the menu bar, with an hourly graph. Click a bar to see that hour's breakdown.

```bash
swiftc -O -o TokMon app/main.swift
```

Point it at the CLI with `TOKMON_BIN=/path/to/tokmon` if it is not in `~/bin` or the usual
Homebrew locations.

## Notes

- Prices are per-million-token rates for current Claude models and live at the top of
  `bin/tokmon`. Update them there when they change; the cost-weighted share depends on them.

## Citing

If you use `tokmon` or its efficiency measure in your work, GitHub's **"Cite this repository"**
button gives the reference — metadata is in [`CITATION.cff`](CITATION.cff).

## Author

Evgenii Arsentev — [arsentev.ai](https://arsentev.ai) ·
ORCID [0000-0002-9120-7298](https://orcid.org/0000-0002-9120-7298)

## License

MIT — see [LICENSE](LICENSE).
