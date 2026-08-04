#!/usr/bin/env bash
# guard-writes — deny any mutation outside this repo. A PreToolUse hook (LOUD rung: fails at the
# point of misuse, with a reason). This is the guardrail that makes unattended running safe: an agent
# left alone all night cannot touch anything outside the project it was pointed at.
#
# WHY THIS CANNOT LIVE IN CLAUDE.md: "don't touch other projects" written as an instruction is a
# promise, and the whole premise of game_loop is that promises break under long sessions and compaction.
# A hook holds whether or not the agent remembers it.
#
# THE MODEL: an ALLOWLIST, not a denylist. Writes are permitted only under the repo, the OS temp dir,
# this project's agent-memory dir, and anything in config.json -> allow_write_roots. Everything else
# is denied by default. A denylist ("block ~/dev, ~/.ssh, ...") defaults to UNPROTECTED and silently
# misses whatever nobody remembered to list; an allowlist defaults to PROTECTED.
#
# SCOPE — what this DOES and does NOT catch (a guard that overstates its reach buys false confidence):
#   DOES: Write/Edit/NotebookEdit whose target resolves outside the allow roots.
#   DOES: Bash mutators (rm/mv/cp/mkdir/chmod/... , shell redirects, git writes, sed -i) whose
#         resolved target is outside the allow roots. Paths resolved by realpath, `cd` tracked across
#         segments, every offending path collected (not just the first).
#   DOES: Bash invoking a configured deploy/publish verb, anywhere (config.json -> deploy_verbs).
#   DOES NOT: catch mutations made via MCP tools, an interpreter one-liner (`python3 -c 'os.remove(..)'`),
#             a path built from a shell variable (`rm $TARGET/x`), or a script that mutates without
#             naming the path on the command line. Those need tool-level matching this does not do.
#             Do not read silence here as safety.
#
# THE ESCAPE HATCH IS THE HUMAN, deliberately. There is no env-var override — a guard the agent can
# switch off is not a guard. A single mutation outside the repo is unlocked only by
# `game_loop authorize --path <prefix> --reason "<their words>"`, which is single-use and logged forever.

set -uo pipefail
payload=$(cat)

GAMELOOP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"    # .game_loop/
REPO="${CLAUDE_PROJECT_DIR:-$(dirname "$GAMELOOP_DIR")}"
CONFIG_F="$GAMELOOP_DIR/config.json"

REPO_REAL=$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$REPO" 2>/dev/null)
SLUG=$(python3 -c 'import re,sys; print(re.sub(r"[^a-zA-Z0-9]", "-", sys.argv[1]))' "$REPO_REAL" 2>/dev/null)

# State is per-session: an authorization is granted IN a session and spendable only THERE. The hook
# payload's session_id is authoritative; env is the fallback; neither → the repo-global legacy file
# (human terminal, old harness). Mirrors set_session() in bin/game_loop and bin/watchdog.
SID=$(printf '%s' "$payload" | python3 -c '
import json, os, re, sys
sid = json.load(sys.stdin).get("session_id") or os.environ.get("GAME_LOOP_SESSION") or os.environ.get("CLAUDE_CODE_SESSION_ID") or ""
print(re.sub(r"[^A-Za-z0-9._-]", "-", sid.strip())[:64])' 2>/dev/null)
if [ -n "$SID" ]; then
  STATE_F="$GAMELOOP_DIR/sessions/$SID/state.json"
else
  STATE_F="$GAMELOOP_DIR/state.json"
fi

deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}\n' \
    "$(printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')"
  exit 0
}

# Like deny(), but defers to the human's normal interactive approval instead of hard-blocking. Used
# only for the out-of-repo write case: the human approves inline, once, right where they are — no
# separate `game_loop authorize` terminal command needed. NOTE: on an unattended run with nobody to
# answer, "ask" has no human to resolve it and the tool call stalls/denies by timeout — this trades
# away part of the unattended-safety guarantee INV3 exists for, in exchange for interactive speed.
ask() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":%s}}\n' \
    "$(printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')"
  exit 0
}

