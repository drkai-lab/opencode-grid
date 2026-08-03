# opencode4

**Press `SUPER + ]` and four opencode panes open up: one orchestrator, three workers, a whole little team.**

[日本語](README.ja.md)

## What this is

It's opencode running in a 2x2 grid of tmux panes. Top left is the orchestrator, the one who hands out tasks. The other three are workers; they do the work. Everyone talks through a plain text log on disk, so the orchestrator can read all the reports without tab-hunting.

Each pane carries a Todo sidebar on its right showing the agent's current task. When a task is done, `oc-todo-clear` wipes the entry, so the sidebar only ever shows what's still in flight.

I built this because I missed `cmd + ]` from my Mac days and wanted it on [Omarchy](https://omarchy.org/). It's nothing fancy: a few bash scripts and one keybinding. If you've got tmux, opencode, and a Hyprland box, it'll run.

## What you need

- Hyprland (omarchy ships with it; current versions work fine)
- tmux and opencode
- a terminal: ghostty, kitty, foot, alacritty, or xdg-terminal-exec
- uwsm-app, so the key can open a terminal inside the Wayland session. Optional — the installer just warns if it's missing.
- something to feed opencode models: a local [Ollama](https://ollama.com/) instance or a cloud provider both work

## Install

The easy way:

```bash
git clone https://github.com/drkai-lab/opencode-grid.git
cd opencode-grid
./install.sh
```

That puts `opencode4`, `oc-send`, `oc-todo-view`, and `oc-todo-clear` into `~/.local/bin`, copies the two agent definitions into `~/.config/opencode/agents/` (your existing files are left alone), adds a binding to `~/.config/hypr/bindings.conf`, and reloads Hyprland. Run it again and it just skips what's already done.

By hand:

```bash
install -m755 bin/opencode4 bin/oc-send bin/oc-todo-view bin/oc-todo-clear ~/.local/bin/
cp agents/orchestrator.md agents/worker.md ~/.config/opencode/agents/
```

then add one line to `~/.config/hypr/bindings.conf`:

```
bindd = SUPER, bracketright, OpenCode 4-pane, exec, uwsm-app -- ghostty -e ~/.local/bin/opencode4
```

## Using it

1. Hit `SUPER + ]`. The grid opens in whatever directory you're in — or reattaches to the session if it's already running.
2. Top left is the orchestrator. The rest are workers.
3. From the orchestrator pane, tell a worker what to do:

   ```bash
   oc-send WORKER-1 "Refactor the auth module and report back."
   ```

4. Workers write their replies to the wire log (`~/.local/state/oc-grid/wire.log`). The orchestrator reads it and folds the results together for you.
5. Watch the Todo sidebars: each one shows the agent's current task, and clears itself once the task is reported done.
6. Leaving? `Ctrl-b d` detaches. The session keeps running in the background, and `SUPER + ]` brings you back.

Two more keys control the grid from anywhere:

- `SUPER + [` closes the terminal window but keeps the four agents running in the background. The session stays alive, so `SUPER + ]` returns you to it.
- `SUPER + W` shuts everything down: the four agents and the terminal window. Note that this replaces the usual "close window" meaning of `SUPER + W`. `SUPER ALT + W` still closes a window for good.

Everything the grid knows lives in `~/.local/state/oc-grid/` — the wire log, the role→pane map, and the `todo/` files behind the sidebars. Remove that folder to start over.

## Adjusting it

The agent definitions in `~/.config/opencode/agents/` decide what the orchestrator and workers look like. The installer never overwrites them, so edit freely. Usually all you change is the `model:` line to point at your backend. Restart the grid and you're set.

The Todo sidebars read from `~/.local/state/oc-grid/todo/<ROLE>`. `oc-send` writes the task it sends there, and `oc-todo-clear <ROLE>` removes it (or swaps in a new one). The sidebar width is the `OC_GRID_TODO_PCT` environment variable, 23% of each pane by default.

## Removing it

```bash
./uninstall.sh
```

Removes the scripts, the agent definitions (unless you changed them), and the binding, then reloads Hyprland.

## License

MIT © drkai-lab
