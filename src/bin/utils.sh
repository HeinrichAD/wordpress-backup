# -*- coding: utf-8 -*-

# SPDX-FileCopyrightText: 2015 Angelo Veltens <angelo.veltens@online.de>
#
# SPDX-License-Identifier: MIT

# Usage:
# Asuming this script is in the same directory:
#   LOG_SOURCE_NAME="Entrypoint"
#   source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"


# environment variables
# ------------------------------------------

function check_env() {
  local env_var="$1"
  local env_var_file="${env_var}_FILE"
  if [ -z "${!env_var:-}" ] && [ -z "${!env_var_file:-}" ]; then
    log_error "$env_var and $env_var_file are not set (but one is required)"
    echo "Finished: FAILURE" >&2
    exit 1
  fi
  if [ "${!env_var:-}" ] && [ "${!env_var_file:-}" ]; then
    log_error "Both $env_var and $env_var_file are set (but are exclusive)"
    echo "Finished: FAILURE" >&2
    exit 1
  fi
  if [ "${!env_var_file:-}" ] && ! [ -r "${!env_var_file:-}" ]; then
    log_error "$env_var_file is not a readable file"
    echo "Finished: FAILURE" >&2
    exit 1
  fi
}

function get_env() {
  local env_var="$1"
  local default_value="$2"
  local env_var_file="${env_var}_FILE"
  if [ -n "${!env_var:-}" ]; then
    echo "${!env_var}"
  elif [ -r "${!env_var_file:-}" ]; then
    cat "${!env_var_file}"
  elif [ -n "$default_value" ]; then
    echo "$default_value"
  else
    echo "Error: $env_var and $env_var_file are not set (but one is requested)"
    echo "Finished: FAILURE"
    exit 2
  fi
}


# log functions
# ------------------------------------------

log() {
  printf '%s [%s] [%s]: %s\n' "$(date --rfc-3339=seconds)" "$1" "${LOG_SOURCE_NAME:-Utils}" "${@:2}"
}

log_info() {
  log "INFO" "$@"
}

log_warn() {
  log "WARN" "$@"
}

log_error() {
  log "ERROR" "$@" >&2
}