# A human-authorized, single-use exception (`game_loop authorize`). Takes the offending realpath;
# prints "yes" iff a live authorization covers it, in which case the authorization is CONSUMED and
# the spend logged — one authorization buys one mutation, whichever tool performs it. Shared by the
# Write/Edit and Bash branches so the escape hatch behaves identically on both paths. No env
# override: it cannot be set without writing a permanent log entry carrying the human's own words.
consume_authorization() {
  OFFENDER="$1" GAMELOOP_DIR="$GAMELOOP_DIR" STATE_F="$STATE_F" SID="$SID" python3 <<'PY'
import json, os, sys, datetime
state_f = os.environ["STATE_F"]
log_f = os.path.join(os.environ["GAMELOOP_DIR"], "log.jsonl")
sid = os.environ.get("SID", "")
off = os.environ["OFFENDER"]
try:
    with open(state_f) as f:
        st = json.load(f)
except (OSError, ValueError):
    sys.exit(0)
for a in st.get("authorized", []):
    if a.get("uses_left", 0) <= 0:
        continue
    root = a.get("path", "")
    if off == root or off.startswith(root + os.sep):
        a["uses_left"] -= 1
        try:
            with open(state_f, "w") as f:
                json.dump(st, f, indent=2); f.write("\n")
            with open(log_f, "a") as f:
                rec = {"t": datetime.datetime.now().isoformat(timespec="seconds")}
                if sid:
                    rec["sid"] = sid[:8]
                rec.update({"kind": "authorized_write", "path": off,
                            "reason": a.get("reason"), "uses_left": a["uses_left"]})
                f.write(json.dumps(rec) + "\n")
        except OSError:
            sys.exit(0)
        print("yes")
        break
PY
}

tool=$(printf '%s' "$payload" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_name",""))' 2>/dev/null)

case "$tool" in
  Write|Edit|NotebookEdit)
    fp=$(printf '%s' "$payload" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null)
    [ -z "$fp" ] && exit 0
    # Prints "yes" when the target is inside an allow root, else the resolved realpath — which is
    # what an authorization is matched against (authorize records real prefixes, not raw tool input).
    verdict=$(REPO_REAL="$REPO_REAL" SLUG="$SLUG" CONFIG_F="$CONFIG_F" FP="$fp" python3 <<'PY'
import json, os
repo = os.environ["REPO_REAL"]
home = os.path.expanduser("~")
allow = [repo, "/tmp", "/private/tmp", "/var/folders",
         os.path.join(home, ".claude", "projects", os.environ["SLUG"])]
try:
    with open(os.environ["CONFIG_F"]) as f:
        allow += [os.path.expanduser(p) for p in (json.load(f).get("allow_write_roots") or [])]
except (OSError, ValueError):
    pass
allow = [os.path.realpath(p) for p in allow]
real = os.path.realpath(os.environ["FP"])
print("yes" if any(real == a or real.startswith(a + os.sep) for a in allow) else real)
PY
)
    [ "$verdict" = "yes" ] && exit 0
    if [ -n "$verdict" ]; then
      consumed=$(consume_authorization "$verdict")
      [ "$consumed" = "yes" ] && exit 0
    fi
    ask "Write outside this repo → $fp

