#!/usr/bin/env bash
# install.sh — install the `urls` command and its terminal key bindings.
#
#   ./install.sh                 install to ~/.local/bin + add key bindings
#   ./install.sh --prefix DIR    install the command somewhere else
#   ./install.sh --no-keys       skip the ⌃X shortcuts, just install the command
#   ./install.sh --help

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${URLS_BIN_DIR:-$HOME/.local/bin}"
ADD_KEYS=1
BEGIN="# >>> urls >>>"
END="# <<< urls <<<"

bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
ok()    { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn()  { printf '  \033[33m!\033[0m %s\n' "$*"; }
die()   { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case $1 in
    --prefix) BIN_DIR="${2:-}"; [[ -n $BIN_DIR ]] || die "--prefix needs a directory"; shift 2 ;;
    --no-keys) ADD_KEYS=0; shift ;;
    -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown option '$1' (try --help)" ;;
  esac
done

# ---------- preflight ------------------------------------------------------
bold "urls — installing"
[[ $(uname -s) == Darwin ]] || die "this tool is macOS-only (it uses AppleScript and pbcopy)"
[[ -f $REPO_DIR/bin/urls ]] || die "bin/urls not found — run this from inside the cloned repo"

if command -v python3 >/dev/null 2>&1; then
  ok "python3 found ($(python3 -V 2>&1))"
else
  warn "python3 not found — Firefox/Waterfox/Zen will be skipped."
  warn "  Install it with:  xcode-select --install"
fi

# ---------- the command ----------------------------------------------------
mkdir -p "$BIN_DIR"
install -m 755 "$REPO_DIR/bin/urls" "$BIN_DIR/urls"
ok "installed $BIN_DIR/urls"

# ---------- shell integration ---------------------------------------------
shell_name=$(basename "${SHELL:-/bin/zsh}")
case $shell_name in
  zsh)  RC="$HOME/.zshrc" ;;
  bash) RC="$HOME/.bash_profile" ;;
  *)    RC="$HOME/.profile"; warn "unrecognised shell '$shell_name' — key bindings skipped"; ADD_KEYS=0 ;;
esac
touch "$RC"

# drop any previous managed block so re-running is always safe
if grep -qF "$BEGIN" "$RC"; then
  tmp=$(mktemp)
  awk -v b="$BEGIN" -v e="$END" '
    index($0,b) {skip=1} !skip {print} index($0,e) {skip=0}' "$RC" > "$tmp"
  mv "$tmp" "$RC"
  ok "removed previous urls block from $(basename "$RC")"
fi

# trim trailing blank lines so repeat installs never grow the file
tmp=$(mktemp)
awk '{l[NR]=$0} END{last=NR; while(last>0 && l[last] ~ /^[[:space:]]*$/) last--;
      for(i=1;i<=last;i++) print l[i]}' "$RC" > "$tmp"
mv "$tmp" "$RC"

{
  printf '\n%s\n' "$BEGIN"
  printf 'case ":$PATH:" in *":%s:"*) ;; *) export PATH="%s:$PATH" ;; esac\n' "$BIN_DIR" "$BIN_DIR"
  if (( ADD_KEYS )) && [[ $shell_name == zsh ]]; then
    cat <<'ZSH'
if [[ -o interactive ]] && command -v urls >/dev/null 2>&1; then
  _urls_copy_widget() { local m; m=$(urls -c 2>&1);  zle -M "$m"; }
  _urls_md_widget()   { local m; m=$(urls -md 2>&1); zle -M "$m"; }
  zle -N _urls_copy_widget
  zle -N _urls_md_widget
  bindkey '^Xu' _urls_copy_widget   # ctrl-x u  -> all open tabs to the clipboard
  bindkey '^Xm' _urls_md_widget     # ctrl-x m  -> all open tabs to ~/Downloads/*.md
fi
ZSH
  elif (( ADD_KEYS )) && [[ $shell_name == bash ]]; then
    cat <<'BASH'
if [[ $- == *i* ]] && command -v urls >/dev/null 2>&1; then
  bind -x '"\C-xu": urls -c'    # ctrl-x u  -> all open tabs to the clipboard
  bind -x '"\C-xm": urls -md'   # ctrl-x m  -> all open tabs to ~/Downloads/*.md
fi
BASH
  fi
  printf '%s\n' "$END"
} >> "$RC"
ok "updated $RC"
(( ADD_KEYS )) && ok "bound ctrl-x u (clipboard) and ctrl-x m (markdown file)"

# ---------- done -----------------------------------------------------------
echo
bold "Installed. Next:"
cat <<EOF
  1. Reload your shell:      exec $shell_name
  2. Try it:                 urls
  3. First run against Safari/Brave/Chrome, macOS will ask
     "Terminal wants to control Safari" — click OK. It asks once per browser.

Optional system-wide hotkey (works even when the terminal is not focused):
  Shortcuts.app -> New Shortcut -> "Run Shell Script" -> $BIN_DIR/urls -c
  then set a keyboard shortcut in the shortcut's info panel.
EOF
