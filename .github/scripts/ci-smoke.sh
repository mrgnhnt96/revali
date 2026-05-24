#!/usr/bin/env bash
# Minimal CI smoke test: bootstrap deps and run revali on examples/hello.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOG_DIR="$ROOT/logs/ci-smoke"
PROJECT="examples/hello"
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
  dart pub global activate sip_cli
  export PATH="${HOME}/.pub-cache/bin:${PATH}"
  command -v sip
  sip pub get --recursive --no-version-check --no-concurrent
}

step_build_runner() {
  local packages=(
    packages/revali_construct
    revali_router/revali_router
    constructs/revali_server
  )

  for relative in "${packages[@]}"; do
    echo "build_runner in $relative"
    (
      cd "$ROOT/$relative"
      dart pub get
      dart run build_runner build --delete-conflicting-outputs
    )
  done
}

step_hello() {
  (
    cd "$ROOT/$PROJECT"
    dart pub get
    dart run revali dev --generate-only --recompile
    dart run revali build
  )
}

overall_exit=0

run_step 'Environment' "$LOG_DIR/00-environment.log" step_environment || overall_exit=1
run_step 'Bootstrap tooling' "$LOG_DIR/01-bootstrap.log" step_bootstrap || overall_exit=1
run_step 'Build runner (codegen deps)' "$LOG_DIR/02-build-runner.log" step_build_runner || overall_exit=1
run_step 'Hello example (revali generate + build)' "$LOG_DIR/03-hello.log" step_hello || overall_exit=1

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
