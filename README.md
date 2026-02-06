# shellsuit

Pre-built terminal color themes for Ghostty, Kitty, Alacritty, Termux, and Starship. One script to install.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Priyans-hu/shellsuit/master/install.sh)
```

## Themes

### E.D.I.T.H.
> Cyan-orange, inspired by Spider-Man's AI

| | Color |
|---|---|
| Background | ![#0F1419](https://placehold.co/16x16/0F1419/0F1419) `#0F1419` |
| Foreground | ![#E6E9ED](https://placehold.co/16x16/E6E9ED/E6E9ED) `#E6E9ED` |
| Cursor | ![#33B5E5](https://placehold.co/16x16/33B5E5/33B5E5) `#33B5E5` |

```
  Normal:  #1A2332  #E23636  #7DCE82  #E5A033  #33B5E5  #A37ACC  #56C2D6  #E6E9ED
  Bright:  #4A5568  #FF5555  #98E89E  #F5C84C  #5BC4F1  #C4A7E7  #7AD4E4  #FFFFFF
```

### J.A.R.V.I.S.
> Blue-gold, inspired by Iron Man's AI

| | Color |
|---|---|
| Background | ![#0D0D0D](https://placehold.co/16x16/0D0D0D/0D0D0D) `#0D0D0D` |
| Foreground | ![#E8E8E8](https://placehold.co/16x16/E8E8E8/E8E8E8) `#E8E8E8` |
| Cursor | ![#00D4FF](https://placehold.co/16x16/00D4FF/00D4FF) `#00D4FF` |

```
  Normal:  #1A1A1A  #AA0000  #39FF14  #FFD700  #00D4FF  #FF00FF  #00FFFF  #E8E8E8
  Bright:  #4D4D4D  #FF3333  #7FFF00  #FFE066  #66E0FF  #FF66FF  #66FFFF  #FFFFFF
```

### F.R.I.D.A.Y.
> Blue-cyan, inspired by the Avengers' AI

| | Color |
|---|---|
| Background | ![#0A0E14](https://placehold.co/16x16/0A0E14/0A0E14) `#0A0E14` |
| Foreground | ![#E6E6E6](https://placehold.co/16x16/E6E6E6/E6E6E6) `#E6E6E6` |
| Cursor | ![#00BFFF](https://placehold.co/16x16/00BFFF/00BFFF) `#00BFFF` |

```
  Normal:  #141820  #FF5555  #50FA7B  #F4B728  #0096FF  #BD93F9  #00BFFF  #E6E6E6
  Bright:  #3D4556  #FF6E6E  #69FF94  #FFDA45  #33AAFF  #D6ACFF  #33D6FF  #FFFFFF
```

### Catppuccin Mocha
> Soothing pastel theme for the high-spirited

| | Color |
|---|---|
| Background | ![#1E1E2E](https://placehold.co/16x16/1E1E2E/1E1E2E) `#1E1E2E` |
| Foreground | ![#CDD6F4](https://placehold.co/16x16/CDD6F4/CDD6F4) `#CDD6F4` |
| Cursor | ![#F5E0DC](https://placehold.co/16x16/F5E0DC/F5E0DC) `#F5E0DC` |

```
  Normal:  #45475A  #F38BA8  #A6E3A1  #F9E2AF  #89B4FA  #F5C2E7  #94E2D5  #BAC2DE
  Bright:  #585B70  #F38BA8  #A6E3A1  #F9E2AF  #89B4FA  #F5C2E7  #94E2D5  #A6ADC8
```

### Tokyo Night
> Dark theme inspired by Tokyo city lights

| | Color |
|---|---|
| Background | ![#1A1B26](https://placehold.co/16x16/1A1B26/1A1B26) `#1A1B26` |
| Foreground | ![#C0CAF5](https://placehold.co/16x16/C0CAF5/C0CAF5) `#C0CAF5` |
| Cursor | ![#C0CAF5](https://placehold.co/16x16/C0CAF5/C0CAF5) `#C0CAF5` |

```
  Normal:  #15161E  #F7768E  #9ECE6A  #E0AF68  #7AA2F7  #BB9AF7  #7DCFFF  #A9B1D6
  Bright:  #414868  #F7768E  #9ECE6A  #E0AF68  #7AA2F7  #BB9AF7  #7DCFFF  #C0CAF5
```

## Install

### One-liner

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Priyans-hu/shellsuit/master/install.sh)
```

Asks you which theme + terminal, downloads the config, tells you what to add.

### Manual Install

<details>
<summary><b>Ghostty</b></summary>

```bash
# Download theme (replace 'edith' with theme name)
curl -fsSL https://raw.githubusercontent.com/Priyans-hu/shellsuit/master/themes/edith/ghostty \
  -o ~/.config/ghostty/themes/edith

# Add to ~/.config/ghostty/config:
theme = edith
```
</details>

<details>
<summary><b>Kitty</b></summary>

```bash
curl -fsSL https://raw.githubusercontent.com/Priyans-hu/shellsuit/master/themes/edith/kitty-theme.conf \
  -o ~/.config/kitty/current-theme.conf

# Add to ~/.config/kitty/kitty.conf:
include current-theme.conf
```
</details>

<details>
<summary><b>Alacritty</b></summary>

```bash
mkdir -p ~/.config/alacritty/themes
curl -fsSL https://raw.githubusercontent.com/Priyans-hu/shellsuit/master/themes/edith/alacritty-theme.toml \
  -o ~/.config/alacritty/themes/shellsuit.toml

# Add to ~/.config/alacritty/alacritty.toml:
[general]
import = ["~/.config/alacritty/themes/shellsuit.toml"]
```
</details>

<details>
<summary><b>Termux</b></summary>

```bash
curl -fsSL https://raw.githubusercontent.com/Priyans-hu/shellsuit/master/themes/edith/termux.properties \
  -o ~/.termux/colors.properties

# Reload:
termux-reload-settings
```
</details>

<details>
<summary><b>Starship (prompt colors)</b></summary>

```bash
# Download palette and append to starship.toml:
curl -fsSL https://raw.githubusercontent.com/Priyans-hu/shellsuit/master/themes/edith/starship-palette.toml \
  >> ~/.config/starship.toml

# Add at the top of ~/.config/starship.toml:
palette = "shellsuit"
```
</details>

## What's in the box

```
themes/
  edith/
    ghostty              # Ghostty theme file
    kitty-theme.conf     # Kitty color config
    alacritty-theme.toml # Alacritty color config
    termux.properties    # Termux color properties
    starship-palette.toml # Starship color palette
  jarvis/
  friday/
  catppuccin-mocha/
  tokyo-night/
```

Each theme has the same 16 ANSI colors + background/foreground/cursor, pre-formatted for each terminal. Same colors, different formats — because every terminal has its own config syntax.

## Supported Terminals

| Terminal | Platform | Config Format |
|----------|----------|---------------|
| [Ghostty](https://ghostty.org) | macOS, Linux | `key = value` |
| [Kitty](https://sw.kovidgoyal.net/kitty/) | macOS, Linux | `key #hex` |
| [Alacritty](https://alacritty.org) | macOS, Linux, Windows | TOML |
| [Termux](https://termux.dev) | Android | Java properties |
| [Starship](https://starship.rs) | Cross-platform (prompt) | TOML palette |

## Contributing

Want to add a theme? Create a folder under `themes/` with configs for each terminal. See any existing theme for the format.

## License

MIT
