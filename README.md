# tokmon

**Where your Claude Code tokens actually go — by machine, by session, and by *reason*.**

Your subscription burns tokens, but the usual question — "which question was expensive?" — is the
wrong one. Spend is **context × turns**: every turn re-reads everything already in the window, so a
token that entered the context on turn 15 of 116 is paid for 101 times. `tokmon` makes that visible.

```
$ tokmon
today  1.07kkk tokens   ·  burn rate 64kk/h

$ tokmon разбор 24
session                          tokens    what inflated the context
my-site · refactor              312kk     file re-reads (47) · long tool output (12)
my-app · release-prep           241kk     subagent transcripts (8)
```

## Why it exists

Long sessions are the expensive ones — not hard ones. A 20-turn chat that keeps a 200k-token
context costs more than fifty short, focused chats. Once you can see that, the fix is boring and
effective: close the topic, clear the context, start the next task in a fresh session.

## What it reads

Local Claude Code transcripts (`~/.claude/projects/**/*.jsonl`) — the files the CLI already writes
on your own machine. Nothing leaves the machine: `tokmon` makes no network calls at all.

## Install

```bash
cp bin/tokmon ~/bin/tokmon && chmod +x ~/bin/tokmon   # needs python3 only, no dependencies
tokmon
```

## Usage

| command | what it shows |
|---|---|
| `tokmon` | what is burning tokens right now |
| `tokmon разбор [hours]` | breakdown: sessions and what specifically inflated the context |
| `tokmon окно` | the current 5-hour subscription window |
| `tokmon --json` | machine-readable state (used by the menu-bar app) |
| `tokmon --probe <hours>` | raw JSON dump of the parsed sessions |

### Configuration

| env var | default | meaning |
|---|---|---|
| `TOKMON_DAY_START` | `06:00` | when *your* day starts — the daily total resets here, not at midnight |
| `TOKMON_WARN` | `30000000` | tokens/hour that turns the menu-bar counter yellow |
| `TOKMON_ALARM` | `90000000` | tokens/hour that turns it red |

## Menu-bar app (macOS)

`app/main.swift` is a tiny `LSUIElement` status-bar app: it polls `tokmon --json` once a minute and
shows the current burn rate in the menu bar, with an hourly graph. Click a bar in the graph to see
the breakdown for that exact hour.

```bash
swiftc -O -o TokMon app/main.swift
```

Point it at the CLI with `TOKMON_BIN=/path/to/tokmon` if it isn't in `~/bin` or the usual Homebrew
locations.

## Notes

- Prices are per-million-token rates for the current Claude models and live at the top of
  `bin/tokmon` — update them there when they change.
- CLI output and comments are currently in Russian; the code itself is plain Python 3 with no
  dependencies. An English translation is a welcome PR.

## License

MIT — see [LICENSE](LICENSE).
