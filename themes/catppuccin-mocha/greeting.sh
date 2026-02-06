#!/usr/bin/env bash
# shellsuit greeting — Catppuccin Mocha
# Source this in your .zshrc or .bashrc

_shellsuit_greeting() {
  local hour=$(date +%H)
  local greeting

  if   (( hour >= 5  && hour < 12 )); then greeting="Good morning"
  elif (( hour >= 12 && hour < 17 )); then greeting="Good afternoon"
  elif (( hour >= 17 && hour < 21 )); then greeting="Good evening"
  else greeting="Working late"
  fi

  local RESET=$'\e[0m' DIM=$'\e[2m'
  local C1=$'\e[38;5;183m' C2=$'\e[97m' C3=$'\e[38;5;218m'
  local quotes=(
    "Time for something warm."
    "Pastels loaded. Looking cozy."
    "Soft colors, sharp code."
    "Everything looks better in mocha."
    "Warm tones online."
    "Your palette is ready."
    "Sip, type, repeat."
  )

  if [[ -n "$ZSH_VERSION" ]]; then
    local quote="${quotes[$((RANDOM % ${#quotes[@]} + 1))]}"
  else
    local quote="${quotes[$((RANDOM % ${#quotes[@]}))]}"
  fi

  echo ""
  echo "${C1}  ╭──────────────────────────────────────────────╮${RESET}"
  echo "${C1}  │${RESET}  ${C3}☕${RESET}  ${C1}catppuccin mocha${RESET}                         ${C1}│${RESET}"
  echo "${C1}  │${RESET}                                              ${C1}│${RESET}"
  echo "${C1}  │${RESET}  ${C2}${greeting}.${RESET}"
  echo "${C1}  │${RESET}  ${DIM}${quote}${RESET}"
  echo "${C1}  ╰──────────────────────────────────────────────╯${RESET}"
  echo ""
}

_shellsuit_greeting
