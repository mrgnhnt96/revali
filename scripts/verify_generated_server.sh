#!/usr/bin/env bash
#
# Regenerates the test_suite servers, then runs them.
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
# Usage: scripts/verify_generated_server.sh [--min N]

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MIN_PACKAGES=10

while [ $# -gt 0 ]; do
  case "$1" in
    --min) MIN_PACKAGES="$2"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

SUITE="test_suite/constructs/revali_server"

if [ ! -d "$SUITE" ]; then
  echo "FAIL: $SUITE does not exist."
  echo "This script names a path directly, so a rename silently stops checking"
  echo "anything -- which is the failure it was written to prevent."
  exit 1
fi

echo "=== regenerating $SUITE with the CURRENT generator"

generated=0
failed_packages=()

for dir in "$SUITE"/*/; do
  pkg="${dir%/}"

  # A package is generatable when it has routes to generate FROM. Anything
  # else here is a fixture or a stray directory.
  [ -d "$pkg/routes" ] || continue

  rel="${pkg#"$ROOT"/}"

  if (cd "$pkg" && dart run revali dev --generate-only >/tmp/revali_regen_out 2>&1); then
    generated=$((generated + 1))
    printf '  ✓ %s\n' "$rel"
    continue
  fi

  printf '  ✗ %s\n' "$rel"
  sed 's/\x1b\[[0-9;]*m//g' /tmp/revali_regen_out | tail -25 | sed 's/^/      /'
  failed_packages+=("$rel")
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

echo
echo "=== running the regenerated servers"

# Delegated rather than reimplemented: run_all_tests.sh already knows to avoid
# sip, to skip linked worktrees, and to enforce its own floor.
exec "$ROOT/scripts/run_all_tests.sh" --path test_suite
