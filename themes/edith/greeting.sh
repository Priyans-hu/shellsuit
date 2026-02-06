#!/usr/bin/env bash
# shellsuit greeting — E.D.I.T.H.
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
  local C1=$'\e[38;5;74m' C2=$'\e[97m' C3=$'\e[38;5;214m'
  local quotes=(
    "Welcome back, Peter."
    "Scanning environment... All clear."
    "Surveillance systems active."
    "All Stark satellites online."
    "How can I help today?"
    "I'm here if you need me."
    "Defense protocols ready."
  )

  if [[ -n "$ZSH_VERSION" ]]; then
    local quote="${quotes[$((RANDOM % ${#quotes[@]} + 1))]}"
  else
    local quote="${quotes[$((RANDOM % ${#quotes[@]}))]}"
  fi

  echo ""
  echo "${C1}  ╭──────────────────────────────────────────────╮${RESET}"
  echo "${C1}  │${RESET}  ${C3}🕷️${RESET}  ${C1}E.D.I.T.H.${RESET} ${DIM}v3.0${RESET}                        ${C1}│${RESET}"
  echo "${C1}  │${RESET}                                              ${C1}│${RESET}"
  echo "${C1}  │${RESET}  ${C2}${greeting}, Peter.${RESET}"
  echo "${C1}  │${RESET}  ${DIM}${quote}${RESET}"
  echo "${C1}  ╰──────────────────────────────────────────────╯${RESET}"
  echo ""
}

_shellsuit_greeting
