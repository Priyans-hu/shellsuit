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

TERMINALS=("ghostty" "kitty" "alacritty" "termux")
TERMINAL_LABELS=(
  "Ghostty"
  "Kitty"
  "Alacritty"
  "Termux"
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
