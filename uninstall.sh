#!/usr/bin/env bash
# uninstall.sh — remove the `urls` command and its shell block.
set -euo pipefail

BIN_DIR="${URLS_BIN_DIR:-$HOME/.local/bin}"
BEGIN="# >>> urls >>>"
END="# <<< urls <<<"
ok() { printf '  \033[32m✓\033[0m %s\n' "$*"; }

printf '\033[1m%s\033[0m\n' "urls — uninstalling"

if [[ -f $BIN_DIR/urls ]]; then rm -f "$BIN_DIR/urls"; ok "removed $BIN_DIR/urls"
else ok "no command at $BIN_DIR/urls"; fi

for RC in "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.bashrc" \
          "$HOME/.bash_profile" "$HOME/.bash_login" "$HOME/.profile"; do
  [[ -f $RC ]] || continue
  grep -qF "$BEGIN" "$RC" || continue
  tmp=$(mktemp)
  awk -v b="$BEGIN" -v e="$END" '
    index($0,b) {skip=1} !skip {print} index($0,e) {skip=0}' "$RC" > "$tmp"
  mv "$tmp" "$RC"
  ok "cleaned $RC"
done

echo
echo "Done. Exported .md files in ~/Downloads were left alone."
echo "To also revoke the browser Automation permission:"
echo "  tccutil reset AppleEvents"
