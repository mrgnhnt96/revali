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
# `dart test` also honours `dart_test.yaml` tag skips, which `sip test` does
# not: in packages/revali_redis, `dart test` reports "+50 ~1" (the
# @Tags(['integration']) suite skipped) while `sip test` runs all 62. That
# divergence is why the pre-commit hook calls this script with --path rather
# than running sip itself -- a hook that runs tests the suite declared skippable
# fails on machines without the infrastructure those tests need.
#
# Usage: scripts/run_all_tests.sh [--min N] [--path DIR]

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Linked git worktrees are checkouts of THIS repo living inside it, so package
# discovery walks straight into a full second copy of the suite -- which has no
# .dart_tool, so every package in it fails to resolve.
#
# Ask git where they are rather than guessing a directory name. showrunner puts
# them in .worktrees/, the harness's own worktree tool uses .claude/worktrees/,
# and a hand-made one goes wherever its author said. Matching on a convention
# is a race this script loses quietly: the failures look like a broken merge,
# and they scale with however many worktrees happen to exist.
#
# Only worktrees strictly INSIDE this checkout are candidates. Excluding merely
# "the one that is ROOT" is not enough and fails in the direction that hurts:
# run from inside a worktree, ROOT is that worktree and the main checkout is its
# PARENT, so every package under ROOT sits below it and the whole suite is pruned
# to nothing -- 0 packages, which the floor below correctly calls a broken gate.
# Discovery never walks above ROOT anyway, so anything not under it is not a
# candidate in the first place.
#
# The trailing `?*` matters: `"$ROOT"/*` would also match `$ROOT/` itself, since
# `*` matches the empty string -- which is the same self-prune by another route.
worktree_prefixes=()
while IFS= read -r line; do
  case "$line" in
    "worktree "*)
      wt="${line#worktree }"
      case "$wt" in
        "$ROOT") ;;
        "$ROOT"/?*) worktree_prefixes+=("$wt") ;;
      esac
      ;;
  esac
done < <(git worktree list --porcelain 2>/dev/null || true)

MIN_PACKAGES=25
SEARCH_ROOT="."
SCOPED=0
while [ $# -gt 0 ]; do
  case "$1" in
    --min) MIN_PACKAGES="$2"; shift 2 ;;
    # Scope discovery to one package subtree, still recursively -- the hook
    # needs the nested packages under e.g. revali_router/ too.
    --path)
      SEARCH_ROOT="$2"
      SCOPED=1
      shift 2
      ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ ! -d "$SEARCH_ROOT" ]; then
  echo "no such directory: $SEARCH_ROOT" >&2
  exit 2
fi

# A whole-repo run expects dozens of packages; a scoped run may legitimately
# hold one. The floor still exists either way -- exiting 0 having run nothing
# is the other way a test gate lies.
if [ "$SCOPED" -eq 1 ] && [ "$MIN_PACKAGES" -eq 25 ]; then
  MIN_PACKAGES=1
fi

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

  # Skip anything inside a linked worktree -- see worktree_prefixes above.
  case "$dir" in
    /*) abs_dir="$dir" ;;
    ./*) abs_dir="$ROOT/${dir#./}" ;;
    *) abs_dir="$ROOT/$dir" ;;
  esac
  in_worktree=0
  for wt in ${worktree_prefixes+"${worktree_prefixes[@]}"}; do
    case "$abs_dir/" in "$wt"/*) in_worktree=1; break ;; esac
  done
  [ "$in_worktree" -eq 0 ] || continue

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
done < <(find "$SEARCH_ROOT" -name pubspec.yaml \
  -not -path '*/.dart_tool/*' -not -path '*/.worktrees/*' | sort)

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
