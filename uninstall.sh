#!/usr/bin/env bash
# Remove the OpenCode 4-pane grid from an omarchy / Hyprland setup.
#
# - removes ~/.local/bin/opencode-grid and ~/.local/bin/oc-send
# - removes ~/.config/opencode/agents/orchestrator.md and worker.md
#   (only if they still contain the grid marker comment)
# - removes the SUPER + ] binding block from ~/.config/hypr/bindings.conf
# - reloads Hyprland
set -euo pipefail

BIN="${HOME}/.local/bin"
BINDINGS="${HOME}/.config/hypr/bindings.conf"
AGENTS="${HOME}/.config/opencode/agents"
MARK="opencode-grid"

step() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN\033[0m %s\n' "$*" >&2; }

# --- scripts ----------------------------------------------------------------
step "Removing scripts"
rm -f "${BIN}/opencode-grid" "${BIN}/oc-send"
echo "    removed ${BIN}/opencode-grid, ${BIN}/oc-send"

# --- agent definitions (only if they are the distributed ones) --------------
step "Removing opencode agent definitions"
for f in orchestrator worker; do
  target="${AGENTS}/${f}.md"
  if [ -f "$target" ] && grep -q "oc4 tmux grid\|oc4 grid\|opencode-grid" "$target" 2>/dev/null; then
    rm -f "$target"
    echo "    removed $target"
  elif [ -f "$target" ]; then
    warn "$target was customized - leaving it in place."
  fi
done

# --- keybinding --------------------------------------------------------------
step "Removing Hyprland keybinding (SUPER + ])"
if [ -f "$BINDINGS" ] && grep -q "$MARK" "$BINDINGS"; then
  # delete from the marker comment line through the bindd line (and the blank line before)
  awk -v mark="$MARK" '
    { keep[NR] = $0 }
    END {
      skip = 0
      for (i = 1; i <= NR; i++) {
        line = keep[i]
        if (line ~ /OpenCode 4-pane grid: SUPER \+ \] launches it\./ || line ~ /github.com\/drkai-lab\/opencode-grid/) {
          skip = 1
          # also swallow the preceding blank line if there is one
          if (i > 1 && keep[i-1] ~ /^[[:space:]]*$/) { printed_prev[i-1] = 1 }
          continue
        }
        if (skip && line ~ /bindd = SUPER, bracketright/) { skip = 0; continue }
        if (printed_prev[i]) continue
        print line
      }
    }' "$BINDINGS" > "${BINDINGS}.tmp" && mv "${BINDINGS}.tmp" "$BINDINGS"
  echo "    updated ${BINDINGS}"
else
  warn "no ${MARK} binding found - nothing to remove."
fi

# --- reload -----------------------------------------------------------------
step "Reloading Hyprland"
hyprctl reload >/dev/null 2>&1 || warn "hyprctl reload failed - run it manually."

step "Done. The OpenCode 4-pane grid has been uninstalled."
