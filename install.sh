#!/usr/bin/env bash
# install.sh — install the `urls` command and its terminal key bindings.
#
#   ./install.sh                 install to ~/.local/bin + add key bindings
#   ./install.sh --prefix DIR    install the command somewhere else
#   ./install.sh --no-keys       skip the ⌃X shortcuts, just install the command
#   ./install.sh --no-grant      skip the browser permission step
#   ./install.sh --shell bash    set up bash (or: zsh, both) instead of your login shell
#   ./install.sh --yes           don't ask before opening a browser to authorize it
#   ./install.sh --help

# Re-exec under bash if invoked as `sh install.sh` or `zsh install.sh`. Shells read
# a script incrementally, so doing this before any bash-only syntax appears means
# the wrong shell never reaches a construct it cannot parse.
# Note: macOS /bin/sh IS bash in POSIX mode, so BASH_VERSION alone is not enough --
# posix mode still rejects process substitution. Check for both.
case "${SHELLOPTS:-}" in *posix*) exec /usr/bin/env bash "$0" "$@" ;; esac
if [ -z "${BASH_VERSION:-}" ]; then
  exec /usr/bin/env bash "$0" "$@"
fi

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${URLS_BIN_DIR:-$HOME/.local/bin}"
ADD_KEYS=1
DO_GRANT=1
TARGET_SHELL=auto
ASSUME_YES=0
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
    --no-grant) DO_GRANT=0; shift ;;
    --shell) TARGET_SHELL="${2:-}"; [[ -n $TARGET_SHELL ]] || die "--shell needs zsh, bash or both"; shift 2 ;;
    -y|--yes) ASSUME_YES=1; shift ;;
    -h|--help) awk 'NR>1 && /^#/ {sub(/^# ?/,""); print; next} NR>1 {exit}' "$0"; exit 0 ;;
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
login_shell=$(basename "${SHELL:-/bin/zsh}")
[[ $TARGET_SHELL == auto ]] && TARGET_SHELL=$login_shell

RC_FILES=()
add_bash_targets() {
  # Non-login interactive shells read ~/.bashrc; login shells read only the FIRST
  # of .bash_profile / .bash_login / .profile that exists. Cover both, and never
  # create a .bash_profile — doing so would shadow an existing .profile.
  RC_FILES+=("$HOME/.bashrc")
  local f login_rc=""
  for f in "$HOME/.bash_profile" "$HOME/.bash_login" "$HOME/.profile"; do
    [[ -f $f ]] && { login_rc=$f; break; }
  done
  [[ -z $login_rc ]] && login_rc="$HOME/.bash_profile"
  RC_FILES+=("$login_rc")
}

case $TARGET_SHELL in
  zsh)  RC_FILES=("$HOME/.zshrc") ;;
  bash) add_bash_targets ;;
  both) RC_FILES=("$HOME/.zshrc"); add_bash_targets ;;
  *)    RC_FILES=("$HOME/.profile")
        warn "unrecognised shell '$TARGET_SHELL' — key bindings skipped"; ADD_KEYS=0 ;;
esac

emit_block() {  # $1 = rc file, $2 = zsh|bash
  printf '\n%s\n' "$BEGIN"
  printf 'case ":$PATH:" in *":%s:"*) ;; *) export PATH="%s:$PATH" ;; esac\n' "$BIN_DIR" "$BIN_DIR"
  (( ADD_KEYS )) || { printf '%s\n' "$END"; return; }
  if [[ $2 == zsh ]]; then
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
  else
    cat <<'BASH'
if [[ $- == *i* ]] && command -v urls >/dev/null 2>&1; then
  bind -x '"\C-xu": urls -c'    # ctrl-x u  -> all open tabs to the clipboard
  bind -x '"\C-xm": urls -md'   # ctrl-x m  -> all open tabs to ~/Downloads/*.md
fi
BASH
  fi
  printf '%s\n' "$END"
}

