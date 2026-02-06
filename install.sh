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
  "edith            - Cyan-orange, Spider-Man's AI"
  "jarvis           - Blue-gold, Iron Man's AI"
  "friday           - Blue-cyan, Avengers' AI"
  "catppuccin-mocha - Warm dark pastels"
  "tokyo-night      - Cool blue-purple"
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

# ── Install terminal theme ──────────────────
echo -e "${BOLD}Installing ${THEME} for ${TERMINAL_LABELS[$term_idx]}...${RESET}"
echo ""

case "$TERMINAL" in
  ghostty)
    DEST_DIR="${HOME}/.config/ghostty/themes"
    mkdir -p "$DEST_DIR"
    curl -fsSL "${BASE_URL}/${THEME}/ghostty" -o "${DEST_DIR}/${THEME}"
    echo -e "  ${GREEN}✓${RESET} Downloaded to ${DEST_DIR}/${THEME}"
    echo ""
    echo -e "  ${YELLOW}Add to ~/.config/ghostty/config:${RESET}"
    echo -e "  ${DIM}theme = ${THEME}${RESET}"
    ;;
  kitty)
    DEST_DIR="${HOME}/.config/kitty"
    mkdir -p "$DEST_DIR"
    curl -fsSL "${BASE_URL}/${THEME}/kitty-theme.conf" -o "${DEST_DIR}/current-theme.conf"
    echo -e "  ${GREEN}✓${RESET} Downloaded to ${DEST_DIR}/current-theme.conf"
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
    echo -e "  ${GREEN}✓${RESET} Downloaded to ${DEST_DIR}/shellsuit.toml"
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
    echo -e "  ${GREEN}✓${RESET} Downloaded to ${DEST_DIR}/colors.properties"
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

# ── Optional: Starship palette ──────────────
read -p "  Do you use Starship prompt? [y/N]: " starship_choice
if [[ "$starship_choice" =~ ^[Yy]$ ]]; then
  STARSHIP_CONFIG="${STARSHIP_CONFIG:-${HOME}/.config/starship.toml}"

  echo ""
  echo -e "  ${BOLD}Installing Starship palette...${RESET}"

  # Download palette to temp
  PALETTE_TMP=$(mktemp)
  curl -fsSL "${BASE_URL}/${THEME}/starship-palette.toml" -o "$PALETTE_TMP"

  if [[ -f "$STARSHIP_CONFIG" ]]; then
    # Remove existing shellsuit palette if present
    if grep -q "\[palettes.shellsuit\]" "$STARSHIP_CONFIG" 2>/dev/null; then
      # Remove old palette section
      sed -i.bak '/\[palettes.shellsuit\]/,/^\[/{ /^\[palettes.shellsuit\]/d; /^\[/!d; }' "$STARSHIP_CONFIG"
      sed -i.bak '/^palette = "shellsuit"/d' "$STARSHIP_CONFIG"
    fi
  else
    touch "$STARSHIP_CONFIG"
  fi

  # Add palette = "shellsuit" at top if not present
  if ! grep -q 'palette = "shellsuit"' "$STARSHIP_CONFIG" 2>/dev/null; then
    echo 'palette = "shellsuit"' | cat - "$STARSHIP_CONFIG" > "${STARSHIP_CONFIG}.tmp"
    mv "${STARSHIP_CONFIG}.tmp" "$STARSHIP_CONFIG"
  fi

  # Append palette section (skip comment lines from the downloaded file)
  echo "" >> "$STARSHIP_CONFIG"
  grep -v "^#" "$PALETTE_TMP" | grep -v "^$" >> "$STARSHIP_CONFIG"

  rm -f "$PALETTE_TMP" "${STARSHIP_CONFIG}.bak"

  echo -e "  ${GREEN}✓${RESET} Starship palette added to ${STARSHIP_CONFIG}"
fi

echo ""
echo -e "  ${GREEN}Done!${RESET} Restart your terminal to see the new theme."
echo ""
