---
title: revali up
description: Run every Revali service in a repository at once
---

`revali up` starts `revali dev` for every Revali service in a repository. They all run in one terminal, and one set of keys controls them. Use it when a repository has several services that you want to run together.

```bash
dart run revali up
```

Services are the packages that [`revali services`](/revali/cli/services) lists. Each one gets its own port, in path order starting at `--base-port`. The port is passed to it as `PORT`:

```text
Starting 3 service(s)

  orders    http://localhost:8080
  billing   http://localhost:8081
  users     http://localhost:8082
```

<Callout type="important">

A service reads `PORT` only when its app uses [`AppConfig.fromEnv`](/revali/app-configuration/env-vars#appconfigfromenv). A service that sets `port` directly ignores the port it was assigned.

</Callout>

## Options

| Flag | Default | Description |
| --- | --- | --- |
| `--root <path>` | working directory | Where to start looking for services. |
| `--only <name>` | all services | Runs only the named services, matched by package name or path. Repeatable. An unknown name is an error. |
| `--base-port <port>` | `8080` | The first port to assign. Each following service gets the next port. |

## The Screen

When a terminal is attached, `revali up` draws three regions:

- **Roster.** One row per service, showing its name, address and state. `▸` marks the selected service. Three rows show at a time, and the list scrolls with the selection.
- **Log pane.** Output from the selected service only. A service that crashed keeps its row and its log, so you can read the error.
- **Footer.** The keys that work right now.

| State | Meaning |
| --- | --- |
| `starting` | The process has started but hasn't reported anything else yet. |
| `generating` | Generation is running. |
| `serving` | The service reported the address it is listening on. |
| `needs fix` | `revali dev` is still running, but the server is down (a port collision, for example). Press `r` to retry. |
| `crashed` | `revali dev` exited with a non-zero code. Press `s` to start it again. |
| `stopped` | `revali dev` exited with code 0. |

## Keys

| Key | Effect |
| --- | --- |
| `↑` / `↓` | Move the selection, wrapping at both ends |
| `1`–`9` | Select a service by its position in the list |
| `j` / `k` | Scroll the log pane one line |
| `PageUp` / `PageDown` | Scroll the log pane one page |
| `g` | Jump back to live output |
| `r` / `c` / `q` | Reload, clear, or stop the selected service |
| `R` / `C` / `Q` | Reload, clear, or stop every service |
| `s` | Start a service whose process has exited |
| `Ctrl-C` | Stop all services. Press it again to stop waiting for them. |

The mouse also works. Click a row to select that service. Click a URL or a route path in the log pane to open it in a browser. Scroll the wheel over the pane to scroll the log.

`r`, `c` and `q` reach each service through its `.revali_cmd` file, the same channel [`revali dev`](/revali/cli/dev#hot-reload-and-hotkeys) uses when it has no terminal. Saving a file still reloads the service that owns it.

## Without a Terminal

In CI, or when stdin or stdout is redirected, there is no screen. Each service's output is printed with its name as a prefix:

```text
orders   Serving at http://localhost:8080/api
billing  Serving at http://localhost:8081/api
```

## Shutdown and Failures

- `Ctrl-C` and `Q` send `SIGTERM` to every service, so each one shuts down [gracefully](/revali/app-configuration/graceful-shutdown). The screen lists each service while it drains. A second `Ctrl-C` stops waiting for a service that ignores the signal.
- If one service fails to start, the error is reported and the other services keep running. Press `s` to start it again once it's fixed.
- If no service starts at all, `revali up` exits with a non-zero code.

Related: [`revali services`](/revali/cli/services) · [`revali compose`](/revali/cli/compose)
