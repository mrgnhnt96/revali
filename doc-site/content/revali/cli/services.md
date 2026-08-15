---
title: revali services
description: List the Revali services in a repository
---

The `revali services` command prints every Revali service it can find, without starting anything.

It answers the question the rest of the multi-service tooling depends on: what counts as "the system"? [`revali up`](/revali/cli/up) and [`revali compose`](/revali/cli/compose) both run the same discovery, so if a service is missing from one of them, this is where to look first.

## Basic Usage

```bash
dart run revali services
```

```
3 service(s)

  orders    services/orders
  billing   services/billing
  users     services/users  (no Dockerfile yet)
```

The `(no Dockerfile yet)` marker means [`revali build`](/revali/cli/build) has not run in that package. It matters for `revali compose`, whose generated file builds each service from `.revali/build/Dockerfile`.

## What Counts as a Service

A directory is a service when **both** are true:

1. It has a `pubspec.yaml` and a `routes/` directory.
2. Its `pubspec.yaml` depends on the framework.

The dependency check is the load-bearing half. `routes/` is a common enough directory name that a frontend router, a docs folder, or a fixture would otherwise be reported as a service you were expected to run.

Discovery stops descending once it finds a service — a service does not contain another service — and skips `.revali`, `.dart_tool`, `.git`, `build`, `node_modules`, and any dotted directory. Results are sorted by path, so the order is stable between runs, and that same order is what assigns ports in `revali up` and `revali compose`.

## Options

| Flag | Meaning |
|---|---|
| `--root <path>` | Directory to search from. Defaults to the working directory. |
| `--paths` | Print only paths, one per line, for scripting. |

`--paths` writes nothing else — no count, no header, no color — so it can be piped:

```bash
for service in $(dart run revali services --paths); do
  (cd "$service" && dart run revali build)
done
```

## Exit Codes

| Code | Meaning |
|---|---|
| `0` | At least one service was found. |
| `1` | The `--root` directory does not exist, or no service was found under it. |

Finding nothing is an error rather than an empty list on purpose: in a script, an empty list reads as "there is nothing to do" and a wrong `--root` looks exactly the same.

## Related

- [`revali up`](/revali/cli/up) — run everything this lists
- [`revali compose`](/revali/cli/compose) — generate a `docker-compose.yaml` for it
- [`revali build`](/revali/cli/build) — produce the Dockerfile a service is missing
