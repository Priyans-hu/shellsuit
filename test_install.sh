#!/usr/bin/env bash
# Mock test for install.sh — simulates full flow without real installs
# Can run locally or in GitHub Actions CI

set -euo pipefail

PASS=0
FAIL=0
TESTS=()

pass() { PASS=$((PASS + 1)); TESTS+=("PASS: $1"); }
fail() { FAIL=$((FAIL + 1)); TESTS+=("FAIL: $1 — $2"); }

echo "=== shellsuit install.sh mock tests ==="
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ── Test 1: Syntax check ──────────────────
echo "1. Syntax check..."
if bash -n install.sh 2>/dev/null; then
  pass "syntax valid"
else
  fail "syntax invalid" "bash -n failed"
fi

# ── Test 2: All functions defined ──────────
echo "2. Checking function definitions..."
EXPECTED_FUNCS=(
  "detect_os" "detect_shell_rc" "has_brew" "add_to_rc"
  "pick_theme" "pick_terminal" "install_colors"
  "_download_nerd_font" "_print_font_hint" "install_nerd_font"
  "install_starship_config" "install_starship_binary"
  "install_greeting" "install_shell_plugins" "print_summary"
)
for func in "${EXPECTED_FUNCS[@]}"; do
  if grep -q "^${func}()" install.sh; then
    pass "function ${func}() defined"
  else
    fail "function ${func}() missing" "not found in install.sh"
  fi
done

# ── Test 3: Source helpers, test detect_os ──
echo "3. Testing detect_os..."
# Source everything up to but not including the main flow
eval "$(sed -n '/^# ── Colors/,/^# ── Main/p' install.sh | head -n -1)" 2>/dev/null || true

detect_os
if [[ "$OS_TYPE" =~ ^(macos|linux|wsl|termux)$ ]]; then
  pass "detect_os → ${OS_TYPE}"
else
  fail "detect_os" "unexpected: ${OS_TYPE}"
fi

# ── Test 4: detect_shell_rc ───────────────
echo "4. Testing detect_shell_rc..."
detect_shell_rc
if [[ -n "$SHELL_RC" ]]; then
  pass "detect_shell_rc → ${SHELL_RC}"
elif [[ "$SHELL" != *"zsh"* && "$SHELL" != *"bash"* ]]; then
  pass "detect_shell_rc → empty (non-zsh/bash shell: $SHELL)"
else
  fail "detect_shell_rc" "empty for SHELL=$SHELL"
fi

# ── Test 5: add_to_rc idempotency ─────────
echo "5. Testing add_to_rc idempotency..."
TEST_RC="/tmp/shellsuit-test-rc-$$"
echo "# existing" > "$TEST_RC"
SAVED_RC="$SHELL_RC"
SHELL_RC="$TEST_RC"

add_to_rc "shellsuit-unique-guard" "test line" "echo shellsuit-unique-guard" >/dev/null 2>&1
if grep -q "shellsuit-unique-guard" "$TEST_RC"; then
  pass "add_to_rc: adds new line"
else
  fail "add_to_rc" "line not added"
fi

LINES_BEFORE=$(wc -l < "$TEST_RC")
add_to_rc "shellsuit-unique-guard" "test line" "echo shellsuit-unique-guard" >/dev/null 2>&1
LINES_AFTER=$(wc -l < "$TEST_RC")
if [[ "$LINES_BEFORE" -eq "$LINES_AFTER" ]]; then
  pass "add_to_rc: idempotent on re-run"
else
  fail "add_to_rc idempotency" "added duplicate (${LINES_BEFORE} → ${LINES_AFTER})"
fi

SHELL_RC="$SAVED_RC"
rm -f "$TEST_RC"

# ── Test 6: Data arrays consistent ────────
echo "6. Checking data array sizes..."
# Source arrays from the script
eval "$(grep -A1 '^THEMES=' install.sh | head -1)"
eval "$(sed -n '/^THEME_LABELS=/,/^)/p' install.sh)"
eval "$(grep -A1 '^TERMINALS=' install.sh | head -1)"
eval "$(sed -n '/^TERMINAL_LABELS=/,/^)/p' install.sh)"
eval "$(grep -A1 '^FONTS=' install.sh | head -1)"
eval "$(sed -n '/^FONT_LABELS=/,/^)/p' install.sh)"
eval "$(sed -n '/^FONT_FAMILIES=/,/^)/p' install.sh)"
eval "$(sed -n '/^BREW_FONT_NAMES=/,/^)/p' install.sh)"

