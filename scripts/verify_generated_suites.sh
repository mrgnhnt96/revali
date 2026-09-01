#!/usr/bin/env bash
#
# Regenerates every suite under test_suite/constructs, then runs them.
#
# This exists because of the rule verify.yaml states at the top of itself: a
# change whose OUTPUT is not the thing you edited is not verified until the
# output's real consumer has consumed it. `packages/revali/lib/server/makers/`
# is a code generator, and two separate things made its gate vacuous:
#
#   1. The makers were only ever mapped to `--path packages`, so the gate ran
#      the generator's OWN tests -- which compare emitted text to emitted text
#      and cannot notice that the emitted text does not compile.
#
#   2. run_all_tests.sh never regenerates anything. It skips */.revali/* during
#      discovery and runs whatever generated code is already on disk. So even
#      pointing it at test_suite would have tested the PREVIOUS generator's
#      output and passed.
#
# Observed, not theorised: a change to server_file_maker.dart that added a line
# to every generated server passed `verify` green while every .revali/ on disk
# still held the old code. It was caught by regenerating by hand.
#
# Regeneration is the whole point of this script -- if you make it faster by
# skipping it, delete the script instead, because what is left is the gate that
# already failed.
#
# Discovery is by directory, not by a list, and that is the second reason this
# script exists. `test-suite:revali_server` and `test-suite:revali_client` in
# scripts.yaml are hand-written enumerations, and the suites lifecycle/,
# messaging/ and worker_isolates/ were simply never added to the server one --
# so nothing generated them, their tests could not compile, and packages were
# published anyway. A gate that reads the same list the generator reads cannot
# see a package missing from that list.
#
# Both constructs are covered for the same reason: revali_client's enumeration
# is complete today, but it is the same hand-written list with the same failure
# mode, and "complete today" is not a gate.
#
# Usage:
#   scripts/verify_generated_suites.sh [--min N] [--generate-only] [--jobs N]
#
# --generate-only stops after regeneration instead of delegating to
# run_all_tests.sh. It exists for callers that already run the suite afterwards
# (the pre-push hook, CI) so the tests are not run twice. It does NOT skip
# regeneration -- see above.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MIN_PACKAGES=25
GENERATE_ONLY=0
# Regenerating all of them one at a time takes ~4m45s, which is too much to add
# to a pre-push hook that already generates and runs the whole suite. Revali
# guards its shared kernel cache with a .compile.lock, so the cold compile
# serialises itself and only the generation runs concurrently.
JOBS=4

while [ $# -gt 0 ]; do
  case "$1" in
    --min) MIN_PACKAGES="$2"; shift 2 ;;
    --generate-only) GENERATE_ONLY=1; shift ;;
    --jobs) JOBS="$2"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

SUITES="test_suite/constructs"

if [ ! -d "$SUITES" ]; then
  echo "FAIL: $SUITES does not exist."
  echo "This script names a path directly, so a rename silently stops checking"
  echo "anything -- which is the failure it was written to prevent."
  exit 1
fi

# A package is generatable when it has routes to generate FROM and a pubspec to
# generate INTO. Anything else under here is a fixture or a stray directory.
# `find` rather than a glob because the suites nest: the websocket packages live
# at revali_client/websockets/*, which `$SUITES/*/*/` would not reach either.
packages=()
while IFS= read -r routes; do
  pkg="${routes%/routes}"
  [ -f "$pkg/pubspec.yaml" ] || continue
  packages+=("$pkg")
done < <(find "$SUITES" -type d -name routes \
  -not -path '*/.revali/*' -not -path '*/.dart_tool/*' -not -path '*/build/*' \
  | sort)

total=${#packages[@]}

echo "=== regenerating $total package(s) under $SUITES with the CURRENT generator"

logs="$(mktemp -d)"
trap 'rm -rf "$logs"' EXIT

# Batches of $JOBS rather than `wait -n`, which needs bash 4.3. macOS ships
# bash 3.2, and a gate that only runs on the maintainer's Linux box is not one.
i=0
while [ "$i" -lt "$total" ]; do
  launched=0
  while [ "$launched" -lt "$JOBS" ] && [ $((i + launched)) -lt "$total" ]; do
    idx=$((i + launched))
    pkg="${packages[$idx]}"
    (
      if (cd "$pkg" && dart run revali dev --generate-only >"$logs/$idx.log" 2>&1)
      then
        echo 0 >"$logs/$idx.status"
      else
        echo 1 >"$logs/$idx.status"
      fi
    ) &
    launched=$((launched + 1))
  done
  wait
  i=$((i + launched))
done

generated=0
failed_packages=()

# Reported in discovery order rather than completion order, so the output is
# the same list every run and a diff between two runs means something.
idx=0
while [ "$idx" -lt "$total" ]; do
  pkg="${packages[$idx]}"
  status="$(cat "$logs/$idx.status" 2>/dev/null || echo 1)"

  if [ "$status" = "0" ]; then
    generated=$((generated + 1))
    printf '  ✓ %s\n' "$pkg"
  else
    printf '  ✗ %s\n' "$pkg"
    sed 's/\x1b\[[0-9;]*m//g' "$logs/$idx.log" 2>/dev/null \
      | tail -25 | sed 's/^/      /'
    failed_packages+=("$pkg")
  fi

  idx=$((idx + 1))
done

echo
echo "regenerated: $generated  failed: ${#failed_packages[@]}"

if [ ${#failed_packages[@]} -gt 0 ]; then
  echo
  echo "FAIL: ${#failed_packages[@]} package(s) failed to generate:"
  printf '  - %s\n' "${failed_packages[@]}"
  echo
  echo "A generator that cannot produce a server is the loudest form of this"
  echo "failure, and the one the generator's own string tests cannot see."
  exit 1
fi

# The floor. Exiting 0 having regenerated nothing is exactly the vacuous pass
# this script exists to stop -- and it is the failure mode that hides longest,
# because a gate that checks nothing looks identical to a gate that passed.
if [ "$generated" -lt "$MIN_PACKAGES" ]; then
  echo
  echo "FAIL: only $generated package(s) regenerated, expected at least $MIN_PACKAGES."
  echo "Something stopped discovering them. That is a broken gate, not a pass."
  exit 1
fi

if [ "$GENERATE_ONLY" -eq 1 ]; then
  echo
  echo "OK: every package under $SUITES regenerated."
  exit 0
fi

echo
echo "=== running the regenerated servers"

# Delegated rather than reimplemented: run_all_tests.sh already knows to avoid
# sip, to skip linked worktrees, and to enforce its own floor.
exec "$ROOT/scripts/run_all_tests.sh" --path test_suite
