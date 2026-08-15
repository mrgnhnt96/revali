---
title: revali up
description: Run every Revali service in a repository at once
---

The `revali up` command starts **every** Revali service in a repository together, on one screen, with one set of keystrokes driving all of them.

Five services is otherwise five `revali dev` processes in five terminals. That is the point at which people stop running the whole system locally and start developing one service against staging or mocks — which hides exactly the mismatches that splitting into services creates.

## Basic Usage

```bash
dart run revali up
```

Every service gets a port assigned in order and passed as `PORT`, which [`AppConfig.fromEnv`](/revali/app-configuration/env-vars) reads:

```
Starting 3 service(s)

  orders    http://localhost:8080
  billing   http://localhost:8081
  users     http://localhost:8082
```

## What Counts as a Service

A package with a `routes/` directory **that also depends on the framework**. The dependency check matters: `routes/` alone is a common enough directory name that a frontend router or a docs folder would otherwise be reported as a service.

Use [`revali services`](/revali/cli/services) to see what would be picked up without starting anything.

## Options

| Flag | Meaning |
|---|---|
| `--root <path>` | Directory to search from. Defaults to the working directory. |
| `--only <name>` | Run just these services, by package name or path. Repeatable. |
| `--base-port <port>` | First port to assign; services take one each in order. Defaults to `8080`. |

An unknown `--only` name is refused rather than ignored — a typo would otherwise look like a service that starts and does nothing.

## The Screen

With a terminal attached, `revali up` takes the alternate screen and draws three regions:

```
┌──────────────────────────────────────────────────────────────┐
│ ▸ orders    http://localhost:8080   serving                  │
│   billing   http://localhost:8081   generating   ⠹           │
│   users     http://localhost:8082   needs fix                │
├──────────────────────────────────────────────────────────────┤
│ orders  Server running on http://localhost:8080              │
│ orders  GET /api/orders 200                                  │
│                                                    12-40/318 │
├──────────────────────────────────────────────────────────────┤
│ ↑↓ select jk scroll g live r reload c clear q quit R/C/Q all │
└──────────────────────────────────────────────────────────────┘
```

- **The roster.** One row per service — name, address, state — with `▸` on the focused one. Three rows are visible at a time however large the fleet is, and the window follows the selection; the log pane below is why `revali up` exists, and a roster that grew with the fleet would leave a ten-service repo four lines of output to read.
- **The log pane.** The focused service's output, and only that service's. A crashed service keeps its row *and* its pane, which is where you look to read the error that killed it.
- **The footer.** The keys that apply *right now*. A key that would do nothing in the current state is left off the line entirely rather than dimmed, so everything the footer offers is something that works.

### Service States

| State | Meaning |
|---|---|
| `starting` | Spawned, and has not yet said anything more specific. |
| `generating` | A build or retrieve step is in flight. |
| `serving` | Announced an address it is listening on. |
| `needs fix` | The server is down but `revali dev` is not — a port collision, typically. Recoverable with `r`. |
| `crashed` | The `revali dev` process exited non-zero. Bring it back with `s`. |
| `stopped` | The `revali dev` process exited zero. |

`needs fix` and `crashed` are the two the roster colors loudly, because they are the two that cost something to miss.

## Keystrokes

| Key | Effect |
|---|---|
| `↑` / `↓` | Move the selection, wrapping at both ends |
| `1`–`9` | Select that service directly, even one scrolled out of the roster |
| `j` / `k` | Scroll the focused pane a line at a time |
| `PageUp` / `PageDown` | Scroll a screen, keeping one row of overlap |
| `g` | Jump the pane back to live output |
| `r` | Regenerate and restart the focused service |
| `c` | Clear the focused pane |
| `q` | Stop the focused service; the rest of the fleet carries on |
| `s` | Start a service whose process is gone |
| `R` / `C` / `Q` | The same three, applied to **every** service |
| `Ctrl-C` | Stop the fleet. Press again to stop waiting for it. |

The mouse works too: click a roster row to focus it, click a URL or a route path in the pane to open it in a browser, and scroll the wheel over the pane. A clickable run is underlined; a route path resolves against the address its service announced, so a click before a service is listening does nothing rather than opening a guess.

<Callout type="note">

`r`, `c` and `q` reach the children through each service's `.revali_cmd` file rather than through stdin. A child process's stdin is a pipe, not a terminal, so `revali dev` inside it takes its headless path and never reads keystrokes at all — the same file-based channel [`revali dev`](/revali/cli/dev) documents for CI and agents.

`s` is the exception, and could not work any other way: there is no process left to write a file to, so it asks `revali up` itself to spawn a new one.

</Callout>

File-watching reload works independently of the keys, so saving a file still reloads the service that owns it.

## Without a Terminal

In CI, or with stdout or stdin redirected, there is no screen. `revali up` prints each service's output flat, prefixed with its name in a stable color and aligned across the fleet:

```
orders   Server running on http://localhost:8080
billing  Server running on http://localhost:8081
orders   GET /api/orders 200
```

Raw mode is *probed* rather than assumed — a pseudo-TTY can claim to be a terminal and still refuse it — so a pipeline gets flat output rather than a screen it cannot type at.

Child processes that redraw their line with a bare `\r` cannot overwrite the prefix, so it stays readable when several services start at once.

## Shutdown

`Ctrl-C` and `Q` both send `SIGTERM` to every child, so each drains through the [graceful shutdown](/revali/app-configuration/graceful-shutdown) path rather than being killed — in-flight requests finish and readiness reports `503` while they do.

The screen swaps to a shutdown view while that happens, listing each service as it drains. A fleet with real drain delays takes seconds to go down, and the whole point of the swap is that a developer can tell "draining" from "wedged". If a child ignores `SIGTERM` entirely, a second `Ctrl-C` stops waiting for it.

## When a Service Fails to Start

It is reported and the rest carry on. The usual cause is a compile error the developer is about to fix, and losing the whole fleet for one makes the loop worse rather than safer.

Its row stays in the roster reading `crashed`, its pane keeps the output that explains why, and `s` brings it back once the cause is fixed.

If **no** service starts, `revali up` exits non-zero rather than sitting there with nothing running.

## Related

- [`revali dev`](/revali/cli/dev) — one service, with the same keystrokes
- [`revali services`](/revali/cli/services) — list what would run
- [`revali compose`](/revali/cli/compose) — a `docker-compose.yaml` for the same set
