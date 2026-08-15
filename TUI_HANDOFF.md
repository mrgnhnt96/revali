# `revali up` TUI — handoff

Written for whoever picks this up next. The release is **held** for it: see
[Release state](#release-state) before doing anything else.

## The problem, in one screenshot

Two services under `revali up` merged into one flat stream:

```
orders  | ⠋ Retrieving constructs...
orders  | ✓ Retrieved constructs (61ms)
billing | ⠋ Retrieving constructs...
orders  | Constructs entrypoint is up to date
billing | ✓ Retrieved constructs (72ms)
...
```

Three separate faults, only one of which is cosmetic:

1. **Spinners are UI, and a shared stream cannot render them.** A child redraws
   in place with `\r`. Prefixing every line to say which service it came from
   makes redrawing impossible, so each frame became a permanent line.
2. **You cannot address one service.** `r`/`c`/`q` go to the whole fleet. There
   is no way to reload only `billing`, and no way to read only its log.
3. **State is invisible.** Whether a service is generating, serving, or dead is
   something you infer from scrollback.

A patch has landed for (1) — `523bcce6`, `prefixLines` now keeps only a line's
finished state and drops unresolved spinner frames. It took the output from
~20 noisy lines to one result line per step, and it is worth keeping.

**But it is a patch on the wrong layer.** It fixes the spinner problem by
deleting spinners, which is a confession that the medium is wrong. (2) and (3)
are untouched and cannot be fixed in a flat stream.

## What to build

A `nocterm` TUI, the way `hooksman` already does it.

```
┌ revali up ─────────────────────────────────────────────┐
│  ▸ billing   :8080   serving    12 req                 │
│    orders    :8081   generating ⠋                      │  ← service list
├────────────────────────────────────────────────────────┤
│  ✓ Retrieved constructs (52ms)                         │
│  ✓ Generated server code (2.3s)                        │  ← focused log
│  Serving at http://0.0.0.0:8080/api                    │
│                                                        │
├────────────────────────────────────────────────────────┤
│  ↑↓ select   r reload   c clear   q quit   R/Q all     │  ← footer
└────────────────────────────────────────────────────────┘
```

- **Service list** — name, port, state, focused marker. State comes from what
  `_running` and the exit future already track.
- **Log pane** — a ring buffer *per service*, showing the focused one. Spinners
  work again here, because each pane owns its region and can redraw in place.
- **Keys** — `↑`/`↓` (or `1`–`9`) select. `r`/`c`/`q` act on the **focused**
  service; a shifted variant acts on all. That is the capability that does not
  exist today.

## Where the code is

Everything lives in one file plus one helper:

| Path | What it does now |
|---|---|
| `packages/revali/lib/clis/revali_runner/commands/up_command.dart` | the whole command |
| `packages/revali/lib/services/service_plan.dart` | `prefixLines`, `colorFor`, `planServices` |
| `packages/revali/test/services/service_plan_test.dart` | 21 tests, incl. the spinner ones |
| `packages/revali/test/clis/revali_runner/commands/up_command_test.dart` | 6 tests for the command channel |

The functions that matter in `up_command.dart`:

- `_runAll(plans)` — starts everything, then waits on `exits`. **This is where
  `runApp` replaces the wait.**
- `_start(plan, color, width, exits)` — spawns one child and calls `pipe()` on
  its stdout/stderr. `pipe` currently flattens into `logger`; it should append
  to that service's buffer instead. **The per-service chunk is already here —
  today it is thrown away.**
- `_listenForKeystrokes(plans)` — raw-mode stdin listener. **Deleted**; nocterm
  owns the keyboard.
- `broadcastCommand(plans, command)` — **keep exactly as is.** See below.
- `_stop()` — SIGTERM to every child. Keep; wire to `q`-all.

### Do not reimplement the command channel

`broadcastCommand` writes `reload`/`clear`/`quit` into each service's
`.revali_cmd`, which `revali dev` already watches when it has no TTY
(`vm_service_handler.dart` → `_handleDevCommandFile`). Children cannot read
keystrokes because their stdin is a pipe — that is *why* the file channel
exists, and a TUI does not change it.

The TUI changes **who is addressed**, not the mechanism. Split it:

```dart
void sendCommand(ServicePlan plan, String command)   // one service — new
void broadcastCommand(List<ServicePlan> plans, ...)  // all — existing, keep
```

The existing test asserts the words written are exactly the ones
`_handleDevCommand` accepts. Keep that test: an unrecognised command is
*ignored* there, not reported, so a rename on either side silently breaks the
keys.

## How to verify it — this is the important part

**nocterm is testable without a terminal.** `package:nocterm` exports
`NoctermTester` (`src/test/nocterm_tester.dart`) with:

- `pumpComponent(Component, [Duration])`
- `sendKey(LogicalKey)` / `sendKeyEvent(KeyboardEvent)`
- `TerminalState` + matchers (`src/test/matchers.dart`)

So the whole thing can be driven headlessly:

```dart
await tester.pumpComponent(UpApp(plans: [orders, billing], ...));
await tester.sendKey(LogicalKey.arrowDown);   // focus orders
await tester.sendKey(LogicalKey.keyR);        // reload only orders
// assert: orders/.revali_cmd == 'reload\n', billing/.revali_cmd untouched
```

That last assertion is the one that matters, and it is the test the current
code cannot have. **Write it first.**

I could not verify a TUI in the session that produced this document — the
agent's `stdout` is not a terminal. `NoctermTester` removes that excuse. Do not
hand this over verified only by looking at it.

## Traps already paid for

- **A child's `\r` is not a line break.** It means *replace what I just drew*.
  Treating it as a break is what caused the wall of frames. But a **trailing**
  `\r` is the other half of a CRLF ending — treating *that* as a redraw
  discards whole lines on Windows. Both cases are covered by tests in
  `service_plan_test.dart`; read them before touching output handling.
- **Frames arrive one write at a time.** Collapsing within a chunk is not
  enough — the first frame lands in its own chunk. That is why unresolved
  spinner frames are dropped, not just deduplicated.
- **Ports are assigned in discovery order, which is alphabetical.** `billing`
  gets the base port, `orders` the next. The TUI should show the assigned port
  per service, because guessing it is a real papercut (it caught me while
  writing the demo README).
- **A service that fails to start must not take the fleet down.** Current
  behaviour, deliberate — the usual cause is a compile error about to be
  fixed. Preserve it: show the service as `crashed` in the list rather than
  exiting.

## Try it against something real

`/tmp/revali-demo` is a working two-service repo built for exactly this
(README included). It depends on the local checkout by path.

```bash
cd /tmp/revali-demo/orders
dart run revali up --root ..
```

`orders` runs 3 worker isolates and a 2s drain delay; `billing` consumes from
Redis. If `/tmp` has been cleared, the README explains how to rebuild it.

## Open decisions

Not blockers — make a call and write it down.

- **Scrollback.** Ring buffer per service: what size, and is scrolling in the
  log pane needed? `AutoScrollController`, `ListView` and `Scrollbar` all ship
  with nocterm.
- **Non-TTY fallback.** `revali up` in CI has no terminal. Keep the current
  flat prefixed output for that path — do **not** make the TUI mandatory. The
  existing `stdin.hasTerminal` check in `_listenForKeystrokes` is the seam.
- **Colour.** `colorFor(index)` gives each service a stable colour. Reuse it so
  the list and the log agree.
- **Does the log pane need the prefix at all?** Inside a per-service pane it is
  redundant. `prefixLines` may reduce to `lastFrame` + drop-unresolved.

## Release state

**That round shipped on 08.15.26** — this section said "nothing is published"
and was stale by the time anyone read it; `revali` 3.3.0, `revali_core` 3.1.0
and `revali_redis` 0.1.0 are all on pub.dev now. Verified against the registry,
not against this file.

So the TUI is a **fast follow**, not a held release. `revali up` already ships
in `revali` 3.3.0 without it, which is the version a first user touches.

A second round is staged in `LATEST_CHANGELOG.md`: `revali_core` 3.2.0 and
`revali_redis` 0.2.0, carrying the delivery-semantics fixes (see `todo.md`).
The TUI can ride that one. `revali` itself is not in it, so the `revali up`
entry in `LATEST_CHANGELOG.md` still reads `3.3.0` — bump it when the TUI
lands, or the release skips the package silently.

When ready: `sip run publish`, **from a real terminal**. It prints a plan for
every package and refuses when no terminal is attached. Add the TUI to
`revali`'s `LATEST_CHANGELOG.md` entry before publishing — that file is the
release notes, and today's entry describes `revali up` without it.

## Also still open, unrelated to the TUI

**Both `revali_redis` items listed here are now closed** (8.15.26) — this
section is kept only so the history reads straight:

- `RedisBroker.connect()` forwards every constructor option, `claimAfter`,
  `maxDeliveries` and `retryAfter` among them.
- Consumers still register in every isolate, which is correct for a Redis
  Streams consumer group — every worker pulling under its *own* name is the
  point. The name is what was wrong, and it is scoped by isolate index now
  (`IsolateIdentity.scopeName`), so `/tmp/revali-demo/billing` no longer has a
  reason to be pinned to one worker.

See `todo.md` for what came out of closing them: `maxDeliveries` was off by
one, retries had no backoff, and the repair paths starved under load.
