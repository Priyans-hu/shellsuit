#!/usr/bin/env bash
set -e

REPO="Priyans-hu/shellsuit"
BRANCH="master"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/themes"

# Colors
BOLD="\033[1m"
GREEN="\033[32m"
CYAN="\033[36m"
YELLOW="\033[33m"
DIM="\033[2m"
RESET="\033[0m"

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

echo ""
echo -e "${BOLD}shellsuit${RESET} — terminal theme installer"
echo ""

# ── Pick theme ──────────────────────────────
echo -e "${CYAN}Pick a theme:${RESET}"
echo ""
for i in "${!THEME_LABELS[@]}"; do
  echo -e "  ${BOLD}$((i+1)))${RESET} ${THEME_LABELS[$i]}"
done
echo ""
read -p "  Choice [1-${#THEMES[@]}]: " theme_choice
theme_idx=$((theme_choice - 1))

if [[ $theme_idx -lt 0 || $theme_idx -ge ${#THEMES[@]} ]]; then
  echo "Invalid choice." && exit 1
fi
THEME="${THEMES[$theme_idx]}"
echo ""

# ── Pick terminal ───────────────────────────
echo -e "${CYAN}Which terminal do you use?${RESET}"
echo ""
for i in "${!TERMINAL_LABELS[@]}"; do
  echo -e "  ${BOLD}$((i+1)))${RESET} ${TERMINAL_LABELS[$i]}"
done
# Hint if running inside WSL
if [[ -n "$WSL_DISTRO_NAME" ]] || grep -qi microsoft /proc/version 2>/dev/null; then
  echo ""
  echo -e "  ${DIM}(WSL detected — option 5 recommended)${RESET}"
fi
echo ""
read -p "  Choice [1-${#TERMINALS[@]}]: " term_choice
term_idx=$((term_choice - 1))

if [[ $term_idx -lt 0 || $term_idx -ge ${#TERMINALS[@]} ]]; then
  echo "Invalid choice." && exit 1
fi
TERMINAL="${TERMINALS[$term_idx]}"
echo ""

# ── Install terminal colors ─────────────────
echo -e "${BOLD}Installing ${THEME} colors for ${TERMINAL_LABELS[$term_idx]}...${RESET}"
echo ""

case "$TERMINAL" in
  ghostty)
    DEST_DIR="${HOME}/.config/ghostty/themes"
    mkdir -p "$DEST_DIR"
    curl -fsSL "${BASE_URL}/${THEME}/ghostty" -o "${DEST_DIR}/${THEME}"
    echo -e "  ${GREEN}✓${RESET} Terminal colors installed"
    echo ""
    echo -e "  ${YELLOW}Add to ~/.config/ghostty/config:${RESET}"
    echo -e "  ${DIM}theme = ${THEME}${RESET}"
    ;;
  kitty)
    DEST_DIR="${HOME}/.config/kitty"
    mkdir -p "$DEST_DIR"
    curl -fsSL "${BASE_URL}/${THEME}/kitty-theme.conf" -o "${DEST_DIR}/current-theme.conf"
    echo -e "  ${GREEN}✓${RESET} Terminal colors installed"
    echo ""
    if grep -q "include current-theme.conf" "${DEST_DIR}/kitty.conf" 2>/dev/null; then
      echo -e "  ${DIM}kitty.conf already includes the theme.${RESET}"
    else
      echo -e "  ${YELLOW}Add to ~/.config/kitty/kitty.conf:${RESET}"
      echo -e "  ${DIM}include current-theme.conf${RESET}"
    fi
    ;;
  alacritty)
    DEST_DIR="${HOME}/.config/alacritty/themes"
    mkdir -p "$DEST_DIR"
    curl -fsSL "${BASE_URL}/${THEME}/alacritty-theme.toml" -o "${DEST_DIR}/shellsuit.toml"
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
    DEST_DIR="${HOME}/.termux"
    mkdir -p "$DEST_DIR"
    curl -fsSL "${BASE_URL}/${THEME}/termux.properties" -o "${DEST_DIR}/colors.properties"
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
    # Map theme slug to scheme name
    case "$THEME" in
      edith)            SCHEME_NAME="ShellSuit - E.D.I.T.H." ;;
      jarvis)           SCHEME_NAME="ShellSuit - J.A.R.V.I.S." ;;
      friday)           SCHEME_NAME="ShellSuit - F.R.I.D.A.Y." ;;
      catppuccin-mocha) SCHEME_NAME="ShellSuit - Catppuccin Mocha" ;;
      tokyo-night)      SCHEME_NAME="ShellSuit - Tokyo Night" ;;
    esac

    # Download the scheme file
    SCHEME_FILE="/tmp/shellsuit-wt-scheme.json"
    curl -fsSL "${BASE_URL}/${THEME}/windows-terminal.json" -o "$SCHEME_FILE"

    # Try to find Windows Terminal settings.json
    WT_SETTINGS=""
    if [[ -d "/mnt/c" ]]; then
      for win_user_dir in /mnt/c/Users/*/; do
        for pkg in "Microsoft.WindowsTerminal_8wekyb3d8bbwe" "Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe"; do
          candidate="${win_user_dir}AppData/Local/Packages/${pkg}/LocalState/settings.json"
          if [[ -f "$candidate" ]]; then
            WT_SETTINGS="$candidate"
            break 2
          fi
        done
      done
    fi

    INJECTED=false
    if [[ -n "$WT_SETTINGS" ]] && command -v jq &>/dev/null; then
      echo -e "  ${GREEN}Found:${RESET} ${DIM}${WT_SETTINGS}${RESET}"
      echo ""
      read -p "  Auto-add scheme to settings.json? [y/N]: " inject_choice
      if [[ "$inject_choice" =~ ^[Yy]$ ]]; then
        cp "$WT_SETTINGS" "${WT_SETTINGS}.shellsuit-backup"
        echo -e "  ${DIM}Backed up to settings.json.shellsuit-backup${RESET}"

        if UPDATED=$(jq --argjson scheme "$(cat "$SCHEME_FILE")" \
          '(.schemes // []) |= (map(select(.name != $scheme.name)) + [$scheme])' \
          "$WT_SETTINGS" 2>/dev/null); then
          echo "$UPDATED" > "$WT_SETTINGS"
          echo -e "  ${GREEN}✓${RESET} Color scheme added to settings.json"
          INJECTED=true
        else
          echo -e "  ${YELLOW}Could not parse settings.json automatically.${RESET}"
        fi
      fi
    fi

    if [[ "$INJECTED" = false ]]; then
      LOCAL_DIR="${HOME}/.config/shellsuit"
      mkdir -p "$LOCAL_DIR"
      cp "$SCHEME_FILE" "${LOCAL_DIR}/windows-terminal.json"
      echo -e "  ${GREEN}✓${RESET} Scheme saved to ~/.config/shellsuit/windows-terminal.json"
      echo ""
      echo -e "  ${YELLOW}To install manually:${RESET}"
      echo -e "  ${DIM}1. Open Windows Terminal Settings (Ctrl+Shift+,)${RESET}"
      echo -e "  ${DIM}2. In the JSON, find the \"schemes\" array${RESET}"
      echo -e "  ${DIM}3. Paste the contents of windows-terminal.json${RESET}"
    fi

    rm -f "$SCHEME_FILE"

    echo ""
    echo -e "  ${YELLOW}Then set in your WSL profile:${RESET}"
    echo -e "  ${DIM}\"colorScheme\": \"${SCHEME_NAME}\"${RESET}"
    ;;
esac

echo ""

# ── Starship prompt ─────────────────────────
read -p "  Install Starship prompt? [y/N]: " starship_choice
if [[ "$starship_choice" =~ ^[Yy]$ ]]; then
  STARSHIP_CONFIG="${STARSHIP_CONFIG:-${HOME}/.config/starship.toml}"

  if [[ -f "$STARSHIP_CONFIG" ]]; then
    cp "$STARSHIP_CONFIG" "${STARSHIP_CONFIG}.backup"
    echo -e "  ${DIM}Backed up existing config to starship.toml.backup${RESET}"
  fi

  curl -fsSL "${BASE_URL}/${THEME}/starship.toml" -o "$STARSHIP_CONFIG"
  echo -e "  ${GREEN}✓${RESET} Starship prompt installed"

  if ! command -v starship &>/dev/null; then
    echo ""
    echo -e "  ${YELLOW}Starship not found. Install it:${RESET}"
    echo -e "  ${DIM}curl -sS https://starship.rs/install.sh | sh${RESET}"
    echo ""
    echo -e "  ${YELLOW}Then add to your shell config:${RESET}"
    echo -e "  ${DIM}eval \"\$(starship init zsh)\"   # or bash${RESET}"
  fi
fi

echo ""

# ── Shell greeting ──────────────────────────
read -p "  Install shell greeting? [y/N]: " greeting_choice
if [[ "$greeting_choice" =~ ^[Yy]$ ]]; then
  GREETING_DIR="${HOME}/.config/shellsuit"
  mkdir -p "$GREETING_DIR"
  curl -fsSL "${BASE_URL}/${THEME}/greeting.sh" -o "${GREETING_DIR}/greeting.sh"
  echo -e "  ${GREEN}✓${RESET} Greeting script installed"

  # Detect shell config
  SHELL_RC=""
  if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC="${HOME}/.zshrc"
  elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_RC="${HOME}/.bashrc"
  fi

  if [[ -n "$SHELL_RC" ]]; then
    if grep -q "shellsuit/greeting.sh" "$SHELL_RC" 2>/dev/null; then
      echo -e "  ${DIM}Already sourced in ${SHELL_RC}${RESET}"
    else
      echo "" >> "$SHELL_RC"
      echo "# shellsuit greeting" >> "$SHELL_RC"
      echo '[[ -f ~/.config/shellsuit/greeting.sh ]] && source ~/.config/shellsuit/greeting.sh' >> "$SHELL_RC"
      echo -e "  ${GREEN}✓${RESET} Added to ${SHELL_RC}"
    fi
  else
    echo ""
    echo -e "  ${YELLOW}Add to your shell config:${RESET}"
    echo -e "  ${DIM}source ~/.config/shellsuit/greeting.sh${RESET}"
  fi
fi

echo ""
echo -e "  ${GREEN}Done!${RESET} Restart your terminal to see the new theme."
echo ""
