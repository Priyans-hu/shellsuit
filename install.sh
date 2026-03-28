#!/usr/bin/env bash
set -e

REPO="Priyans-hu/shellsuit"
BRANCH="master"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/themes"

# ── Colors ─────────────────────────────────
BOLD="\033[1m"
GREEN="\033[32m"
CYAN="\033[36m"
YELLOW="\033[33m"
DIM="\033[2m"
RESET="\033[0m"

# ── Data ───────────────────────────────────
THEMES=("edith" "jarvis" "friday" "catppuccin-mocha" "tokyo-night")
THEME_LABELS=(
  "E.D.I.T.H.       — Spider-Man's AI  (cyan-orange)"
  "J.A.R.V.I.S.     — Iron Man's AI    (red-gold)"
  "F.R.I.D.A.Y.     — Avengers' AI     (blue-cyan)"
  "Catppuccin Mocha  — Warm dark pastels"
  "Tokyo Night       — Cool blue-purple"
)

TERMINALS=("ghostty" "kitty" "alacritty" "termux" "windows-terminal")
TERMINAL_LABELS=(
  "Ghostty"
  "Kitty"
  "Alacritty"
  "Termux"
  "Windows Terminal (WSL)"
)

FONTS=("JetBrainsMono" "FiraCode" "Hack" "Meslo")
FONT_LABELS=(
  "JetBrains Mono"
  "Fira Code"
  "Hack"
  "Meslo LG"
)
FONT_FAMILIES=(
  "JetBrainsMono Nerd Font"
  "FiraCode Nerd Font"
  "Hack Nerd Font"
  "MesloLGS Nerd Font"
)
BREW_FONT_NAMES=(
  "font-jetbrains-mono-nerd-font"
  "font-fira-code-nerd-font"
  "font-hack-nerd-font"
  "font-meslo-lg-nerd-font"
)
NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"

# ── State ──────────────────────────────────
THEME=""
TERMINAL=""
OS_TYPE=""
SHELL_RC=""
STARSHIP_CONFIG_INSTALLED=false
SUMMARY=()

# ── Helpers ────────────────────────────────

