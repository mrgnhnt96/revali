# INVARIANTS

The non-negotiables `game_loop stepback` re-injects. This is the template that ships with game_loop —
**edit it to your project's north star.** Keep the six general ones; add your own as observed failures
demand (INV5). Each should earn its place from a real mistake, not from wanting a tidy list.

---

## INV1 — Enforcement lives in tools, never in instructions

A rule the agent has to *remember* is followed only some of the time — long sessions and context
compaction break that promise. A rule a hook *consumes* holds every time.

Test for any guard here: **if the agent ignored every instruction, would this still hold?** If no, it
is not enforcement; it is a wish. This is why the keystone check is always "name a real file that
exists" — the one check prose cannot satisfy.

## INV2 — Read a real file before asserting (THE gate)

Every claim about external reality — a dependency, a harness, another repo — must name the real file
that backs it: `game_loop claim --assert ".." --read <path>`. A research subagent's citation is not a
source; it *finds* the file, it does not *read* it. Cite the file you read.

## INV3 — Everything outside this repo is READ-ONLY

Read other projects, mine them, use their data as fixtures. Never write, never run their tooling,
never deploy. Access is not permission — logged-in accounts, tokens, and an always-on prod connection
are not permission. Enforced by `.game_loop/bin/guard-writes.sh`, not by this paragraph, because a
paragraph exactly like it is the kind of thing that already fails.

## INV4 — No gate without a logged, observed failure

Ceremony has a certain cost and a hypothetical benefit. Do not add a rung until `log.jsonl` shows a
real failure that demands it. When tempted, name the entry that justifies it.

## INV5 — A guard must never block its own fix

A guard that blocks the fix it recommends is a guard that gets switched off — and a guard disabled
once is disabled forever. Every guard needs a legitimate path through it. Here the escape hatch is the
*human* (`game_loop authorize`), never an env var, because an advertised bypass is a bypass.

## INV6 — ENCODE, don't remember; and state what a guard misses

A learning is a bug in the system with a countdown. Its deliverable is an **artifact**, not a
sentence: `game_loop harden --learning ".." --artifact <real path> --mechanism ".." --rung N`. Take the
highest rung that applies — **1 IMPOSSIBLE · 2 LOUD · 3 CHECKED · 4 AUTOMATED · 5 VISIBLE · 6
doc/memory** (last resort). And a guard that overstates its reach buys false confidence: say what it
does *not* catch, in the guard itself. Silence from a guard is not evidence of safety.

---

**The outside view outranks my attachment.** The human and fresh review subagents are the real
outside view. When they disagree with me, they are probably right; update rather than defend.
