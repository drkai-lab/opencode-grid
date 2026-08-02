#!/usr/bin/env bash
# Install the OpenCode 4-pane grid on an omarchy / Hyprland setup.
#
# - installs bin/opencode-grid and bin/oc-send into ~/.local/bin
# - copies agents/orchestrator.md and agents/worker.md into ~/.config/opencode/agents/
#   (never overwrites existing files - edit those to set your own models)
# - wires the Hyprland keybinding: SUPER + ]  (OpenCode 4-pane)
# - reloads Hyprland
#
# Safe to run repeatedly - it never duplicates lines it already added.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${HOME}/.local/bin"
BINDINGS="${HOME}/.config/hypr/bindings.conf"
AGENTS="${HOME}/.config/opencode/agents"
MARK="opencode-grid"

step() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN\033[0m %s\n' "$*" >&2; }

# --- dependency check -------------------------------------------------------
missing=()
for dep in tmux opencode hyprctl; do
  command -v "$dep" >/dev/null 2>&1 || missing+=("$dep")
done
if command -v uwsm-app >/dev/null 2>&1; then
  LAUNCHER="uwsm-app --"
else
  warn "uwsm-app not found - launching the terminal directly (no wayland session wrapper)."
  LAUNCHER=""
fi
if [ "${#missing[@]}" -gt 0 ]; then
  echo "error: missing dependencies: ${missing[*]}" >&2
  exit 1
fi

# --- terminal detection -----------------------------------------------------
TERMINAL=""
for cand in ghostty kitty foot alacritty; do
  if command -v "$cand" >/dev/null 2>&1; then TERMINAL="$cand"; break; fi
done
if [ -z "$TERMINAL" ] && command -v xdg-terminal-exec >/dev/null 2>&1; then
  TERMINAL="xdg-terminal-exec"
fi
if [ -z "$TERMINAL" ]; then
  echo "error: no supported terminal found (ghostty/kitty/foot/alacritty/xdg-terminal-exec)" >&2
  exit 1
fi

# --- install scripts --------------------------------------------------------
step "Installing scripts to ${BIN}/"
mkdir -p "$BIN"
install -m755 "${HERE}/bin/opencode-grid" "${BIN}/opencode-grid"
install -m755 "${HERE}/bin/oc-send" "${BIN}/oc-send"

# --- install agent definitions (never overwrite) ----------------------------
step "Installing opencode agent definitions to ${AGENTS}/"
mkdir -p "$AGENTS"
for f in orchestrator worker; do
  if [ -f "${AGENTS}/${f}.md" ]; then
    warn "${AGENTS}/${f}.md already exists - skipping (edit it yourself to set your model)."
  else
    cp "${HERE}/agents/${f}.md" "${AGENTS}/${f}.md"
    echo "    wrote ${AGENTS}/${f}.md"
  fi
done

# --- wire Hyprland keybinding -----------------------------------------------
step "Wiring Hyprland keybinding (SUPER + ])"
mkdir -p "$(dirname "$BINDINGS")"
touch "$BINDINGS"
if grep -q "$MARK" "$BINDINGS" 2>/dev/null; then
  warn "keybinding for ${MARK} already present - skipping."
else
  cat >> "$BINDINGS" <<EOF

# OpenCode 4-pane grid: SUPER + ] launches it.
# https://github.com/drkai-lab/opencode-grid
bindd = SUPER, bracketright, OpenCode 4-pane, exec, ${LAUNCHER:+${LAUNCHER} }${TERMINAL} -e ~/.local/bin/opencode-grid
EOF
  echo "    added binding to ${BINDINGS}"
fi

# --- reload -----------------------------------------------------------------
step "Reloading Hyprland"
hyprctl reload >/dev/null 2>&1 || warn "hyprctl reload failed - run it manually."

step "Done. Press SUPER + ] to launch the OpenCode 4-pane grid."
step "Edit ~/.config/opencode/agents/orchestrator.md and worker.md to set your models."