Everything outside this project is READ-ONLY by default unless you approve this specific write.
Approving allows this one write; it does not disable the guard for anything else."
    ;;

  Bash)
    cmd=$(printf '%s' "$payload" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null)
    [ -z "$cmd" ] && exit 0

    # A heredoc/quoted DATA body (e.g. a commit message piped through a here-doc into cat) is DATA, not
    # executed shell — scanning it for redirects / mutators / deploy verbs false-positives on ordinary
    # prose. scan_cmd is $cmd with the bodies of here-docs fed to a known DATA SINK (cat/tee) removed,
    # and the quoted arguments of known MESSAGE-BEARING flags (-m/--notes/--reason/…) blanked: those
    # strings are prose their commands never execute, and scanning them denies commit messages that
    # merely mention a redirect or a deploy verb. Bodies of here-docs fed to an interpreter
    # (bash/sh/python/…) are KEPT — they DO run and must stay guarded, and so are all other quoted
    # strings (bash -c '…' executes). Unknown consumer -> KEPT (fail safe: a false positive, never a
    # silent bypass).
    #
    # NB: this Python is embedded in a $(...) here-doc, so it must contain NO backtick, NO dollar-paren,
    # and NO literal here-doc operator — any of those derails bash's parse of the surrounding $(...).
    # The here-doc operator is therefore built from chr(60); the consumer is found by a plain word scan.
    scan_cmd=$(CMD="$cmd" python3 <<'PY'
import os, re, sys
cmd = os.environ["CMD"]
DATA_SINKS = {"cat", "tee"}
HD = chr(60) + chr(60)                       # the here-doc operator, with no literal one in this file
opener = re.compile(re.escape(HD) + r"-?\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1")
lines = cmd.split("\n")
out, i = [], 0
while i < len(lines):
    line = lines[i]
    out.append(line)
    found = opener.findall(line)
    if found:
        # The consumer is the last command word BEFORE the here-doc operator — after dropping
        # redirect clauses, or the redirect TARGET would be mistaken for the consumer
        # (in a line like: cat with a redirect, then the operator, the consumer is cat).
        pre = re.sub(r">>?\s*[^\s;&|<>]*", " ", line.split(HD, 1)[0])
        words = re.findall(r"[A-Za-z0-9_./]+", pre)
        is_data = (os.path.basename(words[-1]) if words else "") in DATA_SINKS
        delims = [d for _q, d in found]
        i += 1
        di = 0
        while i < len(lines) and di < len(delims):
            body = lines[i]
            if body.strip() == delims[di]:
                out.append(body)             # keep the delimiter line itself
                di += 1
            elif not is_data:
                out.append(body)             # code here-doc: body executes — keep it in the scan
            # data here-doc: drop the body line (it is data, not shell)
            i += 1
        continue
    i += 1

# Blank the quoted argument of message-bearing flags. These strings are DATA to their command
# (a commit message, a note, a reason) — never executed — so redirects or deploy verbs mentioned
# inside them must not be flagged. Quoted strings NOT behind one of these flags are kept: an
# interpreter argument (a -c script) executes and must stay guarded.
MSG_FLAGS = ("-m|--message|--notes|--reason|--body|--title|--assert|--learning|--question"
             "|--predict|--doing|--milestone|--set")
QSTR = "\"(?:[^\"\\\\]|\\\\.)*\"|'[^']*'"
text = "\n".join(out)
text = re.sub("(?:^|(?<=\\s))(" + MSG_FLAGS + ")(=|\\s+)(" + QSTR + ")",
              lambda m: m.group(1) + m.group(2) + "\"\"", text)
sys.stdout.write(text)
PY
)

    # 0. A commit is when a change becomes real. Refuse one whose owed checks (.game_loop/verify.yaml)
    #    have not run SINCE the change. No-op when verify.yaml is empty, so it costs nothing until you
    #    opt in. --no-verify skips it, out loud and on the record. Gates `git commit` only, not every
    #    write: a check per keystroke is ceremony that gets switched off.
    #    Gates only commits that TARGET THIS repo: verify.yaml describes THIS repo's owed checks, and a
    #    commit made in some other repository (a clone in a scratch root, a sibling project) owes that
    #    repo's checks, not ours. The target is resolved per segment — `cd` tracked, `git -C` honored —
    #    the same way the mutation scanner resolves paths.
    commit_here=$(REPO_REAL="$REPO_REAL" SCAN_CMD="$scan_cmd" python3 - "$payload" <<'PY'
import json, os, re, shlex, sys
payload = json.loads(sys.argv[1])
cmd = os.environ.get("SCAN_CMD", "")
repo = os.environ["REPO_REAL"]
cwd = payload.get("cwd") or repo
home = os.path.expanduser("~")
for seg in re.split(r"&&|\|\||;|\||\n", cmd):
    try:
        argv = shlex.split(seg)
    except ValueError:
        argv = seg.split()
    if not argv:
        continue
    verb = os.path.basename(argv[0])
    args = argv[1:]
    if verb == "cd" and args:
        nxt = os.path.expanduser(args[0].replace("$HOME", home))
        cwd = nxt if os.path.isabs(nxt) else os.path.join(cwd, nxt)
        continue
    if verb != "git" or "commit" not in args or "--no-verify" in args:
        continue
    tgt = cwd
    if "-C" in args and args.index("-C") + 1 < len(args):
        c = os.path.expanduser(args[args.index("-C") + 1].replace("$HOME", home))
        tgt = c if os.path.isabs(c) else os.path.join(cwd, c)
    tgt = os.path.realpath(tgt)
    if tgt == repo or tgt.startswith(repo + os.sep):
        print("yes")
        break
PY
)
    if [ "$commit_here" = "yes" ]; then
      if ! "$GAMELOOP_DIR/bin/verify" --check >/tmp/.game_loop_verify 2>&1; then
        # ORDERING NOTE: this hook runs at PreToolUse, BEFORE the command body executes. Bundling
        # `verify` and `git commit` in ONE call can never pass — the check runs before your verify
        # line does. Run them as two separate calls.
        chained_hint=""
        if printf '%s' "$cmd" | grep -qE 'bin/verify|\bverify\b'; then
          chained_hint="
