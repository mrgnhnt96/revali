---
title: revali services
description: List the Revali services in a repository
---

`revali services` lists the Revali services in a repository without starting any of them. [`revali up`](/revali/cli/up) and [`revali compose`](/revali/cli/compose) find services the same way, so use this command to check what they will include.

```bash
dart run revali services
```

```text
3 service(s)

  orders    services/orders
  billing   services/billing
  users     services/users  (no Dockerfile yet)
```

`(no Dockerfile yet)` means the service has no `.revali/build/Dockerfile`, which `revali compose` needs. To create one, run [`revali build`](/revali/cli/build) in that package with [`revali_docker`](/constructs/revali_docker) installed.

## What Counts as a Service

A directory counts as a service when both of these are true:

1. It has a `pubspec.yaml` and a `routes/` directory.
2. Its `pubspec.yaml` depends on `revali_router` or `revali`.

Search rules:

- The search doesn't look inside a service for more services.
- It skips `.revali`, `.dart_tool`, `.git`, `build`, `node_modules` and every directory whose name starts with a dot.
- Results are sorted by path. `revali up` and `revali compose` assign ports in this order.

## Options

| Flag | Default | Description |
| --- | --- | --- |
| `--root <path>` | working directory | Where to start looking for services. |
| `--paths` | off | Prints only the paths, one per line, with no header or color. |

```bash
for service in $(dart run revali services --paths); do
  (cd "$service" && dart run revali build)
done
```

## Exit Codes

| Code | Meaning |
| --- | --- |
| `0` | At least one service was found. |
| `1` | The `--root` directory doesn't exist, or no services were found. |
