#!/usr/bin/env bash
# Minimal CI smoke test: bootstrap deps and run revali on small_test.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOG_DIR="$ROOT/logs/ci-smoke"
PROJECT="small_test"
STEP_RESULTS=()

mkdir -p "$LOG_DIR"
cd "$ROOT"

run_step() {
  local name="$1"
  local log_file="$2"
  shift 2

  echo ""
  echo "==> $name"
  {
    echo "STEP: $name"
    echo "Started: $(date '+%Y-%m-%d %H:%M:%S %z')"
    echo ""
  } >"$log_file"

  local exit_code=0
  if "$@" >>"$log_file" 2>&1; then
    exit_code=0
  else
    exit_code=$?
  fi

  local status="PASS"
  if [[ "$exit_code" -ne 0 ]]; then
    status="FAIL"
  fi

  {
    echo ""
    echo "Finished: $(date '+%Y-%m-%d %H:%M:%S %z') | Status: $status | Exit code: $exit_code"
  } >>"$log_file"

  STEP_RESULTS+=("$status|$name|$exit_code|$(basename "$log_file")")
  return "$exit_code"
}

step_environment() {
  echo "Root: $ROOT"
  echo "Project: $PROJECT"
  echo "OS: $(uname -a)"
  dart --version -v
  git --version
}

step_bootstrap() {
  echo "nada"
}

step_small_test() {
  (
    cd "$ROOT/$PROJECT"
    dart pub get
    dart run revali dev --generate-only --recompile
  )
}

overall_exit=0

run_step 'Environment' "$LOG_DIR/00-environment.log" step_environment || overall_exit=1
run_step 'Bootstrap tooling' "$LOG_DIR/01-bootstrap.log" step_bootstrap || overall_exit=1
run_step 'small_test (revali generate-only)' "$LOG_DIR/02-small-test.log" step_small_test || overall_exit=1

summary_path="$LOG_DIR/summary.log"
{
  echo "Revali CI smoke summary"
  echo "Project: $PROJECT"
  echo "Completed: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo "Root: $ROOT"
  echo "Overall exit code: $overall_exit"
  echo ""
  echo "Step results:"
  for result in "${STEP_RESULTS[@]}"; do
    IFS='|' read -r status name exit_code log_file <<<"$result"
    echo "- [$status] $name (exit $exit_code) -> $log_file"
  done
} | tee "$summary_path"

exit "$overall_exit"