YOU CHAINED verify WITH THIS COMMIT IN ONE COMMAND. That can't work: this gate runs BEFORE the
command body, so your verify line hasn't executed yet. Run verify as a SEPARATE, EARLIER call."
        fi
        deny "$(cat /tmp/.game_loop_verify)

A green check from BEFORE your change is evidence about code that no longer exists.
Run ./.game_loop/bin/verify, or commit with --no-verify to skip it on the record.$chained_hint"
      fi
    fi

    # 1. Configured deploy/publish verbs — denied anywhere, no path needed.
    deploy_hit=$(CONFIG_F="$CONFIG_F" CMD="$scan_cmd" python3 <<'PY'
import json, os, re
defaults = ["npm publish", "yarn publish", "pnpm publish", "twine upload",
            "gh release create", "docker push"]
verbs = list(defaults)
try:
    with open(os.environ["CONFIG_F"]) as f:
        verbs += (json.load(f).get("deploy_verbs") or [])
except (OSError, ValueError):
    pass
cmd = os.environ["CMD"]
for v in verbs:
    # The boundary class includes quote chars: a deploy verb at the start of an interpreter arg
    # (a -c script) executes just the same, and message-flag strings were already blanked upstream.
    pat = r"(^|[\s;&|'\"])" + r"\s+".join(re.escape(w) for w in v.split())
    if re.search(pat, cmd):
        print(v)
        break
PY
)
    if [ -n "$deploy_hit" ]; then
      deny "BLOCKED: deploy/publish verb '$deploy_hit'.

