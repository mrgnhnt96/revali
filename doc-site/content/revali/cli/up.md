---
title: revali up
description: Run every Revali service in a repository at once
---

The `revali up` command starts **every** Revali service in a repository together, with merged output and one set of keystrokes driving all of them.

Five services is otherwise five `revali dev` processes in five terminals. That is the point at which people stop running the whole system locally and start developing one service against staging or mocks — which hides exactly the mismatches that splitting into services creates.

## Basic Usage

```bash
dart run revali up
```

Every service gets a port assigned in order and passed as `PORT`, which [`AppConfig.fromEnv`](/revali/app-configuration) reads:

```
Starting 3 service(s)

  orders    http://localhost:8080
  billing   http://localhost:8081
  users     http://localhost:8082
```

## What Counts as a Service

A package with a `routes/` directory **that also depends on the framework**. The dependency check matters: `routes/` alone is a common enough directory name that a frontend router or a docs folder would otherwise be reported as a service.

Use `revali services` to see what would be picked up without starting anything.

## Options

| Flag | Meaning |
|---|---|
| `--root <path>` | Directory to search from. Defaults to the working directory. |
| `--only <name>` | Run just these services, by package name or path. Repeatable. |
| `--base-port <port>` | First port to assign; services take one each in order. Defaults to `8080`. |

An unknown `--only` name is refused rather than ignored — a typo would otherwise look like a service that starts and does nothing.

## Keystrokes

While `revali up` is running, press:

| Key | Effect |
|---|---|
| `r` | Regenerate and restart **every** service |
| `c` | Clear and reprint each status board |
| `q` | Quit the fleet |

These reach the children through each service's `.revali_cmd` file rather than through stdin. A child process's stdin is a pipe, not a terminal, so `revali dev` inside it takes its headless path and never reads keystrokes at all — the same file-based channel [`revali dev`](/revali/cli/dev) documents for CI and agents.

One file is written per service, in that service's own directory. `q` also stops the fleet, so a service wedged badly enough to ignore its command file cannot leave `revali up` waiting on it forever.

File-watching reload works independently of the keys, so saving a file still reloads the service that owns it.

## Output

Each service's output is prefixed with its name in a stable color, aligned across the fleet:

```
orders   Server running on http://localhost:8080
billing  Server running on http://localhost:8081
orders   GET /api/orders 200
```

Child processes that redraw their line with a bare `\r` cannot overwrite the prefix, so it stays readable when several services start at once.

## Shutdown

`Ctrl-C` sends `SIGTERM` to every child, so each drains through the [graceful shutdown](/revali/app-configuration) path rather than being killed — in-flight requests finish and readiness reports `503` while they do.

## When a Service Fails to Start

It is reported and the rest carry on. The usual cause is a compile error the developer is about to fix, and losing the whole fleet for one makes the loop worse rather than safer:

```
billing exited (254)
```

If **no** service starts, `revali up` exits non-zero rather than sitting there with nothing running.

## Related

- [`revali dev`](/revali/cli/dev) — one service, with the same keystrokes
- `revali services` — list what would run
- `revali compose` — generate a `docker-compose.yaml` for the same set
