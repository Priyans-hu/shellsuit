#!/usr/bin/env bash
# shellsuit greeting — Tokyo Night
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
  local C1=$'\e[38;5;111m' C2=$'\e[97m' C3=$'\e[38;5;141m'
  local quotes=(
    "City lights are on."
    "Neon glow initialized."
    "Night mode activated."
    "The city never sleeps."
    "Pixels sharp, colors deep."
    "Your terminal, your skyline."
    "Late nights, clean code."
  )

  if [[ -n "$ZSH_VERSION" ]]; then
    local quote="${quotes[$((RANDOM % ${#quotes[@]} + 1))]}"
  else
    local quote="${quotes[$((RANDOM % ${#quotes[@]}))]}"
  fi

  echo ""
  echo "${C1}  ╭──────────────────────────────────────────────╮${RESET}"
  echo "${C1}  │${RESET}  ${C3}✦${RESET}  ${C1}tokyo night${RESET}                                ${C1}│${RESET}"
  echo "${C1}  │${RESET}                                              ${C1}│${RESET}"
  echo "${C1}  │${RESET}  ${C2}${greeting}.${RESET}"
  echo "${C1}  │${RESET}  ${DIM}${quote}${RESET}"
  echo "${C1}  ╰──────────────────────────────────────────────╯${RESET}"
  echo ""
}

_shellsuit_greeting