detect_os() {
  if [[ "$(uname)" == "Darwin" ]]; then
    OS_TYPE="macos"
  elif [[ -n "${TERMUX_VERSION:-}" ]]; then
    OS_TYPE="termux"
  elif [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/version 2>/dev/null; then
    OS_TYPE="wsl"
  else
    OS_TYPE="linux"
  fi
}

detect_shell_rc() {
  if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC="${HOME}/.zshrc"
  elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_RC="${HOME}/.bashrc"
  else
    SHELL_RC=""
  fi
}

has_brew() { command -v brew &>/dev/null; }

add_to_rc() {
  local guard="$1" comment="$2" line="$3"
  if [[ -z "$SHELL_RC" ]]; then
    echo ""
    echo -e "  ${YELLOW}Add to your shell config:${RESET}"
    echo -e "  ${DIM}${line}${RESET}"
    return 0
  fi
  if grep -q "$guard" "$SHELL_RC" 2>/dev/null; then
    echo -e "  ${DIM}Already in ${SHELL_RC}: ${comment}${RESET}"
    return 0
  fi
  echo "" >> "$SHELL_RC"
  echo "# ${comment}" >> "$SHELL_RC"
  echo "$line" >> "$SHELL_RC"
  echo -e "  ${GREEN}✓${RESET} Added to ${SHELL_RC}"
}

# ── Pick theme ─────────────────────────────

pick_theme() {
  echo -e "${CYAN}Pick a theme:${RESET}"
  echo ""
  for i in "${!THEME_LABELS[@]}"; do
    echo -e "  ${BOLD}$((i+1)))${RESET} ${THEME_LABELS[$i]}"
  done
  echo ""
  read -p "  Choice [1-${#THEMES[@]}]: " theme_choice
  local idx=$((theme_choice - 1))

  if [[ $idx -lt 0 || $idx -ge ${#THEMES[@]} ]]; then
    echo "Invalid choice." && exit 1
  fi
  THEME="${THEMES[$idx]}"
  echo ""
}

# ── Pick terminal ──────────────────────────

pick_terminal() {
  echo -e "${CYAN}Which terminal do you use?${RESET}"
  echo ""
  for i in "${!TERMINAL_LABELS[@]}"; do
    echo -e "  ${BOLD}$((i+1)))${RESET} ${TERMINAL_LABELS[$i]}"
  done
  if [[ "$OS_TYPE" == "wsl" ]]; then
    echo ""
    echo -e "  ${DIM}(WSL detected — option 5 recommended)${RESET}"
  fi
  echo ""
  read -p "  Choice [1-${#TERMINALS[@]}]: " term_choice
  local idx=$((term_choice - 1))

  if [[ $idx -lt 0 || $idx -ge ${#TERMINALS[@]} ]]; then
    echo "Invalid choice." && exit 1
  fi
  TERMINAL="${TERMINALS[$idx]}"
  TERMINAL_LABEL="${TERMINAL_LABELS[$idx]}"
  echo ""
}

# ── Install terminal colors ────────────────

install_colors() {
  echo -e "${BOLD}Installing ${THEME} colors for ${TERMINAL_LABEL}...${RESET}"
  echo ""

  case "$TERMINAL" in
    ghostty)
      local dest="${HOME}/.config/ghostty/themes"
      mkdir -p "$dest"
      curl -fsSL "${BASE_URL}/${THEME}/ghostty" -o "${dest}/${THEME}"
      echo -e "  ${GREEN}✓${RESET} Terminal colors installed"
      echo ""
      echo -e "  ${YELLOW}Add to ~/.config/ghostty/config:${RESET}"
      echo -e "  ${DIM}theme = ${THEME}${RESET}"
      ;;
    kitty)
      local dest="${HOME}/.config/kitty"
      mkdir -p "$dest"
      curl -fsSL "${BASE_URL}/${THEME}/kitty-theme.conf" -o "${dest}/current-theme.conf"
      echo -e "  ${GREEN}✓${RESET} Terminal colors installed"
      echo ""
      if grep -q "include current-theme.conf" "${dest}/kitty.conf" 2>/dev/null; then
        echo -e "  ${DIM}kitty.conf already includes the theme.${RESET}"
      else
        echo -e "  ${YELLOW}Add to ~/.config/kitty/kitty.conf:${RESET}"
        echo -e "  ${DIM}include current-theme.conf${RESET}"
      fi
      ;;
    alacritty)
      local dest="${HOME}/.config/alacritty/themes"
      mkdir -p "$dest"
      curl -fsSL "${BASE_URL}/${THEME}/alacritty-theme.toml" -o "${dest}/shellsuit.toml"
      echo -e "  ${GREEN}✓${RESET} Terminal colors installed"
      echo ""
      if grep -q "themes/shellsuit.toml" "${HOME}/.config/alacritty/alacritty.toml" 2>/dev/null; then
        echo -e "  ${DIM}alacritty.toml already imports the theme.${RESET}"
      else
        echo -e "  ${YELLOW}Add to ~/.config/alacritty/alacritty.toml:${RESET}"
        echo -e "  ${DIM}[general]${RESET}"
        echo -e "  ${DIM}import = [\"~/.config/alacritty/themes/shellsuit.toml\"]${RESET}"
      fi
      ;;
    termux)
      local dest="${HOME}/.termux"
      mkdir -p "$dest"
      curl -fsSL "${BASE_URL}/${THEME}/termux.properties" -o "${dest}/colors.properties"
      echo -e "  ${GREEN}✓${RESET} Terminal colors installed"
      echo ""
      if command -v termux-reload-settings &>/dev/null; then
        termux-reload-settings
        echo -e "  ${GREEN}✓${RESET} Reloaded Termux settings"
      else
        echo -e "  ${YELLOW}Restart Termux to see changes.${RESET}"
      fi
      ;;
    windows-terminal)
      local scheme_name
      case "$THEME" in
        edith)            scheme_name="ShellSuit - E.D.I.T.H." ;;
        jarvis)           scheme_name="ShellSuit - J.A.R.V.I.S." ;;
        friday)           scheme_name="ShellSuit - F.R.I.D.A.Y." ;;
        catppuccin-mocha) scheme_name="ShellSuit - Catppuccin Mocha" ;;
        tokyo-night)      scheme_name="ShellSuit - Tokyo Night" ;;
      esac

      local scheme_file="/tmp/shellsuit-wt-scheme.json"
      curl -fsSL "${BASE_URL}/${THEME}/windows-terminal.json" -o "$scheme_file"

      local wt_settings=""
      if [[ -d "/mnt/c" ]]; then
        for win_user_dir in /mnt/c/Users/*/; do
          for pkg in "Microsoft.WindowsTerminal_8wekyb3d8bbwe" "Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe"; do
            local candidate="${win_user_dir}AppData/Local/Packages/${pkg}/LocalState/settings.json"
            if [[ -f "$candidate" ]]; then
              wt_settings="$candidate"
              break 2
            fi
          done
        done
      fi

      local injected=false
      if [[ -n "$wt_settings" ]] && command -v jq &>/dev/null; then
        echo -e "  ${GREEN}Found:${RESET} ${DIM}${wt_settings}${RESET}"
        echo ""
        read -p "  Auto-add scheme to settings.json? [y/N]: " inject_choice
        if [[ "$inject_choice" =~ ^[Yy]$ ]]; then
          cp "$wt_settings" "${wt_settings}.shellsuit-backup"
          echo -e "  ${DIM}Backed up to settings.json.shellsuit-backup${RESET}"
          local updated
          if updated=$(jq --argjson scheme "$(cat "$scheme_file")" \
            '(.schemes // []) |= (map(select(.name != $scheme.name)) + [$scheme])' \
            "$wt_settings" 2>/dev/null); then
            echo "$updated" > "$wt_settings"
            echo -e "  ${GREEN}✓${RESET} Color scheme added to settings.json"
            injected=true
          else
            echo -e "  ${YELLOW}Could not parse settings.json automatically.${RESET}"
          fi
        fi
      fi

      if [[ "$injected" = false ]]; then
        local local_dir="${HOME}/.config/shellsuit"
        mkdir -p "$local_dir"
        cp "$scheme_file" "${local_dir}/windows-terminal.json"
        echo -e "  ${GREEN}✓${RESET} Scheme saved to ~/.config/shellsuit/windows-terminal.json"
        echo ""
        echo -e "  ${YELLOW}To install manually:${RESET}"
        echo -e "  ${DIM}1. Open Windows Terminal Settings (Ctrl+Shift+,)${RESET}"
        echo -e "  ${DIM}2. In the JSON, find the \"schemes\" array${RESET}"
        echo -e "  ${DIM}3. Paste the contents of windows-terminal.json${RESET}"
      fi

      rm -f "$scheme_file"
      echo ""
      echo -e "  ${YELLOW}Then set in your WSL profile:${RESET}"
      echo -e "  ${DIM}\"colorScheme\": \"${scheme_name}\"${RESET}"
      ;;
  esac

  SUMMARY+=("Colors: ${THEME} for ${TERMINAL_LABEL}")
}

# ── Nerd Font ──────────────────────────────

_download_nerd_font() {
  local font_name="$1" dest_dir="$2"
  local zip_url="${NERD_FONT_URL}/${font_name}.zip"
  local tmp_zip="/tmp/shellsuit-font-${font_name}.zip"

  mkdir -p "$dest_dir"
  echo -e "  ${DIM}Downloading ${font_name} Nerd Font...${RESET}"
  curl -fSL "$zip_url" -o "$tmp_zip"
  unzip -o -q "$tmp_zip" -d "$dest_dir" '*.ttf' 2>/dev/null || \
    unzip -o -q "$tmp_zip" -d "$dest_dir"
  rm -f "$tmp_zip"
}

_print_font_hint() {
  local family="$1"
  echo ""
  echo -e "  ${YELLOW}Set font in your terminal config:${RESET}"
  case "$TERMINAL" in
    ghostty)
      echo -e "  ${DIM}font-family = ${family}${RESET}"
      echo -e "  ${DIM}(in ~/.config/ghostty/config)${RESET}" ;;
    kitty)
      echo -e "  ${DIM}font_family ${family}${RESET}"
      echo -e "  ${DIM}(in ~/.config/kitty/kitty.conf)${RESET}" ;;
    alacritty)
      echo -e "  ${DIM}[font.normal]${RESET}"
      echo -e "  ${DIM}family = \"${family}\"${RESET}"
      echo -e "  ${DIM}(in ~/.config/alacritty/alacritty.toml)${RESET}" ;;
    windows-terminal)
      echo -e "  ${DIM}\"fontFace\": \"${family}\"${RESET}"
      echo -e "  ${DIM}(in your WSL profile in settings.json)${RESET}" ;;
    termux)
      echo -e "  ${DIM}Font set automatically.${RESET}" ;;
  esac
}

install_nerd_font() {
  echo ""
  read -p "  Install a Nerd Font? (recommended for prompt icons) [y/N]: " choice
  [[ "$choice" =~ ^[Yy]$ ]] || return 0

  echo ""
  echo -e "${CYAN}Pick a font:${RESET}"
  echo ""
  for i in "${!FONT_LABELS[@]}"; do
    echo -e "  ${BOLD}$((i+1)))${RESET} ${FONT_LABELS[$i]}"
  done
  echo ""
  read -p "  Choice [1-${#FONTS[@]}]: " font_choice
  local idx=$((font_choice - 1))

  if [[ $idx -lt 0 || $idx -ge ${#FONTS[@]} ]]; then
    echo "Invalid choice." && return 0
  fi

  local font_name="${FONTS[$idx]}"
  local font_family="${FONT_FAMILIES[$idx]}"

  echo ""
  case "$OS_TYPE" in
    macos)
      if has_brew; then
        echo -e "  ${DIM}Installing via Homebrew...${RESET}"
        brew install --cask "${BREW_FONT_NAMES[$idx]}" 2>/dev/null || true
      else
        _download_nerd_font "$font_name" "${HOME}/Library/Fonts"
      fi
      ;;
    linux|wsl)
      if ! command -v unzip &>/dev/null; then
        echo -e "  ${YELLOW}unzip is required. Install it:${RESET}"
        echo -e "  ${DIM}sudo apt install unzip${RESET}"
        return 0
      fi
      _download_nerd_font "$font_name" "${HOME}/.local/share/fonts"
      fc-cache -fv >/dev/null 2>&1 || true
      if [[ "$OS_TYPE" == "wsl" ]]; then
        echo ""
        echo -e "  ${YELLOW}Note:${RESET} Windows Terminal uses Windows-side fonts."
        echo -e "  ${DIM}Also install the font on Windows:${RESET}"
        echo -e "  ${DIM}Download from: https://www.nerdfonts.com/font-downloads${RESET}"
        echo -e "  ${DIM}Right-click the .ttf files → Install for all users${RESET}"
      fi
      ;;
    termux)
      if ! command -v unzip &>/dev/null; then
        echo -e "  ${YELLOW}unzip is required: pkg install unzip${RESET}"
        return 0
      fi
      local tmp_dir="/tmp/shellsuit-font-$$"
      mkdir -p "$tmp_dir" "${HOME}/.termux"
      echo -e "  ${DIM}Downloading ${font_name} Nerd Font...${RESET}"
      curl -fSL "${NERD_FONT_URL}/${font_name}.zip" -o "${tmp_dir}/${font_name}.zip"
      unzip -o -q "${tmp_dir}/${font_name}.zip" -d "$tmp_dir"
      local regular_ttf
      regular_ttf=$(find "$tmp_dir" -name '*Regular*' -name '*.ttf' | head -1)
      if [[ -z "$regular_ttf" ]]; then
        regular_ttf=$(find "$tmp_dir" -name '*.ttf' | head -1)
      fi
      if [[ -n "$regular_ttf" ]]; then
        cp "$regular_ttf" "${HOME}/.termux/font.ttf"
        command -v termux-reload-settings &>/dev/null && termux-reload-settings
      fi
      rm -rf "$tmp_dir"
      ;;
  esac

  echo -e "  ${GREEN}✓${RESET} ${font_family} installed"
  SUMMARY+=("Nerd Font: ${font_family}")
  _print_font_hint "$font_family"
}

# ── Starship prompt config ─────────────────

install_starship_config() {
  echo ""
  read -p "  Install Starship prompt? [y/N]: " choice
  [[ "$choice" =~ ^[Yy]$ ]] || return 0

  local config="${STARSHIP_CONFIG:-${HOME}/.config/starship.toml}"

  if [[ -f "$config" ]]; then
    cp "$config" "${config}.backup"
    echo -e "  ${DIM}Backed up existing config to starship.toml.backup${RESET}"
  fi

  curl -fsSL "${BASE_URL}/${THEME}/starship.toml" -o "$config"
  echo -e "  ${GREEN}✓${RESET} Starship prompt config installed"
  STARSHIP_CONFIG_INSTALLED=true
  SUMMARY+=("Starship prompt: ${THEME}")
}

# ── Starship binary ────────────────────────

install_starship_binary() {
  [[ "$STARSHIP_CONFIG_INSTALLED" == true ]] || return 0
  command -v starship &>/dev/null && return 0

  echo ""
  echo -e "  ${YELLOW}Starship binary not found.${RESET}"
  read -p "  Install Starship now? (may need sudo) [y/N]: " choice
  [[ "$choice" =~ ^[Yy]$ ]] || {
    echo -e "  ${DIM}Install later: curl -sS https://starship.rs/install.sh | sh${RESET}"
    return 0
  }

  echo -e "  ${DIM}Running official Starship installer...${RESET}"
  curl -sS https://starship.rs/install.sh | sh -s -- -y || {
    echo -e "  ${YELLOW}Starship install may have failed. Try manually:${RESET}"
    echo -e "  ${DIM}curl -sS https://starship.rs/install.sh | sh${RESET}"
    return 0
  }

  echo -e "  ${GREEN}✓${RESET} Starship installed"
  SUMMARY+=("Starship binary: installed")

  local shell_name=""
  if [[ "$SHELL" == *"zsh"* ]]; then shell_name="zsh"
  elif [[ "$SHELL" == *"bash"* ]]; then shell_name="bash"
  fi

  if [[ -n "$shell_name" ]]; then
    add_to_rc "starship init" "shellsuit starship" \
      "eval \"\$(starship init ${shell_name})\""
  fi
}

# ── Shell greeting ─────────────────────────

install_greeting() {
  echo ""
  read -p "  Install shell greeting? [y/N]: " choice
  [[ "$choice" =~ ^[Yy]$ ]] || return 0

  local dest="${HOME}/.config/shellsuit"
  mkdir -p "$dest"
  curl -fsSL "${BASE_URL}/${THEME}/greeting.sh" -o "${dest}/greeting.sh"
  echo -e "  ${GREEN}✓${RESET} Greeting script installed"

  add_to_rc "shellsuit/greeting.sh" "shellsuit greeting" \
    '[[ -f ~/.config/shellsuit/greeting.sh ]] && source ~/.config/shellsuit/greeting.sh'

  SUMMARY+=("Shell greeting: ${THEME}")
}

# ── Shell plugins ──────────────────────────

install_shell_plugins() {
  [[ "$SHELL" == *"zsh"* ]] || return 0

  echo ""
  read -p "  Install zsh plugins? (syntax-highlighting + autosuggestions) [y/N]: " choice
  [[ "$choice" =~ ^[Yy]$ ]] || return 0

  local plugin_dir="${HOME}/.config/shellsuit/plugins"

  if [[ "$OS_TYPE" == "macos" ]] && has_brew; then
    echo -e "  ${DIM}Installing via Homebrew...${RESET}"
    brew install zsh-syntax-highlighting zsh-autosuggestions 2>/dev/null || true

    local prefix
    prefix="$(brew --prefix)"
    add_to_rc "zsh-syntax-highlighting" "shellsuit zsh-syntax-highlighting" \
      "source ${prefix}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    add_to_rc "zsh-autosuggestions" "shellsuit zsh-autosuggestions" \
      "source ${prefix}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  else
    if ! command -v git &>/dev/null; then
      echo -e "  ${YELLOW}git is required for plugin install.${RESET}"
      echo -e "  ${DIM}sudo apt install git${RESET}"
      return 0
    fi

    mkdir -p "$plugin_dir"
    echo -e "  ${DIM}Cloning plugins...${RESET}"

    if [[ ! -d "${plugin_dir}/zsh-syntax-highlighting" ]]; then
      git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "${plugin_dir}/zsh-syntax-highlighting" 2>/dev/null
    fi

    if [[ ! -d "${plugin_dir}/zsh-autosuggestions" ]]; then
      git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git \
        "${plugin_dir}/zsh-autosuggestions" 2>/dev/null
    fi

    add_to_rc "zsh-syntax-highlighting" "shellsuit zsh-syntax-highlighting" \
      "source ${plugin_dir}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    add_to_rc "zsh-autosuggestions" "shellsuit zsh-autosuggestions" \
      "source ${plugin_dir}/zsh-autosuggestions/zsh-autosuggestions.zsh"
  fi

  echo -e "  ${GREEN}✓${RESET} zsh plugins installed"
  SUMMARY+=("zsh-syntax-highlighting" "zsh-autosuggestions")
}

# ── Summary ────────────────────────────────

print_summary() {
  echo ""
  if [[ ${#SUMMARY[@]} -eq 0 ]]; then
    echo -e "  ${GREEN}Done!${RESET} Restart your terminal to see the new theme."
  else
    echo -e "  ${GREEN}Done!${RESET} Here's what was set up:"
    echo ""
    for item in "${SUMMARY[@]}"; do
      echo -e "    ${GREEN}✓${RESET} ${item}"
    done
    echo ""
    echo -e "  ${DIM}Restart your terminal to see all changes.${RESET}"
  fi
  echo ""
}

# ── Main ───────────────────────────────────

echo ""
echo -e "${BOLD}shellsuit${RESET} — terminal theme installer"
echo ""

detect_os
detect_shell_rc

pick_theme
pick_terminal
install_colors
install_nerd_font
install_starship_config
install_starship_binary
install_greeting
install_shell_plugins
print_summary
