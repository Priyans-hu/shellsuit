# shellsuit

Pre-built terminal themes with custom prompt, Nerd Font, shell plugins, and startup greeting. One command to set up the same terminal experience on macOS and Windows/WSL.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Priyans-hu/shellsuit/master/install.sh)
```

## What you get

- **Terminal colors** — 16 ANSI + bg/fg/cursor for Ghostty, Kitty, Alacritty, Termux, Windows Terminal
- **Nerd Font** — Optional install of JetBrains Mono, FiraCode, Hack, or MesloLG Nerd Font
- **Starship prompt** — Themed layout with custom icons, symbols, and colors
- **Shell greeting** — Time-aware greeting box on every new terminal session
- **Shell plugins** — zsh-syntax-highlighting and zsh-autosuggestions (zsh only)

## Themes

### E.D.I.T.H.
> Spider-Man's AI — cyan & orange

```
  ╭──────────────────────────────────────────────╮
  │  🕷️  E.D.I.T.H. v3.0                        │
  │                                              │
  │  Good morning, Peter.                        │
  │  All Stark satellites online.                │
  ╰──────────────────────────────────────────────╯

  ┌─ 🕷️ PARKER/shellsuit on  main
  └─ ›
```

### J.A.R.V.I.S.
> Iron Man's AI — red & gold

```
  ╭──────────────────────────────────────────────╮
  │  ⟐  J.A.R.V.I.S. v1.0                       │
  │                                              │
  │  Good morning, sir.                          │
  │  The suit is ready when you are.             │
  ╰──────────────────────────────────────────────╯

  ╭─ ⟐ STARK/shellsuit on  main
  ╰─ ❯
```

### F.R.I.D.A.Y.
> Avengers' AI — blue & cyan

```
  ╭──────────────────────────────────────────────╮
  │  ◈  F.R.I.D.A.Y. v2.0                       │
  │                                              │
  │  Good morning, boss.                         │
  │  Avengers protocols loaded.                  │
  ╰──────────────────────────────────────────────╯

  ┌─ ◈ AVENGERS/shellsuit on  main
  └─ ▸
```

### Catppuccin Mocha
> Warm dark pastels

```
  ╭──────────────────────────────────────────────╮
  │  ☕  catppuccin mocha                         │
  │                                              │
  │  Good morning.                               │
  │  Time for something warm.                    │
  ╰──────────────────────────────────────────────╯

  ┌─  ~/shellsuit on  main
  └─ ❯
```

### Tokyo Night
> City lights — blue & purple

```
  ╭──────────────────────────────────────────────╮
  │  ✦  tokyo night                              │
  │                                              │
  │  Good evening.                               │
  │  City lights are on.                         │
  ╰──────────────────────────────────────────────╯

  ┌─  ~/shellsuit on  main
  └─ ❯
```

## Supported terminals

| Terminal | Platform |
|----------|----------|
| [Ghostty](https://ghostty.org) | macOS, Linux |
| [Kitty](https://sw.kovidgoyal.net/kitty/) | macOS, Linux |
| [Alacritty](https://alacritty.org) | macOS, Linux, Windows |
| [Termux](https://termux.dev) | Android |
| [Windows Terminal](https://aka.ms/terminal) | Windows (via WSL) |
| [Starship](https://starship.rs) | Cross-platform (prompt) |

## Install

### One-liner

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Priyans-hu/shellsuit/master/install.sh)
```

Picks your theme and terminal, then optionally installs Nerd Font, Starship prompt, shell greeting, and zsh plugins.

### Manual

<details>
<summary><b>Terminal colors</b></summary>

**Ghostty**
```bash
curl -fsSL https://raw.githubusercontent.com/Priyans-hu/shellsuit/master/themes/edith/ghostty \
  -o ~/.config/ghostty/themes/edith

# Add to ~/.config/ghostty/config:
# theme = edith
```

**Kitty**
```bash
curl -fsSL https://raw.githubusercontent.com/Priyans-hu/shellsuit/master/themes/edith/kitty-theme.conf \
  -o ~/.config/kitty/current-theme.conf

# Add to ~/.config/kitty/kitty.conf:
# include current-theme.conf
```

**Alacritty**
```bash
mkdir -p ~/.config/alacritty/themes
curl -fsSL https://raw.githubusercontent.com/Priyans-hu/shellsuit/master/themes/edith/alacritty-theme.toml \
  -o ~/.config/alacritty/themes/shellsuit.toml

# Add to ~/.config/alacritty/alacritty.toml:
# [general]
# import = ["~/.config/alacritty/themes/shellsuit.toml"]
```