seen=""
for RC in "${RC_FILES[@]}"; do
  case " $seen " in *" $RC "*) continue ;; esac   # same file listed twice
  seen="$seen $RC"
  [[ $(basename "$RC") == .zshrc ]] && kind=zsh || kind=bash
  touch "$RC"

  # drop any previous managed block so re-running is always safe
  if grep -qF "$BEGIN" "$RC"; then
    tmp=$(mktemp)
    awk -v b="$BEGIN" -v e="$END" '
      index($0,b) {skip=1} !skip {print} index($0,e) {skip=0}' "$RC" > "$tmp"
    mv "$tmp" "$RC"
  fi

  # trim trailing blank lines so repeat installs never grow the file
  tmp=$(mktemp)
  awk '{l[NR]=$0} END{last=NR; while(last>0 && l[last] ~ /^[[:space:]]*$/) last--;
        for(i=1;i<=last;i++) print l[i]}' "$RC" > "$tmp"
  mv "$tmp" "$RC"

  emit_block "$RC" "$kind" >> "$RC"
  ok "updated $RC ($kind)"
done
(( ADD_KEYS )) && ok "bound ctrl-x u (clipboard) and ctrl-x m (markdown file)"

# ---------- browser access -------------------------------------------------
# macOS gates Apple Events behind TCC. Nothing can grant that permission from a
# script (the TCC store is SIP-protected), but we CAN trigger each prompt now so
# the user approves them all here instead of being ambushed on first real use.
app_installed() { osascript -e "id of app \"$1\"" >/dev/null 2>&1; }
is_running()    { [[ $(osascript -e "application \"$1\" is running" 2>/dev/null) == true ]]; }

probe_app() {   # 0 = allowed, 1 = denied, 2 = no response
  local err
  err=$(osascript -e "tell application \"$1\" to count windows" 2>&1 >/dev/null) || true
  [[ -z $err ]] && return 0
  case $err in
    *-1743*|*"Not authorized"*|*"not allowed"*) return 1 ;;
    *) return 2 ;;
  esac
}

if (( DO_GRANT )); then
  echo
  bold "Browser access"
  echo "  macOS asks before letting a terminal read a browser's tabs. Approving now"
  echo "  means urls just works afterwards — click OK on each dialog."
  echo
  while IFS='|' read -r app label <&3; do
    app_installed "$app" || continue
    launched=0
    if ! is_running "$app"; then
      if (( ASSUME_YES )); then
        reply=y
      elif [[ -t 0 ]]; then
        printf '  %s is not running. Open it briefly to authorize now? [y/N] ' "$label"
        read -r reply || reply=n
      else
        reply=n
      fi
      case ${reply:-n} in
        y|Y|yes|YES) launched=1 ;;
        *) warn "$label skipped — it will ask the first time you use it"; continue ;;
      esac
    fi
    rc=0; probe_app "$app" || rc=$?
    case $rc in
      0) ok "$label authorized" ;;
      1) warn "$label denied — re-enable under System Settings > Privacy & Security > Automation" ;;
      2) warn "$label did not respond — it will ask on first use" ;;
    esac
    (( launched )) && osascript -e "tell application \"$app\" to quit" >/dev/null 2>&1 || true
  done 3< <("$BIN_DIR/urls" --apps)

  # Downloads is also TCC-protected on modern macOS; surface that prompt too.
  outdir="${URLS_OUTDIR:-$HOME/Downloads}"
  mkdir -p "$outdir" 2>/dev/null || true
  if : > "$outdir/.urls-write-check" 2>/dev/null; then
    rm -f "$outdir/.urls-write-check"
    ok "can write exports to $outdir"
  else
    warn "cannot write to $outdir — allow it under System Settings > Privacy & Security > Files and Folders"
  fi

  case "${TERM_PROGRAM:-}" in
    Apple_Terminal) client="Terminal" ;;
    iTerm.app) client="iTerm" ;;
    vscode) client="VS Code" ;;
    "") client="this terminal" ;;
    *) client="$TERM_PROGRAM" ;;
  esac
  echo
  echo "  These approvals belong to $client. Running urls from a different terminal"
  echo "  app asks once more — that is macOS, not urls."
fi

# ---------- verify ---------------------------------------------------------
if v=$("$BIN_DIR/urls" --version 2>&1); then
  ok "verified: $v runs correctly"
else
  die "installed but $BIN_DIR/urls will not run — please open an issue with this output: $v"
fi

# ---------- done -----------------------------------------------------------
echo
bold "Installed. Next:"
cat <<EOF
  1. Reload your shell:      exec $login_shell
  2. Try it:                 urls
     ctrl-x u  copies every open tab      ctrl-x m  writes a markdown file

Optional system-wide hotkey (works even when the terminal is not focused):
  Shortcuts.app -> New Shortcut -> "Run Shell Script" -> $BIN_DIR/urls -c
  then set a keyboard shortcut in the shortcut's info panel.
EOF
