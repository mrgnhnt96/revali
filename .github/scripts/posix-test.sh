#!/usr/bin/env bash
# macOS/Linux CI test runner for Revali.
# All output is tee'd to numbered log files under logs/ci/ for export.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOG_DIR="$ROOT/logs/ci"
STEP_RESULTS=()

mkdir -p "$LOG_DIR"
cd "$ROOT"

write_step_header() {
  local name="$1"
  local log_file="$2"
  cat >"$log_file" <<EOF
================================================================================
STEP: $name
Started: $(date '+%Y-%m-%d %H:%M:%S %z')
Working directory: $(pwd)
================================================================================

EOF
}

run_logged_step() {
  local name="$1"
  local log_file="$2"
  shift 2

  echo ""
  echo "==> $name"
  write_step_header "$name" "$log_file"

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

add_pub_cache_bin_to_path() {
  export PATH="${HOME}/.pub-cache/bin:${PATH}"
}

set_revali_pubspec_path_dependencies() {
  local comment_out="$1"
  while IFS= read -r -d '' pubspec; do
    if [[ "$pubspec" == *"/.revali/"* ]]; then
      continue
    fi

    python3 - "$pubspec" "$comment_out" <<'PY'
import sys

pubspec_path, comment_out = sys.argv[1], sys.argv[2] == "true"
with open(pubspec_path, encoding="utf-8") as handle:
    lines = handle.read().splitlines()

changed = False
for index, line in enumerate(lines):
    if "path:" not in line or ".revali/" not in line:
        continue

    if comment_out:
        if index > 0 and not lines[index - 1].lstrip().startswith("#"):
            lines[index - 1] = f"#{lines[index - 1]}"
            changed = True
        if not line.lstrip().startswith("#"):
            lines[index] = f"#{line}"
            changed = True
    else:
        if index > 0 and lines[index - 1].lstrip().startswith("#"):
            lines[index - 1] = lines[index - 1].lstrip("#").lstrip()
            changed = True
        if line.lstrip().startswith("#"):
            lines[index] = line.lstrip("#").lstrip()
            changed = True

if changed:
    with open(pubspec_path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(lines) + "\n")
    print(f"Updated {pubspec_path}")
PY
  done < <(find "$ROOT" -name pubspec.yaml -not -path '*/.revali/*' -print0)
}

run_dart_in_directory() {
  local directory="$1"
  shift
  (
    cd "$directory"
    dart "$@"
  )
}

run_test_suite_generation() {
  local failures=()
  local server_dirs=(
    methods access_control custom_return_types primitive_return_types
    null_primitive_return_types middleware params pipes default_params
    custom_params sse sse_custom meta_reflect
  )
  local client_dirs=(
    can_compile_aot cookies primitive_return_types null_primitive_return_types
    custom_return_types default_params default_custom_params methods params
    sse sse_custom
    websockets/custom_return_types websockets/primitive_return_types
    websockets/params websockets/null_primitive_return_types websockets/two_way
  )

  for dir in "${server_dirs[@]}"; do
    echo "Generating server test suite: $dir"
    if ! run_dart_in_directory "$ROOT/test_suite/constructs/revali_server/$dir" \
      run revali dev --generate-only --recompile; then
      failures+=("revali_server/$dir")
    fi
  done

  for dir in "${client_dirs[@]}"; do
    echo "Generating client test suite: $dir"
    if ! run_dart_in_directory "$ROOT/test_suite/constructs/revali_client/$dir" \
      run revali dev --generate-only --recompile; then
      failures+=("revali_client/$dir")
    fi
  done

  if ((${#failures[@]} > 0)); then
    echo "Generation failures:"
    printf '  - %s\n' "${failures[@]}"
    return 1
  fi

  return 0
}

run_recursive_dart_tests() {
  local failures=()
  local pubspec

  while IFS= read -r -d '' pubspec; do
    if [[ "$pubspec" == *"/.revali/"* || "$pubspec" == *"/examples/"* ]]; then
      continue
    fi

    local package_dir
    package_dir="$(dirname "$pubspec")"
    if [[ ! -d "$package_dir/test" ]]; then
      continue
    fi

    local relative_path="${package_dir#"$ROOT"/}"
    echo ""
    echo "--- dart test in $relative_path ---"

    (
      cd "$package_dir"
      dart pub get -v
      dart test --reporter expanded --chain-stack-traces --verbose-trace
    ) || failures+=("$relative_path")
  done < <(find "$ROOT" -name pubspec.yaml -print0 | sort -z)

  if ((${#failures[@]} > 0)); then
    echo ""
    echo "Test failures:"
    printf '  - %s\n' "${failures[@]}"
    return 1
  fi

  return 0
}

step_environment() {
  echo "Root: $ROOT"
  echo "Log directory: $LOG_DIR"
  echo "Computer: $(hostname)"
  echo "User: $(whoami)"
  echo "OS: $(uname -a)"
  echo "Shell: $SHELL"
  echo "PATH: $PATH"
  command -v dart
  dart --version -v
  git --version
}

step_bootstrap() {
  dart pub global activate sip_cli
  add_pub_cache_bin_to_path
  echo "Pub cache bin: ${HOME}/.pub-cache/bin"
  command -v sip

  (
    cd "$ROOT/hooks"
    dart pub get -v
  )
  (
    cd "$ROOT/scripts"
    dart pub get -v
  )
  sip pub get --recursive --no-version-check
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
      dart pub get -v
      dart run build_runner build --delete-conflicting-outputs -v
    )
  done
}

step_test_suite_generation() {
  echo 'Commenting out .revali path dependencies...'
  set_revali_pubspec_path_dependencies true

  (
    cd "$ROOT/test_suite"
    dart pub get -v
  )

  run_test_suite_generation

  echo 'Restoring .revali path dependencies...'
  set_revali_pubspec_path_dependencies false

  (
    cd "$ROOT/test_suite"
    dart pub get -v
  )
}

step_recursive_tests() {
  run_recursive_dart_tests
}

step_hello_example() {
  (
    cd "$ROOT/examples/hello"
    dart pub get -v
    dart run revali dev --generate-only --recompile
    dart run revali build
  )
}

overall_exit=0

run_logged_step 'Environment' "$LOG_DIR/00-environment.log" step_environment || overall_exit=1
run_logged_step 'Bootstrap tooling' "$LOG_DIR/01-bootstrap.log" step_bootstrap || overall_exit=1
run_logged_step 'Build runner code generation' "$LOG_DIR/02-build-runner.log" step_build_runner || overall_exit=1
run_logged_step 'Test suite generation' "$LOG_DIR/03-test-suite-gen.log" step_test_suite_generation || overall_exit=1
run_logged_step 'Recursive dart tests' "$LOG_DIR/04-recursive-tests.log" step_recursive_tests || overall_exit=1
run_logged_step 'Hello example smoke test' "$LOG_DIR/05-hello-example.log" step_hello_example || overall_exit=1

summary_path="$LOG_DIR/summary.log"
{
  echo "Revali CI summary"
  echo "Completed: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo "Root: $ROOT"
  echo "Overall exit code: $overall_exit"
  echo ""
  echo "Step results:"
  for result in "${STEP_RESULTS[@]}"; do
    IFS='|' read -r status name exit_code log_file <<<"$result"
    echo "- [$status] $name (exit $exit_code) -> $log_file"
  done
  echo ""
  echo "Download the logs/ci artifact from the GitHub Actions run to share these files."
} | tee "$summary_path"

exit "$overall_exit"
