# Contributing

Thanks for taking an interest in `contextburn`.

## Reporting a problem

Open an issue with:

- the command you ran and its output;
- your Python version (`python3 --version`) and operating system;
- if a number looks wrong, the model name and a rough session length. Please do not paste
  transcript contents: they can contain private code and prompts.

## Proposing a change

1. Fork the repository and create a branch.
2. Keep the CLI dependency-free: it must run on a stock `python3`.
3. Keep the tool offline: no network calls, no telemetry.
4. If you change how a number is computed, explain the reasoning in the pull request and show
   the output before and after on the same data.
5. Update `CHANGELOG.md` under an "Unreleased" heading.

## Prices

Per-model token prices live at the top of `bin/contextburn`. Updates are welcome when a provider
changes its rates; please link the provider's pricing page in the pull request.

## Language

The interface is English by default. Russian strings sit next to the English ones in `tr(en, ru)`
calls; when you add a user-facing string, add both variants.
