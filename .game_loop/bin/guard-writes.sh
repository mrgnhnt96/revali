#!/usr/bin/env bash
# Fail-open entrypoint for the write guard. The real logic lives in guard-writes-impl.sh; this shim
# runs it, but if that file cannot even PARSE (a broken edit) it ALLOWS the tool instead of exiting 2.
#
# WHY: a PreToolUse hook that exits non-zero BLOCKS the tool. If the guard's own code has a syntax
# error, every Write/Edit/Bash — including the one that would REPAIR the guard — is blocked, and the
# session can only be rescued from outside the run. A guard that cannot parse is not guarding anything
# anyway, so failing OPEN keeps the repo editable back to health. Keep THIS file trivially correct: it
# is the piece that must never itself break — put no real logic here; all of it lives in the impl.
impl="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/guard-writes-impl.sh"
bash -n "$impl" 2>/dev/null || exit 0        # impl unparseable / missing → fail OPEN (allow, repairable)
exec bash "$impl"
