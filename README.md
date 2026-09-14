# myshell

Personal macOS bash + tmux + vim setup (Catppuccin Mocha).

Target machine: Apple Silicon Mac with Homebrew.

## For another Cursor agent

Read `AGENTS.md` and follow it. Do not invent a different theme or plugin set.

```bash
git clone git@github.com:leochen902/myshell.git
cd myshell
chmod +x install.sh
./install.sh
```

Then reload Cursor (`Cmd+Shift+P` → `Reload Window`) and fully quit/reopen iTerm.

## What this includes

| Piece | Role |
|---|---|
| Homebrew bash 5.x | Login / default shell (not macOS `/bin/bash` 3.2) |
| Starship | Catppuccin powerline prompt |
| JetBrains Mono Nerd Font | Icons and ligatures (`JetBrainsMono NF`) |
| eza / bat / fzf / zoxide / fd / ripgrep | Everyday CLI |
| tmux | Prefix `Ctrl-a`, Catppuccin status |
| vim + vim-plug | Catppuccin Mocha, fzf, commentary, surround, fugitive, gitgutter |

Secrets stay in `~/.bashrc.local` and are not in this repo.
