#!/usr/bin/env bash
# Apply this myshell setup on a Mac (Apple Silicon Homebrew at /opt/homebrew).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="${HOME}"
BREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="$(brew --prefix)"
fi
BASH_BIN="${BREW_PREFIX}/bin/bash"
BACKUP="${HOME_DIR}/.dotfiles-backup/myshell-$(date +%Y%m%d-%H%M%S)"

backup() {
  local src="$1"
  if [ -e "$src" ] && [ ! -L "$src" ]; then
    mkdir -p "$BACKUP"
    cp -p "$src" "$BACKUP/"
  elif [ -e "$src" ]; then
    mkdir -p "$BACKUP"
    cp -p "$src" "$BACKUP/" 2>/dev/null || true
  fi
}

install_file() {
  local from="$1"
  local to="$2"
  mkdir -p "$(dirname "$to")"
  backup "$to"
  local tmp
  tmp="$(mktemp)"
  sed -e "s|/opt/homebrew|${BREW_PREFIX}|g" -e "s|/Users/leochen|${HOME_DIR}|g" "$from" >"$tmp"
  mv "$tmp" "$to"
}

echo "==> Installing Homebrew packages"
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required. Install from https://brew.sh and re-run." >&2
  exit 1
fi

brew install bash starship eza bat fzf zoxide fd ripgrep bash-completion@2 tmux
brew install --cask font-jetbrains-mono-nerd-font iterm2 || true

echo "==> Writing dotfiles (backups in ${BACKUP})"
install_file "$ROOT/home/bashrc" "${HOME_DIR}/.bashrc"
install_file "$ROOT/home/bash_profile" "${HOME_DIR}/.bash_profile"
install_file "$ROOT/home/inputrc" "${HOME_DIR}/.inputrc"
install_file "$ROOT/home/zshrc" "${HOME_DIR}/.zshrc"
install_file "$ROOT/home/tmux.conf" "${HOME_DIR}/.tmux.conf"
install_file "$ROOT/home/vimrc" "${HOME_DIR}/.vimrc"
install_file "$ROOT/home/config/starship.toml" "${HOME_DIR}/.config/starship.toml"

if [ ! -f "${HOME_DIR}/.bashrc.local" ]; then
  cp "$ROOT/extras/bashrc.local.example" "${HOME_DIR}/.bashrc.local"
fi

echo "==> bat Catppuccin Mocha theme"
BAT_CFG="$(bat --config-dir)"
mkdir -p "${BAT_CFG}/themes"
if curl -fsSL "https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme" \
  -o "${BAT_CFG}/themes/Catppuccin Mocha.tmTheme"; then
  bat cache --build || true
fi

echo "==> vim-plug and plugins"
mkdir -p "${HOME_DIR}/.vim/autoload" "${HOME_DIR}/.vim/undo" "${HOME_DIR}/.vim/backup" "${HOME_DIR}/.vim/swap" "${HOME_DIR}/.vim/plugged"
curl -fsSL -o "${HOME_DIR}/.vim/autoload/plug.vim" \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim -es -u "${HOME_DIR}/.vimrc" -i NONE +'PlugInstall --sync' +qa || true

echo "==> iTerm2 Bash profile"
mkdir -p "${HOME_DIR}/Library/Application Support/iTerm2/DynamicProfiles"
install_file "$ROOT/extras/iterm2/bash-default.json" \
  "${HOME_DIR}/Library/Application Support/iTerm2/DynamicProfiles/bash-default.json"
defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "leochen-bash-default" || true

echo "==> Cursor terminal settings (merge, do not wipe other keys)"
CURSOR_SETTINGS="${HOME_DIR}/Library/Application Support/Cursor/User/settings.json"
if [ -f "$CURSOR_SETTINGS" ]; then
  backup "$CURSOR_SETTINGS"
  python3 - "$CURSOR_SETTINGS" "$ROOT/extras/cursor-terminal.settings.json" "$BASH_BIN" <<'PY'
import json, sys
from pathlib import Path
target, snippet, bash_bin = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3]
data = json.loads(target.read_text())
extra = json.loads(snippet.read_text())
extra["terminal.integrated.profiles.osx"]["bash"]["path"] = bash_bin
data.update(extra)
target.write_text(json.dumps(data, indent=2) + "\n")
PY
fi

echo "==> Terminal.app font + custom shell"
defaults write com.apple.Terminal Shell -string "$BASH_BIN" || true
osascript <<APPLESCRIPT || true
tell application "Terminal"
  try
    set font name of settings set "Clear Dark" to "JetBrainsMonoNF-Regular"
    set font size of settings set "Clear Dark" to 14
  end try
end tell
APPLESCRIPT

echo "==> Default login shell -> ${BASH_BIN}"
if ! grep -qxF "$BASH_BIN" /etc/shells 2>/dev/null || [ "$(dscl . -read "/Users/${USER}" UserShell 2>/dev/null | awk '{print $2}')" != "$BASH_BIN" ]; then
  echo "A macOS password dialog may appear to change the login shell."
  osascript -e "do shell script \"grep -qxF '${BASH_BIN}' /etc/shells || echo '${BASH_BIN}' >> /etc/shells; dscl . -create /Users/${USER} UserShell '${BASH_BIN}'\" with administrator privileges" \
    || echo "Could not change login shell automatically. Run: echo ${BASH_BIN} | sudo tee -a /etc/shells && chsh -s ${BASH_BIN}"
fi

echo
echo "Done."
echo "1. Quit and reopen iTerm / Terminal (Cmd+Q)."
echo "2. In Cursor: Cmd+Shift+P -> Reload Window so JetBrainsMono NF loads."
echo "3. Put secrets in ~/.bashrc.local (see extras/bashrc.local.example)."
echo "4. Verify: echo \"\$SHELL\" && bash --version && tmux -V"
