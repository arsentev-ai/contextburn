# contextburn for VS Code

A status bar meter for Claude Code sessions: **what share of the tokens you paid for became model output**,
and how much was the agent re-reading context it had already sent.

![demo](https://raw.githubusercontent.com/arsentev-ai/contextburn/main/assets/readme/demo.gif)

The status bar shows useful work as a percentage of cost over the last few hours. Hover for the token view;
click for the full breakdown — sessions, peak context, and what filled it.

## Requirements

The extension is a thin front-end for the [contextburn](https://github.com/arsentev-ai/contextburn) CLI:

```bash
pip install contextburn
```

It reads the transcripts Claude Code already writes on your machine. Nothing leaves the machine.

## Settings

| setting | default | meaning |
|---|---|---|
| `contextburn.command` | `contextburn` | path to the CLI |
| `contextburn.hours` | `5` | window the status bar measures |
| `contextburn.refreshSeconds` | `120` | refresh interval |
| `contextburn.metric` | `cost` | `cost` or `tokens` |

## Why this number

In 36 controlled runs of the same twelve tasks, 94% of paid tokens re-read context that had already been sent,
and cost followed a U-curve in session length — report: DOI [10.5281/zenodo.22699668](https://doi.org/10.5281/zenodo.22699668).

Author: [Evgenii Arsentev](https://arsentev.ai) · MIT
