#!/usr/bin/env bash
# Install the OpenCode 4-pane grid on an omarchy / Hyprland setup.
#
# - installs bin/opencode4, bin/oc-send, bin/oc-todo-view, bin/oc-todo-clear
#   into ~/.local/bin
# - copies agents/orchestrator.md and agents/worker.md into
#   ~/.config/opencode/agents/ (never overwrites an existing file)
# - wires the Hyprland keybinding: SUPER + ]  (OpenCode 4-pane)
# - reloads Hyprland
#
# Safe to run repeatedly - it never duplicates the keybinding block.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${HOME}/.local/bin"
BINDINGS="${HOME}/.config/hypr/bindings.conf"
AGENTS="${HOME}/.config/opencode/agents"
MARK="opencode-grid"
START_MARK="# >>> ${MARK} >>>"
END_MARK="# <<< ${MARK} <<<"
LAUNCHER="${BIN}/opencode4"

step() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR\033[0m %s\n' "$*" >&2; exit 1; }

# --- dependency check -------------------------------------------------------
step "Checking dependencies"
missing=()
for dep in tmux opencode hyprctl; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    missing+=("$dep")
  fi
done
if [ "${#missing[@]}" -gt 0 ]; then
  die "missing required tools: ${missing[*]}"
fi
# uwsm-app is the recommended omarchy launcher for the SUPER + ] binding.
# If it is missing, we still add the binding (the user may install it later)
# but we warn loudly so the failure mode is obvious.
if ! command -v uwsm-app >/dev/null 2>&1; then
  warn "uwsm-app not found - the SUPER + ] binding will not fire until it is installed."
fi

# --- terminal detection (ghostty preferred) ---------------------------------
step "Detecting terminal emulator"
TERMINAL=""
for cand in ghostty kitty foot alacritty; do
  if command -v "$cand" >/dev/null 2>&1; then
    TERMINAL="$cand"
    break
  fi
done
if [ -z "$TERMINAL" ] && command -v xdg-terminal-exec >/dev/null 2>&1; then
  TERMINAL="xdg-terminal-exec"
fi
if [ -z "$TERMINAL" ]; then
  die "no supported terminal found (looked for: ghostty, kitty, foot, alacritty, xdg-terminal-exec)"
fi
echo "    using terminal: $TERMINAL"

# --- install scripts --------------------------------------------------------
step "Installing scripts to ${BIN}/"
mkdir -p "$BIN"
install -m755 "${HERE}/bin/opencode4"     "${BIN}/opencode4"
install -m755 "${HERE}/bin/oc-send"       "${BIN}/oc-send"
install -m755 "${HERE}/bin/oc-todo-view"  "${BIN}/oc-todo-view"
install -m755 "${HERE}/bin/oc-todo-clear" "${BIN}/oc-todo-clear"
echo "    installed opencode4, oc-send, oc-todo-view, oc-todo-clear"

# --- install agent definitions (never overwrite) ----------------------------
step "Installing opencode agent definitions to ${AGENTS}/"
mkdir -p "$AGENTS"
for f in orchestrator worker; do
  src="${HERE}/agents/${f}.md"
  dst="${AGENTS}/${f}.md"
  if [ -f "$dst" ]; then
    warn "${dst} already exists - leaving it alone (edit it manually to set your model)."
  else
    cp "$src" "$dst"
    echo "    wrote $dst"
  fi
done

# --- wire Hyprland keybinding -----------------------------------------------
step "Wiring Hyprland keybinding (SUPER + ])"
mkdir -p "$(dirname "$BINDINGS")"
touch "$BINDINGS"
if grep -qF "$MARK" "$BINDINGS" 2>/dev/null; then
  warn "${MARK} binding already present in ${BINDINGS} - skipping."
else
  # Make sure the file ends with a newline before we append a new block.
  if [ -s "$BINDINGS" ] && [ -n "$(tail -c 1 "$BINDINGS")" ]; then
    printf '\n' >> "$BINDINGS"
  fi
  cat >> "$BINDINGS" <<EOF
${START_MARK}
# OpenCode 4-pane grid: SUPER + ] launches the tmux oc4 session,
# SUPER + [ minimizes it (agents keep running), SUPER + W closes everything.
# NOTE: SUPER + W is rebound from "close window" to "close the grid".
# https://github.com/drkai-lab/opencode-grid
bindd = SUPER, bracketright, OpenCode 4-pane, exec, uwsm-app -- ${TERMINAL} -e ${LAUNCHER}
bindd = SUPER, bracketleft, OpenCode 4-pane minimize, exec, tmux detach-client -s oc4
unbind = SUPER, W
bindd = SUPER, W, OpenCode 4-pane close all, exec, tmux kill-session -t oc4 2>/dev/null
${END_MARK}
EOF
  echo "    added binding to ${BINDINGS}"
fi

# --- reload -----------------------------------------------------------------
step "Reloading Hyprland"
if hyprctl reload >/dev/null 2>&1; then
  echo "    reloaded"
else
  warn "hyprctl reload failed - run it manually after the next Hyprland restart."
fi

cat <<'NOTE'

Done. Press SUPER + ] to launch the OpenCode 4-pane grid.

Before the first run, edit the model: line in
  ~/.config/opencode/agents/orchestrator.md
  ~/.config/opencode/agents/worker.md
to point at your provider (Ollama, opencode-go, ...). The distributed files
ship with placeholder models that must be replaced.

The grid opens with a Todo sidebar to the right of every pane: each agent's
current task is shown there. Agents clear their Todo with `oc-todo-clear`
once a task is done, so the sidebar only ever lists work in progress.
NOTE
