#!/usr/bin/env bash
# shellsuit greeting — J.A.R.V.I.S.
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
  local C1=$'\e[91m' C2=$'\e[93m' C3=$'\e[96m'
  local quotes=(
    "All systems operational, sir."
    "Shall I prepare the deployment sequence?"
    "The suit is ready when you are."
    "Running diagnostics... All clear."
    "At your service, as always."
    "I've prepared the dev environment."
    "Mark LXXXV online and ready."
  )

  if [[ -n "$ZSH_VERSION" ]]; then
    local quote="${quotes[$((RANDOM % ${#quotes[@]} + 1))]}"
  else
    local quote="${quotes[$((RANDOM % ${#quotes[@]}))]}"
  fi

  echo ""
  echo "${C1}  ╭──────────────────────────────────────────────╮${RESET}"
  echo "${C1}  │${RESET}  ${C3}⟐${RESET}  ${C1}J.A.R.V.I.S.${RESET} ${DIM}v1.0${RESET}                      ${C1}│${RESET}"
  echo "${C1}  │${RESET}                                              ${C1}│${RESET}"
  echo "${C1}  │${RESET}  ${C2}${greeting}, sir.${RESET}"
  echo "${C1}  │${RESET}  ${DIM}${quote}${RESET}"
  echo "${C1}  ╰──────────────────────────────────────────────╯${RESET}"
  echo ""
}

_shellsuit_greeting
