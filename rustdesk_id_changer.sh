#!/bin/bash
# -
# rustdesk_id_changer.sh
# =====
# RustDesk ID Changer for Linux.
#
# RustDesk : https://github.com/rustdesk/rustdesk
# Linux porting from RustDesk ID Changer : https://github.com/abdullah-erturk/RustDesk-ID-Changer
#
# Aruyu <vine9151@gmail.com> +2026.04.05
# -



T_CO_RED='\e[1;31m'
T_CO_YELLOW='\e[1;33m'
T_CO_GREEN='\e[1;32m'
T_CO_BLUE='\e[1;34m'
T_CO_GRAY='\e[1;30m'
T_CO_NC='\e[0m'

CURRENT_PROGRESS=0

function script_print()
{
  echo -ne "${T_CO_BLUE}[SCRIPT]${T_CO_NC}$1"
}

function script_notify_print()
{
  echo -ne "${T_CO_BLUE}[SCRIPT]${T_CO_NC}${T_CO_GREEN}-Notify- $1${T_CO_NC}"
}

function script_error_print()
{
  echo -ne "${T_CO_BLUE}[SCRIPT]${T_CO_NC}${T_CO_RED}-Error- $1${T_CO_NC}"
}

function script_println()
{
  echo -ne "${T_CO_BLUE}[SCRIPT]${T_CO_NC}$1\n"
}

function script_notify_println()
{
  echo -ne "${T_CO_BLUE}[SCRIPT]${T_CO_NC}${T_CO_GREEN}-Notify- $1${T_CO_NC}\n"
}

function script_error_println()
{
  echo -ne "${T_CO_BLUE}[SCRIPT]${T_CO_NC}${T_CO_RED}-Error- $1${T_CO_NC}\n"
}

function error_exit()
{
  script_error_println "$1\n"
  exit 1
}

function find_rustdesk_bin()
{
  local candidates=(
    $(which rustdesk 2> /dev/null)
    /usr/bin/rustdesk
    /usr/local/bin/rustdesk
    /snap/bin/rustdesk
  )

  for candidate in ${candidates}; do
    if [[ -x ${candidate} ]]; then
      echo ${candidate}
      return 0
    fi
  done

  return 1
}

function find_rustdesk_config()
{
  local candidates=(
    "/root/.config/rustdesk/RustDesk.toml"
    "$HOME/.config/rustdesk/RustDesk.toml"
  )

  for candidate in "${candidates[@]}"; do
    if [[ -f ${candidate} ]]; then
      echo ${candidate}
      return 0
    fi
  done

  return 1
}

function get_current_id()
{
  local current_id=$($1 --get-id 2> /dev/null)

  if [[ -z ${current_id} ]]; then
    current_id="Unknown"
  fi

  echo ${current_id}
  return 0
}

function set_new_id()
{
  local new_id=$1

  script_println " Current ID : ${CURRENT_ID}"
  script_println " New ID     : ${new_id}\n"

  script_notify_println "Stopping RustDesk service..."
  pkill -9 -x rustdesk
  sleep 1
  systemctl stop --now rustdesk
  sleep 2
  systemctl disable rustdesk

  cp ${RUSTDESK_CONFIG} ${RUSTDESK_CONFIG}.bak

  sed -i "1s/.*/id = '${new_id}'/" ${RUSTDESK_CONFIG}
  if [[ $? -ne 0 ]]; then
    script_error_println "Failed to set RustDesk config file."
    cp ${RUSTDESK_CONFIG}.bak ${RUSTDESK_CONFIG}
    return 1
  fi

  script_notify_println "Succeeded to set RustDesk config file."
  script_notify_println "Restarting RustDesk service..."

  systemctl enable rustdesk
  systemctl start --now rustdesk
  if [[ $? -ne 0 ]]; then
    script_error_println "Failed to restart RustDesk."
  fi

  return 0
}

function user_defined() {
  local new_id
  while true; do
    read -p "  Enter the ID you want to set: " new_id

    if [[ -z ${new_id} ]]; then
      continue
    elif [[ ${#new_id} -lt 6 ]]; then
      script_error_println "New ID value must be at least 6 characters. (Entered ${#new_id})"
    elif [[ ! ${new_id} =~ ^[a-zA-Z0-9_-]+$ ]]; then
      script_error_println "New ID value can only use 'char', 'number', '-' and '_'."
    else
      break
    fi

    echo
  done

  echo
  set_new_id ${new_id}
}

function main()
{
  clear
  RUSTDESK_BIN=$(find_rustdesk_bin)
  RUSTDESK_CONFIG=$(find_rustdesk_config)
  CURRENT_ID=$(get_current_id ${RUSTDESK_BIN})

  echo
  echo "================================================================="
  echo
  echo "  RustDesk ID Changer for Linux (Port from RustDesk-ID-Changer)"
  echo
  echo "  1 - Set RustDesk ID to hostname : '$(hostname)'"
  echo "  2 - Set RustDesk ID to 9-digit random numbers"
  echo "  3 - Set RustDesk ID to the custom value"
  echo
  echo "  4 - Exit"
  echo
  echo "================================================================="
  echo
  echo "  Current RustDesk ID : ${CURRENT_ID}"
  echo "  RustDesk bin PATH   : ${RUSTDESK_BIN}"
  echo "  Config file PATH    : ${RUSTDESK_CONFIG}"
  echo
  echo "================================================================="
  echo

  local selection
  read -p "  Enter the command you want to proceed [1-4]: " selection
  echo
  case ${selection} in
    1 ) set_new_id $(hostname);;
    2 ) set_new_id $(cat /dev/urandom | tr -dc '0-9' | head -c 9);;
    3 ) user_defined;;
    4 ) exit 0;;

    * ) echo "  Wrong answer."
        sleep 1
        main;;
  esac
}



# =====
# Starting codes in blew
# =====

if [[ $EUID -ne 0 ]]; then
  error_exit "This script must be run as ROOT!"
fi


main
script_notify_println "All successfully done.\n"
exit 0
