#!/usr/bin/env bash
# shellsuit greeting — F.R.I.D.A.Y.
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
  local C1=$'\e[94m' C2=$'\e[96m' C3=$'\e[93m'
  local quotes=(
    "All systems nominal, boss."
    "Combat systems standing by."
    "I've got your back, boss."
    "Threat assessment complete."
    "Ready for tactical deployment."
    "Avengers protocols loaded."
    "Scans are clean. Let's go."
  )

  if [[ -n "$ZSH_VERSION" ]]; then
    local quote="${quotes[$((RANDOM % ${#quotes[@]} + 1))]}"
  else
    local quote="${quotes[$((RANDOM % ${#quotes[@]}))]}"
  fi

  echo ""
  echo "${C1}  ╭──────────────────────────────────────────────╮${RESET}"
  echo "${C1}  │${RESET}  ${C3}◈${RESET}  ${C1}F.R.I.D.A.Y.${RESET} ${DIM}v2.0${RESET}                      ${C1}│${RESET}"
  echo "${C1}  │${RESET}                                              ${C1}│${RESET}"
  echo "${C1}  │${RESET}  ${C2}${greeting}, boss.${RESET}"
  echo "${C1}  │${RESET}  ${DIM}${quote}${RESET}"
  echo "${C1}  ╰──────────────────────────────────────────────╯${RESET}"
  echo ""
}

_shellsuit_greeting
