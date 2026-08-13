#!/usr/bin/env bash
#
# Runs every package's tests with `dart test` and fails if any package fails.
#
# Deliberately not `sip test`. In
# test_suite/constructs/revali_server/access_control, `dart test` exits 1 with
# 3 failures while `sip test` exits 0 reporting "40 passed, 0 failed" -- the
# failing tests disappear from both the count and the exit code. A gate built
# on a runner that cannot go red is not a gate.
#
# Also enforces a floor. Exiting 0 having run nothing is the other way a test
# gate lies, and it is the one that hides for longest.
#
# Usage: scripts/run_all_tests.sh [--min N]

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MIN_PACKAGES=25
while [ $# -gt 0 ]; do
  case "$1" in
    --min) MIN_PACKAGES="$2"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

failed_packages=()
passed=0
ran=0
skipped=0

# Every package with tests, minus generated output and the fixtures that are
# compiled by other packages' tests rather than run on their own.
while IFS= read -r pubspec; do
  dir="$(dirname "$pubspec")"

  case "$dir" in
    */.dart_tool/*|*/.revali/*|*/build/*) continue ;;
    */test/fixtures/*|*/fixtures/*) continue ;;
  esac

  [ -d "$dir/test" ] || continue

  rel="${dir#"$ROOT"/}"

  if (cd "$dir" && dart test --reporter=failures-only >/tmp/revali_test_out 2>&1); then
    ran=$((ran + 1))
    passed=$((passed + 1))
    printf '  ✓ %s\n' "$rel"
    continue
  fi

  # `dart test` also exits 1 when a package simply has nothing to run. That is
  # a package with an empty test/ directory, not a failure.
  if grep -qE 'No tests (ran|were found)' /tmp/revali_test_out; then
    skipped=$((skipped + 1))
    printf '  – %s (no tests)\n' "$rel"
    continue
  fi

  # A package without a `test` dev_dependency cannot run tests at all. That is
  # not a failing suite -- e.g. the root `hooks` package, whose test/ directory
  # only ever holds sip's generated optimizer file.
  if grep -q 'Could not find package `test`' /tmp/revali_test_out; then
    skipped=$((skipped + 1))
    printf '  – %s (no test dependency)\n' "$rel"
    continue
  fi

  ran=$((ran + 1))
  printf '  ✗ %s\n' "$rel"
  sed 's/\x1b\[[0-9;]*m//g' /tmp/revali_test_out | tail -25 | sed 's/^/      /'
  failed_packages+=("$rel")
done < <(find . -name pubspec.yaml -not -path '*/.dart_tool/*' | sort)

echo
echo "packages run: $ran  passed: $passed  failed: ${#failed_packages[@]}  skipped: $skipped"

if [ "$ran" -lt "$MIN_PACKAGES" ]; then
  echo
  echo "FAIL: only $ran package(s) ran, expected at least $MIN_PACKAGES."
  echo "Something stopped discovering tests -- that is a broken gate, not a pass."
  exit 1
fi

if [ ${#failed_packages[@]} -gt 0 ]; then
  echo
  echo "FAIL: ${#failed_packages[@]} package(s) failed:"
  printf '  - %s\n' "${failed_packages[@]}"
  exit 1
fi

echo "OK"