**Termux**
```bash
curl -fsSL https://raw.githubusercontent.com/Priyans-hu/shellsuit/master/themes/edith/termux.properties \
  -o ~/.termux/colors.properties && termux-reload-settings
```

Replace `edith` with any theme: `jarvis`, `friday`, `catppuccin-mocha`, `tokyo-night`.
</details>

<details>
<summary><b>Windows Terminal (WSL)</b></summary>

```bash
# From inside WSL — view the scheme JSON:
curl -fsSL https://raw.githubusercontent.com/Priyans-hu/shellsuit/master/themes/edith/windows-terminal.json
```

Then:
1. Open Windows Terminal Settings → Open JSON file (`Ctrl+Shift+,`)
2. Add the JSON object to the `"schemes"` array
3. In your WSL profile, set: `"colorScheme": "ShellSuit - E.D.I.T.H."`

Replace `edith` with any theme. Scheme names: `ShellSuit - E.D.I.T.H.`, `ShellSuit - J.A.R.V.I.S.`, `ShellSuit - F.R.I.D.A.Y.`, `ShellSuit - Catppuccin Mocha`, `ShellSuit - Tokyo Night`.
</details>

<details>
<summary><b>Nerd Font</b></summary>

A Nerd Font is needed for Starship prompt icons to render correctly.

**macOS (Homebrew)**
```bash
brew install --cask font-jetbrains-mono-nerd-font
```

**Linux / WSL**
```bash
mkdir -p ~/.local/share/fonts
curl -fSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip \
  -o /tmp/JetBrainsMono.zip
unzip -o -q /tmp/JetBrainsMono.zip -d ~/.local/share/fonts '*.ttf'
fc-cache -fv
rm /tmp/JetBrainsMono.zip
```

**WSL + Windows Terminal:** Also install the font on Windows (right-click `.ttf` → Install for all users), since Windows Terminal uses Windows-side fonts.

**Termux**
```bash
curl -fSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip \
  -o /tmp/JetBrainsMono.zip
unzip -o -q /tmp/JetBrainsMono.zip -d /tmp/nerdfonts
cp /tmp/nerdfonts/*Regular*.ttf ~/.termux/font.ttf
termux-reload-settings
```

Other fonts: Replace `JetBrainsMono` with `FiraCode`, `Hack`, or `Meslo`.
</details>

<details>
<summary><b>Starship prompt</b></summary>

```bash
# Back up existing config
cp ~/.config/starship.toml ~/.config/starship.toml.backup 2>/dev/null

# Download theme prompt
curl -fsSL https://raw.githubusercontent.com/Priyans-hu/shellsuit/master/themes/edith/starship.toml \
  -o ~/.config/starship.toml
```

Requires [Starship](https://starship.rs). Add to your shell config:
```bash
eval "$(starship init zsh)"   # or bash/fish
```
</details>

<details>
<summary><b>Shell greeting</b></summary>

```bash
mkdir -p ~/.config/shellsuit
curl -fsSL https://raw.githubusercontent.com/Priyans-hu/shellsuit/master/themes/edith/greeting.sh \
  -o ~/.config/shellsuit/greeting.sh

# Add to ~/.zshrc or ~/.bashrc:
[[ -f ~/.config/shellsuit/greeting.sh ]] && source ~/.config/shellsuit/greeting.sh
```
</details>

<details>
<summary><b>Shell plugins (zsh)</b></summary>

**macOS (Homebrew)**
```bash
brew install zsh-syntax-highlighting zsh-autosuggestions

# Add to ~/.zshrc:
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
```

**Linux / WSL**
```bash
mkdir -p ~/.config/shellsuit/plugins
git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
  ~/.config/shellsuit/plugins/zsh-syntax-highlighting
git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git \
  ~/.config/shellsuit/plugins/zsh-autosuggestions

# Add to ~/.zshrc:
source ~/.config/shellsuit/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.config/shellsuit/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
```
</details>

## What's in the box

```
themes/
  edith/              — E.D.I.T.H. (Spider-Man)
  jarvis/             — J.A.R.V.I.S. (Iron Man)
  friday/             — F.R.I.D.A.Y. (Avengers)
  catppuccin-mocha/   — Catppuccin Mocha
  tokyo-night/        — Tokyo Night

    ghostty             Terminal color theme
    kitty-theme.conf    Kitty color config
    alacritty-theme.toml  Alacritty color config
    termux.properties   Termux color properties
    starship.toml       Starship prompt config
    greeting.sh           Shell greeting script
    windows-terminal.json Windows Terminal color scheme
```

## Contributing

Want to add a theme? Create a folder under `themes/` with all 7 config files. See any existing theme for the format.

## License

MIT
