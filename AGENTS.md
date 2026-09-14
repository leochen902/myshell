# Agent playbook: reproduce this shell on another Mac

The user wants **the same setup as leochen's current machine**, not a redesigned one.

Repo: `git@github.com:leochen902/myshell.git`

## Do

1. Clone this repo.
2. Run `./install.sh` (or do the same steps by hand if the script fails).
3. Backup existing `~/.bashrc`, `~/.bash_profile`, `~/.zshrc`, `~/.tmux.conf`, `~/.vimrc`, `~/.config/starship.toml` before overwriting.
4. Keep machine-local secrets out of git. If the user has API keys, put them in `~/.bashrc.local` (see `extras/bashrc.local.example`).
5. After install: ask the user to **Reload Cursor Window** and **Cmd+Q** iTerm/Terminal.

## Do not

- Do not switch the theme away from Catppuccin Mocha / the bundled `starship.toml`.
- Do not replace Starship with Oh My Bash / oh-my-posh unless the user asks.
- Do not commit `~/.bashrc.local` or any API keys.
- Do not overwrite the entire Cursor `settings.json`; merge only the keys in `extras/cursor-terminal.settings.json`.
- Do not leave the login shell as `/bin/zsh` or `/bin/bash` (3.2). It must be Homebrew bash.

## Packages

```bash
brew install bash starship eza bat fzf zoxide fd ripgrep bash-completion@2 tmux
brew install --cask font-jetbrains-mono-nerd-font iterm2
```

## Files to install (from `home/`)

| Source | Destination |
|---|---|
| `home/bashrc` | `~/.bashrc` |
| `home/bash_profile` | `~/.bash_profile` |
| `home/inputrc` | `~/.inputrc` |
| `home/zshrc` | `~/.zshrc` (hands off interactive zsh → bash) |
| `home/tmux.conf` | `~/.tmux.conf` |
| `home/vimrc` | `~/.vimrc` |
| `home/config/starship.toml` | `~/.config/starship.toml` |

Replace `/opt/homebrew` with `$(brew --prefix)` on Intel Macs (`/usr/local`).
Replace `/Users/leochen` with the new `$HOME` (iTerm profile working directory).

## Login shell

```bash
BASH_BIN="$(brew --prefix)/bin/bash"
echo "$BASH_BIN" | sudo tee -a /etc/shells
chsh -s "$BASH_BIN"
```

GUI alternative (password dialog):

```bash
osascript -e "do shell script \"grep -qxF '$BASH_BIN' /etc/shells || echo '$BASH_BIN' >> /etc/shells; dscl . -create /Users/$USER UserShell '$BASH_BIN'\" with administrator privileges"
```

## Font (this bit broke icons last time)

Installed family name is **`JetBrainsMono NF`**, not `JetBrainsMono Nerd Font`.

Cursor `settings.json` keys:

```json
"terminal.integrated.fontFamily": "JetBrainsMono NF",
"terminal.integrated.fontSize": 14,
"terminal.integrated.fontLigatures": true,
"terminal.integrated.defaultProfile.osx": "bash",
"terminal.integrated.profiles.osx": {
  "bash": { "path": "/opt/homebrew/bin/bash", "args": ["-l"] }
}
```

iTerm2: copy `extras/iterm2/bash-default.json` to
`~/Library/Application Support/iTerm2/DynamicProfiles/`
and set Default Bookmark Guid to `leochen-bash-default`.

## Extra install steps

```bash
# bat theme
mkdir -p "$(bat --config-dir)/themes"
curl -fsSL "https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme" \
  -o "$(bat --config-dir)/themes/Catppuccin Mocha.tmTheme"
bat cache --build

# vim-plug + plugins listed in vimrc
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
mkdir -p ~/.vim/{undo,backup,swap,plugged}
vim +'PlugInstall --sync' +qa
```

Locale must be set (empty `LC_COLLATE` makes `eza`/`ls` warn):

```bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

These are already in `bash_profile` / `bashrc`.

## Verify

```bash
echo "$SHELL"          # /opt/homebrew/bin/bash
bash --version         # 5.x, not 3.2
echo "$LANG"           # en_US.UTF-8
starship --version
tmux -V
vim --version | head -1
ls                     # eza with icons, no setlocale warning
```

New Cursor terminal should show the Catppuccin powerline prompt (mauve / blue / green / peach / pink / sky) and `❯`.

Scrollback / history is **50000 lines** everywhere: bash `HISTSIZE`, tmux `history-limit`, Cursor `terminal.integrated.scrollback`, iTerm2 `Scrollback Lines`, Terminal.app `ScrollbackLines`.

## tmux / vim cheat sheet (so you can explain it)

tmux prefix is **`Ctrl-a`**. Search screen text: `Ctrl-a` `[` then `/` or `?`, `n`/`N` next/prev, `q` to quit.

vim leader is **Space**. `Space f` files, `Space /` ripgrep, `Space e` netrw, `gcc` comment.