This is an irreversible, outward-facing action (a real publish/release/deploy). An unattended agent
does not fire these. If it is genuinely needed, escalate to the human — that is the only escape
hatch, by design. (Configured in .game_loop/config.json -> deploy_verbs.)"
    fi

    # 2. Mutation aimed OUTSIDE the allow roots, decided by RESOLVING PATHS — not matching names.
    offender=$(REPO_REAL="$REPO_REAL" SLUG="$SLUG" CONFIG_F="$CONFIG_F" SCAN_CMD="$scan_cmd" python3 - "$payload" <<'PY'
import json, os, re, shlex, sys

payload = json.loads(sys.argv[1])
cmd = os.environ.get("SCAN_CMD", "")          # here-doc DATA bodies already stripped (see scan_cmd)
cwd = payload.get("cwd") or os.environ["REPO_REAL"]
home = os.path.expanduser("~")

allow = [os.environ["REPO_REAL"], "/tmp", "/private/tmp", "/var/folders",
         os.path.join(home, ".claude", "projects", os.environ["SLUG"])]
try:
    with open(os.environ["CONFIG_F"]) as f:
        allow += [os.path.expanduser(p) for p in (json.load(f).get("allow_write_roots") or [])]
except (OSError, ValueError):
    pass
allow = [os.path.realpath(p) for p in allow]

MUTATORS = {"rm", "rmdir", "touch", "mkdir", "chmod", "chown", "ln", "dd", "truncate", "tee"}
GIT_WRITES = {"commit", "push", "reset", "rebase", "checkout", "clean", "apply", "restore", "mv"}


def under(path, root):
    return path == root or path.startswith(root + os.sep)


# Standard character devices: discard sinks and the console/std streams. A redirect to one of these
# (e.g. `2>/dev/null`, `>/dev/stderr`) never writes a real out-of-repo file, so it must not be flagged.
# Matched on the LITERAL path — /dev/stdout & friends are symlinks realpath would resolve away.
STD_DEVICES = {"/dev/null", "/dev/zero", "/dev/stdin", "/dev/stdout", "/dev/stderr", "/dev/tty",
               "/dev/random", "/dev/urandom"}


def offends(raw, cwd):
    """Return the offending realpath, or None if this path is inside an allow root."""
    p = os.path.expanduser(raw.replace("$HOME", home))
    if not os.path.isabs(p):
        p = os.path.join(cwd, p)
    if p in STD_DEVICES or p.startswith("/dev/fd/"):
        return None
    real = os.path.realpath(p)
    return None if any(under(real, a) for a in allow) else real


def redirect_targets(seg):
    """Redirect targets in one segment, QUOTE-AWARE in both directions: a redirect character inside
    quotes is data (a sed script, prose in a message) and must not be flagged, while a QUOTED target
    after a real, unquoted redirect is a genuine write and must be — the naive regex missed those,
    because a captured token starting with a quote char never resolves to an absolute path."""
    targets, i, n, q = [], 0, len(seg), None
    while i < n:
        c = seg[i]
        if q:
            if c == q:
                q = None
        elif c in "'\"":
            q = c
        elif c == ">":
            j = i + 1
            if j < n and seg[j] == ">":
                j += 1
            while j < n and seg[j] in " \t":
                j += 1
            if j < n and seg[j] in "'\"":
                k = seg.find(seg[j], j + 1)
                if k != -1:
                    targets.append(seg[j + 1:k])
                    i = k
            else:
                k = j
                while k < n and seg[k] not in " \t;&|<>":
                    k += 1
                if k > j:
                    targets.append(seg[j:k])
                    i = k - 1
        i += 1
    return targets


offenders = []
# Split on shell separators AND newlines. Omitting \n would collapse a multi-line command into one
# segment whose verb is its first token, so a mutating later line would never be checked.
for seg in re.split(r"&&|\|\||;|\||\n", cmd):
    try:
        argv = shlex.split(seg)
    except ValueError:
        argv = seg.split()
    if not argv:
        continue
    verb = os.path.basename(argv[0])
    args = argv[1:]
    pathish = [a for a in args if not a.startswith("-") and "&" not in a and a not in (">", ">>")]

    if verb == "cd" and pathish:
        nxt = os.path.expanduser(pathish[0].replace("$HOME", home))
        cwd = nxt if os.path.isabs(nxt) else os.path.join(cwd, nxt)
        continue

    check = []
    if verb == "cp":
        check = pathish[-1:]                       # cp checks its DESTINATION only (reading is fine)
    elif verb == "mv":
        check = pathish                            # mv mutates source AND destination
    elif verb in MUTATORS:
        check = pathish
    elif verb == "sed" and "-i" in args:
        check = pathish
    elif verb == "git" and any(a in GIT_WRITES for a in args):
        check = pathish                            # catches `git -C <path> commit`
    check.extend(redirect_targets(seg))            # redirects mutate regardless of the verb

    for raw in check:
        bad = offends(raw, cwd)
        if bad:
            offenders.append(bad)

for o in dict.fromkeys(offenders):
    print(o)
PY
)

    if [ -n "$offender" ]; then
      consumed=$(consume_authorization "$offender")
      [ "$consumed" = "yes" ] && exit 0
      ask "Mutating command targets a path outside this repo → $offender

Everything outside this project is READ-ONLY by default unless you approve this specific mutation.
Approving allows this one command; it does not disable the guard for anything else."
    fi
    ;;
esac

exit 0
