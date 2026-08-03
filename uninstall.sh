#!/usr/bin/env bash
# Remove the OpenCode 4-pane grid from an omarchy / Hyprland setup.
#
# - removes ~/.local/bin/opencode4, oc-send, oc-todo-view, oc-todo-clear
#   (and the legacy ~/.local/bin/opencode-grid)
# - removes ~/.config/opencode/agents/orchestrator.md and worker.md
#   (only when they still look like the distributed files)
# - removes the SUPER + ] binding block from ~/.config/hypr/bindings.conf
# - reloads Hyprland
set -euo pipefail

BIN="${HOME}/.local/bin"
BINDINGS="${HOME}/.config/hypr/bindings.conf"
AGENTS="${HOME}/.config/opencode/agents"
MARK="opencode-grid"
START_MARK="# >>> ${MARK} >>>"
END_MARK="# <<< ${MARK} <<<"

step() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR\033[0m %s\n' "$*" >&2; exit 1; }

# --- scripts ----------------------------------------------------------------
step "Removing scripts from ${BIN}/"
rm -f "${BIN}/opencode4" "${BIN}/oc-send" "${BIN}/oc-todo-view" "${BIN}/oc-todo-clear"
rm -f "${BIN}/opencode-grid"   # legacy name from older releases
echo "    removed opencode4, oc-send, oc-todo-view, oc-todo-clear"

# --- agent definitions (only if they still look like the distributed ones) ---
step "Removing opencode agent definitions (untouched only)"
for f in orchestrator worker; do
  dst="${AGENTS}/${f}.md"
  if [ ! -f "$dst" ]; then
    continue
  fi
  if grep -qE 'oc4 tmux grid|opencode-grid' "$dst" 2>/dev/null; then
    rm -f "$dst"
    echo "    removed $dst"
  else
    warn "$dst was customized - leaving it in place."
  fi
done

# --- keybinding --------------------------------------------------------------
step "Removing Hyprland keybinding (SUPER + ])"
if [ ! -f "$BINDINGS" ]; then
  warn "${BINDINGS} does not exist - nothing to do."
elif grep -qF "$START_MARK" "$BINDINGS" 2>/dev/null; then
  # New format: delete the block delimited by >>> MARK >>> and <<< MARK <<<.
  awk -v start="$START_MARK" -v end="$END_MARK" '
    $0 ~ start { in_block = 1; next }
    $0 ~ end   { if (in_block) { in_block = 0; next } }
    !in_block  { print }
  ' "$BINDINGS" > "${BINDINGS}.tmp" && mv "${BINDINGS}.tmp" "$BINDINGS"
  echo "    removed ${MARK} block from ${BINDINGS}"
elif grep -qE 'bindd *= *SUPER, *bracketright, *OpenCode 4-pane' "$BINDINGS" 2>/dev/null; then
  # Legacy format: a single bindd line (possibly preceded by comments) that the
  # older installer dropped in. Remove the matching bindd line together with
  # any contiguous comment block directly above it; leave everything else
  # (including unrelated comments and a trailing blank) untouched.
  awk '
    BEGIN { in_cb = 0; ccount = 0 }
    {
      if (in_cb) {
        if ($0 ~ /^[[:space:]]*$/)           { flush(); print; in_cb = 0; next }
        if ($0 ~ /^[[:space:]]*#/)           { buf[++ccount] = $0; next }
        if ($0 ~ /bindd = SUPER, bracketright, OpenCode 4-pane/) {
          ccount = 0; in_cb = 0; next
        }
        flush(); in_cb = 0
      }
      if ($0 ~ /bindd = SUPER, bracketright, OpenCode 4-pane/) { next }
      if ($0 ~ /^[[:space:]]*#/)           { buf[++ccount] = $0; in_cb = 1; next }
      print
    }
    END { flush() }
    function flush(   i) { for (i = 1; i <= ccount; i++) print buf[i]; ccount = 0 }
  ' "$BINDINGS" > "${BINDINGS}.tmp" && mv "${BINDINGS}.tmp" "$BINDINGS"
  echo "    removed legacy ${MARK} binding from ${BINDINGS}"
else
  warn "no ${MARK} binding found in ${BINDINGS} - nothing to do."
fi

# --- reload -----------------------------------------------------------------
step "Reloading Hyprland"
if hyprctl reload >/dev/null 2>&1; then
  echo "    reloaded"
else
  warn "hyprctl reload failed - run it manually after the next Hyprland restart."
fi

echo "Uninstalled."