if [[ ${#THEMES[@]} -eq 5 && ${#THEMES[@]} -eq ${#THEME_LABELS[@]} ]]; then
  pass "THEMES + THEME_LABELS: 5 each"
else
  fail "theme arrays" "${#THEMES[@]} vs ${#THEME_LABELS[@]}"
fi

if [[ ${#TERMINALS[@]} -eq 5 && ${#TERMINALS[@]} -eq ${#TERMINAL_LABELS[@]} ]]; then
  pass "TERMINALS + TERMINAL_LABELS: 5 each"
else
  fail "terminal arrays" "${#TERMINALS[@]} vs ${#TERMINAL_LABELS[@]}"
fi

if [[ ${#FONTS[@]} -eq 4 && ${#FONT_LABELS[@]} -eq 4 && ${#FONT_FAMILIES[@]} -eq 4 && ${#BREW_FONT_NAMES[@]} -eq 4 ]]; then
  pass "FONTS arrays: all 4"
else
  fail "font arrays" "FONTS=${#FONTS[@]} LABELS=${#FONT_LABELS[@]} FAMILIES=${#FONT_FAMILIES[@]} BREW=${#BREW_FONT_NAMES[@]}"
fi

# ── Test 7: JSON theme files valid ─────────
echo "7. Validating windows-terminal.json files..."
REQUIRED_KEYS="background black blue brightBlack brightBlue brightCyan brightGreen brightPurple brightRed brightWhite brightYellow cursorColor cyan foreground green name purple red selectionBackground white yellow"
for theme_dir in themes/*/; do
  theme=$(basename "$theme_dir")
  json="${theme_dir}windows-terminal.json"
  if [[ ! -f "$json" ]]; then
    fail "JSON: ${theme}" "file missing"
    continue
  fi
  if ! jq empty "$json" 2>/dev/null; then
    fail "JSON: ${theme}" "invalid JSON"
    continue
  fi
  actual_keys=$(jq -r 'keys[]' "$json" | sort | tr '\n' ' ' | sed 's/ $//')
  if [[ "$actual_keys" == "$REQUIRED_KEYS" ]]; then
    pass "JSON valid: ${theme} (21 keys)"
  else
    fail "JSON keys: ${theme}" "missing or extra keys"
  fi
done

# ── Setup mock environment ─────────────────
MOCK_BIN="/tmp/shellsuit-mock-bin-$$"
MOCK_HOME="/tmp/shellsuit-mock-home-$$"
MOCK_INPUT="/tmp/shellsuit-mock-input-$$"
mkdir -p "$MOCK_BIN" "$MOCK_HOME/.config"

# Mock curl: create output file, don't touch stdin
cat > "$MOCK_BIN/curl" << 'CURL'
#!/usr/bin/env bash
exec < /dev/null
while [[ $# -gt 0 ]]; do
  case "$1" in -o) mkdir -p "$(dirname "$2")"; touch "$2"; shift 2 ;; *) shift ;; esac
done
CURL
chmod +x "$MOCK_BIN/curl"

run_installer() {
  # $1 = input string, $2 = SHELL override
  local input="$1" shell_val="${2:-/bin/zsh}"
  printf "$input" > "$MOCK_INPUT"
  HOME="$MOCK_HOME" PATH="$MOCK_BIN:$PATH" SHELL="$shell_val" \
    bash install.sh < "$MOCK_INPUT" 2>&1
}

# ── Test 8: Mock full install — skip all ───
echo "8. Mock full install (skip all optionals)..."

OUTPUT=$(run_installer "1\n1\nN\nN\nN\nN\n" /bin/zsh) && EXIT_CODE=0 || EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]]; then
  pass "skip-all flow: exit 0"
else
  fail "skip-all flow" "exit ${EXIT_CODE}"
fi

if echo "$OUTPUT" | grep -q "Done!"; then
  pass "skip-all flow: summary printed"
else
  fail "skip-all flow" "no summary"
fi

if echo "$OUTPUT" | grep -q "Colors: edith"; then
  pass "skip-all flow: colors in summary"
else
  fail "skip-all flow" "colors not in summary"
fi

# ── Test 9: Mock full install — accept font + starship config ──
echo "9. Mock full install (font + starship, rest skipped)..."

# starship binary may or may not exist in mock PATH — handle both
# Inputs: theme=3, terminal=3(alacritty), font=y, font_choice=1, starship=y,
#   starship_binary=y (if prompted), greeting=N, plugins=N
OUTPUT2=$(run_installer "3\n3\ny\n1\ny\ny\nN\nN\n" /bin/zsh) && EXIT2=0 || EXIT2=$?

if [[ $EXIT2 -eq 0 ]]; then
  pass "optionals flow: exit 0"
else
  if echo "$OUTPUT2" | grep -q "Done!"; then
    pass "optionals flow: completed despite starship binary skip"
  else
    fail "optionals flow" "exit ${EXIT2}, no summary"
  fi
fi

if echo "$OUTPUT2" | grep -q "Nerd Font"; then
  pass "optionals flow: font in summary"
else
  fail "optionals flow" "font not in summary"
fi

if echo "$OUTPUT2" | grep -q "Starship prompt"; then
  pass "optionals flow: starship config in summary"
else
  fail "optionals flow" "starship not in summary"
fi

# ── Test 10: Mock with bash shell (plugins should be skipped) ──
echo "10. Mock install with bash shell (plugins auto-skipped)..."

OUTPUT3=$(run_installer "1\n2\nN\nN\nN\n" /bin/bash) && EXIT3=0 || EXIT3=$?

if [[ $EXIT3 -eq 0 ]]; then
  pass "bash shell flow: exit 0 (plugins skipped)"
else
  fail "bash shell flow" "exit ${EXIT3}"
fi

if ! echo "$OUTPUT3" | grep -q "zsh plugins"; then
  pass "bash shell flow: no plugins prompt"
else
  fail "bash shell flow" "plugins prompt appeared for bash"
fi

# ── Cleanup ────────────────────────────────
rm -rf "$MOCK_BIN" "$MOCK_HOME" "$MOCK_INPUT"

# ── Results ────────────────────────────────
echo ""
echo "=== Results ==="
echo ""
for t in "${TESTS[@]}"; do
  if [[ "$t" == PASS* ]]; then
    echo -e "  \033[32m${t}\033[0m"
  else
    echo -e "  \033[31m${t}\033[0m"
  fi
done
echo ""
echo "Total: $((PASS + FAIL)) | Passed: ${PASS} | Failed: ${FAIL}"
echo ""

[[ $FAIL -eq 0 ]]
