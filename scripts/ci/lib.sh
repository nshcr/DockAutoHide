#!/usr/bin/env bash

ci_script_name() {
  basename "${BASH_SOURCE[1]}"
}

ci_usage_with_env() {
  local usage="$1"
  local env_var="$2"

  echo "Usage: $(ci_script_name) ${usage}" >&2
  echo "Or set ${env_var} in the environment." >&2
}

ci_require_env() {
  local env_var="$1"
  if [[ -z "${!env_var:-}" ]]; then
    echo "Missing ${env_var}" >&2
    exit 1
  fi
}

ci_require_file() {
  local path="$1"
  local message="${2:-Required file not found}"

  if [[ ! -f "${path}" ]]; then
    echo "${message}: ${path}" >&2
    exit 1
  fi
}

ci_require_dir() {
  local path="$1"
  local message="${2:-Required directory not found}"

  if [[ ! -d "${path}" ]]; then
    echo "${message}: ${path}" >&2
    exit 1
  fi
}

ci_write_github_env() {
  local key="$1"
  local value="$2"

  ci_require_env "GITHUB_ENV"
  echo "${key}=${value}" >> "${GITHUB_ENV}"
}

ci_write_github_env_if_set() {
  local key="$1"
  local value="${2:-}"

  if [[ -n "${value}" ]]; then
    ci_write_github_env "${key}" "${value}"
  fi
}
