// contextburn status bar: runs the local CLI, never sends anything over the network.
const vscode = require("vscode");
const { execFile } = require("child_process");

let item, timer, output;

function cfg() {
  const c = vscode.workspace.getConfiguration("contextburn");
  return { cmd: c.get("command"), hours: c.get("hours"), every: c.get("refreshSeconds"), metric: c.get("metric") };
}

function run(args, cb) {
  const { cmd } = cfg();
  execFile(cmd, args, { timeout: 60000, maxBuffer: 8 * 1024 * 1024 }, cb);
}

function refresh() {
  const { hours, metric } = cfg();
  run(["--efficiency", String(hours)], (err, stdout) => {
    if (err) {
      item.text = "$(flame) contextburn: not found";
      item.tooltip = "Install the CLI: pip install contextburn — or set contextburn.command";
      return;
    }
    let e;
    try { e = JSON.parse(stdout); } catch { item.text = "$(flame) contextburn: ?"; return; }
    if (!e.tokens_total) { item.text = "$(flame) no sessions"; item.tooltip = `No Claude Code sessions in the last ${hours}h`; return; }
    const useful = metric === "tokens" ? e.useful_share_tokens : e.useful_share_cost;
    item.text = `$(flame) ${useful.toFixed(1)}% work`;
    item.tooltip = new vscode.MarkdownString(
      `**contextburn — last ${hours}h, ${e.sessions} sessions**\n\n` +
      `useful work, cost-weighted: **${e.useful_share_cost.toFixed(1)}%**\n\n` +
      `useful work, tokens: ${e.useful_share_tokens.toFixed(2)}%\n\n` +
      `context re-reading: ${e.reread_share_tokens.toFixed(1)}% of tokens\n\n` +
      `one useful token costs ${Math.round(e.paid_tokens_per_useful_token)} paid tokens\n\n` +
      `click for the full breakdown`);
  });
}

function detail() {
  const { hours } = cfg();
  output.clear();
  output.show(true);
  run(["detail", String(hours)], (err, stdout, stderr) => output.append(err ? String(stderr || err) : stdout));
}

function schedule() {
  clearInterval(timer);
  timer = setInterval(refresh, cfg().every * 1000);
  refresh();
}

function activate(context) {
  output = vscode.window.createOutputChannel("contextburn");
  item = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 100);
  item.command = "contextburn.detail";
  item.text = "$(flame) contextburn";
  item.show();
  context.subscriptions.push(
    item, output,
    vscode.commands.registerCommand("contextburn.detail", detail),
    vscode.commands.registerCommand("contextburn.refresh", refresh),
    vscode.workspace.onDidChangeConfiguration((ev) => { if (ev.affectsConfiguration("contextburn")) schedule(); }),
    { dispose: () => clearInterval(timer) });
  schedule();
}

function deactivate() { clearInterval(timer); }

module.exports = { activate, deactivate };
